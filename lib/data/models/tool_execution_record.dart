import 'package:stars/domain/models/models.dart';

/// SQLite representation of a redacted [ToolExecutionRecord].
final class ToolExecutionDbRecord {
  const ToolExecutionDbRecord(this.values);

  factory ToolExecutionDbRecord.fromDomain(ToolExecutionRecord record) {
    final invocationId =
        record.invocationId.isEmpty ? record.executionId : record.invocationId;
    final attemptId =
        record.attemptId.isEmpty ? record.executionId : record.attemptId;
    final providerCallId =
        record.providerCallId.isEmpty ? record.callId : record.providerCallId;
    return ToolExecutionDbRecord({
      'execution_id': record.executionId,
      'invocation_id': invocationId,
      'attempt_id': attemptId,
      'provider_call_id': providerCallId,
      'run_id': record.runId,
      'turn_id': record.turnId,
      'message_id': record.messageId,
      'chat_id': record.chatId,
      'bot_id': record.botId,
      'call_id': record.callId,
      'tool_name': record.name,
      'tool_title': record.title,
      'mcp_server_name': record.mcpServerName,
      'source': record.source.name,
      'risk_level': record.riskLevel.name,
      'status': record.status.name,
      'detail': record.detail,
      'arguments_summary': record.argumentsSummary,
      'result_summary': record.resultSummary,
      'approval_status': record.approvalStatus,
      'error_code': record.errorCode,
      'duration_ms': record.durationMs,
      'started_at': record.startedAt.millisecondsSinceEpoch,
      'completed_at': record.completedAt?.millisecondsSinceEpoch,
      'updated_at': record.updatedAt.millisecondsSinceEpoch,
    });
  }

  final Map<String, Object?> values;

  ToolExecutionRecord toDomain() {
    final completedAt = _nullableInteger('completed_at');
    return ToolExecutionRecord(
      executionId: _text('execution_id'),
      invocationId: _text('invocation_id'),
      attemptId: _text('attempt_id'),
      providerCallId: _text('provider_call_id'),
      runId: _text('run_id'),
      turnId: _text('turn_id'),
      messageId: _text('message_id'),
      chatId: _text('chat_id'),
      botId: _text('bot_id'),
      callId: _text('call_id'),
      name: _text('tool_name'),
      title: _text('tool_title'),
      mcpServerName: _text('mcp_server_name'),
      source: _enumValue(ToolSource.values, _text('source'), 'source'),
      riskLevel: _enumValue(
        ToolRiskLevel.values,
        _text('risk_level'),
        'risk_level',
      ),
      status: _enumValue(
        ToolInvocationStatus.values,
        _text('status'),
        'status',
      ),
      detail: _text('detail'),
      argumentsSummary: _text('arguments_summary'),
      resultSummary: _text('result_summary'),
      approvalStatus: _text('approval_status'),
      errorCode: _text('error_code'),
      durationMs: _nullableInteger('duration_ms'),
      startedAt: DateTime.fromMillisecondsSinceEpoch(_integer('started_at')),
      completedAt:
          completedAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(completedAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(_integer('updated_at')),
    );
  }

  String _text(String key) {
    final value = values[key];
    if (value is String) return value;
    throw FormatException(
      'Tool execution record field "$key" must be a string.',
    );
  }

  int _integer(String key) {
    final value = values[key];
    if (value is int) return value;
    throw FormatException(
      'Tool execution record field "$key" must be an integer.',
    );
  }

  int? _nullableInteger(String key) {
    final value = values[key];
    if (value == null || value is int) return value as int?;
    throw FormatException(
      'Tool execution record field "$key" must be an integer or null.',
    );
  }
}

T _enumValue<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException(
    'Tool execution record field "$field" has an unknown value.',
  );
}
