import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/use_cases/recover_conversation_tasks.dart';

import '../../support/task_terminal_harness.dart';

void main() {
  late TaskTerminalHarness h;
  setUp(() => h = TaskTerminalHarness());
  tearDown(() => h.close());

  test('terminal narration usage is persisted once with the result', () async {
    await h.open();
    await h.fail();
    final finish = h.finalizer(
      polish: (request, cancellation) async {
        request.onTokenUsage?.call(const ModelTokenUsage(inputTokens: 120));
        request.onTokenUsage?.call(
          const ModelTokenUsage(inputTokens: 120, outputTokens: 15),
        );
        return request.allowedNarrations.first;
      },
    );
    await finish('task-1');
    await finish('task-1');
    await h.runner.db.reopen();
    expect((await h.result()).tokenUsage.inputTokens, 120);
    expect((await h.result()).tokenUsage.outputTokens, 15);
    expect((await h.runner.db.task).progress.tokenUsage!.inputTokens, 120);
    expect((await h.runner.db.task).progress.tokenUsage!.outputTokens, 15);
  });

  test(
    'a natural completion reply omits repeated expired reads and keeps write verification internal',
    () async {
      await h.open(toolName: 'write_report');
      h.configureTool();
      for (var i = 0; i < 10; i++) {
        await h.observe(call: 'read-$i');
      }
      h.runner.clock.advance(const Duration(hours: 2));
      h.configureTool(write: true, name: 'write_report');
      await h.observe(call: 'write');
      h.configureTool();
      await h.observe(call: 'read-back');
      final snapshot = await h.runner.snapshot;
      final receipt = snapshot.evidence.singleWhere(
        (e) => e.evidenceKind == EvidenceKind.actionReceipt,
      );
      const reply = '报告已经整理好，可以查看了。';
      h.runner.models.completeStep();
      h.runner.models.candidate(
        GroundedAnswerCandidate(
          claims: [
            AnswerClaim(
              claimId: '${receipt.attemptId}:action',
              text: reply,
              kind: ClaimKind.completedAction,
              evidenceIds: [receipt.evidenceId],
            ),
          ],
        ),
      );
      await h.runner.run();
      final synthesis = h.runner.models.synthesisRequests.single;
      expect(synthesis.requiredClaims, isEmpty);
      expect(synthesis.availableClaims, hasLength(13));
      expect(synthesis.draftText, contains(snapshot.task.objective));
      expect(synthesis.draftText, contains('zh-CN'));
      expect(
        h.runner.models.requests.last.messages.map((m) => m.content),
        contains('整理报告'),
      );

      await h.runner.db.reopen();
      await h.finalizer()('task-1');
      final result = await h.result();
      expect(result.content, reply);
      expect(result.terminalOutcome, MessageTerminalOutcome.completed);
      expect(result.grounding.trustLevel, AnswerTrustLevel.verified);
      expect(result.grounding.claims, hasLength(1));
      expect((await h.runner.snapshot).evidence, hasLength(12));
      expect(
        (await h.runner.db.task).progress.verificationStatus,
        TaskVerificationStatus.verified,
      );
    },
  );

  test(
    'a read-only task can finish without reciting its observations',
    () async {
      await h.open();
      await h.observe();
      await h.candidate(omit: true);
      await h.finalizer()('task-1');
      final result = await h.result();
      expect(result.content, '已整理。');
      expect(result.terminalOutcome, MessageTerminalOutcome.completed);
      expect((await h.runner.snapshot).evidence, hasLength(1));
    },
  );

  test('requested findings still use the selected evidence binding', () async {
    await h.open();
    await h.observe();
    await h.observe(call: 'read-2');
    final evidence = (await h.runner.snapshot).evidence.last;
    const reply = '整理完了，报告共有 42 条记录。';
    h.runner.models.completeStep();
    h.runner.models.candidate(
      GroundedAnswerCandidate(
        claims: [
          AnswerClaim(
            claimId: '${evidence.attemptId}:fact',
            text: reply,
            kind: ClaimKind.currentFact,
            evidenceIds: [evidence.evidenceId],
          ),
        ],
      ),
    );
    await h.runner.run();
    await h.finalizer()('task-1');
    final result = await h.result();
    expect(result.content, reply);
    expect(result.grounding.trustLevel, AnswerTrustLevel.verified);
    expect(result.grounding.evidenceIds, [evidence.evidenceId]);
  });

  for (final readback in ['missing', 'before_write', 'expired']) {
    test('a short reply cannot bypass $readback write verification', () async {
      await h.open(write: true, toolName: 'write_report');
      final write = h.runner.tool;
      if (readback == 'before_write') {
        h.configureTool();
        await h.observe();
      }
      h.runner.tool = write;
      await h.observe(call: 'write');
      h.configureTool();
      if (readback == 'expired') {
        await h.observe(call: 'read-back');
        h.runner.clock.advance(const Duration(hours: 2));
      }
      await h.candidate(omit: true);
      await h.finalizer()('task-1');
      final task = await h.runner.db.task;
      expect(task.status, ConversationTaskStatus.failed);
      expect(
        task.terminalSummary!.reasonCode,
        TaskReasonCode.verificationFailed,
      );
      expect((await h.result()).content, isNot('已整理。'));
    });
  }

  test(
    'one verified result uses evidence from multiple segments and survives reopen',
    () async {
      await h.open();
      await h.observe();
      await h.observe(call: 'read-2');
      final evidence = (await h.runner.snapshot).evidence;
      expect(evidence.map((e) => e.runId).toSet(), hasLength(2));
      await h.candidate();
      expect(
        (await h.messages()).where(
          (m) => m.taskMessageKind == TaskMessageKind.result,
        ),
        isEmpty,
      );
      final finish = h.finalizer();
      await finish('task-1');
      final result = await h.result();
      expect(result.terminalOutcome, MessageTerminalOutcome.completed);
      expect(result.grounding.trustLevel, AnswerTrustLevel.verified);
      expect(
        result.grounding.evidenceIds.toSet(),
        evidence.map((e) => e.evidenceId).toSet(),
      );
      expect(await h.evidence.getForMessage(result.messageId), hasLength(2));
      expect(
        (await h.runner.db.task).progress.verificationStatus,
        TaskVerificationStatus.verified,
      );
      expect(finish.metrics.evidenceCoverage, 1);
      await h.runner.db.reopen();
      await h.finalizer()('task-1');
      expect((await h.result()).content, result.content);
      expect(
        (await h.runner.db.database.query(
          'conversation_task_events',
          where: "kind = 'terminal'",
        )),
        hasLength(1),
      );
    },
  );

  test(
    'strict failure suppresses unsupported claims and retains validated partial facts',
    () async {
      await h.open();
      await h.observe();
      await h.candidate(unsupported: true);
      final finish = h.finalizer();
      await finish('task-1');
      final task = await h.runner.db.task;
      final result = await h.result();
      expect(task.status, ConversationTaskStatus.failed);
      expect(
        task.terminalSummary!.reasonCode,
        TaskReasonCode.verificationFailed,
      );
      expect(result.content, isNot(contains('未经证实')));
      expect(result.content, contains('report.count: 42'));
      expect(result.grounding.trustLevel, AnswerTrustLevel.partiallyVerified);
      expect(
        result.grounding.claims.where(
          (c) => c.trustLevel == ClaimTrustLevel.verified,
        ),
        hasLength(1),
      );
      expect(finish.metrics.suppressedClaims, 1);
    },
  );

  test(
    'non-strict snapshot retains unverified claims with partial trust',
    () async {
      await h.open(strict: false);
      await h.observe();
      await h.candidate(unsupported: true);
      await h.finalizer()('task-1');
      final result = await h.result();
      expect(result.terminalOutcome, MessageTerminalOutcome.completed);
      expect(result.content, contains('未经证实'));
      expect(result.grounding.trustLevel, AnswerTrustLevel.partiallyVerified);
    },
  );

  test(
    'accepted reliability setting controls trust while hidden status still verifies evidence',
    () async {
      await h.open(reliability: false, showStatus: false);
      await h.observe();
      await h.candidate();
      await h.finalizer()('task-1');
      final result = await h.result();
      expect(result.grounding.trustLevel, AnswerTrustLevel.unverified);
      expect(result.grounding.reasonCode, 'reliability_policy_disabled');
      expect(
        result.grounding.claims.single.trustLevel,
        ClaimTrustLevel.verified,
      );
      expect(result.grounding.evidenceIds, hasLength(1));
    },
  );

  test(
    'write receipt without readback fails strict completion and never claims rollback',
    () async {
      await h.open(write: true);
      await h.observe();
      await h.candidate();
      await h.finalizer()('task-1');
      final task = await h.runner.db.task;
      expect(task.status, ConversationTaskStatus.failed);
      expect(
        task.terminalSummary!.sideEffectStatus,
        TaskSideEffectStatus.irreversible,
      );
      expect(task.terminalSummary!.canRetry, isFalse);
      expect((await h.result()).content, contains('未作回滚'));
    },
  );

  for (final mutation in ['expired', 'digest', 'failed_attempt']) {
    test('$mutation evidence cannot verify the final answer', () async {
      await h.open();
      await h.observe();
      await h.candidate();
      if (mutation == 'expired') {
        h.runner.clock.advance(const Duration(hours: 2));
      } else if (mutation == 'digest') {
        await h.runner.db.database.execute(
          'DROP TRIGGER tool_evidence_records_prevent_update',
        );
        await h.runner.db.database.update('tool_evidence_records', {
          'result_summary': 'tampered',
        });
      } else {
        await h.runner.db.database.update('tool_execution_records', {
          'status': 'failed',
        });
      }
      await h.finalizer()('task-1');
      expect((await h.runner.db.task).status, ConversationTaskStatus.failed);
      expect((await h.result()).grounding.evidenceIds, isEmpty);
      expect((await h.result()).content, isNot(contains('报告共 42 条')));
    });
  }

  test(
    'unrecoverable execution failure gets one safe localized result when Provider fails',
    () async {
      await h.open();
      await h.fail();
      var calls = 0;
      final finish = h.finalizer(
        polish: (_, _) async {
          calls++;
          throw StateError('Bearer sensitive /private/file');
        },
      );
      await finish('task-1');
      await finish('task-1');
      expect(calls, 1);
      final result = await h.result();
      expect(result.terminalOutcome, MessageTerminalOutcome.failed);
      expect(result.content, contains('未能完成'));
      expect(result.content, contains('调整请求'));
      expect(result.content, isNot(contains('sensitive')));
      expect(finish.metrics.narrationFallbacks, 1);
      expect(finish.metrics.narrationFailures, 1);
    },
  );

  test(
    'queued cancellation is an operational result without a failed trust label',
    () async {
      await h.open();
      await h.cancel();
      await h.finalizer()('task-1');
      final result = await h.result();
      expect(result.terminalOutcome, MessageTerminalOutcome.cancelled);
      expect(result.content, contains('已取消'));
      expect(result.grounding.reasonCode, 'no_verifiable_claims');
      expect(result.grounding.trustLevel, AnswerTrustLevel.unverified);
      expect(
        (await h.runner.db.task).terminalSummary!.cancellationSource,
        TaskCancellationSource.user,
      );
    },
  );

  test(
    'cancelRequested never publishes a cancelled result before the runner checks it',
    () async {
      await h.open();
      final task = await h.runner.db.task;
      committed(
        await h.runner.db.repository.requestCancellation(
          taskId: task.taskId,
          expectedRevision: task.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.runner.clock.now(),
        ),
      );
      expect(await h.finalizer()('task-1'), isNull);
      expect(
        (await h.messages()).where(
          (m) => m.taskMessageKind == TaskMessageKind.result,
        ),
        isEmpty,
      );
    },
  );

  test(
    'cancellation racing success validation fences the draft and wins after reconciliation',
    () async {
      await h.open();
      await h.observe();
      await h.candidate();
      final entered = Completer<void>(), release = Completer<void>();
      final ledger = _DelayedEvidence(h.evidence, entered, release);
      final pending = h.finalizer(ledger: ledger)('task-1');
      await entered.future;
      final task = await h.runner.db.task;
      committed(
        await h.runner.db.repository.requestCancellation(
          taskId: task.taskId,
          expectedRevision: task.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.runner.clock.now(),
        ),
      );
      release.complete();
      await pending;
      expect(
        (await h.runner.db.task).status,
        ConversationTaskStatus.cancelRequested,
      );
      expect(
        (await h.messages()).where(
          (m) => m.taskMessageKind == TaskMessageKind.result,
        ),
        isEmpty,
      );
      await h.runner.run();
      await h.finalizer()('task-1');
      expect(
        (await h.result()).terminalOutcome,
        MessageTerminalOutcome.cancelled,
      );
    },
  );

  for (final table in ['messages', 'answer_claim_evidence']) {
    test(
      '$table commit failure is atomic and durable candidate retries after restart',
      () async {
        await h.open();
        await h.observe();
        await h.candidate();
        await h.runner.db.failWrite(table);
        await expectLater(h.finalizer()('task-1'), throwsA(isA<Exception>()));
        expect((await h.runner.db.task).status.isTerminal, isFalse);
        expect(
          (await h.runner.db.database.query(
            'messages',
            where: "task_message_kind = 'taskResult'",
          )),
          isEmpty,
        );
        expect(
          (await h.runner.db.database.query('answer_claim_evidence')),
          isEmpty,
        );
        await h.runner.db.clearFailure();
        await h.runner.db.reopen();
        final ready =
            await RecoverConversationTasks(
              repository: h.runner.db.repository,
              clock: h.runner.clock,
            )();
        expect(ready, hasLength(1));
        await h.finalizer().onReady(ready.single);
        expect(
          (await h.result()).terminalOutcome,
          MessageTerminalOutcome.completed,
        );
      },
    );
  }

  test(
    'two finalizers racing the same candidate commit exactly one result',
    () async {
      await h.open();
      await h.observe();
      await h.candidate();
      await Future.wait([h.finalizer()('task-1'), h.finalizer()('task-1')]);
      expect(
        (await h.messages()).where(
          (m) => m.taskMessageKind == TaskMessageKind.result,
        ),
        hasLength(1),
      );
      expect(
        (await h.runner.db.database.query('answer_claim_evidence')),
        hasLength(1),
      );
    },
  );
}

final class _DelayedEvidence implements ToolEvidenceRepository {
  _DelayedEvidence(this.inner, this.entered, this.release);
  final ToolEvidenceRepository inner;
  final Completer<void> entered, release;
  @override
  Future<ToolEvidenceRecord?> getById(String id) async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return inner.getById(id);
  }

  @override
  Future<bool> verifyDigest(String id) => inner.verifyDigest(id);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
