import 'dart:async';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart'
    show ObserveConversationTasks;
import 'package:stars/domain/use_cases/prepare_conversation_task_retry.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

enum ConversationTaskSort { oldestFirst, newestFirst }

typedef TaskRetryDispatcher =
    Future<void> Function(
      ConversationTaskRetryDraft draft,
      String input,
      String language,
      VerificationPolicySnapshot verification,
    );

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
    required this.commands,
    required this.prepareRetry,
    this.dispatchRetry,
    this.retryAvailable,
  });
  final String chatId, botId;
  final ObserveConversationTasks observe;
  final ConversationTaskCommands commands;
  final PrepareConversationTaskRetry prepareRetry;
  final TaskRetryDispatcher? dispatchRetry;
  final bool Function()? retryAvailable;
  String _query = '';
  ConversationTaskSort _sort = ConversationTaskSort.oldestFirst;
  String get query => _query;
  ConversationTaskSort get sort => _sort;
  bool get canRetry =>
      dispatchRetry != null && (retryAvailable?.call() ?? true);
  List<ConversationTaskProgressSummary> get visibleSummaries {
    final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final result =
        state.summaries.where((summary) {
          final text =
              '${summary.title} ${summary.taskId} '
                      '${summary.progress.currentStepSummary} '
                      '${summary.progress.latestTool?.name ?? ''}'
                  .toLowerCase();
          return terms.every(text.contains);
        }).toList();
    result.sort((a, b) {
      final time = a.createdAt.compareTo(b.createdAt);
      final order = time == 0 ? a.taskId.compareTo(b.taskId) : time;
      return sort == ConversationTaskSort.oldestFirst ? order : -order;
    });
    return List.unmodifiable(result);
  }

  void search(String value) {
    if (isDisposed || _query == value) return;
    _query = value;
    notifyListeners();
  }

  void toggleSort() {
    if (isDisposed) return;
    _sort =
        sort == ConversationTaskSort.oldestFirst
            ? ConversationTaskSort.newestFirst
            : ConversationTaskSort.oldestFirst;
    notifyListeners();
  }

  StreamSubscription<List<ConversationTaskProgressSummary>>? _subscription;
  int _observationGeneration = 0;
  ConversationTasksState _state = ConversationTasksState();
  ConversationTasksState get state => _state;

  Future<void> start() async {
    if (isDisposed) return;
    final generation = ++_observationGeneration;
    final previous = _subscription;
    _subscription = null;
    _state = ConversationTasksState(
      summaries: state.summaries,
      pendingCommands: state.pendingCommands,
    );
    notifyListeners();
    await previous?.cancel();
    if (isDisposed || generation != _observationGeneration) return;
    _subscription = observe(chatId).listen((summaries) {
      if (isDisposed || generation != _observationGeneration) return;
      _state = ConversationTasksState(
        summaries: summaries,
        pendingCommands: state.pendingCommands,
        loading: false,
      );
      notifyListeners();
    }, onError: (Object _) => _error());
  }

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

  Future<void> retryReviewed({
    required ConversationTaskRetryDraft draft,
    required String input,
    required String language,
    required VerificationPolicySnapshot verification,
  }) => _command(draft.taskId, () async {
    if (!canRetry || input.trim().isEmpty) return false;
    // Revalidate scope and side effects after the review dialog closes.
    await prepareRetry(chatId: chatId, botId: botId, taskId: draft.taskId);
    await dispatchRetry!(draft, input, language, verification);
    return true;
  });

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
      pendingCommands: state.pendingCommands,
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
