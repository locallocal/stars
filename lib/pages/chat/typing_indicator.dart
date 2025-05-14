import 'package:flutter/material.dart';
import 'package:bubble/generated/l10n.dart';

class TypingIndicator extends StatelessWidget {
  final String botName;

  const TypingIndicator({super.key, required this.botName});

  @override
  Widget build(BuildContext context) {
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
