import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/ai/provider_context_summarizer.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/context_summarizer.dart';
import 'package:stars/domain/services/stars_system_prompt.dart';

void main() {
  test('prepends Stars context to the summarization request', () async {
    final provider = _SummaryProvider();
    final summarizer = ProviderContextSummarizer(
      bot: _bot,
      providerFactory: (_) => provider,
      starsSystemPromptProvider: _testStarsSystemPrompt,
    );

    await summarizer.summarize(
      ContextSummaryRequest(
        chatId: 'chat-1',
        summaryId: 'summary-1',
        sourceMessages: [
          Message(
            messageId: 'message-1',
            chatId: 'chat-1',
            botId: _bot.id,
            senderId: 'user-1',
            content: 'Keep this short.',
            timestamp: DateTime(2026),
          ),
        ],
        targetTokens: 500,
      ),
    );

    expect(provider.messages, hasLength(2));
    expect(provider.messages.first.role, 'system');
    expect(
      provider.messages.first.content,
      startsWith('<stars_application_context>'),
    );
    expect(
      provider.messages.first.content,
      contains('You compress conversation data.'),
    );
    expect(provider.messages.last.role, 'user');
  });

  test(
    'omits Stars context from summaries when injection is disabled',
    () async {
      final provider = _SummaryProvider();
      final summarizer = ProviderContextSummarizer(
        bot: _bot,
        providerFactory: (_) => provider,
        starsSystemPromptProvider: _testStarsSystemPrompt,
        starsSystemPromptEnabledProvider: () async => false,
      );

      await summarizer.summarize(
        ContextSummaryRequest(
          chatId: 'chat-1',
          summaryId: 'summary-1',
          sourceMessages: [
            Message(
              messageId: 'message-1',
              chatId: 'chat-1',
              botId: _bot.id,
              senderId: 'user-1',
              content: 'Keep this short.',
              timestamp: DateTime(2026),
            ),
          ],
          targetTokens: 500,
        ),
      );

      expect(
        provider.messages.first.content,
        isNot(contains('<stars_application_context>')),
      );
      expect(
        provider.messages.first.content,
        startsWith('You compress conversation data.'),
      );
    },
  );

  test('uses the selected language for summary prompt injection', () async {
    final provider = _SummaryProvider();
    final summarizer = ProviderContextSummarizer(
      bot: _bot,
      providerFactory: (_) => provider,
      starsSystemPromptProvider: _testStarsSystemPrompt,
      starsSystemPromptLanguageProvider: () async => 'ja_JP',
    );

    await summarizer.summarize(
      ContextSummaryRequest(
        chatId: 'chat-1',
        summaryId: 'summary-1',
        sourceMessages: [
          Message(
            messageId: 'message-1',
            chatId: 'chat-1',
            botId: _bot.id,
            senderId: 'user-1',
            content: 'Keep this short.',
            timestamp: DateTime(2026),
          ),
        ],
        targetTokens: 500,
      ),
    );

    expect(provider.messages.first.content, contains('アプリケーション: Stars'));
    expect(provider.messages.first.content, contains('選択中の表示言語: 日本語'));
  });

  test(
    'drops an assistant fact that has no successful tool evidence',
    () async {
      final provider = _SummaryProvider(response: _factResponse('assistant-1'));
      final summarizer = ProviderContextSummarizer(
        bot: _bot,
        providerFactory: (_) => provider,
        starsSystemPromptProvider: _testStarsSystemPrompt,
      );

      final result = await summarizer.summarize(
        ContextSummaryRequest(
          chatId: 'chat-1',
          summaryId: 'summary-1',
          sourceMessages: [
            Message(
              messageId: 'assistant-1',
              chatId: 'chat-1',
              botId: _bot.id,
              senderId: _bot.id,
              content: 'The deployment succeeded.',
              terminalOutcome: MessageTerminalOutcome.completed,
              timestamp: DateTime(2026),
            ),
          ],
          targetTokens: 500,
        ),
      );

      expect(result.items, isEmpty);
      expect(result.markdown, isNot(contains('deployment succeeded')));
      expect(provider.messages.last.content, contains('tool_grounded="false"'));
    },
  );

  test('keeps a tool-grounded assistant fact with source provenance', () async {
    final provider = _SummaryProvider(response: _factResponse('assistant-1'));
    final summarizer = ProviderContextSummarizer(
      bot: _bot,
      providerFactory: (_) => provider,
      starsSystemPromptProvider: _testStarsSystemPrompt,
    );

    final result = await summarizer.summarize(
      ContextSummaryRequest(
        chatId: 'chat-1',
        summaryId: 'summary-1',
        sourceMessages: [
          Message(
            messageId: 'assistant-1',
            chatId: 'chat-1',
            botId: _bot.id,
            senderId: _bot.id,
            content: 'The deployment succeeded.',
            processInfo: const MessageProcessInfo(
              toolCalls: [
                MessageToolCall(
                  callId: 'deploy-1',
                  name: 'deploy',
                  status: 'succeeded',
                  resultSummary: 'completed',
                ),
              ],
            ),
            terminalOutcome: MessageTerminalOutcome.completed,
            timestamp: DateTime(2026),
          ),
        ],
        targetTokens: 500,
      ),
    );

    expect(result.items.single.sourceMessageIds, ['assistant-1']);
    expect(result.markdown, contains('<!-- sources: assistant-1 -->'));
    expect(provider.messages.last.content, contains('tool_grounded="true"'));
    expect(provider.messages.last.content, contains('call_id="deploy-1"'));
  });
}

final class _SummaryProvider extends AiProvider {
  _SummaryProvider({this.response = _emptyResponse}) : super(_bot);

  final String response;

  List<ChatMessage> messages = const [];

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
    this.messages = List.unmodifiable(messages);
    onResponse(response);
  }
}

const _emptyResponse = '''
{"schema_version":1,"narrative_summary":"","facts":[],"preferences":[],"decisions":[],"open_tasks":[],"unresolved_questions":[],"corrections":[],"artifact_references":[]}
''';

String _factResponse(String sourceId) => '''
{"schema_version":1,"narrative_summary":"","facts":[{"key":"deployment.status","value":"The deployment succeeded.","confidence":0.9,"importance":0.8,"source_message_ids":["$sourceId"]}],"preferences":[],"decisions":[],"open_tasks":[],"unresolved_questions":[],"corrections":[],"artifact_references":[]}
''';

final _bot = Bot(
  id: 'bot-1',
  name: 'Bot',
  avatar: '',
  provider: 'test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

String _testStarsSystemPrompt(String languageCode) => buildStarsSystemPrompt(
  operatingSystem: 'TestOS',
  operatingSystemVersion: '1.2.3',
  languageCode: languageCode,
);
