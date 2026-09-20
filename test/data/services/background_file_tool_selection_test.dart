import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/services/ai/moonshot.dart';
import 'package:stars/data/services/task_runtime_factory.dart';
import 'package:stars/data/services/tools/built_in_tools.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';

import '../../support/compose_chat_fixtures.dart';
import '../../support/foreground_turn_fixtures.dart';
import '../../support/task_runner_harness.dart';

void main() {
  test(
    'retries incomplete activation, then plans and executes a real file write',
    () async {
      final h = TaskRepositoryHarness();
      await h.open();
      addTearDown(h.close);
      final clock = _Clock();
      final bot = foregroundBot(
        apiType: 'moonshot',
        model: 'kimi-k3',
        parameters: {Bot.parameterSupportsAutomaticSkillActivation: true},
      );
      final output = File('${h.directory.path}/chapter8.md');
      const content = '# 第八章\n\n需要保存的正文。\n';
      final accepted = changeTask(
        taskFixture(
          acceptance: TaskAcceptanceSnapshot(
            providerId: bot.apiType,
            modelId: bot.model,
            configurationDigest: taskProviderConfigurationDigest(bot),
            language: 'zh-CN',
            context: taskAcceptance().context,
            deferredPreparation: true,
            allowedToolNames: const {},
            verification: taskAcceptance().verification,
            segmentLimits: TaskSegmentLimits(maxModelTurns: 1),
          ),
        ),
        {'objective': '保存第八章到 ${output.path}，并读取校验'},
      );
      committed(
        await h.accept(
          task: accepted,
          plan: ConversationTaskPlan(
            taskId: accepted.taskId,
            revision: 1,
            objective: accepted.objective,
            isPending: true,
            steps: const [],
            allowedToolNames: const {},
            createdAt: accepted.createdAt,
          ),
        ),
      );
      final requests = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        requests.add(payload);
        expect((await h.task).status, ConversationTaskStatus.running);
        expect(
          (payload['tools'] as List).map((t) => t['function']['name']),
          contains(finishSkillSelectionToolName),
        );
        final message =
            requests.length == 1
                ? {'content': '好的，我会保存到本地。'}
                : {
                  'tool_calls': [
                    {
                      'id': 'skill-${requests.length}',
                      'type': 'function',
                      'function': {
                        'name':
                            requests.length == 2
                                ? 'activate_skill'
                                : finishSkillSelectionToolName,
                        'arguments': jsonEncode(
                          requests.length == 2
                              ? {'name': 'file-operations'}
                              : {
                                'selectedSkills': ['file-operations'],
                                'reason': 'Write the chapter and read it back.',
                              },
                        ),
                      },
                    },
                  ],
                };
        return http.Response(
          jsonEncode({
            'choices': [
              {'message': message},
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final models = RunnerModels();
      final providers = ForegroundProviders(
        (bot) => _Provider(bot, models, client),
      );
      final skill = fixtureSkill(
        'user:files',
        'file-operations',
        'Write files and read back their content.',
        requestedToolNames: {'write_local_file', 'read_local_file'},
      );
      final builtIns = createBuiltInTools(now: clock.now);
      final registry = StaticToolRegistry(builtIns);
      final prepare = PrepareTextGeneration(
        aiProviderRepository: providers,
        composeChatTurn:
            ComposeChatTurn(
              skillRepository: FixtureFakeSkillRepository({
                'user:files': skill,
              }),
              bindingRepository: FixtureFakeBindingRepository([
                fixtureBinding('user:files', requiresApproval: false),
              ]),
              conversationArtifactsDirectoryProvider:
                  (_) async => h.directory.path,
            ).call,
        toolRegistry: registry,
        verificationToolCandidateNames: {
          for (final tool in builtIns)
            if (isEligibleVerificationTool(tool.definition))
              tool.definition.name,
        },
      );
      var segment = 0;
      Future<TaskSegmentResult> run() async {
        final current = await h.task;
        final at = clock.now();
        final lease = TaskLease(
          taskId: current.taskId,
          ownerId: 'writer',
          token: 'lease-${++segment}',
          acquiredAt: at,
          expiresAt: at.add(const Duration(hours: 1)),
        );
        committed(
          await h.repository.tryAcquireLease(
            taskId: current.taskId,
            expectedRevision: current.revision,
            lease: lease,
            now: at,
          ),
        );
        final runtime = TaskRuntimeFactory(
          tasks: h.repository,
          bots: _Bots(bot),
          providers: providers,
          registry: registry,
          policy: const DefaultToolPolicy(
            allowLocalRead: true,
            allowDestructiveWithApproval: true,
          ),
          prepare: prepare,
          messages: SqliteMessageRepository(localDatabase: h.local),
          clock: clock,
        );
        return (await runtime.resolve(current))(
          input: (await h.repository.getExecutionSnapshot(current.taskId))!,
          lease: lease,
          segmentId: 'segment-$segment',
        );
      }

      expect(await run(), isA<TaskBackoff>());
      final failed =
          (await h.repository.getExecutionSnapshot(accepted.taskId))!;
      expect(
        failed.plan.preparation,
        isNull,
        reason:
            'requests=${requests.length}, scope=${failed.toolScope}, modelRequests=${models.requests.length}',
      );
      expect(failed.plan.revision, 1);
      expect(failed.attempts, isEmpty);
      expect(models.requests, isEmpty);
      expect(await output.exists(), isFalse);

      await h.reopen();
      clock.offset = const Duration(minutes: 1);
      models.tool(
        name: 'stars_revise_task_plan',
        arguments: {
          'steps': [
            {'id': 'write', 'summary': '保存正文'},
            {'id': 'verify', 'summary': '读取确认保存结果'},
          ],
          'allowedToolNames': ['write_local_file', 'read_local_file'],
        },
      );
      expect(await run(), isA<TaskContinueSegment>());
      final planning = models.requests.single;
      final state = jsonDecode(planning.messages.last.content) as Map;
      expect(
        (state['available_tools'] as List).map((tool) => tool['name']),
        contains('write_local_file'),
      );
      expect(planning.tools.map((tool) => tool.name), [
        'stars_revise_task_plan',
      ]);
      final planned =
          (await h.repository.getExecutionSnapshot(accepted.taskId))!;
      expect(planned.toolScope, contains('write_local_file'));
      expect(planned.plan.allowedToolNames, {
        'write_local_file',
        'read_local_file',
      });
      expect(planned.attempts, isEmpty);
      expect(requests, hasLength(3));

      await h.reopen();
      models
        ..tool(
          name: 'write_local_file',
          arguments: {
            'path': output.path,
            'content': content,
            'mode': 'create',
          },
        )
        ..completeStep()
        ..tool(name: 'read_local_file', arguments: {'path': output.path})
        ..completeStep();
      for (var i = 0; i < 4; i++) {
        expect(await run(), isA<TaskContinueSegment>());
      }
      expect(await output.readAsString(), content);
      final done = (await h.repository.getExecutionSnapshot(accepted.taskId))!;
      expect(done.attempts.map((attempt) => attempt.name), [
        'write_local_file',
        'read_local_file',
      ]);
      expect(
        done.attempts.map((attempt) => attempt.status),
        everyElement(ToolInvocationStatus.succeeded),
      );
      expect(done.checkpoint!.completedStepIds, ['write', 'verify']);
      expect(
        requests,
        hasLength(3),
        reason: 'Resuming a prepared task must not redo discovery or writes.',
      );
    },
  );
}

final class _Provider extends AiProvider {
  _Provider(super.bot, this.models, this.client);
  final RunnerModels models;
  final http.Client client;
  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );
  @override
  SkillToolSession openSkillToolSession(SkillToolSessionRequest request) =>
      Moonshot(bot, client: client).openSkillToolSession(request);
  @override
  AgentModelSession openModelSession(ModelRequest request) =>
      models.open(taskAcceptance(), request);
  @override
  Future<void> generateText(List<ChatMessage> messages) =>
      throw UnsupportedError('Use model sessions');
}

final class _Bots implements BotRepository {
  _Bots(this.bot);
  final Bot bot;
  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async => [bot];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Clock implements TaskRunnerClock {
  Duration offset = Duration.zero;
  @override
  DateTime now() => DateTime.now().toUtc().add(offset);
  @override
  Future<T> timeout<T>(Future<T> work, Duration limit) => work.timeout(limit);
}
