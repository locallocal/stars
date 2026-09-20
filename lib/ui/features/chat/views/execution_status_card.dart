import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/utils/theme.dart';

/// A borderless disclosure inside an existing task card. Its parent owns
/// scrolling; expanded content always uses its natural height.
class ExecutionDetailsDisclosure extends StatefulWidget {
  const ExecutionDetailsDisclosure({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    this.subtitle,
    this.header,
    this.summary,
    this.initiallyExpanded = true,
    this.maintainState = false,
  });

  final String id, title;
  final String? subtitle;
  final Widget? header, summary;
  final Widget child;
  final bool initiallyExpanded;
  final bool maintainState;

  @override
  State<ExecutionDetailsDisclosure> createState() =>
      _ExecutionDetailsDisclosureState();
}

class _ExecutionDetailsDisclosureState
    extends State<ExecutionDetailsDisclosure> {
  late final _controller = ShadAccordionController<String>(
    widget.initiallyExpanded ? widget.id : null,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final duration =
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180);
    return ShadAccordion<String>(
      controller: _controller,
      maintainState: widget.maintainState,
      children: [
        ShadAccordionItem<String>(
          value: widget.id,
          separator: const SizedBox.shrink(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          underlineTitleOnHover: false,
          duration: duration,
          effects: [SizeEffect(duration: duration, curve: Curves.easeInOut)],
          title: ListenableBuilder(
            listenable: _controller,
            builder:
                (context, child) => Semantics(
                  button: true,
                  expanded: _controller.value.contains(widget.id),
                  onTap: () => _controller.toggle(widget.id),
                  child: child,
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.header ??
                    Text(
                      widget.title,
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                if (widget.subtitle case final subtitle?) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.muted.copyWith(
                      color: theme.colorScheme.mutedForeground,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                if (widget.summary != null) ...[
                  const SizedBox(height: 8),
                  widget.summary!,
                ],
              ],
            ),
          ),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              final expanded = _controller.value.contains(widget.id);
              return ExcludeFocus(
                excluding: !expanded,
                child: ExcludeSemantics(excluding: !expanded, child: child!),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

class ExecutionStatusCard extends StatelessWidget {
  final bool isDesktop;
  final IconData icon;
  final Key? iconKey;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget? subtitleContent;
  final Widget? child;

  const ExecutionStatusCard({
    super.key,
    required this.isDesktop,
    required this.icon,
    this.iconKey = const ValueKey<String>('execution-status-icon'),
    this.iconColor,
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
        ExecutionStatusHeader(
          isDesktop: isDesktop,
          icon: icon,
          iconKey: iconKey,
          iconColor: iconColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

class ExecutionStatusHeader extends StatelessWidget {
  final bool isDesktop;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? subtitleContent;
  final Key? iconKey;
  final Color? iconColor;

  const ExecutionStatusHeader({
    super.key,
    required this.isDesktop,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleContent,
    this.iconKey = const ValueKey<String>('execution-status-icon'),
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = iconColor ?? StarsStatusTone.info.foreground(context);
    return Row(
      children: [
        ExecutionStatusIcon(
          key: iconKey,
          isDesktop: isDesktop,
          foregroundColor: foreground,
          child: Icon(icon, size: 16, color: foreground),
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
              if (subtitleContent != null || subtitle.isNotEmpty) ...[
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
            ],
          ),
        ),
      ],
    );
  }
}

class ExecutionStatusIcon extends StatelessWidget {
  const ExecutionStatusIcon({
    super.key,
    required this.isDesktop,
    required this.child,
    this.foregroundColor,
  });

  final bool isDesktop;
  final Widget child;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final foreground =
        foregroundColor ?? StarsStatusTone.info.foreground(context);
    final brightness =
        ShadTheme.maybeOf(context)?.brightness ?? Theme.of(context).brightness;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: foreground.withValues(
          alpha: brightness == Brightness.dark ? 0.16 : 0.10,
        ),
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
