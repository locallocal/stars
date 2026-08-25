part of 'compose_chat_turn.dart';

extension _ComposeChatTurnSkills on ComposeChatTurn {
  Future<Map<String, SkillContent>> _loadBundledSkills() async {
    final loader = _bundledSkillLoader;
    if (loader == null) return const {};
    try {
      return Map<String, SkillContent>.unmodifiable({
        for (final content in await loader())
          if (content.descriptor.scope == SkillScope.bundled)
            content.descriptor.id: content,
      });
    } on Object {
      return const {};
    }
  }

  SkillContent? _loadSystemShellSkill(
    AiProvider? provider,
    _TurnSkillState state,
    Set<String> enabledSkillIds,
  ) {
    if (provider?.capabilities.supportsAgentLoop != true ||
        !enabledSkillIds.contains(shellCommandSkillId)) {
      return null;
    }
    final content = state.bundledContents[shellCommandSkillId];
    if (content == null ||
        content.descriptor.id != shellCommandSkillId ||
        !content.descriptor.isUsable ||
        !content.descriptor.requestedToolNames.contains(shellCommandToolName)) {
      return null;
    }
    final tokens = _estimateTokens(content.instructions);
    if (tokens > _budget.maxTokensPerSkill ||
        state.skillTokens + tokens > _budget.maxSkillContextTokens) {
      return null;
    }
    return content;
  }

  SkillContent? _loadSystemSkillInstallerSkill(
    AiProvider? provider,
    _TurnSkillState state,
    Set<String> enabledSkillIds, {
    required int reservedTokens,
  }) {
    if (provider?.capabilities.supportsAgentLoop != true ||
        !enabledSkillIds.contains(skillInstallerSkillId)) {
      return null;
    }
    final content = state.bundledContents[skillInstallerSkillId];
    if (content == null ||
        content.descriptor.id != skillInstallerSkillId ||
        !content.descriptor.isUsable ||
        !content.descriptor.requestedToolNames.containsAll(
          skillInstallerToolNames,
        )) {
      return null;
    }
    final tokens = _estimateTokens(content.instructions);
    if (tokens > _budget.maxTokensPerSkill ||
        state.skillTokens + reservedTokens + tokens >
            _budget.maxSkillContextTokens) {
      return null;
    }
    return content;
  }

  SkillContent? _loadSystemDirectoryOperationsSkill(
    AiProvider? provider,
    _TurnSkillState state,
    Set<String> enabledSkillIds, {
    required int reservedTokens,
  }) => _loadSystemLocalFileSystemSkill(
    provider,
    state,
    enabledSkillIds,
    skillId: directoryOperationsSkillId,
    requestedToolNames: directoryOperationsToolNames,
    reservedTokens: reservedTokens,
  );

  SkillContent? _loadSystemFileOperationsSkill(
    AiProvider? provider,
    _TurnSkillState state,
    Set<String> enabledSkillIds, {
    required int reservedTokens,
  }) => _loadSystemLocalFileSystemSkill(
    provider,
    state,
    enabledSkillIds,
    skillId: fileOperationsSkillId,
    requestedToolNames: fileOperationsToolNames,
    reservedTokens: reservedTokens,
  );

  SkillContent? _loadSystemLocalFileSystemSkill(
    AiProvider? provider,
    _TurnSkillState state,
    Set<String> enabledSkillIds, {
    required String skillId,
    required Set<String> requestedToolNames,
    required int reservedTokens,
  }) {
    if (provider?.capabilities.supportsAgentLoop != true ||
        !enabledSkillIds.contains(skillId)) {
      return null;
    }
    final content = state.bundledContents[skillId];
    if (content == null ||
        content.descriptor.id != skillId ||
        !content.descriptor.isUsable ||
        !content.descriptor.requestedToolNames.containsAll(
          requestedToolNames,
        )) {
      return null;
    }
    final tokens = _estimateTokens(content.instructions);
    if (tokens > _budget.maxTokensPerSkill ||
        state.skillTokens + reservedTokens + tokens >
            _budget.maxSkillContextTokens) {
      return null;
    }
    return content;
  }

