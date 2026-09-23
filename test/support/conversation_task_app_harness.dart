import 'package:stars/domain/use_cases/conversation_message_file_cache.dart';
import 'package:stars/domain/use_cases/resolve_message_local_files.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/repositories/file_skill_repository.dart';
import 'package:stars/data/repositories/memory_conversation_draft_repository.dart';
import 'package:stars/data/repositories/local_conversation_directory_repository.dart';
import 'package:stars/data/repositories/sqlite_bot_repository.dart';
import 'package:stars/data/repositories/sqlite_bot_skill_binding_repository.dart';
import 'package:stars/data/repositories/sqlite_chat_repository.dart';
import 'package:stars/data/repositories/sqlite_conversation_history_repository.dart';
import 'package:stars/data/repositories/sqlite_conversation_memory_repository.dart';
import 'package:stars/data/repositories/sqlite_mcp_inventory_repository.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/repositories/sqlite_profile_repository.dart';
import 'package:stars/data/repositories/sqlite_skill_inventory_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/data/services/bot_api_key_cipher.dart';
import 'package:stars/data/services/conversation_summary_storage.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/data/services/skills/skill_package_storage_service.dart';
import 'package:stars/data/services/skills/skill_parser.dart';
import 'package:stars/data/services/task_tool_adapters.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/compact_conversation.dart';
import 'package:stars/domain/use_cases/create_user_message.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/domain/use_cases/get_conversation_task_execution.dart';
import 'package:stars/domain/use_cases/get_task_message_execution.dart';
import 'package:stars/domain/use_cases/persist_conversation_assets.dart';
import 'package:stars/domain/use_cases/prepare_conversation_context.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';
import 'package:stars/ui/core/dependency_injection/app_dependencies.dart';
import 'package:stars/ui/features/app/view_models/startup_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/view_models/model_log_view_model.dart';

import 'foreground_turn_fixtures.dart' show foregroundBot, routeFrames;
import 'task_runner_harness.dart' show RunnerClock;

part 'conversation_task_app_provider.dart';
part 'conversation_task_app_job.dart';

/// Real database, preparation, repositories and production task composition.
/// Only the provider, external job service, key vault and clock are controlled.
final class ConversationTaskAppHarness implements AppDependencies {
  @override
  late final GetTaskMessageExecution taskMessageExecution =
      GetTaskMessageExecution(
        () => GetConversationTaskExecution(conversationTasks.repository),
      );

  @override
  late final ConversationMessageFileCache conversationMessageFiles =
      ConversationMessageFileCache(
        createResolver:
            (chatId) => ResolveMessageLocalFiles(
              repository: messageActionRepository,
              evidenceRepository: toolEvidenceRepository,
              directoryProvider:
                  () => conversationArtifactsDirectoryProvider(chatId),
            ),
      );

  final clock = RunnerClock();
  late Directory directory;
  late Database database;
  late LocalDatabaseService local;
  late AcceptanceProviders providers;
  late AcceptanceJobClient job;
  late SqliteConversationMemoryRepository memory;
  late FileSkillRepository skills;
  late SqliteBotSkillBindingRepository bindings;
  @override
  late SqliteProfileRepository profileRepository;
  @override
  late SqliteBotRepository botRepository;
  @override
  late SqliteChatRepository chatRepository;
  @override
  late SqliteMessageRepository messageRepository;
  @override
  late SqliteToolEvidenceRepository toolEvidenceRepository;
  @override
  late MemoryConversationDraftRepository conversationDraftRepository;
  @override
  late PrepareTextGeneration prepareTextGeneration;
  @override
  late AppConversationTasks conversationTasks;
  @override
  late ChatGenerationRegistry generationRegistry;
  ModelLogViewModel? Function(String chatId)? modelLogViewModelFactory;
  @override
  ModelLogViewModel? createModelLogViewModel(String chatId) =>
      modelLogViewModelFactory?.call(chatId);

  Bot get bot => foregroundBot(provider: 'openai');

