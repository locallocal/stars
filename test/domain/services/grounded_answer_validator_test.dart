import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';

void main() {
  final now = DateTime.utc(2026, 9, 5, 12);

  group('GroundedAnswerValidator', () {
    test(
      'accepts a persisted same-run observation with exact semantics',
      () async {
        final evidence = _observation(
          validUntil: now.add(const Duration(hours: 1)),
        );
        final result = await _validate(
          evidence: evidence,
          now: now,
          claim: _claim(kind: ClaimKind.currentFact),
          requirement: _weatherRequirement(),
        );

        expect(result.trustLevel, AnswerTrustLevel.verified);
        expect(result.reasonCode, 'all_claims_verified');
        expect(result.evidenceIds, [evidence.evidenceId]);
        expect(result.claims.single.trustLevel, ClaimTrustLevel.verified);
        expect(result.claims.single.issues, isEmpty);
      },
    );

    test('rejects every deterministic evidence-gate failure', () async {
      final validUntil = now.add(const Duration(hours: 1));
      final cases = <
        String,
        ({
          ToolEvidenceRecord? evidence,
          AnswerClaim claim,
          ClaimEvidenceRequirement? requirement,
          EvidenceRejectionReason reason,
          bool integrityValid,
        })
      >{
        'missing ledger record': (
          evidence: null,
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceNotFound,
          integrityValid: true,
        ),
        'cross-run evidence': (
          evidence: _observation(runId: 'run-other', validUntil: validUntil),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceRunMismatch,
          integrityValid: true,
        ),
        'unpersisted evidence': (
          evidence: _observation(persisted: false, validUntil: validUntil),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceNotPersisted,
          integrityValid: true,
        ),
        'invalid ledger digest': (
          evidence: _observation(validUntil: validUntil),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceIntegrityInvalid,
          integrityValid: false,
        ),
        'calculation used for weather': (
          evidence: _calculation(),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceKindMismatch,
          integrityValid: true,
        ),
        'wrong tool capability': (
          evidence: _observation(
            capabilities: const {ToolCapability.localRead},
            validUntil: validUntil,
          ),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceCapabilityMismatch,
          integrityValid: true,
        ),
        'wrong subject': (
          evidence: _observation(
            subject: 'file:metadata',
            validUntil: validUntil,
          ),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceSubjectMismatch,
          integrityValid: true,
        ),
        'wrong scope': (
          evidence: _observation(
            scope: const {'city': 'Shanghai'},
            validUntil: validUntil,
          ),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceScopeMismatch,
          integrityValid: true,
        ),
        'future observation': (
          evidence: _observation(
            observedAt: now.add(const Duration(minutes: 1)),
            validUntil: now.add(const Duration(hours: 1)),
          ),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceNotYetObserved,
          integrityValid: true,
        ),
        'current evidence without validity window': (
          evidence: _observation(
            capabilities: const {ToolCapability.localRead},
          ),
          claim: _claim(),
          requirement: _weatherRequirement(
            requiredCapabilities: const {ToolCapability.localRead},
          ),
          reason: EvidenceRejectionReason.evidenceValidityMissing,
          integrityValid: true,
        ),
        'expired evidence': (
          evidence: _observation(
            observedAt: now.subtract(const Duration(hours: 2)),
            validUntil: now,
          ),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceExpired,
          integrityValid: true,
        ),
        'missing required structured fact': (
          evidence: _observation(
            factName: 'weather.humidity',
            validUntil: validUntil,
          ),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceEmpty,
          integrityValid: true,
        ),
        'missing application requirement': (
          evidence: _observation(validUntil: validUntil),
          claim: _claim(),
          requirement: null,
          reason: EvidenceRejectionReason.claimRequirementMissing,
          integrityValid: true,
        ),
      };

      for (final entry in cases.entries) {
        final result = await _validate(
          evidence: entry.value.evidence,
          now: now,
          claim: entry.value.claim,
          requirement: entry.value.requirement,
          integrityValid: entry.value.integrityValid,
        );

        expect(
          result.trustLevel,
          AnswerTrustLevel.unverified,
          reason: entry.key,
        );
        expect(
          result.claims.single.issues.single.reason,
          entry.value.reason,
          reason: entry.key,
        );
      }
    });

    test(
      'calculation cannot support weather, file, or network facts',
      () async {
        final cases = <ClaimEvidenceRequirement>[
          _weatherRequirement(),
          ClaimEvidenceRequirement(
            claimId: 'claim-1',
            allowedEvidenceKinds: const {EvidenceKind.observation},
            subject: 'file:metadata',
            scope: const {'path': '/tmp/report.txt'},
            requiredCapabilities: const {ToolCapability.localRead},
            requiredFactNames: const {'file.exists'},
          ),
          ClaimEvidenceRequirement(
            claimId: 'claim-1',
            allowedEvidenceKinds: const {EvidenceKind.observation},
            subject: 'web:search',
            scope: const {'query': 'Stars'},
            requiredCapabilities: const {ToolCapability.network},
            requiredFactNames: const {'web.source'},
          ),
        ];

        for (final requirement in cases) {
          final result = await _validate(
            evidence: _calculation(),
            now: now,
            claim: _claim(),
            requirement: requirement,
          );
          expect(result.trustLevel, AnswerTrustLevel.unverified);
          expect(
            result.claims.single.issues.single.reason,
            EvidenceRejectionReason.evidenceKindMismatch,
          );
        }
      },
    );

    test(
      'calculation and action receipts support only matching claims',
      () async {
        final calculation = await _validate(
          evidence: _calculation(),
          now: now,
          claim: _claim(kind: ClaimKind.externalFact),
          requirement: ClaimEvidenceRequirement(
            claimId: 'claim-1',
            allowedEvidenceKinds: const {EvidenceKind.calculation},
            subject: 'calculation:basic-arithmetic',
            scope: const {'expression': '2+2'},
            requiredCapabilities: const {ToolCapability.compute},
            requiredFactNames: const {'calculation.result'},
          ),
        );
        final action = await _validate(
          evidence: _actionReceipt(),
          now: now,
          claim: _claim(kind: ClaimKind.completedAction),
          requirement: ClaimEvidenceRequirement(
            claimId: 'claim-1',
            allowedEvidenceKinds: const {EvidenceKind.actionReceipt},
            subject: 'weather:current',
            scope: const {'city': 'Beijing'},
            requiredCapabilities: const {ToolCapability.externalWrite},
            requiredFactNames: const {'action.accepted'},
          ),
        );

        expect(calculation.trustLevel, AnswerTrustLevel.verified);
        expect(action.trustLevel, AnswerTrustLevel.verified);
      },
    );

    test('error evidence can only support execution failure', () async {
      final failure = _failure();
      final rejected = await _validate(
        evidence: failure,
        now: now,
        claim: _claim(),
        requirement: _weatherRequirement(),
      );
      final accepted = await _validate(
        evidence: failure,
        now: now,
        claim: _claim(kind: ClaimKind.executionFailure),
        requirement: ClaimEvidenceRequirement(
          claimId: 'claim-1',
          allowedEvidenceKinds: const {EvidenceKind.executionFailure},
          toolName: 'weather.read',
          attemptId: failure.attemptId,
        ),
      );

      expect(rejected.trustLevel, AnswerTrustLevel.unverified);
      expect(
        rejected.claims.single.issues.single.reason,
        EvidenceRejectionReason.executionFailureEvidenceMismatch,
      );
      expect(accepted.trustLevel, AnswerTrustLevel.verified);
    });

    test('fails closed for claim-level and ledger-level omissions', () async {
      final failure = _failure();
      final cases = <
        String,
        ({
          _FakeEvidenceRepository repository,
          AnswerClaim claim,
          ClaimEvidenceRequirement? requirement,
          EvidenceRejectionReason reason,
        })
      >{
        'claim has no evidence': (
          repository: _FakeEvidenceRepository(const []),
          claim: AnswerClaim(
            claimId: 'claim-1',
            text: 'Beijing is 25 degrees now.',
            kind: ClaimKind.currentFact,
          ),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.claimHasNoEvidence,
        ),
        'non-factual claim cites evidence': (
          repository: _FakeEvidenceRepository([failure]),
          claim: _claim(kind: ClaimKind.nonFactual),
          requirement: null,
          reason: EvidenceRejectionReason.claimDoesNotAcceptEvidence,
        ),
        'invalid failure requirement': (
          repository: _FakeEvidenceRepository([failure]),
          claim: _claim(kind: ClaimKind.executionFailure),
          requirement: ClaimEvidenceRequirement(
            claimId: 'claim-1',
            allowedEvidenceKinds: const {EvidenceKind.executionFailure},
          ),
          reason: EvidenceRejectionReason.claimRequirementInvalid,
        ),
        'ledger unavailable': (
          repository: _FakeEvidenceRepository(const [], readFailure: true),
          claim: _claim(),
          requirement: _weatherRequirement(),
          reason: EvidenceRejectionReason.evidenceLedgerUnavailable,
        ),
      };

      for (final entry in cases.entries) {
        final result = await GroundedAnswerValidator(
          evidenceRepository: entry.value.repository,
        ).validate(
          runId: 'run-1',
          candidate: GroundedAnswerCandidate(claims: [entry.value.claim]),
          requirements: [
            if (entry.value.requirement != null) entry.value.requirement!,
          ],
          validatedAt: now,
        );

        expect(result.trustLevel, AnswerTrustLevel.unverified);
        expect(
          result.claims.single.issues.single.reason,
          entry.value.reason,
          reason: entry.key,
        );
      }
    });

    test('action receipt cannot support a final state claim', () async {
      final result = await _validate(
        evidence: _actionReceipt(),
        now: now,
        claim: _claim(kind: ClaimKind.currentFact),
        requirement: _weatherRequirement(
          allowedEvidenceKinds: const {EvidenceKind.actionReceipt},
          requiredCapabilities: const {ToolCapability.externalWrite},
        ),
      );

      expect(result.trustLevel, AnswerTrustLevel.unverified);
      expect(
        result.claims.single.issues.single.reason,
        EvidenceRejectionReason.actionReceiptCannotSupportState,
      );
    });

    test('one covered and one uncovered claim is strictly partial', () async {
      final evidence = _observation(
        validUntil: now.add(const Duration(hours: 1)),
      );
      final repository = _FakeEvidenceRepository([evidence]);
      final candidate = GroundedAnswerCandidate(
        claims: [
          _claim(),
          AnswerClaim(
            claimId: 'claim-2',
            text: 'Shanghai is warm.',
            kind: ClaimKind.currentFact,
          ),
        ],
      );

      final result = await GroundedAnswerValidator(
        evidenceRepository: repository,
      ).validate(
        runId: 'run-1',
        candidate: candidate,
        requirements: [_weatherRequirement()],
        validatedAt: now,
      );

      expect(result.trustLevel, AnswerTrustLevel.partiallyVerified);
      expect(result.reasonCode, 'some_claims_verified');
      expect(result.evidenceIds, [evidence.evidenceId]);
      expect(result.claims.map((item) => item.trustLevel), [
        ClaimTrustLevel.verified,
        ClaimTrustLevel.unverified,
      ]);
    });

    test('unreferenced decorative evidence has no trust impact', () async {
      final used = _observation(validUntil: now.add(const Duration(hours: 1)));
      final unused = _observation(
        attemptId: 'attempt-unused',
        runId: 'run-other',
        persisted: false,
        validUntil: now.subtract(const Duration(minutes: 1)),
      );
      final repository = _FakeEvidenceRepository([used, unused]);

      final result = await GroundedAnswerValidator(
        evidenceRepository: repository,
      ).validate(
        runId: 'run-1',
        candidate: GroundedAnswerCandidate(claims: [_claim()]),
        requirements: [_weatherRequirement()],
        validatedAt: now,
      );

      expect(result.trustLevel, AnswerTrustLevel.verified);
      expect(repository.requestedIds, {used.evidenceId});
    });

    test('optional model review can reject but cannot upgrade', () async {
      final valid = _observation(validUntil: now.add(const Duration(hours: 1)));
      final rejectingReviewer = _Reviewer(false);
      final rejected = await _validate(
        evidence: valid,
        now: now,
        claim: _claim(),
        requirement: _weatherRequirement(),
        reviewer: rejectingReviewer,
      );
      final invalid = _calculation();
      final approvingReviewer = _Reviewer(true);
      final notUpgraded = await _validate(
        evidence: invalid,
        now: now,
        claim: _claim(),
        requirement: _weatherRequirement(),
        reviewer: approvingReviewer,
      );

      expect(rejected.trustLevel, AnswerTrustLevel.unverified);
      expect(
        rejected.claims.single.issues.single.reason,
        EvidenceRejectionReason.modelReviewRejected,
      );
      expect(rejectingReviewer.calls, 1);
      expect(notUpgraded.trustLevel, AnswerTrustLevel.unverified);
      expect(approvingReviewer.calls, 0);
    });

    test(
      'non-factual and user assertions never make a message verified',
      () async {
        final repository = _FakeEvidenceRepository(const []);
        final result = await GroundedAnswerValidator(
          evidenceRepository: repository,
        ).validate(
          runId: 'run-1',
          candidate: GroundedAnswerCandidate(
            claims: [
              AnswerClaim(
                claimId: 'claim-1',
                text: 'You prefer dark mode.',
                kind: ClaimKind.userAssertion,
              ),
            ],
            nonFactualText: 'Happy to help.',
          ),
          requirements: const [],
          validatedAt: now,
        );

        expect(result.trustLevel, AnswerTrustLevel.unverified);
        expect(result.reasonCode, 'no_verifiable_claims');
        expect(repository.requestedIds, isEmpty);
      },
    );
  });
}

