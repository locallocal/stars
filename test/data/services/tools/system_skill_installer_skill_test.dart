import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/system_skill_installer_skill.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Skill installer passes its content digest', () async {
    final skill = SystemSkillInstallerSkill();

    final content = await skill.loadContent();

    expect(skill.isValid, isTrue);
    expect(skill.promptVersion, 3);
    expect(skill.contentDigest, hasLength(64));
    expect(content.descriptor.id, skillInstallerSkillId);
    expect(content.descriptor.scope, SkillScope.bundled);
    expect(content.descriptor.trustState, SkillTrustState.bundledTrusted);
    expect(content.descriptor.requestedToolNames, skillInstallerToolNames);
    expect(content.instructions, contains('source_type'));
    expect(content.instructions, contains('subdirectory'));
    expect(content.instructions, contains('list_installed_skills'));
    expect(content.instructions, contains('exact `skill_id`'));
    expect(content.instructions, contains('Never use `run_shell_command`'));
    expect(content.instructions, contains('configured_enabled'));
    expect(content.files, ['SKILL.md']);
  });
}