  SkillContent? _loadSystemMcpInstallerSkill(
    AiProvider? provider,
    _TurnSkillState state,
    Set<String> enabledSkillIds, {
    required int reservedTokens,
  }) {
    if (provider?.capabilities.supportsAgentLoop != true ||
        !enabledSkillIds.contains(mcpInstallerSkillId)) {
      return null;
    }
    final content = state.bundledContents[mcpInstallerSkillId];
    if (content == null ||
        content.descriptor.id != mcpInstallerSkillId ||
        !content.descriptor.isUsable ||
        !content.descriptor.requestedToolNames.containsAll(
          mcpInstallerToolNames,
        )) {
      return null;
    }
    final tokens = _estimateTokens(content.instructions);
    if (tokens > _budget.maxTokensPerSkill ||
        state.skillTokens + reservedTokens + tokens >
            _budget.maxSkillContextTokens) {
      return null;
    }
    return content;
  }

  bool _isValidConversationHistorySkill(SkillContent? content) {
    return content != null &&
        content.descriptor.id == conversationHistorySkillId &&
        content.descriptor.isUsable &&
        content.descriptor.requestedToolNames.containsAll(
          conversationHistoryToolNames,
        );
  }

  Future<void> _resolveAutomaticSkills({
    required AiProvider provider,
    required Bot bot,
    required List<Message> history,
    required Message userMessage,
    required String currentUserId,
    required List<SkillCatalogEntry> catalog,
    required Map<String, SkillDescriptor> descriptors,
    required _TurnSkillState state,
    required String conversationArtifactsDirectory,
  }) async {
    final initialPrompt = _composeSystemPrompt(
      bot.systemPrompt,
      state.contents.values.toList(),
      bot: bot,
      conversationId: userMessage.chatId,
      conversationArtifactsDirectory: conversationArtifactsDirectory,
      catalog: catalog,
    );
    final initialMessages = <ChatMessage>[
      if (initialPrompt.isNotEmpty)
        ChatMessage(role: 'system', content: initialPrompt),
      ..._composeHistory(
        history: history,
        userMessage: userMessage,
        currentUserId: currentUserId,
      ),
    ];
    final session = provider.openSkillToolSession(
      SkillToolSessionRequest(messages: initialMessages, catalog: catalog),
    );
    final candidatesByName = <String, SkillCatalogEntry>{
      for (final candidate in catalog) candidate.name: candidate,
    };
    try {
      SkillToolTurn turn = await session.start();
      state.preflightTokenUsage = state.preflightTokenUsage + turn.tokenUsage;
      var toolCalls = 0;
      for (var modelTurn = 0; modelTurn < _budget.maxToolTurns; modelTurn++) {
        if (turn.calls.isEmpty || turn.isComplete) break;
        final results = <SkillToolResult>[];
        for (final call in turn.calls) {
          toolCalls += 1;
          if (toolCalls > _budget.maxToolCalls) {
            results.add(
              SkillToolResult(
                callId: call.callId,
                name: call.name,
                content: 'Skill tool call limit reached.',
                isError: true,
              ),
            );
            continue;
          }
          results.add(
            await _executeSkillTool(
              call: call,
              candidatesByName: candidatesByName,
              descriptors: descriptors,
              state: state,
            ),
          );
        }
        if (modelTurn + 1 >= _budget.maxToolTurns) break;
        turn = await session.continueWith(results);
        state.preflightTokenUsage = state.preflightTokenUsage + turn.tokenUsage;
      }
    } finally {
      session.close();
    }
  }

