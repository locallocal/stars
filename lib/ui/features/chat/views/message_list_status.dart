part of 'message_list.dart';

/// Keeps status controls usable in the mobile Material app as well as ShadApp.
class _MessageMetadata extends StatelessWidget {
  const _MessageMetadata({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: children,
    );
    if (ShadTheme.maybeOf(context) != null) return content;
    final materialTheme = Theme.of(context);
    return ShadTheme(
      data: buildStarsShadTheme(
        brightness: materialTheme.brightness,
        fontSize: materialTheme.textTheme.bodyLarge?.fontSize ?? 14,
        highContrast: MediaQuery.highContrastOf(context),
      ),
      child: content,
    );
  }
}

class _MessageTerminalStatus extends StatelessWidget {
  const _MessageTerminalStatus({
    required this.outcome,
    required this.hasPartialContent,
    required this.reasonCode,
  });

  final MessageTerminalOutcome outcome;
  final bool hasPartialContent;
  final String reasonCode;

  @override
  Widget build(BuildContext context) {
    final (icon, label, variant) = switch (outcome) {
      MessageTerminalOutcome.cancelled => (
        LucideIcons.square,
        hasPartialContent
            ? S.of(context).replyStoppedPartial
            : S.of(context).replyCancelled,
        ShadBadgeVariant.outline,
      ),
      MessageTerminalOutcome.failed => (
        LucideIcons.triangleAlert,
        reasonCode == 'model_turn_limit_reached'
            ? S.of(context).modelTurnLimitReached
            : hasPartialContent
            ? S.of(context).generationFailedPartial
            : S.of(context).generationFailed,
        ShadBadgeVariant.destructive,
      ),
      MessageTerminalOutcome.emptyResponse => (
        LucideIcons.circleSlash,
        S.of(context).noContentReturned,
        ShadBadgeVariant.outline,
      ),
      MessageTerminalOutcome.completed => (
        LucideIcons.check,
        hasPartialContent
            ? S.of(context).partialResponse
            : S.of(context).statusCompleted,
        ShadBadgeVariant.secondary,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: ShadBadge.raw(
          variant: variant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 6),
              Flexible(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}
