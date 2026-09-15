import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/ai/task_terminal_polisher.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_terminal.dart';

import '../../../support/foreground_turn_fixtures.dart';
import '../../../support/conversation_task_fixtures.dart';

void main() {
  late Bot bot;
  late ForegroundProvider provider;
  late _Bots bots;
  late ConversationTask task;
  late TaskTerminalPolisherFactory factory;
  setUp(() {
    bot = foregroundBot();
    bots = _Bots(bot);
    provider = ForegroundProvider(bot, events: () => const Stream.empty());
    factory = TaskTerminalPolisherFactory(
      bots: bots,
      providers: ForegroundProviders((_) => provider),
    );
    final accepted = taskAcceptance();
    task = taskFixture(
      acceptance: TaskAcceptanceSnapshot(
        providerId: bot.apiType,
        modelId: bot.model,
        configurationDigest: taskProviderConfigurationDigest(bot),
        language: 'zh-CN',
        context: [
          TaskContextMessage(
            role: TaskContextRole.user,
            content: 'private conversation history',
          ),
        ],
        allowedToolNames: {'read_file'},
        verification: accepted.verification,
        segmentLimits: accepted.segmentLimits,
      ),
    );
  });

  test(
    'terminal Provider sees safe summary only and cannot invoke tools',
    () async {
      final narrator = NarrateConversationTaskTerminal();
      final summary = taskTerminal(ConversationTaskStatus.failed);
      final expected = narrator.policy.alternatives(summary, 'zh-CN').last;
      provider.events =
          () => Stream.fromIterable([
            const ReasoningDelta('private reasoning'),
            TextDelta(expected),
            const ModelTurnCompleted(stopReason: 'stop'),
          ]);
      final result = await narrator(
        summary: summary,
        language: 'zh-CN',
        polish: factory.forTask(task),
      );
      expect(result.usedFallback, isFalse);
      expect(bots.refreshed, isTrue);
      final session = provider.sessions.single;
      expect(session.request.tools, isEmpty);
      expect(
        session.request.messages.map((m) => m.content).join(),
        isNot(contains('private conversation history')),
      );
      expect(result.text, isNot(contains('private reasoning')));
      expect(session.closed, isTrue);
    },
  );

  test(
    'tool or malformed Provider output falls back with one closed session',
    () async {
      provider.events =
          () => Stream.fromIterable([
            ToolCallRequested(
              callId: 'native',
              name: 'write_file',
              arguments: {},
            ),
            const ModelTurnCompleted(stopReason: 'stop'),
          ]);
      final narrator = NarrateConversationTaskTerminal();
      final result = await narrator(
        summary: taskTerminal(ConversationTaskStatus.failed),
        language: 'zh-CN',
        polish: factory.forTask(task),
      );
      expect(result.usedFallback, isTrue);
      expect(provider.sessions, hasLength(1));
      expect(provider.sessions.single.closed, isTrue);
    },
  );

  test(
    'missing bot resolves to local narration without any Provider request',
    () async {
      bots.bot = null;
      final result = await NarrateConversationTaskTerminal()(
        summary: taskTerminal(ConversationTaskStatus.cancelled),
        language: 'zh-CN',
        polish: factory.forTask(task),
      );
      expect(result.usedFallback, isTrue);
      expect(provider.sessions, isEmpty);
    },
  );

  test(
    'deadline closes and cancels stalled Provider session without waiting for EOF',
    () async {
      final events = StreamController<ModelEvent>();
      addTearDown(events.close);
      provider.events = () => events.stream;
      final result = await NarrateConversationTaskTerminal(
        timeout: const Duration(milliseconds: 10),
      )(
        summary: taskTerminal(ConversationTaskStatus.failed),
        language: 'zh-CN',
        polish: factory.forTask(task),
      );
      await Future<void>.delayed(Duration.zero);
      expect(result.usedFallback, isTrue);
      expect(provider.sessions.single.closed, isTrue);
      expect(provider.sessions.single.cancellations, 1);
    },
  );
}

final class _Bots implements BotRepository {
  _Bots(this.bot);
  Bot? bot;
  bool refreshed = false;
  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async {
    refreshed = forceRefresh;
    return [if (bot != null) bot!];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
