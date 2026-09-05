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

  test('drops an assistant fact that has no verified claim evidence', () async {
    final provider = _SummaryProvider(
      response: _factResponse(
        sourceId: 'assistant-1',
        claimReference: 'assistant-1#claim-missing',
      ),
    );
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
        evaluatedAt: DateTime.utc(2026, 9, 5, 12),
      ),
    );

    expect(result.items, isEmpty);
    expect(result.markdown, isNot(contains('deployment succeeded')));
    expect(provider.messages.last.content, contains('<claims>'));
    expect(provider.messages.last.content, isNot(contains('tool_grounded')));
  });

  test(
    'keeps only the verified claim from a mixed-trust assistant message',
    () async {
      final provider = _SummaryProvider(
        response: _mixedFactResponse('assistant-1'),
      );
      final sourceEvidence = ContextSourceEvidence(
        messageId: 'assistant-1',
        role: ContextSourceRole.assistant,
        claims: [
          ContextClaimEvidence(
            referenceId: 'assistant-1#claim-verified',
            claimId: 'claim-verified',
            text: 'The deployment succeeded.',
            kind: ClaimKind.externalFact,
            trustLevel: ClaimTrustLevel.verified,
            evidenceIds: const ['attempt-deploy:evidence'],
            evidence: [
              ContextEvidenceSummary(
                evidenceId: 'attempt-deploy:evidence',
                toolName: 'deploy.status',
                source: ToolSource.mcp,
                resultSummary: 'Deployment status is succeeded.',
                observedAt: DateTime.utc(2026, 9, 5, 10, 30),
              ),
            ],
          ),
          ContextClaimEvidence(
            referenceId: 'assistant-1#claim-unverified',
            claimId: 'claim-unverified',
            text: 'Version 42 is live.',
            kind: ClaimKind.externalFact,
            trustLevel: ClaimTrustLevel.unverified,
            evidenceIds: const [],
            evidence: const [],
          ),
        ],
      );
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
          sourceEvidence: [sourceEvidence],
          targetTokens: 500,
          evaluatedAt: DateTime.utc(2026, 9, 5, 12),
        ),
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.memoryKey, 'deployment.status');
      expect(result.items.single.sourceMessageIds, ['assistant-1']);
      expect(result.items.single.sourceClaimIds, [
        'assistant-1#claim-verified',
      ]);
      expect(result.markdown, contains('<!-- sources: assistant-1 -->'));
      expect(
        result.markdown,
        contains('claim: ref=assistant-1#claim-verified'),
      );
      expect(result.markdown, contains('tool=deploy.status'));
      expect(result.markdown, contains('source=mcp'));
      expect(result.markdown, contains('observed_at=2026-09-05T10:30:00.000Z'));
      expect(provider.messages.last.content, contains('trust="verified"'));
      expect(provider.messages.last.content, contains('trust="unverified"'));
      expect(
        provider.messages.last.content,
        contains('Deployment status is succeeded.'),
      );
    },
  );

  test(
    'keeps user input as an assertion but never as an external fact',
    () async {
      final provider = _SummaryProvider(response: _userBoundaryResponse);
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
              messageId: 'user-1',
              chatId: 'chat-1',
              botId: _bot.id,
              senderId: 'user-1',
              content: 'Production is healthy.',
              timestamp: DateTime(2026),
            ),
          ],
          targetTokens: 500,
          evaluatedAt: DateTime.utc(2026, 9, 5, 12),
        ),
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.kind, ConversationMemoryKind.userAssertion);
      expect(result.items.single.content, 'User says production is healthy.');
    },
  );
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
{"schema_version":2,"narrative_summary":"","facts":[],"user_assertions":[],"preferences":[],"decisions":[],"open_tasks":[],"unresolved_questions":[],"corrections":[],"artifact_references":[]}
''';

String _factResponse({
  required String sourceId,
  required String claimReference,
}) => '''
{"schema_version":2,"narrative_summary":"","facts":[{"key":"deployment.status","value":"The deployment succeeded.","confidence":0.9,"importance":0.8,"source_message_ids":["$sourceId"],"source_claim_ids":["$claimReference"]}],"user_assertions":[],"preferences":[],"decisions":[],"open_tasks":[],"unresolved_questions":[],"corrections":[],"artifact_references":[]}
''';

String _mixedFactResponse(String sourceId) => '''
{"schema_version":2,"narrative_summary":"","facts":[{"key":"deployment.status","value":"The deployment succeeded.","confidence":0.9,"importance":0.8,"source_message_ids":["$sourceId"],"source_claim_ids":["$sourceId#claim-verified"]},{"key":"deployment.version","value":"Version 42 is live.","confidence":0.9,"importance":0.8,"source_message_ids":["$sourceId"],"source_claim_ids":["$sourceId#claim-unverified"]}],"user_assertions":[],"preferences":[],"decisions":[],"open_tasks":[],"unresolved_questions":[],"corrections":[],"artifact_references":[]}
''';

const _userBoundaryResponse = '''
{"schema_version":2,"narrative_summary":"","facts":[{"key":"production.health","value":"Production is healthy.","confidence":0.9,"importance":0.8,"source_message_ids":["user-1"],"source_claim_ids":[]}],"user_assertions":[{"key":"production.health.assertion","value":"User says production is healthy.","confidence":0.9,"importance":0.8,"source_message_ids":["user-1"]}],"preferences":[],"decisions":[],"open_tasks":[],"unresolved_questions":[],"corrections":[],"artifact_references":[]}
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
