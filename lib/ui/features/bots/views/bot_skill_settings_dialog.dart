import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/bots/views/bot_capability_controls.dart';
import 'package:stars/utils/theme.dart';

/// Persists a Skill setting and returns its resolved value.
typedef BotSkillSettingUpdater = Future<bool> Function(bool value);

/// Opens the configuration surface for one Bot Skill.
///
/// Setting updates are applied immediately. Each updater returns the resolved
/// value so the dialog can reconcile optimistic state after persistence.
Future<void> showBotSkillSettingsDialog({
  required BuildContext context,
  required SkillDescriptor skill,
  required bool embedded,
  required bool isEnabled,
  required bool isApprovalExempt,
  required Key dialogKey,
  required Key closeButtonKey,
  required Key enabledSwitchKey,
  required Key approvalSwitchKey,
  BotSkillSettingUpdater? onEnabledChanged,
  BotSkillSettingUpdater? onApprovalExemptChanged,
}) async {
  final dialog = _BotSkillSettingsDialog(
    skill: skill,
    embedded: embedded,
    isEnabled: isEnabled,
    isApprovalExempt: isApprovalExempt,
    dialogKey: dialogKey,
    closeButtonKey: closeButtonKey,
    enabledSwitchKey: enabledSwitchKey,
    approvalSwitchKey: approvalSwitchKey,
    onEnabledChanged: onEnabledChanged,
    onApprovalExemptChanged: onApprovalExemptChanged,
  );
  if (embedded) {
    await showShadDialog<void>(context: context, builder: (_) => dialog);
    return;
  }
  await showDialog<void>(context: context, builder: (_) => dialog);
}

/// A Skill summary row matching the selected MCP Server row interaction.
class BotSkillSummaryRow extends StatelessWidget {
  const BotSkillSummaryRow({
    super.key,
    required this.skill,
    required this.embedded,
    required this.isEnabled,
    required this.isApprovalExempt,
    required this.onOpen,
    this.removeButtonKey,
    this.onRemove,
  });

  final SkillDescriptor skill;
  final bool embedded;
  final bool isEnabled;
  final bool isApprovalExempt;
  final VoidCallback onOpen;
  final Key? removeButtonKey;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final summary = _statusSummary(
      strings,
      isEnabled: isEnabled,
      isApprovalExempt: isApprovalExempt,
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: (embedded
                          ? ShadTheme.of(context).textTheme.small
                          : Theme.of(context).textTheme.titleSmall)
                      ?.copyWith(color: StarsDesktopThemeSpec.text(context)),
                ),
                const SizedBox(height: 3),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      embedded
                          ? StarsDesktopThemeSpec.metaStyle(context)
                          : Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            embedded ? LucideIcons.chevronRight : Icons.chevron_right_rounded,
            size: embedded ? 16 : 20,
          ),
          const SizedBox(width: 8),
          if (onRemove != null)
            embedded
                ? StarsDesktopIconAction(
                  key: removeButtonKey,
                  icon: LucideIcons.trash2,
                  label: strings.removeSkill,
                  iconSize: 16,
                  onPressed: onRemove,
                )
                : IconButton(
                  key: removeButtonKey,
                  tooltip: strings.removeSkill,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: skill.name,
      hint: strings.skillDetails,
      child: InkWell(
        onTap: onOpen,
        borderRadius: ShadTheme.of(context).radius,
        child: content,
      ),
    );
  }
}

class _BotSkillSettingsDialog extends StatefulWidget {
  const _BotSkillSettingsDialog({
    required this.skill,
    required this.embedded,
    required this.isEnabled,
    required this.isApprovalExempt,
    required this.dialogKey,
    required this.closeButtonKey,
    required this.enabledSwitchKey,
    required this.approvalSwitchKey,
    required this.onEnabledChanged,
    required this.onApprovalExemptChanged,
  });

  final SkillDescriptor skill;
  final bool embedded;
  final bool isEnabled;
  final bool isApprovalExempt;
  final Key dialogKey;
  final Key closeButtonKey;
  final Key enabledSwitchKey;
  final Key approvalSwitchKey;
  final BotSkillSettingUpdater? onEnabledChanged;
  final BotSkillSettingUpdater? onApprovalExemptChanged;

  @override
  State<_BotSkillSettingsDialog> createState() =>
      _BotSkillSettingsDialogState();
}

