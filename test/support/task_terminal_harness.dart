import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/use_cases/finalize_conversation_task.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_terminal.dart';

import 'task_runner_harness.dart';
export 'task_runner_harness.dart';

final class TaskTerminalHarness {
  final runner = TaskRunnerHarness();
  int identities = 0;
  Future<void> open({
    bool strict = true,
    bool reliability = true,
    bool showStatus = true,
    bool write = false,
    String toolName = 'read_file',
  }) async {
    final original = taskAcceptance(limits: TaskSegmentLimits(maxToolCalls: 1));
    await runner.open(
      acceptance: TaskAcceptanceSnapshot(
        providerId: original.providerId,
        modelId: original.modelId,
        configurationDigest: original.configurationDigest,
        language: original.language,
        context: original.context,
        allowedToolNames: {...original.allowedToolNames, toolName},
        verification: VerificationPolicySnapshot(
          reliabilityEnabled: reliability,
          strictGroundingEnabled: strict,
          showVerificationStatus: showStatus,
        ),
        segmentLimits: original.segmentLimits,
      ),
    );
    configureTool(write: write, name: toolName);
  }

  void configureTool({bool write = false, String name = 'read_file'}) {
    final kind = write ? EvidenceKind.actionReceipt : EvidenceKind.observation;
    runner.tool = RunnerTool(
      definition: ToolDefinition(
        name: name,
        description: 'Report results',
        source: ToolSource.builtIn,
        riskLevel: write ? ToolRiskLevel.write : ToolRiskLevel.readOnly,
        inputSchema: {'type': 'object'},
        outputSchema: {
          'type': 'object',
          'properties': toolEvidenceOutputSchemaProperties,
          'required': toolEvidenceOutputRequiredFields,
          'additionalProperties': false,
        },
        capabilities: {
          write ? ToolCapability.localWrite : ToolCapability.localRead,
        },
        toolVersion: '1',
        evidenceCapabilities: {kind},
        evidenceScope: ToolEvidenceScopeRule(
          subject: 'report',
          fixedScope: {'report': 'report-1'},
        ),
        defaultEvidenceValidity: const Duration(hours: 1),
        requiresReadAfterWrite: write,
      ),
    );
    runner.tool.onStart = (call) async {
      final facts = [
        StructuredFact(
          name: write ? 'action.completed' : 'report.count',
          value: write ? true : 42,
        ),
        if (write) StructuredFact(name: 'report.count', value: 42),
      ];
      return ToolCompleted(
        ToolResult(
          callId: call.callId,
          name: call.name,
          content: 'Report processed.',
          structuredContent: toolEvidenceOutputMetadata(
            evidenceKind: kind,
            subject: 'report',
            scope: {'report': 'report-1'},
            structuredFacts: facts,
            observedAt: runner.clock.now(),
          ),
          evidenceKind: kind,
          subject: 'report',
          scope: {'report': 'report-1'},
          structuredFacts: facts,
          observedAt: runner.clock.now(),
        ),
      );
    };
  }

  Future<void> observe({String call = 'read-1'}) async {
    runner.models.tool(
      id: call,
      name: runner.tool.definition.name,
      arguments: {'page': identities++},
    );
    await runner.run();
  }

  Future<void> candidate({bool unsupported = false, bool omit = false}) async {
    final snapshot = await runner.snapshot;
    runner.models.completeStep();
    runner.models.candidate(
      GroundedAnswerCandidate(
        claims: [
          if (!omit)
            for (final evidence in snapshot.evidence)
              AnswerClaim(
                claimId:
                    '${evidence.attemptId}:${evidence.evidenceKind == EvidenceKind.actionReceipt ? 'action' : 'fact'}',
                text:
                    evidence.evidenceKind == EvidenceKind.actionReceipt
                        ? '写操作已完成。'
                        : '报告共 42 条。',
                kind:
                    evidence.evidenceKind == EvidenceKind.actionReceipt
                        ? ClaimKind.completedAction
                        : ClaimKind.currentFact,
                evidenceIds: [evidence.evidenceId],
              ),
          if (unsupported)
            AnswerClaim(
              claimId: 'unsupported',
              text: '未经证实的完成声明',
              kind: ClaimKind.completedAction,
            ),
        ],
        nonFactualText: omit || snapshot.evidence.isEmpty ? '已整理。' : '',
      ),
    );
    await runner.run();
  }

  Future<void> fail() async {
    runner.models.tool(name: 'not_authorized');
    await runner.run();
  }

  Future<void> cancel() async {
    final task = await runner.db.task;
    committed(
      await runner.db.repository.requestCancellation(
        taskId: task.taskId,
        expectedRevision: task.revision,
        source: TaskCancellationSource.user,
        requestedAt: runner.clock.now(),
      ),
    );
    await runner.run();
  }

  ToolEvidenceRepository get evidence =>
      SqliteToolEvidenceRepository(localDatabase: runner.db.local);
  FinalizeConversationTask finalizer({
    TaskTerminalPolisher? polish,
    ToolEvidenceRepository? ledger,
  }) => FinalizeConversationTask(
    repository: runner.db.repository,
    evidenceRepository: ledger ?? evidence,
    ownerId: 'terminal-worker',
    newId: () => 'terminal-lease-${identities++}',
    clock: runner.clock,
    tools: [runner.tool.definition],
    polisher: (_) => polish,
  );
  Future<List<Message>> messages() async {
    final repository = SqliteMessageRepository(localDatabase: runner.db.local);
    try {
      return await repository.getMessages('chat-1');
    } finally {
      await repository.dispose();
    }
  }

  Future<Message> result() async => (await messages()).singleWhere(
    (m) => m.taskMessageKind == TaskMessageKind.result,
  );
  Future<void> close() => runner.close();
}
