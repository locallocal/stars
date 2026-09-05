import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/post_write_verification_policy.dart';

void main() {
  group('PostWriteVerificationPolicy', () {
    test(
      'pairs an already-exposed local observation with exact postconditions',
      () {
        final write = _writeDefinition(
          source: ToolSource.builtIn,
          capabilities: const {ToolCapability.localWrite},
        );
        final read = _readDefinition(
          source: ToolSource.builtIn,
          capabilities: const {ToolCapability.localRead},
        );

        final plan = const PostWriteVerificationPolicy().plan(
          invocation: _successfulWrite(write),
          writeTool: write,
          exposedTools: [write, read],
        );

        expect(plan, isNotNull);
        expect(plan!.hasPairedRead, isTrue);
        expect(plan.verificationToolName, read.name);
        expect(plan.actionRequirement.claimKind, ClaimKind.completedAction);
        expect(plan.actionRequirement.requiredFactValues, {
          'action.completed': true,
        });
        expect(plan.stateRequirement.claimKind, ClaimKind.currentFact);
        expect(plan.stateRequirement.toolName, read.name);
        expect(plan.stateRequirement.subject, 'resource:item');
        expect(plan.stateRequirement.scope, {'resource_id': 'item-1'});
        expect(plan.stateRequirement.requiredFactValues, {
          'resource.version': 2,
          'resource.digest': 'digest-2',
        });
      },
    );

    test('does not pair MCP reads from another server or subject', () {
      final write = _writeDefinition(
        source: ToolSource.mcp,
        capabilities: const {ToolCapability.externalWrite},
        serverName: 'server-a',
      );
      final wrongServer = _readDefinition(
        source: ToolSource.mcp,
        capabilities: const {
          ToolCapability.network,
          ToolCapability.externalRead,
        },
        serverName: 'server-b',
      );
      final wrongSubject = _readDefinition(
        name: 'resource_other_read',
        source: ToolSource.mcp,
        capabilities: const {
          ToolCapability.network,
          ToolCapability.externalRead,
        },
        serverName: 'server-a',
        subject: 'resource:other',
      );

      final plan = const PostWriteVerificationPolicy().plan(
        invocation: _successfulWrite(write),
        writeTool: write,
        exposedTools: [write, wrongServer, wrongSubject],
      );

      expect(plan, isNotNull);
      expect(plan!.hasPairedRead, isFalse);
      expect(plan.stateRequirement.verificationAvailable, isFalse);
      expect(plan.stateRequirement.toolName, isEmpty);
      expect(plan.stateRequirement.requiredCapabilities, {
        ToolCapability.externalRead,
      });
    });

    test('keeps a shell-like write unpaired and never treats it as state', () {
      final shell = _writeDefinition(
        name: 'run_shell_write',
        source: ToolSource.builtIn,
        capabilities: const {ToolCapability.process, ToolCapability.localWrite},
      );

      final plan = const PostWriteVerificationPolicy().plan(
        invocation: _successfulWrite(shell),
        writeTool: shell,
        exposedTools: [shell],
      );

      expect(plan, isNotNull);
      expect(plan!.hasPairedRead, isFalse);
      expect(plan.actionRequirement.allowedEvidenceKinds, {
        EvidenceKind.actionReceipt,
      });
      expect(plan.stateRequirement.allowedEvidenceKinds, {
        EvidenceKind.observation,
      });
    });

    test('ignores Tools that do not require a persisted post-write read', () {
      final write = _writeDefinition(
        source: ToolSource.builtIn,
        capabilities: const {ToolCapability.localWrite},
        requiresReadAfterWrite: false,
      );

      final plan = const PostWriteVerificationPolicy().plan(
        invocation: _successfulWrite(write),
        writeTool: write,
        exposedTools: [write],
      );

      expect(plan, isNull);
    });

    test(
      'allocates distinct application claim IDs when names are reserved',
      () {
        final write = _writeDefinition(
          source: ToolSource.builtIn,
          capabilities: const {ToolCapability.localWrite},
        );

        final plan = const PostWriteVerificationPolicy().plan(
          invocation: _successfulWrite(write),
          writeTool: write,
          exposedTools: [write],
          reservedClaimIds: const {
            'run-1:invocation:1:attempt:1:action',
            'run-1:invocation:1:attempt:1:state',
          },
        );

        expect(
          plan!.actionRequirement.claimId,
          'run-1:invocation:1:attempt:1:action:2',
        );
        expect(
          plan.stateRequirement.claimId,
          'run-1:invocation:1:attempt:1:state:2',
        );
      },
    );

    test(
      'requires affirmative completion even when the receipt says false',
      () {
        final write = _writeDefinition(
          source: ToolSource.builtIn,
          capabilities: const {ToolCapability.localWrite},
        );

        final plan = const PostWriteVerificationPolicy().plan(
          invocation: _successfulWrite(write, actionCompleted: false),
          writeTool: write,
          exposedTools: [write],
        );

        expect(plan!.actionRequirement.requiredFactValues, {
          'action.completed': true,
        });
      },
    );
  });
}

