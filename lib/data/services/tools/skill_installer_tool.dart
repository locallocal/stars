import 'package:stars/data/services/skills/skill_installation_service.dart';
import 'package:stars/domain/models/models.dart';

final class SkillInstallerTool implements ExecutableTool {
  SkillInstallerTool({required SkillInstallationGateway installation})
    : _installation = installation;

  final SkillInstallationGateway _installation;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: installSkillToolName,
    title: 'Install Skill',
    description:
        'Install one Stars Skill from GitHub, an HTTPS ZIP URL, a local ZIP, '
        'or a local directory through the validated Skill installation pipeline.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'source_type': {
          'type': 'string',
          'enum': ['github', 'zip_url', 'local_zip', 'local_directory'],
        },
        'source': {'type': 'string', 'minLength': 1, 'maxLength': 4096},
        'ref': {'type': 'string', 'maxLength': 255},
        'subdirectory': {'type': 'string', 'maxLength': 1024},
        'archive_sha256': {'type': 'string', 'pattern': '^[A-Fa-f0-9]{64}\$'},
      },
      'required': ['source_type', 'source'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'skill_id': {'type': 'string'},
        'name': {'type': 'string'},
        'version': {'type': 'string'},
        'description': {'type': 'string'},
        'source_uri': {'type': 'string'},
        'content_digest': {'type': 'string'},
        'trust_state': {'type': 'string'},
        'signature_status': {'type': 'string'},
        'validation_status': {'type': 'string'},
      },
      'required': [
        'skill_id',
        'name',
        'version',
        'description',
        'source_uri',
        'content_digest',
        'trust_state',
        'signature_status',
        'validation_status',
      ],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.destructive,
    capabilities: const {
      ToolCapability.localRead,
      ToolCapability.localWrite,
      ToolCapability.network,
      ToolCapability.externalRead,
    },
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final sourceType = switch (call.arguments['source_type']) {
      'github' => SkillInstallSourceType.github,
      'zip_url' => SkillInstallSourceType.zipUrl,
      'local_zip' => SkillInstallSourceType.localZip,
      'local_directory' => SkillInstallSourceType.localDirectory,
      _ => null,
    };
    if (sourceType == null) {
      return _error(call, 'Skill 安装来源类型无效。', 'invalid_skill_source');
    }
    try {
      final source = _requiredString(
        call.arguments['source'],
        field: 'source',
        maximumLength: 4096,
      );
      final ref = _optionalString(
        call.arguments['ref'],
        field: 'ref',
        maximumLength: 255,
      );
      final subdirectory = _optionalString(
        call.arguments['subdirectory'],
        field: 'subdirectory',
        maximumLength: 1024,
      );
      final archiveSha256 = _optionalString(
        call.arguments['archive_sha256'],
        field: 'archive_sha256',
        maximumLength: 64,
      );
      final installed = await _installation.install(
        SkillInstallationRequest(
          sourceType: sourceType,
          source: source,
          ref: ref,
          subdirectory: subdirectory,
          archiveSha256: archiveSha256,
        ),
        cancellationToken,
      );
      final structured = <String, Object?>{
        'skill_id': installed.id,
        'name': installed.name,
        'version': installed.version,
        'description': installed.description,
        'source_uri': installed.sourceUri,
        'content_digest': installed.contentDigest,
        'trust_state': installed.trustState.name,
        'signature_status': installed.signatureStatus.name,
        'validation_status': installed.validationStatus.name,
      };
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content:
            'Installed Skill ${installed.name} ${installed.version} '
            '(${installed.id}).',
        structuredContent: structured,
      );
    } on AgentRunCancelledException {
      rethrow;
    } on ArgumentError {
      return _error(call, 'Skill 安装参数无效。', 'invalid_skill_source');
    } on SkillInstallException catch (error) {
      return _error(call, error.message, 'skill_install_rejected');
    } on Object {
      return _error(call, 'Skill 安装失败。', 'skill_install_failed');
    }
  }

  String _requiredString(
    Object? value, {
    required String field,
    required int maximumLength,
  }) {
    if (value is! String ||
        value.trim().isEmpty ||
        value.length > maximumLength ||
        value.contains('\u0000')) {
      throw ArgumentError.value(value, field);
    }
    return value.trim();
  }

  String _optionalString(
    Object? value, {
    required String field,
    required int maximumLength,
  }) {
    if (value == null) return '';
    if (value is! String ||
        value.length > maximumLength ||
        value.contains('\u0000')) {
      throw ArgumentError.value(value, field);
    }
    return value.trim();
  }

  ToolResult _error(ToolCallRequest call, String message, String code) =>
      ToolResult(
        callId: call.callId,
        name: call.name,
        content: message,
        isError: true,
        errorCode: code,
      );
}