Future<GroundedAnswerValidationResult> _validate({
  required ToolEvidenceRecord? evidence,
  required DateTime now,
  required AnswerClaim claim,
  required ClaimEvidenceRequirement? requirement,
  bool integrityValid = true,
  ClaimEvidenceReviewer? reviewer,
}) {
  final repository = _FakeEvidenceRepository([
    if (evidence != null) evidence,
  ], integrityValid: integrityValid);
  return GroundedAnswerValidator(
    evidenceRepository: repository,
    reviewer: reviewer,
  ).validate(
    runId: 'run-1',
    candidate: GroundedAnswerCandidate(claims: [claim]),
    requirements: [if (requirement != null) requirement],
    validatedAt: now,
  );
}

AnswerClaim _claim({ClaimKind kind = ClaimKind.currentFact}) => AnswerClaim(
  claimId: 'claim-1',
  text: 'Beijing is 25 degrees now.',
  kind: kind,
  evidenceIds: const ['attempt-1:evidence'],
);

ClaimEvidenceRequirement _weatherRequirement({
  Set<EvidenceKind> allowedEvidenceKinds = const {EvidenceKind.observation},
  Set<ToolCapability> requiredCapabilities = const {ToolCapability.network},
}) => ClaimEvidenceRequirement(
  claimId: 'claim-1',
  allowedEvidenceKinds: allowedEvidenceKinds,
  subject: 'weather:current',
  scope: const {'city': 'Beijing'},
  requiredCapabilities: requiredCapabilities,
  requiredFactNames: const {'weather.temperature'},
);

