import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/tool.dart';

final class ToolInvocationEventDbRecord {
  ToolInvocationEventDbRecord(Map<String, Object?> values)
    : values = Map<String, Object?>.unmodifiable(values);

  factory ToolInvocationEventDbRecord.fromDomain(ToolInvocationEvent event) {
    return ToolInvocationEventDbRecord(
      _withRecordDigest(<String, Object?>{
        'event_id': event.eventId,
        'run_id': event.runId,
        'turn_id': event.turnId,
        'chat_id': event.chatId,
        'message_id': event.messageId,
        'invocation_id': event.invocationId,
        'attempt_id': event.attemptId,
        'provider_call_id': event.providerCallId,
        'tool_name': event.toolName,
        'tool_version': event.toolVersion,
        'source': event.source.name,
        'status': event.status.name,
        'sequence': event.sequence,
        'occurred_at': event.occurredAt.millisecondsSinceEpoch,
        'error_code': event.errorCode,
      }),
    );
  }

  final Map<String, Object?> values;

  bool get hasValidDigest => _hasValidRecordDigest(values);

  ToolInvocationEvent toDomain() {
    _requireValidRecordDigest(values, 'Tool invocation event');
    return ToolInvocationEvent(
      eventId: _ledgerText(values, 'event_id'),
      runId: _ledgerText(values, 'run_id'),
      turnId: _ledgerText(values, 'turn_id'),
      chatId: _ledgerText(values, 'chat_id'),
      messageId: _ledgerText(values, 'message_id'),
      invocationId: _ledgerText(values, 'invocation_id'),
      attemptId: _ledgerText(values, 'attempt_id'),
      providerCallId: _ledgerText(values, 'provider_call_id'),
      toolName: _ledgerText(values, 'tool_name'),
      toolVersion: _ledgerText(values, 'tool_version'),
      source: _ledgerEnum(
        ToolSource.values,
        _ledgerText(values, 'source'),
        'source',
      ),
      status: _ledgerEnum(
        ToolInvocationStatus.values,
        _ledgerText(values, 'status'),
        'status',
      ),
      sequence: _ledgerInt(values, 'sequence'),
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        _ledgerInt(values, 'occurred_at'),
        isUtc: true,
      ),
      errorCode: _ledgerText(values, 'error_code'),
    );
  }
}

final class ToolEvidenceDbRecord {
  ToolEvidenceDbRecord(Map<String, Object?> values)
    : values = Map<String, Object?>.unmodifiable(values);

  factory ToolEvidenceDbRecord.fromDomain(ToolEvidenceRecord evidence) {
    final capabilityNames =
        evidence.capabilities.map((item) => item.name).toList()..sort();
    final facts = <Object?>[
      for (final fact in evidence.structuredFacts)
        <String, Object?>{
          'name': fact.name,
          'value': fact.value,
          'unit': fact.unit,
          'attributes': fact.attributes,
        },
    ];
    return ToolEvidenceDbRecord(
      _withRecordDigest(<String, Object?>{
        'evidence_id': evidence.evidenceId,
        'run_id': evidence.runId,
        'turn_id': evidence.turnId,
        'chat_id': evidence.chatId,
        'message_id': evidence.messageId,
        'invocation_id': evidence.invocationId,
        'attempt_id': evidence.attemptId,
        'provider_call_id': evidence.providerCallId,
        'tool_name': evidence.toolName,
        'tool_version': evidence.toolVersion,
        'source': evidence.source.name,
        'capabilities_json': _canonicalJson(capabilityNames),
        'terminal_status': evidence.terminalStatus.name,
        'evidence_kind': evidence.evidenceKind.name,
        'subject': evidence.subject,
        'scope_json': _canonicalJson(evidence.scope),
        'result_summary': evidence.resultSummary,
        'arguments_digest': evidence.argumentsDigest,
        'result_digest': evidence.resultDigest,
        'structured_facts_json': _canonicalJson(facts),
        'observed_at': evidence.observedAt.millisecondsSinceEpoch,
        'valid_until': evidence.validUntil?.millisecondsSinceEpoch,
        'payload_ref': evidence.payloadRef,
        'payload_expires_at': evidence.payloadExpiresAt?.millisecondsSinceEpoch,
        'truncated': evidence.truncated ? 1 : 0,
        'schema_valid': evidence.schemaValid ? 1 : 0,
        'persisted': 1,
        'error_code': evidence.errorCode,
      }),
    );
  }

  final Map<String, Object?> values;

  bool get hasValidDigest => _hasValidRecordDigest(values);

