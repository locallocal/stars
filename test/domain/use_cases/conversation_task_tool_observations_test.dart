import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import '../../support/task_runner_harness.dart';

void main() {
  late TaskRunnerHarness h;
  setUp(() => h = TaskRunnerHarness());
  tearDown(() => h.close());

  Map<String, dynamic> modelState() =>
      jsonDecode(h.models.requests.last.messages.last.content)
          as Map<String, dynamic>;

  Future<void> discardResults() async {
    final row =
        (await h.db.database.query('conversation_task_checkpoints')).single;
    final checkpoint = jsonDecode(row['checkpoint_json']! as String) as Map;
    (checkpoint['execution'] as Map).remove('toolResults');
    await h.db.database.update('conversation_task_checkpoints', {
      'checkpoint_json': jsonEncode(checkpoint),
    });
    await h.db.reopen();
  }

  test('full text and structured results survive a database restart', () async {
    await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
    final content = '  # Sources\n\n${'Data\n' * 1000}\n  ';
    final structured = {
      'skills': [
        for (var i = 0; i < 20; i++)
          {'source': 'https://example.com/skill-$i.zip', 'ref': 'v1'},
      ],
    };
    h.tool.onStart =
        (call) async => ToolCompleted(
          ToolResult(
            callId: call.callId,
            name: call.name,
            content: content,
            structuredContent: structured,
          ),
        );
    h.models.tool();
    expect(await h.run(), isA<TaskContinueSegment>());
    await h.db.reopen();
    h.models.completeStep();
    h.models.candidate();
    expect(await h.run(), isA<TaskCompletionCandidate>());
    final result = (modelState()['tool_results'] as List).single as Map;
    expect(result['content'], content);
    expect(result['structured_content'], structured);
    expect(result['redacted'], isFalse);
    expect(result['truncated'], isFalse);
  });

  test(
    'sensitive fields are redacted before persistence and model reuse',
    () async {
      await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
      h.tool.onStart =
          (call) async => ToolCompleted(
            ToolResult(
              callId: call.callId,
              name: call.name,
              content: 'password=private-value',
              structuredContent: {
                'api_key': 'private-key',
                'nested': {'authorization': 'private-auth', 'value': 'safe'},
              },
            ),
          );
      h.models.tool();
      await h.run();
      await h.db.reopen();
      h.models.completeStep();
      h.models.candidate();
      await h.run();
      final result = (modelState()['tool_results'] as List).single as Map;
      expect(result['redacted'], isTrue);
      expect(jsonEncode(await h.db.facts()), isNot(contains('private-')));
      expect(jsonEncode(modelState()), isNot(contains('private-')));
      expect(jsonEncode(result), contains('safe'));
    },
  );

  for (final write in [false, true]) {
    test(
      'missing retained results ${write ? 'never repeat writes' : 'allow fresh reads'}',
      () async {
        await h.open(limits: TaskSegmentLimits(maxToolCalls: 1));
        h.tool = RunnerTool(
          risk: write ? ToolRiskLevel.write : ToolRiskLevel.readOnly,
        );
        h.models.tool();
        await h.run();
        final original = (await h.snapshot).attempts.single.attemptId;
        await discardResults();
        h.models.tool(id: 'new-call');
        h.models.completeStep();
        h.models.candidate();
        var result = await h.run();
        if (result is TaskContinueSegment) result = await h.run();
        expect(result, isA<TaskCompletionCandidate>());
        expect(h.tool.starts, write ? 1 : 2);
        expect(
          result.snapshot.attempts.map((a) => a.attemptId),
          contains(original),
        );
        expect(
          result.snapshot.checkpoint!.execution!.toolResults,
          write ? isEmpty : hasLength(1),
        );
      },
    );
  }

  test(
    'repeated successful calls stop after the persisted duplicate limit',
    () async {
      await h.open(
        limits: TaskSegmentLimits(maxModelTurns: 1, maxSameCallRetries: 3),
      );
      for (var i = 0; i < 8; i++) {
        h.models.tool(id: 'duplicate-$i');
      }
      TaskSegmentResult? result;
      for (var i = 0; i < 6; i++) {
        result = await h.run();
        if (result is TaskNeedsSafeFinalization) break;
        await h.db.reopen();
      }
      expect(result, isA<TaskNeedsSafeFinalization>());
      expect(
        (result! as TaskNeedsSafeFinalization).reasonCode,
        TaskReasonCode.noProgress,
      );
      expect(h.tool.starts, 1);
      expect(
        result.snapshot.checkpoint!.execution!.consecutiveDuplicateCalls,
        3,
      );
      expect(result.snapshot.task.progress.noProgressSegments, greaterThan(0));
      expect(h.models.requests.length, lessThan(8));
    },
  );

  test('a batched read after a write observes the changed state', () async {
    final acceptance = taskAcceptance();
    await h.open(
      acceptance: TaskAcceptanceSnapshot(
        providerId: acceptance.providerId,
        modelId: acceptance.modelId,
        configurationDigest: acceptance.configurationDigest,
        language: acceptance.language,
        context: acceptance.context,
        allowedToolNames: {'read_file', 'write_state'},
        verification: acceptance.verification,
        segmentLimits: acceptance.segmentLimits,
      ),
    );
    var value = 0;
    h.tool.onStart =
        (call) async => ToolCompleted(
          ToolResult(
            callId: call.callId,
            name: call.name,
            content: 'value=$value',
            structuredContent: {'value': value},
          ),
        );
    final write = RunnerTool(
        definition: ToolDefinition(
          name: 'write_state',
          description: 'Update state',
          source: ToolSource.builtIn,
          riskLevel: ToolRiskLevel.write,
          inputSchema: const {'type': 'object'},
        ),
      )
      ..onStart = (call) async {
        value++;
        return ToolCompleted(
          ToolResult(callId: call.callId, name: call.name, content: 'Updated'),
        );
      };
    h.toolOverrides = [h.tool, write];
    h.models.tool();
    // Both calls are prepared against the pre-write snapshot.
    h.models.events([
      ToolCallRequested(
        callId: 'write',
        name: 'write_state',
        arguments: const {},
      ),
      ToolCallRequested(
        callId: 'read-again',
        name: 'read_file',
        arguments: const {},
      ),
      const ModelTurnCompleted(stopReason: 'tool_calls'),
    ]);
    h.models.completeStep();
    h.models.candidate();
    expect(await h.run(), isA<TaskCompletionCandidate>());
    expect(h.tool.starts, 2);
    final reads = (modelState()['tool_results'] as List).where(
      (r) => r['tool'] == 'read_file',
    );
    expect(reads.last['structured_content'], {'value': 1});
  });

  test(
    'tool output and success roll back atomically on checkpoint failure',
    () async {
      await h.open();
      await h.db.failWrite(
        'conversation_task_checkpoints',
        operation: 'UPDATE',
        when: "instr(NEW.checkpoint_json, '\"toolResults\"') > 0",
      );
      h.models.tool();
      await expectLater(h.run(), throwsA(isA<Exception>()));
      final snapshot = await h.snapshot;
      expect(snapshot.attempts.single.status, ToolInvocationStatus.running);
      expect(snapshot.checkpoint!.execution!.toolResults, isEmpty);
    },
  );
}