ToolEvidenceRecord _observation({
  String attemptId = 'attempt-1',
  String runId = 'run-1',
  String subject = 'weather:current',
  Map<String, Object?> scope = const {'city': 'Beijing'},
  Set<ToolCapability> capabilities = const {ToolCapability.network},
  String factName = 'weather.temperature',
  DateTime? observedAt,
  DateTime? validUntil,
  bool persisted = true,
}) => ToolEvidenceRecord(
  evidenceId: ToolEvidenceRecord.evidenceIdForAttempt(attemptId),
  runId: runId,
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'message-1',
  invocationId: 'invocation-1',
  attemptId: attemptId,
  toolName: 'weather.read',
  toolVersion: '1',
  source: ToolSource.builtIn,
  capabilities: capabilities,
  terminalStatus: ToolInvocationStatus.succeeded,
  evidenceKind: EvidenceKind.observation,
  subject: subject,
  scope: scope,
  resultSummary: 'Weather observed.',
  argumentsDigest: _digestA,
  resultDigest: _digestB,
  structuredFacts: [StructuredFact(name: factName, value: 25)],
  observedAt: observedAt ?? DateTime.utc(2026, 9, 5, 11),
  validUntil: validUntil,
  persisted: persisted,
);

ToolEvidenceRecord _calculation() => ToolEvidenceRecord(
  evidenceId: 'attempt-1:evidence',
  runId: 'run-1',
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'message-1',
  invocationId: 'invocation-1',
  attemptId: 'attempt-1',
  toolName: 'calculator',
  toolVersion: '1',
  source: ToolSource.builtIn,
  capabilities: const {ToolCapability.compute},
  terminalStatus: ToolInvocationStatus.succeeded,
  evidenceKind: EvidenceKind.calculation,
  subject: 'calculation:basic-arithmetic',
  scope: const {'expression': '2+2'},
  resultSummary: 'Calculation completed.',
  argumentsDigest: _digestA,
  resultDigest: _digestB,
  structuredFacts: [StructuredFact(name: 'calculation.result', value: 4)],
  observedAt: DateTime.utc(2026, 9, 5, 11),
  persisted: true,
);

