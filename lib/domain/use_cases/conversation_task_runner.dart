import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart' show ModelTokenUsage;
import 'package:stars/domain/models/provider_failure.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_execution_state.dart';
import 'package:stars/domain/models/task_file_read_observation.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/services/task_safe_data.dart';
import 'package:stars/domain/services/task_execution_details.dart';
import 'package:stars/domain/services/task_file_read_policy.dart';
import 'package:stars/domain/services/task_execution_gate.dart';
import 'package:stars/domain/services/task_verification_preparation.dart';
import 'package:stars/domain/services/tool_result_validator.dart';
import 'package:stars/domain/use_cases/conversation_task_model_turn.dart';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';

export 'conversation_task_runner_contracts.dart';

part 'conversation_task_runner_persistence.dart';
part 'conversation_task_runner_tools.dart';
part 'conversation_task_runner_recovery.dart';
part 'conversation_task_runner_preparation.dart';

/// Advances one accepted task segment. Every external operation follows a
/// committed checkpoint and a lease check. This use case never writes messages.
final class ConversationTaskRunner {
  ConversationTaskRunner({
    required this.repository,
    required TaskModelSessionFactory sessions,
    required Iterable<TaskToolAdapter> tools,
    required this.policy,
    this.prepare,
    this.clock = const SystemTaskRunnerClock(),
    double Function()? jitter,
  }) : model = ConversationTaskModelTurn(sessions),
       tools = Map.unmodifiable({
         for (final tool in tools) tool.definition.name: tool,
       }),
       jitter = jitter ?? Random().nextDouble;

  final ConversationTaskRepository repository;
  final ConversationTaskModelTurn model;
  final Map<String, TaskToolAdapter> tools;
  final ToolPolicy policy;
  final TaskExecutionPreparer? prepare;
  final TaskRunnerClock clock;
  final double Function() jitter;

  Future<TaskSegmentResult> run({
    required TaskExecutionSnapshot input,
    required TaskLease lease,
    required String segmentId,
    TaskExecutionGate? writeGate,
    AgentCancellationToken? interruption,
  }) =>
      _TaskSegment(
        this,
        input,
        lease,
        segmentId,
        writeGate ?? TaskExecutionGate(),
        interruption,
      ).run();
}

final class _TaskSegment {
  _TaskSegment(
    this.runner,
    this.snapshot,
    this.lease,
    this.segmentId,
    this.writeGate,
    this.interruption,
  );
  final TaskExecutionGate writeGate;
  final AgentCancellationToken? interruption;
  final ConversationTaskRunner runner;
  late Map<String, TaskToolAdapter> tools = runner.tools;
  TaskExecutionSnapshot snapshot;
  final TaskLease lease;
  final String segmentId;
  final cancellation = AgentCancellationToken();
  final completed = <String>{};
  final calls = <TaskPendingCall>[];
  final fileReads = <TaskFileReadObservation>[];
  final jobs = <TaskExternalJob>[];
  String? nextStep;
  bool stepStarted = false, replan = false, unknownEffects = false;
  int failures = 0,
      backoffs = 0,
      modelTurns = 0,
      toolCalls = 0,
      planRevisions = 0,
      repairs = 0;
  GroundedAnswerCandidate? candidate;
  ModelTokenUsage? pendingModelUsage;
  String? finalizationReason;
  String startDigest = '';
  ConversationTaskPhase phase = ConversationTaskPhase.planning;
  ConversationTask get task => snapshot.task;
  TaskSegmentLimits get limits => task.acceptance.segmentLimits;
  DateTime get now => runner.clock.now();
  List<ToolDefinition> get definitions => [
    for (final name in snapshot.plan.allowedToolNames)
      if (tools[name] case final adapter?) adapter.definition,
  ];

