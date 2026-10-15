import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/skills/skill_parser.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'stars-skill-parser-',
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('parses standard metadata and progressive resource folders', () async {
    final root = await _createSkill(
      temporaryDirectory,
      name: 'release-notes',
      body: '''
---
name: release-notes
description: Prepare concise release notes from a change list.
license: Apache-2.0
compatibility: Stars desktop
metadata:
  version: "1.2.0"
allowed-tools: read search
---
# Release notes

Summarize user-visible changes first.
''',
    );
    await File('${root.path}/references/style.md').create(recursive: true);
    await File('${root.path}/assets/template.md').create(recursive: true);

    final parsed = await const SkillParser().parse(root);

    expect(parsed.name, 'release-notes');
    expect(parsed.description, contains('concise release notes'));
    expect(parsed.version, '1.2.0');
    expect(parsed.license, 'Apache-2.0');
    expect(parsed.compatibility, 'Stars desktop');
    expect(parsed.requestedToolNames, {'read', 'search'});
    expect(parsed.instructions, contains('Summarize user-visible changes'));
    expect(parsed.hasReferences, isTrue);
    expect(parsed.hasAssets, isTrue);
    expect(parsed.hasScripts, isFalse);
    expect(parsed.validationStatus, SkillValidationStatus.valid);
    expect(
      parsed.files,
      containsAll(<String>[
        'SKILL.md',
        'references/style.md',
        'assets/template.md',
      ]),
    );
  });

  test('keeps scripts gated and reports a sandbox approval warning', () async {
    final root = await _createSkill(
      temporaryDirectory,
      name: 'safe-review',
      body: '''
---
name: safe-review
description: Review a proposed change.
---
Review the change.
''',
    );
    await File('${root.path}/scripts/run.sh').create(recursive: true);

    final parsed = await const SkillParser().parse(root);

    expect(parsed.hasScripts, isTrue);
    expect(parsed.validationStatus, SkillValidationStatus.validWithWarnings);
    expect(
      parsed.diagnostics.map((item) => item.code),
      contains('scripts_require_sandbox_approval'),
    );
  });

  test(
    'accepts top-level ecosystem versions and prefers metadata.version',
    () async {
      for (final metadata in ['', 'metadata:\n  version: "3.0.0"\n']) {
        final root = await _createSkill(
          temporaryDirectory,
          name: 'standard-skill',
          body: '''
---
name: standard-skill
description: Standard third-party Skill.
version: 2.0.0
$metadata---
Use standard resources.
''',
        );
        final parsed = await const SkillParser().parse(root);
        expect(parsed.version, metadata.isEmpty ? '2.0.0' : '3.0.0');
        expect(parsed.validationStatus, SkillValidationStatus.valid);
      }
    },
  );

  test(
    'marks an invalid package instead of accepting mismatched identity',
    () async {
      final root = await _createSkill(
        temporaryDirectory,
        name: 'folder-name',
        body: '''
---
name: other-name
description: A mismatched Skill.
---
Do something.
''',
      );

      final parsed = await const SkillParser().parse(root);

      expect(parsed.validationStatus, SkillValidationStatus.invalid);
      expect(
        parsed.diagnostics.map((item) => item.code),
        contains('directory_mismatch'),
      );
    },
  );

  test('rejects SKILL.md without YAML frontmatter', () async {
    final root = await _createSkill(
      temporaryDirectory,
      name: 'invalid-frontmatter',
      body: '# No frontmatter',
    );

    expect(
      () => const SkillParser().parse(root),
      throwsA(isA<SkillInstallException>()),
    );
  });
}

Future<Directory> _createSkill(
  Directory parent, {
  required String name,
  required String body,
}) async {
  final root = Directory('${parent.path}/$name');
  await root.create(recursive: true);
  await File('${root.path}/SKILL.md').writeAsString(body);
  return root;
}
