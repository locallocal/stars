import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/utils/theme.dart';

/// Shared semantic colors for task badges, tool statuses, and history icons.
extension TaskStatusColors on ShadThemeData {
  Color taskStatusForeground(ConversationTaskStatus status) => switch (status) {
    ConversationTaskStatus.queued =>
      brightness == Brightness.dark
          ? const Color(0xFFCBD5E1)
          : const Color(0xFF334155),
    ConversationTaskStatus.running => StarsStatusTone.info.foregroundFor(this),
    ConversationTaskStatus.waitingForUser => StarsStatusTone.warning
        .foregroundFor(this),
    ConversationTaskStatus.paused =>
      brightness == Brightness.dark
          ? const Color(0xFFC4B5FD)
          : const Color(0xFF6D28D9),
    ConversationTaskStatus.cancelRequested =>
      brightness == Brightness.dark
          ? const Color(0xFFFDBA74)
          : const Color(0xFF9A3412),
    ConversationTaskStatus.succeeded => StarsStatusTone.success.foregroundFor(
      this,
    ),
    ConversationTaskStatus.failed => StarsStatusTone.danger.foregroundFor(this),
    ConversationTaskStatus.cancelled => colorScheme.secondaryForeground,
  };

  Color taskStatusBackground(ConversationTaskStatus status) =>
      status == ConversationTaskStatus.cancelled
          ? colorScheme.secondary
          : Color.alphaBlend(
            taskStatusForeground(
              status,
            ).withValues(alpha: brightness == Brightness.dark ? 0.16 : 0.10),
            colorScheme.card,
          );

  ({Color foreground, Color background}) toolStatusBadgeColors(String status) {
    final taskStatus = switch (status) {
      'succeeded' ||
      'completed' ||
      'created' ||
      'attached' ||
      'activated' ||
      'duplicateReused' => ConversationTaskStatus.succeeded,
      'running' || 'streaming' => ConversationTaskStatus.running,
      'requested' => ConversationTaskStatus.queued,
      'awaitingApproval' ||
      'interrupted' => ConversationTaskStatus.waitingForUser,
      'failed' ||
      'error' ||
      'denied' ||
      'timedOut' ||
      'duplicateConflict' => ConversationTaskStatus.failed,
      'cancelled' || 'skipped' => ConversationTaskStatus.cancelled,
      _ => null,
    };
    return taskStatus == null
        ? (
          foreground: colorScheme.mutedForeground,
          background: colorScheme.secondary,
        )
        : (
          foreground: taskStatusForeground(taskStatus),
          background: taskStatusBackground(taskStatus),
        );
  }
}
