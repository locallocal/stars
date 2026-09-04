part of 'tool.dart';

/// The claim category a terminal tool result is allowed to support.
enum EvidenceKind { observation, calculation, actionReceipt, executionFailure }

/// One schema-validated, normalized fact extracted from a tool result.
///
/// [value] and [attributes] are recursively copied into unmodifiable JSON
/// containers so later adapter mutations cannot change persisted evidence.
final class StructuredFact {
  factory StructuredFact({
    required String name,
    required Object value,
    String unit = '',
    Map<String, Object?> attributes = const {},
  }) {
    _requireNormalizedText(name, 'name');
    if (!_factNamePattern.hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'Fact names must be stable dotted identifiers.',
      );
    }
    _requireOptionalNormalizedText(unit, 'unit');
    final frozenValue = _freezeJsonValue(value, 'value');
    if (_isEmptyJsonValue(frozenValue)) {
      throw ArgumentError.value(value, 'value', 'Fact values cannot be empty.');
    }
    return StructuredFact._(
      name: name,
      value: frozenValue!,
      unit: unit,
      attributes: _freezeJsonMap(attributes, 'attributes'),
    );
  }

  const StructuredFact._({
    required this.name,
    required this.value,
    required this.unit,
    required this.attributes,
  });

  final String name;
  final Object value;
  final String unit;
  final Map<String, Object?> attributes;
}

/// An immutable point-in-time audit event for one tool attempt.
///
/// Unlike [ToolEvidenceRecord], this model deliberately accepts non-terminal
/// statuses. Requested, approval and running events prove only that lifecycle
/// activity happened; they never become factual evidence.
final class ToolInvocationEvent {
  factory ToolInvocationEvent({
    required String eventId,
    required String runId,
    required String turnId,
    required String chatId,
    String messageId = '',
    required String invocationId,
    required String attemptId,
    String providerCallId = '',
    required String toolName,
    String toolVersion = '',
    required ToolSource source,
    required ToolInvocationStatus status,
    required int sequence,
    required DateTime occurredAt,
    String errorCode = '',
  }) {
    for (final entry in <(String, String)>[
      ('eventId', eventId),
      ('runId', runId),
      ('turnId', turnId),
      ('chatId', chatId),
      ('invocationId', invocationId),
      ('attemptId', attemptId),
    ]) {
      _requireApplicationId(entry.$2, entry.$1);
    }
    _requireOptionalApplicationId(messageId, 'messageId');
    _requireProviderId(providerCallId);
    _requireNormalizedText(toolName, 'toolName');
    _requireOptionalNormalizedText(toolVersion, 'toolVersion');
    _requireOptionalErrorCode(errorCode);
    if (sequence < 1) {
      throw ArgumentError.value(
        sequence,
        'sequence',
        'Event sequence must be positive.',
      );
    }
    final expectedEventId = eventIdForAttempt(attemptId, sequence);
    if (eventId != expectedEventId) {
      throw ArgumentError.value(
        eventId,
        'eventId',
        'Event IDs must be derived from the application attempt identity.',
      );
    }
    if (providerCallId.isNotEmpty && eventId == providerCallId) {
      throw ArgumentError.value(
        eventId,
        'eventId',
        'Application event IDs cannot reuse Provider call IDs.',
      );
    }
    return ToolInvocationEvent._(
      eventId: eventId,
      runId: runId,
      turnId: turnId,
      chatId: chatId,
      messageId: messageId,
      invocationId: invocationId,
      attemptId: attemptId,
      providerCallId: providerCallId,
      toolName: toolName,
      toolVersion: toolVersion,
      source: source,
      status: status,
      sequence: sequence,
      occurredAt: occurredAt,
      errorCode: errorCode,
    );
  }

  const ToolInvocationEvent._({
    required this.eventId,
    required this.runId,
    required this.turnId,
    required this.chatId,
    required this.messageId,
    required this.invocationId,
    required this.attemptId,
    required this.providerCallId,
    required this.toolName,
    required this.toolVersion,
    required this.source,
    required this.status,
    required this.sequence,
    required this.occurredAt,
    required this.errorCode,
  });

