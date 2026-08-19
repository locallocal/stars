import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/file_skill_repository.dart';
import 'package:stars/data/repositories/sqlite_skill_inventory_repository.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/data/services/skills/skill_installation_service.dart';
import 'package:stars/data/services/skills/skill_package_storage_service.dart';
import 'package:stars/data/services/skills/skill_parser.dart';
import 'package:stars/data/services/tools/skill_installer_tool.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  sqfliteFfiInit();

  test('session installer persists a queryable SQLite Skill record', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'stars-session-skill-verification-',
    );
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onConfigure: DatabaseService.configure,
        onCreate: DatabaseService.createSchema,
      ),
    );
    final localDatabase = LocalDatabaseService(
      databaseProvider: () async => database,
    );
    final repository = FileSkillRepository(
      localDatabase: localDatabase,
      storageService: SkillPackageStorageService(
        applicationSupportDirectoryProvider:
            () async => Directory('${temporary.path}/support'),
      ),
      parser: const SkillParser(),
    );
    addTearDown(() async {
      await repository.dispose();
      await database.close();
      await temporary.delete(recursive: true);
    });

    final source = Directory('${temporary.path}/session-installed');
    await source.create(recursive: true);
    await File('${source.path}/SKILL.md').writeAsString('''
---
name: session-installed
description: Verify session installation persistence.
metadata:
  version: "1.0.0"
---
Verification instructions.
''');

    final tool = SkillInstallerTool(
      installation: SkillInstallationService(
        skillRepository: repository,
        endpointPolicy: SkillCatalogEndpointPolicy(),
      ),
    );
    final result = await tool.execute(
      ToolCallRequest(
        callId: 'verify-install',
        name: installSkillToolName,
        arguments: {'source_type': 'local_directory', 'source': source.path},
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isFalse);
    expect(
      result.structuredContent,
      containsPair('skill_id', 'user:session-installed'),
    );

    final rows = await database.query(
      'skills',
      where: 'id = ?',
      whereArgs: ['user:session-installed'],
    );
    expect(rows, hasLength(1));
    expect(rows.single['name'], 'session-installed');

    final inventory = SqliteSkillInventoryRepository(
      localDatabase: localDatabase,
    );
    final page = await inventory.listInstalled(
      query: 'user:session-installed',
      limit: 10,
    );
    expect(page.items, hasLength(1));
    expect(page.items.single.id, 'user:session-installed');
    expect(page.items.single.version, '1.0.0');
  });
}
