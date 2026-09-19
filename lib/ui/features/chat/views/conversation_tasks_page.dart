import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/conversation_tasks_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_task_card.dart';
import 'package:stars/ui/features/chat/views/conversation_task_execution_section.dart';
import 'package:stars/utils/theme.dart';

/// Shares the directory page's width, spacing and workspace surface.
final class ConversationTasksPage extends StatefulWidget {
  const ConversationTasksPage({
    super.key,
    required this.viewModel,
    required this.onAction,
    this.embedded = true,
  });
  final ConversationTasksViewModel viewModel;
  final void Function(ConversationTaskProgressSummary, TaskCardAction) onAction;
  final bool embedded;

  @override
  State<ConversationTasksPage> createState() => _ConversationTasksPageState();
}

final class _ConversationTasksPageState extends State<ConversationTasksPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  final _expansionController = ShadAccordionController<String>.multiple();
  late (int, String, ConversationTaskSort) _listLocation;

  (int, String, ConversationTaskSort) get _currentListLocation => (
    widget.viewModel.currentPage,
    widget.viewModel.query,
    widget.viewModel.sort,
  );

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.viewModel.query;
    _listLocation = _currentListLocation;
    widget.viewModel.addListener(_handleViewModelChanged);
    _expansionController.addListener(_handleExpansionChanged);
  }

  @override
  void didUpdateWidget(covariant ConversationTasksPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_handleViewModelChanged);
      oldWidget.viewModel.setExpandedTasks(const []);
      widget.viewModel.addListener(_handleViewModelChanged);
      _expansionController.value = [];
      _searchController.text = widget.viewModel.query;
      _listLocation = _currentListLocation;
      _resetScroll();
    }
  }

  void _handleViewModelChanged() {
    final location = _currentListLocation;
    if (location != _listLocation) {
      _listLocation = location;
      _resetScroll();
    }
    final taskIds =
        widget.viewModel.state.summaries.map((s) => s.taskId).toSet();
    if (_expansionController.value.any((id) => !taskIds.contains(id))) {
      _expansionController.value =
          _expansionController.value.where(taskIds.contains).toList();
    }
  }

  void _handleExpansionChanged() {
    widget.viewModel.setExpandedTasks(_expansionController.value);
  }

  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_handleViewModelChanged);
    widget.viewModel.setExpandedTasks(const []);
    _expansionController.removeListener(_handleExpansionChanged);
    _expansionController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.viewModel.search('');
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final words = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final content = ColoredBox(
      key: const ValueKey('conversation-tasks-page'),
      color: StarsDesktopThemeSpec.workspaceSurface(context),
      child: Padding(
        padding:
            widget.embedded
                ? StarsDesktopThemeSpec.profilePagePadding
                : const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            key: const ValueKey('conversation-tasks-content'),
            constraints: const BoxConstraints(
              maxWidth: StarsDesktopThemeSpec.contentMaxWidth,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.embedded) ...[
                    Text(
                      words.tasks,
                      style: StarsDesktopThemeSpec.pageTitleStyle(context),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    words.pageDescription,
                    style: StarsDesktopThemeSpec.bodyStyle(context)?.copyWith(
                      color: StarsDesktopThemeSpec.mutedText(context),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: widget.viewModel,
                      builder: (context, _) => _browser(context, words),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return widget.embedded
        ? content
        : Scaffold(
          appBar: AppBar(title: Text(words.tasks)),
          body: SafeArea(top: false, child: content),
        );
  }

  Widget _browser(BuildContext context, TaskProgressStrings words) {
    final vm = widget.viewModel;
    final state = vm.state;
    final summaries = vm.visibleSummaries;
    final search = StarsSearchField(
      key: const ValueKey('conversation-tasks-search'),
      hintText: words.searchTasks,
      semanticLabel: words.searchTasks,
      controller: _searchController,
      focusNode: _searchFocus,
      onChanged: vm.search,
      insetFocusRing: true,
      suffixIcon:
          vm.query.isEmpty
              ? null
              : StarsDesktopIconAction(
                key: const ValueKey('conversation-tasks-clear-search'),
                icon: LucideIcons.x,
                label: S.of(context).clearSearch,
                onPressed: _clearSearch,
              ),
    );
    final sort = ShadButton.outline(
      key: const ValueKey('conversation-tasks-sort'),
      size: ShadButtonSize.sm,
      // Outline borders sit outside the button's configured content height.
      height: StarsDesktopThemeSpec.botFormFieldHeight - 2,
      leading: const Icon(LucideIcons.arrowUpDown, size: 16),
      onPressed: vm.toggleSort,
      child: Text(
        vm.sort == ConversationTaskSort.oldestFirst
            ? words.oldestFirst
            : words.newestFirst,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder:
              (context, constraints) =>
                  constraints.maxWidth < 600
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          search,
                          const SizedBox(height: 10),
                          Align(alignment: Alignment.centerRight, child: sort),
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(child: search),
                          const SizedBox(width: 12),
                          sort,
                        ],
                      ),
        ),
        const SizedBox(height: 16),
        if (state.error) ...[
          ShadAlert.destructive(
            key: const ValueKey('conversation-tasks-error'),
            icon: const Icon(LucideIcons.circleAlert),
            title: Text(words.commandFailed),
            description:
                state.summaries.isEmpty
                    ? ShadButton.outline(
                      key: const ValueKey('conversation-tasks-retry-load'),
                      size: ShadButtonSize.sm,
                      onPressed: vm.start,
                      child: Text(S.of(context).retry),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child:
              state.loading && state.summaries.isEmpty
                  ? const Center(
                    child: SizedBox(width: 120, child: ShadProgress()),
                  )
                  : state.error && state.summaries.isEmpty
                  ? const SizedBox.expand()
                  : summaries.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          vm.query.trim().isEmpty
                              ? LucideIcons.listTodo
                              : LucideIcons.searchX,
                          size: 28,
                          color: StarsDesktopThemeSpec.mutedText(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          vm.query.trim().isEmpty
                              ? words.noTasks
                              : words.noMatchingTasks,
                          key: const ValueKey('conversation-tasks-empty'),
                          textAlign: TextAlign.center,
                        ),
                        if (vm.query.isNotEmpty)
                          ShadButton.ghost(
                            onPressed: _clearSearch,
                            child: Text(S.of(context).clearSearch),
                          ),
                      ],
                    ),
                  )
                  : Scrollbar(
                    controller: _scrollController,
                    child: ListView.separated(
                      key: const ValueKey('conversation-tasks-list'),
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: summaries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final summary = summaries[index];
                        return ConversationTaskCard(
                          key: ValueKey('task-${summary.taskId}'),
                          summary: summary,
                          expansionController: _expansionController,
                          executionDetails:
                              _expansionController.value.contains(
                                    summary.taskId,
                                  )
                                  ? ConversationTaskExecutionSection(
                                    key: ValueKey(
                                      'task-execution-${summary.taskId}',
                                    ),
                                    state: vm.executionFor(summary.taskId),
                                    onRetry:
                                        () => vm.loadExecution(
                                          summary.taskId,
                                          force: true,
                                        ),
                                  )
                                  : null,
                          showStatusAction: false,
                          busy: state.pendingCommands.contains(summary.taskId),
                          refreshing: state.loading,
                          onRefresh: vm.start,
                          onAction:
                              (action) => widget.onAction(summary, action),
                        );
                      },
                    ),
                  ),
        ),
        if (vm.filteredCount > 0) ...[
          const SizedBox(height: 12),
          _TaskPagination(
            currentPage: vm.currentPage,
            totalPages: vm.totalPages,
            firstItem: vm.firstVisibleItem,
            lastItem: vm.lastVisibleItem,
            totalItems: vm.filteredCount,
            onPrevious: vm.hasPreviousPage ? vm.previousPage : null,
            onNext: vm.hasNextPage ? vm.nextPage : null,
          ),
        ],
      ],
    );
  }
}

