part of 'conversation_turn_dispatcher.dart';

TaskAcceptanceSnapshot _freezeAcceptance(
  ConversationTurnInput input,
  PreparedChatGeneration prepared,
  ToolRegistry tools,
  bool Function(ExecutableTool) supportsTaskTool,
) {
  final registry = OverlayToolRegistry(
    parent: tools,
    overlayTools: prepared.runScopedTools,
  );
  final requested = {
    ...prepared.requestedToolNames,
    ...prepared.verificationToolNames,
  };
  final allowed =
      requested.isEmpty
          ? <String>{}
          : registry
              .list(allowedNames: requested)
              .where((definition) {
                final tool = registry.find(definition.name);
                return tool != null && supportsTaskTool(tool);
              })
              .map((tool) => tool.name)
              .toSet();
  return TaskAcceptanceSnapshot(
    providerId: input.bot.apiType,
    modelId: input.bot.model,
    // Credentials remain runtime-only. Endpoint and options are represented by
    // a digest, never by an arbitrary Provider-configuration map in task JSON.
    configurationDigest: taskProviderConfigurationDigest(input.bot),
    language: input.language,
    context: [
      for (final message in prepared.messages)
        TaskContextMessage(
          role: switch (message.role) {
            'system' => TaskContextRole.system,
            'user' => TaskContextRole.user,
            'assistant' => TaskContextRole.assistant,
            'tool' => TaskContextRole.tool,
            _ => throw ArgumentError('Unsupported prepared context role.'),
          },
          content: message.content,
          assetReferences: [...message.images, ...message.files],
        ),
    ],
    allowedToolNames: allowed,
    verification: VerificationPolicySnapshot(
      reliabilityEnabled:
          input.verification.reliabilityEnabled &&
          prepared.reliabilityPolicyEnabled,
      strictGroundingEnabled: input.verification.strictGroundingEnabled,
      showVerificationStatus: input.verification.showVerificationStatus,
      policyVersion: input.verification.policyVersion,
    ),
    segmentLimits: input.segmentLimits,
  );
}

_AcceptanceWrite _createAcceptance(
  _PendingTurn pending,
  BackgroundTaskPlan proposal,
  DateTime at,
) {
  final user = pending.input.userMessage;
  // A stable bounded identity even if the original turn ID is already 256 chars.
  final taskId = 'task:${sha256.convert(utf8.encode(user.turnId))}';
  final acknowledgement = const TaskAcknowledgementPolicy().evaluate(
    draft: proposal.acknowledgementDraft,
    title: proposal.title,
    objective: proposal.objective,
    language: pending.input.language,
  );
  final task = ConversationTask(
    taskId: taskId,
    chatId: user.chatId,
    botId: user.botId,
    originTurnId: user.turnId,
    originUserMessageId: user.messageId,
    retryOfTaskId: pending.input.retryOfTaskId,
    title: proposal.title,
    objective: proposal.objective,
    acceptance: pending.acceptance!,
    progress: TaskProgress(
      totalSteps: proposal.steps.length,
      lastMeaningfulProgressAt: at,
    ),
    createdAt: at,
    updatedAt: at,
  );
  return _AcceptanceWrite(
    task: task,
    plan: ConversationTaskPlan(
      taskId: taskId,
      revision: 1,
      objective: proposal.objective,
      steps: proposal.steps,
      allowedToolNames: proposal.allowedToolNames,
      createdAt: at,
    ),
    event: ConversationTaskEvent(
      taskId: taskId,
      sequence: 1,
      kind: TaskEventKind.queued,
      occurredAt: at,
      safeSummary: acknowledgement.text,
    ),
    acknowledgement: Message(
      messageId: task.ackMessageId,
      turnId: user.turnId,
      chatId: user.chatId,
      botId: user.botId,
      senderId: user.botId,
      taskId: taskId,
      taskMessageKind: TaskMessageKind.acknowledgement,
      content: acknowledgement.text,
      timestamp: at,
      tokenUsage: pending.prepared!.preflightTokenUsage + pending.usage,
    ),
    ackFallback: acknowledgement.usedFallback,
  );
}

final class _AcceptanceWrite {
  const _AcceptanceWrite({
    required this.task,
    required this.plan,
    required this.event,
    required this.acknowledgement,
    required this.ackFallback,
  });
  final ConversationTask task;
  final ConversationTaskPlan plan;
  final ConversationTaskEvent event;
  final Message acknowledgement;
  final bool ackFallback;
}

Bot _frozenBot(Bot bot) => Bot(
  id: bot.id,
  name: bot.name,
  avatar: bot.avatar,
  provider: bot.provider,
  baseURL: bot.baseURL,
  apiKey: bot.apiKey,
  apiType: bot.apiType,
  model: bot.model,
  systemPrompt: bot.systemPrompt,
  parameters:
      bot.parameters == null
          ? null
          : _freezeJson(bot.parameters) as Map<String, dynamic>,
  createTimestamp: bot.createTimestamp,
  modifyTimestamp: bot.modifyTimestamp,
);

Object? _freezeJson(Object? value) {
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return Map<String, dynamic>.unmodifiable({
      for (final key in keys) key: _freezeJson(value[key]),
    });
  }
  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(value.map(_freezeJson));
  }
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  throw ArgumentError('Provider parameters must be JSON values.');
}
