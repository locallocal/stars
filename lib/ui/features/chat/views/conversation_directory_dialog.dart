import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';
import 'package:stars/utils/theme.dart';

Future<void> showConversationDirectoryDialog({
  required BuildContext context,
  required ConversationDirectoryViewModel viewModel,
}) async {
  try {
    await showChatShadDialog<void>(
      context: context,
      builder:
          (dialogContext) => ConversationDirectoryDialog(viewModel: viewModel),
    );
  } finally {
    viewModel.dispose();
  }
}

final class ConversationDirectoryDialog extends StatefulWidget {
  const ConversationDirectoryDialog({super.key, required this.viewModel});

  final ConversationDirectoryViewModel viewModel;

  @override
  State<ConversationDirectoryDialog> createState() =>
      _ConversationDirectoryDialogState();
}

final class _ConversationDirectoryDialogState
    extends State<ConversationDirectoryDialog> {
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
  void didUpdateWidget(covariant ConversationDirectoryDialog oldWidget) {
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
    final strings = S.of(context);
    return ShadDialog(
      key: const ValueKey<String>('conversation-directory-dialog'),
      title: Text(
        strings.conversationDirectory,
        style: StarsDesktopThemeSpec.pageTitleStyle(context),
      ),
      description: Text(strings.conversationDirectoryDescription),
      constraints: const BoxConstraints(maxWidth: 760),
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
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DirectoryPath(
                path: widget.viewModel.directoryPath,
                canNavigateUp: widget.viewModel.canNavigateUp,
                loading: widget.viewModel.loading,
                onNavigateUp: () => unawaited(widget.viewModel.navigateUp()),
              ),
              const SizedBox(height: 12),
              StarsSearchField(
                key: const ValueKey<String>('conversation-directory-search'),
                hintText: strings.searchConversationFiles,
                semanticLabel: strings.searchConversationFiles,
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: widget.viewModel.search,
                insetFocusRing: true,
                suffixIcon:
                    widget.viewModel.query.isEmpty
                        ? null
                        : StarsDesktopIconAction(
                          key: const ValueKey<String>(
                            'conversation-directory-clear-search',
                          ),
                          icon: LucideIcons.x,
                          label: strings.clearSearch,
                          iconSize: 16,
                          onPressed: _clearSearch,
                        ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildContents(context)),
            ],
          ),
        ),
      ),
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
      child: ListView.separated(
        key: const ValueKey<String>('conversation-directory-list'),
        controller: _scrollController,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const ShadSeparator.horizontal(),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _DirectoryEntryRow(
            entry: entry,
            onOpen:
                entry.isDirectory && !viewModel.loading
                    ? () => unawaited(viewModel.openDirectory(entry))
                    : null,
          );
        },
      ),
    );
  }
}

final class _DirectoryPath extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    return Row(
      children: [
        StarsDesktopIconAction(
          key: const ValueKey<String>('conversation-directory-up'),
          icon: LucideIcons.arrowLeft,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          enabled: canNavigateUp && !loading,
          onPressed: onNavigateUp,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            key: const ValueKey<String>('conversation-directory-path'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.controlFill,
              borderRadius: StarsDesktopThemeSpec.itemRadius,
              border: Border.all(color: tokens.separator),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.folderOpen,
                  size: 17,
                  color: tokens.secondaryText,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: SelectableText(
                    path.isEmpty ? '…' : path,
                    maxLines: 2,
                    style: StarsDesktopThemeSpec.metaStyle(context),
                  ),
                ),
              ],
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
      button: entry.isDirectory,
      onTap: onOpen,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey<String>(
              'conversation-directory-${entry.relativePath}',
            ),
            borderRadius: StarsDesktopThemeSpec.itemRadius,
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
                      entry.isDirectory
                          ? LucideIcons.folder
                          : LucideIcons.fileText,
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
                  if (entry.isDirectory) ...[
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
