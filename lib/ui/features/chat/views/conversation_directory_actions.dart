import 'dart:async';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_directory.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';

/// Entry actions shared by the full directory page and its compact dialog.
class ConversationDirectoryEntryMenu extends StatefulWidget {
  const ConversationDirectoryEntryMenu({
    super.key,
    required this.entry,
    required this.viewModel,
  });

  final ConversationDirectoryEntry entry;
  final ConversationDirectoryViewModel viewModel;

  @override
  State<ConversationDirectoryEntryMenu> createState() => _EntryMenuState();
}

class _EntryMenuState extends State<ConversationDirectoryEntryMenu> {
  final _controller = ShadPopoverController();
  final _focusNode = FocusNode(debugLabel: 'conversation-entry-actions');
  bool _restoreTriggerFocus = false;
  bool _choosingDestination = false;

  void _toggleMenu() {
    if (!_controller.isOpen) {
      // Restore keyboard focus without leaving a ring after pointer actions.
      _restoreTriggerFocus = _focusNode.hasFocus;
    }
    _controller.toggle();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _copyEntry() async {
    _controller.hide();
    if (widget.viewModel.busy || _choosingDestination) return;
    final viewModel = widget.viewModel;
    final entry = widget.entry;
    final strings = S.of(context);
    setState(() => _choosingDestination = true);
    try {
      final destination = await FilePicker.getDirectoryPath(
        dialogTitle: strings.chooseCopyDestination,
      );
      if (!mounted || destination == null || destination.isEmpty) return;
      final succeeded = await viewModel.copyEntry(entry, destination);
      if (!mounted) return;
      if (succeeded) {
        showStarsNotice(
          context,
          strings.entryCopySucceeded,
          tone: StarsNoticeTone.success,
        );
      } else if (viewModel.mutationError case final error?) {
        showStarsNotice(
          context,
          safeFailureMessage(context, error),
          tone: StarsNoticeTone.error,
        );
      }
    } on Object {
      if (mounted) {
        showStarsNotice(
          context,
          strings.entryCopyFailed,
          tone: StarsNoticeTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _choosingDestination = false);
        if (_restoreTriggerFocus) _focusNode.requestFocus();
      }
    }
  }

  Future<void> _showAction({required bool rename}) async {
    _controller.hide();
    if (widget.viewModel.busy) return;
    widget.viewModel.clearMutationError();
    await showChatShadDialog<void>(
      context: context,
      barrierDismissible: false,
      variant: rename ? ShadDialogVariant.primary : ShadDialogVariant.alert,
      returnFocusNode: _restoreTriggerFocus ? _focusNode : null,
      builder:
          (context) => _EntryActionDialog(
            entry: widget.entry,
            viewModel: widget.viewModel,
            rename: rename,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return ShadPopover(
      controller: _controller,
      anchor: const ShadAnchorAuto(
        offset: Offset(-12, 0),
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.bottomLeft,
        fallback: ShadAnchorAuto(
          offset: Offset(-12, 0),
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
        ),
      ),
      padding: const EdgeInsets.all(6),
      popover:
          (context) => SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EntryMenuItem(
                  key: const ValueKey('conversation-entry-rename'),
                  enabled: !widget.viewModel.busy && !_choosingDestination,
                  icon: LucideIcons.pencil,
                  label: strings.rename,
                  onPressed: () => unawaited(_showAction(rename: true)),
                ),
                _EntryMenuItem(
                  key: const ValueKey('conversation-entry-copy'),
                  enabled: !widget.viewModel.busy && !_choosingDestination,
                  icon: LucideIcons.copy,
                  label: MaterialLocalizations.of(context).copyButtonLabel,
                  onPressed: () => unawaited(_copyEntry()),
                ),
                _EntryMenuItem(
                  key: const ValueKey('conversation-entry-delete'),
                  enabled: !widget.viewModel.busy && !_choosingDestination,
                  icon: LucideIcons.trash2,
                  label: strings.delete,
                  destructive: true,
                  onPressed: () => unawaited(_showAction(rename: false)),
                ),
              ],
            ),
          ),
      child: StarsDesktopIconAction(
        key: ValueKey('conversation-entry-menu-${widget.entry.relativePath}'),
        icon: LucideIcons.ellipsis,
        label:
            '${MaterialLocalizations.of(context).showMenuTooltip}: ${widget.entry.name}',
        focusNode: _focusNode,
        enabled: !widget.viewModel.busy && !_choosingDestination,
        onPressed: _toggleMenu,
        hoverBackgroundColor: Colors.transparent,
      ),
    );
  }
}

