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
    );
  }
}
