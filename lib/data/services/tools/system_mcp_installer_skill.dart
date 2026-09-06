import 'package:stars/data/services/tools/bundled_system_skill.dart';
import 'package:stars/domain/models/models.dart';

final class SystemMcpInstallerSkill extends BundledSystemSkill {
  SystemMcpInstallerSkill()
    : super(
        bundledAssetRoot: assetRoot,
        bundledAssetPath: assetPath,
        expectedDigest: mcpInstallerSkillContentDigest,
        promptVersion: mcpInstallerSkillPromptVersion,
        skillId: mcpInstallerSkillId,
        name: 'mcp-installer',
        description:
            'Install Stars MCP servers and query installed servers or the '
            'current conversation Bot\'s enabled MCP servers and Tools from '
            'SQLite. Use when the user asks to add, configure, register, or '
            'install an MCP server, list installed MCP servers, or inspect '
            'which MCP servers and Tools are enabled for the current '
            'conversation.',
        compatibility: 'Stars desktop',
        requestedToolNames: mcpInstallerToolNames,
        integrityError:
            'Built-in MCP installer Skill failed integrity validation.',
      );

  static const assetRoot = 'assets/skills/system/mcp-installer';
  static const assetPath = 'assets/skills/system/mcp-installer/SKILL.md';
}