class _BotSkillSettingsDialogState extends State<_BotSkillSettingsDialog> {
  late bool _isEnabled;
  late bool _isApprovalExempt;
  var _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.isEnabled;
    _isApprovalExempt = widget.isApprovalExempt;
  }

  Future<void> _setEnabled(bool value) async {
    final update = widget.onEnabledChanged;
    if (update == null || _isUpdating) return;
    final previous = _isEnabled;
    setState(() {
      _isEnabled = value;
      _isUpdating = true;
    });
    var resolved = previous;
    try {
      resolved = await update(value);
    } finally {
      if (mounted) {
        setState(() {
          _isEnabled = resolved;
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _setApprovalExempt(bool value) async {
    final update = widget.onApprovalExemptChanged;
    if (update == null || _isUpdating || !_isEnabled) return;
    final previous = _isApprovalExempt;
    setState(() {
      _isApprovalExempt = value;
      _isUpdating = true;
    });
    var resolved = previous;
    try {
      resolved = await update(value);
    } finally {
      if (mounted) {
        setState(() {
          _isApprovalExempt = resolved;
          _isUpdating = false;
        });
      }
    }
  }

  void _close() {
    if (!_isUpdating) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return widget.embedded
        ? _buildDesktopDialog(context)
        : _buildDialog(context);
  }

  Widget _buildDesktopDialog(BuildContext context) {
    final strings = S.of(context);
    return ShadDialog(
      key: widget.dialogKey,
      closeIcon: StarsDesktopIconAction(
        key: widget.closeButtonKey,
        icon: LucideIcons.x,
        iconSize: 18,
        label: MaterialLocalizations.of(context).closeButtonTooltip,
        enabled: !_isUpdating,
        onPressed: _close,
      ),
      closeIconPosition: ShadPosition.directional(
        top: 12,
        end: 8,
        textDirection: Directionality.of(context),
      ),
      title: Text(
        widget.skill.name,
        style: TextStyle(color: StarsDesktopThemeSpec.text(context)),
      ),
      description: Text(strings.skillDetails),
      constraints: const BoxConstraints(maxWidth: 680),
      actions: [
        ShadButton.outline(
          enabled: !_isUpdating,
          onPressed: _close,
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
      child: _buildBody(context),
    );
  }

  Widget _buildDialog(BuildContext context) {
    return AlertDialog(
      key: widget.dialogKey,
      title: Text(widget.skill.name),
      content: SizedBox(width: 560, child: _buildBody(context)),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : _close,
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final strings = S.of(context);
    final details = Row(
      key: const ValueKey<String>('bot-skill-settings-details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            widget.embedded
                ? LucideIcons.wandSparkles
                : Icons.auto_awesome_rounded,
            size: 18,
            color: StarsDesktopThemeSpec.mutedText(context),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            widget.skill.description.isEmpty
                ? strings.skillDetails
                : widget.skill.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style:
                widget.embedded
                    ? StarsDesktopThemeSpec.metaStyle(context)
                    : Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
    final controls =
        widget.embedded
            ? BotCapabilityControls(
              key: const ValueKey<String>('bot-skill-settings-controls'),
              enabledSwitchKey: widget.enabledSwitchKey,
              approvalSwitchKey: widget.approvalSwitchKey,
              isEnabled: _isEnabled,
              isApprovalExempt: _isApprovalExempt,
              enabledLabel: strings.skillEnabled,
              disabledLabel: strings.skillDisabled,
              approvalExemptLabel: strings.mcpNoApprovalRequired,
              onEnabledChanged:
                  widget.onEnabledChanged != null && !_isUpdating
                      ? _setEnabled
                      : null,
              onApprovalExemptChanged:
                  widget.onApprovalExemptChanged != null &&
                          _isEnabled &&
                          !_isUpdating
                      ? _setApprovalExempt
                      : null,
            )
            : Wrap(
              key: const ValueKey<String>('bot-skill-settings-controls'),
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _isEnabled ? strings.skillEnabled : strings.skillDisabled,
                    ),
                    Switch(
                      key: widget.enabledSwitchKey,
                      value: _isEnabled,
                      onChanged:
                          widget.onEnabledChanged != null && !_isUpdating
                              ? _setEnabled
                              : null,
                    ),
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(strings.mcpNoApprovalRequired),
                    Switch(
                      key: widget.approvalSwitchKey,
                      value: _isApprovalExempt,
                      onChanged:
                          widget.onApprovalExemptChanged != null &&
                                  _isEnabled &&
                                  !_isUpdating
                              ? _setApprovalExempt
                              : null,
                    ),
                  ],
                ),
              ],
            );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: controls,
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: details),
              const SizedBox(width: 16),
              controls,
            ],
          );
        },
      ),
    );
  }
}

String _statusSummary(
  S strings, {
  required bool isEnabled,
  required bool isApprovalExempt,
}) {
  if (!isEnabled) return strings.skillDisabled;
  if (!isApprovalExempt) return strings.skillEnabled;
  return '${strings.skillEnabled} · ${strings.mcpNoApprovalRequired}';
}
