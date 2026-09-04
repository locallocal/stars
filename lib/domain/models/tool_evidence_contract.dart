part of 'tool.dart';

/// JSON Schema properties shared by every evidence-bearing Tool output.
const Map<String, Object?> toolEvidenceOutputSchemaProperties = {
  'evidence_kind': {
    'type': 'string',
    'enum': ['observation', 'calculation', 'actionReceipt'],
  },
  'subject': {'type': 'string', 'minLength': 1},
  'scope': {'type': 'object', 'minProperties': 1, 'additionalProperties': true},
  'facts': {
    'type': 'array',
    'minItems': 1,
    'items': {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'minLength': 1},
        'value': {
          'type': ['null', 'boolean', 'object', 'array', 'number', 'string'],
        },
        'unit': {'type': 'string'},
        'attributes': {'type': 'object', 'additionalProperties': true},
      },
      'required': ['name', 'value'],
      'additionalProperties': false,
    },
  },
  'observed_at': {'type': 'string', 'format': 'date-time'},
  'valid_until': {'type': 'string', 'format': 'date-time'},
};

const List<String> toolEvidenceOutputRequiredFields = [
  'evidence_kind',
  'subject',
  'scope',
  'facts',
  'observed_at',
];

/// Declaratively binds top-level Tool arguments to an evidence scope.
final class ToolEvidenceScopeRule {
  factory ToolEvidenceScopeRule({
    required String subject,
    Map<String, String> argumentToScope = const {},
    Map<String, Object?> fixedScope = const {},
  }) {
    _requireNormalizedText(subject, 'subject');
    final mappings = Map<String, String>.unmodifiable(argumentToScope);
    final frozenFixedScope = _freezeJsonMap(fixedScope, 'fixedScope');
    if (mappings.isEmpty && frozenFixedScope.isEmpty) {
      throw ArgumentError('An evidence scope rule cannot produce empty scope.');
    }
    final scopeKeys = <String>{...frozenFixedScope.keys};
    for (final entry in mappings.entries) {
      _requireScopeKey(entry.key, 'argumentToScope argument');
      _requireScopeKey(entry.value, 'argumentToScope scope key');
      if (!scopeKeys.add(entry.value)) {
        throw ArgumentError.value(
          entry.value,
          'argumentToScope',
          'Evidence scope keys must be unique.',
        );
      }
    }
    return ToolEvidenceScopeRule._(
      subject: subject,
      argumentToScope: mappings,
      fixedScope: frozenFixedScope,
    );
  }

  const ToolEvidenceScopeRule._({
    required this.subject,
    required this.argumentToScope,
    required this.fixedScope,
  });

  final String subject;
  final Map<String, String> argumentToScope;
  final Map<String, Object?> fixedScope;

  bool matches({
    required Map<String, Object?> arguments,
    required String resultSubject,
    required Map<String, Object?> resultScope,
  }) {
    if (resultSubject != subject) return false;
    final expected = <String, Object?>{...fixedScope};
    for (final entry in argumentToScope.entries) {
      if (arguments.containsKey(entry.key)) {
        expected[entry.value] = arguments[entry.key];
      }
    }
    return _canonicalToolJson(expected) == _canonicalToolJson(resultScope);
  }
}

/// A validated, payload-free business evidence value ready for persistence.
final class ToolEvidenceCandidate {
  factory ToolEvidenceCandidate({
    required String toolVersion,
    required Set<ToolCapability> capabilities,
    required EvidenceKind evidenceKind,
    required String subject,
    required Map<String, Object?> scope,
    required List<StructuredFact> structuredFacts,
    required String argumentsDigest,
    required String resultDigest,
    required DateTime observedAt,
    DateTime? validUntil,
  }) {
    _requireNormalizedText(toolVersion, 'toolVersion');
    _requireNormalizedText(subject, 'subject');
    _requireDigest(argumentsDigest, 'argumentsDigest');
    _requireDigest(resultDigest, 'resultDigest');
    final normalizedObservedAt = observedAt.toUtc();
    final normalizedValidUntil = validUntil?.toUtc();
    if (normalizedValidUntil != null &&
        !normalizedValidUntil.isAfter(normalizedObservedAt)) {
      throw ArgumentError.value(
        validUntil,
        'validUntil',
        'Evidence validity must end after it was observed.',
      );
    }
    final frozenCapabilities = Set<ToolCapability>.unmodifiable(capabilities);
    final frozenScope = _freezeJsonMap(scope, 'scope');
    final frozenFacts = List<StructuredFact>.unmodifiable(structuredFacts);
    _validateUniqueFactNames(frozenFacts);
    _validateEvidenceSemantics(
      terminalStatus: ToolInvocationStatus.succeeded,
      evidenceKind: evidenceKind,
      capabilities: frozenCapabilities,
      subject: subject,
      scope: frozenScope,
      structuredFacts: frozenFacts,
      truncated: false,
      schemaValid: true,
      validUntil: normalizedValidUntil,
      errorCode: '',
    );
    return ToolEvidenceCandidate._(
      toolVersion: toolVersion,
      capabilities: frozenCapabilities,
      evidenceKind: evidenceKind,
      subject: subject,
      scope: frozenScope,
      structuredFacts: frozenFacts,
      argumentsDigest: argumentsDigest,
      resultDigest: resultDigest,
      observedAt: normalizedObservedAt,
      validUntil: normalizedValidUntil,
    );
  }

