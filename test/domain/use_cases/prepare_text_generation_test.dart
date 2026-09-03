import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/mcp_inventory_repository.dart';
import 'package:stars/domain/repositories/skill_inventory_repository.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';

void main() {
  test(
    'prepares a turn through the injected composer and provider factory',
    () async {
      final provider = _FakeProvider(_bot);
      final providers = _FakeProviderRepository(provider);
      AiProvider? composerProvider;
      final useCase = PrepareTextGeneration(
        aiProviderRepository: providers,
        composeChatTurn: ({
          required bot,
          required history,
          required userMessage,
          required currentUserId,
          skillToolProvider,
        }) async {
          expect(bot, same(_bot));
          expect(history, [_historyMessage]);
          expect(userMessage, same(_userMessage));
          expect(currentUserId, 'user-1');
          composerProvider = skillToolProvider;
          return PreparedChatTurn(
            messages: [ChatMessage(role: 'user', content: 'hello')],
            activatedSkills: const [],
            requestedToolNames: const {'unavailable_tool'},
            reliabilityPolicyEnabled: false,
          );
        },
      );

      final result = await useCase(
        chatId: 'chat-1',
        bot: _bot,
        history: [_historyMessage],
        userMessage: _userMessage,
        currentUserId: 'user-1',
      );

      expect(composerProvider, same(provider));
      expect(result.userMessage, same(_userMessage));
      expect(result.messages.single.content, 'hello');
      expect(result.requestedToolNames, {'unavailable_tool'});
      expect(result.runScopedTools, isEmpty);
      expect(result.reliabilityPolicyEnabled, isFalse);
      expect(
        () => result.messages.add(
          ChatMessage(role: 'assistant', content: 'mutate'),
        ),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'adds only requested inventory tools from injected repositories',
    () async {
      final providers = _FakeProviderRepository(_FakeProvider(_bot));
      final useCase = PrepareTextGeneration(
        aiProviderRepository: providers,
        skillInventoryRepository: _UnusedSkillInventoryRepository(),
        mcpInventoryRepository: _UnusedMcpInventoryRepository(),
        composeChatTurn:
            ({
              required bot,
              required history,
              required userMessage,
              required currentUserId,
              skillToolProvider,
            }) async => PreparedChatTurn(
              messages: [],
              activatedSkills: const [],
              requestedToolNames: const {
                listInstalledSkillsToolName,
                listInstalledMcpServersToolName,
              },
            ),
      );

      final result = await useCase(
        chatId: 'chat-1',
        bot: _bot,
        history: const [],
        userMessage: _userMessage,
        currentUserId: 'user-1',
      );

      expect(result.runScopedTools.map((tool) => tool.definition.name), [
        listInstalledSkillsToolName,
        listCurrentConversationSkillsToolName,
        listInstalledMcpServersToolName,
        listCurrentConversationMcpToolName,
      ]);
    },
  );
}

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

final _historyMessage = Message(
  messageId: 'history-1',
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'bot-1',
  content: 'earlier',
  timestamp: DateTime(2026),
);

final _userMessage = Message(
  messageId: 'user-1',
  runId: 'run-1',
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'user-1',
  content: 'hello',
  timestamp: DateTime(2026, 1, 2),
);

final class _FakeProviderRepository implements AiProviderRepository {
  const _FakeProviderRepository(this.provider);

  final AiProvider provider;

  @override
  AiProvider create(Bot bot) => provider;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeProvider extends AiProvider {
  _FakeProvider(super.bot);

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _UnusedSkillInventoryRepository
    implements SkillInventoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedMcpInventoryRepository implements McpInventoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
