import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/skills/skill_installation_service.dart';
import 'package:stars/data/services/tools/skill_installer_tool.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  test('is approval-gated and exposes explicit installation fields', () {
    final tool = SkillInstallerTool(installation: _FakeInstallationGateway());
    final definition = tool.definition;
    final call = ToolCallRequest(
      callId: 'install-policy',
      name: installSkillToolName,
      arguments: const {
        'source_type': 'github',
        'source': 'https://github.com/acme/skill',
      },
    );
    final context = ToolPolicyContext(
      runId: 'run-1',
      chatId: 'chat-1',
      botId: 'bot-1',
      requestedToolNames: skillInstallerToolNames,
    );

    expect(definition.riskLevel, ToolRiskLevel.destructive);
    expect(definition.capabilities, contains(ToolCapability.localWrite));
    expect(definition.capabilities, contains(ToolCapability.network));
    expect(
      (definition.inputSchema['properties']! as Map<String, Object?>).keys,
      containsAll(<String>[
        'source_type',
        'source',
        'ref',
        'subdirectory',
        'archive_sha256',
      ]),
    );
    expect(
      const DefaultToolPolicy().evaluate(definition, call, context).outcome,
      ToolPolicyOutcome.deny,
    );
    expect(
      const DefaultToolPolicy(
        allowDestructiveWithApproval: true,
      ).evaluate(definition, call, context).outcome,
      ToolPolicyOutcome.requireApproval,
    );
  });

  test('maps arguments and returns the installed Skill metadata', () async {
    final gateway = _FakeInstallationGateway();
    final tool = SkillInstallerTool(installation: gateway);

    final result = await tool.execute(
      ToolCallRequest(
        callId: 'install-1',
        name: installSkillToolName,
        arguments: const {
          'source_type': 'github',
          'source': 'https://github.com/acme/skills',
          'ref': 'v1.2.0',
          'subdirectory': 'reviewer',
          'archive_sha256':
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        },
      ),
      AgentCancellationToken(),
    );

    expect(gateway.request?.sourceType, SkillInstallSourceType.github);
    expect(gateway.request?.ref, 'v1.2.0');
    expect(gateway.request?.subdirectory, 'reviewer');
    expect(result.isError, isFalse);
    expect(result.structuredContent, {
      'skill_id': 'user:reviewer',
      'name': 'reviewer',
      'version': '1.2.0',
      'description': 'Review code.',
      'source_uri': 'https://github.com/acme/skills',
      'content_digest': List.filled(64, 'c').join(),
      'trust_state': 'userReviewed',
      'signature_status': 'unsigned',
      'validation_status': 'validWithWarnings',
    });
  });

  test('returns a stable rejection error for invalid packages', () async {
    final tool = SkillInstallerTool(
      installation: _FakeInstallationGateway(reject: true),
    );

    final result = await tool.execute(
      ToolCallRequest(
        callId: 'install-failed',
        name: installSkillToolName,
        arguments: const {
          'source_type': 'local_zip',
          'source': '/tmp/invalid.zip',
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isTrue);
    expect(result.errorCode, 'skill_install_rejected');
    expect(result.content, 'Package rejected.');
  });

  test('rejects arguments that do not satisfy the public schema', () async {
    final gateway = _FakeInstallationGateway();
    final tool = SkillInstallerTool(installation: gateway);

    final result = await tool.execute(
      ToolCallRequest(
        callId: 'invalid-source',
        name: installSkillToolName,
        arguments: const {'source_type': 'github', 'source': 42},
      ),
      AgentCancellationToken(),
    );

    expect(result.errorCode, 'invalid_skill_source');
    expect(gateway.request, isNull);
  });
}

final class _FakeInstallationGateway implements SkillInstallationGateway {
  _FakeInstallationGateway({this.reject = false});

  final bool reject;
  SkillInstallationRequest? request;

  @override
  Future<SkillDescriptor> install(
    SkillInstallationRequest request,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    this.request = request;
    if (reject) throw const SkillInstallException('Package rejected.');
    final now = DateTime(2026, 8, 9);
    return SkillDescriptor(
      id: 'user:reviewer',
      name: 'reviewer',
      description: 'Review code.',
      version: '1.2.0',
      scope: SkillScope.user,
      sourceUri: request.source,
      rootPath: '/skills/reviewer',
      contentDigest: List.filled(64, 'c').join(),
      trustState: SkillTrustState.userReviewed,
      validationStatus: SkillValidationStatus.validWithWarnings,
      compatibility: 'Stars',
      installedAt: now,
      updatedAt: now,
    );
  }
}
