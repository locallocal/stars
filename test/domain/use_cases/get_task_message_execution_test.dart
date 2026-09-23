import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/get_conversation_task_execution.dart';
import 'package:stars/domain/use_cases/get_task_message_execution.dart';

import '../../support/conversation_task_fixtures.dart';

void main() {
  test(
    'result projects saved attempts without changing message accounting',
    () async {
      final task = taskFixture(
        status: ConversationTaskStatus.succeeded,
        progress: TaskProgress(
          totalSteps: 2,
          lastMeaningfulProgressAt: taskTime,
          tokenUsage: const ModelTokenUsage(inputTokens: 140, outputTokens: 26),
        ),
      );
      final repository = _ExecutionRepository(
        TaskExecutionSnapshot(
          task: task,
          plan: taskPlan(task),
          lastSequence: 0,
          attempts: [
            ToolExecutionRecord(
              executionId: 'execution-1',
              attemptId: 'attempt-1',
              runId: 'run-1',
              turnId: task.originTurnId,
              messageId: task.resultMessageId!,
              chatId: task.chatId,
              botId: task.botId,
              callId: 'call-1',
              name: 'run_shell_command',
              source: ToolSource.builtIn,
              riskLevel: ToolRiskLevel.readOnly,
              status: ToolInvocationStatus.succeeded,
              argumentsSummary: '{"command":"pwd"}',
              resultSummary: '/workspace',
              startedAt: taskTime,
              updatedAt: taskTime,
            ),
          ],
        ),
      );
      final project = GetTaskMessageExecution(
        () => GetConversationTaskExecution(repository),
      );
      final message = Message(
        messageId: task.resultMessageId!,
        taskId: task.taskId,
        taskMessageKind: TaskMessageKind.result,
        terminalOutcome: MessageTerminalOutcome.completed,
        chatId: task.chatId,
        botId: task.botId,
        senderId: task.botId,
        content: 'Report ready',
        tokenUsage: const ModelTokenUsage(inputTokens: 10, outputTokens: 5),
        timestamp: taskTime,
      );
      final execution = await project(message);
      final process = execution.processInfo;
      expect(execution.tokenUsage!.inputTokens, 140);
      expect(execution.tokenUsage!.outputTokens, 26);
      expect(process.toolCalls.single.status, 'succeeded');
      expect(process.toolCalls.single.resultSummary, '/workspace');
      expect(process.commandExecutions.single.command, 'pwd');
      expect(process.durationMs, 0);
      expect(message.processInfo.hasData, isFalse);
      expect(message.tokenUsage.inputTokens, 10);
      expect(message.content, 'Report ready');
      expect(repository.reads, 1);
      expect(project.peek(message), same(execution));
      await project(message.copyWith(content: 'Updated narration'));
      expect(repository.reads, 1);

      expect(
        (await project(message.copyWith(botId: 'other-bot'))).tokenUsage,
        isNull,
      );
      expect(
        (await project(message.copyWith(chatId: 'other-chat'))).tokenUsage,
        isNull,
      );
      repository.snapshot = null;
      project.clearChat(message.chatId);
      final unavailable = await project(message);
      expect(unavailable.processInfo, same(message.processInfo));
      expect(unavailable.tokenUsage, isNull);
    },
  );

  test(
    'concurrent requests share one read and failures can be retried',
    () async {
      final snapshot = _snapshot();
      final pending = Completer<TaskExecutionSnapshot?>();
      final repository = _ExecutionRepository(snapshot)
        ..read = () => pending.future;
      final project = GetTaskMessageExecution(
        () => GetConversationTaskExecution(repository),
      );
      final message = _result(snapshot);
      final first = project(message);
      final second = project(message);
      expect(repository.reads, 1);
      pending.completeError(StateError('temporarily unavailable'));
      await expectLater(Future.wait([first, second]), throwsStateError);
      expect(project.peek(message), isNull);

      repository.read = null;
      final recovered = await project(message);
      expect(recovered.tokenUsage!.inputTokens, 80);
      expect(repository.reads, 2);
      expect(project.peek(message), same(recovered));
    },
  );

  test(
    'running results and missing tasks are not frozen in the cache',
    () async {
      final repository = _ExecutionRepository(
        _snapshot(status: ConversationTaskStatus.running),
      );
      final project = GetTaskMessageExecution(
        () => GetConversationTaskExecution(repository),
      );
      final message = _result(repository.snapshot!);
      await project(message);
      expect(project.peek(message), isNull);
      repository.snapshot = null;
      expect((await project(message)).tokenUsage, isNull);
      repository.snapshot = _snapshot(inputTokens: 120);
      expect((await project(message)).tokenUsage!.inputTokens, 120);
      expect(repository.reads, 3);
    },
  );

  test(
    'clearing a chat fences an in-flight read and allows a fresh load',
    () async {
      final old = _snapshot();
      final pending = Completer<TaskExecutionSnapshot?>();
      final repository = _ExecutionRepository(old)..read = () => pending.future;
      final project = GetTaskMessageExecution(
        () => GetConversationTaskExecution(repository),
      );
      final message = _result(old);
      final loading = project(message);
      project.clearChat(message.chatId);
      repository
        ..read = null
        ..snapshot = _snapshot(inputTokens: 120);
      final fresh = await project(message);
      pending.complete(old);
      expect((await loading).tokenUsage, isNull);
      expect(project.peek(message), same(fresh));
      expect(fresh.tokenUsage!.inputTokens, 120);
      expect(repository.reads, 2);
    },
  );

  test(
    'execution cache keeps recently used tasks within its capacity',
    () async {
      final repository = _ExecutionRepository(null);
      final project = GetTaskMessageExecution(
        () => GetConversationTaskExecution(repository),
        cacheCapacity: 2,
      );
      final first = _result(_snapshot(id: 'task-1'));
      final second = _result(_snapshot(id: 'task-2'));
      final third = _result(_snapshot(id: 'task-3'));
      repository.snapshot = _snapshot(id: 'task-1');
      await project(first);
      repository.snapshot = _snapshot(id: 'task-2');
      await project(second);
      expect(project.peek(first), isNotNull);
      repository.snapshot = _snapshot(id: 'task-3');
      await project(third);
      expect(project.peek(second), isNull);
      expect(project.peek(first), isNotNull);
      expect(project.peek(third), isNotNull);
      expect(repository.reads, 3);
      project.clear();
      expect(project.peek(first), isNull);
    },
  );

  test(
    'progress uses its historical summary without reading the live task',
    () async {
      final summary = ConversationTaskProgressSummary(
        taskId: 'task-1',
        chatId: 'chat-1',
        title: 'Report',
        status: ConversationTaskStatus.running,
        phase: ConversationTaskPhase.executing,
        planRevision: 1,
        summaryRevision: 3,
        createdAt: taskTime,
        updatedAt: taskTime.add(const Duration(seconds: 12)),
        progress: TaskProgress(
          totalSteps: 2,
          lastMeaningfulProgressAt: taskTime,
          tokenUsage: const ModelTokenUsage(inputTokens: 100, outputTokens: 20),
          latestTool: TaskToolProgress(
            attemptId: 'attempt-1',
            name: 'read_file',
            status: ToolInvocationStatus.running,
            safeSummary: 'Reading report',
          ),
        ),
      );
      final project = GetTaskMessageExecution(
        () => throw StateError('Historical replies must not read live facts'),
      );
      final message = Message(
        messageId: 'question:status',
        taskId: summary.taskId,
        summaryRevision: summary.summaryRevision,
        taskMessageKind: TaskMessageKind.status,
        taskStatusSummaries: [summary],
        chatId: 'chat-1',
        botId: 'bot-1',
        senderId: 'bot-1',
        content: 'Still reading',
        timestamp: taskTime,
      );
      final execution = await project(message);
      final process = execution.processInfo;
      expect(execution.tokenUsage!.inputTokens, 100);
      expect(execution.tokenUsage!.outputTokens, 20);
      expect(process.durationMs, 12000);
      expect(process.toolCalls.single.status, 'running');
      expect(process.toolCalls.single.resultSummary, 'Reading report');
    },
  );

  for (final (usages, expected) in <(List<ModelTokenUsage?>, int?)>[
    ([ModelTokenUsage.empty], 0),
    ([null], null),
    (
      [
        const ModelTokenUsage(inputTokens: 40, outputTokens: 10),
        const ModelTokenUsage(inputTokens: 60, outputTokens: 15),
      ],
      100,
    ),
    ([const ModelTokenUsage(inputTokens: 40), null], null),
  ]) {
    test(
      'progress aggregates ${usages.length} usage reports as $expected',
      () async {
        final summaries = [
          for (final (index, usage) in usages.indexed)
            ConversationTaskProgressSummary(
              taskId: 'task-$index',
              chatId: 'chat-1',
              title: 'Report $index',
              status: ConversationTaskStatus.running,
              phase: ConversationTaskPhase.executing,
              planRevision: 1,
              summaryRevision: 3,
              updatedAt: taskTime,
              progress: TaskProgress(
                totalSteps: 2,
                lastMeaningfulProgressAt: taskTime,
                tokenUsage: usage,
              ),
            ),
        ];
        final message = Message(
          messageId: 'status',
          taskMessageKind: TaskMessageKind.status,
          taskStatusSummaries: summaries,
          chatId: 'chat-1',
          botId: 'bot-1',
          senderId: 'bot-1',
          content: 'Progress',
          timestamp: taskTime,
        );
        final execution = await GetTaskMessageExecution(
          () => throw StateError('Progress must use its snapshot'),
        )(message);
        expect(execution.tokenUsage?.inputTokens, expected);
        if (expected == 100) expect(execution.tokenUsage!.outputTokens, 25);
      },
    );
  }
}

