import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/utils/theme.dart';

Future<void> showConversationDirectoryDialog({
  required BuildContext context,
  required ConversationDirectoryViewModel viewModel,
  MessageActionViewModel? actionViewModel,
}) async {
  try {
    await showChatShadDialog<void>(
      context: context,
      builder:
          (dialogContext) => ConversationDirectoryDialog(
            viewModel: viewModel,
            actionViewModel: actionViewModel,
          ),
    );
  } finally {
    viewModel.dispose();
  }
}

final class ConversationDirectoryDialog extends StatelessWidget {
  const ConversationDirectoryDialog({
    super.key,
    required this.viewModel,
    this.actionViewModel,
  });

  final ConversationDirectoryViewModel viewModel;
  final MessageActionViewModel? actionViewModel;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final dialogHeight =
        (viewport.height * 0.68).clamp(360.0, 680.0).toDouble();
    final dialogWidth = (viewport.width - 32).clamp(280.0, 920.0).toDouble();
    return ShadDialog(
      key: const ValueKey<String>('conversation-directory-dialog'),
      title: Text(
        strings.conversationDirectory,
        style: StarsDesktopThemeSpec.pageTitleStyle(context),
      ),
      description: Text(strings.conversationDirectoryDescription),
      constraints: BoxConstraints(maxWidth: dialogWidth),
      closeIcon: StarsDesktopIconAction(
        key: const ValueKey<String>('conversation-directory-header-close'),
        icon: LucideIcons.x,
        label: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        ShadButton.outline(
          key: const ValueKey<String>('conversation-directory-close'),
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          height: dialogHeight,
          child: ConversationDirectoryBrowser(
            viewModel: viewModel,
            actionViewModel: actionViewModel,
          ),
        ),
      ),
    );
  }
}

/// Directory contents shared by the mobile dialog and desktop workspace page.
final class ConversationDirectoryBrowser extends StatefulWidget {
  const ConversationDirectoryBrowser({
    super.key,
    required this.viewModel,
    this.actionViewModel,
  });

  final ConversationDirectoryViewModel viewModel;
  final MessageActionViewModel? actionViewModel;

  @override
  State<ConversationDirectoryBrowser> createState() =>
      _ConversationDirectoryBrowserState();
}

final class _ConversationDirectoryBrowserState
    extends State<ConversationDirectoryBrowser> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_changed);
    unawaited(widget.viewModel.load());
  }

  @override
  void didUpdateWidget(covariant ConversationDirectoryBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel == widget.viewModel) return;
    oldWidget.viewModel.removeListener(_changed);
    widget.viewModel.addListener(_changed);
    _searchController.text = widget.viewModel.query;
    unawaited(widget.viewModel.load());
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_changed);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (_searchController.text != widget.viewModel.query) {
      _searchController.value = TextEditingValue(
        text: widget.viewModel.query,
        selection: TextSelection.collapsed(
          offset: widget.viewModel.query.length,
        ),
      );
    }
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    widget.viewModel.clearSearch();
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DirectoryToolbar(
          path: widget.viewModel.directoryPath,
          canNavigateUp: widget.viewModel.canNavigateUp,
          loading: widget.viewModel.loading,
          onNavigateUp: () => unawaited(widget.viewModel.navigateUp()),
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          query: widget.viewModel.query,
          onSearch: widget.viewModel.search,
          onClearSearch: _clearSearch,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _DirectoryEntriesPanel(
            count: widget.viewModel.visibleEntries.length,
            loading: widget.viewModel.loading,
            child: _buildContents(context),
          ),
        ),
      ],
    );
  }

  Widget _buildContents(BuildContext context) {
    final viewModel = widget.viewModel;
    if (viewModel.loading && viewModel.snapshot == null) {
      return const Center(child: SizedBox(width: 160, child: ShadProgress()));
    }
    if (viewModel.error case final error?) {
      return _DirectoryError(
        message: safeFailureMessage(context, error),
        onRetry: () => unawaited(viewModel.load()),
      );
    }

    final entries = viewModel.visibleEntries;
    if (entries.isEmpty) {
      return _DirectoryEmptyState(
        hasQuery: viewModel.query.trim().isNotEmpty,
        onClear: _clearSearch,
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        key: const ValueKey<String>('conversation-directory-list'),
        controller: _scrollController,
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final filePath = viewModel.filePathFor(entry);
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == entries.length - 1 ? 0 : 4,
            ),
            child: _DirectoryEntryRow(
              entry: entry,
              onOpen:
                  viewModel.loading
                      ? null
                      : entry.isDirectory
                      ? () => unawaited(viewModel.openDirectory(entry))
                      : filePath == null
                      ? null
                      : () => showLocalFilePreviewDialog(
                        context: context,
                        filePath: filePath,
                        actions: widget.actionViewModel,
                      ),
            ),
          );
        },
      ),
    );
  }
}

