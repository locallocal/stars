import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/domain/models/models.dart';

import '../../support/conversation_task_fixtures.dart';

void main() {
  for (final status in ConversationTaskStatus.values) {
    test(
      'round-trips ${status.name} task, frozen policies and message identity',
      () {
        final task = taskFixture(
          status: status,
          lease: status == ConversationTaskStatus.running ? taskLease() : null,
        );
        final row = ConversationTaskRecord.fromDomain(task);
        final restored = ConversationTaskRecord(
          _jsonRoundTrip(row.values),
        ).toDomain(progress: task.progress);
        expect(ConversationTaskRecord.fromDomain(restored).values, row.values);
        expect(restored.createdAt, taskTime);
        expect(restored.acceptance.context.single.content, '整理报告');
        expect(restored.acceptance.segmentLimits.maxModelTurns, 32);
        expect(restored.verificationPolicy.strictGroundingEnabled, isTrue);
      },
    );
  }

  test(
    'round-trips every execution override without duration precision loss',
    () {
      final limits = TaskSegmentLimits(
        maxModelTurns: 50,
        maxToolCalls: 60,
        maxSameCallRetries: 5,
        maxConsecutiveToolFailures: 9,
        maxReliabilityRepairs: 4,
        maxPlanRevisions: 9,
        maxNoProgressSegments: 10,
        providerTimeout: const Duration(minutes: 16, microseconds: 1),
        toolTimeout: const Duration(minutes: 17),
        pollTimeout: const Duration(minutes: 6),
        reconcileTimeout: const Duration(minutes: 18),
        initialBackoff: const Duration(seconds: 30),
        maxBackoff: const Duration(hours: 1),
      );
      final encoded = TaskSegmentLimitsRecord.encode(limits);
      expect(
        TaskSegmentLimitsRecord.encode(
          TaskSegmentLimitsRecord.decode(_jsonRoundTrip(encoded)),
        ),
        encoded,
      );
    },
  );

  test(
    'snapshot decoder rejects unknown config, credential and reasoning fields',
    () {
      final values = TaskAcceptanceRecord.encode(taskAcceptance());
      for (final key in ['apiKey', 'accessToken', 'reasoning', 'parameters']) {
        expect(
          () => TaskAcceptanceRecord.decode({...values, key: 'secret'}),
          throwsFormatException,
        );
      }
      final context =
          (values['context']! as List<Object?>).single! as Map<String, Object?>;
      expect(
        () => TaskAcceptanceRecord.decode({
          ...values,
          'context': [
            {...context, 'reasoning': 'private'},
          ],
        }),
        throwsFormatException,
      );
      expect(jsonEncode(values), isNot(contains('apiKey')));
      expect(jsonEncode(values), isNot(contains('reasoning')));
    },
  );

  test(
    'rejects unsupported lifecycle values and corrupt stable message identities',
    () {
      final task = taskFixture(),
          values = ConversationTaskRecord.fromDomain(taskFixture()).values;
      expect(
        () => ConversationTaskRecord({
          ...values,
          'status': 'timedOut',
        }).toDomain(progress: task.progress),
        throwsFormatException,
      );
      expect(
        () => ConversationTaskRecord({
          ...values,
          'ack_message_id': 'random',
        }).toDomain(progress: task.progress),
        throwsFormatException,
      );
    },
  );

  test('progress counters, tools, approval and verification round-trip', () {
    final progress = TaskProgress(
      completedSteps: 2,
      totalSteps: 4,
      currentStepSummary: '等待审批',
      lastMeaningfulProgressAt: taskTime,
      modelTurns: 35,
      toolAttempts: 49,
      recoveries: 2,
      segments: 3,
      noProgressSegments: 1,
      summaryHash: 'a' * 64,
      latestTool: TaskToolProgress(
        attemptId: 'attempt-1',
        name: 'read_file',
        status: ToolInvocationStatus.succeeded,
        safeSummary: '已读取资料',
      ),
      pendingApprovalId: 'approval-1',
      pendingApprovalSummary: '保存报告',
      approvalRequestedAt: taskTime,
      reasonCode: TaskReasonCode.reconciliationRequired,
      verificationStatus: TaskVerificationStatus.verifying,
    );
    final record = TaskProgressRecord.fromDomain('task-1', 8, progress);
    final restored =
        TaskProgressRecord(_jsonRoundTrip(record.values)).toDomain();
    expect(
      TaskProgressRecord.fromDomain('task-1', 8, restored).values,
      record.values,
    );
  });

  test('plan and checkpoint include safe external job recovery state', () {
    final plan = ConversationTaskPlanRecord.fromDomain(taskPlan(taskFixture()));
    expect(
      ConversationTaskPlanRecord.fromDomain(plan.toDomain()).values,
      plan.values,
    );
    final checkpoint = ConversationTaskCheckpoint(
      taskId: 'task-1',
      segmentId: 'segment-2',
      planRevision: 1,
      sequence: 8,
      phase: ConversationTaskPhase.observing,
      savedAt: taskTime,
      nextStepId: 'write',
      evidenceCursor: 3,
      completedStepIds: ['read'],
      pendingAttemptIds: ['attempt-1'],
      context: taskAcceptance().context,
      externalJobs: [
        TaskExternalJob(
          attemptId: 'attempt-1',
          externalJobId: 'job-1',
          resumeHandle: 'handle:job-1',
          safeStatus: 'pending',
          nextPollAt: taskTime,
        ),
      ],
    );
    final record = ConversationTaskCheckpointRecord.fromDomain(checkpoint);
    final restored =
        ConversationTaskCheckpointRecord(
          _jsonRoundTrip(record.values),
        ).toDomain();
    expect(
      ConversationTaskCheckpointRecord.fromDomain(restored).values,
      record.values,
    );
    expect(() => restored.externalJobs.clear(), throwsUnsupportedError);
  });

  for (final kind in TaskEventKind.values) {
    test('${kind.name} event round-trips immutable audit references', () {
      final event = ConversationTaskEvent(
        taskId: 'task-1',
        sequence: 9,
        kind: kind,
        occurredAt: taskTime,
        safeSummary: '进展已记录',
        planRevision: 3,
        modelTurns: 2,
        verificationStatus: TaskVerificationStatus.partial,
        segmentId: 'segment-1',
        stepId: 'read',
        attemptId: 'attempt-1',
        approvalId: 'approval-1',
        evidenceId: 'attempt-1:evidence',
        reasonCode: TaskReasonCode.noProgress,
      );
      final row = ConversationTaskEventRecord.fromDomain(event);
      expect(
        ConversationTaskEventRecord.fromDomain(row.toDomain()).values,
        row.values,
      );
    });
  }

  test('approval and immutable execution/evidence links round-trip', () {
    final approval = TaskApprovalDbRecord.fromDomain(
      TaskApprovalRecord(
        approvalId: 'approval-1',
        taskId: 'task-1',
        requestRevision: 2,
        safeActionSummary: '写入报告',
        requestedAt: taskTime,
        attemptId: 'attempt-1',
        decision: TaskApprovalDecision.approved,
        decidedBy: 'user-1',
        decidedAt: taskTime,
      ),
    );
    expect(
      TaskApprovalDbRecord.fromDomain(approval.toDomain()).values,
      approval.values,
    );
    final link = TaskToolAttemptLinkRecord.fromDomain(
      TaskToolAttemptLink(
        taskId: 'task-1',
        segmentId: 'segment-1',
        attemptId: 'attempt-1',
        idempotencyKey: 'operation-1',
        attemptNumber: 1,
      ),
    );
    expect(
      TaskToolAttemptLinkRecord.fromDomain(link.toDomain()).values,
      link.values,
    );
    final evidence = TaskEvidenceLinkRecord.fromDomain(
      TaskEvidenceLink(
        taskId: 'task-1',
        segmentId: 'segment-1',
        attemptId: 'attempt-1',
        evidenceId: 'attempt-1:evidence',
      ),
    );
    expect(
      TaskEvidenceLinkRecord.fromDomain(evidence.toDomain()).values,
      evidence.values,
    );
    expect(
      () => TaskEvidenceLink(
        taskId: 'task-1',
        segmentId: 'segment-1',
        attemptId: 'other',
        evidenceId: 'attempt-1:evidence',
      ),
      throwsArgumentError,
    );
  });

  test(
    'message kinds map to stable storage names and preserve metadata in copyWith',
    () {
      for (final kind in TaskMessageKind.values) {
        final taskId = kind == TaskMessageKind.directReply ? null : 'task-1';
        final message = Message(
          messageId: switch (kind) {
            TaskMessageKind.directReply => 'turn-1:assistant',
            TaskMessageKind.acknowledgement => 'task-1:ack',
            TaskMessageKind.status => 'status-1',
            TaskMessageKind.result => 'task-1:result',
          },
          turnId: 'turn-1',
          chatId: 'chat-1',
          botId: 'bot-1',
          senderId: 'assistant',
          taskId: taskId,
          taskMessageKind: kind,
          summaryRevision: kind == TaskMessageKind.status ? 7 : null,
          terminalOutcome:
              kind == TaskMessageKind.result
                  ? MessageTerminalOutcome.completed
                  : null,
          content: '回复',
          timestamp: taskTime,
        );
        final row = MessageRecord.fromDomain(message.copyWith(content: '更新'));
        expect(row.values['task_message_kind'], kind.storageName);
        final restored = row.toDomain();
        expect(restored.taskId, taskId);
        expect(restored.taskMessageKind, kind);
        expect(restored.summaryRevision, message.summaryRevision);
      }
    },
  );

  test(
    'message metadata rejects wrong IDs, unsupported kinds and fake operational trust',
    () {
      Message message({
        String id = 'task-1:ack',
        MessageGrounding grounding = const MessageGrounding.unverified(),
      }) => Message(
        messageId: id,
        turnId: 'turn-1',
        chatId: 'chat-1',
        botId: 'bot-1',
        senderId: 'assistant',
        taskId: 'task-1',
        taskMessageKind: TaskMessageKind.acknowledgement,
        content: '记录',
        grounding: grounding,
        timestamp: taskTime,
      );
      expect(() => message(id: 'random'), throwsArgumentError);
      expect(
        () => message(
          grounding: MessageGrounding(
            trustLevel: AnswerTrustLevel.verified,
            evidenceIds: ['attempt-1:evidence'],
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => TaskMessageKind.fromStorage('unknown'),
        throwsFormatException,
      );
      final status = Message(
        messageId: 'status-1',
        chatId: 'chat-1',
        botId: 'bot-1',
        senderId: 'assistant',
        taskMessageKind: TaskMessageKind.status,
        content: '没有活动任务',
        timestamp: taskTime,
      );
      expect(MessageRecord.fromDomain(status).toDomain().taskId, isNull);
    },
  );
}

Map<String, Object?> _jsonRoundTrip(Map<String, Object?> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, Object?>;