  Future<SkillToolResult> _executeSkillTool({
    required SkillToolCall call,
    required Map<String, SkillCatalogEntry> candidatesByName,
    required Map<String, SkillDescriptor> descriptors,
    required _TurnSkillState state,
  }) async {
    final stopwatch = Stopwatch()..start();
    if (call.name == 'activate_skill') {
      final name = call.arguments['name']?.toString() ?? '';
      final candidate = candidatesByName[name];
      final descriptor = candidate == null ? null : descriptors[candidate.id];
      if (candidate == null || descriptor == null) {
        stopwatch.stop();
        state
          ..attempts.add(
            SkillActivationAttempt(
              skillId: '',
              skillName: name,
              contentDigest: '',
              trigger: SkillActivationTrigger.model,
              status: SkillActivationStatus.failed,
              startedAt: DateTime.now().subtract(stopwatch.elapsed),
              completedAt: DateTime.now(),
              durationMs: stopwatch.elapsedMilliseconds,
              errorCode: 'invalid_candidate',
            ),
          )
          ..toolCalls.add(
            MessageToolCall(
              name: call.name,
              status: 'failed',
              detail: name,
              durationMs: stopwatch.elapsedMilliseconds,
            ),
          );
        return SkillToolResult(
          callId: call.callId,
          name: call.name,
          content: 'Unknown or unavailable Skill.',
          isError: true,
        );
      }
      final activated = await _activate(
        state: state,
        descriptor: descriptor,
        trigger: SkillActivationTrigger.model,
        stopwatch: stopwatch,
      );
      stopwatch.stop();
      state.toolCalls.add(
        MessageToolCall(
          name: call.name,
          status: activated ? 'completed' : 'skipped',
          detail: descriptor.name,
          durationMs: stopwatch.elapsedMilliseconds,
        ),
      );
      if (!activated) {
        return SkillToolResult(
          callId: call.callId,
          name: call.name,
          content:
              'Skill was not activated because a context limit was reached.',
          isError: true,
        );
      }
      final content = state.contents[descriptor.id]!.content;
      final references = content.files
          .where((file) => file.startsWith('references/'))
          .join('\n');
      return SkillToolResult(
        callId: call.callId,
        name: call.name,
        content: '''
Activated ${descriptor.name}.

<skill_instructions>
${content.instructions}
</skill_instructions>
${references.isEmpty ? '' : '<available_references>\n$references\n</available_references>'}''',
      );
    }

    if (call.name == 'read_skill_resource') {
      final name = call.arguments['name']?.toString() ?? '';
      final relativePath = call.arguments['path']?.toString() ?? '';
      final activeEntry =
          state.contents.values
              .where((entry) => entry.content.descriptor.name == name)
              .firstOrNull;
      if (activeEntry == null) {
        stopwatch.stop();
        state.toolCalls.add(
          MessageToolCall(
            name: call.name,
            status: 'failed',
            detail: relativePath,
            durationMs: stopwatch.elapsedMilliseconds,
          ),
        );
        return SkillToolResult(
          callId: call.callId,
          name: call.name,
          content: 'Activate the Skill before reading its references.',
          isError: true,
        );
      }
      final resourceKey = '${activeEntry.content.descriptor.id}:$relativePath';
      final cachedResource = state.resources[resourceKey];
      if (cachedResource != null) {
        stopwatch.stop();
        state.toolCalls.add(
          MessageToolCall(
            name: call.name,
            status: 'completed',
            detail: relativePath,
            durationMs: stopwatch.elapsedMilliseconds,
          ),
        );
        return SkillToolResult(
          callId: call.callId,
          name: call.name,
          content: cachedResource.content,
        );
      }
      try {
        var resource = await _skillRepository.readResource(
          activeEntry.content.descriptor.id,
          relativePath,
          contentDigest: activeEntry.content.descriptor.contentDigest,
        );
        final remaining = _budget.maxResourceTokens - state.resourceTokens;
        if (remaining <= 0) {
          throw const SkillInstallException(
            'Skill resource Token budget exhausted.',
          );
        }
        final bounded = _truncateToTokens(resource.content, remaining);
        resource = SkillResourceContent(
          skillId: resource.skillId,
          path: resource.path,
          content: bounded,
        );
        state.resources[resourceKey] = resource;
        state.resourceTokens += _estimateTokens(bounded);
        stopwatch.stop();
        state.toolCalls.add(
          MessageToolCall(
            name: call.name,
            status: 'completed',
            detail: relativePath,
            durationMs: stopwatch.elapsedMilliseconds,
          ),
        );
        return SkillToolResult(
          callId: call.callId,
          name: call.name,
          content: bounded,
        );
      } catch (error) {
        stopwatch.stop();
        state.toolCalls.add(
          MessageToolCall(
            name: call.name,
            status: 'failed',
            detail: relativePath,
            durationMs: stopwatch.elapsedMilliseconds,
          ),
        );
        return SkillToolResult(
          callId: call.callId,
          name: call.name,
          content:
              AppFailure.from(error, code: 'skill_resource_read_failed').code,
          isError: true,
        );
      }
    }

    stopwatch.stop();
    state.toolCalls.add(
      MessageToolCall(
        name: call.name,
        status: 'failed',
        detail: 'unsupported',
        durationMs: stopwatch.elapsedMilliseconds,
      ),
    );
    return SkillToolResult(
      callId: call.callId,
      name: call.name,
      content: 'Unsupported Skill tool.',
      isError: true,
    );
  }