final class _DirectoryToolbar extends StatelessWidget {
  const _DirectoryToolbar({
    required this.path,
    required this.canNavigateUp,
    required this.loading,
    required this.onNavigateUp,
    required this.searchController,
    required this.searchFocusNode,
    required this.query,
    required this.onSearch,
    required this.onClearSearch,
  });

  final String path;
  final bool canNavigateUp;
  final bool loading;
  final VoidCallback onNavigateUp;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String query;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final pathField = _DirectoryPath(
      path: path,
      canNavigateUp: canNavigateUp,
      loading: loading,
      onNavigateUp: onNavigateUp,
    );
    final searchField = StarsSearchField(
      key: const ValueKey<String>('conversation-directory-search'),
      hintText: strings.searchConversationFiles,
      semanticLabel: strings.searchConversationFiles,
      controller: searchController,
      focusNode: searchFocusNode,
      onChanged: onSearch,
      insetFocusRing: true,
      suffixIcon:
          query.isEmpty
              ? null
              : StarsDesktopIconAction(
                key: const ValueKey<String>(
                  'conversation-directory-clear-search',
                ),
                icon: LucideIcons.x,
                label: strings.clearSearch,
                iconSize: 16,
                onPressed: onClearSearch,
              ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [pathField, const SizedBox(height: 10), searchField],
          );
        }
        return Row(
          children: [
            Expanded(child: pathField),
            const SizedBox(width: 12),
            SizedBox(width: 280, child: searchField),
          ],
        );
      },
    );
  }
}

final class _DirectoryEntriesPanel extends StatelessWidget {
  const _DirectoryEntriesPanel({
    required this.count,
    required this.loading,
    required this.child,
  });

  final int count;
  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      key: const ValueKey<String>('conversation-directory-entries'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                LucideIcons.files,
                size: 16,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context).fileCount(count.toString()),
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
        if (loading) const ShadProgress(),
        Expanded(child: child),
      ],
    );
  }
}

final class _DirectoryPath extends StatefulWidget {
  const _DirectoryPath({
    required this.path,
    required this.canNavigateUp,
    required this.loading,
    required this.onNavigateUp,
  });

  final String path;
  final bool canNavigateUp;
  final bool loading;
  final VoidCallback onNavigateUp;

  @override
  State<_DirectoryPath> createState() => _DirectoryPathState();
}

