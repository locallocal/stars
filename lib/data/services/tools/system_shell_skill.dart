import 'package:stars/data/services/tools/bundled_system_skill.dart';
import 'package:stars/domain/models/models.dart';

final class SystemShellSkill extends BundledSystemSkill {
  SystemShellSkill()
    : super(
        bundledAssetRoot: assetRoot,
        bundledAssetPath: assetPath,
        expectedDigest: shellCommandSkillContentDigest,
        promptVersion: shellCommandSkillPromptVersion,
        skillId: shellCommandSkillId,
        name: 'shell-command',
        description:
            'Run build, test, version-control, package-manager, diagnostic, '
            'or other process-oriented commands through the native desktop '
            'shell when no structured built-in Tool fits; do not use for '
            'ordinary file or directory operations.',
        compatibility: 'Stars desktop',
        requestedToolNames: shellCommandToolNames,
        integrityError:
            'Built-in shell command Skill failed integrity validation.',
      );

  static const assetRoot = 'assets/skills/system/shell-command';
  static const assetPath = 'assets/skills/system/shell-command/SKILL.md';
}
