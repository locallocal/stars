import 'dart:async';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_list_item.dart';
import 'package:stars/domain/models/conversation_task_execution.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart'
    show ObserveConversationTasks;
import 'package:stars/domain/use_cases/prepare_conversation_task_retry.dart';
import 'package:stars/domain/use_cases/get_conversation_task_execution.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';
import 'package:stars/ui/features/chat/view_models/task_execution_presentation.dart';

enum ConversationTaskSort { oldestFirst, newestFirst }

final class ConversationTaskExecutionState {
  ConversationTaskExecutionState({
    this.data,
    this.loading = false,
    this.error = false,
  }) : presentation = data == null ? null : TaskExecutionPresentation(data);

  ConversationTaskExecutionState._withStatus(
    ConversationTaskExecutionState? previous, {
    this.loading = false,
    this.error = false,
  }) : data = previous?.data,
       presentation = previous?.presentation;

  final ConversationTaskExecution? data;
  final TaskExecutionPresentation? presentation;
  final bool loading, error;
}

typedef TaskRetryDispatcher =
    Future<void> Function(
      ConversationTaskRetryDraft draft,
      String input,
      String language,
      VerificationPolicySnapshot verification,
    );

final class ConversationTasksState {
  ConversationTasksState({
    List<ConversationTaskListItem> summaries = const [],
    Set<String> pendingCommands = const {},
    this.loading = true,
    this.error = false,
  }) : summaries = List.unmodifiable(summaries),
       pendingCommands = Set.unmodifiable(pendingCommands);
  final List<ConversationTaskListItem> summaries;
  final Set<String> pendingCommands;
  final bool loading, error;
}

/// Observes durable facts. Disposal releases subscriptions only; tasks belong
/// to the app scheduler, and ordinary chat input never changes their objective.
final class ConversationTasksViewModel extends DisposableChangeNotifier {
  static const pageSize = 20;
  static const detailCacheCapacity = 40;

  ConversationTasksViewModel({
    required this.chatId,
    required this.botId,
    required this.observe,
    required this.commands,
    required this.prepareRetry,
    this.dispatchRetry,
    this.retryAvailable,
    GetConversationTaskExecution? getExecution,
  }) : getExecution =
           getExecution ?? GetConversationTaskExecution(observe.repository);
  final String chatId, botId;
  final ObserveConversationTasks observe;
  final ConversationTaskCommands commands;
  final PrepareConversationTaskRetry prepareRetry;
  final TaskRetryDispatcher? dispatchRetry;
  final bool Function()? retryAvailable;
  final GetConversationTaskExecution getExecution;
  final _execution = <String, ConversationTaskExecutionState>{};
  Set<String> _expandedTaskIds = {};

  ConversationTaskExecutionState executionFor(String taskId) =>
      _execution[taskId] ?? ConversationTaskExecutionState(loading: true);

  ConversationTaskProgressSummary? detailsFor(String taskId) =>
      _execution[taskId]?.data?.summary?.observedAt(observe.clock.now());

  /// Expansion is view state; loading and refresh ownership stay in the VM.
  void setExpandedTasks(Iterable<String> ids) {
    if (isDisposed) return;
    final expanded = ids.toSet();
    final changed =
        expanded.length != _expandedTaskIds.length ||
        !expanded.containsAll(_expandedTaskIds);
    _expandedTaskIds = expanded;
    if (changed) notifyListeners();
    _refreshExpandedExecutions();
  }

  void _refreshExpandedExecutions() {
    for (final summary in visibleSummaries) {
      if (_expandedTaskIds.contains(summary.taskId)) {
        unawaited(loadExecution(summary.taskId));
      }
    }
  }

  Future<void> loadExecution(String taskId, {bool force = false}) async {
    if (isDisposed || _execution[taskId]?.loading == true) return;
    final summary =
        state.summaries.where((s) => s.taskId == taskId).firstOrNull;
    if (summary == null) return;
    final previousState = _execution[taskId];
    final previous = previousState?.data;
    if (!force &&
        previous != null &&
        previousState?.error != true &&
        previous.revision >= summary.summaryRevision) {
      // Touch the entry without recreating the cached presentation.
      _execution[taskId] = _execution.remove(taskId)!;
      return;
    }
    final loading = ConversationTaskExecutionState._withStatus(
      previousState,
      loading: true,
    );
    _execution.remove(taskId);
    _execution[taskId] = loading;
    notifyListeners();
    try {
      final data = await getExecution(
        taskId: taskId,
        chatId: chatId,
        botId: botId,
      );
      if (isDisposed || !identical(_execution[taskId], loading)) return;
      _execution[taskId] =
          data == null
              ? ConversationTaskExecutionState._withStatus(
                previousState,
                error: true,
              )
              : ConversationTaskExecutionState(data: data);
      _trimExecutionCache();
      notifyListeners();
      // A live update can arrive while the database read is in flight.
      final latest =
          state.summaries.where((s) => s.taskId == taskId).firstOrNull;
      if (data != null &&
          latest != null &&
          latest.summaryRevision > summary.summaryRevision &&
          latest.summaryRevision > data.revision &&
          _expandedTaskIds.contains(taskId) &&
          visibleSummaries.any((s) => s.taskId == taskId)) {
        unawaited(loadExecution(taskId));
      }
    } on Object {
      if (isDisposed || !identical(_execution[taskId], loading)) return;
      _execution[taskId] = ConversationTaskExecutionState._withStatus(
        previousState,
        error: true,
      );
      _trimExecutionCache();
      notifyListeners();
    }
  }