  Future<bool> _activate({
    required _TurnSkillState state,
    required SkillDescriptor descriptor,
    required SkillActivationTrigger trigger,
    Stopwatch? stopwatch,
  }) async {
    if (state.contents.containsKey(descriptor.id)) return true;
    final startedAt = DateTime.now();
    SkillContent? content;
    String errorCode = '';
    try {
      if (state.contents.length >= _budget.maxActivatedSkills) {
        errorCode = 'skill_count_limit';
      } else {
        content =
            state.bundledContents[descriptor.id] ??
            await _skillRepository.load(
              descriptor.id,
              contentDigest: descriptor.contentDigest,
            );
        final tokens = _estimateTokens(content.instructions);
        if (tokens > _budget.maxTokensPerSkill) {
          errorCode = 'per_skill_token_limit';
        } else if (state.skillTokens + tokens > _budget.maxSkillContextTokens) {
          errorCode = 'skill_context_token_limit';
        } else {
          state.contents[descriptor.id] = (content: content, trigger: trigger);
          state.skillTokens += tokens;
        }
      }
    } catch (_) {
      errorCode = 'load_failed';
    }
    final completedAt = DateTime.now();
    final activated = errorCode.isEmpty && content != null;
    state.attempts.add(
      SkillActivationAttempt(
        skillId: descriptor.id,
        skillName: descriptor.name,
        contentDigest: descriptor.contentDigest,
        trigger: trigger,
        status:
            activated
                ? SkillActivationStatus.activated
                : errorCode == 'load_failed'
                ? SkillActivationStatus.failed
                : SkillActivationStatus.skipped,
        startedAt: startedAt,
        completedAt: completedAt,
        durationMs:
            stopwatch?.elapsedMilliseconds ??
            completedAt.difference(startedAt).inMilliseconds,
        errorCode: errorCode,
      ),
    );
    return activated;
  }
}

final class _TurnSkillState {
  _TurnSkillState();

  final Map<String, ({SkillContent content, SkillActivationTrigger trigger})>
  contents = {};
  final Map<String, SkillContent> bundledContents = {};
  final Map<String, SkillResourceContent> resources = {};
  final List<SkillActivationAttempt> attempts = [];
  final List<MessageToolCall> toolCalls = [];
  int skillTokens = 0;
  int resourceTokens = 0;
  ModelTokenUsage preflightTokenUsage = ModelTokenUsage.empty;
}
