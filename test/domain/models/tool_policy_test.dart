import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('DefaultToolPolicy verification authorization', () {
    test('keeps discovered reads behind their normal approval gates', () {
      final cases = <ToolDefinition, String>{
        _observationDefinition('verify_file'): 'local_read_requires_approval',
        _observationDefinition(
              'verify_external',
              capabilities: const {ToolCapability.externalRead},
            ):
            'external_read_requires_approval',
        _observationDefinition(
              'verify_network',
              capabilities: const {
                ToolCapability.network,
                ToolCapability.externalRead,
              },
            ):
            'network_requires_approval',
      };

      for (final entry in cases.entries) {
        final definition = entry.key;
        final decision = const DefaultToolPolicy().evaluate(
          definition,
          ToolCallRequest(
            callId: 'read-1',
            name: definition.name,
            arguments: const {},
          ),
          _context(verificationToolNames: {definition.name}),
        );

        expect(decision.outcome, ToolPolicyOutcome.requireApproval);
        expect(decision.reason, entry.value);
      }
    });

    test('rejects write and process Tools in the verification channel', () {
      final definitions = [
        _actionDefinition('verify_write'),
        _observationDefinition(
          'verify_process',
          capabilities: const {
            ToolCapability.localRead,
            ToolCapability.process,
          },
        ),
      ];

      for (final definition in definitions) {
        final decision = const DefaultToolPolicy().evaluate(
          definition,
          ToolCallRequest(
            callId: 'unsafe-1',
            name: definition.name,
            arguments: const {},
          ),
          _context(verificationToolNames: {definition.name}),
        );

        expect(decision.outcome, ToolPolicyOutcome.deny);
        expect(decision.reason, 'verification_tool_not_eligible');
      }
    });

    test('does not expose an unrelated MCP inventory entry', () {
      final definition = ToolDefinition(
        name: 'mcp.server.read',
        description: 'Unrequested MCP read.',
        inputSchema: const {'type': 'object'},
        source: ToolSource.mcp,
        riskLevel: ToolRiskLevel.readOnly,
        capabilities: const {
          ToolCapability.network,
          ToolCapability.externalRead,
        },
      );

      final decision = const DefaultToolPolicy().evaluate(
        definition,
        ToolCallRequest(
          callId: 'mcp-1',
          name: definition.name,
          arguments: const {},
        ),
        _context(),
      );

      expect(decision.outcome, ToolPolicyOutcome.deny);
      expect(decision.reason, 'tool_not_requested_by_active_skill');
    });
  });
}

ToolPolicyContext _context({
  Set<String> requestedToolNames = const {},
  Set<String> verificationToolNames = const {},
}) => ToolPolicyContext(
  runId: 'run-1',
  chatId: 'chat-1',
  botId: 'bot-1',
  requestedToolNames: requestedToolNames,
  verificationToolNames: verificationToolNames,
);

ToolDefinition _observationDefinition(
  String name, {
  Set<ToolCapability> capabilities = const {ToolCapability.localRead},
}) => ToolDefinition(
  name: name,
  description: 'Observe a resource.',
  inputSchema: const {'type': 'object'},
  outputSchema: _evidenceSchema(),
  source: ToolSource.builtIn,
  riskLevel: ToolRiskLevel.readOnly,
  capabilities: capabilities,
  toolVersion: '1.0.0',
  evidenceCapabilities: const {EvidenceKind.observation},
  evidenceScope: ToolEvidenceScopeRule(
    subject: 'file:content',
    fixedScope: const {'path': 'notes.txt'},
  ),
  defaultEvidenceValidity:
      capabilities.any(
            const <ToolCapability>{
              ToolCapability.network,
              ToolCapability.externalRead,
            }.contains,
          )
          ? const Duration(minutes: 5)
          : null,
);

ToolDefinition _actionDefinition(String name) => ToolDefinition(
  name: name,
  description: 'Write a resource.',
  inputSchema: const {'type': 'object'},
  outputSchema: _evidenceSchema(),
  source: ToolSource.builtIn,
  riskLevel: ToolRiskLevel.write,
  capabilities: const {ToolCapability.localWrite},
  toolVersion: '1.0.0',
  evidenceCapabilities: const {EvidenceKind.actionReceipt},
  evidenceScope: ToolEvidenceScopeRule(
    subject: 'file:content',
    fixedScope: const {'path': 'notes.txt'},
  ),
);

Map<String, Object?> _evidenceSchema() => {
  'type': 'object',
  'properties': <String, Object?>{
    'ok': {'type': 'boolean'},
    ...toolEvidenceOutputSchemaProperties,
  },
  'required': ['ok', ...toolEvidenceOutputRequiredFields],
  'additionalProperties': false,
};
