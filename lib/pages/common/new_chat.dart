import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/pages/chat.dart';

void createNewChat(BuildContext context, Bot bot) async {
  final id = 'chat_${DateTime.now().millisecondsSinceEpoch}';
  final newChat = Chat(
    id: id,
    botId: bot.id,
    lastMessage: '',
    lastMessageTimestamp: DateTime.now(),
    createTimestamp: DateTime.now(),
    modifyTimestamp: DateTime.now(),
  );
  await ChatService.addChat(newChat);

  if (context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(id: id, bot: bot)),
    ).then((_) {
      // 当聊天页面关闭后，通知聊天列表页刷新
      // 使用 Navigator.of(context).pushNamedAndRemoveUntil 来刷新聊天列表页
      // 但这里我们不想移除当前页面，所以使用通知机制

      // 发送通知，让聊天列表页刷新
      ChatService.notifyChatListChanged();
    });
  }
}