  @override
  SqliteConversationMemoryRepository get conversationMemoryRepository => memory;
  @override
  ConversationArtifactsDirectoryProvider
  get conversationArtifactsDirectoryProvider =>
      (id) async => '${directory.path}/Stars/chats/$id';
  @override
  CompactConversation get compactConversation => CompactConversation(
    messageRepository: messageRepository,
    memoryRepository: memory,
    summarizerFactory: (_) => throw UnsupportedError('Unexpected compaction'),
  );
  @override
  LocalConversationDirectoryRepository get conversationDirectoryRepository =>
      LocalConversationDirectoryRepository(
        directoryProvider: conversationArtifactsDirectoryProvider,
      );

  Future<void> open() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp('stars-task-acceptance-');
    await _compose();
    await botRepository.addBot(bot);
    await local.insertChat(
      ChatRecord.fromDomain(
        Chat(
          id: 'chat-1',
          botId: bot.id,
          lastMessageTimestamp: clock.now(),
          createTimestamp: clock.now(),
          modifyTimestamp: clock.now(),
        ),
      ).values,
    );
    await start();
  }

  Future<void> _compose() async {
    conversationMessageFiles.clear();
    taskMessageExecution.clear();
    database =
        await DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        ).initDatabase();
    local = LocalDatabaseService(databaseProvider: () async => database);
    conversationDraftRepository = MemoryConversationDraftRepository();
    final summaries = ConversationSummaryStorage(
      documentsDirectoryProvider:
          () async => Directory('${directory.path}/Stars'),
    );
    memory = SqliteConversationMemoryRepository(
      localDatabase: local,
      storage: summaries,
    );
    chatRepository = SqliteChatRepository(
      localDatabase: local,
      conversationMemoryRepository: memory,
      conversationSummaryStorage: summaries,
      conversationDraftRepository: conversationDraftRepository,
    );
    messageRepository = SqliteMessageRepository(localDatabase: local);
    botRepository = SqliteBotRepository(
      localDatabase: local,
      chatRepository: chatRepository,
      apiKeyCipher: _TestVault(),
    );
    profileRepository = SqliteProfileRepository(localDatabase: local);
    toolEvidenceRepository = SqliteToolEvidenceRepository(localDatabase: local);
    bindings = SqliteBotSkillBindingRepository(localDatabase: local);
    skills = FileSkillRepository(
      localDatabase: local,
      parser: const SkillParser(),
      storageService: SkillPackageStorageService(
        applicationSupportDirectoryProvider: () async => directory,
      ),
    );
    final history = SqliteConversationHistoryRepository(
      messageRepository: messageRepository,
    );
    final skillInventory = SqliteSkillInventoryRepository(localDatabase: local);
    final mcpInventory = SqliteMcpInventoryRepository(localDatabase: local);
    providers = AcceptanceProviders();
    job = AcceptanceJobClient(
      File('${directory.path}/external-service.json'),
      clock,
    );
    final tool = AcceptanceReportTool();
    final registry = StaticToolRegistry([tool]);
    final compose = ComposeChatTurn(
      skillRepository: skills,
      bindingRepository: bindings,
      bundledSkillLoader: () async => const [],
      conversationArtifactsDirectoryProvider:
          (id) async => '${directory.path}/Stars/chats/$id',
      prepareConversationContext: PrepareConversationContext(
        memoryRepository: memory,
        aiProviderRepository: providers,
        toolEvidenceRepository: toolEvidenceRepository,
      ),
    );
    prepareTextGeneration = PrepareTextGeneration(
      composeChatTurn: compose.call,
      aiProviderRepository: providers,
      conversationHistoryRepository: history,
      skillInventoryRepository: skillInventory,
      mcpInventoryRepository: mcpInventory,
      toolRegistry: registry,
      verificationToolCandidateNames: {tool.definition.name},
    );
    conversationTasks = createAppConversationTasks(
      database: local,
      clock: clock,
      messages: messageRepository,
      drafts: conversationDraftRepository,
      prepare: prepareTextGeneration,
      bots: botRepository,
      chats: chatRepository,
      providers: providers,
      registry: registry,
      policy: const DefaultToolPolicy(),
      history: history,
      skills: skillInventory,
      mcp: mcpInventory,
      adapters: {
        tool.definition.name: JobTaskToolAdapter(
          definition: tool.definition,
          client: job,
          checkpointArgumentNames: {'report'},
          guaranteesIdempotency: true,
        ),
      },
    );
    generationRegistry = ChatGenerationRegistry(
      dispatcher: conversationTasks.dispatcher,
      taskProgress: conversationTasks.progress,
      providerFactory: providers.create,
    );
  }

  Future<void> start() async {
    final startup = StartupViewModel(
      profileRepository: profileRepository,
      recoveryInitializer: conversationTasks.start,
    );
    try {
      await startup.load();
      expectSync(startup.hasError, isFalse);
      expectSync(startup.profile, isNotNull);
    } finally {
      startup.dispose();
    }
  }

  Future<void> restart({bool startImmediately = true}) async {
    await _disposeComposition();
    await _compose();
    if (startImmediately) await start();
  }

  Future<void> _disposeComposition() async {
    await conversationTasks.dispose();
    await conversationTasks.progress.settle();
    generationRegistry.clear();
    await messageRepository.dispose();
    await chatRepository.dispose();
    await botRepository.dispose();
    await profileRepository.dispose();
    await bindings.dispose();
    await skills.dispose();
    await database.close();
  }

  Future<void> close() async {
    await _disposeComposition();
    await directory.delete(recursive: true);
  }

  Future<ConversationTask> task() async =>
      (await conversationTasks.repository.getByOriginTurnId(
        (await messageRepository.getMessages('chat-1'))
            .firstWhere(
              (m) => m.taskMessageKind == TaskMessageKind.acknowledgement,
            )
            .turnId,
      ))!;

  Future<Map<String, int>> integrity() async {
    Future<int> count(String sql) async =>
        (await database.rawQuery(sql)).single.values.single as int;
    return {
      'acknowledgementsWithoutTask': await count(
        "SELECT COUNT(*) FROM messages m LEFT JOIN conversation_tasks t ON t.task_id=m.task_id WHERE m.task_message_kind='taskAcknowledgement' AND t.task_id IS NULL",
      ),
      'duplicateResults': await count(
        "SELECT COUNT(*) FROM (SELECT task_id FROM messages WHERE task_message_kind='taskResult' GROUP BY task_id HAVING COUNT(*) > 1)",
      ),
      'terminalWithoutResult': await count(
        "SELECT COUNT(*) FROM conversation_tasks t LEFT JOIN messages m ON m.message_id=t.task_id || ':result' WHERE t.status IN ('succeeded','failed','cancelled') AND m.message_id IS NULL",
      ),
    };
  }

  @override
  AiProviderRepository get aiProviderRepository => providers;
  @override
  AttachmentRepository get attachmentRepository => _NoAttachments();
  @override
  MessageActionRepository get messageActionRepository => _NoActions();
  @override
  CreateUserMessage get createUserMessage =>
      CreateUserMessage(messageRepository: messageRepository);
  @override
  PersistConversationAssets get persistConversationAssets =>
      PersistConversationAssets(repository: attachmentRepository);
  @override
  GenerateMediaTurn get generateMediaTurn => GenerateMediaTurn(
    messageRepository: messageRepository,
    chatRepository: chatRepository,
    providerRepository: providers,
    attachmentRepository: attachmentRepository,
    persistConversationAssets: persistConversationAssets,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected dependency: ${invocation.memberName}');
}

final class _TestVault implements BotApiKeyCipher {
  @override
  bool isEncrypted(String value) => value == 'fixture-ciphertext';
  @override
  Future<String> encrypt({
    required String botId,
    required String apiKey,
  }) async => 'fixture-ciphertext';
  @override
  Future<String> decrypt({
    required String botId,
    required String encrypted,
  }) async {
    if (!isEncrypted(encrypted)) throw StateError('Invalid test ciphertext');
    return foregroundBot().apiKey;
  }
}

final class _NoAttachments implements ConversationAssetRepository {
  @override
  Future<List<String>> persistAssets({
    required String chatId,
    required Iterable<String> sourcePaths,
  }) async {
    expectSync(sourcePaths, isEmpty);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected attachment operation');
}

final class _NoActions implements MessageActionRepository {
  @override
  String? get localFileHomeDirectory => null;

  @override
  Future<bool> localFileExists(String path) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected platform action');
}
