import 'package:stars/data/services/local_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/tool_evidence_record.dart';
import 'package:stars/data/repositories/sqlite_agent_run_recovery_repository.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_execution_repository.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/use_cases/recover_agent_runs.dart';

import '../../support/task_runner_harness.dart';

void main() {
  late TaskRunnerHarness h;
  setUp(() async {
    h = TaskRunnerHarness();
    await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
  });
  tearDown(() => h.close());

  RecoverAgentRuns oldRecovery() {
    final messages = SqliteMessageRepository(localDatabase: h.db.local);
    return RecoverAgentRuns(
      recoveryRepository: SqliteAgentRunRecoveryRepository(
        localDatabase: h.db.local,
      ),
      messageRepository: messages,
      groundedMessageRepository: messages,
      evidenceRepository: SqliteToolEvidenceRepository(
        localDatabase: h.db.local,
      ),
      executionRepository: SqliteToolExecutionRepository(
        localDatabase: h.db.local,
      ),
    );
  }

  test(
    'legacy recovery neither interrupts task attempts nor appends a late interruption',
    () async {
      h.models.tool();
      await h.db.failWrite(
        'conversation_task_events',
        when: "NEW.kind = 'toolSucceeded'",
      );
      await expectLater(h.run(), throwsA(isA<Exception>()));
      await h.db.clearFailure();
      final record = (await h.snapshot).attempts.single;
      final event = ToolInvocationEvent(
        eventId: ToolInvocationEvent.eventIdForAttempt(record.attemptId, 1),
        runId: record.runId,
        turnId: record.turnId,
        chatId: record.chatId,
        messageId: record.messageId,
        invocationId: record.invocationId,
        attemptId: record.attemptId,
        providerCallId: record.providerCallId,
        toolName: h.tool.definition.name,
        toolVersion: h.tool.definition.toolVersion,
        source: record.source,
        status: ToolInvocationStatus.running,
        sequence: 1,
        occurredAt: h.clock.now(),
      );
      await h.db.database.insert(
        'tool_invocation_events',
        ToolInvocationEventDbRecord.fromDomain(event).values,
      );
      final before = await h.db.facts();
      final recovery = SqliteAgentRunRecoveryRepository(
        localDatabase: h.db.local,
      );
      expect(await recovery.loadLatestNonTerminalInvocations(), isEmpty);
      await recovery.appendInterruptedInvocation(
        event,
        occurredAt: h.clock.now(),
      );
      final report = await oldRecovery()(recoveredAt: h.clock.now());
      expect(report.interruptedInvocations, 0);
      expect(report.failedAnswers, 0);
      expect(await h.db.facts(), before);
      expect(await h.db.database.query('tool_invocation_events'), hasLength(1));
    },
  );

  test(
    'legacy orphan-answer recovery excludes committed task evidence and task result checkpoints',
    () async {
      h.tool = RunnerTool(
        definition: ToolDefinition(
          name: 'read_file',
          description: 'Read report',
          source: ToolSource.builtIn,
          riskLevel: ToolRiskLevel.readOnly,
          inputSchema: {'type': 'object'},
          outputSchema: {
            'type': 'object',
            'properties': toolEvidenceOutputSchemaProperties,
            'required': toolEvidenceOutputRequiredFields,
            'additionalProperties': false,
          },
          toolVersion: '1',
          capabilities: {ToolCapability.localRead},
          evidenceCapabilities: {EvidenceKind.observation},
          evidenceScope: ToolEvidenceScopeRule(
            subject: 'report',
            fixedScope: {'report': '1'},
          ),
        ),
      );
      h.tool.onStart =
          (call) async => ToolCompleted(
            ToolResult(
              callId: call.callId,
              name: call.name,
              content: 'Observed report',
              structuredContent: toolEvidenceOutputMetadata(
                evidenceKind: EvidenceKind.observation,
                subject: 'report',
                scope: {'report': '1'},
                structuredFacts: [
                  StructuredFact(name: 'report.count', value: 42),
                ],
                observedAt: h.clock.now(),
              ),
              evidenceKind: EvidenceKind.observation,
              subject: 'report',
              scope: {'report': '1'},
              structuredFacts: [
                StructuredFact(name: 'report.count', value: 42),
              ],
              observedAt: h.clock.now(),
            ),
          );
      h.models.tool();
      await h.run();
      expect((await h.snapshot).evidence, hasLength(1));
      final snapshot = await h.snapshot;
      await h.db.local.upsertAgentRunAnswerCheckpoint({
        'run_id': snapshot.checkpoint!.segmentId,
        'chat_id': snapshot.task.chatId,
        'message_id': '${snapshot.task.taskId}:result',
        'terminal_message_json': '{}',
        'created_at': h.clock.now().millisecondsSinceEpoch,
      });
      final before = await h.db.facts();
      final recovery = SqliteAgentRunRecoveryRepository(
        localDatabase: h.db.local,
      );
      expect(await recovery.loadPendingAnswers(), isEmpty);
      expect(await recovery.loadEvidenceAwaitingAnswer(), isEmpty);
      final report = await oldRecovery()(recoveredAt: h.clock.now());
      expect(report.recoveredAnswers, 0);
      expect(report.failedAnswers, 0);
      expect(await h.db.facts(), before);
    },
  );
}
