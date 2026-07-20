import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required this.chatId,
    required this.bot,
    required MessageRepository messageRepository,
    required ChatRepository chatRepository,
    required AiProviderRepository aiProviderRepository,
    required ChatGenerationRegistry generationRegistry,
  }) : _messageRepository = messageRepository,
       _chatRepository = chatRepository,
       _aiProviderRepository = aiProviderRepository,
       generationRegistry = generationRegistry,
       generationViewModel = generationRegistry.viewModelFor(chatId, bot);

  final String chatId;
  final Bot bot;
  final MessageRepository _messageRepository;
  final ChatRepository _chatRepository;
  final AiProviderRepository _aiProviderRepository;
  final ChatGenerationRegistry generationRegistry;
  final ChatGenerationViewModel generationViewModel;

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

  Future<List<String>> generateImage({
    required String prompt,
    required String size,
    required String outputDirectory,
    required List<String> referenceImages,
    required String style,
  }) => _aiProviderRepository.generateImage(
    bot: bot,
    prompt: prompt,
    size: size,
    outputDirectory: outputDirectory,
    referenceImages: referenceImages,
    style: style,
  );

  Future<String> generateSpeech({
    required String prompt,
    required String voiceType,
    required String outputDirectory,
  }) => _aiProviderRepository.generateSpeech(
    bot: bot,
    prompt: prompt,
    voiceType: voiceType,
    outputDirectory: outputDirectory,
  );

  Future<String> generateMusic({
    required String prompt,
    required String outputDirectory,
    required String referenceMusic,
  }) => _aiProviderRepository.generateMusic(
    bot: bot,
    prompt: prompt,
    outputDirectory: outputDirectory,
    referenceMusic: referenceMusic,
  );

  Future<String> generateVideo({
    required String prompt,
    required String ratio,
    required String outputDirectory,
    required List<String> referenceImages,
  }) => _aiProviderRepository.generateVideo(
    bot: bot,
    prompt: prompt,
    ratio: ratio,
    outputDirectory: outputDirectory,
    referenceImages: referenceImages,
  );

  void notifyChatListChanged() => _chatRepository.invalidate();
}
