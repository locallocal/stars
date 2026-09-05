import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/strict_grounding_policy.dart';

void main() {
  const policy = StrictGroundingPolicy();

  test('strict mode keeps verified and creative segments but hides facts', () {
    final message = _message(
      content: 'Verified fact.\n\nUnverified fact.\n\nA short poem.',
      grounding: MessageGrounding(
        trustLevel: AnswerTrustLevel.partiallyVerified,
        reasonCode: 'some_claims_verified',
        claims: [
          _claim(
            id: 'verified',
            text: 'Verified fact.',
            trust: ClaimTrustLevel.verified,
            evidenceIds: const ['attempt-1:evidence'],
          ),
          _claim(
            id: 'unverified',
            text: 'Unverified fact.',
            trust: ClaimTrustLevel.unverified,
          ),
          MessageClaimGrounding(
            claim: AnswerClaim(
              claimId: 'creative',
              text: 'A short poem.',
              kind: ClaimKind.nonFactual,
            ),
            trustLevel: ClaimTrustLevel.notVerifiable,
            reasonCode: 'not_fact_checked',
          ),
        ],
      ),
    );

    final result = policy.present(message);

    expect(result.content, 'Verified fact.\n\nA short poem.');
    expect(result.suppressedFacts, isTrue);
    expect(result.hasNotFactCheckedContent, isTrue);
    expect(policy.previewFor(message), strictGroundingPreviewMarker);
  });

  test('strict mode fails closed for legacy content without claim bounds', () {
    final result = policy.present(
      _message(content: 'Possibly factual legacy answer.'),
    );

    expect(result.content, isEmpty);
    expect(result.suppressedFacts, isTrue);
    expect(result.hasNotFactCheckedContent, isFalse);
  });

  test('strict mode never exposes content outside structured claims', () {
    final result = policy.present(
      _message(
        content: 'Verified fact.\n\nUnbounded provider suffix.',
        grounding: MessageGrounding(
          trustLevel: AnswerTrustLevel.verified,
          reasonCode: 'all_claims_verified',
          evidenceIds: const ['attempt-1:evidence'],
          claims: [
            _claim(
              id: 'verified',
              text: 'Verified fact.',
              trust: ClaimTrustLevel.verified,
              evidenceIds: const ['attempt-1:evidence'],
            ),
          ],
        ),
      ),
    );

    expect(result.content, 'Verified fact.');
    expect(result.content, isNot(contains('Unbounded provider suffix.')));
    expect(result.suppressedFacts, isTrue);
  });

  test('declared non-factual content remains visible and marked unchecked', () {
    final message = _message(
      content: 'A fictional story.',
      grounding: MessageGrounding(
        reasonCode: 'no_verifiable_claims',
        claims: [
          MessageClaimGrounding(
            claim: AnswerClaim(
              claimId: 'creative',
              text: 'A fictional story.',
              kind: ClaimKind.nonFactual,
            ),
            trustLevel: ClaimTrustLevel.notVerifiable,
            reasonCode: 'not_fact_checked',
          ),
        ],
      ),
    );

    final result = policy.present(message);

    expect(result.content, message.content);
    expect(result.suppressedFacts, isFalse);
    expect(result.hasNotFactCheckedContent, isTrue);
    expect(policy.previewFor(message), message.content);
  });
}

MessageClaimGrounding _claim({
  required String id,
  required String text,
  required ClaimTrustLevel trust,
  List<String> evidenceIds = const [],
}) => MessageClaimGrounding(
  claim: AnswerClaim(
    claimId: id,
    text: text,
    kind: ClaimKind.currentFact,
    evidenceIds: evidenceIds,
  ),
  trustLevel: trust,
  acceptedEvidenceIds:
      trust == ClaimTrustLevel.verified ? evidenceIds : const [],
  reasonCode:
      trust == ClaimTrustLevel.verified
          ? 'evidence_accepted'
          : 'claimHasNoEvidence',
);

Message _message({
  required String content,
  MessageGrounding grounding = const MessageGrounding.unverified(),
}) => Message(
  messageId: 'message-1',
  turnId: 'turn-1',
  runId: 'run-1',
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'bot-1',
  content: content,
  grounding: grounding,
  terminalOutcome: MessageTerminalOutcome.completed,
  timestamp: DateTime(2026),
);