  Future<TaskSegmentResult> run() async {
    StreamSubscription<ConversationTaskProgressSummary>? watch;
    try {
      await _check(allowCancellation: true);
      _restore();
      watch = runner.repository.watchProgress(task.taskId).listen((summary) {
        if (summary.status == ConversationTaskStatus.cancelRequested ||
            summary.status.isTerminal) {
          cancellation.cancel();
        }
      }, onError: (Object _) => cancellation.cancel());
      if (task.cancelRequestedAt != null) return await _cancel();
      if (finalizationReason != null) {
        return await _finishFinalization(
          finalizationReason!,
          unknown: unknownEffects,
        );
      }
      if (candidate != null) return await _finishCandidate();
      final pendingApproval = snapshot.approvals.where(
        (a) => a.decision == null,
      );
      if (pendingApproval.isNotEmpty) {
        return await _approvalWait(pendingApproval.single.approvalId);
      }
      if (task.nextRunAt case final scheduled? when scheduled.isAfter(now)) {
        return await _backoff(until: scheduled);
      }
      startDigest = _digest();
      await _save(
        snapshot.checkpoint == null
            ? TaskEventKind.started
            : TaskEventKind.resumed,
        status: ConversationTaskStatus.running,
      );
      while (true) {
        await _check();
        if (snapshot.plan.isPending && snapshot.plan.preparation == null) {
          final result = await _prepareExecution();
          if (result != null) return result;
        }
        if (modelTurns >= limits.maxModelTurns ||
            toolCalls >= limits.maxToolCalls) {
          return await _continue();
        }
        if (calls.isNotEmpty) {
          final result = await _tool();
          if (result != null) return result;
          continue;
        }
        if (nextStep == null && !replan) {
          phase = ConversationTaskPhase.verifying;
          if (task.progress.verificationStatus ==
              TaskVerificationStatus.notStarted) {
            await _save(TaskEventKind.verificationStarted);
          }
          phase = ConversationTaskPhase.synthesizing;
        } else if (!stepStarted && !replan) {
          stepStarted = true;
          phase = ConversationTaskPhase.executing;
          await _save(TaskEventKind.stepStarted, stepId: nextStep);
        }
        TaskModelTurn turn;
        pendingModelUsage = null;
        var modelStarted = false;
        try {
          turn = await _operation((token) {
            modelStarted = true;
            return runner.model.run(
              snapshot: snapshot,
              tools:
                  replan
                      ? tools.values.map((tool) => tool.definition).toList()
                      : definitions,
              nextStepId: nextStep,
              replan: replan,
              cancellation: token,
              onTokenUsage: (usage) {
                if (!token.isCancelled) pendingModelUsage = usage;
              },
              synthesis:
                  nextStep == null && !replan
                      ? GroundedAnswerSynthesisRequest(
                        reliabilityFeedback:
                            repairs == 0
                                ? ''
                                : 'Return exactly one structured grounded answer; no tools or ordinary text.',
                        availableClaims: groundedSynthesisRequirements(
                          taskVerificationRequirements(snapshot, definitions),
                        ),
                        draftText:
                            'Write the final reply to the user for this completed task: ${task.objective}\n'
                            'Use the accepted conversation context and committed results. '
                            'Reply in ${task.acceptance.language} with plain, natural wording. '
                            'Lead with the outcome. For a simple completion request, a brief '
                            'confirmation and the useful deliverable or file link are enough. '
                            'Include substantive findings only when the user asked for them. '
                            'Choose the wording and level of detail from the context; do not use '
                            'a fixed completion template. Do not narrate tool calls, repeated reads, '
                            'evidence records, byte counts or hashes unless the user requested '
                            'those details or they are needed to explain the result. '
                            'Use available claims only for relevant factual statements. '
                            'Do not claim an action or verification beyond the committed evidence.',
                        evidence: [
                          for (final evidence in snapshot.evidence)
                            GroundedEvidenceReference(
                              evidenceId: evidence.evidenceId,
                              providerCallId: evidence.providerCallId,
                              toolName: evidence.toolName,
                              isError:
                                  evidence.terminalStatus !=
                                  ToolInvocationStatus.succeeded,
                            ),
                        ],
                      )
                      : null,
            );
          }, limits.providerTimeout);
        } on TaskModelProtocolException {
          modelTurns++;
          await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
          if (++repairs > limits.maxReliabilityRepairs) {
            return await _continue();
          }
          continue;
        } on GroundedAnswerFormatException {
          modelTurns++;
          await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
          if (++repairs > limits.maxReliabilityRepairs) {
            return await _continue();
          }
          continue;
        } on ProviderFailure catch (error) {
          modelTurns++;
          await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
          if (!error.retryable) {
            return await _finishFinalization(_providerReason(error));
          }
          return await _backoff();
        } on TimeoutException {
          modelTurns++;
          await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
          return await _backoff();
        } on AgentRunCancelledException {
          if (modelStarted) {
            modelTurns++;
            await _save(
              TaskEventKind.modelTurnCompleted,
              modelCount: 1,
              cleanup: true,
            );
          }
          rethrow;
        } on _TaskFenceLost {
          rethrow;
        } on StateError {
          // A model-session contract failure must not escape to the scheduler's
          // one-second recovery loop. Keep retries durable and bounded.
          modelTurns++;
          await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
          if (backoffs >= limits.maxSameCallRetries) {
            return await _finishFinalization(
              TaskReasonCode.providerUnavailable,
            );
          }
          return await _backoff();
        } on Exception {
          modelTurns++;
          await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
          return await _backoff();
        }
        modelTurns++;
        backoffs = 0;
        if (turn.steps case final steps?) {
          if (planRevisions >= limits.maxPlanRevisions) {
            await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
            return await _continue();
          }
          final result = await _revise(steps, turn.allowedToolNames);
          if (result != null) return result;
        } else if (turn.candidate case final answer?) {
          candidate = answer;
          await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
          return await _finishCandidate();
        } else if (turn.calls.isNotEmpty) {
          try {
            for (final call in turn.calls) {
              calls.add(_prepare(call));
            }
          } on ArgumentError {
            calls.clear();
            await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
            return await _finishFinalization(TaskReasonCode.invalidPlan);
          }
          await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
        } else {
          final step = nextStep!;
          completed.add(step);
          nextStep = _nextStep();
          stepStarted = false;
          phase = ConversationTaskPhase.observing;
          await _save(TaskEventKind.stepCompleted, stepId: step, modelCount: 1);
        }
      }
    } on _TaskFenceLost {
      return TaskLeaseLost(snapshot);
    } on AgentRunCancelledException {
      try {
        await _check(allowCancellation: true);
        if (task.cancelRequestedAt == null) {
          // An application pause is not a user cancellation. The previously
          // committed intent remains available for reconciliation on resume.
          await _release();
          return TaskContinueSegment(snapshot);
        }
        return await _cancel();
      } on _TaskFenceLost {
        return TaskLeaseLost(snapshot);
      }
    } finally {
      cancellation.cancel();
      await watch?.cancel();
    }
  }

