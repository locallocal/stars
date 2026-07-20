import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/services/chat_generation_controller.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required this.chatId,
    required this.bot,
    required MessageRepository messageRepository,
    required ChatRepository chatRepository,
    required ChatGenerationRegistry generationRegistry,
  }) : _messageRepository = messageRepository,
       _chatRepository = chatRepository,
       generationRegistry = generationRegistry,
       generationController = generationRegistry.controllerFor(chatId, bot);

  final String chatId;
  final Bot bot;
  final MessageRepository _messageRepository;
  final ChatRepository _chatRepository;
  final ChatGenerationRegistry generationRegistry;
  final ChatGenerationController generationController;

  List<Message> _messages = const [];
  Object? _historyError;
  bool _isLoading = false;

  List<Message> get messages => _messages;
  Object? get historyError => _historyError;
  bool get isLoading => _isLoading;

  Future<void> loadMessages() async {
    _isLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      _messages = await _messageRepository.getMessages(chatId);
    } catch (error) {
      _historyError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String createId(String prefix) => _messageRepository.createId(prefix);

  Future<Message> upsertMessage(Message message) =>
      _messageRepository.upsertMessage(message);

  Future<void> updateLastMessage(String content) =>
      _chatRepository.updateLastMessage(chatId, content);

  Future<void> clearHistory() => _chatRepository.clearHistory(chatId);

  void notifyChatListChanged() => _chatRepository.invalidate();
}