  ToolEvidenceRecord toDomain() {
    _requireValidRecordDigest(values, 'Tool evidence record');
    final validUntil = _ledgerNullableInt(values, 'valid_until');
    final payloadExpiresAt = _ledgerNullableInt(values, 'payload_expires_at');
    return ToolEvidenceRecord(
      evidenceId: _ledgerText(values, 'evidence_id'),
      runId: _ledgerText(values, 'run_id'),
      turnId: _ledgerText(values, 'turn_id'),
      chatId: _ledgerText(values, 'chat_id'),
      messageId: _ledgerText(values, 'message_id'),
      invocationId: _ledgerText(values, 'invocation_id'),
      attemptId: _ledgerText(values, 'attempt_id'),
      providerCallId: _ledgerText(values, 'provider_call_id'),
      toolName: _ledgerText(values, 'tool_name'),
      toolVersion: _ledgerText(values, 'tool_version'),
      source: _ledgerEnum(
        ToolSource.values,
        _ledgerText(values, 'source'),
        'source',
      ),
      capabilities: _capabilities(_ledgerText(values, 'capabilities_json')),
      terminalStatus: _ledgerEnum(
        ToolInvocationStatus.values,
        _ledgerText(values, 'terminal_status'),
        'terminal_status',
      ),
      evidenceKind: _ledgerEnum(
        EvidenceKind.values,
        _ledgerText(values, 'evidence_kind'),
        'evidence_kind',
      ),
      subject: _ledgerText(values, 'subject'),
      scope: _jsonObject(_ledgerText(values, 'scope_json'), 'scope_json'),
      resultSummary: _ledgerText(values, 'result_summary'),
      argumentsDigest: _ledgerText(values, 'arguments_digest'),
      resultDigest: _ledgerText(values, 'result_digest'),
      structuredFacts: _structuredFacts(
        _ledgerText(values, 'structured_facts_json'),
      ),
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        _ledgerInt(values, 'observed_at'),
        isUtc: true,
      ),
      validUntil:
          validUntil == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(validUntil, isUtc: true),
      payloadRef: _ledgerText(values, 'payload_ref'),
      payloadExpiresAt:
          payloadExpiresAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                payloadExpiresAt,
                isUtc: true,
              ),
      truncated: _ledgerBool(values, 'truncated'),
      schemaValid: _ledgerBool(values, 'schema_valid'),
      persisted: _ledgerBool(values, 'persisted'),
      errorCode: _ledgerText(values, 'error_code'),
    );
  }
}

Map<String, Object?> _withRecordDigest(Map<String, Object?> values) =>
    <String, Object?>{
      ...values,
      'record_digest': _calculateRecordDigest(values),
    };

bool _hasValidRecordDigest(Map<String, Object?> values) {
  final stored = values['record_digest'];
  if (stored is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(stored)) {
    return false;
  }
  final content = <String, Object?>{...values}..remove('record_digest');
  return stored == _calculateRecordDigest(content);
}

void _requireValidRecordDigest(Map<String, Object?> values, String recordType) {
  if (!_hasValidRecordDigest(values)) {
    throw FormatException('$recordType digest does not match its content.');
  }
}

String _calculateRecordDigest(Map<String, Object?> values) =>
    sha256.convert(utf8.encode(_canonicalJson(values))).toString();

String _canonicalJson(Object? value) {
  if (value is Map<Object?, Object?>) {
    final entries =
        value.entries.toList()
          ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));
    return '{${entries.map((entry) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException('Canonical JSON keys must be strings.');
      }
      return '${jsonEncode(key)}:${_canonicalJson(entry.value)}';
    }).join(',')}}';
  }
  if (value is List<Object?>) {
    return '[${value.map(_canonicalJson).join(',')}]';
  }
  return jsonEncode(value);
}

Set<ToolCapability> _capabilities(String source) {
  final decoded = _jsonArray(source, 'capabilities_json');
  return <ToolCapability>{
    for (final value in decoded)
      _ledgerEnum(
        ToolCapability.values,
        _jsonString(value, 'capabilities_json'),
        'capabilities_json',
      ),
  };
}

List<StructuredFact> _structuredFacts(String source) {
  final decoded = _jsonArray(source, 'structured_facts_json');
  return List<StructuredFact>.unmodifiable(
    decoded.map((value) {
      if (value is! Map<String, Object?>) {
        throw const FormatException(
          'Structured facts must contain JSON objects.',
        );
      }
      return StructuredFact(
        name: _jsonString(value['name'], 'structured_facts_json.name'),
        value: _requiredJsonValue(
          value['value'],
          'structured_facts_json.value',
        ),
        unit: _jsonString(value['unit'], 'structured_facts_json.unit'),
        attributes: _jsonMapValue(
          value['attributes'],
          'structured_facts_json.attributes',
        ),
      );
    }),
  );
}

Map<String, Object?> _jsonObject(String source, String field) {
  final decoded = _decodeJson(source, field);
  if (decoded is Map<String, Object?>) return decoded;
  throw FormatException('$field must contain a JSON object.');
}

List<Object?> _jsonArray(String source, String field) {
  final decoded = _decodeJson(source, field);
  if (decoded is List<Object?>) return decoded;
  throw FormatException('$field must contain a JSON array.');
}

Object? _decodeJson(String source, String field) {
  try {
    return jsonDecode(source);
  } on FormatException catch (error) {
    throw FormatException(
      '$field contains invalid JSON.',
      source,
      error.offset,
    );
  }
}

Map<String, Object?> _jsonMapValue(Object? value, String field) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$field must be a JSON object.');
}

Object _requiredJsonValue(Object? value, String field) {
  if (value != null) return value;
  throw FormatException('$field cannot be null.');
}

String _jsonString(Object? value, String field) {
  if (value is String) return value;
  throw FormatException('$field must be a string.');
}

String _ledgerText(Map<String, Object?> values, String field) {
  final value = values[field];
  if (value is String) return value;
  throw FormatException('$field must be a string.');
}

int _ledgerInt(Map<String, Object?> values, String field) {
  final value = values[field];
  if (value is int) return value;
  throw FormatException('$field must be an integer.');
}

int? _ledgerNullableInt(Map<String, Object?> values, String field) {
  final value = values[field];
  if (value == null || value is int) return value as int?;
  throw FormatException('$field must be an integer or null.');
}

bool _ledgerBool(Map<String, Object?> values, String field) {
  return switch (_ledgerInt(values, field)) {
    0 => false,
    1 => true,
    _ => throw FormatException('$field must be zero or one.'),
  };
}

T _ledgerEnum<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('$field contains an unknown enum value.');
}
