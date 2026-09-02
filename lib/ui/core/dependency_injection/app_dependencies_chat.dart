part of 'app_dependencies.dart';

Future<void> _persistToolInvocation(
  ToolExecutionRepository executionRepository,
  SkillEcosystemRepository complianceRepository,
  ToolExecutionRecord record,
) async {
  await executionRepository.upsert(record);
  final now = DateTime.now();
  await complianceRepository.appendComplianceEvent(
    SkillComplianceEvent(
      id:
          '${now.microsecondsSinceEpoch}:tool:'
          '${record.executionId}:${record.status.name}',
      type: SkillComplianceEventType.toolInvoked,
      decision: record.approvalStatus,
      reason: record.errorCode,
      metadata: {
        'executionId': record.executionId,
        'runId': record.runId,
        'chatId': record.chatId,
        'botId': record.botId,
        'callId': record.callId,
        'tool': record.name,
        'source': record.source.name,
        'riskLevel': record.riskLevel.name,
        'status': record.status.name,
        'argumentsSummary': record.argumentsSummary,
        'resultSummary': record.resultSummary,
        'durationMs': record.durationMs,
      },
      timestamp: now,
    ),
  );
}

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
