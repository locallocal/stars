part of 'app_dependencies.dart';

/// Application lifetime, independent of conversation routes/view models.
final class AppConversationTasks {
  AppConversationTasks({
    required this.repository,
    required this.scheduler,
    required this.commands,
    required this.deleteConversation,
    required this.deleteBot,
  });
  final ConversationTaskRepository repository;
  final ConversationTaskScheduler scheduler;
  final ConversationTaskCommands commands;
  final DeleteConversation deleteConversation;
  final DeleteBot deleteBot;
  final _lifecycle = TaskExecutionGate();
  bool _initialized = false, _suspended = false, _closed = false;

  Future<void> start() => _lifecycle.run(() async {
    if (_closed) return;
    await scheduler.recovery();
    _initialized = true;
    if (!_suspended) await scheduler.start();
  });

  Future<void> setSuspended(bool suspended) {
    _suspended = suspended;
    return _lifecycle.run(() async {
      if (!_initialized || _closed) return;
      if (_suspended) {
        await scheduler.stop();
      } else {
        await scheduler.start();
      }
    });
  }

  Future<void> dispose() {
    _closed = true;
    return _lifecycle.run(scheduler.stop);
  }
}

AppConversationTasks _createConversationTasks({
  required LocalDatabaseService database,
  required BotRepository bots,
  required ChatRepository chats,
  required AiProviderRepository providers,
  required ToolRegistry registry,
  required ToolPolicy policy,
  required ConversationHistoryRepository history,
  required SkillInventoryRepository skills,
  required McpInventoryRepository mcp,
}) {
  final repository = SqliteConversationTaskRepository(localDatabase: database);
  final random = Random.secure();
  String newId() =>
      List.generate(
        24,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
  final runtime = TaskRuntimeFactory(
    tasks: repository,
    bots: bots,
    providers: providers,
    registry: registry,
    policy: policy,
    scopedTools: (task) async {
      final snapshot = await repository.getExecutionSnapshot(task.taskId);
      final access = TaskHistoryAccess.fromAttempts(
        snapshot?.attempts ?? [],
        chatId: task.chatId,
        turnId: task.originTurnId,
      );
      return [
        ...ConversationHistoryToolSession(
          repository: history,
          chatId: task.chatId,
          runId: task.originTurnId,
          initiallyAllowedReferences: access.references,
          initiallyAllowedCursors: access.cursors,
        ).createTools(),
        ...SkillInventoryToolSession(
          repository: skills,
          chatId: task.chatId,
        ).createTools(),
        ...McpInventoryToolSession(
          repository: mcp,
          chatId: task.chatId,
        ).createTools(),
      ];
    },
  );
  final finalizer = FinalizeConversationTask(
    repository: repository,
    evidenceRepository: SqliteToolEvidenceRepository(localDatabase: database),
    ownerId: newId(),
    newId: newId,
    tools: registry.list(),
    polisher:
        TaskTerminalPolisherFactory(bots: bots, providers: providers).forTask,
  );
  final scheduler = ConversationTaskScheduler(
    repository: repository,
    resolve: runtime.resolve,
    ownerId: newId(),
    newId: newId,
    onReady: finalizer.onReady,
  );
  final commands = ConversationTaskCommands(
    repository: repository,
    wake: scheduler.enqueue,
    metrics: scheduler.metrics,
  );
  return AppConversationTasks(
    repository: repository,
    scheduler: scheduler,
    commands: commands,
    deleteConversation: DeleteConversation(
      chats: chats,
      tasks: repository,
      commands: commands,
    ),
    deleteBot: DeleteBot(repository: bots, tasks: repository),
  );
}
