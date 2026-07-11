import 'package:bubble/model/model.dart';
import 'package:bubble/services/chat_service.dart';

Future<Chat> createNewChat(Bot bot) async {
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
  return newChat;
}
