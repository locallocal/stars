import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/file_skill_repository.dart';
import 'package:stars/data/repositories/sqlite_skill_inventory_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/data/services/skills/skill_catalog_endpoint_policy.dart';
import 'package:stars/data/services/skills/skill_installation_service.dart';
import 'package:stars/data/services/skills/skill_package_storage_service.dart';
import 'package:stars/data/services/skills/skill_parser.dart';
import 'package:stars/data/services/skills/skill_source_resolver.dart';
import 'package:stars/data/services/task_tool_adapters.dart';
import 'package:stars/data/services/tools/resolve_skill_source_tool.dart';
import 'package:stars/data/services/tools/skill_installer_tool.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';
import 'package:stars/domain/use_cases/finalize_conversation_task.dart';
import 'package:stars/domain/use_cases/skill_inventory_tools.dart';

import '../../support/task_runner_harness.dart';
import '../../support/task_scheduler_harness.dart'
    show createRunnerScheduler, until;

void main() {
  late TaskRunnerHarness h;
  late FileSkillRepository skills;
  late ResolveSkillSourceTool resolver;
  late SkillInstallerTool installer;
  late ExecutableTool inventory;
  var fetches = 0;
  var downloads = 0;
  var invalidPackage = '';
  Object? response;
  List<Object?>? pages;
  const source =
      'npx skills add https://www.modelscope.cn/collections/Tashanworld/keyanjinengbao';

  Future<void> open({TaskSegmentLimits? limits}) async {
    h = TaskRunnerHarness();
    final acceptance = taskAcceptance(limits: limits);
    await h.open(
      acceptance: TaskAcceptanceSnapshot(
        providerId: acceptance.providerId,
        modelId: acceptance.modelId,
        configurationDigest: acceptance.configurationDigest,
        language: 'zh-CN',
        context: acceptance.context,
        allowedToolNames: {
          'resolve_skill_source',
          'install_skill',
          'list_installed_skills',
        },
        verification: acceptance.verification,
        segmentLimits: acceptance.segmentLimits,
      ),
    );
    skills = FileSkillRepository(
      localDatabase: h.db.local,
      storageService: SkillPackageStorageService(
        applicationSupportDirectoryProvider:
            () async => Directory('${h.db.directory.path}/support'),
      ),
      parser: const SkillParser(),
    );
    final policy = SkillCatalogEndpointPolicy(
      dnsLookup: (_) async => [InternetAddress('8.8.8.8')],
    );
    resolver = ResolveSkillSourceTool(
      resolver: SkillSourceResolver(
        endpointPolicy: policy,
        fetcher: (uri, _, _) async {
          fetches++;
          if (pages != null) {
            final page = int.parse(uri.queryParameters['PageNumber']!);
            return utf8.encode(jsonEncode(pages![page - 1]));
          }
          if (response is Exception) {
            throw response!;
          }
          return utf8.encode(
            response is String ? response! as String : jsonEncode(response),
          );
        },
      ),
    );
    installer = SkillInstallerTool(
      installation: SkillInstallationService(
        skillRepository: skills,
        endpointPolicy: policy,
        fetcher: (uri, _, _) async {
          downloads++;
          final name =
              uri.pathSegments[2] == invalidPackage
                  ? 'INVALID NAME'
                  : uri.pathSegments[2];
          return ZipEncoder().encodeBytes(
            Archive()..addFile(
              ArchiveFile.string(
                'bundle/SKILL.md',
                '---\nname: $name\ndescription: Research skill.\nversion: 1.0.0\n---\nUse this skill.\n',
              ),
            ),
          );
        },
      ),
    );
    inventory =
        SkillInventoryToolSession(
          repository: SqliteSkillInventoryRepository(localDatabase: h.db.local),
          chatId: 'chat-1',
        ).createTools().first;
    h.toolOverrides = [
      for (final tool in [resolver, installer, inventory])
        SynchronousTaskToolAdapter(
          tool,
          checkpointArgumentNames:
              taskCheckpointArguments[tool.definition.name]!,
        ),
    ];
  }

  setUp(() {
    fetches = 0;
    downloads = 0;
    invalidPackage = '';
    pages = null;
    response = {
      'Code': 200,
      'Success': true,
      'Data': {
        'CollectionElements': {
          'Total': 20,
          'CollectionElementVoList': [
            for (var i = 0; i < 20; i++)
              {
                'ElementType': 'skill',
                'ElementPath': 'owner',
                'ElementName': 'research-$i',
              },
          ],
        },
      },
    };
  });
  tearDown(() async {
    await skills.dispose();
    await h.close();
  });

  FinalizeConversationTask finalizer() => FinalizeConversationTask(
    repository: h.db.repository,
    evidenceRepository: SqliteToolEvidenceRepository(localDatabase: h.db.local),
    ownerId: 'finalizer',
    newId: () => 'terminal-lease',
    clock: h.clock,
    tools: h.toolOverrides!.map((t) => t.definition).toList(),
  );

  for (final count in [25, 205]) {
    test(
      'all $count paginated sources install across checkpoints and a database restart',
      () async {
        pages = [
          for (var page = 0; page * 10 < count; page++)
            _collectionPage(count, start: page * 10, size: 10),
        ];
        final perSegment = count > 100 ? 48 : 1;
        await open(limits: TaskSegmentLimits(maxToolCalls: perSegment));
        h.models.tool(
          name: 'resolve_skill_source',
          arguments: const {'source': source},
        );
        h.models.turns.add(() {
          final state =
              jsonDecode(h.models.requests.last.messages.last.content) as Map;
          final result = (state['tool_results'] as List).single as Map;
          final data = result['structured_content'] as Map;
          expect(data['count'], count);
          final entries = data['skills'] as List;
          return Stream.fromIterable([
            for (var i = 0; i < entries.length; i++)
              ToolCallRequested(
                callId: 'install-$i',
                name: 'install_skill',
                arguments: Map<String, Object?>.from(entries[i] as Map)
                  ..remove('name'),
              ),
            const ModelTurnCompleted(stopReason: 'tool_calls'),
          ]);
        });
        h.models.tool(name: 'list_installed_skills');
        h.models.completeStep();
        h.models.candidate();
        var segments = 0;
        while (true) {
          final result = await h.run();
          segments++;
          if (result is TaskCompletionCandidate) break;
          expect(result, isA<TaskContinueSegment>());
          expect(
            segments,
            lessThanOrEqualTo(((count + 2) / perSegment).ceil()),
          );
          if (segments == 1) await h.db.reopen();
        }
        expect(segments, greaterThan(1));
        await h.db.reopen();
        final retained = (await h.snapshot).checkpoint!.execution!.toolResults;
        expect(
          retained.where((item) => item.tool == 'resolve_skill_source'),
          hasLength(1),
        );
        await finalizer()('task-1');
        expect((await h.db.task).status, ConversationTaskStatus.succeeded);
        expect(fetches, (count / 10).ceil());
        expect(downloads, count);
        expect(await h.db.database.query('skills'), hasLength(count));
        expect(
          (await h.snapshot).attempts.where((a) => a.name == 'install_skill'),
          hasLength(count),
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }

  for (final selectedOnly in [false, true]) {
    test(
      'completion checks the entire requested selection (selected: $selectedOnly)',
      () async {
        response = _collectionPage(25);
        await open(limits: TaskSegmentLimits(maxToolCalls: 1));
        h.models.tool(
          name: 'resolve_skill_source',
          arguments: {
            'source': source,
            if (selectedOnly) 'skill_names': ['research-24'],
          },
        );
        expect(await h.run(), isA<TaskContinueSegment>());
        for (var i = 0; i < (selectedOnly ? 1 : 20); i++) {
          final index = selectedOnly ? 24 : i;
          h.models.tool(
            name: 'install_skill',
            arguments: {
              'source_type': 'zip_url',
              'source':
                  'https://www.modelscope.cn/skills/owner/research-$index/archive/zip/master',
            },
          );
          expect(await h.run(), isA<TaskContinueSegment>());
        }
        await h.db.reopen();
        h.models.completeStep();
        if (selectedOnly) {
          h.models.candidate();
          expect(await h.run(), isA<TaskCompletionCandidate>());
        } else {
          final result = await h.run() as TaskNeedsSafeFinalization;
          expect(result.reasonCode, TaskReasonCode.verificationFailed);
        }
        await finalizer()('task-1');
        expect(
          (await h.db.task).status,
          selectedOnly
              ? ConversationTaskStatus.succeeded
              : ConversationTaskStatus.failed,
        );
        expect(
          await h.db.database.query('skills'),
          hasLength(selectedOnly ? 1 : 20),
        );
      },
    );
  }

  for (final failure in ['bad-json', 'empty', 'incomplete', 'network']) {
    test(
      '$failure resolution automatically commits failure without installing or retrying',
      () async {
        if (failure == 'bad-json') response = '<html>error</html>';
        if (failure == 'network') {
          response = const SocketException('unavailable');
        }
        if (failure == 'empty' || failure == 'incomplete') {
          response = {
            'Code': 200,
            'Success': true,
            'Data': {
              'CollectionElements': {
                'Total': failure == 'empty' ? 0 : 20,
                'CollectionElementVoList': <Object?>[],
              },
            },
          };
        }
        await open();
        h.models.tool(
          name: 'resolve_skill_source',
          arguments: const {'source': source},
        );
        final finish = finalizer();
        final scheduler = createRunnerScheduler(h, onReady: finish.onReady);
        addTearDown(scheduler.stop);
        await scheduler.start(periodic: false);
        await until(() async => (await h.db.task).status.isTerminal);
        final task = await h.db.task;
        expect(task.status, ConversationTaskStatus.failed);
        expect(
          task.terminalSummary!.reasonCode,
          TaskReasonCode.skillSourceFailed,
        );
        expect(task.terminalSummary!.safeReason, contains('已停止'));
        expect(task.nextRunAt, isNull);
        expect(downloads, 0);
        expect(fetches, 1);
        expect(h.models.requests, hasLength(1));
        await scheduler.stop();
        await h.db.reopen();
        expect((await h.db.task).status, ConversationTaskStatus.failed);
        expect(await h.db.database.query('skills'), isEmpty);
        expect((await h.snapshot).approvals, isEmpty);
      },
    );
  }

  test('a completion disclaimer without installation is not success', () async {
    await open();
    h.models.completeStep();
    final result = await h.run() as TaskNeedsSafeFinalization;
    expect(result.reasonCode, TaskReasonCode.verificationFailed);
    await finalizer()('task-1');
    expect((await h.db.task).status, ConversationTaskStatus.failed);
    expect(downloads, 0);
  });

  test(
    'package parsing rejection terminates with earlier installations retained',
    () async {
      await open();
      invalidPackage = 'research-1';
      h.models.events([
        for (var i = 0; i < 3; i++)
          ToolCallRequested(
            callId: 'install-$i',
            name: 'install_skill',
            arguments: {
              'source_type': 'zip_url',
              'source':
                  'https://www.modelscope.cn/skills/owner/research-$i/archive/zip/master',
            },
          ),
        const ModelTurnCompleted(stopReason: 'tool_calls'),
      ]);
      final result = await h.run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.skillInstallRejected);
      expect(result.sideEffectsUnknown, isFalse);
      await finalizer()('task-1');
      final task = await h.db.task;
      expect(task.status, ConversationTaskStatus.failed);
      expect(task.waitingReason, isNull);
      expect(
        task.terminalSummary!.sideEffectStatus,
        TaskSideEffectStatus.irreversible,
      );
      expect(downloads, 2);
      expect(await h.db.database.query('skills'), hasLength(1));
    },
  );

  test(
    'legacy completion candidates cannot bypass the installation gate',
    () async {
      await open();
      h.models.completeStep();
      await h.run();
      final row =
          (await h.db.database.query('conversation_task_checkpoints')).single;
      final checkpoint = jsonDecode(row['checkpoint_json']! as String) as Map;
      (checkpoint['execution'] as Map)
        ..['finalizationReason'] = null
        ..['candidate'] = {
          'schema_version': 1,
          'claims': <Object?>[],
          'non_factual_text': 'Please retry the installation.',
        };
      await h.db.database.update('conversation_task_checkpoints', {
        'checkpoint_json': jsonEncode(checkpoint),
      });
      await h.db.reopen();
      await finalizer()('task-1');
      expect((await h.db.task).status, ConversationTaskStatus.failed);
    },
  );

  for (final defect in [
    'truncated',
    'count-mismatch',
    'missing-output',
    'oversized',
    'redacted',
  ]) {
    test('$defect source results cannot start an installation', () async {
      await open();
      final entry = <String, Object?>{
        'name': 'reviewer',
        'source_type': 'zip_url',
        'source':
            defect == 'redacted'
                ? 'https://example.com/skill.zip?password=private'
                : 'https://example.com/skill.zip',
        if (defect == 'oversized') 'ref': 'r' * 140000,
      };
      final adapter = RunnerTool(
          definition: resolver.definition,
          checkpointArgumentNames: {'source'},
        )
        ..onStart =
            (call) async => ToolCompleted(
              ToolResult(
                callId: call.callId,
                name: call.name,
                content: 'Resolved sources',
                truncated: defect == 'truncated',
                structuredContent:
                    defect == 'missing-output'
                        ? null
                        : {
                          'destination': 'stars',
                          'count': defect == 'count-mismatch' ? 2 : 1,
                          'skills': [entry],
                        },
              ),
            );
      h.toolOverrides = [adapter, ...h.toolOverrides!.skip(1)];
      h.models.tool(
        name: 'resolve_skill_source',
        arguments: const {'source': source},
      );
      final result = await h.run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.skillSourceFailed);
      expect(adapter.starts, 1);
      expect(
        result.snapshot.attempts.single.status,
        ToolInvocationStatus.failed,
      );
      expect(result.snapshot.checkpoint!.execution!.toolResults, isEmpty);
      await finalizer()('task-1');
      expect((await h.db.task).status, ConversationTaskStatus.failed);
      expect(downloads, 0);
    });
  }
}

Map<String, Object?> _collectionPage(int total, {int start = 0, int? size}) => {
  'Code': 200,
  'Success': true,
  'Data': {
    'ElementCount': total,
    'CollectionElements': {
      'Total': total,
      'CollectionElementVoList': [
        for (var i = start; i < start + (size ?? total) && i < total; i++)
          {
            'ElementType': 'skill',
            'ElementPath': 'owner',
            'ElementName': 'research-$i',
          },
      ],
    },
  },
};
