import 'dart:convert';

/// Semantic category declared for one user-visible answer segment.
enum ClaimKind {
  externalFact,
  currentFact,
  completedAction,
  executionFailure,
  userAssertion,
  nonFactual,
}

/// Application-computed trust for one structured answer claim.
enum ClaimTrustLevel { verified, unverified, notVerifiable }

extension ClaimKindWireName on ClaimKind {
  String get wireName => switch (this) {
    ClaimKind.externalFact => 'external_fact',
    ClaimKind.currentFact => 'current_fact',
    ClaimKind.completedAction => 'completed_action',
    ClaimKind.executionFailure => 'execution_failure',
    ClaimKind.userAssertion => 'user_assertion',
    ClaimKind.nonFactual => 'non_factual',
  };
}

/// One immutable, model-proposed claim and its application evidence links.
final class AnswerClaim {
  factory AnswerClaim({
    required String claimId,
    required String text,
    required ClaimKind kind,
    List<String> evidenceIds = const [],
  }) {
    final normalizedId = claimId.trim();
    final normalizedText = text.trim();
    if (!_claimIdPattern.hasMatch(normalizedId)) {
      throw const GroundedAnswerFormatException('invalid_claim_id');
    }
    _validateVisibleText(normalizedText, emptyCode: 'empty_claim_text');
    final normalizedEvidenceIds = <String>[];
    final seenEvidenceIds = <String>{};
    for (final evidenceId in evidenceIds) {
      if (!_evidenceIdPattern.hasMatch(evidenceId) ||
          !seenEvidenceIds.add(evidenceId)) {
        throw const GroundedAnswerFormatException('invalid_evidence_id');
      }
      normalizedEvidenceIds.add(evidenceId);
    }
    if (normalizedEvidenceIds.length > _maxEvidenceIdsPerClaim) {
      throw const GroundedAnswerFormatException('too_many_evidence_ids');
    }
    return AnswerClaim._(
      claimId: normalizedId,
      text: normalizedText,
      kind: kind,
      evidenceIds: List<String>.unmodifiable(normalizedEvidenceIds),
    );
  }

  const AnswerClaim._({
    required this.claimId,
    required this.text,
    required this.kind,
    required this.evidenceIds,
  });

  final String claimId;
  final String text;
  final ClaimKind kind;
  final List<String> evidenceIds;

  Map<String, Object?> toJson() => <String, Object?>{
    'claim_id': claimId,
    'text': text,
    'kind': kind.wireName,
    'evidence_ids': evidenceIds,
  };
}

/// Immutable claim-level grounding persisted with an assistant message.
///
/// [acceptedEvidenceIds] contains only evidence accepted by the deterministic
/// gate. Model-proposed but rejected IDs remain on [claim.evidenceIds] for
/// auditability and can never become trusted through history replay.
final class MessageClaimGrounding {
  factory MessageClaimGrounding({
    required AnswerClaim claim,
    required ClaimTrustLevel trustLevel,
    List<String> acceptedEvidenceIds = const [],
  }) {
    final accepted = List<String>.unmodifiable(acceptedEvidenceIds);
    final proposed = claim.evidenceIds.toSet();
    final unique = <String>{};
    for (final evidenceId in accepted) {
      if (!proposed.contains(evidenceId) || !unique.add(evidenceId)) {
        throw ArgumentError.value(
          acceptedEvidenceIds,
          'acceptedEvidenceIds',
          'Accepted evidence must be unique and proposed by the claim.',
        );
      }
    }
    if (trustLevel == ClaimTrustLevel.verified && accepted.isEmpty) {
      throw ArgumentError.value(
        trustLevel,
        'trustLevel',
        'A verified claim requires accepted evidence.',
      );
    }
    if (trustLevel != ClaimTrustLevel.verified && accepted.isNotEmpty) {
      throw ArgumentError.value(
        acceptedEvidenceIds,
        'acceptedEvidenceIds',
        'Only a verified claim can retain accepted evidence.',
      );
    }
    return MessageClaimGrounding._(
      claim: claim,
      trustLevel: trustLevel,
      acceptedEvidenceIds: accepted,
    );
  }

  const MessageClaimGrounding._({
    required this.claim,
    required this.trustLevel,
    required this.acceptedEvidenceIds,
  });

  final AnswerClaim claim;
  final ClaimTrustLevel trustLevel;
  final List<String> acceptedEvidenceIds;
}

/// A strictly parsed, Provider-independent answer ready for deterministic UI.
final class GroundedAnswerCandidate {
  factory GroundedAnswerCandidate({
    List<AnswerClaim> claims = const [],
    String nonFactualText = '',
  }) => _validatedCandidate(
    schemaVersion: currentSchemaVersion,
    claims: claims,
    nonFactualText: nonFactualText,
  );

