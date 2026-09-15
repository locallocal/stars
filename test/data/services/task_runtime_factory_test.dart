import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/services/task_runtime_factory.dart';
import 'package:stars/data/services/task_tool_adapters.dart';
import 'package:stars/data/services/tools/built_in_tools.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import '../../support/foreground_turn_fixtures.dart';
import '../../support/task_scheduler_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  late _Bots bots;
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
    bots = _Bots(foregroundBot(parameters: {}));
  });
  tearDown(() => h.close());
  ConversationTask task({Set<String> tools = const {'calculate'}}) =>
      taskFixture(
        acceptance: TaskAcceptanceSnapshot(
          providerId: bots.bot!.apiType,
          modelId: bots.bot!.model,
          configurationDigest: taskProviderConfigurationDigest(bots.bot!),
          language: 'zh-CN',
          context: taskAcceptance().context,
          allowedToolNames: tools,
          verification: taskAcceptance().verification,
          segmentLimits: TaskSegmentLimits(),
        ),
      );
  TaskRuntimeFactory runtime({
    Map<String, TaskToolAdapter> adapters = const {},
    List<Bot>? seen,
  }) => TaskRuntimeFactory(
    tasks: h.repository,
    bots: bots,
    providers: ForegroundProviders((bot) {
      seen?.add(bot);
      return ForegroundProvider(bot, events: () => const Stream.empty());
    }),
    registry: StaticToolRegistry(createBuiltInTools()),
    policy: RunnerPolicy(),
    adapters: adapters,
  );

  test(
    'each segment resolves fresh credentials without copying keys into durable acceptance',
    () async {
      final accepted = task();
      committed(await h.accept(task: accepted));
      final seen = <Bot>[];
      final factory = runtime(seen: seen);
      await factory.resolve(accepted);
      bots.bot = BotRecord.fromDomain(
        bots.bot!,
        storedApiKey: '',
      ).toDomain(apiKey: 'rotated-secret');
      await factory.resolve(accepted);
      expect(bots.refreshes, 2);
      expect(seen.map((bot) => bot.apiKey), [
        'test-credential-not-persisted',
        'rotated-secret',
      ]);
      final facts = jsonEncode(await h.facts());
      expect(facts, isNot(contains('rotated-secret')));
      expect(facts, isNot(contains('test-credential-not-persisted')));
    },
  );

  test(
    'missing bot, unavailable provider and missing key produce actionable safe reasons',
    () async {
      final accepted = task();
      final original = bots.bot!;
      bots.bot = null;
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.code,
            'code',
            TaskReasonCode.botUnavailable,
          ),
        ),
      );
      bots.bot = foregroundBot(model: 'different-model');
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.code,
            'code',
            TaskReasonCode.providerUnavailable,
          ),
        ),
      );
      bots.bot = BotRecord.fromDomain(
        original,
        storedApiKey: '',
      ).toDomain(apiKey: '');
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.reason,
            'reason',
            TaskWaitingReason.authentication,
          ),
        ),
      );
      bots.failure = StateError('Bearer private-credential');
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.code,
            'safe code',
            TaskReasonCode.missingCredentials,
          ),
        ),
      );
    },
  );

  test(
    'an unaudited dynamic tool cannot silently inherit durable argument permission',
    () async {
      final accepted = task(tools: {'dynamic_tool'});
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.code,
            'code',
            TaskReasonCode.invalidPlan,
          ),
        ),
      );
    },
  );

  test(
    'queued cancellation resolves without the bot, key or provider',
    () async {
      final accepted = task();
      committed(await h.accept(task: accepted));
      final cancelling = committed(
        await h.repository.requestCancellation(
          taskId: accepted.taskId,
          expectedRevision: 0,
          source: TaskCancellationSource.user,
          requestedAt: taskTime,
        ),
      );
      bots.bot = null;
      bots.failure = StateError('must not load missing configuration');
      await runtime().resolve(cancelling);
      expect(bots.refreshes, 0);
    },
  );

  test(
    'job adapter recovers a lost start response by lookup and polls the same job',
    () async {
      final runner = TaskRunnerHarness();
      await runner.open();
      addTearDown(runner.close);
      final client = _JobClient(runner.clock);
      final adapter = JobTaskToolAdapter(
        definition: RunnerTool(risk: ToolRiskLevel.write).definition,
        client: client,
        checkpointArgumentNames: {},
      );
      runner.models.tool();
      runner.models.completeStep();
      runner.models.candidate();
      final scheduler = createRunnerScheduler(
        runner,
        resolve:
            (_) async =>
                ConversationTaskRunner(
                  repository: runner.db.repository,
                  sessions: runner.models.open,
                  tools: [adapter],
                  policy: runner.policy,
                  clock: runner.clock,
                  jitter: () => 0.5,
                ).run,
      );
      addTearDown(scheduler.stop);
      await scheduler.start(periodic: false);
      await until(
        () async =>
            (await runner.db.task).nextRunAt != null &&
            scheduler.runningCount == 0,
      );
      await runner.advanceToDue();
      await scheduler.tick();
      await scheduler.tick();
      await until(
        () async =>
            (await runner.snapshot).checkpoint!.externalJobs.isNotEmpty &&
            scheduler.runningCount == 0,
      );
      await runner.advanceToDue();
      await scheduler.tick();
      await scheduler.tick();
      await until(
        () async =>
            (await runner.db.task).phase == ConversationTaskPhase.committing &&
            scheduler.runningCount == 0,
      );
      expect(client.starts, 1);
      expect(client.lookups, 1);
      expect(client.polls, 1);
      expect(client.keys.toSet(), hasLength(1));
      expect(adapter.guaranteesIdempotency, isFalse);
      final job = TaskExternalJob(
        attemptId: 'attempt',
        externalJobId: 'existing',
        resumeHandle: 'handle:existing',
        safeStatus: 'running',
        nextPollAt: runner.clock.now(),
      );
      expect(
        await adapter.cancel(job, AgentCancellationToken()),
        isA<ToolOutcomeUnknown>(),
      );
      expect(client.cancels, 1);
    },
  );
}

class _Bots implements BotRepository {
  _Bots(this.bot);
  Bot? bot;
  Object? failure;
  int refreshes = 0;
  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async {
    expect(forceRefresh, isTrue);
    refreshes++;
    if (failure case final error?) throw error;
    return [if (bot != null) bot!];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _JobClient implements TaskJobClient {
  _JobClient(this.clock);
  final RunnerClock clock;
  int starts = 0, lookups = 0, polls = 0, cancels = 0;
  final keys = <String>[];
  @override
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String key,
    AgentCancellationToken token,
  ) async {
    starts++;
    keys.add(key);
    throw TimeoutException('job created; response lost');
  }

  @override
  Future<ToolReconciliation> lookup(
    ToolCallRequest call,
    String key,
    TaskExternalJob? job,
    AgentCancellationToken token,
  ) async {
    lookups++;
    keys.add(key);
    return ToolReconciled(
      ToolJobStarted(
        externalJobId: 'existing',
        resumeHandle: 'handle:existing',
        safeStatus: 'running',
        nextPollAt: clock.now().add(const Duration(minutes: 1)),
      ),
    );
  }

  @override
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) async {
    expect(job.externalJobId, 'existing');
    polls++;
    return ToolCompleted(
      ToolResult(callId: 'provider-call', name: 'read_file', content: 'Done'),
    );
  }

  @override
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) async {
    cancels++;
    return const ToolOutcomeUnknown();
  }
}
