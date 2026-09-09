import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shadcn-styled controls shared by Bot Skills and MCP Tools.
class BotCapabilityControls extends StatelessWidget {
  const BotCapabilityControls({
    super.key,
    required this.enabledSwitchKey,
    required this.approvalSwitchKey,
    required this.isEnabled,
    required this.isApprovalExempt,
    required this.enabledLabel,
    required this.disabledLabel,
    required this.approvalExemptLabel,
    this.onEnabledChanged,
    this.onApprovalExemptChanged,
  });

  final Key enabledSwitchKey;
  final Key approvalSwitchKey;
  final bool isEnabled;
  final bool isApprovalExempt;
  final String enabledLabel;
  final String disabledLabel;
  final String approvalExemptLabel;
  final ValueChanged<bool>? onEnabledChanged;
  final ValueChanged<bool>? onApprovalExemptChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        ShadSwitch(
          key: enabledSwitchKey,
          value: isEnabled,
          enabled: onEnabledChanged != null,
          onChanged: onEnabledChanged,
          label: _StableStatusLabel(
            label: isEnabled ? enabledLabel : disabledLabel,
            alternatives: [enabledLabel, disabledLabel],
          ),
        ),
        ShadSwitch(
          key: approvalSwitchKey,
          value: isApprovalExempt,
          enabled: onApprovalExemptChanged != null,
          onChanged: onApprovalExemptChanged,
          label: Text(approvalExemptLabel),
        ),
      ],
    );
  }
}

class _StableStatusLabel extends StatelessWidget {
  const _StableStatusLabel({required this.label, required this.alternatives});

  final String label;
  final List<String> alternatives;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final width = alternatives.fold<double>(0, (widest, alternative) {
      final painter = TextPainter(
        text: TextSpan(text: alternative, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      return painter.width > widest ? painter.width : widest;
    });

    return SizedBox(width: width, child: Text(label, maxLines: 1));
  }
}