ToolEvidenceRecord _actionReceipt() => ToolEvidenceRecord(
  evidenceId: 'attempt-1:evidence',
  runId: 'run-1',
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'message-1',
  invocationId: 'invocation-1',
  attemptId: 'attempt-1',
  toolName: 'weather.update',
  toolVersion: '1',
  source: ToolSource.mcp,
  capabilities: const {ToolCapability.externalWrite},
  terminalStatus: ToolInvocationStatus.succeeded,
  evidenceKind: EvidenceKind.actionReceipt,
  subject: 'weather:current',
  scope: const {'city': 'Beijing'},
  resultSummary: 'Update accepted.',
  argumentsDigest: _digestA,
  resultDigest: _digestB,
  structuredFacts: [StructuredFact(name: 'action.accepted', value: true)],
  observedAt: DateTime.utc(2026, 9, 5, 11),
  persisted: true,
);

ToolEvidenceRecord _failure() => ToolEvidenceRecord(
  evidenceId: 'attempt-1:evidence',
  runId: 'run-1',
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'message-1',
  invocationId: 'invocation-1',
  attemptId: 'attempt-1',
  toolName: 'weather.read',
  toolVersion: '1',
  source: ToolSource.builtIn,
  terminalStatus: ToolInvocationStatus.timedOut,
  evidenceKind: EvidenceKind.executionFailure,
  resultSummary: 'Weather read timed out.',
  argumentsDigest: _digestA,
  resultDigest: _digestB,
  observedAt: DateTime.utc(2026, 9, 5, 11),
  schemaValid: false,
  persisted: true,
  errorCode: 'tool_execution_timed_out',
);

