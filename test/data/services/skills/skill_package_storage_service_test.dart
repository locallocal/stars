import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/skills/skill_package_storage_service.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory supportDirectory;
  late SkillPackageStorageService service;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'stars-skill-storage-',
    );
    supportDirectory = Directory('${temporaryDirectory.path}/support');
    service = SkillPackageStorageService(
      applicationSupportDirectoryProvider: () async => supportDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'stages and commits a directory to a content-addressed bundle',
    () async {
      final source = Directory('${temporaryDirectory.path}/summarize');
      await source.create(recursive: true);
      await File('${source.path}/SKILL.md').writeAsString('''
---
name: summarize
description: Summarize supplied material.
---
Keep the summary concise.
''');
      await File('${source.path}/references/tone.md').create(recursive: true);
      await File(
        '${source.path}/references/tone.md',
      ).writeAsString('Use a neutral tone.');

      final staged = await service.stage(
        SkillImportSource(kind: SkillImportKind.directory, path: source.path),
      );
      final stored = await service.commit(
        staged,
        scope: SkillScope.user.name,
        skillName: 'summarize',
      );

      expect(stored.contentDigest, hasLength(64));
      expect(
        stored.rootPath,
        contains('/skills/bundles/user/summarize/${stored.contentDigest}'),
      );
      expect(
        await service.readInstructions(stored.rootPath),
        'Keep the summary concise.',
      );
      expect(
        await service.listFiles(stored.rootPath),
        containsAll(<String>['SKILL.md', 'references/tone.md']),
      );
      expect(
        await service.readReference(stored.rootPath, 'references/tone.md'),
        'Use a neutral tone.',
      );
      await expectLater(
        service.readReference(stored.rootPath, '../SKILL.md'),
        throwsA(isA<SkillInstallException>()),
      );
      await expectLater(
        service.readReference(stored.rootPath, 'SKILL.md'),
        throwsA(isA<SkillInstallException>()),
      );
    },
  );

  for (final compressed in [false, true]) {
    test(
      'installs a ZIP exceeding former byte limits (compressed: $compressed)',
      () async {
        final payload = Uint8List(21 * 1024 * 1024 + 1)..last = 42;
        final archive =
            Archive()
              ..addFile(ArchiveFile.string('large/SKILL.md', 'Large package.'))
              ..addFile(
                compressed
                    ? ArchiveFile(
                      'large/data/catalog.json',
                      payload.length,
                      payload,
                    )
                    : ArchiveFile.noCompress(
                      'large/data/catalog.json',
                      payload.length,
                      payload,
                    ),
              );
        final bytes = ZipEncoder().encodeBytes(archive);
        if (!compressed) expect(bytes.length, greaterThan(20 * 1024 * 1024));
        final zip = await File(
          '${temporaryDirectory.path}/large.zip',
        ).writeAsBytes(bytes);

        final staged = await service.stage(
          SkillImportSource(
            kind: SkillImportKind.zipArchive,
            path: zip.path,
            expectedArchiveDigest: sha256.convert(bytes).toString(),
          ),
        );
        final stored = await service.commit(
          staged,
          scope: 'user',
          skillName: 'large',
        );
        final installed = File('${stored.rootPath}/data/catalog.json');

        expect(await installed.length(), payload.length);
        expect(
          await sha256.bind(installed.openRead()).first,
          sha256.convert(payload),
        );
        await service.verifyImmutableInstallation(
          stored.rootPath,
          stored.contentDigest,
        );
        expect(await staged.stagingDirectory.exists(), isFalse);
      },
    );
  }

  test(
    'copies a local package exceeding the former single and total limits',
    () async {
      final source =
          await Directory('${temporaryDirectory.path}/large').create();
      await File(
        '${source.path}/SKILL.md',
      ).writeAsString('Large local package.');
      final payload = File('${source.path}/payload.bin');
      final handle = await payload.open(mode: FileMode.write);
      try {
        await handle.truncate(21 * 1024 * 1024 + 1);
      } finally {
        await handle.close();
      }
      final expectedDigest = await service.computeContentDigest(source);

      final staged = await service.stage(
        SkillImportSource(kind: SkillImportKind.directory, path: source.path),
      );
      final stored = await service.commit(
        staged,
        scope: 'user',
        skillName: 'large',
      );

      expect(
        await File('${stored.rootPath}/payload.bin').length(),
        await payload.length(),
      );
      expect(stored.contentDigest, expectedDigest);
    },
  );

  test('streaming digest preserves the signed payload encoding', () async {
    final source =
        await Directory('${temporaryDirectory.path}/digest').create();
    await File('${source.path}/b.txt').writeAsBytes([0, 255, 42]);
    await File('${source.path}/a.txt').writeAsString('你好');
    final expected = sha256.convert([
      ...utf8.encode('a.txt'),
      0,
      ...utf8.encode('你好'),
      0,
      ...utf8.encode('b.txt'),
      0,
      0,
      255,
      42,
      0,
    ]);

    expect(await service.computeContentDigest(source), expected.toString());
  });

  test(
    'rejects corrupt ZIP payloads and removes partially staged files',
    () async {
      final payload = utf8.encode('unique-payload-to-corrupt');
      final archive =
          Archive()
            ..addFile(ArchiveFile.string('safe/SKILL.md', 'Instructions.'))
            ..addFile(
              ArchiveFile.noCompress('safe/data.bin', payload.length, payload),
            );
      final bytes = ZipEncoder().encodeBytes(archive);
      final offset = latin1.decode(bytes).indexOf('unique-payload-to-corrupt');
      expect(offset, greaterThan(0));
      bytes[offset] ^= 1;
      final zip = await File(
        '${temporaryDirectory.path}/corrupt.zip',
      ).writeAsBytes(bytes);

      await expectLater(
        service.stage(
          SkillImportSource(kind: SkillImportKind.zipArchive, path: zip.path),
        ),
        throwsA(isA<SkillInstallException>()),
      );

      expect(
        await Directory(
          '${supportDirectory.path}/skills/staging',
        ).list().toList(),
        isEmpty,
      );
    },
  );

  test('rejects ZIP symlinks without extracting their targets', () async {
    final archive =
        Archive()
          ..addFile(ArchiveFile.string('safe/SKILL.md', 'Instructions.'))
          ..addFile(
            ArchiveFile.string('safe/link', '../../outside')
              ..mode = 0xa1ff
              ..symbolicLink = '../../outside',
          );
    final zip = await File(
      '${temporaryDirectory.path}/link.zip',
    ).writeAsBytes(ZipEncoder().encodeBytes(archive));

    await expectLater(
      service.stage(
        SkillImportSource(kind: SkillImportKind.zipArchive, path: zip.path),
      ),
      throwsA(isA<SkillInstallException>()),
    );
  });

  test('rejects ZIP path traversal before writing outside staging', () async {
    final zipFile = File('${temporaryDirectory.path}/malicious.zip');
    final archive =
        Archive()
          ..addFile(ArchiveFile.string('../outside.txt', 'escaped'))
          ..addFile(
            ArchiveFile.string('safe-skill/SKILL.md', '''
---
name: safe-skill
description: A nominal package.
---
Do work.
'''),
          );
    await zipFile.writeAsBytes(ZipEncoder().encodeBytes(archive));

    expect(
      () => service.stage(
        SkillImportSource(kind: SkillImportKind.zipArchive, path: zipFile.path),
      ),
      throwsA(isA<SkillInstallException>()),
    );
    expect(
      File('${supportDirectory.path}/skills/outside.txt').existsSync(),
      isFalse,
    );
    expect(
      File('${temporaryDirectory.path}/outside.txt').existsSync(),
      isFalse,
    );
  });

  test('selects one nested Skill from a repository ZIP', () async {
    final zipFile = File('${temporaryDirectory.path}/repository.zip');
    final archive =
        Archive()
          ..addFile(
            ArchiveFile.string('repository-main/skills/alpha/SKILL.md', '''
---
name: alpha
description: Alpha Skill.
---
Run alpha.
'''),
          )
          ..addFile(
            ArchiveFile.string('repository-main/skills/beta/SKILL.md', '''
---
name: beta
description: Beta Skill.
---
Run beta.
'''),
          );
    await zipFile.writeAsBytes(ZipEncoder().encodeBytes(archive));

    final staged = await service.stage(
      SkillImportSource(
        kind: SkillImportKind.zipArchive,
        path: zipFile.path,
        subdirectory: 'skills/beta',
      ),
    );

    expect(staged.skillRoot.path, endsWith('/repository-main/skills/beta'));
    expect(
      await File('${staged.skillRoot.path}/SKILL.md').readAsString(),
      contains('name: beta'),
    );
    await service.cleanup(staged);
  });

  test('rejects an unsafe Skill subdirectory', () async {
    final zipFile = File('${temporaryDirectory.path}/safe.zip');
    final archive =
        Archive()..addFile(
          ArchiveFile.string('safe/SKILL.md', '''
---
name: safe
description: Safe Skill.
---
Run safely.
'''),
        );
    await zipFile.writeAsBytes(ZipEncoder().encodeBytes(archive));

    await expectLater(
      service.stage(
        SkillImportSource(
          kind: SkillImportKind.zipArchive,
          path: zipFile.path,
          subdirectory: '../safe',
        ),
      ),
      throwsA(isA<SkillInstallException>()),
    );
  });

  test(
    'detached signature does not change the signed content digest',
    () async {
      final source = Directory('${temporaryDirectory.path}/signed');
      await source.create(recursive: true);
      await File('${source.path}/SKILL.md').writeAsString('''
---
name: signed
description: Signed content.
---
Do work.
''');
      final before = await service.computeContentDigest(source);
      await File(
        '${source.path}/SIGNATURE.json',
      ).writeAsString('{"signature":"detached"}');
      final after = await service.computeContentDigest(source);

      expect(after, before);
    },
  );

  test(
    'script execution verification rejects a modified installation',
    () async {
      final source = Directory('${temporaryDirectory.path}/immutable');
      await source.create(recursive: true);
      await File('${source.path}/SKILL.md').writeAsString('''
---
name: immutable
description: Immutable content.
---
Do work.
''');
      final staged = await service.stage(
        SkillImportSource(kind: SkillImportKind.directory, path: source.path),
      );
      final stored = await service.commit(
        staged,
        scope: SkillScope.user.name,
        skillName: 'immutable',
      );
      await File('${stored.rootPath}/SKILL.md').writeAsString('modified');

      expect(
        () => service.verifyImmutableInstallation(
          stored.rootPath,
          stored.contentDigest,
        ),
        throwsA(isA<SkillInstallException>()),
      );
    },
  );

  test('rejects symbolic links in directory imports', () async {
    if (Platform.isWindows) return;
    final source = Directory('${temporaryDirectory.path}/linked');
    await source.create(recursive: true);
    await File('${source.path}/SKILL.md').writeAsString('''
---
name: linked
description: Contains an unsafe link.
---
Do work.
''');
    final external = File('${temporaryDirectory.path}/secret.txt');
    await external.writeAsString('secret');
    await Link('${source.path}/reference.txt').create(external.path);

    expect(
      () => service.stage(
        SkillImportSource(kind: SkillImportKind.directory, path: source.path),
      ),
      throwsA(isA<SkillInstallException>()),
    );
  });
}
