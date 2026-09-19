import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/get_conversation_task_execution.dart';

import '../../support/task_runner_harness.dart';

void main() {
  for (final status in [
    ConversationTaskStatus.succeeded,
    ConversationTaskStatus.failed,
    ConversationTaskStatus.cancelled,
  ]) {
    test('terminal history exposes the committed $status outcome', () async {
      final task = taskFixture(status: status);
      final snapshot = TaskExecutionSnapshot(
        task: task,
        plan: taskPlan(task),
        lastSequence: 2,
        events: [
          for (final (index, kind)
              in [TaskEventKind.started, TaskEventKind.terminal].indexed)
            ConversationTaskEvent(
              taskId: task.taskId,
              sequence: index + 1,
              kind: kind,
              occurredAt: taskTime,
              safeSummary: 'Saved event',
            ),
        ],
      );
      final execution =
          (await GetConversationTaskExecution(_SnapshotRepository(snapshot))(
            taskId: task.taskId,
            chatId: task.chatId,
            botId: task.botId,
          ))!;
      expect(execution.activities.first.terminalStatus, isNull);
      expect(execution.activities.last.terminalStatus, status);
    });
  }

  test(
    'execution history keeps failed and successful attempts in event order after restart',
    () async {
      final h = TaskRunnerHarness();
      await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
      addTearDown(h.close);
      h.models.tool(arguments: {'path': 'report.md'});
      h.tool.onStart =
          (call) async => ToolCompleted(
            ToolResult(
              callId: call.callId,
              name: call.name,
              content: 'First attempt failed.',
              isError: true,
              errorCode: 'unavailable',
            ),
          );
      await h.run();
      await h.advanceToDue();
      await h.db.reopen();
      h.tool.onStart = null;
      await h.run();
      await h.db.reopen();
      final execution =
          (await GetConversationTaskExecution(h.db.repository)(
            taskId: 'task-1',
            chatId: 'chat-1',
            botId: 'bot-1',
          ))!;
      final calls = execution.processInfo.toolCalls;
      expect(calls.map((call) => call.status), ['failed', 'succeeded']);
      expect(calls.map((call) => call.attemptId).toSet(), hasLength(2));
      expect(calls.map((call) => call.invocationId).toSet(), hasLength(1));
      expect(calls.first.resultSummary, 'First attempt failed.');
      expect(calls.last.resultSummary, 'Read completed.');
      expect(
        calls.every((call) => call.argumentsSummary.contains('report.md')),
        isTrue,
      );
      expect(execution.processInfo.commandExecutions, isEmpty);
      expect(
        execution.activities.map((activity) => activity.event.kind),
        containsAllInOrder([
          TaskEventKind.stepStarted,
          TaskEventKind.toolQueued,
          TaskEventKind.toolStarted,
          TaskEventKind.toolFailed,
          TaskEventKind.toolRetry,
          TaskEventKind.toolStarted,
          TaskEventKind.toolSucceeded,
        ]),
      );
      expect(
        execution.activities
            .firstWhere((a) => a.event.kind == TaskEventKind.stepStarted)
            .subject,
        'Step 0',
      );
    },
  );
}

final class _SnapshotRepository implements ConversationTaskRepository {
  const _SnapshotRepository(this.snapshot);
  final TaskExecutionSnapshot snapshot;

  @override
  Future<TaskExecutionSnapshot?> getExecutionSnapshot(String taskId) async =>
      snapshot;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Only the execution snapshot is read.');
}