ToolDefinition _writeDefinition({
  String name = 'resource_write',
  required ToolSource source,
  required Set<ToolCapability> capabilities,
  String serverName = '',
  bool requiresReadAfterWrite = true,
}) => ToolDefinition(
  name: name,
  mcpServerName: serverName,
  description: 'Write a resource.',
  inputSchema: const {'type': 'object'},
  outputSchema: _evidenceSchema(),
  source: source,
  riskLevel: ToolRiskLevel.write,
  capabilities: capabilities,
  toolVersion: '1.0.0',
  evidenceCapabilities: const {EvidenceKind.actionReceipt},
  evidenceScope: ToolEvidenceScopeRule(
    subject: 'resource:item',
    fixedScope: const {'resource_id': 'item-1'},
  ),
  requiresReadAfterWrite: requiresReadAfterWrite,
);

ToolDefinition _readDefinition({
  String name = 'resource_read',
  required ToolSource source,
  required Set<ToolCapability> capabilities,
  String serverName = '',
  String subject = 'resource:item',
}) => ToolDefinition(
  name: name,
  mcpServerName: serverName,
  description: 'Read a resource.',
  inputSchema: const {'type': 'object'},
  outputSchema: _evidenceSchema(),
  source: source,
  riskLevel: ToolRiskLevel.readOnly,
  capabilities: capabilities,
  toolVersion: '1.0.0',
  evidenceCapabilities: const {EvidenceKind.observation},
  evidenceScope: ToolEvidenceScopeRule(
    subject: subject,
    fixedScope: const {'resource_id': 'item-1'},
  ),
  defaultEvidenceValidity: const Duration(minutes: 5),
);

ToolInvocationRecord _successfulWrite(
  ToolDefinition write, {
  bool actionCompleted = true,
}) => ToolInvocationRecord(
  runId: 'run-1',
  invocationId: 'run-1:invocation:1',
  attemptId: 'run-1:invocation:1:attempt:1',
  providerCallId: 'write-1',
  name: write.name,
  source: write.source,
  riskLevel: write.riskLevel,
  status: ToolInvocationStatus.succeeded,
  startedAt: DateTime.utc(2026, 9, 5, 10),
  completedAt: DateTime.utc(2026, 9, 5, 10, 0, 1),
  evidenceCandidate: ToolEvidenceCandidate(
    toolVersion: write.toolVersion,
    capabilities: write.capabilities,
    evidenceKind: EvidenceKind.actionReceipt,
    subject: 'resource:item',
    scope: const {'resource_id': 'item-1'},
    structuredFacts: [
      StructuredFact(name: 'action.completed', value: actionCompleted),
      StructuredFact(name: 'resource.version', value: 2),
      StructuredFact(name: 'resource.digest', value: 'digest-2'),
    ],
    argumentsDigest: _digestA,
    resultDigest: _digestB,
    observedAt: DateTime.utc(2026, 9, 5, 10),
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

const _digestA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _digestB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