  const GroundedAnswerCandidate._({
    required this.schemaVersion,
    required this.claims,
    required this.nonFactualText,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final List<AnswerClaim> claims;
  final String nonFactualText;

  bool get isLegacy => schemaVersion == 0;

  List<String> get evidenceIds => List<String>.unmodifiable({
    for (final claim in claims) ...claim.evidenceIds,
  });

  String get renderedText => <String>[
    for (final claim in claims) claim.text,
    if (nonFactualText.isNotEmpty) nonFactualText,
  ].join('\n\n');

  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': schemaVersion,
    'claims': [for (final claim in claims) claim.toJson()],
    'non_factual_text': nonFactualText,
  };

  static GroundedAnswerCandidate parseJson(
    String source, {
    required Set<String> allowedEvidenceIds,
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const GroundedAnswerFormatException('invalid_grounded_json');
    }
    if (decoded is! Map) {
      throw const GroundedAnswerFormatException('invalid_grounded_object');
    }
    final root = _stringMap(decoded, code: 'invalid_grounded_object');
    _requireExactKeys(root, const {
      'schema_version',
      'claims',
      'non_factual_text',
    });
    final schemaVersion = root['schema_version'];
    if (schemaVersion is! int) {
      throw const GroundedAnswerFormatException('invalid_grounded_schema');
    }
    if (schemaVersion != currentSchemaVersion) {
      throw const GroundedAnswerFormatException('unsupported_grounded_schema');
    }
    final rawClaims = root['claims'];
    final rawNonFactualText = root['non_factual_text'];
    if (rawClaims is! List || rawNonFactualText is! String) {
      throw const GroundedAnswerFormatException('invalid_grounded_fields');
    }
    if (rawClaims.length > _maxClaims) {
      throw const GroundedAnswerFormatException('too_many_claims');
    }
    final claims = <AnswerClaim>[];
    final claimIds = <String>{};
    for (final rawClaim in rawClaims) {
      if (rawClaim is! Map) {
        throw const GroundedAnswerFormatException('invalid_claim');
      }
      final claim = _parseClaim(
        _stringMap(rawClaim, code: 'invalid_claim'),
        allowedEvidenceIds,
      );
      if (!claimIds.add(claim.claimId)) {
        throw const GroundedAnswerFormatException('duplicate_claim_id');
      }
      claims.add(claim);
    }
    return _validatedCandidate(
      schemaVersion: currentSchemaVersion,
      claims: claims,
      nonFactualText: rawNonFactualText,
    );
  }

  /// Parses schema v1, falling back only to an exact legacy footer at EOF.
  static GroundedAnswerCandidate parseProviderOutput(
    String source, {
    required Set<String> allowedEvidenceIds,
    Map<String, String> providerCallToEvidenceId = const {},
  }) {
    try {
      return parseJson(source, allowedEvidenceIds: allowedEvidenceIds);
    } on GroundedAnswerFormatException {
      final normalized = source.trimRight();
      final matches = _legacyEvidenceFooter.allMatches(normalized).toList();
      if (matches.length != 1 || matches.single.end != normalized.length) {
        rethrow;
      }
      return _parseLegacyAnswer(
        source,
        allowedEvidenceIds: allowedEvidenceIds,
        providerCallToEvidenceId: providerCallToEvidenceId,
      );
    }
  }
}

/// Safe, stable parse failure that never includes Provider response text.
final class GroundedAnswerFormatException implements FormatException {
  const GroundedAnswerFormatException(this.code);

  final String code;

  @override
  String get message => code;

  @override
  int? get offset => null;

  @override
  Object? get source => null;

