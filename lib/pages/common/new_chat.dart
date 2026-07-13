import 'package:stars/model/model.dart';
import 'package:stars/services/chat_service.dart';

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
