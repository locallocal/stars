import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/sqlite_mcp_server_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/data/services/mcp/mcp_task_configuration.dart';
import 'package:stars/data/services/mcp_task_tool_adapter.dart';
import 'package:stars/data/services/tools/add_mcp_server_tool.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/repositories/mcp_credential_store.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';
import 'package:stars/domain/use_cases/finalize_conversation_task.dart';

import '../../support/task_runner_harness.dart';

void main() {
  late TaskRunnerHarness h;
  late SqliteMcpServerRepository servers;
  late _Credentials credentials;
  late AddMcpServerTool tool;
  var connects = 0;
  var connectionFails = false;

  setUp(() async {
    h = TaskRunnerHarness();
    await h.open(
      acceptance: taskAcceptance(allowedToolNames: {addMcpServerToolName}),
    );
    servers = SqliteMcpServerRepository(localDatabase: h.db.local);
    credentials = _Credentials();
    connects = 0;
    connectionFails = false;
    tool = AddMcpServerTool(
      repository: servers,
      credentialStore: credentials,
      connector: (id, _) async {
        connects++;
        final server = (await servers.getServer(id))!;
        if (connectionFails) {
          await servers.saveServer(
            server.copyWith(
              status: McpConnectionStatus.error,
              lastErrorCode: 'mcp_connection_failed',
            ),
          );
          throw const McpException('mcp_connection_failed');
        }
        final connected = server.copyWith(
          status: McpConnectionStatus.connected,
        );
        await servers.replaceCatalog(connected, []);
        return connected;
      },
    );
  });
  tearDown(() async {
    await servers.dispose();
    await h.close();
  });

  Future<ToolResult> execute(
    McpTaskToolAdapter adapter,
    Map<String, Object?> arguments,
  ) async =>
      (await adapter.start(
                ToolCallRequest(
                  callId: 'install',
                  name: addMcpServerToolName,
                  arguments: arguments,
                ),
                'key',
                AgentCancellationToken(),
              )
              as ToolCompleted)
          .result;

  Future<void> finalize() async {
    await FinalizeConversationTask(
      repository: h.db.repository,
      evidenceRepository: SqliteToolEvidenceRepository(
        localDatabase: h.db.local,
      ),
      ownerId: 'finalizer',
      newId: () => 'final-lease',
      clock: h.clock,
      tools: [tool.definition],
    )('task-1');
  }

  test(
    'authenticated install requires approval, survives restart and keeps secrets out of task facts',
    () async {
      final source = _source('real-mcp-credential');
      final configs = McpTaskConfiguration.fromMessages([
        source,
      ], senderId: 'user');
      final arguments = configs.single.safeArguments;
      h.toolOverrides = [McpTaskToolAdapter(tool, configurations: configs)];
      h.policyOverride = const DefaultToolPolicy(allowProcessExecution: true);
      h.models.tool(name: addMcpServerToolName, arguments: arguments);
      final waiting = await h.run() as TaskApprovalWait;
      expect(await servers.getServers(), isEmpty);
      expect(credentials.values, isEmpty);
      expect(connects, 0);
      expect(
        jsonEncode(await h.db.facts()),
        isNot(contains('real-mcp-credential')),
      );
      expect(
        waiting.snapshot.approvals.single.safeActionSummary,
        contains('https://example.com/mcp'),
      );

      await h.db.reopen();
      // Reconstruct the adapter from the same accepted source, like a new process.
      h.toolOverrides = [
        McpTaskToolAdapter(
          tool,
          configurations: McpTaskConfiguration.fromMessages([
            source,
          ], senderId: 'user'),
        ),
      ];
      committed(
        await h.db.repository.decideApproval(
          taskId: 'task-1',
          approvalId: waiting.approvalId,
          expectedRevision: (await h.db.task).revision,
          decision: TaskApprovalDecision.approved,
          actorId: 'user',
          decidedAt: h.clock.now(),
        ),
      );
      h.models
        ..completeStep()
        ..candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      await finalize();
      expect((await h.db.task).status, ConversationTaskStatus.succeeded);
      expect(await servers.getServers(), hasLength(1));
      expect(
        credentials.values.values.single.accessToken,
        'real-mcp-credential',
      );
      expect(connects, 1);
      expect(
        jsonEncode(await h.db.facts()),
        isNot(contains('real-mcp-credential')),
      );
    },
  );

  test('a denied install never writes a server or credentials', () async {
    final configs = McpTaskConfiguration.fromMessages([
      _source('private-token'),
    ], senderId: 'user');
    h.toolOverrides = [McpTaskToolAdapter(tool, configurations: configs)];
    h.policyOverride = const DefaultToolPolicy(allowProcessExecution: true);
    h.models.tool(
      name: addMcpServerToolName,
      arguments: configs.single.safeArguments,
    );
    final waiting = await h.run() as TaskApprovalWait;
    committed(
      await h.db.repository.decideApproval(
        taskId: 'task-1',
        approvalId: waiting.approvalId,
        expectedRevision: (await h.db.task).revision,
        decision: TaskApprovalDecision.denied,
        actorId: 'user',
        decidedAt: h.clock.now(),
      ),
    );
    expect(await h.run(), isA<TaskNeedsSafeFinalization>());
    await finalize();
    expect((await h.db.task).status, ConversationTaskStatus.failed);
    expect(await servers.getServers(), isEmpty);
    expect(credentials.values, isEmpty);
    expect(connects, 0);
  });

  for (final token in [
    '<YOUR_API_KEY>',
    'YOUR_API_KEY',
    r'${API_KEY}',
    '[redacted]',
  ]) {
    test(
      'placeholder $token fails before storage and cannot complete the task',
      () async {
        final configs = McpTaskConfiguration.fromMessages([
          _source(token),
        ], senderId: 'user');
        h.toolOverrides = [McpTaskToolAdapter(tool, configurations: configs)];
        h.models.tool(
          name: addMcpServerToolName,
          arguments: configs.single.safeArguments,
        );
        final failed = await h.run() as TaskNeedsSafeFinalization;
        expect(failed.reasonCode, TaskReasonCode.missingCredentials);
        await finalize();
        expect((await h.db.task).status, ConversationTaskStatus.failed);
        expect(
          (await h.snapshot).attempts.single.errorCode,
          'mcp_access_token_required',
        );
        expect(await servers.getServers(), isEmpty);
        expect(credentials.values, isEmpty);
        expect(connects, 0);
      },
    );
  }

  for (final saveOnly in [false, true]) {
    test(
      'saved server is successful only when connection requirements are met: saveOnly=$saveOnly',
      () async {
        connectionFails = true;
        h.toolOverrides = [McpTaskToolAdapter(tool)];
        h.models
          ..tool(
            name: addMcpServerToolName,
            arguments: {
              'name': 'Remote',
              'transport_type': 'streamable_http',
              'endpoint': 'https://example.com/mcp',
              'connect': !saveOnly,
            },
          )
          ..completeStep();
        if (saveOnly) h.models.candidate();
        final result = await h.run();
        expect(
          result,
          saveOnly
              ? isA<TaskCompletionCandidate>()
              : isA<TaskNeedsSafeFinalization>(),
        );
        await finalize();
        expect(
          (await h.db.task).status,
          saveOnly
              ? ConversationTaskStatus.succeeded
              : ConversationTaskStatus.failed,
        );
        expect(await servers.getServers(), hasLength(1));
        expect(connects, saveOnly ? 0 : 1);
      },
    );
  }

  test('finishing a plan without calling the installer is a failure', () async {
    h.toolOverrides = [McpTaskToolAdapter(tool)];
    h.models.completeStep();
    expect(await h.run(), isA<TaskNeedsSafeFinalization>());
    await finalize();
    expect((await h.db.task).status, ConversationTaskStatus.failed);
    expect(await servers.getServers(), isEmpty);
  });

  test(
    'configuration references cannot leak credentials to a substituted endpoint',
    () async {
      final configs = McpTaskConfiguration.fromMessages([
        _source('private-token'),
      ], senderId: 'user');
      final result =
          await execute(McpTaskToolAdapter(tool, configurations: configs), {
            ...configs.single.safeArguments,
            'endpoint': 'https://other.example.com/mcp',
          });
      expect(result.errorCode, 'mcp_configuration_mismatch');
      expect(await servers.getServers(), isEmpty);
      expect(credentials.values, isEmpty);
    },
  );

  test(
    'references from another task or changed source cannot be resolved',
    () async {
      final config =
          McpTaskConfiguration.fromMessages([
            _source('original'),
          ], senderId: 'user').single;
      for (final configs in [
        <McpTaskConfiguration>[],
        McpTaskConfiguration.fromMessages([
          _source('changed'),
        ], senderId: 'user'),
      ]) {
        final result = await execute(
          McpTaskToolAdapter(tool, configurations: configs),
          config.safeArguments,
        );
        expect(result.errorCode, 'mcp_configuration_unavailable');
      }
      expect(await servers.getServers(), isEmpty);
    },
  );

  test(
    'task schema rejects raw credentials and unsupported source headers',
    () async {
      final direct = await execute(McpTaskToolAdapter(tool), {
        'name': 'Remote',
        'transport_type': 'streamable_http',
        'endpoint': 'https://example.com/mcp',
        'access_token': 'private-token',
      });
      expect(direct.isError, isTrue);
      final configs = McpTaskConfiguration.fromMessages([
        _source('private-token', extraHeaders: {'X-API-Key': 'other-secret'}),
      ], senderId: 'user');
      final result = await execute(
        McpTaskToolAdapter(tool, configurations: configs),
        configs.single.safeArguments,
      );
      expect(result.errorCode, 'mcp_unsupported_headers');
      expect(await servers.getServers(), isEmpty);
      expect(credentials.values, isEmpty);
    },
  );

  test(
    'stdio source environment is restored without exposing it in task arguments',
    () async {
      final source = _message(
        '安装 ${jsonEncode({
          'mcpServers': {
            'Local': {
              'command': 'npx',
              'args': ['-y', 'test-server'],
              'env': {'API_KEY': 'stdio-private'},
            },
          },
        })}',
      );
      final configs = McpTaskConfiguration.fromMessages([
        source,
      ], senderId: 'user');
      expect(
        jsonEncode(configs.single.safeArguments),
        isNot(contains('stdio-private')),
      );
      final result = await execute(
        McpTaskToolAdapter(tool, configurations: configs),
        {...configs.single.safeArguments, 'connect': false},
      );
      expect(result.isError, isFalse);
      expect(credentials.values.values.single.environment, {
        'API_KEY': 'stdio-private',
      });
      expect(connects, 0);
    },
  );

  test(
    'source parsing ignores assistant configuration and understands fenced JSON',
    () {
      final user = _source('user-token');
      final assistant = _message(
        _source('assistant-token').content,
        sender: 'assistant',
      );
      final configs = McpTaskConfiguration.fromMessages([
        user,
        assistant,
      ], senderId: 'user');
      expect(configs.single.arguments['access_token'], 'user-token');
    },
  );
}

Message _source(String token, {Map<String, String> extraHeaders = const {}}) =>
    _message(
      '安装\n```json\n${jsonEncode({
        'mcpServers': {
          'Remote': {
            'type': 'streamable-http',
            'url': 'https://example.com/mcp',
            'headers': {'Authorization': 'Bearer $token', ...extraHeaders},
          },
        },
      })}\n```',
    );

Message _message(String content, {String sender = 'user'}) => Message(
  messageId: 'task-1:user',
  turnId: 'task-1:turn',
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: sender,
  content: content,
  timestamp: taskTime,
);

class _Credentials implements McpCredentialStore {
  final values = <String, McpCredential>{};
  @override
  Future<McpCredential?> read(String id) async => values[id];
  @override
  Future<void> write(String id, McpCredential value) async {
    values[id] = value;
  }

  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }
}
