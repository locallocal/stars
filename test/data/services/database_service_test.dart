import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/services/application_data_directory.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/domain/models/app_failure.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('current database schema', () {
    test('creates exactly the current schema', () async {
      final database = await _openCurrentDatabase();
      addTearDown(database.close);

      await _expectCurrentSchema(database);
    });

    test('replacing a duplicate message id leaves exactly one row', () async {
      final database = await _openCurrentDatabase();
      addTearDown(database.close);

      await database.insert('bots', _botRow('bot-1'));
      await database.insert('chats', _chatRow('chat-1', 'bot-1'));
      const messageId = 'assistant:stable-id';
      await database.insert(
        'messages',
        _messageRow(messageId, 'chat-1', 'bot-1', 'first response'),
      );
      await database.insert(
        'messages',
        _messageRow(messageId, 'chat-1', 'bot-1', 'updated response'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final rows = await database.query(
        'messages',
        where: 'message_id = ?',
        whereArgs: <Object?>[messageId],
      );
      expect(rows, hasLength(1));
      expect(rows.single['content'], 'updated response');
    });

    test(
      'enforces current foreign keys and cascades aggregate deletion',
      () async {
        final database = await _openCurrentDatabase();
        addTearDown(database.close);

        expect(
          (await database.rawQuery('PRAGMA foreign_keys')).single.values.single,
          1,
        );
        await database.insert('bots', _botRow('bot-fk'));
        await database.insert('chats', _chatRow('chat-fk', 'bot-fk'));
        await database.insert(
          'messages',
          _messageRow('message-fk', 'chat-fk', 'bot-fk', 'linked'),
        );
        await database.insert('skills', _skillRow('skill-fk'));
        await database.insert('bot_skill_bindings', <String, Object?>{
          'bot_id': 'bot-fk',
          'skill_id': 'skill-fk',
          'enabled': 1,
          'activation_mode': 'auto',
          'priority': 0,
          'created_at': 1,
          'updated_at': 1,
        });
        await database.insert('conversation_skill_pins', <String, Object?>{
          'chat_id': 'chat-fk',
          'skill_id': 'skill-fk',
          'created_at': 1,
        });

        await database.delete('bots', where: 'id = ?', whereArgs: ['bot-fk']);

        expect(await database.query('chats'), isEmpty);
        expect(await database.query('messages'), isEmpty);
        expect(await database.query('bot_skill_bindings'), isEmpty);
        expect(await database.query('conversation_skill_pins'), isEmpty);
        expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
        expect(
          () =>
              database.insert('chats', _chatRow('orphan-chat', 'missing-bot')),
          throwsA(isA<DatabaseException>()),
        );
      },
    );

    test(
      'allows bundled Skill references without installation records',
      () async {
        final database = await _openCurrentDatabase();
        addTearDown(database.close);

        await database.insert('bots', _botRow('bot-system-skill'));
        await database.insert(
          'chats',
          _chatRow('chat-system-skill', 'bot-system-skill'),
        );
        await database.insert('bot_skill_bindings', <String, Object?>{
          'bot_id': 'bot-system-skill',
          'skill_id': 'system:shell-command',
          'enabled': 1,
          'activation_mode': 'auto',
          'priority': 0,
          'created_at': 1,
          'updated_at': 1,
        });
        await database.insert('conversation_skill_pins', <String, Object?>{
          'chat_id': 'chat-system-skill',
          'skill_id': 'system:shell-command',
          'created_at': 1,
        });

        expect(
          await database.query(
            'skills',
            where: 'id = ?',
            whereArgs: const <Object?>['system:shell-command'],
          ),
          isEmpty,
        );
        expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);

        await database.delete(
          'bots',
          where: 'id = ?',
          whereArgs: const <Object?>['bot-system-skill'],
        );
        expect(await database.query('bot_skill_bindings'), isEmpty);
        expect(await database.query('conversation_skill_pins'), isEmpty);
      },
    );
  });

  group('database version reset policy', () {
    test(
      'migrates the current legacy database into the Stars directory',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'stars_legacy_database_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final legacyDatabasePath = path.join(directory.path, 'app.db');
        final legacyDatabase = await databaseFactoryFfi.openDatabase(
          legacyDatabasePath,
          options: OpenDatabaseOptions(
            version: DatabaseService.databaseVersion,
            onConfigure: DatabaseService.configure,
            onCreate: DatabaseService.createSchema,
          ),
        );
        await legacyDatabase.insert('bots', _botRow('legacy-bot'));
        await legacyDatabase.close();
        final legacyAsset = File(
          path.join(directory.path, 'chats', 'legacy-chat', 'asset.txt'),
        );
        await legacyAsset.parent.create(recursive: true);
        await legacyAsset.writeAsString('legacy asset');

        final service = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );
        final migratedDatabase = await service.initDatabase();
        addTearDown(migratedDatabase.close);

        expect(
          await migratedDatabase.query(
            'bots',
            where: 'id = ?',
            whereArgs: const <Object?>['legacy-bot'],
          ),
          hasLength(1),
        );
        expect(
          await File(
            path.join(
              _applicationDataDirectory(directory).path,
              'chats',
              'legacy-chat',
              'asset.txt',
            ),
          ).readAsString(),
          'legacy asset',
        );
        expect(await File(legacyDatabasePath).exists(), isTrue);
        expect(await legacyAsset.exists(), isTrue);
      },
    );

    test(
      'recovers a Stars backup when another app owns the legacy database',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'stars_shared_database_collision_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final legacyDatabasePath = path.join(directory.path, 'app.db');
        final otherAppDatabase = await databaseFactoryFfi.openDatabase(
          legacyDatabasePath,
          options: OpenDatabaseOptions(
            version: DatabaseService.databaseVersion,
            onCreate:
                (database, _) => database.execute(
                  'CREATE TABLE other_app_data (id TEXT PRIMARY KEY)',
                ),
          ),
        );
        await otherAppDatabase.close();

        final backup = Directory(
          path.join(directory.path, '.stars_backup_current'),
        );
        await backup.create(recursive: true);
        final backupDatabase = await databaseFactoryFfi.openDatabase(
          path.join(backup.path, 'app.db'),
          options: OpenDatabaseOptions(
            version: DatabaseService.databaseVersion,
            onConfigure: DatabaseService.configure,
            onCreate: DatabaseService.createSchema,
          ),
        );
        await backupDatabase.insert('bots', _botRow('backup-bot'));
        await backupDatabase.close();
        await File(path.join(backup.path, 'manifest.json')).writeAsString(
          jsonEncode(<String, Object?>{
            'schema_version': DatabaseService.databaseVersion,
          }),
        );
        final backupAsset = File(
          path.join(backup.path, 'chats', 'backup-chat', 'asset.txt'),
        );
        await backupAsset.parent.create(recursive: true);
        await backupAsset.writeAsString('backup asset');

        final service = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );
        final recoveredDatabase = await service.initDatabase();
        addTearDown(recoveredDatabase.close);

        expect(
          await recoveredDatabase.query(
            'bots',
            where: 'id = ?',
            whereArgs: const <Object?>['backup-bot'],
          ),
          hasLength(1),
        );
        expect(
          await File(
            path.join(
              _applicationDataDirectory(directory).path,
              'chats',
              'backup-chat',
              'asset.txt',
            ),
          ).readAsString(),
          'backup asset',
        );
        final untouchedOtherDatabase = await databaseFactoryFfi.openDatabase(
          legacyDatabasePath,
          options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
        );
        expect(
          await untouchedOtherDatabase.getVersion(),
          DatabaseService.databaseVersion,
        );
        expect(await untouchedOtherDatabase.query('other_app_data'), isEmpty);
        await untouchedOtherDatabase.close();
      },
    );

    test('reopens a database that already uses the current schema', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars_current_database_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final dataDirectory = _applicationDataDirectory(directory);
      await dataDirectory.create(recursive: true);
      final databasePath = path.join(dataDirectory.path, 'app.db');
      final initialDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: DatabaseService.databaseVersion,
          onConfigure: DatabaseService.configure,
          onCreate: DatabaseService.createSchema,
        ),
      );
      await initialDatabase.insert('bots', _botRow('current-bot'));
      await initialDatabase.close();

      final service = DatabaseService(
        applicationDocumentsDirectoryProvider: () async => directory,
      );
      final reopenedDatabase = await service.initDatabase();
      addTearDown(reopenedDatabase.close);

      expect(
        await reopenedDatabase.getVersion(),
        DatabaseService.databaseVersion,
      );
      expect(
        await reopenedDatabase.query(
          'bots',
          where: 'id = ?',
          whereArgs: const <Object?>['current-bot'],
        ),
        hasLength(1),
      );
    });

    test('upgrades version 18 without losing messages or Tool audit', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars_tool_evidence_upgrade_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final dataDirectory = _applicationDataDirectory(directory);
      await dataDirectory.create(recursive: true);
      final databasePath = path.join(dataDirectory.path, 'app.db');
      final previousDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: DatabaseService.databaseVersion,
          onConfigure: DatabaseService.configure,
          onCreate: DatabaseService.createSchema,
        ),
      );
      await previousDatabase.insert('bots', _botRow('upgrade-bot'));
      await previousDatabase.insert(
        'chats',
        _chatRow('upgrade-chat', 'upgrade-bot'),
      );
      await previousDatabase.insert(
        'messages',
        _messageRow(
          'upgrade-message',
          'upgrade-chat',
          'upgrade-bot',
          'Preserved answer',
        ),
      );
      await previousDatabase.insert(
        'tool_execution_records',
        _toolExecutionRow(
          executionId: 'upgrade-attempt',
          chatId: 'upgrade-chat',
          botId: 'upgrade-bot',
          messageId: 'upgrade-message',
        ),
      );
      await _dropToolEvidenceSchema(previousDatabase);
      await previousDatabase.setVersion(18);
      await previousDatabase.close();

      final service = DatabaseService(
        applicationDocumentsDirectoryProvider: () async => directory,
      );
      final upgradedDatabase = await service.initDatabase();
      addTearDown(upgradedDatabase.close);

      expect(
        await upgradedDatabase.getVersion(),
        DatabaseService.databaseVersion,
      );
      expect(
        (await upgradedDatabase.query('messages')).single['content'],
        'Preserved answer',
      );
      expect(
        (await upgradedDatabase.query(
          'tool_execution_records',
        )).single['execution_id'],
        'upgrade-attempt',
      );
      await _expectCurrentSchema(upgradedDatabase);
    });

    test('upgrades version 19 without losing the evidence ledger', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars_provider_native_upgrade_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final dataDirectory = _applicationDataDirectory(directory);
      await dataDirectory.create(recursive: true);
      final databasePath = path.join(dataDirectory.path, 'app.db');
      final previousDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: DatabaseService.databaseVersion,
          onConfigure: DatabaseService.configure,
          onCreate: DatabaseService.createSchema,
        ),
      );
      await previousDatabase.insert('bots', _botRow('evidence-upgrade-bot'));
      await previousDatabase.insert(
        'chats',
        _chatRow('evidence-upgrade-chat', 'evidence-upgrade-bot'),
      );
      await previousDatabase.insert(
        'messages',
        _messageRow(
          'evidence-upgrade-message',
          'evidence-upgrade-chat',
          'evidence-upgrade-bot',
          'Preserved grounded answer',
        ),
      );
      await previousDatabase.insert(
        'tool_invocation_events',
        _toolInvocationEventRow(),
      );
      await previousDatabase.insert(
        'tool_evidence_records',
        _toolEvidenceRecordRow(),
      );
      await previousDatabase.insert('answer_claim_evidence', {
        'message_id': 'evidence-upgrade-message',
        'claim_id': 'claim-1',
        'evidence_id': 'evidence-upgrade-attempt:evidence',
        'created_at': 3,
      });
      await previousDatabase.setVersion(19);
      await previousDatabase.close();

      final service = DatabaseService(
        applicationDocumentsDirectoryProvider: () async => directory,
      );
      final upgradedDatabase = await service.initDatabase();
      addTearDown(upgradedDatabase.close);

      expect(
        await upgradedDatabase.getVersion(),
        DatabaseService.databaseVersion,
      );
      expect(
        await upgradedDatabase.query('tool_invocation_events'),
        hasLength(1),
      );
      expect(
        await upgradedDatabase.query('tool_evidence_records'),
        hasLength(1),
      );
      expect(
        await upgradedDatabase.query('answer_claim_evidence'),
        hasLength(1),
      );
      for (final table in const [
        'tool_execution_records',
        'tool_invocation_events',
        'tool_evidence_records',
      ]) {
        final schema = await upgradedDatabase.rawQuery(
          "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
          [table],
        );
        expect(schema.single['sql'], contains("'providerNative'"));
      }
    });

    test('upgrades version 20 with recovery and metric storage', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars_grounding_recovery_upgrade_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final dataDirectory = _applicationDataDirectory(directory);
      await dataDirectory.create(recursive: true);
      final databasePath = path.join(dataDirectory.path, 'app.db');
      final previousDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: DatabaseService.databaseVersion,
          onConfigure: DatabaseService.configure,
          onCreate: DatabaseService.createSchema,
        ),
      );
      await previousDatabase.insert('bots', _botRow('recovery-upgrade-bot'));
      await previousDatabase.execute('DROP TABLE grounding_metric_counters');
      await previousDatabase.execute(
        'DROP TABLE grounding_metric_observations',
      );
      await previousDatabase.execute('DROP TABLE agent_run_answer_checkpoints');
      await previousDatabase.setVersion(20);
      await previousDatabase.close();

      final service = DatabaseService(
        applicationDocumentsDirectoryProvider: () async => directory,
      );
      final upgradedDatabase = await service.initDatabase();
      addTearDown(upgradedDatabase.close);

      expect(
        await upgradedDatabase.getVersion(),
        DatabaseService.databaseVersion,
      );
      expect(
        await upgradedDatabase.query(
          'bots',
          where: 'id = ?',
          whereArgs: const ['recovery-upgrade-bot'],
        ),
        hasLength(1),
      );
      for (final table in const [
        'agent_run_answer_checkpoints',
        'grounding_metric_counters',
        'grounding_metric_observations',
      ]) {
        final rows = await upgradedDatabase.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          [table],
        );
        expect(rows, hasLength(1));
      }
      final invocationSchema = await upgradedDatabase.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
        const ['tool_invocation_events'],
      );
      expect(invocationSchema.single['sql'], contains("'interrupted'"));
    });

    test(
      'adds Tool execution storage to an existing current database',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'stars_current_tool_execution_upgrade_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final dataDirectory = _applicationDataDirectory(directory);
        await dataDirectory.create(recursive: true);
        final databasePath = path.join(dataDirectory.path, 'app.db');
        final initialDatabase = await databaseFactoryFfi.openDatabase(
          databasePath,
          options: OpenDatabaseOptions(
            version: DatabaseService.databaseVersion,
            onConfigure: DatabaseService.configure,
            onCreate: DatabaseService.createSchema,
          ),
        );
        await initialDatabase.insert('bots', _botRow('existing-bot'));
        await initialDatabase.execute('DROP TABLE tool_execution_records');
        await initialDatabase.close();

        final service = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );
        final migratedDatabase = await service.initDatabase();
        addTearDown(migratedDatabase.close);

        expect(
          await migratedDatabase.query(
            'bots',
            where: 'id = ?',
            whereArgs: const <Object?>['existing-bot'],
          ),
          hasLength(1),
        );
        final tables = await migratedDatabase.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          const <Object?>['tool_execution_records'],
        );
        expect(tables, hasLength(1));
      },
    );

    test(
      'separates identities in existing current Tool execution storage',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'stars_current_tool_identity_upgrade_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final dataDirectory = _applicationDataDirectory(directory);
        await dataDirectory.create(recursive: true);
        final databasePath = path.join(dataDirectory.path, 'app.db');
        final initialDatabase = await databaseFactoryFfi.openDatabase(
          databasePath,
          options: OpenDatabaseOptions(
            version: DatabaseService.databaseVersion,
            onConfigure: DatabaseService.configure,
            onCreate: DatabaseService.createSchema,
          ),
        );
        await initialDatabase.insert('bots', _botRow('existing-bot'));
        await initialDatabase.insert(
          'chats',
          _chatRow('existing-chat', 'existing-bot'),
        );
        await _replaceWithPreGrd004ToolExecutionSchema(initialDatabase);
        await initialDatabase.insert('tool_execution_records', {
          'execution_id': 'legacy-execution-1',
          'run_id': 'run-1',
          'turn_id': 'turn-1',
          'message_id': 'message-1',
          'chat_id': 'existing-chat',
          'bot_id': 'existing-bot',
          'call_id': 'provider-call-1',
          'tool_name': 'legacy.tool',
          'tool_title': '',
          'mcp_server_name': '',
          'source': 'builtIn',
          'risk_level': 'readOnly',
          'status': 'succeeded',
          'detail': '',
          'arguments_summary': '{}',
          'result_summary': 'ok',
          'approval_status': '',
          'error_code': '',
          'duration_ms': 1,
          'started_at': 1,
          'completed_at': 2,
          'updated_at': 2,
        });
        await initialDatabase.close();

        final service = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );
        final migratedDatabase = await service.initDatabase();
        addTearDown(migratedDatabase.close);

        final rows = await migratedDatabase.query('tool_execution_records');
        expect(rows, hasLength(1));
        expect(rows.single['execution_id'], 'legacy-execution-1');
        expect(rows.single['invocation_id'], 'legacy-execution-1');
        expect(rows.single['attempt_id'], 'legacy-execution-1');
        expect(rows.single['provider_call_id'], 'provider-call-1');
        expect(rows.single['status'], 'succeeded');
      },
    );

    test('adds current profile preferences to an existing database', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars_current_profile_upgrade_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final dataDirectory = _applicationDataDirectory(directory);
      await dataDirectory.create(recursive: true);
      final databasePath = path.join(dataDirectory.path, 'app.db');
      final initialDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: DatabaseService.databaseVersion,
          onConfigure: DatabaseService.configure,
          onCreate: DatabaseService.createSchema,
        ),
      );
      await initialDatabase.execute('DROP TABLE profile');
      await initialDatabase.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            avatar TEXT NOT NULL,
            font_size REAL NOT NULL,
            theme_mode INTEGER NOT NULL,
            language TEXT NOT NULL,
            show_execution_status INTEGER NOT NULL
              CHECK (show_execution_status IN (0, 1)),
            create_timestamp INTEGER NOT NULL,
            modify_timestamp INTEGER NOT NULL
          )
        ''');
      await initialDatabase.insert('profile', <String, Object?>{
        'name': 'Existing User',
        'avatar': '',
        'font_size': 14.0,
        'theme_mode': 0,
        'language': 'zh_CN',
        'show_execution_status': 1,
        'create_timestamp': 1,
        'modify_timestamp': 1,
      });
      await initialDatabase.close();

      final service = DatabaseService(
        applicationDocumentsDirectoryProvider: () async => directory,
      );
      final migratedDatabase = await service.initDatabase();
      addTearDown(migratedDatabase.close);

      final rows = await migratedDatabase.query('profile');
      expect(rows.single['name'], 'Existing User');
      expect(rows.single['inject_application_prompt'], 1);
      expect(rows.single['strict_grounding_mode'], 0);
    });

    test(
      'adds message grounding storage without deleting existing rows',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'stars_current_grounding_upgrade_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final dataDirectory = _applicationDataDirectory(directory);
        await dataDirectory.create(recursive: true);
        final databasePath = path.join(dataDirectory.path, 'app.db');
        final initialDatabase = await databaseFactoryFfi.openDatabase(
          databasePath,
          options: OpenDatabaseOptions(
            version: DatabaseService.databaseVersion,
            onConfigure: DatabaseService.configure,
            onCreate: DatabaseService.createSchema,
          ),
        );
        await initialDatabase.insert('bots', _botRow('bot-grounding-upgrade'));
        await initialDatabase.insert(
          'chats',
          _chatRow('chat-grounding-upgrade', 'bot-grounding-upgrade'),
        );
        await initialDatabase.insert(
          'messages',
          _messageRow(
            'message-grounding-upgrade',
            'chat-grounding-upgrade',
            'bot-grounding-upgrade',
            'Existing answer',
          ),
        );
        await initialDatabase.execute(
          'ALTER TABLE messages DROP COLUMN grounding_json',
        );
        await initialDatabase.close();

        final service = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );
        final migratedDatabase = await service.initDatabase();
        addTearDown(migratedDatabase.close);

        final columns = await migratedDatabase.rawQuery(
          'PRAGMA table_info(messages)',
        );
        final rows = await migratedDatabase.query('messages');
        expect(
          columns.map((column) => column['name']),
          contains('grounding_json'),
        );
        expect(rows.single['content'], 'Existing answer');
        expect(rows.single['grounding_json'], isEmpty);
      },
    );

    test(
      'deletes any non-current database before creating the current schema',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'stars_obsolete_database_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final dataDirectory = _applicationDataDirectory(directory);
        await dataDirectory.create(recursive: true);
        final databasePath = path.join(dataDirectory.path, 'app.db');
        final obsoleteDatabase = await databaseFactoryFfi.openDatabase(
          databasePath,
          options: OpenDatabaseOptions(
            version: DatabaseService.databaseVersion - 1,
            onCreate: (database, _) async {
              await database.execute('''
                CREATE TABLE obsolete_data (
                  id TEXT PRIMARY KEY,
                  value TEXT NOT NULL
                )
              ''');
            },
          ),
        );
        await obsoleteDatabase.insert('obsolete_data', <String, Object?>{
          'id': 'obsolete-1',
          'value': 'must be deleted',
        });
        await obsoleteDatabase.close();
        final obsoleteChatDirectory = Directory(
          path.join(dataDirectory.path, 'chats', 'obsolete-chat'),
        );
        await obsoleteChatDirectory.create(recursive: true);
        await File(
          path.join(obsoleteChatDirectory.path, 'attachment.txt'),
        ).writeAsString('must be deleted');

        final service = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );
        final resetDatabase = await service.initDatabase();
        addTearDown(resetDatabase.close);

        expect(
          await resetDatabase.getVersion(),
          DatabaseService.databaseVersion,
        );
        await _expectCurrentSchema(resetDatabase);
        expect(
          await resetDatabase.rawQuery('''
            SELECT name
            FROM sqlite_master
            WHERE type = 'table' AND name = 'obsolete_data'
          '''),
          isEmpty,
        );
        expect(await resetDatabase.query('messages'), isEmpty);
        expect(
          Directory(path.join(dataDirectory.path, 'chats')).existsSync(),
          isFalse,
        );
      },
    );

    test('rejects a database created by a newer application version', () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars_newer_database_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final dataDirectory = _applicationDataDirectory(directory);
      await dataDirectory.create(recursive: true);
      final databasePath = path.join(dataDirectory.path, 'app.db');
      final newerDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: DatabaseService.databaseVersion + 1,
          onCreate:
              (database, _) => database.execute(
                'CREATE TABLE newer_data (id TEXT PRIMARY KEY)',
              ),
        ),
      );
      await newerDatabase.close();

      final service = DatabaseService(
        applicationDocumentsDirectoryProvider: () async => directory,
      );

      await expectLater(
        service.initDatabase(),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.code,
            'code',
            'database_downgrade_not_supported',
          ),
        ),
      );
      expect(await databaseFactoryFfi.databaseExists(databasePath), isTrue);
    });

    test(
      'restores current database and chat assets from a valid backup',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'stars_database_recovery_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final dataDirectory = _applicationDataDirectory(directory);
        final databasePath = path.join(dataDirectory.path, 'app.db');
        final asset = File(
          path.join(dataDirectory.path, 'chats', 'chat-recovery', 'asset.txt'),
        );

        final initialService = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );
        final initialDatabase = await initialService.initDatabase();
        await initialDatabase.insert('bots', _botRow('recovered-bot'));
        await asset.parent.create(recursive: true);
        await asset.writeAsString('current asset');
        await initialDatabase.close();

        final backupService = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );
        final checkedDatabase = await backupService.initDatabase();
        await checkedDatabase.close();
        await asset.writeAsString('uncommitted asset');
        await File(databasePath).writeAsBytes(<int>[0, 1, 2, 3], flush: true);

        final recoveryService = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );
        final recoveredDatabase = await recoveryService.initDatabase();
        addTearDown(recoveredDatabase.close);

        expect(
          await recoveredDatabase.query(
            'bots',
            where: 'id = ?',
            whereArgs: const <Object?>['recovered-bot'],
          ),
          hasLength(1),
        );
        expect(await asset.readAsString(), 'current asset');
        expect(await recoveredDatabase.rawQuery('PRAGMA quick_check'), [
          <String, Object?>{'quick_check': 'ok'},
        ]);
        expect(
          await recoveredDatabase.rawQuery('PRAGMA foreign_key_check'),
          isEmpty,
        );
      },
    );

    test(
      'does not silently replace corrupt current data without a backup',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'stars_unrecoverable_database_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final dataDirectory = _applicationDataDirectory(directory);
        await dataDirectory.create(recursive: true);
        final databasePath = path.join(dataDirectory.path, 'app.db');
        await File(databasePath).writeAsBytes(<int>[0, 1, 2, 3], flush: true);
        final service = DatabaseService(
          applicationDocumentsDirectoryProvider: () async => directory,
        );

        await expectLater(
          service.initDatabase(),
          throwsA(
            isA<AppFailure>().having(
              (failure) => failure.code,
              'code',
              'database_recovery_failed',
            ),
          ),
        );
        expect(await File(databasePath).readAsBytes(), <int>[0, 1, 2, 3]);
      },
    );
  });
}

Directory _applicationDataDirectory(Directory documents) =>
    Directory(path.join(documents.path, starsApplicationDataDirectoryName));

Future<void> _expectCurrentSchema(Database database) async {
  final tables = await database.rawQuery('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
  ''');
  expect(
    tables.map((table) => table['name']),
    unorderedEquals(<String>[
      'chats',
      'messages',
      'tool_execution_records',
      'tool_invocation_events',
      'tool_evidence_records',
      'answer_claim_evidence',
      'agent_run_answer_checkpoints',
      'grounding_metric_counters',
      'grounding_metric_observations',
      'token_usage_records',
      'skills',
      'bot_skill_bindings',
      'skill_activations',
      'skill_publishers',
      'skill_catalogs',
      'skill_script_grants',
      'skill_organization_policy',
      'skill_compliance_events',
      'conversation_skill_pins',
      'mcp_servers',
      'mcp_tools',
      'conversation_memory_state',
      'conversation_summary_segments',
      'conversation_memory_items',
      'bots',
      'profile',
    ]),
  );

  final indexes = await database.rawQuery('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'index' AND name NOT LIKE 'sqlite_autoindex_%'
  ''');
  expect(
    indexes.map((index) => index['name']),
    unorderedEquals(<String>[
      'messages_message_id_unique',
      'messages_bot_id_index',
      'tool_execution_records_run_id_index',
      'tool_execution_records_chat_started_at_index',
      'tool_invocation_events_run_id_index',
      'tool_invocation_events_message_id_index',
      'tool_invocation_events_chat_time_index',
      'tool_evidence_records_run_id_index',
      'tool_evidence_records_message_id_index',
      'tool_evidence_records_observed_at_index',
      'tool_evidence_records_chat_observed_index',
      'answer_claim_evidence_evidence_id_index',
      'token_usage_records_chat_id_index',
      'token_usage_records_bot_id_index',
      'bot_skill_bindings_skill_id_index',
      'skill_activations_run_id_index',
      'skill_activations_chat_id_index',
      'skill_compliance_events_skill_id_index',
      'conversation_skill_pins_skill_id_index',
      'conversation_summary_chat_status_index',
      'conversation_memory_chat_key_index',
      'messages_chat_timestamp_message_index',
      'mcp_tools_server_id_index',
    ]),
  );

  final messageColumns = await database.rawQuery('PRAGMA table_info(messages)');
  expect(
    messageColumns.map((column) => column['name']),
    orderedEquals(<String>[
      'message_id',
      'turn_id',
      'run_id',
      'chat_id',
      'bot_id',
      'sender_id',
      'content',
      'reasoning',
      'process_info',
      'grounding_json',
      'images',
      'files',
      'audio',
      'music',
      'video',
      'token_model',
      'input_token_count',
      'output_token_count',
      'total_token_count',
      'terminal_state',
      'has_partial_content',
      'timestamp',
    ]),
  );
  expect(
    messageColumns.singleWhere(
      (column) => column['name'] == 'message_id',
    )['notnull'],
    1,
  );
  expect(
    messageColumns.singleWhere(
      (column) => column['name'] == 'grounding_json',
    )['dflt_value'],
    "''",
  );

  final toolExecutionColumns = await database.rawQuery(
    'PRAGMA table_info(tool_execution_records)',
  );
  expect(
    toolExecutionColumns.map((column) => column['name']),
    orderedEquals(<String>[
      'execution_id',
      'invocation_id',
      'attempt_id',
      'provider_call_id',
      'run_id',
      'turn_id',
      'message_id',
      'chat_id',
      'bot_id',
      'call_id',
      'tool_name',
      'tool_title',
      'mcp_server_name',
      'source',
      'risk_level',
      'status',
      'detail',
      'arguments_summary',
      'result_summary',
      'approval_status',
      'error_code',
      'duration_ms',
      'started_at',
      'completed_at',
      'updated_at',
    ]),
  );

  final invocationEventColumns = await database.rawQuery(
    'PRAGMA table_info(tool_invocation_events)',
  );
  expect(
    invocationEventColumns.map((column) => column['name']),
    orderedEquals(<String>[
      'event_id',
      'run_id',
      'turn_id',
      'chat_id',
      'message_id',
      'invocation_id',
      'attempt_id',
      'provider_call_id',
      'tool_name',
      'tool_version',
      'source',
      'status',
      'sequence',
      'occurred_at',
      'error_code',
      'record_digest',
    ]),
  );

  final evidenceColumns = await database.rawQuery(
    'PRAGMA table_info(tool_evidence_records)',
  );
  expect(
    evidenceColumns.map((column) => column['name']),
    orderedEquals(<String>[
      'evidence_id',
      'run_id',
      'turn_id',
      'chat_id',
      'message_id',
      'invocation_id',
      'attempt_id',
      'provider_call_id',
      'tool_name',
      'tool_version',
      'source',
      'capabilities_json',
      'terminal_status',
      'evidence_kind',
      'subject',
      'scope_json',
      'result_summary',
      'arguments_digest',
      'result_digest',
      'structured_facts_json',
      'observed_at',
      'valid_until',
      'payload_ref',
      'payload_expires_at',
      'truncated',
      'schema_valid',
      'persisted',
      'error_code',
      'record_digest',
    ]),
  );

  final claimEvidenceColumns = await database.rawQuery(
    'PRAGMA table_info(answer_claim_evidence)',
  );
  expect(
    claimEvidenceColumns.map((column) => column['name']),
    orderedEquals(<String>[
      'message_id',
      'claim_id',
      'evidence_id',
      'created_at',
    ]),
  );

  final chatColumns = await database.rawQuery('PRAGMA table_info(chats)');
  expect(
    chatColumns.singleWhere(
      (column) => column['name'] == 'create_timestamp',
    )['type'],
    'INTEGER',
  );
  expect(
    chatColumns.singleWhere(
      (column) => column['name'] == 'modify_timestamp',
    )['type'],
    'INTEGER',
  );
  expect(
    messageColumns.singleWhere(
      (column) => column['name'] == 'turn_id',
    )['notnull'],
    1,
  );

  final profileColumns = await database.rawQuery('PRAGMA table_info(profile)');
  expect(
    profileColumns.map((column) => column['name']),
    orderedEquals(<String>[
      'id',
      'name',
      'avatar',
      'font_size',
      'theme_mode',
      'language',
      'show_execution_status',
      'inject_application_prompt',
      'strict_grounding_mode',
      'create_timestamp',
      'modify_timestamp',
    ]),
  );
  expect(
    profileColumns.singleWhere(
      (column) => column['name'] == 'inject_application_prompt',
    )['dflt_value'],
    '1',
  );
  expect(
    profileColumns.singleWhere(
      (column) => column['name'] == 'strict_grounding_mode',
    )['dflt_value'],
    '0',
  );

  final mcpColumns = await database.rawQuery('PRAGMA table_info(mcp_servers)');
  expect(
    mcpColumns.map((column) => column['name']),
    orderedEquals(<String>[
      'id',
      'name',
      'transport_type',
      'transport_config_json',
      'remote_server_name',
      'remote_server_version',
      'capabilities_json',
      'connection_status',
      'last_error_code',
      'last_connected_at',
      'created_at',
      'updated_at',
    ]),
  );

  final tokenUsageColumns = await database.rawQuery(
    'PRAGMA table_info(token_usage_records)',
  );
  expect(
    tokenUsageColumns.map((column) => column['name']),
    orderedEquals(<String>[
      'message_id',
      'chat_id',
      'bot_id',
      'operation_kind',
      'token_model',
      'input_token_count',
      'output_token_count',
      'total_token_count',
      'timestamp',
    ]),
  );
}

Map<String, Object?> _botRow(String id) => <String, Object?>{
  'id': id,
  'name': 'Current Bot',
  'avatar': '',
  'provider': 'Provider',
  'base_url': 'https://example.test',
  'api_key': '',
  'api_type': 'openai',
  'model': 'current-model',
  'system_prompt': '',
  'parameters': '{}',
  'create_timestamp': 1,
  'modify_timestamp': 1,
};

Map<String, Object?> _chatRow(String id, String botId) => <String, Object?>{
  'id': id,
  'bot_id': botId,
  'last_message': '',
  'last_message_timestamp': 1,
  'create_timestamp': 1,
  'modify_timestamp': 1,
};

Map<String, Object?> _messageRow(
  String id,
  String chatId,
  String botId,
  String content,
) => <String, Object?>{
  'message_id': id,
  'turn_id': 'turn-$id',
  'run_id': '',
  'chat_id': chatId,
  'bot_id': botId,
  'sender_id': 'assistant',
  'content': content,
  'reasoning': '',
  'process_info':
      '{"reasoning_status":"","duration_ms":null,'
      '"tool_calls":[],"command_executions":[],"file_edits":[],'
      '"skill_activations":[]}',
  'images': '[]',
  'files': '[]',
  'audio': '',
  'music': '',
  'video': '',
  'token_model': '',
  'input_token_count': 0,
  'output_token_count': 0,
  'total_token_count': 0,
  'terminal_state': '',
  'has_partial_content': 0,
  'timestamp': 1,
};

Map<String, Object?> _toolExecutionRow({
  required String executionId,
  required String chatId,
  required String botId,
  required String messageId,
}) => <String, Object?>{
  'execution_id': executionId,
  'invocation_id': '$executionId:invocation',
  'attempt_id': executionId,
  'provider_call_id': 'provider-$executionId',
  'run_id': 'run-$executionId',
  'turn_id': 'turn-$executionId',
  'message_id': messageId,
  'chat_id': chatId,
  'bot_id': botId,
  'call_id': 'provider-$executionId',
  'tool_name': 'resource.read',
  'tool_title': 'Read resource',
  'mcp_server_name': '',
  'source': 'mcp',
  'risk_level': 'readOnly',
  'status': 'succeeded',
  'detail': '',
  'arguments_summary': '{}',
  'result_summary': 'Observed',
  'approval_status': '',
  'error_code': '',
  'duration_ms': 1,
  'started_at': 1,
  'completed_at': 2,
  'updated_at': 2,
};

Map<String, Object?> _toolInvocationEventRow() => <String, Object?>{
  'event_id': 'evidence-upgrade-attempt:event:1',
  'run_id': 'evidence-upgrade-run',
  'turn_id': 'evidence-upgrade-turn',
  'chat_id': 'evidence-upgrade-chat',
  'message_id': 'evidence-upgrade-message',
  'invocation_id': 'evidence-upgrade-invocation',
  'attempt_id': 'evidence-upgrade-attempt',
  'provider_call_id': 'provider-call-1',
  'tool_name': 'mcp.resources.read',
  'tool_version': '1.0.0',
  'source': 'mcp',
  'status': 'succeeded',
  'sequence': 1,
  'occurred_at': 1,
  'error_code': '',
  'record_digest':
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
};

Map<String, Object?> _toolEvidenceRecordRow() => <String, Object?>{
  'evidence_id': 'evidence-upgrade-attempt:evidence',
  'run_id': 'evidence-upgrade-run',
  'turn_id': 'evidence-upgrade-turn',
  'chat_id': 'evidence-upgrade-chat',
  'message_id': 'evidence-upgrade-message',
  'invocation_id': 'evidence-upgrade-invocation',
  'attempt_id': 'evidence-upgrade-attempt',
  'provider_call_id': 'provider-call-1',
  'tool_name': 'mcp.resources.read',
  'tool_version': '1.0.0',
  'source': 'mcp',
  'capabilities_json': '["externalRead"]',
  'terminal_status': 'succeeded',
  'evidence_kind': 'observation',
  'subject': 'resource:item-1',
  'scope_json': '{"resource_id":"item-1"}',
  'result_summary': 'Resource observed.',
  'arguments_digest':
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  'result_digest':
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
  'structured_facts_json':
      '[{"name":"resource.state","value":"ready",'
      '"unit":"","attributes":{}}]',
  'observed_at': 1,
  'valid_until': 2,
  'payload_ref': '',
  'payload_expires_at': null,
  'truncated': 0,
  'schema_valid': 1,
  'persisted': 1,
  'error_code': '',
  'record_digest':
      'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
};

Map<String, Object?> _skillRow(String id) => <String, Object?>{
  'id': id,
  'name': 'Skill',
  'description': '',
  'version': '',
  'scope': 'user',
  'source_uri': '',
  'root_path': '/tmp/skill',
  'content_digest': 'digest',
  'trust_state': 'trusted',
  'validation_status': 'valid',
  'compatibility': '',
  'requested_tools_json': '[]',
  'diagnostics_json': '[]',
  'has_scripts': 0,
  'has_references': 0,
  'has_assets': 0,
  'publisher_id': '',
  'publisher_name': '',
  'signature_status': 'unsigned',
  'catalog_id': '',
  'catalog_entry_id': '',
  'update_policy': 'manual',
  'installed_at': 1,
  'updated_at': 1,
};

Future<Database> _openCurrentDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: DatabaseService.databaseVersion,
      onConfigure: DatabaseService.configure,
      onCreate: DatabaseService.createSchema,
    ),
  );
}

Future<void> _replaceWithPreGrd004ToolExecutionSchema(Database database) async {
  await database.execute('DROP TABLE tool_execution_records');
  await database.execute('''
    CREATE TABLE tool_execution_records (
      execution_id TEXT PRIMARY KEY,
      run_id TEXT NOT NULL,
      turn_id TEXT NOT NULL,
      message_id TEXT NOT NULL,
      chat_id TEXT NOT NULL,
      bot_id TEXT NOT NULL,
      call_id TEXT NOT NULL,
      tool_name TEXT NOT NULL,
      tool_title TEXT NOT NULL DEFAULT '',
      mcp_server_name TEXT NOT NULL DEFAULT '',
      source TEXT NOT NULL
        CHECK (source IN ('builtIn', 'mcp', 'skillScript')),
      risk_level TEXT NOT NULL
        CHECK (risk_level IN ('readOnly', 'write', 'destructive')),
      status TEXT NOT NULL
        CHECK (status IN (
          'requested',
          'awaitingApproval',
          'running',
          'succeeded',
          'failed',
          'denied',
          'cancelled',
          'timedOut',
          'duplicate'
        )),
      detail TEXT NOT NULL DEFAULT '',
      arguments_summary TEXT NOT NULL DEFAULT '',
      result_summary TEXT NOT NULL DEFAULT '',
      approval_status TEXT NOT NULL DEFAULT '',
      error_code TEXT NOT NULL DEFAULT '',
      duration_ms INTEGER,
      started_at INTEGER NOT NULL,
      completed_at INTEGER,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
      FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE CASCADE
    )
  ''');
  await database.execute(
    'CREATE INDEX tool_execution_records_run_id_index '
    'ON tool_execution_records(run_id)',
  );
  await database.execute(
    'CREATE INDEX tool_execution_records_chat_started_at_index '
    'ON tool_execution_records(chat_id, started_at DESC)',
  );
}

Future<void> _dropToolEvidenceSchema(Database database) async {
  await database.execute('DROP TABLE answer_claim_evidence');
  await database.execute('DROP TABLE tool_evidence_records');
  await database.execute('DROP TABLE tool_invocation_events');
}
