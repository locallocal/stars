import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/provider_failure.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import '../../support/task_runner_harness.dart';
import '../../support/task_scheduler_harness.dart'
    show createRunnerScheduler, until;

void main() {
  late TaskRunnerHarness h;
  setUp(() {
    h = TaskRunnerHarness();
  });
  tearDown(() => h.close());

  test(
    'model session state failures back off across restart and stop at the retry limit',
    () async {
      await h.open(limits: TaskSegmentLimits(maxSameCallRetries: 2));
      h.models.completeStep();
      for (var i = 0; i < 3; i++) {
        h.models.turns.add(
          () => throw StateError('private model session details'),
        );
      }
      var scheduler = createRunnerScheduler(h);
      addTearDown(() => scheduler.stop());
      await scheduler.start(periodic: false);
      await until(
        () async =>
            scheduler.runningCount == 0 && (await h.db.task).nextRunAt != null,
      );
      expect(
        (await h.db.task).nextRunAt!.difference(h.clock.time),
        const Duration(seconds: 15),
      );
      expect((await h.snapshot).checkpoint!.execution!.backoffCount, 1);
      expect(h.models.requests, hasLength(2));
      await scheduler.stop();
      await h.db.reopen();
      scheduler = createRunnerScheduler(h);
      await scheduler.start(periodic: false);
      await scheduler.tick();
      expect(h.models.requests, hasLength(2));
      await h.advanceToDue();
      await scheduler.tick();
      await until(
        () async =>
            scheduler.runningCount == 0 &&
            (await h.snapshot).checkpoint!.execution!.backoffCount == 2,
      );
      expect(
        (await h.db.task).nextRunAt!.difference(h.clock.time),
        const Duration(seconds: 30),
      );
      await h.advanceToDue();
      await scheduler.tick();
      await until(
        () async =>
            scheduler.runningCount == 0 &&
            (await h.db.task).status == ConversationTaskStatus.waitingForUser,
      );
      expect((await h.db.task).waitingReason, TaskWaitingReason.requiredInput);
      expect((await h.db.task).nextRunAt, isNull);
      expect(h.models.requests, hasLength(4));
      h.clock.advance(const Duration(hours: 1));
      await scheduler.tick();
      expect(h.models.requests, hasLength(4));
      expect(
        jsonEncode(await h.db.facts()),
        isNot(contains('private model session details')),
      );
    },
  );

  test(
    'an invalid write response cannot prove that no side effect occurred',
    () async {
      await h.open();
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      h.tool.onStart =
          (_) async =>
              throw ProviderFailure.invalidResponse(
                endpointKind: ProviderEndpointKind.unknown,
              );
      final result = await h.run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.reconciliationRequired);
      expect(result.sideEffectsUnknown, isTrue);
      expect(
        result.snapshot.attempts.single.status,
        ToolInvocationStatus.running,
      );
    },
  );

  test(
    'tool provider authentication failure stops the path immediately',
    () async {
      await h.open();
      h.models.tool();
      h.tool.onStart =
          (_) async =>
              throw ProviderFailure.fromHttp(
                statusCode: 401,
                endpointKind: ProviderEndpointKind.unknown,
              );
      final result = await h.run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.missingCredentials);
      expect(result.snapshot.task.nextRunAt, isNull);
      expect(h.tool.starts, 1);
    },
  );

  test('undeclared tool arguments never enter the checkpoint', () async {
    await h.open();
    h.models.tool(
      arguments: {
        'headers': {'x-custom': 'private'},
      },
    );
    expect(await h.run(), isA<TaskNeedsSafeFinalization>());
    expect(h.tool.starts, 0);
    expect(
      jsonEncode(await h.db.database.query('conversation_task_checkpoints')),
      isNot(contains('x-custom')),
    );
  });

  test(
    'a newly checkpointed action counts as progress at a one-turn boundary',
    () async {
      await h.open(
        limits: TaskSegmentLimits(maxModelTurns: 1, maxNoProgressSegments: 1),
      );
      h.models.tool();
      final result = await h.run();
      expect(result, isA<TaskContinueSegment>());
      expect(result.snapshot.task.progress.noProgressSegments, 0);
      expect(result.snapshot.checkpoint!.execution!.calls, hasLength(1));
    },
  );

  test(
    'approval and plan event timestamps remain atomic with an advancing clock',
    () async {
      await h.open();
      h.clock.tick = const Duration(microseconds: 1);
      h.models.tool(
        name: 'stars_revise_task_plan',
        arguments: {
          'steps': [
            {'id': 'revised', 'summary': 'Read report'},
          ],
        },
      );
      h.models.tool();
      h.policy.outcome = ToolPolicyOutcome.requireApproval;
      final result = await h.run() as TaskApprovalWait;
      expect(result.snapshot.plan.revision, 2);
      final events = await h.db.database.query('conversation_task_events');
      final revision = events.singleWhere(
        (row) => row['kind'] == 'planRevised',
      );
      final approval = events.singleWhere(
        (row) => row['kind'] == 'approvalRequested',
      );
      expect(
        revision['occurred_at'],
        result.snapshot.plan.createdAt.microsecondsSinceEpoch,
      );
      expect(
        approval['occurred_at'],
        result.snapshot.approvals.single.requestedAt.microsecondsSinceEpoch,
      );
    },
  );

  test(
    'commits bounded work then restores a fresh session without repeating success',
    () async {
      await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
      h.models.tool(arguments: {'path': 'report.md'});
      expect(await h.run(), isA<TaskContinueSegment>());
      final checkpoint = (await h.snapshot).checkpoint!;
      expect(checkpoint.execution!.calls, isEmpty);
      expect((await h.db.task).lease, isNull);
      expect((await h.db.task).progress.toolAttempts, 1);
      await h.db.reopen();
      h.models.tool(id: 'new-provider-id', arguments: {'path': 'report.md'});
      h.models.completeStep();
      h.models.candidate();
      final result = await h.run();
      expect(result, isA<TaskCompletionCandidate>());
      expect(h.tool.starts, 1);
      expect(result.snapshot.task.progress.modelTurns, 4);
      expect(result.snapshot.task.progress.segments, 2);
      expect(
        result.snapshot.checkpoint!.execution!.candidate!.renderedText,
        '已整理',
      );
      expect(h.models.closed, 4);
      expect(await h.db.database.query('messages'), hasLength(2));
      final serialized = jsonEncode(
        await h.db.database.query('conversation_task_checkpoints'),
      );
      expect(serialized, isNot(contains('private intermediate draft')));
      expect(h.models.requests.last.messages.first.content, '整理报告');
      expect(
        h.models.requests.last.messages.every((m) => m.reasoning.isEmpty),
        isTrue,
      );
    },
  );

  test(
    'frozen budgets allow work beyond old whole-run timeout and tool limits',
    () async {
      await h.open(
        limits: TaskSegmentLimits(maxModelTurns: 32, maxToolCalls: 48),
      );
      h.tool.onStart = (call) async {
        h.clock.advance(const Duration(minutes: 10));
        return ToolCompleted(
          ToolResult(
            callId: call.callId,
            name: call.name,
            content: 'Read completed.',
          ),
        );
      };
      for (var i = 0; i < 35; i++) {
        h.models.tool(id: 'p-$i', arguments: {'page': i});
      }
      final first = await h.run();
      expect(first, isA<TaskContinueSegment>());
      expect(first.snapshot.task.progress.modelTurns, 32);
      await h.db.reopen();
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(h.tool.starts, 35);
      expect(h.clock.time.difference(taskTime), const Duration(minutes: 350));
      expect(
        h.models.requests.every(
          (r) => r.options.requestTimeout == const Duration(minutes: 15),
        ),
        isTrue,
      );
      expect(
        h.clock.budgets.every((d) => d == const Duration(minutes: 15)),
        isTrue,
      );
    },
  );

  test(
    'empty invalid turns reach no-progress only at the frozen segment threshold',
    () async {
      await h.open(
        limits: TaskSegmentLimits(maxModelTurns: 1, maxNoProgressSegments: 3),
      );
      for (var i = 0; i < 3; i++) {
        h.models.events([const ReasoningDelta('secret reasoning')]);
        final result = await h.run();
        expect(result.snapshot.task.progress.noProgressSegments, i + 1);
        if (i < 2) {
          expect(result, isA<TaskContinueSegment>());
        } else {
          expect(
            (result as TaskNeedsSafeFinalization).reasonCode,
            TaskReasonCode.noProgress,
          );
          expect(result.snapshot.task.status.isTerminal, isFalse);
        }
      }
      expect(
        jsonEncode(await h.db.database.query('conversation_task_checkpoints')),
        isNot(contains('secret reasoning')),
      );
    },
  );

  test(
    'approval is durable, returns immediately, and resumes exact arguments after reopening',
    () async {
      await h.open();
      h.policy.outcome = ToolPolicyOutcome.requireApproval;
      h.models.tool(arguments: {'path': 'approved-file'});
      final first = await h.run() as TaskApprovalWait;
      expect(h.tool.starts, 0);
      expect(first.snapshot.task.status, ConversationTaskStatus.waitingForUser);
      expect(first.snapshot.task.lease, isNull);
      h.clock.advance(const Duration(days: 10));
      await h.db.reopen();
      final task = await h.db.task;
      committed(
        await h.db.repository.decideApproval(
          taskId: task.taskId,
          approvalId: first.approvalId,
          expectedRevision: task.revision,
          decision: TaskApprovalDecision.approved,
          actorId: 'user',
          decidedAt: h.clock.now(),
        ),
      );
      h.tool.onStart = (call) async {
        expect(call.arguments, {'path': 'approved-file'});
        return ToolCompleted(
          ToolResult(callId: call.callId, name: call.name, content: 'Done'),
        );
      };
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(h.tool.starts, 1);
      expect((await h.db.task).progress.noProgressSegments, 0);
    },
  );

  test('denied approval never starts the tool', () async {
    await h.open();
    h.policy.outcome = ToolPolicyOutcome.requireApproval;
    h.models.tool();
    final first = await h.run() as TaskApprovalWait;
    final task = await h.db.task;
    committed(
      await h.db.repository.decideApproval(
        taskId: task.taskId,
        approvalId: first.approvalId,
        expectedRevision: task.revision,
        decision: TaskApprovalDecision.denied,
        actorId: 'user',
        decidedAt: h.clock.now(),
      ),
    );
    final result = await h.run() as TaskNeedsSafeFinalization;
    expect(result.reasonCode, TaskReasonCode.permissionDenied);
    expect(h.tool.starts, 0);
  });

  test(
    'long job start and poll persist handles and release resources between polls',
    () async {
      await h.open();
      h.models.tool();
      h.tool.onStart =
          (_) async => ToolJobStarted(
            externalJobId: 'job-1',
            resumeHandle: 'handle:job_1',
            safeStatus: 'running',
            nextPollAt: h.clock.now().add(const Duration(hours: 1)),
          );
      final first = await h.run() as TaskExternalJobWait;
      expect(first.snapshot.task.lease, isNull);
      expect(
        first.snapshot.checkpoint!.externalJobs.single.resumeHandle,
        'handle:job_1',
      );
      await h.db.reopen();
      await h.advanceToDue();
      h.tool.onPoll = (job) async {
        expect(job.externalJobId, 'job-1');
        return ToolCompleted(
          ToolResult(
            callId: 'provider-call',
            name: 'read_file',
            content: 'Job done',
          ),
        );
      };
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(h.tool.starts, 1);
      expect(h.tool.polls, 1);
      expect(h.clock.budgets, contains(const Duration(minutes: 5)));
      expect((await h.snapshot).checkpoint!.externalJobs, isEmpty);
    },
  );

  test(
    'read timeout records an attempt and yields jittered exponential backoff',
    () async {
      await h.open();
      h.models.tool();
      h.tool.onStart =
          (_) async => throw TimeoutException('secret raw exception');
      final first = await h.run() as TaskBackoff;
      expect(
        first.nextRunAt.difference(h.clock.now()),
        const Duration(seconds: 15),
      );
      expect(
        first.snapshot.attempts.single.status,
        ToolInvocationStatus.timedOut,
      );
      await h.advanceToDue();
      final second = await h.run() as TaskBackoff;
      expect(
        second.nextRunAt.difference(h.clock.now()),
        const Duration(seconds: 30),
      );
      expect(second.snapshot.task.progress.noProgressSegments, 0);
      expect(h.tool.keys.toSet(), hasLength(1));
      expect(
        jsonEncode(await h.db.database.query('tool_execution_records')),
        isNot(contains('secret raw exception')),
      );
    },
  );

  test(
    'uncertain write is reconciled before any repeat and returns a safe stop',
    () async {
      await h.open();
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      h.tool.onStart = (_) async => throw TimeoutException('timeout');
      expect(await h.run(), isA<TaskBackoff>());
      await h.advanceToDue();
      await h.db.reopen();
      final result = await h.run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.reconciliationRequired);
      expect(result.sideEffectsUnknown, isTrue);
      expect(h.tool.starts, 1);
      expect(h.tool.reconciles, 1);
    },
  );

  test(
    'write retry is allowed after positive not-started reconciliation',
    () async {
      await h.open();
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      h.tool.onStart = (_) async => throw TimeoutException('timeout');
      await h.run();
      await h.advanceToDue();
      h.tool.onReconcile = () async => const ToolNotStarted();
      expect(await h.run(), isA<TaskBackoff>());
      await h.advanceToDue();
      h.tool.onStart = null;
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(h.tool.starts, 2);
      expect(h.tool.keys.toSet(), hasLength(1));
    },
  );

  test(
    'provider authentication stops immediately without leaking details',
    () async {
      await h.open();
      h.models.events([
        ModelTurnFailed(
          error: 'Bearer secret',
          providerFailure: ProviderFailure.fromHttp(
            statusCode: 401,
            endpointKind: ProviderEndpointKind.responses,
          ),
        ),
      ]);
      final result = await h.run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.missingCredentials);
      expect(result.snapshot.task.progress.modelTurns, 1);
      expect(result.snapshot.task.status.isTerminal, isFalse);
    },
  );

  test(
    'consecutive failures request a revised path instead of failing the task',
    () async {
      await h.open(limits: TaskSegmentLimits(maxConsecutiveToolFailures: 2));
      h.models.tool();
      h.tool.onStart =
          (call) async => ToolCompleted(
            ToolResult(
              callId: call.callId,
              name: call.name,
              content: 'Temporary failure',
              isError: true,
              errorCode: 'unavailable',
            ),
          );
      expect(await h.run(), isA<TaskBackoff>());
      await h.advanceToDue();
      h.models.tool(
        name: 'stars_revise_task_plan',
        arguments: {
          'steps': [
            {'id': 'alternative', 'summary': 'Try another source'},
          ],
        },
      );
      h.models.completeStep();
      h.models.candidate();
      final result = await h.run() as TaskCompletionCandidate;
      expect(result.snapshot.plan.revision, 2);
      expect(result.snapshot.task.progress.totalSteps, 1);
      expect(result.snapshot.task.progress.toolAttempts, 2);
      expect(h.models.requests[1].tools.map((t) => t.name), [
        'stars_revise_task_plan',
      ]);
    },
  );

  test(
    'unsafe arguments are rejected before any tool or credential checkpoint',
    () async {
      await h.open();
      h.models.tool(arguments: {'api_key': 'sk-secretsecret'});
      final result = await h.run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.invalidPlan);
      expect(h.tool.starts, 0);
      expect(
        jsonEncode(await h.db.database.query('conversation_task_checkpoints')),
        isNot(contains('sk-secretsecret')),
      );
    },
  );
}