  static String eventIdForAttempt(String attemptId, int sequence) {
    _requireApplicationId(attemptId, 'attemptId');
    if (sequence < 1) {
      throw ArgumentError.value(
        sequence,
        'sequence',
        'Event sequence must be positive.',
      );
    }
    return '$attemptId:event:$sequence';
  }

  final String eventId;
  final String runId;
  final String turnId;
  final String chatId;
  final String messageId;
  final String invocationId;
  final String attemptId;

  /// Opaque correlation metadata owned by the Provider, never an event ID.
  final String providerCallId;

  final String toolName;
  final String toolVersion;
  final ToolSource source;
  final ToolInvocationStatus status;
  final int sequence;
  final DateTime occurredAt;
  final String errorCode;

  bool get isTerminal => _auditTerminalStatuses.contains(status);
}

/// An immutable terminal result that may be written to the evidence ledger.
///
/// Business evidence is intentionally stricter than audit events: it must be
/// a successful, non-empty, schema-valid and non-truncated structured result.
/// Failure evidence can describe only this attempt's failure.
final class ToolEvidenceRecord {
  factory ToolEvidenceRecord({
    required String evidenceId,
    required String runId,
    required String turnId,
    required String chatId,
    String messageId = '',
    required String invocationId,
    required String attemptId,
    String providerCallId = '',
    required String toolName,
    required String toolVersion,
    required ToolSource source,
    Set<ToolCapability> capabilities = const {},
    required ToolInvocationStatus terminalStatus,
    required EvidenceKind evidenceKind,
    String subject = '',
    Map<String, Object?> scope = const {},
    required String resultSummary,
    required String argumentsDigest,
    required String resultDigest,
    List<StructuredFact> structuredFacts = const [],
    required DateTime observedAt,
    DateTime? validUntil,
    String payloadRef = '',
    DateTime? payloadExpiresAt,
    bool truncated = false,
    bool schemaValid = true,
    bool persisted = false,
    String errorCode = '',
  }) {
    for (final entry in <(String, String)>[
      ('evidenceId', evidenceId),
      ('runId', runId),
      ('turnId', turnId),
      ('chatId', chatId),
      ('invocationId', invocationId),
      ('attemptId', attemptId),
    ]) {
      _requireApplicationId(entry.$2, entry.$1);
    }
    _requireOptionalApplicationId(messageId, 'messageId');
    _requireProviderId(providerCallId);
    final expectedEvidenceId = evidenceIdForAttempt(attemptId);
    if (evidenceId != expectedEvidenceId) {
      throw ArgumentError.value(
        evidenceId,
        'evidenceId',
        'Evidence IDs must be derived from the application attempt identity.',
      );
    }
    if (providerCallId.isNotEmpty && evidenceId == providerCallId) {
      throw ArgumentError.value(
        evidenceId,
        'evidenceId',
        'Application evidence IDs cannot reuse Provider call IDs.',
      );
    }
    _requireNormalizedText(toolName, 'toolName');
    _requireNormalizedText(toolVersion, 'toolVersion');
    _requireNormalizedText(resultSummary, 'resultSummary');
    _requireDigest(argumentsDigest, 'argumentsDigest');
    _requireDigest(resultDigest, 'resultDigest');
    _requireOptionalNormalizedText(subject, 'subject');
    _requireOptionalNormalizedText(payloadRef, 'payloadRef');
    _requireOptionalErrorCode(errorCode);
    if (!_evidenceTerminalStatuses.contains(terminalStatus)) {
      throw ArgumentError.value(
        terminalStatus,
        'terminalStatus',
        'Only terminal execution statuses can become evidence.',
      );
    }
    if (validUntil != null && !validUntil.isAfter(observedAt)) {
      throw ArgumentError.value(
        validUntil,
        'validUntil',
        'Evidence validity must end after it was observed.',
      );
    }
    if (payloadRef.isEmpty != (payloadExpiresAt == null)) {
      throw ArgumentError(
        'Encrypted payload references require an explicit retention expiry.',
      );
    }
    if (payloadRef.isNotEmpty && !payloadRef.startsWith('encrypted://')) {
      throw ArgumentError.value(
        payloadRef,
        'payloadRef',
        'Sensitive payload references must identify encrypted storage.',
      );
    }
    if (payloadExpiresAt != null && !payloadExpiresAt.isAfter(observedAt)) {
      throw ArgumentError.value(
        payloadExpiresAt,
        'payloadExpiresAt',
        'Payload retention must end after the result was observed.',
      );
    }

    final frozenCapabilities = Set<ToolCapability>.unmodifiable(capabilities);
    final frozenFacts = List<StructuredFact>.unmodifiable(structuredFacts);
    final frozenScope = _freezeJsonMap(scope, 'scope');
    _validateUniqueFactNames(frozenFacts);
    _validateEvidenceSemantics(
      terminalStatus: terminalStatus,
      evidenceKind: evidenceKind,
      capabilities: frozenCapabilities,
      subject: subject,
      scope: frozenScope,
      structuredFacts: frozenFacts,
      truncated: truncated,
      schemaValid: schemaValid,
      validUntil: validUntil,
      errorCode: errorCode,
    );

    return ToolEvidenceRecord._(
      evidenceId: evidenceId,
      runId: runId,
      turnId: turnId,
      chatId: chatId,
      messageId: messageId,
      invocationId: invocationId,
      attemptId: attemptId,
      providerCallId: providerCallId,
      toolName: toolName,
      toolVersion: toolVersion,
      source: source,
      capabilities: frozenCapabilities,
      terminalStatus: terminalStatus,
      evidenceKind: evidenceKind,
      subject: subject,
      scope: frozenScope,
      resultSummary: resultSummary,
      argumentsDigest: argumentsDigest,
      resultDigest: resultDigest,
      structuredFacts: frozenFacts,
      observedAt: observedAt,
      validUntil: validUntil,
      payloadRef: payloadRef,
      payloadExpiresAt: payloadExpiresAt,
      truncated: truncated,
      schemaValid: schemaValid,
      persisted: persisted,
      errorCode: errorCode,
    );
  }

