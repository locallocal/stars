import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/repositories/tool_execution_repository.dart';
import 'package:stars/domain/use_cases/persist_tool_invocation.dart';

void main() {
  test(
    'commits the immutable failure evidence before its projection',
    () async {
      final order = <String>[];
      final evidenceRepository = _FaultInjectingEvidenceRepository(
        order: order,
      );
      final executionRepository = _RecordingExecutionRepository(order: order);
      final useCase = PersistToolInvocation(
        evidenceRepository: evidenceRepository,
        executionRepository: executionRepository,
      );

      await useCase(_record(status: ToolInvocationStatus.failed));

      expect(order, ['ledger', 'projection']);
      expect(evidenceRepository.events.single.sequence, 2);
      expect(
        evidenceRepository.events.single.status,
        ToolInvocationStatus.failed,
      );
      final evidence = evidenceRepository.evidence.single;
      expect(evidence.evidenceKind, EvidenceKind.executionFailure);
      expect(evidence.errorCode, 'tool_execution_failed');
      expect(evidence.argumentsDigest, hasLength(64));
      expect(evidence.resultDigest, hasLength(64));
      expect(executionRepository.records, hasLength(1));
    },
  );

  test('ledger write failure never advances the mutable projection', () async {
    final order = <String>[];
    final evidenceRepository = _FaultInjectingEvidenceRepository(
      order: order,
      failure: StateError('ledger unavailable'),
    );
    final executionRepository = _RecordingExecutionRepository(order: order);
    final useCase = PersistToolInvocation(
      evidenceRepository: evidenceRepository,
      executionRepository: executionRepository,
    );

    await expectLater(
      useCase(_record(status: ToolInvocationStatus.succeeded)),
      throwsStateError,
    );

    expect(order, ['ledger']);
    expect(executionRepository.records, isEmpty);
  });
}

ToolExecutionRecord _record({required ToolInvocationStatus status}) {
  final timestamp = DateTime.utc(2026, 9, 4, 10);
  return ToolExecutionRecord(
    executionId: 'run-1:invocation:1:attempt:1',
    invocationId: 'run-1:invocation:1',
    attemptId: 'run-1:invocation:1:attempt:1',
    providerCallId: 'provider-call-1',
    runId: 'run-1',
    turnId: 'turn-1',
    messageId: 'message-1',
    chatId: 'chat-1',
    botId: 'bot-1',
    callId: 'provider-call-1',
    name: 'mcp.resources.read',
    source: ToolSource.mcp,
    riskLevel: ToolRiskLevel.readOnly,
    status: status,
    argumentsSummary: '{"token":"[redacted]"}',
    resultSummary: status == ToolInvocationStatus.failed ? 'failed' : 'done',
    startedAt: timestamp,
    completedAt: timestamp,
    updatedAt: timestamp,
    eventSequence: 2,
  );
}

final class _FaultInjectingEvidenceRepository
    implements ToolEvidenceRepository {
  _FaultInjectingEvidenceRepository({required this.order, this.failure});

  final List<String> order;
  final Object? failure;
  final List<ToolInvocationEvent> events = [];
  final List<ToolEvidenceRecord> evidence = [];

  @override
  Future<void> commitRun({
    required String runId,
    required String chatId,
    required List<ToolInvocationEvent> invocationEvents,
    required List<ToolEvidenceRecord> evidenceRecords,
  }) async {
    order.add('ledger');
    final error = failure;
    if (error != null) throw error;
    events.addAll(invocationEvents);
    evidence.addAll(evidenceRecords);
  }

  @override
  Future<ToolEvidenceRecord?> getById(String evidenceId) async => null;

  @override
  Future<List<ToolEvidenceRecord>> getForMessage(String messageId) async => [];

  @override
  Future<List<ToolInvocationEvent>> getInvocationEventsForRun(
    String runId,
  ) async => [];

  @override
  Future<bool> verifyDigest(String evidenceId) async => false;
}

final class _RecordingExecutionRepository implements ToolExecutionRepository {
  _RecordingExecutionRepository({required this.order});

  final List<String> order;
  final List<ToolExecutionRecord> records = [];

  @override
  Future<void> upsert(ToolExecutionRecord record) async {
    order.add('projection');
    records.add(record);
  }

  @override
  Future<List<ToolExecutionRecord>> getForChat(
    String chatId, {
    int limit = 100,
  }) async => [];

  @override
  Future<List<ToolExecutionRecord>> getForRun(String runId) async => [];
}
