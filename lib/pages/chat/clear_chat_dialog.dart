import 'package:flutter/material.dart';
import 'package:bubble/generated/l10n.dart';

/// 显示清除聊天历史对话框
Future<bool> showClearChatDialog(BuildContext context, String botName) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Center(
            child: Text(
              S.of(context).clearChatHistory,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
              ),
            ),
          ),
          content: Text(S.of(context).confirmClearChat(botName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                S.of(context).cancel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                S.of(context).clear,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
  );

  return result ?? false;
}