  const ToolEvidenceCandidate._({
    required this.toolVersion,
    required this.capabilities,
    required this.evidenceKind,
    required this.subject,
    required this.scope,
    required this.structuredFacts,
    required this.argumentsDigest,
    required this.resultDigest,
    required this.observedAt,
    required this.validUntil,
  });

  final String toolVersion;
  final Set<ToolCapability> capabilities;
  final EvidenceKind evidenceKind;
  final String subject;
  final Map<String, Object?> scope;
  final List<StructuredFact> structuredFacts;
  final String argumentsDigest;
  final String resultDigest;
  final DateTime observedAt;
  final DateTime? validUntil;
}

final class ToolEvidenceContractException implements Exception {
  const ToolEvidenceContractException(this.code);

  final String code;

  @override
  String toString() => code;
}

Map<String, Object?> toolEvidenceOutputMetadata({
  required EvidenceKind evidenceKind,
  required String subject,
  required Map<String, Object?> scope,
  required List<StructuredFact> structuredFacts,
  required DateTime observedAt,
  DateTime? validUntil,
}) => <String, Object?>{
  'evidence_kind': evidenceKind.name,
  'subject': subject,
  'scope': scope,
  'facts': [for (final fact in structuredFacts) _structuredFactJson(fact)],
  'observed_at': observedAt.toUtc().toIso8601String(),
  if (validUntil != null) 'valid_until': validUntil.toUtc().toIso8601String(),
};

ToolEvidenceCandidate? validateToolEvidenceResult(
  ToolDefinition definition,
  Map<String, Object?> arguments,
  ToolResult result,
) {
  if (!definition.producesEvidence) return null;
  if (result.isError || !result.schemaValid || result.truncated) {
    throw const ToolEvidenceContractException('tool_evidence_not_usable');
  }
  final evidenceKind = result.evidenceKind;
  final observedAt = result.observedAt;
  if (evidenceKind == null || observedAt == null) {
    throw const ToolEvidenceContractException('tool_evidence_metadata_missing');
  }
  if (!definition.evidenceCapabilities.contains(evidenceKind)) {
    throw const ToolEvidenceContractException('tool_evidence_kind_not_allowed');
  }
  _requireEmbeddedEvidenceMetadata(result);
  final scopeRule = definition.evidenceScope!;
  if (!scopeRule.matches(
    arguments: arguments,
    resultSubject: result.subject,
    resultScope: result.scope,
  )) {
    throw const ToolEvidenceContractException('tool_evidence_scope_mismatch');
  }
  final validUntil =
      result.validUntil ??
      (definition.defaultEvidenceValidity == null
          ? null
          : observedAt.add(definition.defaultEvidenceValidity!));
  return ToolEvidenceCandidate(
    toolVersion: definition.toolVersion,
    capabilities: definition.capabilities,
    evidenceKind: evidenceKind,
    subject: result.subject,
    scope: result.scope,
    structuredFacts: result.structuredFacts,
    argumentsDigest: _toolArgumentsDigest(arguments),
    resultDigest: result.resultDigest,
    observedAt: observedAt,
    validUntil: validUntil,
  );
}

void _validateToolEvidenceDefinition(ToolDefinition definition) {
  _requireNormalizedText(definition.toolVersion, 'toolVersion');
  final evidenceKinds = definition.evidenceCapabilities;
  if (evidenceKinds.isEmpty) {
    if (definition.evidenceScope != null ||
        definition.defaultEvidenceValidity != null ||
        definition.requiresReadAfterWrite) {
      throw ArgumentError(
        'Evidence policy cannot be configured without evidence capabilities.',
      );
    }
    return;
  }
  if (definition.toolVersion == 'unversioned') {
    throw ArgumentError('Evidence-bearing Tools require an explicit version.');
  }
  if (definition.outputSchema == null || definition.evidenceScope == null) {
    throw ArgumentError(
      'Evidence-bearing Tools require an output Schema and scope rule.',
    );
  }
  _requireEvidenceSchema(definition.outputSchema!);
  final validity = definition.defaultEvidenceValidity;
  if (validity != null && validity <= Duration.zero) {
    throw ArgumentError.value(
      validity,
      'defaultEvidenceValidity',
      'Evidence validity must be positive.',
    );
  }
  if (evidenceKinds.contains(EvidenceKind.executionFailure)) {
    throw ArgumentError(
      'Execution failures are recorded automatically, not declared.',
    );
  }
  for (final kind in evidenceKinds) {
    _validateEvidenceKindCapabilities(kind, definition.capabilities);
  }
  final externalObservation =
      evidenceKinds.contains(EvidenceKind.observation) &&
      definition.capabilities.any(
        const {ToolCapability.externalRead, ToolCapability.network}.contains,
      );
  if (externalObservation && validity == null) {
    throw ArgumentError(
      'External observations require a default evidence validity.',
    );
  }
  if (definition.requiresReadAfterWrite &&
      (!definition.capabilities.any(_writeCapabilities.contains) ||
          !evidenceKinds.contains(EvidenceKind.actionReceipt))) {
    throw ArgumentError(
      'Read-after-write applies only to evidence-bearing write Tools.',
    );
  }
}

