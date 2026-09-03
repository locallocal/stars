import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stars/data/services/application_data_directory.dart';
import 'package:stars/domain/models/app_failure.dart';

part 'database_schema_verifier.dart';
part 'database_tool_execution_schema.dart';

typedef ApplicationDocumentsDirectoryProvider = Future<Directory> Function();

class DatabaseService {
  DatabaseService({
    ApplicationDocumentsDirectoryProvider?
    applicationDocumentsDirectoryProvider,
  }) : _applicationDocumentsDirectoryProvider =
           applicationDocumentsDirectoryProvider ??
           getApplicationDocumentsDirectory;

  final ApplicationDocumentsDirectoryProvider
  _applicationDocumentsDirectoryProvider;
  Database? _database;
  Future<Database>? _openingDatabase;
  // This is the only supported schema generation. Every other version is
  // deleted before the database is opened.
  static const int databaseVersion = 18;
  static const String _databaseFileName = 'app.db';
  static const String _currentBackupName = '.stars_backup_current';
  static const String _previousBackupName = '.stars_backup_previous';
  static const String _backupManifestName = 'manifest.json';

  // 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    return initDatabase();
  }

  // 初始化数据库
  Future<Database> initDatabase() async {
    if (_database != null) return _database!;
    final opening = _openingDatabase;
    if (opening != null) return opening;

    final future = _openDatabase();
    _openingDatabase = future;
    try {
      _database = await future;
      return _database!;
    } finally {
      _openingDatabase = null;
    }
  }

  Future<Database> _openDatabase() async {
    final documents = await _applicationDocumentsDirectoryProvider();
    await documents.create(recursive: true);
    final root = Directory(
      join(documents.path, starsApplicationDataDirectoryName),
    );
    await _migrateLegacyData(documents, root);
    await root.create(recursive: true);
    final path = join(root.path, _databaseFileName);

    await _prepareCurrentDatabase(root, path);
    final database = await openDatabase(
      path,
      version: databaseVersion,
      onConfigure: configure,
      onCreate: createSchema,
    );
    try {
      await _ensureCompatibleProfileSchema(database);
      await _ensureCompatibleMessageGroundingSchema(database);
      await _ensureCompatibleToolExecutionSchema(database);
      await _verifyIntegrity(database);
      await _verifyCurrentDatabaseSchema(database);
      return database;
    } on Object {
      await database.close();
      rethrow;
    }
  }

  static Future<void> configure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _ensureCompatibleProfileSchema(Database database) async {
    final columns = await database.rawQuery('PRAGMA table_info(profile)');
    final columnNames =
        columns.map((column) => column['name']).whereType<String>().toSet();
    if (columnNames.contains('inject_application_prompt')) return;
    await database.execute('''
      ALTER TABLE profile
      ADD COLUMN inject_application_prompt INTEGER NOT NULL DEFAULT 1
        CHECK (inject_application_prompt IN (0, 1))
    ''');
  }

  static Future<void> _ensureCompatibleMessageGroundingSchema(
    Database database,
  ) async {
    final columns = await database.rawQuery('PRAGMA table_info(messages)');
    final columnNames =
        columns.map((column) => column['name']).whereType<String>().toSet();
    if (columnNames.contains('grounding_json')) return;
    await database.execute('''
      ALTER TABLE messages
      ADD COLUMN grounding_json TEXT NOT NULL DEFAULT ''
    ''');
  }

  static Future<void> _migrateLegacyData(
    Directory legacyRoot,
    Directory destination,
  ) async {
    if (await destination.exists()) return;

    final source = await _findLegacyDataSource(legacyRoot);
    if (source == null) return;

    final staging = Directory(
      join(
        legacyRoot.path,
        '.stars_data_staging_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    try {
      await staging.create(recursive: true);
      final stagedDatabase = await source.database.copy(
        join(staging.path, _databaseFileName),
      );
      if (await source.chats.exists()) {
        await _copyDirectory(
          source.chats,
          Directory(join(staging.path, 'chats')),
        );
      }
      await _verifyDatabaseFile(stagedDatabase.path);
      await staging.rename(destination.path);
    } on Object catch (error) {
      if (await staging.exists()) await staging.delete(recursive: true);
      throw AppFailure.storage('database_recovery_failed', cause: error);
    }
  }

  static Future<_LegacyDataSource?> _findLegacyDataSource(
    Directory root,
  ) async {
    final database = File(join(root.path, _databaseFileName));
    if (await _isCurrentDatabaseValid(database)) {
      return _LegacyDataSource(
        database: database,
        chats: Directory(join(root.path, 'chats')),
      );
    }

    for (final name in <String>[_currentBackupName, _previousBackupName]) {
      final backup = Directory(join(root.path, name));
      if (!await _isCurrentBackupValid(backup)) continue;
      return _LegacyDataSource(
        database: File(join(backup.path, _databaseFileName)),
        chats: Directory(join(backup.path, 'chats')),
      );
    }
    return null;
  }

  static Future<bool> _isCurrentDatabaseValid(File database) async {
    if (!await database.exists()) return false;
    try {
      await _verifyDatabaseFile(database.path);
      return true;
    } on Object {
      return false;
    }
  }

  static Future<void> _prepareCurrentDatabase(
    Directory root,
    String databasePath,
  ) async {
    if (!await databaseExists(databasePath)) return;

    final version = await _readVersion(databasePath);
    if (version < databaseVersion) {
      await _deleteCurrentData(root, databasePath);
      return;
    }
    if (version > databaseVersion) {
      throw AppFailure(
        kind: AppFailureKind.migration,
        code: 'database_downgrade_not_supported',
        retryable: false,
        arguments: <String, Object?>{
          'foundVersion': version,
          'expectedVersion': databaseVersion,
        },
      );
    }

    try {
      await _verifyDatabaseFile(databasePath);
      await _writeRollingBackup(root, databasePath);
    } on Object catch (error) {
      final restored = await _restoreLatestCurrentBackup(root, databasePath);
      if (!restored) {
        throw AppFailure.storage('database_recovery_failed', cause: error);
      }
    }
  }

  static Future<int> _readVersion(String databasePath) async {
    Database? database;
    try {
      database = await openDatabase(
        databasePath,
        readOnly: true,
        singleInstance: false,
      );
      return await database.getVersion();
    } on Object catch (error) {
      await database?.close();
      database = null;
      final root = Directory(dirname(databasePath));
      final restored = await _restoreLatestCurrentBackup(root, databasePath);
      if (restored) return databaseVersion;
      throw AppFailure.storage('database_recovery_failed', cause: error);
    } finally {
      await database?.close();
    }
  }

  static Future<void> _verifyDatabaseFile(String databasePath) async {
    final database = await openDatabase(
      databasePath,
      readOnly: true,
      singleInstance: false,
    );
    try {
      if (await database.getVersion() != databaseVersion) {
        throw const FormatException('Backup schema version is not current.');
      }
      await _verifyIntegrity(database);
      await _verifyCurrentDatabaseSchema(
        database,
        allowMissingToolExecutionSchema: true,
      );
    } finally {
      await database.close();
    }
  }

  static Future<void> _verifyIntegrity(Database database) async {
    final quickCheck = await database.rawQuery('PRAGMA quick_check');
    final result = quickCheck.singleOrNull?.values.singleOrNull;
    if (result != 'ok') {
      throw const FormatException('SQLite quick_check failed.');
    }
    final foreignKeyFailures = await database.rawQuery(
      'PRAGMA foreign_key_check',
    );
    if (foreignKeyFailures.isNotEmpty) {
      throw const FormatException('SQLite foreign_key_check failed.');
    }
  }

  static Future<void> _deleteCurrentData(
    Directory root,
    String databasePath,
  ) async {
    await deleteDatabase(databasePath);
    final chats = Directory(join(root.path, 'chats'));
    if (await chats.exists()) await chats.delete(recursive: true);
    final pendingDeletions = Directory(join(root.path, '.pending_deletions'));
    if (await pendingDeletions.exists()) {
      await pendingDeletions.delete(recursive: true);
    }
    for (final name in <String>[_currentBackupName, _previousBackupName]) {
      final backup = Directory(join(root.path, name));
      if (await backup.exists()) await backup.delete(recursive: true);
    }
    await for (final entity in root.list(followLinks: false)) {
      if (entity is Directory &&
          basename(entity.path).startsWith('.stars_backup_staging_')) {
        await entity.delete(recursive: true);
      }
    }
  }

  static Future<void> _writeRollingBackup(
    Directory root,
    String databasePath,
  ) async {
    final staging = Directory(
      join(
        root.path,
        '.stars_backup_staging_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final current = Directory(join(root.path, _currentBackupName));
    final previous = Directory(join(root.path, _previousBackupName));
    try {
      await staging.create(recursive: true);
      await File(databasePath).copy(join(staging.path, _databaseFileName));
      final chats = Directory(join(root.path, 'chats'));
      if (await chats.exists()) {
        await _copyDirectory(chats, Directory(join(staging.path, 'chats')));
      }
      await File(join(staging.path, _backupManifestName)).writeAsString(
        jsonEncode(<String, Object?>{
          'schema_version': databaseVersion,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'includes': <String>[_databaseFileName, 'chats'],
        }),
        flush: true,
      );
      if (await previous.exists()) await previous.delete(recursive: true);
      if (await current.exists()) await current.rename(previous.path);
      await staging.rename(current.path);
    } on Object {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  static Future<bool> _restoreLatestCurrentBackup(
    Directory root,
    String databasePath,
  ) async {
    for (final name in <String>[_currentBackupName, _previousBackupName]) {
      final backup = Directory(join(root.path, name));
      if (!await _isCurrentBackupValid(backup)) continue;
      try {
        await deleteDatabase(databasePath);
        await File(join(backup.path, _databaseFileName)).copy(databasePath);
        final chats = Directory(join(root.path, 'chats'));
        if (await chats.exists()) await chats.delete(recursive: true);
        final backupChats = Directory(join(backup.path, 'chats'));
        if (await backupChats.exists()) {
          await _copyDirectory(backupChats, chats);
        }
        await _verifyDatabaseFile(databasePath);
        return true;
      } on Object {
        // Try the previous current-schema snapshot. Historical versions are
        // never parsed or restored.
      }
    }
    return false;
  }

  static Future<bool> _isCurrentBackupValid(Directory backup) async {
    try {
      final manifest = File(join(backup.path, _backupManifestName));
      final database = File(join(backup.path, _databaseFileName));
      if (!await manifest.exists() || !await database.exists()) return false;
      final decoded = jsonDecode(await manifest.readAsString());
      if (decoded is! Map<String, Object?> ||
          decoded['schema_version'] != databaseVersion) {
        return false;
      }
      await _verifyDatabaseFile(database.path);
      return true;
    } on Object {
      return false;
    }
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final target = join(destination.path, basename(entity.path));
      if (entity is File) {
        await entity.copy(target);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(target));
      }
    }
  }

  static Future<void> createSchema(Database db, int version) async {
    if (version != databaseVersion) {
      throw ArgumentError.value(
        version,
        'version',
        'Only schema version $databaseVersion can be created.',
      );
    }
    await db.execute('''
      CREATE TABLE bots (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar TEXT NOT NULL,
        provider TEXT NOT NULL,
        base_url TEXT NOT NULL,
        api_key TEXT NOT NULL,
        api_type TEXT NOT NULL,
        model TEXT NOT NULL,
        system_prompt TEXT NOT NULL,
        parameters TEXT NOT NULL,
        create_timestamp INTEGER NOT NULL,
        modify_timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        bot_id TEXT NOT NULL,
        last_message TEXT NOT NULL,
        last_message_timestamp INTEGER NOT NULL,
        create_timestamp INTEGER NOT NULL,
        modify_timestamp INTEGER NOT NULL,
        FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        message_id TEXT NOT NULL UNIQUE,
        turn_id TEXT NOT NULL,
        run_id TEXT NOT NULL,
        chat_id TEXT NOT NULL,
        bot_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT NOT NULL,
        reasoning TEXT NOT NULL,
        process_info TEXT NOT NULL,
        grounding_json TEXT NOT NULL DEFAULT '',
        images TEXT NOT NULL,
        files TEXT NOT NULL,
        audio TEXT NOT NULL,
        music TEXT NOT NULL,
        video TEXT NOT NULL,
        token_model TEXT NOT NULL,
        input_token_count INTEGER NOT NULL,
        output_token_count INTEGER NOT NULL,
        total_token_count INTEGER NOT NULL,
        terminal_state TEXT NOT NULL,
        has_partial_content INTEGER NOT NULL
          CHECK (has_partial_content IN (0, 1)),
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
        FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX messages_message_id_unique '
      'ON messages(message_id)',
    );
    await db.execute('CREATE INDEX messages_bot_id_index ON messages(bot_id)');
    await _createToolExecutionSchema(db);
    await _createTokenUsageSchema(db);
    await _createSkillSchema(db);
    await _createSkillEcosystemSchema(db);
    await _createConversationSkillPinSchema(db);
    await _createMcpSchema(db);
    await _createConversationMemorySchema(db);

    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        avatar TEXT NOT NULL,
        font_size REAL NOT NULL,
        theme_mode INTEGER NOT NULL,
        language TEXT NOT NULL,
        show_execution_status INTEGER NOT NULL
          CHECK (show_execution_status IN (0, 1)),
        inject_application_prompt INTEGER NOT NULL DEFAULT 1
          CHECK (inject_application_prompt IN (0, 1)),
        create_timestamp INTEGER NOT NULL,
        modify_timestamp INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createTokenUsageSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE token_usage_records (
        message_id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL DEFAULT '',
        bot_id TEXT NOT NULL DEFAULT '',
        operation_kind TEXT NOT NULL DEFAULT 'chat_reply',
        token_model TEXT NOT NULL DEFAULT '',
        input_token_count INTEGER NOT NULL DEFAULT 0,
        output_token_count INTEGER NOT NULL DEFAULT 0,
        total_token_count INTEGER NOT NULL DEFAULT 0,
        timestamp INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX token_usage_records_chat_id_index '
      'ON token_usage_records(chat_id)',
    );
    await db.execute(
      'CREATE INDEX token_usage_records_bot_id_index '
      'ON token_usage_records(bot_id)',
    );
  }

  static Future<void> _createSkillSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE skills (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        version TEXT NOT NULL DEFAULT '',
        scope TEXT NOT NULL,
        source_uri TEXT NOT NULL DEFAULT '',
        root_path TEXT NOT NULL,
        content_digest TEXT NOT NULL,
        trust_state TEXT NOT NULL,
        validation_status TEXT NOT NULL,
        compatibility TEXT NOT NULL DEFAULT '',
        requested_tools_json TEXT NOT NULL DEFAULT '[]',
        diagnostics_json TEXT NOT NULL DEFAULT '[]',
        has_scripts INTEGER NOT NULL DEFAULT 0,
        has_references INTEGER NOT NULL DEFAULT 0,
        has_assets INTEGER NOT NULL DEFAULT 0,
        publisher_id TEXT NOT NULL DEFAULT '',
        publisher_name TEXT NOT NULL DEFAULT '',
        signature_status TEXT NOT NULL DEFAULT 'unsigned',
        catalog_id TEXT NOT NULL DEFAULT '',
        catalog_entry_id TEXT NOT NULL DEFAULT '',
        update_policy TEXT NOT NULL DEFAULT 'manual',
        installed_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(scope, name)
      )
    ''');
    await db.execute('''
      CREATE TABLE bot_skill_bindings (
        bot_id TEXT NOT NULL,
        skill_id TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        activation_mode TEXT NOT NULL DEFAULT 'auto',
        priority INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (bot_id, skill_id),
        -- Bundled system Skills intentionally have no row in skills.
        FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX bot_skill_bindings_skill_id_index '
      'ON bot_skill_bindings(skill_id)',
    );
    await _createBotSkillReferenceValidationTriggers(db);
    await db.execute('''
      CREATE TABLE skill_activations (
        id TEXT PRIMARY KEY,
        run_id TEXT NOT NULL,
        chat_id TEXT NOT NULL,
        message_id TEXT NOT NULL DEFAULT '',
        skill_id TEXT NOT NULL,
        skill_name TEXT NOT NULL,
        content_digest TEXT NOT NULL,
        trigger_type TEXT NOT NULL,
        status TEXT NOT NULL,
        duration_ms INTEGER,
        error_code TEXT NOT NULL DEFAULT '',
        started_at INTEGER NOT NULL,
        completed_at INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX skill_activations_run_id_index '
      'ON skill_activations(run_id)',
    );
    await db.execute(
      'CREATE INDEX skill_activations_chat_id_index '
      'ON skill_activations(chat_id)',
    );
  }

  static Future<void> _createSkillEcosystemSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE skill_publishers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        key_id TEXT NOT NULL,
        public_key TEXT NOT NULL,
        organization TEXT NOT NULL DEFAULT '',
        trusted INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE skill_catalogs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        index_uri TEXT NOT NULL,
        publisher_id TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        last_error TEXT NOT NULL DEFAULT '',
        last_fetched_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE skill_script_grants (
        skill_id TEXT PRIMARY KEY,
        content_digest TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 0,
        approved_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE skill_organization_policy (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        allow_unsigned_skills INTEGER NOT NULL DEFAULT 1,
        allow_unknown_publishers INTEGER NOT NULL DEFAULT 0,
        allow_script_execution INTEGER NOT NULL DEFAULT 1,
        allow_automatic_updates INTEGER NOT NULL DEFAULT 0,
        allowed_publishers_json TEXT NOT NULL DEFAULT '[]',
        updated_at INTEGER
      )
    ''');
    await db.execute('''
      INSERT INTO skill_organization_policy (id) VALUES (1)
    ''');
    await db.execute('''
      CREATE TABLE skill_compliance_events (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        skill_id TEXT NOT NULL DEFAULT '',
        content_digest TEXT NOT NULL DEFAULT '',
        publisher_id TEXT NOT NULL DEFAULT '',
        decision TEXT NOT NULL DEFAULT '',
        reason TEXT NOT NULL DEFAULT '',
        metadata_json TEXT NOT NULL DEFAULT '{}',
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX skill_compliance_events_skill_id_index '
      'ON skill_compliance_events(skill_id, timestamp DESC)',
    );
  }

  static Future<void> _createConversationSkillPinSchema(
    DatabaseExecutor db,
  ) async {
    await db.execute('''
      CREATE TABLE conversation_skill_pins (
        chat_id TEXT NOT NULL,
        skill_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (chat_id, skill_id),
        -- Bundled system Skills intentionally have no row in skills.
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX conversation_skill_pins_skill_id_index '
      'ON conversation_skill_pins(skill_id)',
    );
    await _createConversationSkillReferenceValidationTriggers(db);
  }

  static Future<void> _createConversationMemorySchema(
    DatabaseExecutor db,
  ) async {
    await db.execute('''
      CREATE TABLE conversation_memory_state (
        chat_id TEXT PRIMARY KEY,
        revision INTEGER NOT NULL DEFAULT 0,
        active_summary_id TEXT NOT NULL DEFAULT '',
        covered_through_message_id TEXT NOT NULL DEFAULT '',
        auto_memory_enabled INTEGER NOT NULL DEFAULT 1,
        compaction_status TEXT NOT NULL DEFAULT 'idle',
        last_error TEXT NOT NULL DEFAULT '',
        last_compacted_at INTEGER,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE conversation_summary_segments (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        status TEXT NOT NULL,
        file_name TEXT NOT NULL,
        markdown_schema_version INTEGER NOT NULL DEFAULT 1,
        content_digest TEXT NOT NULL,
        content_bytes INTEGER NOT NULL DEFAULT 0,
        source_start_message_id TEXT NOT NULL,
        source_end_message_id TEXT NOT NULL,
        source_message_ids TEXT NOT NULL,
        source_digest TEXT NOT NULL,
        estimated_token_count INTEGER NOT NULL DEFAULT 0,
        provider TEXT NOT NULL DEFAULT '',
        model TEXT NOT NULL DEFAULT '',
        prompt_version INTEGER NOT NULL DEFAULT 1,
        base_revision INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX conversation_summary_chat_status_index '
      'ON conversation_summary_segments(chat_id, status)',
    );
    await db.execute('''
      CREATE TABLE conversation_memory_items (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        memory_key TEXT NOT NULL,
        kind TEXT NOT NULL,
        content TEXT NOT NULL,
        state TEXT NOT NULL,
        origin TEXT NOT NULL,
        importance REAL NOT NULL DEFAULT 0.5,
        confidence REAL NOT NULL DEFAULT 0.5,
        source_message_ids TEXT NOT NULL DEFAULT '[]',
        source_digest TEXT NOT NULL DEFAULT '',
        expires_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX conversation_memory_chat_key_index '
      'ON conversation_memory_items(chat_id, memory_key)',
    );
    await db.execute(
      'CREATE INDEX messages_chat_timestamp_message_index '
      'ON messages(chat_id, timestamp, message_id)',
    );
  }

  static Future<void> _createMcpSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE mcp_servers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        transport_type TEXT NOT NULL
          CHECK (transport_type IN ('streamableHttp', 'stdio')),
        transport_config_json TEXT NOT NULL,
        remote_server_name TEXT NOT NULL DEFAULT '',
        remote_server_version TEXT NOT NULL DEFAULT '',
        capabilities_json TEXT NOT NULL DEFAULT '{}',
        connection_status TEXT NOT NULL DEFAULT 'disconnected'
          CHECK (connection_status IN (
            'disconnected',
            'connecting',
            'connected',
            'authorizationRequired',
            'error'
          )),
        last_error_code TEXT NOT NULL DEFAULT '',
        last_connected_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE mcp_tools (
        server_id TEXT NOT NULL,
        remote_name TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        input_schema_json TEXT NOT NULL,
        output_schema_json TEXT,
        annotations_json TEXT NOT NULL DEFAULT '{}',
        task_support TEXT NOT NULL
          CHECK (task_support IN ('forbidden', 'optional', 'required')),
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (server_id, remote_name),
        FOREIGN KEY (server_id) REFERENCES mcp_servers(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX mcp_tools_server_id_index '
      'ON mcp_tools(server_id)',
    );
  }
}

final class _LegacyDataSource {
  const _LegacyDataSource({required this.database, required this.chats});

  final File database;
  final Directory chats;
}
