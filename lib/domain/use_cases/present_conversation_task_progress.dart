import 'dart:async';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_list_item.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/use_cases/get_conversation_task_progress.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_progress.dart';

/// UI sees only committed summaries; ownership and selection live in Domain.
final class ObserveConversationTasks {
  const ObserveConversationTasks(
    this.repository, {
    this.clock = const SystemTaskRunnerClock(),
  });
  final TaskRunnerClock clock;
  final ConversationTaskRepository repository;
  Stream<List<ConversationTaskListItem>> call(
    String chatId, {
    bool refresh = false,
  }) => repository
      .watchForChat(chatId, refresh: refresh)
      .map(
        (values) =>
            List.unmodifiable(values.map((s) => s.observedAt(clock.now()))),
      );
}

final class SelectConversationTask {
  const SelectConversationTask(this.repository);
  final ConversationTaskRepository repository;
  Future<List<ConversationTaskProgressSummary>> call(
    String chatId, {
    String? taskId,
  }) async {
    final query = GetConversationTaskProgress(repository: repository);
    if (taskId != null) {
      final summary = await query(chatId: chatId, taskId: taskId);
      return summary == null ? const [] : [summary];
    }
    final active = await repository.listActiveForChat(chatId);
    final latest =
        active.isEmpty
            ? await repository.getLatestTerminalForChat(chatId)
            : null;
    return List.unmodifiable([
      for (final task in [...active, if (latest != null) latest])
        if (await query(chatId: chatId, taskId: task.taskId)
            case final summary?)
          summary,
    ]);
  }
}

/// Saves the model's completed reply with the exact facts it summarized.
/// Query data is never substituted for the reply, including on model failure.
final class PresentConversationTaskProgress {
  PresentConversationTaskProgress({
    required this.repository,
    required this.newId,
    NarrateConversationTaskProgress? narrate,
    this.polisher,
    DateTime Function()? now,
  }) : narrate = narrate ?? NarrateConversationTaskProgress(),
       now = now ?? DateTime.now;
  final ConversationTaskRepository repository;
  final String Function(String) newId;
  final DateTime Function() now;
  final NarrateConversationTaskProgress narrate;
  final TaskProgressPolisher? Function(String botId)? polisher;
  final Map<String, Future<Message>> _pending = {};

  Future<void> settle() async {
    await Future.wait(
      _pending.values.map((future) async {
        try {
          await future;
        } on Object {
          // The caller owns presentation and retry of a failed status request.
        }
      }),
    );
  }

  Future<Message> call({
    required String chatId,
    required String botId,
    required String language,
    String question = '',
    String? taskId,
    String? turnId,
    List<ConversationTaskProgressSummary>? summaries,
    AgentCancellationToken? cancellation,
  }) {
    final identity = turnId ?? newId('status-turn');
    final key = '$chatId:$identity';
    return _pending.putIfAbsent(
      key,
      () => _present(
        chatId: chatId,
        botId: botId,
        language: language,
        question: question,
        taskId: taskId,
        turnId: identity,
        summaries: summaries,
        cancellation: cancellation,
      ).whenComplete(() {
        _pending.remove(key);
      }),
    );
  }

  Future<Message> _present({
    required String chatId,
    required String botId,
    required String language,
    required String question,
    required String? taskId,
    required String turnId,
    required List<ConversationTaskProgressSummary>? summaries,
    required AgentCancellationToken? cancellation,
  }) async {
    final elapsed = Stopwatch()..start();
    cancellation?.throwIfCancelled();
    final selection = List<ConversationTaskProgressSummary>.unmodifiable(
      summaries ??
          await SelectConversationTask(repository)(chatId, taskId: taskId),
    );
    if (selection.any(
      (summary) =>
          summary.chatId != chatId ||
          taskId != null && summary.taskId != taskId,
    )) {
      throw ArgumentError(
        'Task progress must belong to the requested conversation.',
      );
    }
    final selected = selection.length == 1 ? selection.single : null;
    final queriedAt = now();
    final text = await narrate(
      chatId: chatId,
      summaries: selection,
      language: language,
      question: question,
      requestedTaskId: taskId,
      polish: polisher?.call(botId),
      cancellation: cancellation,
    );
    cancellation?.throwIfCancelled();
    final message = await repository.saveStatusMessage(
      Message(
        messageId: '$turnId:status',
        turnId: turnId,
        chatId: chatId,
        botId: botId,
        senderId: botId,
        content: text,
        taskMessageKind: TaskMessageKind.status,
        taskId: selected?.taskId,
        summaryRevision: selected?.summaryRevision,
        taskStatusSummaries: selection,
        timestamp: queriedAt,
      ),
    );
    narrate.metrics.cards++;
    narrate.metrics.cardLatency += elapsed.elapsed;
    return message;
  }
}
