import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shared keyboard-operable action for the desktop and mobile theme hosts.
final class TaskActionButton extends StatelessWidget {
  const TaskActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.ghost = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool ghost;
  @override
  Widget build(BuildContext context) {
    if (ShadTheme.maybeOf(context) == null) {
      return OutlinedButton(onPressed: onPressed, child: Text(label));
    }
    return ghost
        ? ShadButton.ghost(
          size: ShadButtonSize.sm,
          enabled: onPressed != null,
          onPressed: onPressed,
          child: Text(label),
        )
        : ShadButton.outline(
          size: ShadButtonSize.sm,
          enabled: onPressed != null,
          onPressed: onPressed,
          child: Text(label),
        );
  }
}