final class _FakeEvidenceRepository implements ToolEvidenceRepository {
  _FakeEvidenceRepository(
    Iterable<ToolEvidenceRecord> records, {
    this.integrityValid = true,
    this.readFailure = false,
  }) : _records = {for (final record in records) record.evidenceId: record};

  final Map<String, ToolEvidenceRecord> _records;
  final bool integrityValid;
  final bool readFailure;
  final Set<String> requestedIds = <String>{};

  @override
  Future<ToolEvidenceRecord?> getById(String evidenceId) async {
    requestedIds.add(evidenceId);
    if (readFailure) throw StateError('ledger unavailable');
    return _records[evidenceId];
  }

  @override
  Future<bool> verifyDigest(String evidenceId) async =>
      integrityValid && _records.containsKey(evidenceId);

  @override
  Future<void> commitRun({
    required String runId,
    required String chatId,
    required List<ToolInvocationEvent> invocationEvents,
    required List<ToolEvidenceRecord> evidenceRecords,
  }) => throw UnimplementedError();

  @override
  Future<List<ToolEvidenceRecord>> getForMessage(String messageId) =>
      throw UnimplementedError();

  @override
  Future<List<ToolInvocationEvent>> getInvocationEventsForRun(String runId) =>
      throw UnimplementedError();
}

final class _Reviewer implements ClaimEvidenceReviewer {
  _Reviewer(this.result);

  final bool result;
  int calls = 0;

  @override
  Future<bool> supports({
    required AnswerClaim claim,
    required ToolEvidenceRecord evidence,
  }) async {
    calls += 1;
    return result;
  }
}

const _digestA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _digestB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
