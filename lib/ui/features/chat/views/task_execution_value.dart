import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/services/task_progress_strings.dart';

/// A selectable audit value that participates in the outer task list's layout.
final class TaskExecutionValue extends StatefulWidget {
  const TaskExecutionValue({
    super.key,
    required this.label,
    required this.value,
  });
  final String label, value;

  @override
  State<TaskExecutionValue> createState() => _TaskExecutionValueState();
}

final class _TaskExecutionValueState extends State<TaskExecutionValue> {
  Timer? _reset;
  bool _copied = false, _failed = false;

  @override
  void didUpdateWidget(covariant TaskExecutionValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _reset?.cancel();
      _copied = _failed = false;
    }
  }

  Future<void> _copy() async {
    final value = widget.value;
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted || value != widget.value) return;
      setState(() {
        _copied = true;
        _failed = false;
      });
    } on Object {
      if (!mounted || value != widget.value) return;
      setState(() {
        _copied = false;
        _failed = true;
      });
    }
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = _failed = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final words = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.textTheme.muted.copyWith(
                    color: theme.colorScheme.mutedForeground,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Semantics(
                label: '${words.executionCopy} · ${widget.label}',
                liveRegion: _copied || _failed,
                child: ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Icon(
                    _copied ? LucideIcons.check : LucideIcons.copy,
                    size: 13,
                  ),
                  onPressed: _copy,
                  child: Text(
                    _failed
                        ? words.executionCopyFailed
                        : _copied
                        ? words.executionCopied
                        : words.executionCopy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectionArea(
            child: Text(
              widget.value,
              style: theme.textTheme.small.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.foreground,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
