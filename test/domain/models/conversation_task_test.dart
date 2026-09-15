import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

import '../../support/conversation_task_fixtures.dart';

void main() {
  final allowed = <ConversationTaskStatus, Set<ConversationTaskStatus>>{
    ConversationTaskStatus.queued: {
      ConversationTaskStatus.running,
      ConversationTaskStatus.paused,
      ConversationTaskStatus.waitingForUser,
      ConversationTaskStatus.failed,
      ConversationTaskStatus.cancelRequested,
    },
    ConversationTaskStatus.running: {
      ConversationTaskStatus.queued,
      ConversationTaskStatus.waitingForUser,
      ConversationTaskStatus.paused,
      ConversationTaskStatus.succeeded,
      ConversationTaskStatus.failed,
      ConversationTaskStatus.cancelRequested,
    },
    ConversationTaskStatus.waitingForUser: {
      ConversationTaskStatus.queued,
      ConversationTaskStatus.running,
      ConversationTaskStatus.paused,
      ConversationTaskStatus.failed,
      ConversationTaskStatus.cancelRequested,
    },
    ConversationTaskStatus.paused: {
      ConversationTaskStatus.queued,
      ConversationTaskStatus.running,
      ConversationTaskStatus.waitingForUser,
      ConversationTaskStatus.failed,
      ConversationTaskStatus.cancelRequested,
    },
    ConversationTaskStatus.cancelRequested: {
      ConversationTaskStatus.paused,
      ConversationTaskStatus.waitingForUser,
      ConversationTaskStatus.cancelled,
      ConversationTaskStatus.failed,
    },
    ConversationTaskStatus.succeeded: {},
    ConversationTaskStatus.failed: {},
    ConversationTaskStatus.cancelled: {},
  };
  group('lifecycle graph', () {
    for (final from in ConversationTaskStatus.values) {
      for (final to in ConversationTaskStatus.values) {
        test('${from.name} -> ${to.name}', () {
          final task = taskFixture(status: from);
          ConversationTask transition() => task.transitionTo(
            to,
            at: taskTime,
            lease: to == ConversationTaskStatus.running ? taskLease() : null,
            waitingReason:
                to == ConversationTaskStatus.waitingForUser
                    ? TaskWaitingReason.approval
                    : null,
            terminalSummary:
                {
                      ConversationTaskStatus.failed,
                      ConversationTaskStatus.cancelled,
                    }.contains(to)
                    ? taskTerminal(to)
                    : null,
            cancellationSource:
                to == ConversationTaskStatus.cancelRequested
                    ? TaskCancellationSource.user
                    : null,
          );
          if (allowed[from]!.contains(to)) {
            final next = transition();
            expect(next.status, to);
            expect(next.revision, task.revision + 1);
            expect(task.status, from);
            expect(
              next.resultMessageId,
              to.isTerminal ? 'task-1:result' : null,
            );
          } else {
            expect(transition, throwsStateError);
          }
        });
      }
    }
  });

  test(
    'cancellation survives a reconciliation wait and cannot restart work',
    () {
      final cancelling = taskFixture().transitionTo(
        ConversationTaskStatus.cancelRequested,
        at: taskTime,
        cancellationSource: TaskCancellationSource.user,
      );
      final waiting = cancelling.transitionTo(
        ConversationTaskStatus.waitingForUser,
        at: taskTime,
        waitingReason: TaskWaitingReason.reconciliation,
      );
      expect(waiting.cancelRequestedAt, taskTime);
      expect(
        () =>
            waiting.transitionTo(ConversationTaskStatus.running, at: taskTime),
        throwsStateError,
      );
      final cancelled = waiting
          .transitionTo(ConversationTaskStatus.cancelRequested, at: taskTime)
          .transitionTo(
            ConversationTaskStatus.cancelled,
            at: taskTime,
            terminalSummary: taskTerminal(ConversationTaskStatus.cancelled),
          );
      expect(cancelled.cancellationSource, TaskCancellationSource.user);
    },
  );

  test(
    'rejects stale transitions, unsupported terminal summaries and unknown cancellation effects',
    () {
      expect(
        () => taskFixture().transitionTo(
          ConversationTaskStatus.running,
          at: taskTime.subtract(const Duration(microseconds: 1)),
        ),
        throwsStateError,
      );
      expect(
        () => taskFixture().transitionTo(
          ConversationTaskStatus.failed,
          at: taskTime,
        ),
        throwsArgumentError,
      );
      expect(
        () => TaskTerminalSummary(
          status: ConversationTaskStatus.cancelled,
          reasonCode: TaskReasonCode.cancelled,
          safeReason: '取消',
          completedWorkSummary: '',
          sideEffectStatus: TaskSideEffectStatus.unknown,
          canRetry: false,
          cancellationSource: TaskCancellationSource.user,
        ),
        throwsArgumentError,
      );
    },
  );

  test('acceptance and checkpoints freeze nested input collections', () {
    final assets = ['asset:source'];
    final context = [
      TaskContextMessage(
        role: TaskContextRole.user,
        content: '报告',
        assetReferences: assets,
      ),
    ];
    final tools = {'read_file'};
    final snapshot = TaskAcceptanceSnapshot(
      providerId: 'provider',
      modelId: 'model',
      configurationDigest: 'digest',
      language: 'zh',
      context: context,
      allowedToolNames: tools,
      verification: taskAcceptance().verification,
      segmentLimits: TaskSegmentLimits(),
    );
    final completed = ['step-1'];
    final checkpoint = ConversationTaskCheckpoint(
      taskId: 'task-1',
      segmentId: 'segment-1',
      planRevision: 1,
      sequence: 1,
      phase: ConversationTaskPhase.observing,
      savedAt: taskTime,
      context: context,
      completedStepIds: completed,
    );
    assets.clear();
    context.clear();
    tools.clear();
    completed.clear();
    expect(snapshot.context.single.assetReferences, ['asset:source']);
    expect(snapshot.allowedToolNames, {'read_file'});
    expect(checkpoint.completedStepIds, ['step-1']);
    expect(() => snapshot.context.clear(), throwsUnsupportedError);
    expect(
      () => snapshot.context.single.assetReferences.add('secret'),
      throwsUnsupportedError,
    );
    expect(() => checkpoint.completedStepIds.clear(), throwsUnsupportedError);
  });

  test(
    'plan steps are distinct and frozen; progress is bounded and approval facts complete',
    () {
      final task = taskFixture();
      expect(() => taskPlan(task).steps.clear(), throwsUnsupportedError);
      expect(
        () => ConversationTaskPlan(
          taskId: task.taskId,
          revision: 1,
          objective: task.objective,
          steps: [
            TaskPlanStep(stepId: 'same', summary: 'one'),
            TaskPlanStep(stepId: 'same', summary: 'two'),
          ],
          allowedToolNames: {},
          createdAt: taskTime,
        ),
        throwsArgumentError,
      );
      expect(
        () => TaskProgress(
          completedSteps: 3,
          totalSteps: 2,
          lastMeaningfulProgressAt: taskTime,
        ),
        throwsArgumentError,
      );
      expect(
        () => TaskProgress(
          totalSteps: 2,
          lastMeaningfulProgressAt: taskTime,
          pendingApprovalId: 'approval',
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'lease has an exclusive expiry boundary and no task deadline semantics',
    () {
      final lease = taskLease();
      expect(
        lease.isValidAt(taskTime.subtract(const Duration(microseconds: 1))),
        isFalse,
      );
      expect(lease.isValidAt(taskTime), isTrue);
      expect(lease.isValidAt(lease.expiresAt), isFalse);
      expect(taskFixture(lease: lease).status, ConversationTaskStatus.queued);
      expect(
        () => taskFixture(lease: taskLease(taskId: 'other')),
        throwsArgumentError,
      );
    },
  );

  test('progress update cannot mix task identities or skip a revision', () {
    final next = taskFixture().transitionTo(
      ConversationTaskStatus.running,
      at: taskTime,
      lease: taskLease(),
    );
    final event = ConversationTaskEvent(
      taskId: next.taskId,
      sequence: 1,
      kind: TaskEventKind.started,
      occurredAt: taskTime,
      safeSummary: '开始',
    );
    expect(
      ConversationTaskProgressUpdate(
        task: next,
        event: event,
        expectedRevision: 0,
        lease: taskLease(),
        now: taskTime,
      ).task,
      next,
    );
    expect(
      () => ConversationTaskProgressUpdate(
        task: next,
        event: event,
        expectedRevision: 1,
        lease: taskLease(),
        now: taskTime,
      ),
      throwsArgumentError,
    );
    expect(
      () => ConversationTaskProgressUpdate(
        task: next,
        event: event,
        expectedRevision: 0,
        lease: taskLease(taskId: 'other'),
        now: taskTime,
      ),
      throwsArgumentError,
    );
  });

  test(
    'external jobs accept revocable local handles, not credentials or URLs',
    () {
      TaskExternalJob job(String handle) => TaskExternalJob(
        attemptId: 'attempt-1',
        externalJobId: 'job-1',
        resumeHandle: handle,
        safeStatus: 'queued',
        nextPollAt: taskTime,
      );
      expect(job('handle:job_1').resumeHandle, 'handle:job_1');
      expect(() => job('https://host/?api_key=secret'), throwsArgumentError);
      expect(() => job('Bearer secret'), throwsArgumentError);
    },
  );
}
