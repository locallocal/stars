import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/system_skill_routing_policy.dart';

void main() {
  const policy = SystemSkillRoutingPolicy();
  const allSystemSkills = {
    shellCommandSkillId,
    directoryOperationsSkillId,
    fileOperationsSkillId,
    skillInstallerSkillId,
    mcpInstallerSkillId,
  };

  group('SystemSkillRoutingPolicy', () {
    test('selects only file operations for a local HTML save request', () {
      final selected = policy.select(
        query: '使用 HTML 生成简历页面，保存到本地',
        enabledSkillIds: allSystemSkills,
      );

      expect(selected, {fileOperationsSkillId});
    });

    test('can combine file and directory operations', () {
      final selected = policy.select(
        query: 'Read a file and list its parent directory',
        enabledSkillIds: allSystemSkills,
      );

      expect(selected, {directoryOperationsSkillId, fileOperationsSkillId});
    });

    test('routes process and installer requests independently', () {
      expect(
        policy.select(
          query: 'Run flutter test for this project',
          enabledSkillIds: allSystemSkills,
        ),
        {shellCommandSkillId},
      );
      expect(
        policy.select(
          query: 'Install this Skill from GitHub',
          enabledSkillIds: allSystemSkills,
        ),
        {skillInstallerSkillId},
      );
      expect(
        policy.select(
          query: 'Show the configured MCP server status',
          enabledSkillIds: allSystemSkills,
        ),
        {mcpInstallerSkillId},
      );
    });

    test('never selects a disabled system Skill', () {
      final selected = policy.select(
        query: 'Save this file and run flutter test',
        enabledSkillIds: const {fileOperationsSkillId},
      );

      expect(selected, {fileOperationsSkillId});
    });

    test('does not expose privileged tools for an unrelated greeting', () {
      final selected = policy.select(
        query: '你好，请介绍一下自己',
        enabledSkillIds: allSystemSkills,
      );

      expect(selected, isEmpty);
    });
  });
}
