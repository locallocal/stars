import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/models/skill_records.dart';
import 'package:stars/data/repositories/sqlite_skill_inventory_repository.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  sqfliteFfiInit();
  late Database database;
  late LocalDatabaseService localDatabase;
  late SqliteSkillInventoryRepository repository;

  setUp(() async {
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
    repository = SqliteSkillInventoryRepository(localDatabase: localDatabase);
  });

  tearDown(() => database.close());

  test(
    'queries installed Skills and binding counts directly from SQLite',
    () async {
      await localDatabase.upsertSkill(
        SkillRecord.fromDomain(
          _skill(
            id: 'user:reviewer',
            name: 'Reviewer',
            description: 'Review pull requests.',
          ),
        ).values,
      );
      await localDatabase.upsertSkill(
        SkillRecord.fromDomain(
          _skill(
            id: 'user:writer',
            name: 'Writer',
            description: 'Write release notes.',
          ),
        ).values,
      );
      await database.insert('bots', _botRow('bot-1'));
      await database.insert('bots', _botRow('bot-2'));
      await localDatabase.upsertBotSkillBinding(
        _binding('bot-1', 'user:reviewer', enabled: true),
      );
      await localDatabase.upsertBotSkillBinding(
        _binding('bot-2', 'user:reviewer', enabled: false),
      );

      final page = await repository.listInstalled(query: 'pull', limit: 10);

      expect(page.truncated, isFalse);
      expect(page.items, hasLength(1));
      expect(page.items.single.id, 'user:reviewer');
      expect(page.items.single.boundBotCount, 2);
      expect(page.items.single.enabledBotCount, 1);

      final byId = await repository.listInstalled(
        query: 'USER:REVIEWER',
        limit: 10,
      );
      expect(byId.items.single.id, 'user:reviewer');

      final bySource = await repository.listInstalled(
        query: 'file:///Reviewer',
        limit: 10,
      );
      expect(bySource.items.single.id, 'user:reviewer');

      final injection = await repository.listInstalled(
        query: "' OR 1=1 --",
        limit: 10,
      );
      expect(injection.items, isEmpty);
    },
  );

  test(
    'queries current conversation bindings, pins, and latest activation',
    () async {
      final now = DateTime(2026, 8, 9, 12);
      await localDatabase.upsertSkill(
        SkillRecord.fromDomain(
          _skill(
            id: 'user:reviewer',
            name: 'Reviewer',
            description: 'Review pull requests.',
          ),
        ).values,
      );
      await localDatabase.upsertSkill(
        SkillRecord.fromDomain(
          _skill(
            id: skillInstallerSkillId,
            name: 'Skill installer',
            description: 'Install Skills.',
          ),
        ).values,
      );
      await database.insert('bots', _botRow('bot-1'));
      await localDatabase.insertChat({
        'id': 'chat-1',
        'bot_id': 'bot-1',
        'last_message': '',
        'last_message_timestamp': now.millisecondsSinceEpoch,
        'create_timestamp': now.millisecondsSinceEpoch,
        'modify_timestamp': now.millisecondsSinceEpoch,
      });
      await localDatabase.upsertBotSkillBinding(
        _binding('bot-1', 'user:reviewer', enabled: true, priority: 7),
      );
      await localDatabase.upsertBotSkillBinding(
        _binding('bot-1', skillInstallerSkillId, enabled: false, priority: 3),
      );
      await localDatabase.upsertConversationSkillPin({
        'chat_id': 'chat-1',
        'skill_id': 'user:reviewer',
        'created_at': now.millisecondsSinceEpoch,
      });
      await expectLater(
        localDatabase.upsertConversationSkillPin({
          'chat_id': 'chat-1',
          'skill_id': 'user:missing',
          'created_at': now.millisecondsSinceEpoch,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await localDatabase.upsertSkillActivations([
        {
          'id': 'activation-1',
          'run_id': 'run-1',
          'chat_id': 'chat-1',
          'message_id': 'message-1',
          'skill_id': 'user:reviewer',
          'skill_name': 'Reviewer',
          'content_digest': 'digest',
          'trigger_type': 'model',
          'status': 'activated',
          'started_at': now.millisecondsSinceEpoch,
          'completed_at': now.millisecondsSinceEpoch,
        },
      ]);

      final items = await repository.listForConversation('chat-1');
      final byId = {for (final item in items) item.id: item};

      expect(byId.keys, {'user:reviewer', skillInstallerSkillId});
      expect(byId['user:reviewer']?.configuredEnabled, isTrue);
      expect(byId['user:reviewer']?.pinnedToConversation, isTrue);
      expect(byId['user:reviewer']?.priority, 7);
      expect(byId['user:reviewer']?.lastActivationStatus, 'activated');
      expect(byId['user:reviewer']?.lastActivatedAt, now);
      expect(byId[skillInstallerSkillId]?.bundled, isTrue);
      expect(byId[skillInstallerSkillId]?.configuredEnabled, isFalse);
      expect(await repository.listForConversation('chat-other'), isEmpty);
    },
  );
}

Map<String, Object?> _botRow(String id) => <String, Object?>{
  'id': id,
  'name': 'Bot',
  'avatar': '',
  'provider': 'Provider',
  'base_url': '',
  'api_key': '',
  'api_type': 'openai',
  'model': 'model',
  'system_prompt': '',
  'parameters': '{}',
  'create_timestamp': 1,
  'modify_timestamp': 1,
};

SkillDescriptor _skill({
  required String id,
  required String name,
  required String description,
}) {
  final now = DateTime(2026, 8, 9);
  return SkillDescriptor(
    id: id,
    name: name,
    description: description,
    version: '1.0.0',
    scope: SkillScope.user,
    sourceUri: 'file:///$name',
    rootPath: '/skills/$name',
    contentDigest: 'digest-$name',
    trustState: SkillTrustState.userReviewed,
    validationStatus: SkillValidationStatus.valid,
    compatibility: 'Stars',
    installedAt: now,
    updatedAt: now,
  );
}

Map<String, Object?> _binding(
  String botId,
  String skillId, {
  required bool enabled,
  int priority = 0,
}) {
  final now = DateTime(2026, 8, 9).millisecondsSinceEpoch;
  return {
    'bot_id': botId,
    'skill_id': skillId,
    'enabled': enabled ? 1 : 0,
    'activation_mode': 'auto',
    'priority': priority,
    'created_at': now,
    'updated_at': now,
  };
}
