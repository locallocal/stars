import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/conversation_history_projection.dart';

import '../../support/compose_chat_fixtures.dart';

void main() {
  test('history cannot invent a missing persisted turn identity', () {
    expect(
      () => normalizeConversationHistoryTurns(
        history: [
          fixtureMessage(senderId: 'user-1', content: 'Question', turnId: ''),
          fixtureMessage(senderId: 'bot-1', content: 'Answer', turnId: ''),
        ],
        currentUserId: 'user-1',
      ),
      throwsFormatException,
    );
  });

  test('omits turns without replayable assistant output', () async {
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository(const {}),
      bindingRepository: FixtureFakeBindingRepository(const []),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
      starsSystemPromptProvider: fixtureTestStarsSystemPrompt,
    );

    final result = await compose(
      bot: fixtureBot(),
      history: [
        fixtureMessage(senderId: 'user-1', content: 'Failed question'),
        fixtureMessage(senderId: 'bot-1', content: ''),
      ],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Retry question',
      ),
      currentUserId: 'user-1',
    );

    expect(result.messages.map((message) => message.role), ['system', 'user']);
    expect(result.messages.last.content, 'Retry question');
    expect(
      result.messages.every(
        (message) =>
            message.content.trim().isNotEmpty ||
            message.images.isNotEmpty ||
            message.files.isNotEmpty,
      ),
      isTrue,
    );
  });

  test(
    'fallback isolates unsuccessful and partial history by default',
    () async {
      final compose = ComposeChatTurn(
        skillRepository: FixtureFakeSkillRepository(const {}),
        bindingRepository: FixtureFakeBindingRepository(const []),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        starsSystemPromptProvider: fixtureTestStarsSystemPrompt,
      );
      final history = [
        fixtureMessage(
          messageId: 'user-failed',
          turnId: 'turn-failed',
          senderId: 'user-1',
          content: 'failed question',
        ),
        fixtureMessage(
          messageId: 'assistant-failed',
          turnId: 'turn-failed',
          runId: 'run-failed',
          senderId: 'bot-1',
          content: 'failed secret',
          terminalOutcome: MessageTerminalOutcome.failed,
        ),
        fixtureMessage(
          messageId: 'user-cancelled',
          turnId: 'turn-cancelled',
          senderId: 'user-1',
          content: 'cancelled question',
        ),
        fixtureMessage(
          messageId: 'assistant-cancelled',
          turnId: 'turn-cancelled',
          runId: 'run-cancelled',
          senderId: 'bot-1',
          content: 'cancelled secret',
          terminalOutcome: MessageTerminalOutcome.cancelled,
        ),
        fixtureMessage(
          messageId: 'user-empty',
          turnId: 'turn-empty',
          senderId: 'user-1',
          content: 'empty question',
        ),
        fixtureMessage(
          messageId: 'assistant-empty',
          turnId: 'turn-empty',
          runId: 'run-empty',
          senderId: 'bot-1',
          content: 'empty response secret',
          terminalOutcome: MessageTerminalOutcome.emptyResponse,
        ),
        fixtureMessage(
          messageId: 'user-partial',
          turnId: 'turn-partial',
          senderId: 'user-1',
          content: 'partial question',
        ),
        fixtureMessage(
          messageId: 'assistant-partial',
          turnId: 'turn-partial',
          runId: 'run-partial',
          senderId: 'bot-1',
          content: 'partial secret',
          terminalOutcome: MessageTerminalOutcome.completed,
          hasPartialContent: true,
        ),
        fixtureMessage(
          messageId: 'user-completed',
          turnId: 'turn-completed',
          senderId: 'user-1',
          content: 'completed question',
        ),
        fixtureMessage(
          messageId: 'assistant-completed',
          turnId: 'turn-completed',
          runId: 'run-completed',
          senderId: 'bot-1',
          content: 'completed answer',
          terminalOutcome: MessageTerminalOutcome.completed,
        ),
      ];

      final result = await compose(
        bot: fixtureBot(),
        history: history,
        userMessage: fixtureMessage(
          messageId: 'current',
          turnId: 'turn-current',
          senderId: 'user-1',
          content: 'follow-up',
        ),
        currentUserId: 'user-1',
      );

      expect(result.messages.map((message) => message.role), [
        'system',
        'user',
        'assistant',
        'user',
      ]);
      final serialized = result.messages
          .map((message) => message.content)
          .join('\n');
      expect(serialized, isNot(contains('failed secret')));
      expect(serialized, isNot(contains('cancelled secret')));
      expect(serialized, isNot(contains('empty response secret')));
      expect(serialized, isNot(contains('partial secret')));
      final assistant = result.messages.singleWhere(
        (message) => message.role == 'assistant',
      );
      expect(assistant.content, contains('<assistant_history_output'));
      expect(assistant.content, contains('run_id="run-completed"'));
      expect(assistant.content, contains('terminal="completed"'));
      expect(assistant.content, contains('trust="unverified"'));
    },
  );
}
