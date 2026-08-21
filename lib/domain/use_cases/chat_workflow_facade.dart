import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/conversation_draft_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/create_user_message.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/domain/use_cases/persist_conversation_assets.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';

final class ChatHistoryBatch {
  ChatHistoryBatch({
    required Iterable<Message> messages,
    this.hasMore = false,
    this.nextCursor,
  }) : messages = List<Message>.unmodifiable(messages);

  final List<Message> messages;
  final bool hasMore;
  final MessageCursor? nextCursor;
}

/// Conversation-scoped application facade used by the presentation layer.
///
/// Repository capabilities and multi-step Use Cases stay behind this boundary,
/// so the Chat ViewModel only coordinates immutable UI state.
final class ChatWorkflowFacade {
  ChatWorkflowFacade({
    required this.chatId,
    required Bot bot,
    required MessageRepository messageRepository,
    required ChatRepository chatRepository,
    required AiProviderRepository aiProviderRepository,
    required AttachmentRepository attachmentRepository,
    required ConversationDraftRepository conversationDraftRepository,
    required CreateUserMessage createUserMessage,
    required PersistConversationAssets persistConversationAssets,
    required GenerateMediaTurn generateMediaTurn,
    required PrepareTextGeneration prepareTextGeneration,
  }) : _bot = bot,
       _messages = messageRepository,
       _chats = chatRepository,
       _providers = aiProviderRepository,
       _attachments = attachmentRepository,
       _drafts = conversationDraftRepository,
       _createUserMessage = createUserMessage,
       _persistConversationAssets = persistConversationAssets,
       _generateMediaTurn = generateMediaTurn,
       _prepareTextGeneration = prepareTextGeneration;

  final String chatId;
  Bot _bot;
  final MessageRepository _messages;
  final ChatRepository _chats;
  final AiProviderRepository _providers;
  final AttachmentRepository _attachments;
  final ConversationDraftRepository _drafts;
  final CreateUserMessage _createUserMessage;
  final PersistConversationAssets _persistConversationAssets;
  final GenerateMediaTurn _generateMediaTurn;
  final PrepareTextGeneration _prepareTextGeneration;

  Bot get bot => _bot;

  void updateBot(Bot bot) {
    if (bot.id != _bot.id) {
      throw ArgumentError.value(
        bot.id,
        'bot.id',
        'A conversation cannot change its Bot identity.',
      );
    }
    _bot = bot;
  }

  ChatHistoryBatch? peekHistory() {
    final messages = _messages;
    if (messages is PaginatedMessageRepository) {
      final page = messages.peekMessagePage(chatId);
      return page == null ? null : _historyBatch(page);
    }
    if (messages is CachedMessageRepository) {
      final cached = messages.peekMessages(chatId);
      return cached == null ? null : ChatHistoryBatch(messages: cached);
    }
    return null;
  }

  Future<ChatHistoryBatch> loadHistory({MessageCursor? before}) async {
    final messages = _messages;
    if (messages is PaginatedMessageRepository) {
      return _historyBatch(
        await messages.getMessagePage(chatId, before: before),
      );
    }
    if (before != null) return ChatHistoryBatch(messages: const []);
    return ChatHistoryBatch(messages: await messages.getMessages(chatId));
  }

  String createId(String prefix) => _messages.createId(prefix);

  Message createUserMessage({
    required String currentUserId,
    required String content,
    List<String> imagePaths = const [],
    List<String> filePaths = const [],
    String imageDetail = '',
    String fileDetail = '',
  }) => _createUserMessage(
    chatId: chatId,
    botId: bot.id,
    senderId: currentUserId,
    content: content,
    imagePaths: imagePaths,
    filePaths: filePaths,
    imageDetail: imageDetail,
    fileDetail: fileDetail,
  );

  Future<Message> upsertMessage(Message message) =>
      _messages.upsertMessage(message);

  Future<void> updateLastMessage(String content) =>
      _chats.updateLastMessage(chatId, content);

  Future<void> clearHistory() => _chats.clearHistory(chatId);

  void notifyChatListChanged() => _chats.invalidate();

  Future<PreparedChatTurn> prepareTextTurn({
    required List<Message> history,
    required Message userMessage,
    required String currentUserId,
  }) => _prepareTextGeneration.prepareTurn(
    bot: bot,
    history: history,
    userMessage: userMessage,
    currentUserId: currentUserId,
  );

  Future<PreparedChatGeneration> prepareTextGeneration({
    required List<Message> history,
    required Message userMessage,
    required String currentUserId,
  }) => _prepareTextGeneration(
    chatId: chatId,
    bot: bot,
    history: history,
    userMessage: userMessage,
    currentUserId: currentUserId,
  );

  Future<String?> captureImage() => _attachments.captureImage();

  Future<String?> selectImage() => _attachments.selectImage();

  Future<String?> selectFile() => _attachments.selectFile();

  Future<List<String>> persistAssets(Iterable<String> sourcePaths) =>
      _persistConversationAssets(chatId: chatId, sourcePaths: sourcePaths);

  Future<MediaTurnResult> generateMediaTurn(
    MediaTurnRequest request, {
    MediaUserPersisted? onUserPersisted,
  }) => _generateMediaTurn(request, onUserPersisted: onUserPersisted);

  Future<ConversationDraft?> readDraft() => _drafts.read(chatId);

  Future<void> writeDraft(ConversationDraft draft) =>
      _drafts.write(chatId, draft);

  Future<void> deleteDraft() => _drafts.delete(chatId);

  Future<List<String>> generateImage({
    required String prompt,
    required String size,
    required String outputDirectory,
    required List<String> referenceImages,
    required String style,
  }) => _providers.generateImage(
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
  }) => _providers.generateSpeech(
    bot: bot,
    prompt: prompt,
    voiceType: voiceType,
    outputDirectory: outputDirectory,
  );

  Future<String> generateMusic({
    required String prompt,
    required String outputDirectory,
    required String referenceMusic,
  }) => _providers.generateMusic(
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
  }) => _providers.generateVideo(
    bot: bot,
    prompt: prompt,
    ratio: ratio,
    outputDirectory: outputDirectory,
    referenceImages: referenceImages,
  );

  Future<bool> cancelMedia() {
    final providers = _providers;
    if (providers is! CancelableMediaRepository) return Future.value(false);
    return providers.cancelMedia(bot.id);
  }

  ChatHistoryBatch _historyBatch(MessagePage page) => ChatHistoryBatch(
    messages: page.messages,
    hasMore: page.hasMore,
    nextCursor: page.nextCursor,
  );
}