final class _DirectoryPathState extends State<_DirectoryPath> {
  late final TextEditingController _pathController;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: _displayPath);
  }

  @override
  void didUpdateWidget(covariant _DirectoryPath oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pathController.text == _displayPath) return;
    _pathController.value = TextEditingValue(text: _displayPath);
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  String get _displayPath => widget.path.isEmpty ? '…' : widget.path;

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.of(context);
    return Row(
      children: [
        StarsDesktopIconAction(
          key: const ValueKey<String>('conversation-directory-up'),
          icon: LucideIcons.arrowLeft,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          enabled: widget.canNavigateUp && !widget.loading,
          onPressed: widget.onNavigateUp,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ShadInput(
            key: const ValueKey<String>('conversation-directory-path'),
            controller: _pathController,
            readOnly: true,
            showCursor: false,
            maxLines: 1,
            style: StarsDesktopThemeSpec.metaStyle(context),
            padding: StarsDesktopThemeSpec.formFieldPadding,
            leading: SizedBox(
              width: 17,
              height: 44,
              child: Center(
                child: Icon(
                  LucideIcons.folderOpen,
                  size: 17,
                  color: shadTheme.colorScheme.mutedForeground,
                ),
              ),
            ),
            alignment: Alignment.centerLeft,
            crossAxisAlignment: CrossAxisAlignment.center,
            constraints: const BoxConstraints(
              minHeight: StarsDesktopThemeSpec.botFormFieldHeight,
            ),
          ),
        ),
      ],
    );
  }
}

final class _DirectoryEntryRow extends StatelessWidget {
  const _DirectoryEntryRow({required this.entry, this.onOpen});

  final ConversationDirectoryEntry entry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final metadata = <String>[
      if (entry.sizeBytes case final size?) _formatBytes(size, locale),
      DateFormat.yMd(locale).add_Hm().format(entry.modifiedAt.toLocal()),
    ];
    return Semantics(
      label: entry.name,
      hint: entry.isDirectory ? null : S.of(context).preview,
      button: onOpen != null,
      onTap: onOpen,
      child: ExcludeSemantics(
        child: ShadButton.ghost(
          key: ValueKey<String>('conversation-directory-${entry.relativePath}'),
          width: double.infinity,
          height: 0,
          expands: true,
          enabled: onOpen != null,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          mainAxisAlignment: MainAxisAlignment.start,
          onPressed: onOpen,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.controlFill,
                  borderRadius: StarsDesktopThemeSpec.itemRadius,
                ),
                alignment: Alignment.center,
                child: Icon(
                  entry.isDirectory ? LucideIcons.folder : LucideIcons.fileText,
                  size: 17,
                  color: tokens.secondaryText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StarsDesktopThemeSpec.bodyStyle(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metadata.join(' · '),
                      style: StarsDesktopThemeSpec.metaStyle(context),
                    ),
                  ],
                ),
              ),
              if (entry.isDirectory && onOpen != null) ...[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronRight,
                  size: 17,
                  color: tokens.secondaryText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _DirectoryEmptyState extends StatelessWidget {
  const _DirectoryEmptyState({required this.hasQuery, required this.onClear});

  final bool hasQuery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    if (hasQuery) {
      return StarsSearchEmptyState(
        key: const ValueKey<String>('conversation-directory-no-results'),
        message: strings.noConversationFilesFound,
        clearLabel: strings.clearSearch,
        onClear: onClear,
      );
    }
    return Center(
      key: const ValueKey<String>('conversation-directory-empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.folderOpen,
            size: 32,
            color: StarsDesktopThemeSpec.mutedText(context),
          ),
          const SizedBox(height: 10),
          Text(
            strings.conversationDirectoryEmpty,
            textAlign: TextAlign.center,
            style: StarsDesktopThemeSpec.bodyStyle(context),
          ),
        ],
      ),
    );
  }
}

final class _DirectoryError extends StatelessWidget {
  const _DirectoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('conversation-directory-error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.circleAlert,
            size: 28,
            color: StarsDesktopThemeSpec.error(context),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: StarsDesktopThemeSpec.bodyStyle(context),
          ),
          const SizedBox(height: 12),
          ShadButton.outline(
            key: const ValueKey<String>('conversation-directory-retry'),
            onPressed: onRetry,
            child: Text(S.of(context).retry),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes, String locale) {
  const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  final formatter = NumberFormat(
    value < 10 && unitIndex > 0 ? '0.0' : '0',
    locale,
  );
  return '${formatter.format(value)} ${units[unitIndex]}';
}
