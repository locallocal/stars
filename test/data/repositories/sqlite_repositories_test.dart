import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/repositories/sqlite_bot_repository.dart';
import 'package:stars/data/repositories/sqlite_chat_repository.dart';
import 'package:stars/data/repositories/sqlite_profile_repository.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/services/database_service.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late LocalDatabaseService localDatabase;
  late SqliteChatRepository chatRepository;
  late SqliteBotRepository botRepository;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onCreate: DatabaseService.createSchema,
      ),
    );
    localDatabase = LocalDatabaseService(
      databaseProvider: () async => database,
    );
    chatRepository = SqliteChatRepository(localDatabase: localDatabase);
    botRepository = SqliteBotRepository(
      localDatabase: localDatabase,
      chatRepository: chatRepository,
    );
  });

  tearDown(() async {
    await botRepository.dispose();
    await chatRepository.dispose();
    await database.close();
  });

  test('empty bot results are cached until an explicit refresh', () async {
    expect(await botRepository.getBots(), isEmpty);
    await database.insert('bots', BotRecord.fromDomain(_bot()).values);

    expect(await botRepository.getBots(), isEmpty);
    expect(await botRepository.getBots(forceRefresh: true), hasLength(1));
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
    final persisted = BotRecord(rows.single).toDomain();
    expect(persisted.apiType, Bot.apiTypeAnthropic);
    expect(persisted.parameters, {'temperature': 0.2});
    expect(persisted.modifyTimestamp, modifiedAt);
  });

  test(
    'profile repository creates one default and publishes updates',
    () async {
      final repository = SqliteProfileRepository(localDatabase: localDatabase);
      addTearDown(repository.dispose);
      final changes = <Profile>[];
      final subscription = repository.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      final profile = await repository.getProfile();
      final updated = Profile(
        name: 'Earthwind',
        avatar: profile.avatar,
        fontSize: 18,
        themeMode: 2,
        language: 'en_US',
        createTimestamp: profile.createTimestamp,
        modifyTimestamp: DateTime(2026, 7, 21),
      );
      await repository.updateProfile(updated);
      await Future<void>.delayed(Duration.zero);

      expect((await database.query('profile')), hasLength(1));
      expect(await repository.getProfile(), same(updated));
      expect(changes, [updated]);
    },
  );
}

Bot _bot() => Bot(
  id: 'bot-1',
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
