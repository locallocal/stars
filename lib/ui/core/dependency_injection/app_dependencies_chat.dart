part of 'app_dependencies.dart';

extension AppDependenciesChatFactories on AppDependencies {
  ConversationTasksViewModel createConversationTasksViewModel(
    String chatId,
    Bot bot,
  ) {
    final tasks = conversationTasks;
    return ConversationTasksViewModel(
      chatId: chatId,
      botId: bot.id,
      observe: ObserveConversationTasks(tasks.repository, clock: tasks.clock),
      commands: tasks.commands,
      prepareRetry: tasks.retry,
      retryAvailable: () => !generationRegistry.hasBlockingRun(chatId),
      dispatchRetry: (draft, input, language, verification) async {
        final generation = generationRegistry.viewModelFor(chatId, bot);
        final accepted = await generation.dispatchText(
          userMessage: createUserMessage(
            chatId: chatId,
            botId: bot.id,
            senderId: 'me',
            content: input,
          ),
          language: language,
          verification: verification,
          retryOfTaskId: draft.taskId,
        );
        if (!accepted) throw StateError('task_retry_dispatch_failed');
      },
    );
  }

  MessageActionViewModel createMessageActionViewModel({String? chatId}) =>
      MessageActionViewModel(
        repository: messageActionRepository,
        evidenceRepository: toolEvidenceRepository,
        localFilesDirectoryProvider:
            chatId == null
                ? null
                : () => conversationArtifactsDirectoryProvider(chatId),
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
        messageActions: createMessageActionViewModel(chatId: chatId),
        generationRegistry: generationRegistry,
        generationViewModel: generationRegistry.viewModelFor(chatId, bot),
      ),
    );
  }
}
