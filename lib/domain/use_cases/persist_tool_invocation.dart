import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/skill_ecosystem_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/repositories/tool_execution_repository.dart';

/// Persists the immutable ledger before updating its current-state projection.
final class PersistToolInvocation {
  const PersistToolInvocation({
    required ToolEvidenceRepository evidenceRepository,
    required ToolExecutionRepository executionRepository,
    SkillEcosystemRepository? complianceRepository,
  }) : _evidenceRepository = evidenceRepository,
       _executionRepository = executionRepository,
       _complianceRepository = complianceRepository;

  final ToolEvidenceRepository _evidenceRepository;
  final ToolExecutionRepository _executionRepository;
  final SkillEcosystemRepository? _complianceRepository;

  Future<void> call(ToolExecutionRecord record) async {
    if (record.eventSequence < 1) {
      throw ArgumentError.value(
        record.eventSequence,
        'eventSequence',
        'Tool ledger events require a positive sequence.',
      );
    }
    final errorCode = _safeErrorCode(record);
    final event = ToolInvocationEvent(
      eventId: ToolInvocationEvent.eventIdForAttempt(
        record.attemptId,
        record.eventSequence,
      ),
      runId: record.runId,
      turnId: record.turnId,
      chatId: record.chatId,
      messageId: record.messageId,
      invocationId: record.invocationId,
      attemptId: record.attemptId,
      providerCallId: record.providerCallId,
      toolName: record.name,
      toolVersion: record.evidenceCandidate?.toolVersion ?? '',
      source: record.source,
      status: record.status,
      sequence: record.eventSequence,
      occurredAt: record.updatedAt,
      errorCode: errorCode,
    );
    final evidence =
        _businessEvidence(record) ??
        _failureEvidence(record, errorCode: errorCode);

    await _evidenceRepository.commitRun(
      runId: record.runId,
      chatId: record.chatId,
      invocationEvents: [event],
      evidenceRecords: [if (evidence != null) evidence],
    );
    await _executionRepository.upsert(record);
    final complianceRepository = _complianceRepository;
    if (complianceRepository != null) {
      await complianceRepository.appendComplianceEvent(
        _complianceEvent(record, event),
      );
    }
  }
}

ToolEvidenceRecord? _businessEvidence(ToolExecutionRecord record) {
  final candidate = record.evidenceCandidate;
  if (record.status != ToolInvocationStatus.succeeded || candidate == null) {
    return null;
  }
  return ToolEvidenceRecord(
    evidenceId: ToolEvidenceRecord.evidenceIdForAttempt(record.attemptId),
    runId: record.runId,
    turnId: record.turnId,
    chatId: record.chatId,
    messageId: record.messageId,
    invocationId: record.invocationId,
    attemptId: record.attemptId,
    providerCallId: record.providerCallId,
    toolName: record.name,
    toolVersion: candidate.toolVersion,
    source: record.source,
    capabilities: candidate.capabilities,
    terminalStatus: record.status,
    evidenceKind: candidate.evidenceKind,
    subject: candidate.subject,
    scope: candidate.scope,
    resultSummary:
        '${record.name} produced '
        '${candidate.structuredFacts.length} structured fact(s).',
    argumentsDigest: candidate.argumentsDigest,
    resultDigest: candidate.resultDigest,
    structuredFacts: candidate.structuredFacts,
    observedAt: candidate.observedAt,
    validUntil: candidate.validUntil,
  );
}

ToolEvidenceRecord? _failureEvidence(
  ToolExecutionRecord record, {
  required String errorCode,
}) {
  if (!const <ToolInvocationStatus>{
    ToolInvocationStatus.failed,
    ToolInvocationStatus.denied,
    ToolInvocationStatus.cancelled,
    ToolInvocationStatus.timedOut,
  }.contains(record.status)) {
    return null;
  }
  final resultEnvelope = jsonEncode(<String, Object?>{
    'status': record.status.name,
    'error_code': errorCode,
    'summary': record.resultSummary,
  });
  return ToolEvidenceRecord(
    evidenceId: ToolEvidenceRecord.evidenceIdForAttempt(record.attemptId),
    runId: record.runId,
    turnId: record.turnId,
    chatId: record.chatId,
    messageId: record.messageId,
    invocationId: record.invocationId,
    attemptId: record.attemptId,
    providerCallId: record.providerCallId,
    toolName: record.name,
    toolVersion: 'unversioned',
    source: record.source,
    terminalStatus: record.status,
    evidenceKind: EvidenceKind.executionFailure,
    resultSummary: 'Tool attempt ended with $errorCode.',
    argumentsDigest: _digest(record.argumentsSummary),
    resultDigest: _digest(resultEnvelope),
    observedAt: record.updatedAt,
    schemaValid: false,
    errorCode: errorCode,
  );
}

SkillComplianceEvent _complianceEvent(
  ToolExecutionRecord record,
  ToolInvocationEvent event,
) => SkillComplianceEvent(
  id: 'tool:${event.eventId}',
  type: SkillComplianceEventType.toolInvoked,
  decision: record.approvalStatus,
  reason: event.errorCode,
  metadata: <String, Object?>{
    'executionId': record.executionId,
    'runId': record.runId,
    'chatId': record.chatId,
    'botId': record.botId,
    'callId': record.callId,
    'tool': record.name,
    'source': record.source.name,
    'riskLevel': record.riskLevel.name,
    'status': record.status.name,
    'argumentsSummary': record.argumentsSummary,
    'resultSummary': record.resultSummary,
    'durationMs': record.durationMs,
  },
  timestamp: record.updatedAt,
);

String _safeErrorCode(ToolExecutionRecord record) {
  final candidate = record.errorCode;
  if (RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(candidate)) return candidate;
  return switch (record.status) {
    ToolInvocationStatus.failed => 'tool_execution_failed',
    ToolInvocationStatus.denied => 'tool_execution_denied',
    ToolInvocationStatus.cancelled => 'tool_execution_cancelled',
    ToolInvocationStatus.timedOut => 'tool_execution_timed_out',
    ToolInvocationStatus.interrupted => 'agent_run_interrupted',
    _ => '',
  };
}

String _digest(String value) => sha256.convert(utf8.encode(value)).toString();
