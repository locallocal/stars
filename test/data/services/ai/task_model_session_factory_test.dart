import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/data/services/ai/moonshot.dart';
import 'package:stars/data/services/ai/task_model_session_factory.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/provider_failure.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';
import 'package:stars/domain/use_cases/finalize_conversation_task.dart';

import '../../../support/foreground_turn_fixtures.dart';
import '../../../support/task_scheduler_harness.dart';

void main() {
  test(
    'a restored completed plan synthesizes through Moonshot and publishes one result',
    () async {
      final h = TaskRunnerHarness();
      final bot = foregroundBot(
        apiType: 'moonshot',
        provider: 'moonshot',
        model: 'kimi-k3',
      );
      await h.open(
        acceptance: TaskAcceptanceSnapshot(
          providerId: bot.apiType,
          modelId: bot.model,
          configurationDigest: taskProviderConfigurationDigest(bot),
          language: 'zh-CN',
          context: [
            TaskContextMessage(role: TaskContextRole.user, content: '整理思路'),
          ],
          allowedToolNames: {},
          verification: VerificationPolicySnapshot(
            reliabilityEnabled: true,
            strictGroundingEnabled: true,
            showVerificationStatus: true,
          ),
          segmentLimits: TaskSegmentLimits(maxModelTurns: 1),
        ),
      );
      addTearDown(h.close);
      h.models.completeStep();
      expect(await h.run(), isA<TaskContinueSegment>());
      expect((await h.snapshot).checkpoint!.completedStepIds, ['step-0']);
      await h.db.reopen();

      final requests = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        requests.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'schema_version': 1,
                    'claims': [],
                    'non_factual_text': '已整理',
                  }),
                },
                'finish_reason': 'stop',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final sessions = TaskProviderSessionFactory(
        chatId: 'chat-a',
        providers: ForegroundProviders((bot) => Moonshot(bot, client: client)),
        bot: bot,
      );
      final runner = ConversationTaskRunner(
        repository: h.db.repository,
        sessions: sessions.open,
        tools: [],
        policy: h.policy,
        clock: h.clock,
        jitter: () => 0.5,
      );
      var ids = 0;
      final finalizer = FinalizeConversationTask(
        repository: h.db.repository,
        evidenceRepository: SqliteToolEvidenceRepository(
          localDatabase: h.db.local,
        ),
        ownerId: 'finalizer',
        newId: () => 'terminal-${ids++}',
        clock: h.clock,
      );
      final scheduler = createRunnerScheduler(
        h,
        resolve: (_) async => runner.run,
        onReady: finalizer.onReady,
      );
      addTearDown(scheduler.stop);
      await scheduler.start(periodic: false);
      await until(
        () async =>
            scheduler.runningCount == 0 && (await h.db.task).status.isTerminal,
      );
      expect((await h.db.task).status, ConversationTaskStatus.succeeded);
      expect((await h.snapshot).checkpoint!.completedStepIds, ['step-0']);
      expect(h.tool.starts, 0);
      expect(requests, hasLength(1));
      expect(requests.single, isNot(contains('tools')));
      expect(jsonEncode(requests.single), contains('required_claims'));
      h.clock.advance(const Duration(hours: 1));
      await scheduler.tick();
      await finalizer('task-1');
      expect(requests, hasLength(1));
      expect(
        await h.db.database.query(
          'messages',
          where: "task_message_kind = 'taskResult'",
        ),
        hasLength(1),
      );
      expect(
        await h.db.database.query(
          'conversation_task_events',
          where: "kind = 'terminal'",
        ),
        hasLength(1),
      );
    },
  );

  test(
    'matches frozen configuration before opening a fresh provider session',
    () {
      final bot = foregroundBot(
        parameters: {
          'z': 2,
          'a': {'b': 1, 'a': 0},
        },
      );
      final equivalent = foregroundBot(
        parameters: {
          'a': {'a': 0, 'b': 1},
          'z': 2,
        },
      );
      expect(
        taskProviderConfigurationDigest(bot),
        taskProviderConfigurationDigest(equivalent),
      );
      final provider = ForegroundProvider(
        bot,
        events: () => const Stream.empty(),
      );
      final providers = ForegroundProviders((_) => provider);
      final factory = TaskProviderSessionFactory(
        chatId: 'chat-a',
        providers: providers,
        bot: bot,
      );
      final acceptance = TaskAcceptanceSnapshot(
        providerId: bot.apiType,
        modelId: bot.model,
        configurationDigest: taskProviderConfigurationDigest(bot),
        language: 'zh-CN',
        context: [
          TaskContextMessage(role: TaskContextRole.user, content: 'accepted'),
        ],
        allowedToolNames: {},
        verification: VerificationPolicySnapshot(
          reliabilityEnabled: true,
          strictGroundingEnabled: true,
          showVerificationStatus: true,
        ),
        segmentLimits: TaskSegmentLimits(),
      );
      final request = ModelRequest(
        messages: [ChatMessage(role: 'user', content: 'accepted')],
      );
      factory.open(acceptance, request).close();
      expect(providers.conversationScopes, ['chat-a']);
      expect(provider.sessions, hasLength(1));
      bot.parameters!['z'] = 3;
      expect(
        () => factory.open(acceptance, request),
        throwsA(
          isA<ProviderFailure>().having(
            (f) => f.code,
            'code',
            'task_provider_configuration_changed',
          ),
        ),
      );
      expect(provider.sessions, hasLength(1));
    },
  );
}
