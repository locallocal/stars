import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/prepare_conversation_context.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';

import '../../support/foreground_turn_fixtures.dart';

void main() {
  test(
    'foreground retains context without activation or remote model metadata',
    () async {
      final providers = _NoNetworkProviders();
      final compose = ComposeChatTurn(
        skillRepository: _UnusedSkills(),
        bindingRepository: _UnusedBindings(),
        bundledSkillLoader: () => throw StateError('Foreground loaded Skills'),
        conversationArtifactsDirectoryProvider: (id) async => '/data/chats/$id',
        prepareConversationContext: PrepareConversationContext(
          memoryRepository: _Memory(),
          aiProviderRepository: providers,
        ),
      );
      final input = foregroundInput(content: '改写上一句话', files: ['notes.txt']);
      final prepare = PrepareTextGeneration(
        composeChatTurn: compose.call,
        aiProviderRepository: providers,
      );
      final result = await prepare(
        chatId: input.userMessage.chatId,
        bot: input.bot,
        history: [
          foregroundInput(turnId: 'earlier', content: '需要改写的原文').userMessage,
          foregroundInput(turnId: 'earlier').userMessage.copyWith(
            messageId: 'earlier:assistant',
            senderId: 'bot-1',
            content: '已收到原文',
          ),
        ],
        userMessage: input.userMessage,
        currentUserId: input.userMessage.senderId,
        foregroundOnly: true,
      );
      expect(providers.calls, 0);
      expect(result.messages.last.content, '改写上一句话');
      expect(result.messages.last.files, ['notes.txt']);
      expect(
        result.messages.map((message) => message.content).join('\n'),
        contains('需要改写的原文'),
      );
      expect(result.messages.first.content, contains('Be helpful.'));
      expect(result.activatedSkills, isEmpty);
      expect(result.requestedToolNames, isEmpty);
      expect(result.verificationToolNames, isEmpty);
      expect(result.runScopedTools, isEmpty);
      expect(result.preflightTokenUsage, ModelTokenUsage.empty);
    },
  );
}

final class _NoNetworkProviders implements AiProviderRepository {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Foreground made a preflight provider request');
  }
}

final class _UnusedSkills implements SkillRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected skill lookup');
}

final class _UnusedBindings implements BotSkillBindingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected binding lookup');
}

final class _Memory implements ConversationMemoryRepository {
  @override
  Future<ConversationSummaryDocument?> getActiveSummary(String id) async =>
      null;
  @override
  Future<List<ConversationMemoryItem>> getItems(String id) async => [];
  @override
  Future<ConversationMemoryState> getState(String id) async =>
      ConversationMemoryState(chatId: id, updatedAt: foregroundTime);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
