import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/bundled_system_skill.dart';

void main() {
  const validSource = '''
---
name: test-skill
description: Test bundled Skill.
allowed-tools: test_tool
metadata:
  scope: system
  prompt-version: 1
---

# Test instructions
''';

  test('validates frontmatter against the runtime descriptor', () async {
    final skill = _TestBundledSystemSkill(validSource);

    final content = await skill.loadContent(
      bundle: _StringAssetBundle({skill.assetPath: validSource}),
    );

    expect(skill.isValid, isTrue);
    expect(content.descriptor.name, 'test-skill');
    expect(content.instructions, '# Test instructions');
  });

  test('rejects integrity-valid content whose metadata drifted', () async {
    final drifted = validSource.replaceFirst('name: test-skill', 'name: stale');
    final skill = _TestBundledSystemSkill(drifted);

    await expectLater(
      skill.loadContent(bundle: _StringAssetBundle({skill.assetPath: drifted})),
      throwsFormatException,
    );

    expect(skill.isValid, isFalse);
  });

  test('loads and integrity-checks bundled reference assets', () async {
    const reference = 'Use the bundled reference.';
    final skill = _TestBundledSystemSkill(
      validSource,
      referenceDigests: {
        'references/guide.md':
            sha256.convert(utf8.encode(reference)).toString(),
      },
    );

    final content = await skill.loadContent(
      bundle: _StringAssetBundle({
        skill.assetPath: validSource,
        'assets/test-skill/references/guide.md': reference,
      }),
    );

    expect(content.descriptor.hasReferences, isTrue);
    expect(content.files, ['SKILL.md', 'references/guide.md']);
    expect(content.resources['references/guide.md'], reference);
  });

  test('rejects a bundled reference whose integrity digest drifted', () async {
    final skill = _TestBundledSystemSkill(
      validSource,
      referenceDigests: const {
        'references/guide.md':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      },
    );

    await expectLater(
      skill.loadContent(
        bundle: _StringAssetBundle({
          skill.assetPath: validSource,
          'assets/test-skill/references/guide.md': 'Drifted reference.',
        }),
      ),
      throwsFormatException,
    );

    expect(skill.isValid, isFalse);
  });
}

final class _TestBundledSystemSkill extends BundledSystemSkill {
  _TestBundledSystemSkill(String source, {super.referenceDigests = const {}})
    : super(
        bundledAssetRoot: 'assets/test-skill',
        bundledAssetPath: 'assets/test-skill/SKILL.md',
        expectedDigest: sha256.convert(utf8.encode(source)).toString(),
        promptVersion: 1,
        skillId: 'system:test-skill',
        name: 'test-skill',
        description: 'Test bundled Skill.',
        compatibility: 'Stars',
        requestedToolNames: const {'test_tool'},
        integrityError: 'Test Skill failed integrity validation.',
      );

  String get assetPath => bundledAssetPath;
}

final class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this.sources);

  final Map<String, String> sources;

  @override
  Future<ByteData> load(String key) async {
    final source = sources[key];
    if (source == null) {
      throw StateError('Missing test asset: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(source));
    return ByteData.sublistView(bytes);
  }
}
