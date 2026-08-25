part of 'chat_generation_view_model.dart';

extension _ChatGenerationPersistence on ChatGenerationViewModel {
  bool _isActiveRun(String runId) =>
      _acceptsAsyncCallbacks && _snapshot.runId == runId;

  bool _canReduceProviderEvent(String runId) =>
      _isActiveRun(runId) &&
      !_snapshot.lifecycle.isTerminal &&
      !_finalizingRuns.contains(runId);

  void _schedulePartialPersistence(String runId) {
    if (!_canReduceProviderEvent(runId) || !_hasGeneratedContent) return;
    if (_partialPersistenceTimer != null) return;
    _partialPersistenceTimer = Timer(_partialPersistenceInterval, () {
      _partialPersistenceTimer = null;
      if (!_canReduceProviderEvent(runId) || !_hasGeneratedContent) return;
      final draft = _buildPartialAssistantMessage(runId);
      _partialPersistenceQueue = _partialPersistenceQueue.then(
        (_) => _persistPartialSafely(draft),
      );
    });
  }

  bool get _hasGeneratedContent =>
      _snapshot.streamingResponse.isNotEmpty ||
      _snapshot.reasoningResponse.isNotEmpty ||
      _snapshot.toolCalls.isNotEmpty ||
      _snapshot.commandExecutions.isNotEmpty ||
      _snapshot.skillActivations.isNotEmpty ||
      _snapshot.localFiles.isNotEmpty;

  Message _buildPartialAssistantMessage(String runId) {
    final duration =
        _startedAt == null
            ? null
            : DateTime.now().difference(_startedAt!).inMilliseconds;
    return Message(
      messageId: '$runId:assistant',
      turnId: _snapshot.turnId ?? runId,
      runId: runId,
      chatId: chatId,
      botId: _bot.id,
      senderId: _bot.id,
      content: _snapshot.streamingResponse,
      reasoning: _snapshot.reasoningResponse,
      processInfo: MessageProcessInfo(
        reasoningStatus: _snapshot.reasoningResponse.isEmpty ? '' : 'streaming',
        durationMs: duration,
        toolCalls: List<MessageToolCall>.of(_snapshot.toolCalls),
        commandExecutions: List<MessageCommandExecution>.of(
          _snapshot.commandExecutions,
        ),
        skillActivations: List<MessageSkillActivation>.of(
          _snapshot.skillActivations,
        ),
      ),
      tokenUsage: _snapshot.tokenUsage,
      files: List<String>.of(_snapshot.localFiles),
      hasPartialContent: true,
      timestamp: _startedAt ?? DateTime.now(),
    );
  }

  Future<void> _persistPartialSafely(Message draft) async {
    try {
      await _messagePersister(draft);
    } catch (error) {
      debugPrint(
        'Failed to persist incremental response for ${draft.runId}: $error',
      );
    }
  }

  Future<void> _updateLastMessageSafely(String content) async {
    try {
      await _lastMessageUpdater(chatId, content);
    } catch (error) {
      debugPrint('Failed to update chat preview for $chatId: $error');
    }
  }

  Future<void> _persistSkillActivationsSafely({
    required String runId,
    required String messageId,
    required List<ActivatedSkill> activatedSkills,
    required List<SkillActivationAttempt> activationAttempts,
  }) async {
    final persister = _skillActivationPersister;
    if (persister == null ||
        (activatedSkills.isEmpty && activationAttempts.isEmpty)) {
      return;
    }
    final startedAt = _startedAt ?? DateTime.now();
    final attempts =
        activationAttempts.isNotEmpty
            ? activationAttempts
            : [
              for (final skill in activatedSkills)
                SkillActivationAttempt(
                  skillId: skill.id,
                  skillName: skill.name,
                  contentDigest: skill.contentDigest,
                  trigger: skill.trigger,
                  status: SkillActivationStatus.activated,
                  startedAt: startedAt,
                  completedAt: DateTime.now(),
                ),
            ];
    try {
      await persister([
        for (var index = 0; index < attempts.length; index++)
          SkillActivationRecord(
            id: '$runId:skill:$index',
            runId: runId,
            chatId: chatId,
            messageId: messageId,
            skillId: attempts[index].skillId,
            skillName: attempts[index].skillName,
            contentDigest: attempts[index].contentDigest,
            trigger: attempts[index].trigger,
            status: attempts[index].status,
            startedAt: attempts[index].startedAt,
            completedAt: attempts[index].completedAt,
            durationMs: attempts[index].durationMs,
            errorCode: attempts[index].errorCode,
          ),
      ]);
    } catch (error) {
      debugPrint('Failed to persist Skill activations for $runId: $error');
    }
  }
}