  const ToolEvidenceRecord._({
    required this.evidenceId,
    required this.runId,
    required this.turnId,
    required this.chatId,
    required this.messageId,
    required this.invocationId,
    required this.attemptId,
    required this.providerCallId,
    required this.toolName,
    required this.toolVersion,
    required this.source,
    required this.capabilities,
    required this.terminalStatus,
    required this.evidenceKind,
    required this.subject,
    required this.scope,
    required this.resultSummary,
    required this.argumentsDigest,
    required this.resultDigest,
    required this.structuredFacts,
    required this.observedAt,
    required this.validUntil,
    required this.payloadRef,
    required this.payloadExpiresAt,
    required this.truncated,
    required this.schemaValid,
    required this.persisted,
    required this.errorCode,
  });

  /// Uses only the application-owned attempt identity, never a Provider ID.
  static String evidenceIdForAttempt(String attemptId) {
    _requireApplicationId(attemptId, 'attemptId');
    return '$attemptId:evidence';
  }

  final String evidenceId;
  final String runId;
  final String turnId;
  final String chatId;
  final String messageId;
  final String invocationId;
  final String attemptId;

  /// Opaque Provider correlation metadata; it is never an evidence identity.
  final String providerCallId;

  final String toolName;
  final String toolVersion;
  final ToolSource source;
  final Set<ToolCapability> capabilities;
  final ToolInvocationStatus terminalStatus;
  final EvidenceKind evidenceKind;
  final String subject;
  final Map<String, Object?> scope;
  final String resultSummary;
  final String argumentsDigest;
  final String resultDigest;
  final List<StructuredFact> structuredFacts;
  final DateTime observedAt;
  final DateTime? validUntil;
  final String payloadRef;
  final DateTime? payloadExpiresAt;
  final bool truncated;
  final bool schemaValid;
  final bool persisted;
  final String errorCode;

  bool get isBusinessFactEvidence =>
      evidenceKind != EvidenceKind.executionFailure;

