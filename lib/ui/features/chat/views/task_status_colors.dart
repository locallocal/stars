import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_task.dart';

/// Shared semantic colors for task badges, tool statuses, and history icons.
extension TaskStatusColors on ShadThemeData {
  Color taskStatusForeground(ConversationTaskStatus status) {
    final (light, dark) = switch (status) {
      ConversationTaskStatus.queued => (
        const Color(0xFF334155),
        const Color(0xFFCBD5E1),
      ),
      ConversationTaskStatus.running => (
        const Color(0xFF1D4ED8),
        const Color(0xFF93C5FD),
      ),
      ConversationTaskStatus.waitingForUser => (
        const Color(0xFF92400E),
        const Color(0xFFFCD34D),
      ),
      ConversationTaskStatus.paused => (
        const Color(0xFF6D28D9),
        const Color(0xFFC4B5FD),
      ),
      ConversationTaskStatus.cancelRequested => (
        const Color(0xFF9A3412),
        const Color(0xFFFDBA74),
      ),
      ConversationTaskStatus.succeeded => (
        const Color(0xFF166534),
        const Color(0xFF86EFAC),
      ),
      ConversationTaskStatus.failed => (
        const Color(0xFFB91C1C),
        const Color(0xFFFCA5A5),
      ),
      ConversationTaskStatus.cancelled => (
        colorScheme.secondaryForeground,
        colorScheme.secondaryForeground,
      ),
    };
    return brightness == Brightness.dark ? dark : light;
  }

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
