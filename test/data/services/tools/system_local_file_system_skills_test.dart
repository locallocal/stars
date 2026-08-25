import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/system_local_file_system_skills.dart';
import 'package:stars/domain/models/models.dart';
import 'package:yaml/yaml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled directory operations Skill passes its content digest',
    () async {
      final skill = SystemDirectoryOperationsSkill();

      final content = await skill.loadContent();
      await _expectFrontmatterMatches(
        assetPath: skill.assetPath,
        content: content,
        promptVersion: skill.promptVersion,
      );

      expect(skill.isValid, isTrue);
      expect(skill.promptVersion, directoryOperationsSkillPromptVersion);
      expect(skill.contentDigest, hasLength(64));
      expect(content.descriptor.id, directoryOperationsSkillId);
      expect(content.descriptor.scope, SkillScope.bundled);
      expect(content.descriptor.trustState, SkillTrustState.bundledTrusted);
      expect(
        content.descriptor.requestedToolNames,
        directoryOperationsToolNames,
      );
      expect(content.descriptor.compatibility, contains('Android'));
      expect(content.descriptor.compatibility, contains('Windows'));
      expect(content.instructions, contains('list_local_directory'));
      expect(content.instructions, contains('recursive'));
      expect(content.instructions, contains('invoke PowerShell'));
      expect(content.files, ['SKILL.md']);
    },
  );

  test('bundled file operations Skill passes its content digest', () async {
    final skill = SystemFileOperationsSkill();

    final content = await skill.loadContent();
    await _expectFrontmatterMatches(
      assetPath: skill.assetPath,
      content: content,
      promptVersion: skill.promptVersion,
    );

    expect(skill.isValid, isTrue);
    expect(skill.promptVersion, fileOperationsSkillPromptVersion);
    expect(skill.contentDigest, hasLength(64));
    expect(content.descriptor.id, fileOperationsSkillId);
    expect(content.descriptor.scope, SkillScope.bundled);
    expect(content.descriptor.trustState, SkillTrustState.bundledTrusted);
    expect(content.descriptor.requestedToolNames, fileOperationsToolNames);
    expect(content.descriptor.compatibility, contains('iOS'));
    expect(content.descriptor.compatibility, contains('Linux'));
    expect(content.instructions, contains('read_local_file'));
    expect(content.instructions, contains('next_offset_bytes'));
    expect(content.instructions, contains('overwrite'));
    expect(content.files, ['SKILL.md']);
  });
}

Future<void> _expectFrontmatterMatches({
  required String assetPath,
  required SkillContent content,
  required int promptVersion,
}) async {
  final source = await rootBundle.loadString(assetPath);
  final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final lines = normalized.split('\n');
  final closingIndex = lines.indexWhere((line) => line.trim() == '---', 1);
  final frontmatter =
      loadYaml(lines.sublist(1, closingIndex).join('\n'))! as YamlMap;
  final metadata = frontmatter['metadata']! as YamlMap;

  expect(content.descriptor.name, frontmatter['name']);
  expect(content.descriptor.description, frontmatter['description']);
  expect(metadata['prompt-version'], promptVersion);
  expect(
    content.descriptor.requestedToolNames,
    (frontmatter['allowed-tools']! as String).split(RegExp(r'\s+')).toSet(),
  );
}
