import 'package:stars/data/services/tools/bundled_system_skill.dart';
import 'package:stars/domain/models/models.dart';

final class SystemConversationHistorySkill extends BundledSystemSkill {
  SystemConversationHistorySkill()
    : super(
        bundledAssetRoot: assetRoot,
        bundledAssetPath: assetPath,
        expectedDigest: conversationHistorySkillContentDigest,
        promptVersion: conversationHistorySkillPromptVersion,
        skillId: conversationHistorySkillId,
        name: 'conversation-history',
        description:
            'Search and read exact persisted messages from the current '
            'conversation through read-only, parameterized SQLite queries.',
        compatibility: 'Stars',
        requestedToolNames: conversationHistoryToolNames,
        integrityError:
            'Built-in conversation history Skill failed integrity validation.',
      );

  static const assetRoot = 'assets/skills/system/conversation-history';
  static const assetPath = 'assets/skills/system/conversation-history/SKILL.md';
}
