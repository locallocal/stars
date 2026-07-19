import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/chat/desktop_chat_primitives.dart';
import 'package:stars/utils/utils.dart';

/// 显示清除聊天历史对话框
Future<bool> showClearChatDialog(BuildContext context, String botName) async {
  if (isDesktopOrTabletPlatform(context)) {
    final result = await showChatShadDialog<bool>(
      context: context,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      variant: ShadDialogVariant.alert,
      builder:
          (dialogContext) => ShadDialog.alert(
            title: Text(
              desktopConversationText(
                dialogContext,
                S.of(dialogContext).clearChatHistory,
              ),
            ),
            description: Text(
              desktopConversationText(
                dialogContext,
                S.of(dialogContext).confirmClearChat(botName),
              ),
            ),
            actions: [
              ShadButton.outline(
                autofocus: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(S.of(dialogContext).cancel),
              ),
              ShadButton.destructive(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(S.of(dialogContext).clear),
              ),
            ],
          ),
    );

    return result ?? false;
  }

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
