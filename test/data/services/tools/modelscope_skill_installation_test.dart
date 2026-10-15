import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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
import 'package:stars/data/services/skills/skill_source_resolver.dart';
import 'package:stars/data/services/tools/resolve_skill_source_tool.dart';
import 'package:stars/data/services/tools/skill_installer_tool.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/skill_inventory_tools.dart';

void main() {
  sqfliteFfiInit();
  late Directory temporary;
  late Database database;
  late FileSkillRepository repository;
  late ExecutableTool inventory;
  late SkillInstallerTool installer;
  late ResolveSkillSourceTool resolver;
  var invalidSecondPackage = false;

  setUp(() async {
    invalidSecondPackage = false;
    temporary = await Directory.systemTemp.createTemp('stars-modelscope-test-');
    database = await databaseFactoryFfi.openDatabase(
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
    repository = FileSkillRepository(
      localDatabase: localDatabase,
      storageService: SkillPackageStorageService(
        applicationSupportDirectoryProvider:
            () async => Directory('${temporary.path}/support'),
      ),
      parser: const SkillParser(),
    );
    inventory =
        SkillInventoryToolSession(
          repository: SqliteSkillInventoryRepository(
            localDatabase: localDatabase,
          ),
          chatId: 'test-chat',
        ).createTools().first;
    final policy = SkillCatalogEndpointPolicy(
      dnsLookup: (_) async => [InternetAddress('8.8.8.8')],
    );
    resolver = ResolveSkillSourceTool(
      resolver: SkillSourceResolver(
        endpointPolicy: policy,
        fetcher: (uri, _, _) async {
          final index = int.parse(uri.queryParameters['PageNumber']!) - 1;
          final name = ['amap-lbs-skill', 'experiment-design'][index];
          return utf8.encode(
            jsonEncode({
              'Code': 200,
              'Success': true,
              'Data': {
                'CollectionElements': {
                  'Total': 2,
                  'CollectionElementVoList': [
                    {
                      'ElementType': 'skill',
                      'ElementPath': 'test-owner',
                      'ElementName': name,
                    },
                  ],
                },
              },
            }),
          );
        },
      ),
    );
    installer = SkillInstallerTool(
      installation: SkillInstallationService(
        skillRepository: repository,
        endpointPolicy: policy,
        fetcher: (uri, _, _) async {
          expect(uri.host, 'www.modelscope.cn');
          final name = uri.pathSegments[2];
          final root = 'skills-test-owner.$name-master-92b171e8';
          final archive =
              Archive()
                ..addFile(
                  ArchiveFile.string('$root/SKILL.md', '''
---
name: ${invalidSecondPackage && name == 'experiment-design' ? 'INVALID NAME' : name}
description: Standard third-party Skill.
version: 2.0.0
---
Use the supporting reference.
'''),
                )
                ..addFile(
                  ArchiveFile.string(
                    '$root/references/guide.md',
                    'Reference content.',
                  ),
                )
                ..addFile(
                  ArchiveFile.string(
                    '$root/scripts/helper.js',
                    'throw new Error("must not execute during import");',
                  ),
                );
          return ZipEncoder().encodeBytes(archive);
        },
        temporaryDirectoryProvider: () => temporary.createTemp('download-'),
      ),
    );
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
    await temporary.delete(recursive: true);
  });

  Future<List<Map<String, Object?>>> resolveCollection() async {
    final resolved = await resolver.execute(
      ToolCallRequest(
        callId: 'resolve',
        name: resolveSkillSourceToolName,
        arguments: const {
          'source':
              'npx skills add https://www.modelscope.cn/collections/Tashanworld/keyanjinengbao',
        },
      ),
      AgentCancellationToken(),
    );
    expect(resolved.isError, isFalse);
    expect(await database.query('skills'), isEmpty);
    return ((resolved.structuredContent! as Map<String, Object?>)['skills']!
            as List)
        .cast<Map<String, Object?>>();
  }

  Future<ToolResult> installEntry(Map<String, Object?> entry) =>
      installer.execute(
        ToolCallRequest(
          callId: 'install-${entry['name']}',
          name: installSkillToolName,
          arguments: {...entry}..remove('name'),
        ),
        AgentCancellationToken(),
      );

  test(
    'resolved collection packages become immutable, SQLite-queryable Stars Skills',
    () async {
      final entries = await resolveCollection();
      expect(entries, hasLength(2));
      for (final entry in entries) {
        final result = await installEntry(entry);
        expect(result.isError, isFalse, reason: result.content);
        final id =
            (result.structuredContent! as Map<String, Object?>)['skill_id']!
                as String;
        final query = await inventory.execute(
          ToolCallRequest(
            callId: 'verify-$id',
            name: listInstalledSkillsToolName,
            arguments: {'query': id},
          ),
          AgentCancellationToken(),
        );
        expect(query.isError, isFalse);
        final rows =
            ((query.structuredContent! as Map<String, Object?>)['skills']!
                    as List)
                .cast<Map<String, Object?>>();
        expect(rows.single['id'], id);
        expect(rows.single['version'], '2.0.0');
        expect(rows.single['enabled_bot_count'], 0);
        final content = await repository.load(id);
        expect(
          content.files,
          containsAll(['SKILL.md', 'scripts/helper.js', 'references/guide.md']),
        );
        expect(content.descriptor.sourceUri, entry['source']);
        expect(
          content.descriptor.rootPath,
          startsWith('${temporary.path}/support/skills/bundles/user/'),
        );
        expect(
          (await repository.readResource(id, 'references/guide.md')).content,
          'Reference content.',
        );
      }
      expect(await database.query('skills'), hasLength(2));
    },
  );

  test(
    'a rejected collection member is not reported or stored as installed',
    () async {
      invalidSecondPackage = true;
      final entries = await resolveCollection();
      final first = await installEntry(entries.first);
      final second = await installEntry(entries.last);
      expect(first.isError, isFalse);
      expect(second.isError, isTrue);
      expect(second.errorCode, 'skill_install_rejected');
      final rows = await database.query('skills');
      expect(rows, hasLength(1));
      expect(
        rows.single['id'],
        (first.structuredContent! as Map<String, Object?>)['skill_id'],
      );
    },
  );
}
