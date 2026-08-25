import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/system_shell_skill.dart';
import 'package:stars/domain/models/models.dart';
import 'package:yaml/yaml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled shell Skill passes its content digest', () async {
    final skill = SystemShellSkill();

    final content = await skill.loadContent();
    final frontmatter = await _loadFrontmatter(SystemShellSkill.assetPath);
    final metadata = frontmatter['metadata']! as YamlMap;

    expect(skill.isValid, isTrue);
    expect(skill.promptVersion, shellCommandSkillPromptVersion);
    expect(skill.contentDigest, hasLength(64));
    expect(content.descriptor.id, shellCommandSkillId);
    expect(content.descriptor.name, frontmatter['name']);
    expect(content.descriptor.description, frontmatter['description']);
    expect(metadata['prompt-version'], skill.promptVersion);
    expect(content.descriptor.scope, SkillScope.bundled);
    expect(content.descriptor.trustState, SkillTrustState.bundledTrusted);
    expect(content.descriptor.requestedToolNames, shellCommandToolNames);
    expect(content.instructions, contains('Every command requires'));
    expect(content.instructions, contains('list_local_directory'));
    expect(content.instructions, contains('working_directory'));
    expect(content.files, ['SKILL.md']);
  });
}

Future<YamlMap> _loadFrontmatter(String assetPath) async {
  final source = await rootBundle.loadString(assetPath);
  final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final lines = normalized.split('\n');
  final closingIndex = lines.indexWhere((line) => line.trim() == '---', 1);
  return loadYaml(lines.sublist(1, closingIndex).join('\n'))! as YamlMap;
}
