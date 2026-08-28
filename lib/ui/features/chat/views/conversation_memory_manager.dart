part of 'conversation_memory_panel.dart';

final class _MemoryManagerDialog extends StatefulWidget {
  const _MemoryManagerDialog({required this.viewModel});

  final ConversationMemoryViewModel viewModel;

  @override
  State<_MemoryManagerDialog> createState() => _MemoryManagerDialogState();
}

final class _MemoryManagerDialogState extends State<_MemoryManagerDialog> {
  String _query = '';
  String? _actionError;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_changed);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_actionError != null) setState(() => _actionError = null);
    try {
      await action();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _actionError = safeFailureMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final items = widget.viewModel.items
        .where(
          (item) =>
              normalized.isEmpty ||
              item.content.toLowerCase().contains(normalized) ||
              item.memoryKey.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
    final tokens = StarsDesktopTokens.of(context);
    return ShadDialog(
      key: const ValueKey<String>('conversation-memory-manager-dialog'),
      title: Text(
        S.of(context).manageMemory,
        style: StarsDesktopThemeSpec.pageTitleStyle(context),
      ),
      description: Text(S.of(context).automaticSummaryWarning),
      constraints: const BoxConstraints(maxWidth: 760),
      actions: [
        ShadButton.raw(
          variant: ShadButtonVariant.outline,
          foregroundColor: tokens.danger,
          onPressed:
              () =>
                  unawaited(_runAction(widget.viewModel.clearAutomaticMemory)),
          leading: const Icon(LucideIcons.trash2, size: 16),
          child: Text(S.of(context).clearAutomaticMemory),
        ),
        ShadButton.outline(
          enabled: !widget.viewModel.compacting,
          onPressed:
              widget.viewModel.compacting
                  ? null
                  : () => unawaited(
                    _runAction(() async {
                      await widget.viewModel.compactNow(rebuild: true);
                    }),
                  ),
          leading:
              widget.viewModel.compacting
                  ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(LucideIcons.refreshCw, size: 16),
          child: Text(S.of(context).rebuildMemory),
        ),
        ShadButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
      child: SizedBox(
        height: 520,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StarsSearchField(
                key: const ValueKey<String>('memory-search-input'),
                hintText: S.of(context).searchMemory,
                onChanged: (value) => setState(() => _query = value),
              ),
              if (_actionError case final error?) ...[
                const SizedBox(height: 10),
                Text(
                  error,
                  key: const ValueKey<String>('memory-action-error'),
                  style: (StarsDesktopThemeSpec.metaStyle(context) ??
                          const TextStyle())
                      .copyWith(color: tokens.danger),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 4),
                  children: [
                    if (widget.viewModel.summary case final summary?) ...[
                      _SummaryMemoryCard(summary: summary),
                      if (items.isNotEmpty) const SizedBox(height: 10),
                    ],
                    for (var index = 0; index < items.length; index++) ...[
                      _MemoryItemTile(
                        item: items[index],
                        viewModel: widget.viewModel,
                        runAction: _runAction,
                      ),
                      if (index != items.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SummaryMemoryCard extends StatelessWidget {
  const _SummaryMemoryCard({required this.summary});

  final ConversationSummaryDocument summary;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    return ShadCard(
      key: const ValueKey<String>('memory-summary-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      backgroundColor: tokens.controlFill,
      border: ShadBorder.all(color: tokens.separator, width: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              LucideIcons.fileText,
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
                  S.of(context).conversationSummary,
                  style: StarsDesktopThemeSpec.bodyStyle(
                    context,
                  )?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  summary.markdown,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: StarsDesktopThemeSpec.metaStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MemoryItemTile extends StatelessWidget {
  const _MemoryItemTile({
    required this.item,
    required this.viewModel,
    required this.runAction,
  });

  final ConversationMemoryItem item;
  final ConversationMemoryViewModel viewModel;
  final Future<void> Function(Future<void> Function()) runAction;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final locale = Localizations.localeOf(context).toString();
    final updatedAt = DateFormat.yMd(
      locale,
    ).add_Hm().format(item.updatedAt.toLocal());
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          item.content,
          style: StarsDesktopThemeSpec.bodyStyle(
            context,
          )?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ShadBadge.outline(child: Text(_kindLabel(context, item.kind))),
            ShadBadge.outline(
              child: Text('${(item.confidence * 100).round()}%'),
            ),
            Text(updatedAt, style: StarsDesktopThemeSpec.metaStyle(context)),
          ],
        ),
      ],
    );
    final actions = Wrap(
      spacing: 2,
      children: [
        _MemoryIconAction(
          key: ValueKey<String>('memory-pin-${item.id}'),
          label:
              item.state == ConversationMemoryItemState.pinned
                  ? S.of(context).unpinMemory
                  : S.of(context).pinMemory,
          icon:
              item.state == ConversationMemoryItemState.pinned
                  ? LucideIcons.pinOff
                  : LucideIcons.pin,
          onPressed:
              () => unawaited(
                runAction(
                  () => viewModel.saveItem(
                    item,
                    state:
                        item.state == ConversationMemoryItemState.pinned
                            ? ConversationMemoryItemState.active
                            : ConversationMemoryItemState.pinned,
                  ),
                ),
              ),
        ),
        _MemoryIconAction(
          key: ValueKey<String>('memory-edit-${item.id}'),
          label: S.of(context).editMemory,
          icon: LucideIcons.pencil,
          onPressed: () => _edit(context),
        ),
        _MemoryIconAction(
          key: ValueKey<String>('memory-forget-${item.id}'),
          label:
              item.state == ConversationMemoryItemState.forgotten
                  ? S.of(context).restoreMemory
                  : S.of(context).forgetMemory,
          icon:
              item.state == ConversationMemoryItemState.forgotten
                  ? LucideIcons.rotateCcw
                  : LucideIcons.eyeOff,
          foregroundColor:
              item.state == ConversationMemoryItemState.forgotten
                  ? null
                  : tokens.danger,
          onPressed:
              () => unawaited(
                runAction(
                  () =>
                      item.state == ConversationMemoryItemState.forgotten
                          ? viewModel.restoreItem(item)
                          : viewModel.forgetItem(item),
                ),
              ),
        ),
      ],
    );
    return ShadCard(
      key: ValueKey<String>('memory-item-${item.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      backgroundColor: tokens.raisedSurface,
      border: ShadBorder.all(color: tokens.separator, width: 1),
      child: LayoutBuilder(
        builder:
            (context, constraints) =>
                constraints.maxWidth >= 480
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 12),
                        actions,
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        details,
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: actions,
                        ),
                      ],
                    ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(text: item.content);
    final value = await showChatShadDialog<String>(
      context: context,
      builder:
          (dialogContext) => ShadDialog(
            key: ValueKey<String>('memory-edit-dialog-${item.id}'),
            title: Text(
              S.of(dialogContext).editMemory,
              style: StarsDesktopThemeSpec.pageTitleStyle(dialogContext),
            ),
            constraints: const BoxConstraints(maxWidth: 560),
            actions: [
              ShadButton.outline(
                key: ValueKey<String>('memory-edit-cancel-${item.id}'),
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              ShadButton(
                key: ValueKey<String>('memory-edit-save-${item.id}'),
                onPressed:
                    () => Navigator.pop(dialogContext, controller.text.trim()),
                child: Text(S.of(dialogContext).save),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ShadInput(
                key: ValueKey<String>('memory-edit-input-${item.id}'),
                controller: controller,
                minLines: 4,
                maxLines: 6,
              ),
            ),
          ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      await runAction(() => viewModel.saveItem(item, content: value));
    }
  }
}

final class _MemoryIconAction extends StatelessWidget {
  const _MemoryIconAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) => StarsDesktopIconAction(
    icon: icon,
    label: label,
    iconSize: 16,
    foregroundColor: foregroundColor,
    onPressed: onPressed,
  );
}

String _statusLabel(
  BuildContext context,
  ConversationCompactionStatus? status,
) => switch (status) {
  ConversationCompactionStatus.background => S.of(context).compactingContext,
  ConversationCompactionStatus.synchronous => S.of(context).compactingContext,
  ConversationCompactionStatus.failed => S.of(context).compactionFailed,
  _ => S.of(context).idle,
};

String _kindLabel(BuildContext context, ConversationMemoryKind kind) =>
    switch (kind) {
      ConversationMemoryKind.fact => S.of(context).memoryFact,
      ConversationMemoryKind.preference => S.of(context).memoryPreference,
      ConversationMemoryKind.decision => S.of(context).memoryDecision,
      ConversationMemoryKind.openTask => S.of(context).memoryTask,
      ConversationMemoryKind.unresolvedQuestion => S.of(context).memoryQuestion,
      ConversationMemoryKind.artifactReference => S.of(context).memoryArtifact,
      ConversationMemoryKind.correction => S.of(context).memoryCorrection,
    };
