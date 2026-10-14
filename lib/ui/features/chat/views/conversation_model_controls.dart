import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/utils/theme.dart';

const double _modelControlWidth = 44;

typedef ConversationPreferenceChanged = Future<void> Function(bool value);

/// Model and presentation controls shown in the conversation inspector.
final class ConversationModelControls extends StatelessWidget {
  const ConversationModelControls({
    super.key,
    required this.showReasoning,
    required this.showVerificationStatus,
    required this.showExecutionStatus,
    required this.strictGroundingMode,
    this.onShowReasoningChanged,
    this.onShowVerificationStatusChanged,
    this.onShowExecutionStatusChanged,
    this.onStrictGroundingModeChanged,
  });

  final bool showReasoning;
  final bool showVerificationStatus;
  final bool showExecutionStatus;
  final bool strictGroundingMode;
  final ConversationPreferenceChanged? onShowReasoningChanged;
  final ConversationPreferenceChanged? onShowVerificationStatusChanged;
  final ConversationPreferenceChanged? onShowExecutionStatusChanged;
  final ConversationPreferenceChanged? onStrictGroundingModeChanged;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _ModelControlRow(
        key: const ValueKey<String>('conversation-reasoning-row'),
        switchKey: const ValueKey<String>('conversation-reasoning-toggle'),
        icon: LucideIcons.brain,
        label: S.of(context).chatReasoning,
        description: S.of(context).showReasoningDescription,
        value: showReasoning,
        onChanged:
            onShowReasoningChanged == null
                ? null
                : (value) => unawaited(
                  _updatePreference(context, onShowReasoningChanged!, value),
                ),
      ),
      _ModelControlRow(
        key: const ValueKey<String>('conversation-verification-status-row'),
        switchKey: const ValueKey<String>(
          'conversation-verification-status-toggle',
        ),
        icon: LucideIcons.badgeCheck,
        label: S.of(context).chatVerificationStatus,
        description: S.of(context).showVerificationStatusDescription,
        value: showVerificationStatus,
        onChanged:
            onShowVerificationStatusChanged == null
                ? null
                : (value) => unawaited(
                  _updatePreference(
                    context,
                    onShowVerificationStatusChanged!,
                    value,
                  ),
                ),
      ),
      _ModelControlRow(
        key: const ValueKey<String>('conversation-execution-status-row'),
        switchKey: const ValueKey<String>(
          'conversation-execution-status-toggle',
        ),
        icon: LucideIcons.activity,
        label: S.of(context).chatExecutionStatus,
        description: S.of(context).showExecutionStatusDescription,
        value: showExecutionStatus,
        onChanged:
            onShowExecutionStatusChanged == null
                ? null
                : (value) => unawaited(
                  _updatePreference(
                    context,
                    onShowExecutionStatusChanged!,
                    value,
                  ),
                ),
      ),
      _ModelControlRow(
        key: const ValueKey<String>('conversation-strict-grounding-row'),
        switchKey: const ValueKey<String>(
          'conversation-strict-grounding-toggle',
        ),
        icon: LucideIcons.shieldCheck,
        label: S.of(context).strictGroundingMode,
        description: S.of(context).strictGroundingModeDescription,
        value: strictGroundingMode,
        onChanged:
            onStrictGroundingModeChanged == null
                ? null
                : (value) => unawaited(
                  _updatePreference(
                    context,
                    onStrictGroundingModeChanged!,
                    value,
                  ),
                ),
      ),
    ];
    return Column(
      key: const ValueKey<String>('conversation-model-controls'),
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          rows[index],
          if (index != rows.length - 1)
            const ShadSeparator.horizontal(
              margin: StarsDesktopThemeSpec.settingsRowSeparatorMargin,
            ),
        ],
      ],
    );
  }

  Future<void> _updatePreference(
    BuildContext context,
    ConversationPreferenceChanged onChanged,
    bool value,
  ) async {
    try {
      await onChanged(value);
    } on Object catch (error) {
      if (context.mounted) {
        showStarsNotice(
          context,
          safeFailureMessage(context, error),
          tone: StarsNoticeTone.error,
        );
      }
    }
  }
}

final class _ModelControlRow extends StatelessWidget {
  const _ModelControlRow({
    super.key,
    required this.switchKey,
    required this.icon,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final IconData icon;
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final toggle = ShadSwitch(
      key: switchKey,
      width: _modelControlWidth,
      value: value,
      enabled: onChanged != null,
      onChanged: onChanged,
    );
    return MergeSemantics(
      child: StarsInspectorInfoRow(
        icon: icon,
        label: label,
        description: description,
        crossAxisAlignment: CrossAxisAlignment.center,
        trailingWidth: _modelControlWidth,
        layout: StarsInspectorInfoRowLayout.settings,
        trailing: toggle,
      ),
    );
  }
}
