import 'package:stars/data/services/tools/bundled_system_skill.dart';
import 'package:stars/domain/models/models.dart';

final class SystemDirectoryOperationsSkill extends BundledSystemSkill {
  SystemDirectoryOperationsSkill()
    : super(
        bundledAssetRoot: 'assets/skills/system/directory-operations',
        bundledAssetPath: 'assets/skills/system/directory-operations/SKILL.md',
        expectedDigest: directoryOperationsSkillContentDigest,
        promptVersion: directoryOperationsSkillPromptVersion,
        skillId: directoryOperationsSkillId,
        name: 'directory-operations',
        description:
            'Inspect, create, or delete local directories with Stars\' '
            'structured tools. Use for folder-level requests; use '
            'file-operations for individual files, and require current tool '
            'evidence for directory state and completed actions.',
        compatibility:
            'Stars native platforms (Android, iOS, Windows, macOS, Linux)',
        requestedToolNames: directoryOperationsToolNames,
        integrityError:
            'Built-in directory operations Skill failed integrity validation.',
      );

  String get assetPath => bundledAssetPath;
}

final class SystemFileOperationsSkill extends BundledSystemSkill {
  SystemFileOperationsSkill()
    : super(
        bundledAssetRoot: 'assets/skills/system/file-operations',
        bundledAssetPath: 'assets/skills/system/file-operations/SKILL.md',
        expectedDigest: fileOperationsSkillContentDigest,
        promptVersion: fileOperationsSkillPromptVersion,
        skillId: fileOperationsSkillId,
        name: 'file-operations',
        description:
            'Find, inspect, create, append, overwrite, copy, move, or delete '
            'individual local files with Stars\' structured tools. Use for '
            'file-level requests; use directory-operations for folders, and '
            'require current tool evidence for file state and completed '
            'actions.',
        compatibility:
            'Stars native platforms (Android, iOS, Windows, macOS, Linux)',
        requestedToolNames: fileOperationsToolNames,
        integrityError:
            'Built-in file operations Skill failed integrity validation.',
      );

  String get assetPath => bundledAssetPath;
}