  void _trimExecutionCache() {
    final visibleExpanded =
        visibleSummaries
            .map((s) => s.taskId)
            .where(_expandedTaskIds.contains)
            .toSet();
    for (final id in _execution.keys.toList()) {
      if (_execution.length <= detailCacheCapacity) break;
      if (!visibleExpanded.contains(id) && !_execution[id]!.loading) {
        _execution.remove(id);
      }
    }
  }

  String _query = '';
  ConversationTaskSort _sort = ConversationTaskSort.newestFirst;
  List<ConversationTaskListItem> _filteredSummaries = const [];
  int _pageIndex = 0;
  String get query => _query;
  ConversationTaskSort get sort => _sort;
  bool get canRetry =>
      dispatchRetry != null && (retryAvailable?.call() ?? true);
  int get filteredCount => _filteredSummaries.length;
  int get totalPages => (filteredCount + pageSize - 1) ~/ pageSize;
  int get currentPage => filteredCount == 0 ? 0 : _pageIndex + 1;
  bool get hasPreviousPage => _pageIndex > 0;
  bool get hasNextPage => _pageIndex + 1 < totalPages;
  int get firstVisibleItem =>
      filteredCount == 0 ? 0 : _pageIndex * pageSize + 1;
  int get lastVisibleItem =>
      ((_pageIndex + 1) * pageSize).clamp(0, filteredCount);

  List<ConversationTaskListItem> get visibleSummaries {
    return List.unmodifiable(
      _filteredSummaries.skip(_pageIndex * pageSize).take(pageSize),
    );
  }

  void _filterAndSort() {
    final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final result =
        state.summaries.where((summary) {
          final text =
              '${summary.title} ${summary.taskId} '
                      '${summary.currentStepSummary} '
                      '${summary.latestToolName}'
                  .toLowerCase();
          return terms.every(text.contains);
        }).toList();
    result.sort((a, b) {
      final time = a.createdAt.compareTo(b.createdAt);
      final order = time == 0 ? a.taskId.compareTo(b.taskId) : time;
      return sort == ConversationTaskSort.oldestFirst ? order : -order;
    });
    _filteredSummaries = List.unmodifiable(result);
    _pageIndex = totalPages == 0 ? 0 : _pageIndex.clamp(0, totalPages - 1);
  }

  void previousPage() {
    if (isDisposed || !hasPreviousPage) return;
    _pageIndex--;
    notifyListeners();
    _refreshExpandedExecutions();
  }

  void nextPage() {
    if (isDisposed || !hasNextPage) return;
    _pageIndex++;
    notifyListeners();
    _refreshExpandedExecutions();
  }

  void search(String value) {
    if (isDisposed || _query == value) return;
    _query = value;
    _pageIndex = 0;
    _filterAndSort();
    notifyListeners();
    _refreshExpandedExecutions();
  }

  void toggleSort() {
    if (isDisposed) return;
    _sort =
        sort == ConversationTaskSort.oldestFirst
            ? ConversationTaskSort.newestFirst
            : ConversationTaskSort.oldestFirst;
    _pageIndex = 0;
    _filterAndSort();
    notifyListeners();
    _refreshExpandedExecutions();
  }

  StreamSubscription<List<ConversationTaskListItem>>? _subscription;
  bool _observing = false;
  int _observationGeneration = 0;
  ConversationTasksState _state = ConversationTasksState();
  ConversationTasksState get state => _state;

  Future<void> refresh() => start(refresh: true);

  Future<void> start({bool refresh = false}) async {
    if (isDisposed ||
        (_observing && (state.loading || (!refresh && !state.error)))) {
      return;
    }
    _observing = true;
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
    _subscription = observe(chatId, refresh: refresh).listen(
      (summaries) {
        if (isDisposed || generation != _observationGeneration) return;
        _state = ConversationTasksState(
          summaries: summaries,
          pendingCommands: state.pendingCommands,
          loading: false,
        );
        _filterAndSort();
        final ids = summaries.map((s) => s.taskId).toSet();
        _execution.removeWhere((id, _) => !ids.contains(id));
        _expandedTaskIds.retainAll(ids);
        notifyListeners();
        _refreshExpandedExecutions();
      },
      onError: (Object _) {
        if (generation == _observationGeneration) _error();
      },
    );
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
