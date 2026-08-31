import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';

/// Keeps the typing status visible for the full assistant-response lifecycle.
///
/// The caller supplies the same request-running state used by the composer
/// action, so the indicator and stop button appear and disappear together.
class AssistantTypingIndicator extends StatelessWidget {
  const AssistantTypingIndicator({
    super.key,
    required this.botName,
    required this.isResponding,
    this.isDesktop = false,
  });

  final String botName;
  final bool isResponding;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    if (!isResponding) return const SizedBox.shrink();
    return TypingIndicator(botName: botName, isDesktop: isDesktop);
  }
}

/// Announces and displays an active response stream.
class TypingIndicator extends StatefulWidget {
  final String botName;
  final bool isDesktop;

  const TypingIndicator({
    super.key,
    required this.botName,
    this.isDesktop = false,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool? _shouldRotate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateRotation();
  }

  @override
  void didUpdateWidget(covariant TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDesktop != widget.isDesktop) _updateRotation();
  }

  void _updateRotation() {
    final shouldRotate =
        widget.isDesktop && !MediaQuery.disableAnimationsOf(context);
    if (_shouldRotate == shouldRotate) return;
    _shouldRotate = shouldRotate;
    if (shouldRotate) {
      _rotationController.repeat();
    } else {
      _rotationController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDesktop) {
      final shadTheme = ShadTheme.of(context);
      final label = S.of(context).botIsTyping(widget.botName);
      return Semantics(
        liveRegion: true,
        value: label,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, top: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: RotationTransition(
                  key: const ValueKey<String>('desktop-typing-spinner'),
                  turns: _rotationController,
                  child: Icon(
                    LucideIcons.loaderCircle,
                    size: 16,
                    color: shadTheme.colorScheme.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: shadTheme.textTheme.muted),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(S.of(context).botIsTyping(widget.botName)),
          const Spacer(),
        ],
      ),
    );
  }
}
