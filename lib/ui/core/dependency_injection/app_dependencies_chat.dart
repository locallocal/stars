part of 'app_dependencies.dart';

extension AppDependenciesChatFactories on AppDependencies {
  MessageActionViewModel createMessageActionViewModel() =>
      MessageActionViewModel(repository: messageActionRepository);

  ChatTokenUsageViewModel createChatTokenUsageViewModel(String chatId) =>
      ChatTokenUsageViewModel(
        chatId: chatId,
        messageRepository: messageRepository,
        chatRepository: chatRepository,
      );

  ConversationMemoryViewModel createConversationMemoryViewModel(
    String chatId,
    Bot bot,
  ) => ConversationMemoryViewModel(
    chatId: chatId,
    bot: bot,
    repository: conversationMemoryRepository,
    compactConversation: compactConversation,
    conversationArtifactsDirectoryProvider:
        conversationArtifactsDirectoryProvider,
  );

  ConversationDirectoryViewModel createConversationDirectoryViewModel(
    String chatId,
  ) => ConversationDirectoryViewModel(
    chatId: chatId,
    repository: conversationDirectoryRepository,
  );
}
