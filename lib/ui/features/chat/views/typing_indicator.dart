import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';

/// Announces and displays an active response stream.
class TypingIndicator extends StatelessWidget {
  final String botName;
  final bool isDesktop;

  const TypingIndicator({
    super.key,
    required this.botName,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      final shadTheme = ShadTheme.of(context);
      final label = S.of(context).botIsTyping(botName);
      return Semantics(
        liveRegion: true,
        value: label,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, top: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.loaderCircle,
                  size: 16,
                  color: shadTheme.colorScheme.mutedForeground,
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
          Text(S.of(context).botIsTyping(botName)),
          const Spacer(),
        ],
      ),
    );
  }
}
