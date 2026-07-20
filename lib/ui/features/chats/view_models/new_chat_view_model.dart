import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/use_cases/create_chat.dart';

class NewChatViewModel {
  const NewChatViewModel({
    required BotRepository botRepository,
    required CreateChat createChat,
  }) : _botRepository = botRepository,
       _createChat = createChat;

  final BotRepository _botRepository;
  final CreateChat _createChat;

  Future<List<Bot>> loadBots() => _botRepository.getBots();

  Future<Chat> create(Bot bot) => _createChat(bot);
}
