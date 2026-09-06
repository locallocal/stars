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
      bundle: _StringAssetBundle(validSource),
    );

    expect(skill.isValid, isTrue);
    expect(content.descriptor.name, 'test-skill');
    expect(content.instructions, '# Test instructions');
  });

  test('rejects integrity-valid content whose metadata drifted', () async {
    final drifted = validSource.replaceFirst('name: test-skill', 'name: stale');
    final skill = _TestBundledSystemSkill(drifted);

    await expectLater(
      skill.loadContent(bundle: _StringAssetBundle(drifted)),
      throwsFormatException,
    );

    expect(skill.isValid, isFalse);
  });
}

final class _TestBundledSystemSkill extends BundledSystemSkill {
  _TestBundledSystemSkill(String source)
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
}

final class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this.source);

  final String source;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(source));
    return ByteData.sublistView(bytes);
  }
}