  bool get canSupportBusinessFacts => isBusinessFactEvidence && persisted;

  bool get canSupportExecutionFailure =>
      evidenceKind == EvidenceKind.executionFailure && persisted;

  bool canSupportBusinessFactsAt(DateTime instant) =>
      canSupportBusinessFacts &&
      !instant.isBefore(observedAt) &&
      (validUntil == null || instant.isBefore(validUntil!));
}

const Set<ToolInvocationStatus> _evidenceTerminalStatuses = {
  ToolInvocationStatus.succeeded,
  ToolInvocationStatus.failed,
  ToolInvocationStatus.denied,
  ToolInvocationStatus.cancelled,
  ToolInvocationStatus.timedOut,
};

const Set<ToolInvocationStatus> _auditTerminalStatuses = {
  ..._evidenceTerminalStatuses,
  ToolInvocationStatus.duplicateReused,
  ToolInvocationStatus.duplicateConflict,
  ToolInvocationStatus.duplicate,
};

const Set<ToolCapability> _readCapabilities = {
  ToolCapability.localRead,
  ToolCapability.externalRead,
  ToolCapability.network,
};

const Set<ToolCapability> _writeCapabilities = {
  ToolCapability.localWrite,
  ToolCapability.externalWrite,
};

final RegExp _applicationIdPattern = RegExp(
  r'^[A-Za-z0-9][A-Za-z0-9._:@/+-]{0,254}$',
);
final RegExp _factNamePattern = RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{0,127}$');
final RegExp _digestPattern = RegExp(r'^[a-f0-9]{64}$');
final RegExp _errorCodePattern = RegExp(r'^[a-z][a-z0-9_]{0,63}$');
final RegExp _controlCharacterPattern = RegExp(r'[\x00-\x1F\x7F]');

void _validateEvidenceSemantics({
  required ToolInvocationStatus terminalStatus,
  required EvidenceKind evidenceKind,
  required Set<ToolCapability> capabilities,
  required String subject,
  required Map<String, Object?> scope,
  required List<StructuredFact> structuredFacts,
  required bool truncated,
  required bool schemaValid,
  required DateTime? validUntil,
  required String errorCode,
}) {
  final succeeded = terminalStatus == ToolInvocationStatus.succeeded;
  if (evidenceKind == EvidenceKind.executionFailure) {
    if (succeeded) {
      throw ArgumentError.value(
        terminalStatus,
        'terminalStatus',
        'Successful results cannot become execution-failure evidence.',
      );
    }
    if (errorCode.isEmpty) {
      throw ArgumentError.value(
        errorCode,
        'errorCode',
        'Execution-failure evidence requires a safe error code.',
      );
    }
    if (structuredFacts.isNotEmpty) {
      throw ArgumentError.value(
        structuredFacts,
        'structuredFacts',
        'Execution failures cannot carry business facts.',
      );
    }
    return;
  }

  if (!succeeded) {
    throw ArgumentError.value(
      terminalStatus,
      'terminalStatus',
      'Failed attempts can only produce execution-failure evidence.',
    );
  }
  if (errorCode.isNotEmpty) {
    throw ArgumentError.value(
      errorCode,
      'errorCode',
      'Successful business evidence cannot carry an error code.',
    );
  }
  if (truncated) {
    throw ArgumentError.value(
      truncated,
      'truncated',
      'Truncated results cannot become business evidence.',
    );
  }
  if (!schemaValid) {
    throw ArgumentError.value(
      schemaValid,
      'schemaValid',
      'Schema-invalid results cannot become business evidence.',
    );
  }
  if (subject.isEmpty || scope.isEmpty || structuredFacts.isEmpty) {
    throw ArgumentError(
      'Business evidence requires a subject, scope, and structured facts.',
    );
  }
  if (capabilities.any(_writeCapabilities.contains) &&
      evidenceKind != EvidenceKind.actionReceipt) {
    throw ArgumentError.value(
      capabilities,
      'capabilities',
      'Successful write results must be represented as action receipts.',
    );
  }

  switch (evidenceKind) {
    case EvidenceKind.observation:
      if (!capabilities.any(_readCapabilities.contains)) {
        throw ArgumentError.value(
          capabilities,
          'capabilities',
          'Observation evidence requires a read capability.',
        );
      }
      if ((capabilities.contains(ToolCapability.externalRead) ||
              capabilities.contains(ToolCapability.network)) &&
          validUntil == null) {
        throw ArgumentError.value(
          validUntil,
          'validUntil',
          'External observations require an explicit validity window.',
        );
      }
    case EvidenceKind.calculation:
      if (!capabilities.contains(ToolCapability.compute) ||
          capabilities.any(_readCapabilities.contains)) {
        throw ArgumentError.value(
          capabilities,
          'capabilities',
          'Calculation evidence requires compute without read capabilities.',
        );
      }
    case EvidenceKind.actionReceipt:
      if (!capabilities.any(_writeCapabilities.contains)) {
        throw ArgumentError.value(
          capabilities,
          'capabilities',
          'Action receipts require a write capability.',
        );
      }
    case EvidenceKind.executionFailure:
      throw StateError('Execution failures return before business checks.');
  }
}

