import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/file_skill_repository.dart';
import 'package:stars/data/repositories/sqlite_bot_skill_binding_repository.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/data/services/skills/skill_package_storage_service.dart';
import 'package:stars/data/services/skills/skill_parser.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  sqfliteFfiInit();

  late Directory temporaryDirectory;
  late Database database;
  late FileSkillRepository repository;
  late SqliteBotSkillBindingRepository bindingRepository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'stars-skill-repository-',
    );
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
            () async => Directory('${temporaryDirectory.path}/support'),
      ),
      parser: const SkillParser(),
    );
    bindingRepository = SqliteBotSkillBindingRepository(
      localDatabase: localDatabase,
    );
  });

  tearDown(() async {
    await bindingRepository.dispose();
    await repository.dispose();
    await database.close();
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'installs, updates, loads, and uninstalls an immutable folder Skill',
    () async {
      final source = Directory('${temporaryDirectory.path}/release-notes');
      await source.create(recursive: true);
      final skillFile = File('${source.path}/SKILL.md');
      await skillFile.writeAsString(_skillSource('First instructions.'));
      await File('${source.path}/references/style.md').create(recursive: true);
      await File(
        '${source.path}/references/style.md',
      ).writeAsString('Use concise headings.');

      final first = await repository.install(
        SkillImportSource(kind: SkillImportKind.directory, path: source.path),
      );
      final firstRoot = Directory(first.rootPath);
      expect(first.id, 'user:release-notes');
      expect(first.trustState, SkillTrustState.userReviewed);
      expect(firstRoot.existsSync(), isTrue);
      expect(
        first.rootPath,
        startsWith('${temporaryDirectory.path}/support/skills/bundles/'),
      );
      expect((await repository.load(first.id)).files, const [
        'SKILL.md',
        'references/style.md',
      ]);
      expect(
        (await repository.load(first.id)).instructions,
        'First instructions.',
      );
      expect(
        (await repository.readResource(
          first.id,
          'references/style.md',
          contentDigest: first.contentDigest,
        )).content,
        'Use concise headings.',
      );
      await expectLater(
        repository.readResource(first.id, 'SKILL.md'),
        throwsA(
          isA<SkillInstallException>().having(
            (error) => error.code,
            'code',
            'invalid_skill_reference_path',
          ),
        ),
      );
      await expectLater(
        repository.readResource(first.id, 'references/missing.md'),
        throwsA(
          isA<SkillInstallException>().having(
            (error) => error.code,
            'code',
            'skill_reference_not_found',
          ),
        ),
      );
      await expectLater(
        repository.readResource('user:missing', 'references/style.md'),
        throwsA(
          isA<SkillInstallException>().having(
            (error) => error.code,
            'code',
            'skill_not_installed',
          ),
        ),
      );
      await File(
        '${source.path}/references/style.md',
      ).writeAsString('Changed after import.');
      expect(
        (await repository.readResource(
          first.id,
          'references/style.md',
          contentDigest: first.contentDigest,
        )).content,
        'Use concise headings.',
      );

      await skillFile.writeAsString(_skillSource('Updated instructions.'));
      final updated = await repository.install(
        SkillImportSource(kind: SkillImportKind.directory, path: source.path),
      );

      expect(updated.id, first.id);
      expect(updated.contentDigest, isNot(first.contentDigest));
      expect(updated.rootPath, isNot(first.rootPath));
      expect(firstRoot.existsSync(), isTrue);
      expect(
        (await repository.load(updated.id)).instructions,
        'Updated instructions.',
      );

      final timestamp = DateTime(2026, 7, 26);
      await database.insert('bots', _botRow('bot-1'));
      await bindingRepository.save(
        BotSkillBinding(
          botId: 'bot-1',
          skillId: updated.id,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
      await repository.uninstall(updated.id);

      expect(await repository.getInstalled(forceRefresh: true), isEmpty);
      expect(await bindingRepository.getForBot('bot-1'), isEmpty);
      expect(Directory(updated.rootPath).existsSync(), isFalse);
      expect(firstRoot.existsSync(), isFalse);
    },
  );

  test('installs a valid ZIP whose SKILL.md is at archive root', () async {
    final zipFile = File('${temporaryDirectory.path}/zip-skill.zip');
    final archive =
        Archive()..addFile(
          ArchiveFile.string('SKILL.md', '''
---
name: zip-skill
description: Imported directly from an archive root.
metadata:
  version: "2.0.0"
---
ZIP instructions.
'''),
        );
    await zipFile.writeAsBytes(ZipEncoder().encodeBytes(archive));

    final installed = await repository.install(
      SkillImportSource(kind: SkillImportKind.zipArchive, path: zipFile.path),
    );

    expect(installed.name, 'zip-skill');
    expect(installed.version, '2.0.0');
    expect(
      (await repository.load(installed.id)).instructions,
      'ZIP instructions.',
    );
  });

  test('invalid YAML never becomes an installed bundle', () async {
    final source = Directory('${temporaryDirectory.path}/broken-skill');
    await source.create(recursive: true);
    await File('${source.path}/SKILL.md').writeAsString('''
---
name: [broken
description: Invalid YAML.
---
Do not install.
''');

    await expectLater(
      repository.install(
        SkillImportSource(kind: SkillImportKind.directory, path: source.path),
      ),
      throwsA(isA<SkillInstallException>()),
    );

    expect(await repository.getInstalled(forceRefresh: true), isEmpty);
    final bundles = Directory(
      '${temporaryDirectory.path}/support/skills/bundles',
    );
    expect(
      bundles.existsSync()
          ? bundles.listSync(recursive: true).whereType<File>()
          : const <File>[],
      isEmpty,
    );
  });
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

String _skillSource(String instructions) => '''
---
name: release-notes
description: Prepare concise release notes.
metadata:
  version: "1.0.0"
---
$instructions
''';
