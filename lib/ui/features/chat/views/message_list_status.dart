part of 'message_list.dart';

class _MessageTerminalStatus extends StatelessWidget {
  const _MessageTerminalStatus({
    required this.outcome,
    required this.hasPartialContent,
  });

  final MessageTerminalOutcome outcome;
  final bool hasPartialContent;

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
        hasPartialContent
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
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCardSection extends StatelessWidget {
  final bool isDesktop;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? subtitleContent;
  final Widget? child;

  const _StatusCardSection({
    required this.isDesktop,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleContent,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isDesktop ? StarsDesktopThemeSpec.statusRadiusValue : 14.0;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusCardHeader(
          isDesktop: isDesktop,
          icon: icon,
          title: title,
          subtitle: subtitle,
          subtitleContent: subtitleContent,
        ),
        if (child != null) ...[const SizedBox(height: 12), child!],
      ],
    );

    if (isDesktop) {
      return ShadCard(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        backgroundColor: StarsDesktopTokens.of(context).controlFill,
        radius: BorderRadius.circular(radius),
        border: ShadBorder.all(color: StarsDesktopTokens.of(context).separator),
        child: content,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StarsDesktopTokens.of(context).controlFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: StarsDesktopTokens.of(context).separator),
      ),
      child: content,
    );
  }
}

class _StatusCardHeader extends StatelessWidget {
  final bool isDesktop;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? subtitleContent;

  const _StatusCardHeader({
    required this.isDesktop,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleContent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusHeaderIcon(
          key: const ValueKey<String>('execution-status-icon'),
          isDesktop: isDesktop,
          child: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:
                      (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14) -
                      1,
                ),
              ),
              const SizedBox(height: 2),
              subtitleContent ??
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: StarsDesktopTokens.of(context).secondaryText,
                      fontSize:
                          (Theme.of(context).textTheme.bodyMedium?.fontSize ??
                              12) -
                          1,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusHeaderIcon extends StatelessWidget {
  const _StatusHeaderIcon({
    super.key,
    required this.isDesktop,
    required this.child,
  });

  final bool isDesktop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius:
            isDesktop
                ? StarsDesktopThemeSpec.itemRadius
                : BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
