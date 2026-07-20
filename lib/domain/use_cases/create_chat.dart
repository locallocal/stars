import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/chat_repository.dart';

typedef Clock = DateTime Function();

class CreateChat {
  CreateChat({required ChatRepository chatRepository, Clock? clock})
    : _chatRepository = chatRepository,
      _clock = clock ?? DateTime.now;

  final ChatRepository _chatRepository;
  final Clock _clock;
  int _sequence = 0;

  Future<Chat> call(Bot bot) async {
    final now = _clock();
    _sequence = (_sequence + 1) & 0x7fffffff;
    final chat = Chat(
      id: 'chat_${now.microsecondsSinceEpoch}_$_sequence',
      botId: bot.id,
      lastMessage: '',
      lastMessageTimestamp: now,
      createTimestamp: now,
      modifyTimestamp: now,
    );
    await _chatRepository.addChat(chat);
    return chat;
  }
}
