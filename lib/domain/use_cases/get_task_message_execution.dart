import 'package:stars/domain/models/conversation_task_execution.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_message_kind.dart';
import 'package:stars/domain/services/task_safe_data.dart';
import 'package:stars/domain/use_cases/get_conversation_task_execution.dart';

/// Read-only execution metadata for task replies, separate from persisted text
/// and token accounting. Progress replies retain the facts they summarized.
typedef TaskMessageExecution =
    ({MessageProcessInfo processInfo, ModelTokenUsage? tokenUsage});

/// Shared across page lifetimes. Only committed terminal executions and frozen
/// status-message snapshots are retained; running tasks are always refreshed.
final class GetTaskMessageExecution {
  GetTaskMessageExecution(this.getExecution, {this.cacheCapacity = 256})
    : assert(cacheCapacity > 0);

  final GetConversationTaskExecution Function() getExecution;
  final int cacheCapacity;
  final _completed = <_TaskKey, ConversationTaskExecution>{};
  final _pending = <_TaskKey, _ExecutionLoad>{};
  final _messages = <_MessageKey, _MessageExecution>{};

  /// Restores execution details and totals in the same frame as cached text.
  TaskMessageExecution? peek(Message message) {
    final key = _messageKey(message);
    final cached = _messages[key];
    if (cached != null && identical(cached.source, message)) {
      if (message.taskMessageKind == TaskMessageKind.result) {
        final taskKey = _taskKey(message);
        final execution = _completed.remove(taskKey);
        if (execution != null) _completed[taskKey] = execution;
      }
      _messages.remove(key);
      _messages[key] = cached;
      return cached.value;
    }
    if (message.taskMessageKind != TaskMessageKind.result) {
      final value = _project(message);
      return message.taskMessageKind == TaskMessageKind.status
          ? _remember(message, value)
          : value;
    }
    final taskKey = _taskKey(message);
    final execution = _completed.remove(taskKey);
    if (execution == null) return null;
    _completed[taskKey] = execution;
    return _remember(message, _project(message, execution));
  }

  Future<TaskMessageExecution> call(Message message) async {
    final cached = peek(message);
    if (cached != null) return cached;
    final key = _taskKey(message);
    final pending = _pending[key];
    final Future<ConversationTaskExecution?> future;
    if (pending != null) {
      future = pending.future;
    } else {
      final load = _ExecutionLoad();
      _pending[key] = load;
      future = load.future = _load(key, load);
    }
    final execution = await future;
    final value = _project(message, execution);
    return execution != null && identical(_completed[key], execution)
        ? _remember(message, value)
        : value;
  }

  Future<ConversationTaskExecution?> _load(
    _TaskKey key,
    _ExecutionLoad load,
  ) async {
    try {
      final execution = await getExecution()(
        taskId: key.taskId,
        chatId: key.chatId,
        botId: key.botId,
      );
      // Deletion/clearing must also fence reads already in flight.
      if (!identical(_pending[key], load)) return null;
      if (execution?.summary?.status.isTerminal == true) {
        _completed[key] = execution!;
        _trim(_completed);
      }
      return execution;
    } finally {
      if (identical(_pending[key], load)) _pending.remove(key);
    }
  }

  void clearChat(String chatId) {
    _completed.removeWhere((key, _) => key.chatId == chatId);
    _pending.removeWhere((key, _) => key.chatId == chatId);
    _messages.removeWhere((key, _) => key.chatId == chatId);
  }

  void clear() {
    _completed.clear();
    _pending.clear();
    _messages.clear();
  }

  TaskMessageExecution _remember(Message message, TaskMessageExecution value) {
    final key = _messageKey(message);
    _messages.remove(key);
    _messages[key] = _MessageExecution(message, value);
    _trim(_messages);
    return value;
  }

  void _trim<T>(Map<T, Object> cache) {
    while (cache.length > cacheCapacity) {
      cache.remove(cache.keys.first);
    }
  }

  TaskMessageExecution _project(
    Message message, [
    ConversationTaskExecution? taskExecution,
  ]) {
    final original = message.processInfo;
    final MessageProcessInfo? execution;
    final ModelTokenUsage? tokenUsage;
    switch (message.taskMessageKind) {
      case TaskMessageKind.result:
        execution = taskExecution?.processInfo;
        tokenUsage = taskExecution?.tokenUsage;
      case TaskMessageKind.status:
        final summaries = message.taskStatusSummaries;
        if (summaries.isEmpty) return (processInfo: original, tokenUsage: null);
        tokenUsage =
            summaries.every((summary) => summary.progress.tokenUsage != null)
                ? ModelTokenUsage.sum(
                  summaries.map((summary) => summary.progress.tokenUsage!),
                )
                : null;
        final summary = summaries.length == 1 ? summaries.single : null;
        execution = MessageProcessInfo(
          durationMs:
              summary?.updatedAt.difference(summary.createdAt).inMilliseconds,
          toolCalls: List.unmodifiable([
            for (final summary in summaries)
              if (summary.progress.latestTool case final tool?)
                MessageToolCall(
                  attemptId: tool.attemptId,
                  name: taskSafeText(tool.name),
                  status: tool.status.name,
                  resultSummary: taskSafeText(tool.safeSummary),
                ),
          ]),
        );
      case TaskMessageKind.acknowledgement:
      case TaskMessageKind.directReply:
      case null:
        return (processInfo: original, tokenUsage: null);
    }
    if (execution == null) {
      return (processInfo: original, tokenUsage: tokenUsage);
    }
    return (
      tokenUsage: tokenUsage,
      processInfo: MessageProcessInfo(
        reasoningStatus: original.reasoningStatus,
        durationMs: execution.durationMs ?? original.durationMs,
        toolCalls:
            execution.toolCalls.isEmpty
                ? original.toolCalls
                : execution.toolCalls,
        commandExecutions:
            execution.commandExecutions.isEmpty
                ? original.commandExecutions
                : execution.commandExecutions,
        fileEdits: original.fileEdits,
        skillActivations: original.skillActivations,
      ),
    );
  }
}

typedef _TaskKey = ({String taskId, String chatId, String botId});
typedef _MessageKey = ({String messageId, String chatId, String botId});

_TaskKey _taskKey(Message message) => (
  taskId: message.taskId!,
  chatId: message.chatId,
  botId: message.botId,
);

_MessageKey _messageKey(Message message) => (
  messageId: message.messageId,
  chatId: message.chatId,
  botId: message.botId,
);

final class _ExecutionLoad {
  late final Future<ConversationTaskExecution?> future;
}

final class _MessageExecution {
  const _MessageExecution(this.source, this.value);
  final Message source;
  final TaskMessageExecution value;
}
