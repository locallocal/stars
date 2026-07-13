import 'package:flutter/material.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/utils/theme.dart';

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
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: StarsDesktopTheme.statusCardBackground(context),
          borderRadius: BorderRadius.circular(StarsDesktopTheme.cardRadius),
          border: Border.all(color: StarsDesktopTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                S.of(context).botIsTyping(botName),
                style: TextStyle(
                  color: StarsDesktopTheme.mutedText(context),
                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                ),
              ),
            ),
          ],
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
