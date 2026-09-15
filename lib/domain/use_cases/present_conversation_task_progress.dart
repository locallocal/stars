import 'dart:async';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
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
  Stream<List<ConversationTaskProgressSummary>> call(String chatId) =>
      repository
          .watchForChat(chatId)
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

/// Saves the deterministic reply first. Optional narration updates that same
/// message asynchronously, independent of foreground/page lifetime.
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
  final Set<Future<void>> _pending = {};
  Future<void> settle() => Future.wait(_pending.toList());

  Future<Message> call({
    required String chatId,
    required String botId,
    required String language,
    String? taskId,
    String? turnId,
    List<ConversationTaskProgressSummary>? summaries,
  }) async {
    final elapsed = Stopwatch()..start();
    final selection =
        summaries ??
        await SelectConversationTask(repository)(chatId, taskId: taskId);
    final selected = selection.length == 1 ? selection.single : null;
    final words = TaskProgressStrings(language);
    final text =
        selected != null
            ? narrate.policy.alternatives(selected, language).first
            : selection.isNotEmpty
            ? words.choose
            : taskId == null
            ? words.noTasks
            : words.notFound;
    final identity = turnId ?? newId('status-turn');
    final message = await repository.saveStatusMessage(
      Message(
        messageId: '$identity:status',
        turnId: identity,
        chatId: chatId,
        botId: botId,
        senderId: botId,
        content: text,
        taskMessageKind: TaskMessageKind.status,
        taskId: selected?.taskId,
        summaryRevision: selected?.summaryRevision,
        taskStatusSummaries: selection,
        timestamp: now(),
      ),
    );
    narrate.metrics.cards++;
    narrate.metrics.cardLatency += elapsed.elapsed;
    if (message.taskStatusSummaries.length == 1) {
      late Future<void> pending;
      pending = _polish(
        message,
        language,
      ).whenComplete(() => _pending.remove(pending));
      _pending.add(pending);
    }
    return message;
  }

  Future<void> _polish(Message message, String language) async {
    try {
      final text = await narrate(
        summary: message.taskStatusSummaries.single,
        language: language,
        polish: polisher?.call(message.botId),
      );
      if (!await repository.updateStatusNarration(
        message.copyWith(content: text),
      )) {
        narrate.metrics.stale++;
      }
    } on Object {
      /* The already-committed deterministic card remains usable. */
    }
  }
}