void _validateUniqueFactNames(List<StructuredFact> facts) {
  final names = <String>{};
  for (final fact in facts) {
    if (!names.add(fact.name)) {
      throw ArgumentError.value(
        fact.name,
        'structuredFacts',
        'Structured fact names must be unique within one evidence record.',
      );
    }
  }
}

void _requireApplicationId(String value, String name) {
  if (!_applicationIdPattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      name,
      'Application IDs must be normalized and contain only safe characters.',
    );
  }
}

void _requireOptionalApplicationId(String value, String name) {
  if (value.isNotEmpty) _requireApplicationId(value, name);
}

void _requireProviderId(String value) {
  if (value.isEmpty) return;
  if (value.trim() != value ||
      value.length > 1024 ||
      _controlCharacterPattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'providerCallId',
      'Provider call IDs must be normalized opaque values.',
    );
  }
}

void _requireNormalizedText(String value, String name) {
  if (value.isEmpty ||
      value.trim() != value ||
      _controlCharacterPattern.hasMatch(value)) {
    throw ArgumentError.value(value, name, 'Value must be normalized text.');
  }
}

void _requireOptionalNormalizedText(String value, String name) {
  if (value.isNotEmpty) _requireNormalizedText(value, name);
}

void _requireDigest(String value, String name) {
  if (!_digestPattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      name,
      'Digests must be lowercase hexadecimal SHA-256 values.',
    );
  }
}

void _requireOptionalErrorCode(String value) {
  if (value.isNotEmpty && !_errorCodePattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'errorCode',
      'Error codes must be normalized machine-readable values.',
    );
  }
}

Map<String, Object?> _freezeJsonMap(Map<String, Object?> source, String name) {
  final frozen = <String, Object?>{};
  for (final entry in source.entries) {
    _requireNormalizedText(entry.key, '$name.key');
    frozen[entry.key] = _freezeJsonValue(entry.value, name);
  }
  return Map<String, Object?>.unmodifiable(frozen);
}

Object? _freezeJsonValue(Object? value, String name) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'JSON numbers must be finite.');
    }
    return value;
  }
  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(
      value.map((item) => _freezeJsonValue(item, name)),
    );
  }
  if (value is Map<Object?, Object?>) {
    final frozen = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw ArgumentError.value(
          value,
          name,
          'JSON object keys must be strings.',
        );
      }
      _requireNormalizedText(key, '$name.key');
      frozen[key] = _freezeJsonValue(entry.value, name);
    }
    return Map<String, Object?>.unmodifiable(frozen);
  }
  throw ArgumentError.value(value, name, 'Value must be JSON-compatible.');
}

bool _isEmptyJsonValue(Object? value) =>
    value == null ||
    (value is String && value.trim().isEmpty) ||
    (value is List<Object?> && value.isEmpty) ||
    (value is Map<Object?, Object?> && value.isEmpty);
