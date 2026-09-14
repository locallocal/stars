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
      'conversation_tasks',
      'conversation_task_plans',
      'conversation_task_events',
      'conversation_task_progress',
      'conversation_task_approvals',
      'conversation_task_checkpoints',
      'conversation_task_tool_attempts',
      'conversation_task_evidence_links',
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
      'conversation_tasks_chat_status_index',
      'conversation_tasks_due_index',
      'conversation_tasks_lease_expiry_index',
      'conversation_task_approvals_pending_index',
      'conversation_task_tool_attempts_segment_index',
      'conversation_task_evidence_links_segment_index',
      'messages_task_id_index',
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
      'task_id',
      'task_message_kind',
      'summary_revision',
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

  final bindingColumns = await database.rawQuery(
    'PRAGMA table_info(bot_skill_bindings)',
  );
  expect(
    bindingColumns.map((column) => column['name']),
    orderedEquals(<String>[
      'bot_id',
      'skill_id',
      'enabled',
      'requires_approval',
      'activation_mode',
      'priority',
      'created_at',
      'updated_at',
    ]),
  );
  expect(
    bindingColumns.singleWhere(
      (column) => column['name'] == 'requires_approval',
    )['dflt_value'],
    '1',
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
    chatColumns.singleWhere((column) => column['name'] == 'name')['type'],
    'TEXT',
  );
  expect(
    chatColumns.singleWhere((column) => column['name'] == 'name')['notnull'],
    1,
  );
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
      'show_reasoning',
      'show_verification_status',
      'show_execution_status',
      'inject_application_prompt',
      'strict_grounding_mode',
      'create_timestamp',
      'modify_timestamp',
    ]),
  );
  expect(
    profileColumns.singleWhere(
      (column) => column['name'] == 'show_reasoning',
    )['dflt_value'],
    '1',
  );
  expect(
    profileColumns.singleWhere(
      (column) => column['name'] == 'show_verification_status',
    )['dflt_value'],
    '1',
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