class _EntryMenuItem extends StatelessWidget {
  const _EntryMenuItem({
    super.key,
    required this.enabled,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final bool enabled;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = ShadTheme.of(context).colorScheme;
    return ShadFocusable(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      builder:
          (context, focused, _) => ShadButton.ghost(
            enabled: enabled,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gap: 10,
            mainAxisAlignment: MainAxisAlignment.start,
            // Match Shad context-menu items: focus uses the accent background.
            decoration: const ShadDecoration(
              secondaryBorder: ShadBorder.none,
              secondaryFocusedBorder: ShadBorder.none,
            ),
            backgroundColor: focused ? colors.accent : null,
            foregroundColor: destructive ? colors.destructive : null,
            hoverForegroundColor: destructive ? colors.destructive : null,
            leading: Icon(icon, size: 16),
            onPressed: onPressed,
            child: Text(label, textAlign: TextAlign.start),
          ),
    );
  }
}

class _EntryActionDialog extends StatefulWidget {
  const _EntryActionDialog({
    required this.entry,
    required this.viewModel,
    required this.rename,
  });

  final ConversationDirectoryEntry entry;
  final ConversationDirectoryViewModel viewModel;
  final bool rename;

  @override
  State<_EntryActionDialog> createState() => _EntryActionDialogState();
}

class _EntryActionDialogState extends State<_EntryActionDialog> {
  final _formKey = GlobalKey<ShadFormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final name = widget.entry.name;
    final extension = name.lastIndexOf('.');
    _nameController = TextEditingController.fromValue(
      TextEditingValue(
        text: name,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset:
              !widget.entry.isDirectory && extension > 0
                  ? extension
                  : name.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.viewModel.busy) return;
    if (widget.rename && !_formKey.currentState!.validate()) {
      return;
    }
    final succeeded =
        widget.rename
            ? await widget.viewModel.renameEntry(
              widget.entry,
              _nameController.text.trim(),
            )
            : await widget.viewModel.deleteEntry(widget.entry);
    if (succeeded && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final strings = S.of(context);
      final busy = widget.viewModel.busy;
      final title =
          widget.rename
              ? strings.rename
              : widget.entry.isDirectory
              ? strings.deleteFolder
              : strings.deleteFile;
      return PopScope(
        canPop: !busy,
        child: ShadDialog.raw(
          variant:
              widget.rename
                  ? ShadDialogVariant.primary
                  : ShadDialogVariant.alert,
          key: ValueKey(
            widget.rename
                ? 'conversation-entry-rename-dialog'
                : 'conversation-entry-delete-dialog',
          ),
          constraints: const BoxConstraints(maxWidth: 440),
          title: Text(title),
          description:
              widget.rename
                  ? null
                  : Text(
                    widget.entry.isDirectory
                        ? strings.confirmDeleteFolder(widget.entry.name)
                        : strings.confirmDeleteFile(widget.entry.name),
                  ),
          closeIcon: const SizedBox.shrink(),
          actions: [
            ShadButton.outline(
              key: const ValueKey('conversation-entry-cancel'),
              enabled: !busy,
              autofocus: !widget.rename,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
            ShadButton.raw(
              key: const ValueKey('conversation-entry-confirm'),
              variant:
                  widget.rename
                      ? ShadButtonVariant.primary
                      : ShadButtonVariant.destructive,
              enabled: !busy,
              leading:
                  busy
                      ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : null,
              onPressed: () => unawaited(_submit()),
              child: Text(widget.rename ? strings.save : strings.delete),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.rename)
                ShadForm(
                  key: _formKey,
                  child: ShadInputFormField(
                    key: const ValueKey('conversation-entry-name'),
                    id: 'name',
                    controller: _nameController,
                    label: Text(strings.entryName),
                    autofocus: true,
                    enabled: !busy,
                    onChanged: (_) => widget.viewModel.clearMutationError(),
                    onSubmitted: (_) => unawaited(_submit()),
                    validator:
                        (value) =>
                            isValidConversationEntryName(value.trim())
                                ? null
                                : strings.entryNameInvalid,
                  ),
                ),
              if (widget.viewModel.mutationError case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: ShadAlert.destructive(
                      key: const ValueKey('conversation-entry-error'),
                      icon: const Icon(LucideIcons.circleAlert),
                      description: Text(safeFailureMessage(context, error)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
