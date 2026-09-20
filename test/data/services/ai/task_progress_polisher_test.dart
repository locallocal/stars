import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/ai/task_progress_polisher.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_progress.dart';
import '../../../support/foreground_turn_fixtures.dart';

void main() {
  late ForegroundProvider provider;
  late TaskProgressPolisherFactory factory;
  late _Bots bots;
  late ForegroundProviders providers;
  final summary = ConversationTaskProgressSummary(
    taskId: 'task-1',
    chatId: 'chat-1',
    title: 'Report',
    status: ConversationTaskStatus.queued,
    phase: ConversationTaskPhase.planning,
    planRevision: 1,
    summaryRevision: 0,
    updatedAt: foregroundTime,
    progress: TaskProgress(
      totalSteps: 5,
      lastMeaningfulProgressAt: foregroundTime,
    ),
  );
  setUp(() {
    bots = _Bots(foregroundBot());
    provider = ForegroundProvider(
      bots.bot!,
      events: () => const Stream.empty(),
    );
    providers = ForegroundProviders((_) => provider);
    factory = TaskProgressPolisherFactory(bots: bots, providers: providers);
  });
  test(
    'isolated session requests free prose from sanitized facts and question',
    () async {
      final narrate = NarrateConversationTaskProgress();
      const expected = 'The report is queued; work has not started yet.';
      provider.events =
          () => Stream.fromIterable([
            const TextDelta(expected),
            const ReasoningDelta('private reasoning'),
            const ModelTurnCompleted(),
          ]);
      expect(
        await narrate(
          chatId: 'chat-1',
          summaries: [summary],
          question: 'Has the report started?',
          language: 'en',
          polish: factory.forBot('bot-1'),
        ),
        expected,
      );
      expect(bots.refreshed, isTrue);
      expect(providers.conversationScopes, ['chat-1']);
      final session = provider.sessions.single;
      expect(session.request.tools, isEmpty);
      expect(session.request.options.webSearch, isFalse);
      expect(session.request.options.deepThinking, isFalse);
      expect(session.request.messages, hasLength(2));
      expect(
        session.request.options.requestTimeout,
        const Duration(seconds: 15),
      );
      final prompt = session.request.messages.first.content;
      expect(prompt, contains('plain, natural words'));
      expect(prompt, contains('does not mean the whole task succeeded'));
      expect(prompt, isNot(contains('allowedNarrations')));
      final payload =
          jsonDecode(session.request.messages.last.content)
              as Map<String, dynamic>;
      expect(payload['question'], 'Has the report started?');
      expect(payload['tasks'], hasLength(1));
      expect(payload.containsKey('allowedNarrations'), isFalse);
      expect(
        session.request.messages.map((m) => m.content).join(),
        isNot(contains(bots.bot!.apiKey)),
      );
      expect(session.closed, isTrue);
    },
  );
  test(
    'native or local tool calls are rejected without any execution',
    () async {
      provider.events =
          () => Stream.fromIterable([
            ToolCallRequested(callId: 'x', name: 'write_file', arguments: {}),
            const ModelTurnCompleted(),
          ]);
      final narrate = NarrateConversationTaskProgress();
      await expectLater(
        narrate(
          chatId: 'chat-1',
          summaries: [summary],
          question: 'Has the report started?',
          language: 'en',
          polish: factory.forBot('bot-1'),
        ),
        throwsA(isA<TaskProgressNarrationException>()),
      );
      expect(narrate.metrics.failures, 1);
      expect(provider.sessions.single.closed, isTrue);
    },
  );
  test(
    'stalled session is cancelled and closed without waiting for EOF',
    () async {
      final stream = StreamController<ModelEvent>();
      addTearDown(stream.close);
      provider.events = () => stream.stream;
      final narrate = NarrateConversationTaskProgress(
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        narrate(
          chatId: 'chat-1',
          summaries: [summary],
          question: 'Has the report started?',
          language: 'en',
          polish: factory.forBot('bot-1'),
        ),
        throwsA(isA<TaskProgressNarrationException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(provider.sessions.single.closed, isTrue);
      expect(provider.sessions.single.cancellations, 1);
    },
  );
  test('missing bot fails without opening a provider', () async {
    bots.bot = null;
    final narrate = NarrateConversationTaskProgress();
    await expectLater(
      narrate(
        chatId: 'chat-1',
        summaries: [summary],
        question: 'Has the report started?',
        language: 'zh-CN',
        polish: factory.forBot('bot-1'),
      ),
      throwsA(isA<TaskProgressNarrationException>()),
    );
    expect(provider.sessions, isEmpty);
    expect(narrate.metrics.failures, 1);
  });
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
