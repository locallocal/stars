import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/system_mcp_installer_skill.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled MCP installer Skill passes its content digest', () async {
    final skill = SystemMcpInstallerSkill();

    final content = await skill.loadContent();

    expect(skill.isValid, isTrue);
    expect(skill.promptVersion, 3);
    expect(skill.contentDigest, hasLength(64));
    expect(content.descriptor.id, mcpInstallerSkillId);
    expect(content.descriptor.name, 'mcp-installer');
    expect(content.descriptor.scope, SkillScope.bundled);
    expect(content.descriptor.trustState, SkillTrustState.bundledTrusted);
    expect(content.descriptor.requestedToolNames, mcpInstallerToolNames);
    expect(content.instructions, contains('list_installed_mcp_servers'));
    expect(content.instructions, contains('configuration_ref'));
    expect(content.instructions, contains('Never use placeholders'));
    expect(content.instructions, contains('list_current_conversation_mcp'));
    expect(content.instructions, contains('SQLite'));
    expect(content.instructions, contains('streamable_http'));
    expect(content.instructions, contains('stdio'));
    expect(content.instructions, contains('never overwrites'));
    expect(content.files, ['SKILL.md']);
  });
}