  void _restore() {
    final checkpoint = snapshot.checkpoint;
    final state = checkpoint?.execution;
    completed.addAll(
      checkpoint?.completedStepIds ??
          [
            for (final step in snapshot.plan.steps)
              if (step.status == TaskPlanStepStatus.completed ||
                  step.status == TaskPlanStepStatus.skipped)
                step.stepId,
          ],
    );
    nextStep = checkpoint?.nextStepId ?? _nextStep();
    calls.addAll(state?.calls ?? []);
    fileReads.addAll(state?.fileReads ?? []);
    jobs.addAll(checkpoint?.externalJobs ?? []);
    stepStarted = state?.stepStarted ?? false;
    replan = snapshot.plan.isPending || (state?.replanRequired ?? false);
    failures = state?.consecutiveFailures ?? 0;
    backoffs = state?.backoffCount ?? 0;
    candidate = state?.candidate;
    finalizationReason = state?.finalizationReason;
    unknownEffects = state?.sideEffectsUnknown ?? false;
    if (checkpoint?.phase == ConversationTaskPhase.committing &&
        task.phase != ConversationTaskPhase.committing) {
      // Explicit resume of a configuration/reconciliation wait, retaining
      // calls and handles without replaying the old finalization candidate.
      finalizationReason = null;
      unknownEffects = false;
    }
    phase = task.phase;
  }

  String? _nextStep() =>
      snapshot.plan.steps
          .where((step) => !completed.contains(step.stepId))
          .firstOrNull
          ?.stepId;

  Future<TaskSegmentResult?> _revise(
    List<TaskPlanStep> steps,
    Set<String>? selectedTools,
  ) async {
    final previous = snapshot.plan;
    final allowed = selectedTools ?? previous.allowedToolNames;
    if (steps.isEmpty ||
        !snapshot.toolScope.containsAll(allowed) ||
        !tools.keys.toSet().containsAll(allowed) ||
        steps.map((s) => s.stepId).toSet().length != steps.length ||
        steps.any((s) => completed.contains(s.stepId))) {
      await _save(TaskEventKind.modelTurnCompleted, modelCount: 1);
      return _finishFinalization(TaskReasonCode.invalidPlan);
    }
    final revised = ConversationTaskPlan(
      taskId: task.taskId,
      revision: previous.revision + 1,
      objective: task.objective,
      steps: [
        for (final step in previous.steps)
          if (completed.contains(step.stepId))
            TaskPlanStep(
              stepId: step.stepId,
              summary: step.summary,
              status: TaskPlanStepStatus.completed,
            ),
        ...steps,
      ],
      allowedToolNames: allowed,
      preparation: previous.preparation,
      createdAt: now,
    );
    nextStep = steps.first.stepId;
    stepStarted = false;
    replan = false;
    failures = 0;
    planRevisions++;
    phase = ConversationTaskPhase.planning;
    await _save(TaskEventKind.planRevised, plan: revised, modelCount: 1);
    return null;
  }
}

final class _TaskFenceLost implements Exception {
  const _TaskFenceLost();
}

String _providerReason(ProviderFailure error) => switch (error.kind) {
  ProviderFailureKind.authentication => TaskReasonCode.missingCredentials,
  ProviderFailureKind.authorization => TaskReasonCode.permissionDenied,
  _ => TaskReasonCode.providerUnavailable,
};

String _hash(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(_canonical(value)))).toString();
Object? _canonical(Object? value) => switch (value) {
  final Map<String, Object?> map => {
    for (final key in map.keys.toList()..sort()) key: _canonical(map[key]),
  },
  final List<Object?> list => list.map(_canonical).toList(),
  _ => value,
};
