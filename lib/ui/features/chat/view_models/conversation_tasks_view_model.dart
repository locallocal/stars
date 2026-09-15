import 'dart:async';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
import 'package:stars/domain/use_cases/prepare_conversation_task_retry.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

final class ConversationTasksState {
  ConversationTasksState({
    List<ConversationTaskProgressSummary> summaries = const [],
    Set<String> pendingCommands = const {},
    this.loading = true,
    this.error = false,
  }) : summaries = List.unmodifiable(summaries),
       pendingCommands = Set.unmodifiable(pendingCommands);
  final List<ConversationTaskProgressSummary> summaries;
  final Set<String> pendingCommands;
  final bool loading, error;
}

/// Observes durable facts. Disposal releases subscriptions only; tasks belong
/// to the app scheduler, and ordinary chat input never changes their objective.
final class ConversationTasksViewModel extends DisposableChangeNotifier {
  ConversationTasksViewModel({
    required this.chatId,
    required this.botId,
    required this.observe,
    required this.present,
    required this.commands,
    required this.prepareRetry,
  });
  final String chatId, botId;
  final ObserveConversationTasks observe;
  final PresentConversationTaskProgress present;
  final ConversationTaskCommands commands;
  final PrepareConversationTaskRetry prepareRetry;
  StreamSubscription<List<ConversationTaskProgressSummary>>? _subscription;
  ConversationTasksState _state = ConversationTasksState();
  ConversationTasksState get state => _state;

  Future<void> start() async {
    await _subscription?.cancel();
    if (isDisposed) return;
    _subscription = observe(chatId).listen((summaries) {
      if (isDisposed) return;
      _state = ConversationTasksState(
        summaries: summaries,
        pendingCommands: state.pendingCommands,
        loading: false,
      );
      notifyListeners();
    }, onError: (Object _) => _error());
  }

  Future<void> query({required String language, String? taskId}) =>
      _command(taskId ?? '', () async {
        await present(
          chatId: chatId,
          botId: botId,
          language: language,
          taskId: taskId,
        );
        return true;
      });
  Future<void> cancel(ConversationTaskProgressSummary s) =>
      _command(s.taskId, () async {
        _scope(s);
        return await commands.cancel(
              taskId: s.taskId,
              expectedRevision: s.summaryRevision,
            )
            is TaskWriteCommitted<ConversationTask>;
      });
  Future<void> decide(
    ConversationTaskProgressSummary s,
    TaskApprovalDecision decision,
  ) => _command(s.taskId, () async {
    _scope(s);
    final id = s.progress.pendingApprovalId;
    if (id == null) return false;
    return await commands.decide(
          taskId: s.taskId,
          expectedRevision: s.summaryRevision,
          approvalId: id,
          decision: decision,
          actorId: 'me',
        )
        is TaskWriteCommitted<TaskApprovalRecord>;
  });
  Future<void> resume(ConversationTaskProgressSummary s) =>
      _command(s.taskId, () async {
        _scope(s);
        return await commands.resume(
              taskId: s.taskId,
              expectedRevision: s.summaryRevision,
            )
            is TaskWriteCommitted<ConversationTask>;
      });
  Future<ConversationTaskRetryDraft> retryDraft(
    ConversationTaskProgressSummary s,
  ) {
    _scope(s);
    return prepareRetry(chatId: chatId, botId: botId, taskId: s.taskId);
  }

  void _scope(ConversationTaskProgressSummary s) {
    if (s.chatId != chatId) {
      throw ArgumentError('Task belongs to another chat.');
    }
  }

  Future<void> _command(String id, Future<bool> Function() action) async {
    if (isDisposed || state.pendingCommands.contains(id)) return;
    _state = ConversationTasksState(
      summaries: state.summaries,
      loading: false,
      pendingCommands: {...state.pendingCommands, id},
    );
    notifyListeners();
    var failed = false;
    try {
      failed = !await action();
    } on Object {
      failed = true;
    }
    if (isDisposed) return;
    _state = ConversationTasksState(
      summaries: state.summaries,
      loading: false,
      error: failed,
      pendingCommands: {...state.pendingCommands}..remove(id),
    );
    notifyListeners();
  }

  void _error() {
    if (isDisposed) return;
    _state = ConversationTasksState(
      summaries: state.summaries,
      loading: false,
      error: true,
    );
    notifyListeners();
  }

  @override
  void disposeResources() {
    unawaited(_subscription?.cancel());
  }
}
