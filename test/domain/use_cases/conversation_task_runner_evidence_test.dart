import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/local_file_system_tools.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
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

  void evidenceTool({
    bool write = false,
    bool invalid = false,
    bool sensitive = false,
    String content = 'Report processed.',
  }) {
    final kind = write ? EvidenceKind.actionReceipt : EvidenceKind.observation;
    h.tool = RunnerTool(
      definition: ToolDefinition(
        name: 'read_file',
        description: 'Report evidence',
        source: ToolSource.builtIn,
        riskLevel: write ? ToolRiskLevel.write : ToolRiskLevel.readOnly,
        inputSchema: {'type': 'object'},
        outputSchema: {
          'type': 'object',
          'properties': toolEvidenceOutputSchemaProperties,
          'required': toolEvidenceOutputRequiredFields,
          'additionalProperties': false,
        },
        capabilities: {
          write ? ToolCapability.localWrite : ToolCapability.localRead,
        },
        toolVersion: '1',
        evidenceCapabilities: {kind},
        evidenceScope: ToolEvidenceScopeRule(
          subject: 'report',
          fixedScope: {'report': 'report-1'},
        ),
        defaultEvidenceValidity: const Duration(hours: 1),
        requiresReadAfterWrite: write,
      ),
    );
    h.tool.onStart = (call) async {
      final facts = [
        StructuredFact(
          name: write ? 'action.completed' : 'report.count',
          value: write ? true : 42,
        ),
        if (sensitive)
          StructuredFact(name: 'note', value: 'Bearer credential-secret'),
      ];
      return ToolCompleted(
        ToolResult(
          callId: call.callId,
          name: call.name,
          content: content,
          structuredContent:
              invalid
                  ? {'wrong': true}
                  : toolEvidenceOutputMetadata(
                    evidenceKind: kind,
                    subject: 'report',
                    scope: {'report': 'report-1'},
                    structuredFacts: facts,
                    observedAt: h.clock.now(),
                  ),
          evidenceKind: kind,
          subject: 'report',
          scope: {'report': 'report-1'},
          structuredFacts: facts,
          observedAt: h.clock.now(),
        ),
      );
    };
  }

  for (final (name, content, expectedSummary) in [
    (
      'multiline Markdown and control characters',
      '# Report\r\n\nCount:\t42\u0000\u007f',
      '# Report Count: 42',
    ),
    ('control-only output', '\u0000\u007f\t\r\n', 'Tool attempt completed.'),
    (
      'sensitive text and diagnostic lines',
      'Report\npassword="private value"\n#0 internalFunction (private.dart:1)\nCount: 42',
      'Report password=[redacted] Count: 42',
    ),
    (
      'credential assignment exposed by normalization',
      'Report\npassword\u0000=private-value',
      'Report password=[redacted]',
    ),
    (
      'structured output after a leading control',
      '\u0000{"count":42}',
      '[details omitted]',
    ),
    ('long output', 'Report\n${'x' * 2500}', 'Report ${'x' * 1993}'),
  ]) {
    test('$name persists successful evidence across restart', () async {
      await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
      evidenceTool(content: content);
      final produce = h.tool.onStart!;
      late ToolResult original;
      h.tool.onStart = (call) async {
        final completed = await produce(call) as ToolCompleted;
        original = completed.result;
        return completed;
      };
      h.models.tool();

      expect(await h.run(), isA<TaskContinueSegment>());
      await h.db.reopen();
      final snapshot = await h.snapshot;
      expect(snapshot.attempts.single.status, ToolInvocationStatus.succeeded);
      expect(snapshot.attempts.single.resultSummary, expectedSummary);
      expect(snapshot.checkpoint!.pendingAttemptIds, isEmpty);
      expect(snapshot.checkpoint!.evidenceCursor, 1);
      final evidence = snapshot.evidence.single;
      expect(evidence.persisted, isTrue);
      expect(evidence.resultSummary, expectedSummary);
      expect(evidence.resultDigest, original.resultDigest);
      expect(evidence.structuredFacts.single.name, 'report.count');
      expect(evidence.structuredFacts.single.value, 42);
      expect(original.content, content);
    });
  }

  test(
    'approved multiline file read reaches completion without interruption or retry',
    () async {
      final acceptance = taskAcceptance();
      await h.open(
        acceptance: TaskAcceptanceSnapshot(
          providerId: acceptance.providerId,
          modelId: acceptance.modelId,
          configurationDigest: acceptance.configurationDigest,
          language: acceptance.language,
          context: acceptance.context,
          allowedToolNames: {'read_local_file'},
          verification: acceptance.verification,
          segmentLimits: TaskSegmentLimits(),
        ),
      );
      const content = '# Report\n\n## Findings\n\nA multiline file.\n';
      final file = File('${h.db.directory.path}/report.md');
      await file.writeAsString(content);
      // The real file adapter timestamps its evidence with the system clock.
      h.clock.time = DateTime.now().toUtc().add(const Duration(minutes: 1));
      final tool = ReadLocalFileTool();
      late ToolResult original;
      h.tool = RunnerTool(definition: tool.definition);
      h.tool.onStart = (call) async {
        original = await tool.execute(call, AgentCancellationToken());
        return ToolCompleted(original);
      };
      h.policy.outcome = ToolPolicyOutcome.requireApproval;
      h.models.tool(name: 'read_local_file', arguments: {'path': file.path});
      h.models.completeStep();
      h.models.candidate();
      final ready = <TaskSegmentResult>[];
      final scheduler = createRunnerScheduler(
        h,
        onReady: (result) async => ready.add(result),
      );
      try {
        await scheduler.start(periodic: false);
        await until(
          () async =>
              (await h.db.task).status ==
                  ConversationTaskStatus.waitingForUser &&
              scheduler.runningCount == 0,
        );
        final waiting = await h.snapshot;
        committed(
          await h.db.repository.decideApproval(
            taskId: waiting.task.taskId,
            approvalId: waiting.approvals.single.approvalId,
            expectedRevision: waiting.task.revision,
            decision: TaskApprovalDecision.approved,
            actorId: 'test-user',
            decidedAt: h.clock.now(),
          ),
        );
        await scheduler.tick();
        await scheduler.tick();
        await until(() => ready.isNotEmpty && scheduler.runningCount == 0);

        expect(ready.single, isA<TaskCompletionCandidate>());
        expect(scheduler.metrics.failures, 0);
        expect(scheduler.metrics.retries, 0);
        expect(h.tool.starts, 1);
        expect(original.isError, isFalse);
        expect(original.content, content);
        final snapshot = await h.snapshot;
        expect(snapshot.attempts.single.status, ToolInvocationStatus.succeeded);
        expect(snapshot.evidence.single.resultDigest, original.resultDigest);
        expect(snapshot.task.progress.completedSteps, 1);
        final events = await h.db.database.query('conversation_task_events');
        expect(
          events.map((row) => row['kind']),
          isNot(
            anyElement(isIn(['toolFailed', 'retryScheduled', 'leaseExpired'])),
          ),
        );
        expect(await file.readAsString(), content);
      } finally {
        await scheduler.stop();
      }
    },
  );

  test(
    'accepted evidence and tool success share a transaction and survive restart for synthesis',
    () async {
      await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
      evidenceTool();
      h.models.tool();
      expect(await h.run(), isA<TaskContinueSegment>());
      final first = await h.snapshot;
      expect(first.evidence, hasLength(1));
      expect(first.checkpoint!.evidenceCursor, 1);
      expect(first.attempts.single.status, ToolInvocationStatus.succeeded);
      await h.db.reopen();
      final evidenceId = (await h.snapshot).evidence.single.evidenceId;
      h.models.completeStep();
      h.models.candidate(
        GroundedAnswerCandidate(
          claims: [
            AnswerClaim(
              claimId: 'count',
              text: '报告共 42 条',
              kind: ClaimKind.currentFact,
              evidenceIds: [evidenceId],
            ),
          ],
        ),
      );
      final result = await h.run() as TaskCompletionCandidate;
      expect(result.candidate.evidenceIds, [evidenceId]);
      expect(h.models.synthesisRequests.single.allowedEvidenceIds, {
        evidenceId,
      });
      await h.db.reopen();
      expect((await h.snapshot).checkpoint!.execution!.candidate!.evidenceIds, [
        evidenceId,
      ]);
    },
  );

  for (final table in [
    'tool_evidence_records',
    'conversation_task_evidence_links',
  ]) {
    test(
      '$table failure rolls back evidence, success, cursor and completed call',
      () async {
        await h.open();
        evidenceTool();
        h.models.tool();
        await h.db.failWrite(table);
        await expectLater(h.run(), throwsA(isA<Exception>()));
        final snapshot = await h.snapshot;
        expect(snapshot.evidence, isEmpty);
        expect(snapshot.checkpoint!.evidenceCursor, 0);
        expect(snapshot.checkpoint!.pendingAttemptIds, hasLength(1));
        expect(snapshot.attempts.single.status, ToolInvocationStatus.running);
      },
    );
  }

  test(
    'invalid tool evidence never becomes an accepted business fact',
    () async {
      await h.open();
      evidenceTool(invalid: true);
      h.models.tool();
      expect(await h.run(), isA<TaskBackoff>());
      final snapshot = await h.snapshot;
      expect(snapshot.evidence, isEmpty);
      expect(snapshot.attempts.single.errorCode, 'invalid_tool_output');
    },
  );

  test('sensitive facts cannot enter the durable evidence ledger', () async {
    await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
    evidenceTool(sensitive: true);
    h.models.tool();
    await h.run();
    expect((await h.snapshot).evidence, isEmpty);
    expect(
      jsonEncode(await h.db.database.query('conversation_task_checkpoints')),
      isNot(contains('credential-secret')),
    );
  });

  test(
    'post-write verification requirements are rebuilt from durable action receipts',
    () async {
      await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
      evidenceTool(write: true);
      h.models.tool();
      await h.run();
      await h.db.reopen();
      h.models.completeStep();
      h.models.candidate();
      await h.run();
      final synthesis = h.models.synthesisRequests.single;
      expect(synthesis.requiredClaims, isEmpty);
      final claims = synthesis.availableClaims;
      expect(claims, hasLength(2));
      expect(claims.first.requiredFactValues, {'action.completed': true});
      expect(claims.last.verificationAvailable, isFalse);
    },
  );

  test(
    'synthesis protocol repair is bounded and candidate is persisted only when controlled',
    () async {
      await h.open();
      h.models.completeStep();
      h.models.events([
        const TextDelta('unstructured answer'),
        const ModelTurnCompleted(stopReason: 'stop'),
      ]);
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(h.models.synthesisRequests, hasLength(2));
      expect(h.models.synthesisRequests.last.reliabilityFeedback, isNotEmpty);
      expect((await h.db.task).progress.modelTurns, 3);
      expect(
        jsonEncode(await h.db.database.query('conversation_task_checkpoints')),
        isNot(contains('unstructured answer')),
      );
    },
  );

  test('a candidate cannot bind evidence from another task', () async {
    await h.open(limits: TaskSegmentLimits(maxModelTurns: 2));
    h.models.completeStep();
    h.models.candidate(
      GroundedAnswerCandidate(
        claims: [
          AnswerClaim(
            claimId: 'fake',
            text: 'invented completion',
            kind: ClaimKind.completedAction,
            evidenceIds: ['foreign-attempt:evidence'],
          ),
        ],
      ),
    );
    expect(await h.run(), isA<TaskContinueSegment>());
    expect((await h.snapshot).checkpoint!.execution!.candidate, isNull);
  });

  test(
    'dynamic plan preserves completed work and revision budget yields a checkpoint',
    () async {
      await h.open(steps: 2, limits: TaskSegmentLimits(maxPlanRevisions: 1));
      h.models.completeStep();
      h.models.tool(
        name: 'stars_revise_task_plan',
        arguments: {
          'steps': [
            {'id': 'new-1', 'summary': 'New step 1'},
            {'id': 'new-2', 'summary': 'New step 2'},
          ],
        },
      );
      h.models.tool(
        name: 'stars_revise_task_plan',
        arguments: {
          'steps': [
            {'id': 'discarded', 'summary': 'Another revision'},
          ],
        },
      );
      final result = await h.run() as TaskContinueSegment;
      expect(result.snapshot.plan.revision, 2);
      expect(result.snapshot.task.progress.completedSteps, 1);
      expect(result.snapshot.task.progress.totalSteps, 3);
      expect(result.snapshot.checkpoint!.completedStepIds, ['step-0']);
      expect(result.snapshot.plan.steps.map((s) => s.stepId), [
        'step-0',
        'new-1',
        'new-2',
      ]);
    },
  );
}
