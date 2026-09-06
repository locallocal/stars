import 'package:stars/data/services/tools/bundled_system_skill.dart';
import 'package:stars/domain/models/models.dart';

final class SystemSkillInstallerSkill extends BundledSystemSkill {
  SystemSkillInstallerSkill()
    : super(
        bundledAssetRoot: assetRoot,
        bundledAssetPath: assetPath,
        expectedDigest: skillInstallerSkillContentDigest,
        promptVersion: skillInstallerSkillPromptVersion,
        skillId: skillInstallerSkillId,
        name: 'skill-installer',
        description:
            'Install Stars Skills and inspect installed or current-conversation '
            'Skill state from SQLite.',
        compatibility: 'Stars desktop',
        requestedToolNames: skillInstallerToolNames,
        integrityError: 'Built-in Skill installer failed integrity validation.',
      );

  static const assetRoot = 'assets/skills/system/skill-installer';
  static const assetPath = 'assets/skills/system/skill-installer/SKILL.md';
}