final class _ExecutionRepository implements ConversationTaskRepository {
  _ExecutionRepository(this.snapshot);
  TaskExecutionSnapshot? snapshot;
  int reads = 0;
  Future<TaskExecutionSnapshot?> Function()? read;

  @override
  Future<TaskExecutionSnapshot?> getExecutionSnapshot(String taskId) async {
    reads++;
    return read == null ? snapshot : await read!();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Only execution history is read.');
}

TaskExecutionSnapshot _snapshot({
  String id = 'task-1',
  ConversationTaskStatus status = ConversationTaskStatus.succeeded,
  int inputTokens = 80,
}) {
  final task = taskFixture(
    id: id,
    status: status,
    progress: TaskProgress(
      totalSteps: 2,
      lastMeaningfulProgressAt: taskTime,
      tokenUsage: ModelTokenUsage(inputTokens: inputTokens),
    ),
  );
  return TaskExecutionSnapshot(
    task: task,
    plan: taskPlan(task),
    lastSequence: 0,
  );
}

Message _result(TaskExecutionSnapshot snapshot) => Message(
  messageId: '${snapshot.task.taskId}:result',
  chatId: snapshot.task.chatId,
  botId: snapshot.task.botId,
  senderId: snapshot.task.botId,
  taskId: snapshot.task.taskId,
  taskMessageKind: TaskMessageKind.result,
  terminalOutcome: MessageTerminalOutcome.completed,
  content: 'Done',
  timestamp: taskTime,
);