void _validateEvidenceKindCapabilities(
  EvidenceKind kind,
  Set<ToolCapability> capabilities,
) {
  switch (kind) {
    case EvidenceKind.observation:
      if (!capabilities.any(_readCapabilities.contains) ||
          capabilities.any(_writeCapabilities.contains)) {
        throw ArgumentError('Observation evidence requires read-only access.');
      }
    case EvidenceKind.calculation:
      if (!capabilities.contains(ToolCapability.compute) ||
          capabilities.any(_readCapabilities.contains) ||
          capabilities.any(_writeCapabilities.contains)) {
        throw ArgumentError('Calculation evidence requires pure computation.');
      }
    case EvidenceKind.actionReceipt:
      if (!capabilities.any(_writeCapabilities.contains)) {
        throw ArgumentError('Action receipts require a write capability.');
      }
    case EvidenceKind.executionFailure:
      throw StateError('Execution failures are not declared capabilities.');
  }
}

void _requireEvidenceSchema(Map<String, Object?> schema) {
  final properties = schema['properties'];
  final required = schema['required'];
  if (schema['type'] != 'object' || properties is! Map || required is! List) {
    throw ArgumentError('Evidence output Schema must describe an object.');
  }
  final propertyNames = properties.keys.map((key) => key.toString()).toSet();
  final requiredNames = required.whereType<String>().toSet();
  if (!propertyNames.containsAll(toolEvidenceOutputRequiredFields) ||
      !requiredNames.containsAll(toolEvidenceOutputRequiredFields)) {
    throw ArgumentError(
      'Evidence output Schema must require the standard evidence fields.',
    );
  }
}

void _requireEmbeddedEvidenceMetadata(ToolResult result) {
  final structured = result.structuredContent;
  if (structured is! Map) {
    throw const ToolEvidenceContractException('tool_evidence_metadata_missing');
  }
  final values = structured.map(
    (key, value) => MapEntry(key.toString(), value),
  );
  final expected = toolEvidenceOutputMetadata(
    evidenceKind: result.evidenceKind!,
    subject: result.subject,
    scope: result.scope,
    structuredFacts: result.structuredFacts,
    observedAt: result.observedAt!,
    validUntil: result.validUntil,
  );
  if (values.containsKey('valid_until') != (result.validUntil != null)) {
    throw const ToolEvidenceContractException('tool_evidence_output_mismatch');
  }
  for (final entry in expected.entries) {
    if (!values.containsKey(entry.key) ||
        _canonicalToolJson(values[entry.key]) !=
            _canonicalToolJson(entry.value)) {
      throw const ToolEvidenceContractException(
        'tool_evidence_output_mismatch',
      );
    }
  }
}

Map<String, Object?> _structuredFactJson(StructuredFact fact) => {
  'name': fact.name,
  'value': fact.value,
  if (fact.unit.isNotEmpty) 'unit': fact.unit,
  if (fact.attributes.isNotEmpty) 'attributes': fact.attributes,
};

String _toolResultDigest(
  String content,
  Object? structuredContent, {
  required String supplied,
}) {
  if (supplied.isNotEmpty) {
    _requireDigest(supplied, 'resultDigest');
    return supplied;
  }
  return sha256
      .convert(
        utf8.encode(
          _canonicalToolJson(<String, Object?>{
            'content': content,
            'structured_content': structuredContent,
          }),
        ),
      )
      .toString();
}

String _toolArgumentsDigest(Map<String, Object?> arguments) =>
    sha256.convert(utf8.encode(_canonicalToolJson(arguments))).toString();

String _canonicalToolJson(Object? value) => jsonEncode(switch (value) {
  null || bool() || String() => value,
  final num number when number.isFinite => number,
  final List<Object?> values => [
    for (final item in values) _canonicalValue(item),
  ],
  final Map<Object?, Object?> values => _canonicalMap(values),
  _ => throw ArgumentError.value(value, 'value', 'Value must be JSON-safe.'),
});

Object? _canonicalValue(Object? value) => jsonDecode(_canonicalToolJson(value));

Map<String, Object?> _canonicalMap(Map<Object?, Object?> values) {
  if (values.keys.any((key) => key is! String)) {
    throw ArgumentError.value(
      values,
      'value',
      'JSON object keys must be text.',
    );
  }
  final keys = values.keys.cast<String>().toList()..sort();
  return <String, Object?>{
    for (final key in keys) key: _canonicalValue(values[key]),
  };
}

void _requireScopeKey(String value, String name) {
  if (!RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{0,127}$').hasMatch(value)) {
    throw ArgumentError.value(value, name, 'Scope keys must be normalized.');
  }
}
