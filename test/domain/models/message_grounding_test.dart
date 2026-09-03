import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('MessageGrounding', () {
    test('defaults assistant messages to unverified without evidence', () {
      final message = _message();

      expect(
        message.grounding.protocolVersion,
        MessageGrounding.currentProtocolVersion,
      );
      expect(message.grounding.trustLevel, AnswerTrustLevel.unverified);
      expect(message.grounding.reasonCode, isEmpty);
      expect(message.grounding.evidenceIds, isEmpty);
    });

    test('defensively copies evidence ids and exposes an immutable list', () {
      final evidenceIds = <String>['evidence-1'];
      final grounding = MessageGrounding(
        trustLevel: AnswerTrustLevel.verified,
        evidenceIds: evidenceIds,
      );

      evidenceIds.add('evidence-2');

      expect(grounding.evidenceIds, ['evidence-1']);
      expect(
        () => grounding.evidenceIds.add('evidence-3'),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid protocol and evidence identities', () {
      expect(() => MessageGrounding(protocolVersion: -1), throwsArgumentError);
      expect(
        () => MessageGrounding(evidenceIds: const ['']),
        throwsArgumentError,
      );
      expect(
        () => MessageGrounding(evidenceIds: const ['evidence-1', 'evidence-1']),
        throwsArgumentError,
      );
    });

    test('requires evidence for verified and partially verified states', () {
      for (final trustLevel in const [
        AnswerTrustLevel.verified,
        AnswerTrustLevel.partiallyVerified,
      ]) {
        expect(
          () => MessageGrounding(trustLevel: trustLevel),
          throwsArgumentError,
          reason: '$trustLevel must not exist without evidence',
        );
      }
    });

    test('copyWith preserves the source and copies replacement evidence', () {
      final original = MessageGrounding(
        trustLevel: AnswerTrustLevel.verified,
        reasonCode: 'all_claims_grounded',
        evidenceIds: const ['evidence-1'],
      );
      final replacementIds = <String>['evidence-2'];

      final updated = original.copyWith(
        trustLevel: AnswerTrustLevel.partiallyVerified,
        reasonCode: 'some_claims_ungrounded',
        evidenceIds: replacementIds,
      );
      replacementIds.add('evidence-3');

      expect(original.trustLevel, AnswerTrustLevel.verified);
      expect(original.reasonCode, 'all_claims_grounded');
      expect(original.evidenceIds, ['evidence-1']);
      expect(updated.trustLevel, AnswerTrustLevel.partiallyVerified);
      expect(updated.reasonCode, 'some_claims_ungrounded');
      expect(updated.evidenceIds, ['evidence-2']);
    });
  });

  group('Message grounding invariants', () {
    test('validates every terminal outcome and trust level combination', () {
      const terminalOutcomes = <MessageTerminalOutcome?>[
        null,
        ...MessageTerminalOutcome.values,
      ];

      for (final terminalOutcome in terminalOutcomes) {
        for (final trustLevel in AnswerTrustLevel.values) {
          final shouldBeValid =
              terminalOutcome == null ||
              terminalOutcome == MessageTerminalOutcome.completed ||
              trustLevel == AnswerTrustLevel.unverified ||
              trustLevel == AnswerTrustLevel.failed;
          Message build() => _message(
            terminalOutcome: terminalOutcome,
            grounding: _grounding(trustLevel),
          );

          if (shouldBeValid) {
            expect(
              build,
              returnsNormally,
              reason: '$terminalOutcome must allow $trustLevel',
            );
          } else {
            expect(
              build,
              throwsArgumentError,
              reason: '$terminalOutcome must reject $trustLevel',
            );
          }
        }
      }
    });

    test('completed and trust state remain independent during copyWith', () {
      final original = _message(
        terminalOutcome: MessageTerminalOutcome.completed,
        grounding: _grounding(AnswerTrustLevel.unverified),
      );

      final verified = original.copyWith(
        content: 'Verified answer',
        grounding: _grounding(AnswerTrustLevel.verified),
      );

      expect(original.content, 'Answer');
      expect(original.grounding.trustLevel, AnswerTrustLevel.unverified);
      expect(verified.content, 'Verified answer');
      expect(verified.terminalOutcome, MessageTerminalOutcome.completed);
      expect(verified.grounding.trustLevel, AnswerTrustLevel.verified);
    });

    test('copyWith rejects a verified failed terminal state', () {
      final message = _message(
        terminalOutcome: MessageTerminalOutcome.completed,
        grounding: _grounding(AnswerTrustLevel.verified),
      );

      expect(
        () => message.copyWith(terminalOutcome: MessageTerminalOutcome.failed),
        throwsArgumentError,
      );
    });
  });
}

MessageGrounding _grounding(AnswerTrustLevel trustLevel) => MessageGrounding(
  trustLevel: trustLevel,
  evidenceIds:
      trustLevel == AnswerTrustLevel.verified ||
              trustLevel == AnswerTrustLevel.partiallyVerified
          ? const ['evidence-1']
          : const [],
);

Message _message({
  MessageTerminalOutcome? terminalOutcome,
  MessageGrounding grounding = const MessageGrounding.unverified(),
}) => Message(
  messageId: 'message-1',
  turnId: 'turn-1',
  runId: 'run-1',
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'bot-1',
  content: 'Answer',
  terminalOutcome: terminalOutcome,
  grounding: grounding,
  timestamp: DateTime(2026),
);
