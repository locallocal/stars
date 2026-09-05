import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/verification_tool_discovery.dart';

void main() {
  group('VerificationToolDiscovery', () {
    test('selects a minimal safe set only from the application allowlist', () {
      final firstRead = _EvidenceTool.observation('a_file_read');
      final duplicateRead = _EvidenceTool.observation('b_file_read');
      final calculation = _EvidenceTool.calculation('calculate');
      final processRead = _EvidenceTool.observation(
        'process_read',
        capabilities: const {ToolCapability.localRead, ToolCapability.process},
      );
      final write = _EvidenceTool.action('write_file');
      final unrelatedMcpInventory = _PlainTool(
        'mcp.inventory.unlisted',
        source: ToolSource.mcp,
        capabilities: const {
          ToolCapability.network,
          ToolCapability.externalRead,
        },
      );
      final registry = StaticToolRegistry([
        firstRead,
        duplicateRead,
        calculation,
        processRead,
        write,
        unrelatedMcpInventory,
      ]);

      final result = const VerificationToolDiscovery().discover(
        registry: registry,
        candidateToolNames: {
          firstRead.definition.name,
          duplicateRead.definition.name,
          calculation.definition.name,
          processRead.definition.name,
          write.definition.name,
        },
      );

      expect(result.toolNames, {'a_file_read', 'calculate'});
      expect(result.unavailableReason, isEmpty);
      expect(result.toolNames, isNot(contains('mcp.inventory.unlisted')));
    });

    test('does not duplicate a verifier already requested by a Skill', () {
      final read = _EvidenceTool.observation('file_read');
      final calculation = _EvidenceTool.calculation('calculate');

      final result = const VerificationToolDiscovery().discover(
        registry: StaticToolRegistry([read, calculation]),
        candidateToolNames: {'file_read', 'calculate'},
        requestedToolNames: const {'file_read'},
      );

      expect(result.toolNames, {'calculate'});
      expect(result.unavailableReason, isEmpty);
    });

    test('reports unavailable when no allowlisted Tool is eligible', () {
      final result = const VerificationToolDiscovery().discover(
        registry: StaticToolRegistry([_PlainTool('plain_read')]),
        candidateToolNames: const {'plain_read', 'missing_read'},
      );

      expect(result.toolNames, isEmpty);
      expect(result.unavailableReason, 'verification_tool_unavailable');
    });
  });
}

final class _EvidenceTool implements ExecutableTool {
  _EvidenceTool._(this.definition);

  factory _EvidenceTool.observation(
    String name, {
    Set<ToolCapability> capabilities = const {ToolCapability.localRead},
  }) => _EvidenceTool._(
    ToolDefinition(
      name: name,
      description: 'Observe a local file.',
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
    ),
  );

  factory _EvidenceTool.calculation(String name) => _EvidenceTool._(
    ToolDefinition(
      name: name,
      description: 'Calculate a value.',
      inputSchema: const {'type': 'object'},
      outputSchema: _evidenceSchema(),
      source: ToolSource.builtIn,
      riskLevel: ToolRiskLevel.readOnly,
      capabilities: const {ToolCapability.compute},
      toolVersion: '1.0.0',
      evidenceCapabilities: const {EvidenceKind.calculation},
      evidenceScope: ToolEvidenceScopeRule(
        subject: 'calculation:value',
        fixedScope: const {'operation': 'test'},
      ),
    ),
  );

  factory _EvidenceTool.action(String name) => _EvidenceTool._(
    ToolDefinition(
      name: name,
      description: 'Write a file.',
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
    ),
  );

  @override
  final ToolDefinition definition;

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async => ToolResult(callId: call.callId, name: call.name, content: 'ok');
}

final class _PlainTool implements ExecutableTool {
  _PlainTool(
    String name, {
    ToolSource source = ToolSource.builtIn,
    Set<ToolCapability> capabilities = const {ToolCapability.localRead},
  }) : definition = ToolDefinition(
         name: name,
         description: 'Plain read.',
         inputSchema: const {'type': 'object'},
         source: source,
         riskLevel: ToolRiskLevel.readOnly,
         capabilities: capabilities,
       );

  @override
  final ToolDefinition definition;

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async => ToolResult(callId: call.callId, name: call.name, content: 'ok');
}

Map<String, Object?> _evidenceSchema() => {
  'type': 'object',
  'properties': <String, Object?>{
    'ok': {'type': 'boolean'},
    ...toolEvidenceOutputSchemaProperties,
  },
  'required': ['ok', ...toolEvidenceOutputRequiredFields],
  'additionalProperties': false,
};
