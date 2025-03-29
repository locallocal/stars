import 'package:flutter/material.dart';
import 'package:bubble/generated/l10n.dart';

class TypingIndicator extends StatelessWidget {
  final String botName;
  final bool isCancellable;
  final VoidCallback onCancelRequest;

  const TypingIndicator({
    super.key,
    required this.botName,
    required this.isCancellable,
    required this.onCancelRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
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
          if (isCancellable)
            IconButton(
              onPressed: onCancelRequest,
              icon: const Icon(Icons.pause_circle_filled),
              tooltip: S.of(context).pauseGeneration,
              iconSize: 28,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}
