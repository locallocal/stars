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
    factory = TaskProgressPolisherFactory(
      bots: bots,
      providers: ForegroundProviders((_) => provider),
    );
  });
  test(
    'isolated session sees only sanitized summary, language and grammar',
    () async {
      final narrate = NarrateConversationTaskProgress();
      final expected = narrate.policy.alternatives(summary, 'en').last;
      provider.events =
          () => Stream.fromIterable([
            TextDelta(
              jsonEncode({
                'taskId': summary.taskId,
                'summaryRevision': 0,
                'content': expected,
              }),
            ),
            const ReasoningDelta('private reasoning'),
            const ModelTurnCompleted(),
          ]);
      expect(
        await narrate(
          summary: summary,
          language: 'en',
          polish: factory.forBot('bot-1'),
        ),
        expected,
      );
      expect(bots.refreshed, isTrue);
      final session = provider.sessions.single;
      expect(session.request.tools, isEmpty);
      expect(session.request.options.webSearch, isFalse);
      expect(session.request.options.deepThinking, isFalse);
      expect(session.request.messages, hasLength(2));
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
      final text = await narrate(
        summary: summary,
        language: 'en',
        polish: factory.forBot('bot-1'),
      );
      expect(text, contains('0/5'));
      expect(narrate.metrics.fallbacks, 1);
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
      await narrate(
        summary: summary,
        language: 'en',
        polish: factory.forBot('bot-1'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(provider.sessions.single.closed, isTrue);
      expect(provider.sessions.single.cancellations, 1);
    },
  );
  test('missing bot yields fallback without opening a provider', () async {
    bots.bot = null;
    final narrate = NarrateConversationTaskProgress();
    await narrate(
      summary: summary,
      language: 'zh-CN',
      polish: factory.forBot('bot-1'),
    );
    expect(provider.sessions, isEmpty);
    expect(narrate.metrics.fallbacks, 1);
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
