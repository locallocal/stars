part of 'app_dependencies.dart';

extension AppDependenciesChatFactories on AppDependencies {
  ConversationTasksViewModel? createConversationTasksViewModel(
    String chatId,
    String botId,
  ) {
    final tasks = conversationTasks;
    if (tasks == null || tasks.progress == null || tasks.retry == null) {
      return null;
    }
    return ConversationTasksViewModel(
      chatId: chatId,
      botId: botId,
      observe: ObserveConversationTasks(tasks.repository, clock: tasks.clock),
      present: tasks.progress!,
      commands: tasks.commands,
      prepareRetry: tasks.retry!,
    );
  }

  MessageActionViewModel createMessageActionViewModel() =>
      MessageActionViewModel(
        repository: messageActionRepository,
        evidenceRepository: toolEvidenceRepository,
      );

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
  ChatViewModel createChatViewModel(String chatId, Bot bot) {
    final workflow = ChatWorkflowFacade(
      chatId: chatId,
      bot: bot,
      messageRepository: messageRepository,
      chatRepository: chatRepository,
      aiProviderRepository: aiProviderRepository,
      attachmentRepository: attachmentRepository,
      conversationDraftRepository: conversationDraftRepository,
      createUserMessage: createUserMessage,
      persistConversationAssets: persistConversationAssets,
      generateMediaTurn: generateMediaTurn,
      prepareTextGeneration: prepareTextGeneration,
    );
    return ChatViewModel(
      interaction: ChatInteractionFacade(
        workflow: workflow,
        messageActions: createMessageActionViewModel(),
        generationRegistry: generationRegistry,
        generationViewModel: generationRegistry.viewModelFor(chatId, bot),
      ),
    );
  }
}