final class _TaskPagination extends StatelessWidget {
  const _TaskPagination({
    required this.currentPage,
    required this.totalPages,
    required this.firstItem,
    required this.lastItem,
    required this.totalItems,
    this.onPrevious,
    this.onNext,
  });

  final int currentPage, totalPages, firstItem, lastItem, totalItems;
  final VoidCallback? onPrevious, onNext;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final range = Text(
      localizations.pageRowsInfoTitle(firstItem, lastItem, totalItems, false),
      key: const ValueKey('conversation-tasks-page-range'),
      style: ShadTheme.of(context).textTheme.muted,
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarsDesktopIconAction(
          key: const ValueKey('conversation-tasks-previous-page'),
          icon: LucideIcons.chevronLeft,
          label: localizations.previousPageTooltip,
          variant: ShadButtonVariant.outline,
          enabled: onPrevious != null,
          onPressed: onPrevious,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              '$currentPage / $totalPages',
              key: const ValueKey('conversation-tasks-page-indicator'),
              style: ShadTheme.of(context).textTheme.small,
            ),
          ),
        ),
        StarsDesktopIconAction(
          key: const ValueKey('conversation-tasks-next-page'),
          icon: LucideIcons.chevronRight,
          label: localizations.nextPageTooltip,
          variant: ShadButtonVariant.outline,
          enabled: onNext != null,
          onPressed: onNext,
        ),
      ],
    );
    return LayoutBuilder(
      builder:
          (context, constraints) =>
              constraints.maxWidth < 500
                  ? Column(
                    children: [range, const SizedBox(height: 8), controls],
                  )
                  : Row(
                    children: [
                      Expanded(child: range),
                      const SizedBox(width: 12),
                      controls,
                    ],
                  ),
    );
  }
}
