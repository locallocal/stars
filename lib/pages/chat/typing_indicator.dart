import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';

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
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ShadCard(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: shadTheme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  S.of(context).botIsTyping(botName),
                  style: shadTheme.textTheme.muted,
                ),
              ),
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
