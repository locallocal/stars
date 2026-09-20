part of 'task_runtime_factory.dart';

extension _TaskRuntimePreparation on TaskRuntimeFactory {
  Future<TaskExecutionPreparation> _prepare(
    ConversationTask task,
    Bot bot,
    AgentCancellationToken cancellation,
  ) async {
    final preparer = prepare;
    final repository = messages;
    if (preparer == null || repository == null) {
      throw StateError('Background preparation is unavailable.');
    }
    cancellation.throwIfCancelled();
    final history = await repository.getMessages(task.chatId);
    final origin = history.indexWhere(
      (message) =>
          message.messageId == task.originUserMessageId &&
          message.turnId == task.originTurnId &&
          message.botId == task.botId,
    );
    if (origin < 0) throw StateError('The accepted input is unavailable.');
    final user = history[origin];
    final prepared = await preparer(
      chatId: task.chatId,
      bot: bot,
      history: history.take(origin).toList(),
      userMessage: user,
      currentUserId: user.senderId,
      backgroundTaskObjective: task.objective,
      cancellation: cancellation,
    );
    cancellation.throwIfCancelled();
    final available = OverlayToolRegistry(
      parent: registry,
      overlayTools: prepared.runScopedTools,
    );
    final selected = <TaskToolAdapter>[];
    for (final name in {
      ...prepared.requestedToolNames,
      ...prepared.verificationToolNames,
    }) {
      final tool = available.find(name);
      if (tool == null) continue;
      final adapter = _adapter(name, tool);
      if (adapter != null) selected.add(adapter);
    }
    final names = selected.map((adapter) => adapter.definition.name).toSet();
    return TaskExecutionPreparation(
      snapshot: TaskPreparationSnapshot(
        context: [
          for (final message in prepared.messages)
            TaskContextMessage(
              role: TaskContextRole.values.byName(message.role),
              content: message.content,
              assetReferences: [...message.images, ...message.files],
            ),
        ],
        allowedToolNames: names,
        approvalExemptToolNames: prepared.approvalExemptToolNames.intersection(
          names,
        ),
      ),
      tools: selected,
      tokenUsage: prepared.preflightTokenUsage,
    );
  }
}
