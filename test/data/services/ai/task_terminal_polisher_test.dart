import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/ai/task_terminal_polisher.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import 'package:stars/domain/services/task_terminal_context.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_terminal.dart';

import '../../../support/foreground_turn_fixtures.dart';
import '../../../support/conversation_task_fixtures.dart';
import '../../../support/conversation_task_repository_harness.dart'
    show taskTool;

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
            content: '请读取 sales.xlsx，按地区汇总',
          ),
        ],
        allowedToolNames: {'read_file'},
        verification: accepted.verification,
        segmentLimits: accepted.segmentLimits,
      ),
    );
  });

  test(
    'terminal Provider uses redacted context and errors to write a natural reply',
    () async {
      final narrator = NarrateConversationTaskTerminal();
      final summary = taskTerminal(ConversationTaskStatus.failed);
      const expected = '销售汇总没能生成：没有找到你指定的 sales.xlsx。请确认文件位置。';
      final context = taskTerminalContext(
        TaskExecutionSnapshot(
          task: task,
          plan: taskPlan(task),
          lastSequence: 1,
          attempts: [
            taskTool(
              at: taskTime,
              status: ToolInvocationStatus.failed,
              arguments: '{"path":"sales.xlsx","api_key":"private-value"}',
              summary: 'File not found: sales.xlsx',
            ),
          ],
        ),
      );
      final usages = <ModelTokenUsage>[];
      provider.events =
          () => Stream.fromIterable([
            const ReasoningDelta('private reasoning'),
            GroundedAnswerProduced(
              GroundedAnswerCandidate(nonFactualText: expected),
            ),
            const ModelTurnCompleted(stopReason: 'stop'),
            const UsageReported(
              ModelTokenUsage(inputTokens: 120, outputTokens: 15),
            ),
          ]);
      final result = await narrator(
        summary: summary,
        language: 'zh-CN',
        context: context,
        polish: factory.forTask(task),
        onTokenUsage: usages.add,
      );
      expect(result.usedFallback, isFalse);
      expect(usages.single.inputTokens, 120);
      expect(usages.single.outputTokens, 15);
      expect(bots.refreshed, isTrue);
      final session = provider.sessions.single;
      expect(session.request.tools, isEmpty);
      expect(session.syntheses, hasLength(1));
      expect(
        session.request.options.requestTimeout,
        const Duration(seconds: 15),
      );
      expect(
        session.request.messages.map((m) => m.content).join(),
        contains('请读取 sales.xlsx，按地区汇总'),
      );
      expect(
        session.request.messages.last.content,
        contains('File not found: sales.xlsx'),
      );
      expect(
        session.request.messages.last.content,
        isNot(contains('private-value')),
      );
      expect(
        session.request.messages.last.content,
        isNot(contains('allowed_narrations')),
      );
      expect(result.text, expected);
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