  @override
  String toString() => code;
}

AnswerClaim _parseClaim(
  Map<String, Object?> value,
  Set<String> allowedEvidenceIds,
) {
  _requireExactKeys(value, const {'claim_id', 'text', 'kind', 'evidence_ids'});
  final claimId = value['claim_id'];
  final text = value['text'];
  final rawKind = value['kind'];
  final rawEvidenceIds = value['evidence_ids'];
  if (claimId is! String ||
      text is! String ||
      rawKind is! String ||
      rawEvidenceIds is! List) {
    throw const GroundedAnswerFormatException('invalid_claim_fields');
  }
  final kind = _claimKind(rawKind);
  final evidenceIds = <String>[];
  for (final rawId in rawEvidenceIds) {
    if (rawId is! String || !allowedEvidenceIds.contains(rawId)) {
      throw const GroundedAnswerFormatException('evidence_id_out_of_range');
    }
    evidenceIds.add(rawId);
  }
  return AnswerClaim(
    claimId: claimId,
    text: text,
    kind: kind,
    evidenceIds: evidenceIds,
  );
}

ClaimKind _claimKind(String wireName) {
  for (final value in ClaimKind.values) {
    if (value.wireName == wireName) return value;
  }
  throw const GroundedAnswerFormatException('unknown_claim_kind');
}

GroundedAnswerCandidate _validatedCandidate({
  required int schemaVersion,
  required List<AnswerClaim> claims,
  required String nonFactualText,
}) {
  if (claims.length > _maxClaims) {
    throw const GroundedAnswerFormatException('too_many_claims');
  }
  final frozenClaims = List<AnswerClaim>.unmodifiable(claims);
  final claimIds = <String>{};
  for (final claim in frozenClaims) {
    if (!claimIds.add(claim.claimId)) {
      throw const GroundedAnswerFormatException('duplicate_claim_id');
    }
  }
  final normalizedNonFactualText = nonFactualText.trim();
  if (normalizedNonFactualText.isNotEmpty) {
    _validateVisibleText(
      normalizedNonFactualText,
      emptyCode: 'empty_non_factual_text',
    );
  }
  if (frozenClaims.isEmpty && normalizedNonFactualText.isEmpty) {
    throw const GroundedAnswerFormatException('empty_grounded_answer');
  }
  final totalCharacters = frozenClaims.fold<int>(
    normalizedNonFactualText.runes.length,
    (total, claim) => total + claim.text.runes.length,
  );
  if (totalCharacters > _maxAnswerCharacters) {
    throw const GroundedAnswerFormatException('grounded_answer_too_long');
  }
  return GroundedAnswerCandidate._(
    schemaVersion: schemaVersion,
    claims: frozenClaims,
    nonFactualText: normalizedNonFactualText,
  );
}

GroundedAnswerCandidate _parseLegacyAnswer(
  String source, {
  required Set<String> allowedEvidenceIds,
  required Map<String, String> providerCallToEvidenceId,
}) {
  final normalized = source.trimRight();
  final matches = _legacyEvidenceFooter.allMatches(normalized).toList();
  if (matches.length != 1 || matches.single.end != normalized.length) {
    throw const GroundedAnswerFormatException('invalid_grounded_json');
  }
  final body = normalized.substring(0, matches.single.start).trim();
  _validateVisibleText(body, emptyCode: 'empty_grounded_answer');
  final providerCallIds =
      (matches.single.group(1) ?? '')
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
  final evidenceIds = <String>[];
  for (final providerCallId in providerCallIds) {
    final evidenceId = providerCallToEvidenceId[providerCallId];
    if (evidenceId == null || !allowedEvidenceIds.contains(evidenceId)) {
      throw const GroundedAnswerFormatException(
        'legacy_evidence_id_out_of_range',
      );
    }
    evidenceIds.add(evidenceId);
  }
  return _validatedCandidate(
    schemaVersion: 0,
    claims: [
      AnswerClaim(
        claimId: 'legacy:claim:1',
        text: body,
        kind: ClaimKind.nonFactual,
        evidenceIds: evidenceIds,
      ),
    ],
    nonFactualText: '',
  );
}

Map<String, Object?> _stringMap(
  Map<Object?, Object?> value, {
  required String code,
}) {
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) throw GroundedAnswerFormatException(code);
    result[entry.key as String] = entry.value;
  }
  return result;
}

void _requireExactKeys(Map<String, Object?> value, Set<String> expected) {
  if (value.length != expected.length ||
      !value.keys.toSet().containsAll(expected)) {
    throw const GroundedAnswerFormatException('unexpected_grounded_fields');
  }
}

void _validateVisibleText(String value, {required String emptyCode}) {
  if (value.isEmpty) throw GroundedAnswerFormatException(emptyCode);
  if (value.runes.length > _maxSegmentCharacters ||
      _unsafeTextPattern.hasMatch(value) ||
      value.contains('<stars_evidence')) {
    throw const GroundedAnswerFormatException('invalid_visible_text');
  }
}

final RegExp _claimIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$');
final RegExp _evidenceIdPattern = RegExp(
  r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,511}$',
);
final RegExp _unsafeTextPattern = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');
final RegExp _legacyEvidenceFooter = RegExp(
  r'<stars_evidence\s+call_ids="([^"]*)"\s*/>',
);
const int _maxClaims = 128;
const int _maxEvidenceIdsPerClaim = 64;
const int _maxSegmentCharacters = 16000;
const int _maxAnswerCharacters = 65536;
