import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/models/skill_records.dart';
import 'package:stars/data/repositories/sqlite_bot_repository.dart';
import 'package:stars/data/repositories/sqlite_bot_skill_binding_repository.dart';
import 'package:stars/data/repositories/sqlite_chat_repository.dart';
import 'package:stars/data/repositories/sqlite_conversation_skill_pin_repository.dart';
import 'package:stars/data/repositories/sqlite_profile_repository.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/repositories/sqlite_skill_run_repository.dart';
import 'package:stars/data/services/bot_api_key_cipher.dart';
import 'package:stars/data/services/conversation_summary_storage.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database database;
  late LocalDatabaseService localDatabase;
  late SqliteChatRepository chatRepository;
  late SqliteBotRepository botRepository;
  late SecureBotApiKeyCipher apiKeyCipher;
  late SqliteBotSkillBindingRepository bindingRepository;
  late SqliteSkillRunRepository skillRunRepository;
  late SqliteConversationSkillPinRepository pinRepository;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onConfigure: DatabaseService.configure,
        onCreate: DatabaseService.createSchema,
      ),
    );
    localDatabase = LocalDatabaseService(
      databaseProvider: () async => database,
    );
    chatRepository = SqliteChatRepository(localDatabase: localDatabase);
    apiKeyCipher = SecureBotApiKeyCipher();
    botRepository = SqliteBotRepository(
      localDatabase: localDatabase,
      chatRepository: chatRepository,
      apiKeyCipher: apiKeyCipher,
    );
    bindingRepository = SqliteBotSkillBindingRepository(
      localDatabase: localDatabase,
    );
    skillRunRepository = SqliteSkillRunRepository(localDatabase: localDatabase);
    pinRepository = SqliteConversationSkillPinRepository(
      localDatabase: localDatabase,
    );
  });

  tearDown(() async {
    await bindingRepository.dispose();
    await pinRepository.dispose();
    await botRepository.dispose();
    await chatRepository.dispose();
    await database.close();
  });

  test('empty bot results are cached until an explicit refresh', () async {
    expect(await botRepository.getBots(), isEmpty);
    final bot = _bot();
    await database.insert(
      'bots',
      BotRecord.fromDomain(
        bot,
        storedApiKey: await apiKeyCipher.encrypt(
          botId: bot.id,
          apiKey: bot.apiKey,
        ),
      ).values,
    );

    expect(await botRepository.getBots(), isEmpty);
    expect(await botRepository.getBots(forceRefresh: true), hasLength(1));
  });

  test(
    'message history cache stays coherent across writes and clears',
    () async {
      final repository = SqliteMessageRepository(localDatabase: localDatabase);
      final bot = _bot();
      final timestamp = DateTime(2026, 8, 10, 10);
      await botRepository.addBot(bot);
      await localDatabase.insertChat(
        ChatRecord.fromDomain(
          Chat(
            id: 'chat-cache',
            botId: bot.id,
            lastMessageTimestamp: timestamp,
            createTimestamp: timestamp,
            modifyTimestamp: timestamp,
          ),
        ).values,
      );
      final original = Message(
        messageId: 'message-cache',
        turnId: 'turn-cache',
        chatId: 'chat-cache',
        botId: bot.id,
        senderId: 'me',
        content: 'before',
        timestamp: timestamp,
      );
      await repository.upsertMessage(original);

      final firstPage = await repository.getMessagePage('chat-cache');
      final cachedPage = await repository.getMessagePage('chat-cache');
      expect(cachedPage, same(firstPage));
      expect(repository.peekMessages('chat-cache'), same(firstPage.messages));

      await repository.upsertMessage(original.copyWith(content: 'after'));
      final updatedPage = await repository.getMessagePage('chat-cache');
      expect(updatedPage, isNot(same(firstPage)));
      expect(updatedPage.messages.single.content, 'after');
      expect(repository.peekMessages('chat-cache'), same(updatedPage.messages));

      await localDatabase.clearChatHistory('chat-cache', timestamp);
      expect(repository.peekMessages('chat-cache'), isNull);
      expect(await repository.getMessages('chat-cache'), isEmpty);
    },
  );

  test('message pages use a stable timestamp and id cursor', () async {
    final repository = SqliteMessageRepository(localDatabase: localDatabase);
    addTearDown(repository.dispose);
    final bot = _bot();
    final timestamp = DateTime(2026, 8, 10, 10);
    await botRepository.addBot(bot);
    await localDatabase.insertChat(
      ChatRecord.fromDomain(
        Chat(
          id: 'chat-paged',
          botId: bot.id,
          lastMessageTimestamp: timestamp,
          createTimestamp: timestamp,
          modifyTimestamp: timestamp,
        ),
      ).values,
    );
    await repository.upsertMessages([
      for (var index = 0; index < 55; index++)
        Message(
          messageId: 'message-${index.toString().padLeft(3, '0')}',
          turnId: 'turn-$index',
          chatId: 'chat-paged',
          botId: bot.id,
          senderId: 'me',
          content: '$index',
          timestamp: timestamp,
        ),
    ]);

    final recent = await repository.getMessagePage('chat-paged');
    final older = await repository.getMessagePage(
      'chat-paged',
      before: recent.nextCursor,
    );

    expect(recent.messages, hasLength(50));
    expect(recent.messages.first.messageId, 'message-005');
    expect(recent.messages.last.messageId, 'message-054');
    expect(recent.hasMore, isTrue);
    expect(older.messages, hasLength(5));
    expect(older.messages.first.messageId, 'message-000');
    expect(older.messages.last.messageId, 'message-004');
    expect(older.hasMore, isFalse);
  });

  test('a growing cached window keeps its earlier-page cursor', () async {
    final repository = SqliteMessageRepository(localDatabase: localDatabase);
    addTearDown(repository.dispose);
    final bot = _bot();
    final timestamp = DateTime(2026, 8, 10, 11);
    await botRepository.addBot(bot);
    await localDatabase.insertChat(
      ChatRecord.fromDomain(
        Chat(
          id: 'chat-growing-page',
          botId: bot.id,
          lastMessageTimestamp: timestamp,
          createTimestamp: timestamp,
          modifyTimestamp: timestamp,
        ),
      ).values,
    );
    await repository.upsertMessages([
      for (var index = 0; index < 50; index++)
        Message(
          messageId: 'growing-${index.toString().padLeft(3, '0')}',
          turnId: 'turn-$index',
          chatId: 'chat-growing-page',
          botId: bot.id,
          senderId: 'me',
          content: '$index',
          timestamp: timestamp.add(Duration(milliseconds: index)),
        ),
    ]);
    final initial = await repository.getMessagePage('chat-growing-page');
    expect(initial.hasMore, isFalse);

    await repository.upsertMessage(
      Message(
        messageId: 'growing-050',
        turnId: 'turn-50',
        chatId: 'chat-growing-page',
        botId: bot.id,
        senderId: 'me',
        content: '50',
        timestamp: timestamp.add(const Duration(milliseconds: 50)),
      ),
    );

    final current = repository.peekMessagePage('chat-growing-page')!;
    expect(current.messages, hasLength(50));
    expect(current.hasMore, isTrue);
    final earlier = await repository.getMessagePage(
      'chat-growing-page',
      before: current.nextCursor,
    );
    expect(earlier.messages.single.messageId, 'growing-000');
  });

  test('bot update persists every field with millisecond timestamps', () async {
    final original = _bot();
    await botRepository.addBot(original);
    final modifiedAt = DateTime.fromMillisecondsSinceEpoch(1770000000123);
    final updated = Bot(
      id: original.id,
      name: 'Updated',
      avatar: '/avatar.png',
      provider: 'Custom',
      baseURL: 'https://updated.test',
      apiKey: 'new-secret',
      apiType: Bot.apiTypeAnthropic,
      model: 'updated-model',
      systemPrompt: 'updated prompt',
      parameters: const {'temperature': 0.2},
      createTimestamp: original.createTimestamp,
      modifyTimestamp: modifiedAt,
    );

    await botRepository.updateBot(updated);

    final rows = await database.query(
      'bots',
      where: 'id = ?',
      whereArgs: [original.id],
    );
    final record = BotRecord(rows.single);
    expect(record.storedApiKey, isNot('new-secret'));
    expect(apiKeyCipher.isEncrypted(record.storedApiKey), isTrue);
    final decryptedApiKey = await apiKeyCipher.decrypt(
      botId: original.id,
      encrypted: record.storedApiKey,
    );
    final persisted = record.toDomain(apiKey: decryptedApiKey);
    expect(persisted.apiKey, 'new-secret');
    expect(persisted.apiType, Bot.apiTypeAnthropic);
    expect(persisted.parameters, {'temperature': 0.2});
    expect(persisted.modifyTimestamp, modifiedAt);
  });

  test('plaintext Bot API keys are rejected as non-current data', () async {
    final bot = _bot();
    await database.insert(
      'bots',
      BotRecord.fromDomain(bot, storedApiKey: bot.apiKey).values,
    );

    await expectLater(
      botRepository.getBot(bot.id),
      throwsA(isA<FormatException>()),
    );
    final rows = await database.query('bots', columns: ['api_key']);
    expect(rows.single['api_key'], bot.apiKey);
  });

  test(
    'profile repository creates one default and publishes updates',
    () async {
      final repository = SqliteProfileRepository(
        localDatabase: localDatabase,
        defaultFontSize: ProfileDefaults.desktopFontSize,
      );
      addTearDown(repository.dispose);
      final changes = <Profile>[];
      final subscription = repository.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      final profile = await repository.getProfile();
      expect(profile.fontSize, ProfileDefaults.desktopFontSize);
      expect(profile.showExecutionStatus, isTrue);
      expect(profile.injectApplicationPrompt, isTrue);
      final updated = profile.copyWith(
        name: 'Earthwind',
        fontSize: 18,
        themeMode: 2,
        language: 'en_US',
        showExecutionStatus: false,
        injectApplicationPrompt: false,
        modifyTimestamp: DateTime(2026, 7, 21),
      );
      await repository.updateProfile(updated);
      await Future<void>.delayed(Duration.zero);

      final rows = await database.query('profile');
      expect(rows, hasLength(1));
      expect(rows.single['show_execution_status'], 0);
      expect(rows.single['inject_application_prompt'], 0);
      expect(await repository.getProfile(), same(updated));
      expect(changes, [updated]);
    },
  );

  test('message repository aggregates persisted token usage by bot', () async {
    final repository = SqliteMessageRepository(localDatabase: localDatabase);
    final timestamp = DateTime(2026, 7, 25);
    await botRepository.addBot(_bot());
    await botRepository.addBot(_bot(id: 'bot-2'));
    for (final entry
        in const <String, String>{
          'chat-1': 'bot-1',
          'chat-2': 'bot-1',
          'chat-3': 'bot-2',
        }.entries) {
      await localDatabase.insertChat(
        ChatRecord.fromDomain(
          Chat(
            id: entry.key,
            botId: entry.value,
            lastMessageTimestamp: timestamp,
            createTimestamp: timestamp,
            modifyTimestamp: timestamp,
          ),
        ).values,
      );
    }
    await repository.upsertMessages([
      Message(
        messageId: 'assistant-1',
        turnId: 'turn-1',
        chatId: 'chat-1',
        botId: 'bot-1',
        senderId: 'bot-1',
        content: 'First',
        tokenUsage: const ModelTokenUsage(
          model: 'model-a',
          inputTokens: 100,
          outputTokens: 40,
          totalTokens: 140,
        ),
        timestamp: timestamp,
      ),
      Message(
        messageId: 'assistant-2',
        turnId: 'turn-2',
        chatId: 'chat-2',
        botId: 'bot-1',
        senderId: 'bot-1',
        content: 'Second',
        tokenUsage: const ModelTokenUsage(
          model: 'model-b',
          inputTokens: 80,
          outputTokens: 20,
          totalTokens: 100,
        ),
        timestamp: timestamp,
      ),
      Message(
        messageId: 'other-bot',
        turnId: 'turn-3',
        chatId: 'chat-3',
        botId: 'bot-2',
        senderId: 'bot-2',
        content: 'Other',
        tokenUsage: const ModelTokenUsage(
          inputTokens: 1000,
          outputTokens: 1000,
          totalTokens: 2000,
        ),
        timestamp: timestamp,
      ),
    ]);
    await database.update(
      'token_usage_records',
      {'total_token_count': 0},
      where: 'message_id = ?',
      whereArgs: ['assistant-1'],
    );

    final usage = await repository.getTokenUsageForBot('bot-1');
    expect(usage.inputTokens, 180);
    expect(usage.outputTokens, 60);
    expect(usage.effectiveTotalTokens, 240);
    final batchedUsage = await repository.getTokenUsageForBots([
      'bot-1',
      'bot-2',
      'missing',
    ]);
    expect(batchedUsage['bot-1']?.effectiveTotalTokens, 240);
    expect(batchedUsage['bot-2']?.effectiveTotalTokens, 2000);
    expect(batchedUsage['missing'], ModelTokenUsage.empty);

    final usageByChat = await repository.getTokenUsageByChatForBot('bot-1');
    expect(usageByChat.keys, ['chat-1', 'chat-2']);
    expect(usageByChat['chat-1']?.effectiveTotalTokens, 140);
    expect(usageByChat['chat-2']?.effectiveTotalTokens, 100);
    final usageRecords = await repository.getTokenUsageRecordsForBot('bot-1');
    expect(usageRecords.map((record) => record.chatId), ['chat-1', 'chat-2']);

    final persisted = await repository.getMessages('chat-1');
    expect(persisted.single.tokenUsage.model, 'model-a');
    expect(persisted.single.tokenUsage.effectiveTotalTokens, 140);
  });

  test('chat deletion retains usage until the bot is deleted', () async {
    final repository = SqliteMessageRepository(localDatabase: localDatabase);
    final bot = _bot();
    final timestamp = DateTime(2026, 7, 25, 10);
    await botRepository.addBot(bot);
    await localDatabase.insertChat(
      ChatRecord.fromDomain(
        Chat(
          id: 'chat-clear',
          botId: bot.id,
          lastMessageTimestamp: timestamp,
          createTimestamp: timestamp,
          modifyTimestamp: timestamp,
        ),
      ).values,
    );
    await repository.upsertMessage(
      Message(
        messageId: 'assistant-clear',
        turnId: 'turn-clear',
        chatId: 'chat-clear',
        botId: 'bot-1',
        senderId: 'bot-1',
        content: 'Response to clear',
        tokenUsage: const ModelTokenUsage(
          model: 'model-a',
          inputTokens: 90,
          outputTokens: 30,
          totalTokens: 120,
        ),
        timestamp: timestamp,
      ),
    );

    await chatRepository.clearHistory('chat-clear');

    expect(await repository.getMessages('chat-clear'), isEmpty);
    final records = await repository.getTokenUsageRecordsForChat('chat-clear');
    expect(records, hasLength(1));
    expect(records.single.usage.effectiveTotalTokens, 120);
    expect(
      (await repository.getTokenUsageForBot('bot-1')).effectiveTotalTokens,
      120,
    );

    await chatRepository.deleteChat('chat-clear');

    expect(await repository.getMessages('chat-clear'), isEmpty);
    final retained = await repository.getTokenUsageRecordsForChat('chat-clear');
    expect(retained, hasLength(1));
    expect(retained.single.usage.effectiveTotalTokens, 120);
    expect(
      (await repository.getTokenUsageForBot('bot-1')).effectiveTotalTokens,
      120,
    );

    await botRepository.deleteBot(bot.id);

    expect(await repository.getTokenUsageRecordsForChat('chat-clear'), isEmpty);
    expect(await repository.getTokenUsageRecordsForBot(bot.id), isEmpty);
    expect(
      (await repository.getTokenUsageForBot(bot.id)).effectiveTotalTokens,
      0,
    );
  });

  test('Skill bindings round-trip and are removed with their bot', () async {
    final bot = _bot();
    await botRepository.addBot(bot);
    await localDatabase.upsertSkill(
      SkillRecord.fromDomain(_skill('user:release-notes')).values,
    );
    final timestamp = DateTime(2026, 7, 26, 10);
    final binding = BotSkillBinding(
      botId: bot.id,
      skillId: 'user:release-notes',
      priority: 12,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    await bindingRepository.save(binding);

    final restored = await bindingRepository.getForBot(bot.id);
    expect(restored, hasLength(1));
    expect(restored.single.skillId, binding.skillId);
    expect(restored.single.activationMode, SkillActivationMode.auto);
    expect(restored.single.priority, 12);

    await botRepository.deleteBot(bot.id);

    expect(await bindingRepository.getForBot(bot.id), isEmpty);
  });

  test('creates a Bot with a bundled system Skill binding', () async {
    final bot = _bot();
    final timestamp = DateTime(2026, 8, 18);
    final binding = BotSkillBinding(
      botId: bot.id,
      skillId: 'system:shell-command',
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    await botRepository.addBotWithSkillBindings(bot, [binding]);

    expect(await botRepository.getBot(bot.id), isNotNull);
    final restored = await bindingRepository.getForBot(bot.id);
    expect(restored, hasLength(1));
    expect(restored.single.botId, binding.botId);
    expect(restored.single.skillId, binding.skillId);
    expect(await localDatabase.loadSkill(binding.skillId), isEmpty);
  });

  test('Bot and Skill bindings roll back as one transaction', () async {
    final bot = _bot();
    await database.execute('''
      CREATE TRIGGER fail_binding_insert
      BEFORE INSERT ON bot_skill_bindings
      BEGIN
        SELECT RAISE(ABORT, 'injected binding failure');
      END
    ''');

    await expectLater(
      botRepository.addBotWithSkillBindings(bot, [
        BotSkillBinding(
          botId: bot.id,
          skillId: 'user:test',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]),
      throwsA(anything),
    );

    expect(await localDatabase.loadBot(bot.id), isEmpty);
    expect(await bindingRepository.getForBot(bot.id), isEmpty);
  });

  test('Bot deletion rolls back all database rows on failure', () async {
    final bot = _bot();
    final timestamp = DateTime(2026, 8, 10);
    await botRepository.addBot(bot);
    await localDatabase.insertChat(
      ChatRecord.fromDomain(
        Chat(
          id: 'chat-delete-rollback',
          botId: bot.id,
          lastMessageTimestamp: timestamp,
          createTimestamp: timestamp,
          modifyTimestamp: timestamp,
        ),
      ).values,
    );
    final messages = SqliteMessageRepository(localDatabase: localDatabase);
    addTearDown(messages.dispose);
    await messages.upsertMessage(
      Message(
        messageId: 'message-delete-rollback',
        turnId: 'turn-delete-rollback',
        chatId: 'chat-delete-rollback',
        botId: bot.id,
        senderId: 'me',
        content: 'keep me',
        timestamp: timestamp,
      ),
    );
    final documents = await Directory.systemTemp.createTemp(
      'stars-bot-delete-',
    );
    addTearDown(() async {
      if (await documents.exists()) await documents.delete(recursive: true);
    });
    final chatDirectory = await Directory(
      path.join(documents.path, 'chats', 'chat-delete-rollback'),
    ).create(recursive: true);
    final attachment = File(path.join(chatDirectory.path, 'attachment.txt'));
    await attachment.writeAsString('keep attachment');
    final stagedChatRepository = SqliteChatRepository(
      localDatabase: localDatabase,
      conversationSummaryStorage: ConversationSummaryStorage(
        documentsDirectoryProvider: () async => documents,
      ),
    );
    final stagedBotRepository = SqliteBotRepository(
      localDatabase: localDatabase,
      chatRepository: stagedChatRepository,
      apiKeyCipher: apiKeyCipher,
    );
    addTearDown(stagedBotRepository.dispose);
    addTearDown(stagedChatRepository.dispose);
    await database.execute('''
      CREATE TRIGGER fail_bot_delete
      BEFORE DELETE ON bots
      BEGIN
        SELECT RAISE(ABORT, 'injected bot delete failure');
      END
    ''');

    await expectLater(stagedBotRepository.deleteBot(bot.id), throwsA(anything));

    expect(await localDatabase.loadBot(bot.id), hasLength(1));
    expect(await localDatabase.loadChat('chat-delete-rollback'), hasLength(1));
    expect(
      await localDatabase.loadMessages('chat-delete-rollback'),
      hasLength(1),
    );
    expect(await attachment.readAsString(), 'keep attachment');
  });

  test('Skill activation audit records round-trip by run', () async {
    final startedAt = DateTime(2026, 7, 26, 10);
    final completedAt = startedAt.add(const Duration(milliseconds: 8));
    await skillRunRepository.saveActivations([
      SkillActivationRecord(
        id: 'run-1:user:release-notes',
        runId: 'run-1',
        chatId: 'chat-1',
        messageId: 'message-1',
        skillId: 'user:release-notes',
        skillName: 'release-notes',
        contentDigest: 'abc123',
        trigger: SkillActivationTrigger.model,
        status: SkillActivationStatus.activated,
        startedAt: startedAt,
        completedAt: completedAt,
        durationMs: 8,
      ),
    ]);

    final restored = await skillRunRepository.getForRun('run-1');

    expect(restored, hasLength(1));
    expect(restored.single.skillName, 'release-notes');
    expect(restored.single.contentDigest, 'abc123');
    expect(restored.single.trigger, SkillActivationTrigger.model);
    expect(restored.single.status, SkillActivationStatus.activated);
    expect(restored.single.durationMs, 8);
    expect(restored.single.completedAt, completedAt);
  });

  test('conversation Skill pins round-trip and clear with chat', () async {
    final bot = _bot();
    final timestamp = DateTime(2026, 7, 27, 9);
    await botRepository.addBot(bot);
    await localDatabase.upsertSkill(
      SkillRecord.fromDomain(_skill('user:release-notes')).values,
    );
    await localDatabase.insertChat(
      ChatRecord.fromDomain(
        Chat(
          id: 'chat-pinned',
          botId: bot.id,
          lastMessageTimestamp: timestamp,
          createTimestamp: timestamp,
          modifyTimestamp: timestamp,
        ),
      ).values,
    );
    final pin = ConversationSkillPin(
      chatId: 'chat-pinned',
      skillId: 'user:release-notes',
      createdAt: timestamp,
    );

    await pinRepository.save(pin);
    expect(await pinRepository.getForChat(pin.chatId), hasLength(1));

    await localDatabase.deleteChat(pin.chatId);

    expect(await pinRepository.getForChat(pin.chatId), isEmpty);
  });
}

Bot _bot({String id = 'bot-1'}) => Bot(
  id: id,
  name: 'Assistant',
  avatar: '',
  provider: 'OpenAI',
  baseURL: 'https://example.test',
  apiKey: 'secret',
  apiType: Bot.apiTypeOpenAI,
  model: 'model',
  systemPrompt: '',
  parameters: const {'temperature': 0.7},
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

SkillDescriptor _skill(String id) => SkillDescriptor(
  id: id,
  name: id.split(':').last,
  description: 'Test Skill',
  version: '1.0.0',
  scope: SkillScope.user,
  sourceUri: 'file:///$id',
  rootPath: '/skills/$id',
  contentDigest: 'digest-$id',
  trustState: SkillTrustState.userReviewed,
  validationStatus: SkillValidationStatus.valid,
  compatibility: 'Stars',
  installedAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
