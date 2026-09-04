import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('GroundedAnswerCandidate', () {
    const evidenceId = 'run-1:invocation:1:attempt:1:evidence';

    test('parses every claim kind and renders only structured segments', () {
      final candidate = GroundedAnswerCandidate.parseJson(
        jsonEncode({
          'schema_version': 1,
          'claims': [
            for (final kind in ClaimKind.values)
              {
                'claim_id': 'claim-${kind.name}',
                'text': 'Segment ${kind.name}',
                'kind': kind.wireName,
                'evidence_ids':
                    kind == ClaimKind.nonFactual ? [] : [evidenceId],
              },
          ],
          'non_factual_text': 'Closing note',
        }),
        allowedEvidenceIds: const {evidenceId},
      );

      expect(candidate.schemaVersion, 1);
      expect(candidate.claims.map((claim) => claim.kind), ClaimKind.values);
      expect(candidate.evidenceIds, [evidenceId]);
      expect(candidate.renderedText, contains('Segment externalFact'));
      expect(candidate.renderedText, endsWith('Closing note'));
      expect(candidate.renderedText, isNot(contains('schema_version')));
      expect(candidate.toJson()['claims'], hasLength(ClaimKind.values.length));
    });

    test('free text is accepted only through non_factual_text', () {
      final candidate = GroundedAnswerCandidate.parseJson(
        jsonEncode({
          'schema_version': 1,
          'claims': <Object?>[],
          'non_factual_text': 'Hello there.',
        }),
        allowedEvidenceIds: const {},
      );

      expect(candidate.claims, isEmpty);
      expect(candidate.renderedText, 'Hello there.');
    });

    test('rejects malformed JSON and unknown fields', () {
      expect(
        () => GroundedAnswerCandidate.parseJson(
          '{broken',
          allowedEvidenceIds: const {},
        ),
        throwsA(_formatFailure('invalid_grounded_json')),
      );
      expect(
        () => GroundedAnswerCandidate.parseJson(
          jsonEncode({
            'schema_version': 1,
            'claims': <Object?>[],
            'non_factual_text': 'Hello',
            'provider_payload': 'must not leak',
          }),
          allowedEvidenceIds: const {},
        ),
        throwsA(_formatFailure('unexpected_grounded_fields')),
      );
      expect(
        () => GroundedAnswerCandidate.parseJson(
          jsonEncode({
            'schema_version': 1.0,
            'claims': <Object?>[],
            'non_factual_text': 'Hello',
          }),
          allowedEvidenceIds: const {},
        ),
        throwsA(_formatFailure('invalid_grounded_schema')),
      );
    });

    test('rejects unknown kind, duplicate IDs, and empty claims', () {
      Map<String, Object?> payload(List<Map<String, Object?>> claims) => {
        'schema_version': 1,
        'claims': claims,
        'non_factual_text': '',
      };
      Map<String, Object?> claim({String id = 'c1', String text = 'Fact'}) => {
        'claim_id': id,
        'text': text,
        'kind': 'external_fact',
        'evidence_ids': <String>[],
      };

      expect(
        () => GroundedAnswerCandidate.parseJson(
          jsonEncode(payload([claim()..['kind'] = 'provider_fact'])),
          allowedEvidenceIds: const {},
        ),
        throwsA(_formatFailure('unknown_claim_kind')),
      );
      expect(
        () => GroundedAnswerCandidate.parseJson(
          jsonEncode(payload([claim(), claim()])),
          allowedEvidenceIds: const {},
        ),
        throwsA(_formatFailure('duplicate_claim_id')),
      );
      expect(
        () => GroundedAnswerCandidate.parseJson(
          jsonEncode(payload([claim(text: '  ')])),
          allowedEvidenceIds: const {},
        ),
        throwsA(_formatFailure('empty_claim_text')),
      );
    });

    test('rejects evidence outside the current synthesis request', () {
      expect(
        () => GroundedAnswerCandidate.parseJson(
          jsonEncode({
            'schema_version': 1,
            'claims': [
              {
                'claim_id': 'c1',
                'text': 'Fact',
                'kind': 'current_fact',
                'evidence_ids': ['another-run:evidence'],
              },
            ],
            'non_factual_text': '',
          }),
          allowedEvidenceIds: const {evidenceId},
        ),
        throwsA(_formatFailure('evidence_id_out_of_range')),
      );
    });

    test('legacy footer maps Provider calls and is never rendered', () {
      final candidate = GroundedAnswerCandidate.parseProviderOutput(
        'Legacy answer.\n<stars_evidence call_ids="call-1" />',
        allowedEvidenceIds: const {evidenceId},
        providerCallToEvidenceId: const {'call-1': evidenceId},
      );

      expect(candidate.isLegacy, isTrue);
      expect(candidate.renderedText, 'Legacy answer.');
      expect(candidate.renderedText, isNot(contains('stars_evidence')));
      expect(candidate.evidenceIds, [evidenceId]);
      expect(candidate.claims.single.kind, ClaimKind.nonFactual);
    });

    test('legacy footer rejects unknown Provider calls', () {
      expect(
        () => GroundedAnswerCandidate.parseProviderOutput(
          'Legacy answer.\n<stars_evidence call_ids="unknown" />',
          allowedEvidenceIds: const {evidenceId},
          providerCallToEvidenceId: const {'call-1': evidenceId},
        ),
        throwsA(_formatFailure('legacy_evidence_id_out_of_range')),
      );
    });

    test('copies claim and evidence collections immutably', () {
      final evidenceIds = <String>[evidenceId];
      final claim = AnswerClaim(
        claimId: 'c1',
        text: 'Fact',
        kind: ClaimKind.externalFact,
        evidenceIds: evidenceIds,
      );
      final claims = <AnswerClaim>[claim];
      final candidate = GroundedAnswerCandidate(claims: claims);
      evidenceIds.clear();
      claims.clear();

      expect(candidate.claims, hasLength(1));
      expect(candidate.claims.single.evidenceIds, [evidenceId]);
      expect(() => candidate.claims.add(claim), throwsUnsupportedError);
    });
  });
}

Matcher _formatFailure(String code) => isA<GroundedAnswerFormatException>()
    .having((error) => error.code, 'code', code);
