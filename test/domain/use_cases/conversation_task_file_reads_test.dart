import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/local_file_system_tools.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import '../../support/task_runner_harness.dart';

void main() {
  late TaskRunnerHarness h;
  late File source;
  setUp(() => h = TaskRunnerHarness());
  tearDown(() => h.close());

  Future<void> open({TaskSegmentLimits? limits, int steps = 1}) async {
    final acceptance = taskAcceptance(limits: limits);
    await h.open(
      steps: steps,
      acceptance: TaskAcceptanceSnapshot(
        providerId: acceptance.providerId,
        modelId: acceptance.modelId,
        configurationDigest: acceptance.configurationDigest,
        language: acceptance.language,
        context: acceptance.context,
        allowedToolNames: {'read_local_file', 'write_local_file'},
        verification: acceptance.verification,
        segmentLimits: acceptance.segmentLimits,
      ),
    );
    h.clock.time = DateTime.now().toUtc().add(const Duration(minutes: 1));
    source = File('${h.db.directory.path}/report.md');
    final read = ReadLocalFileTool();
    h.tool = RunnerTool(
      definition: read.definition,
      checkpointArgumentNames: {
        'path',
        'encoding',
        'offset_bytes',
        'max_bytes',
      },
    );
    h.tool.onStart =
        (call) async =>
            ToolCompleted(await read.execute(call, AgentCancellationToken()));
    h.toolOverrides = [
      h.tool,
      SynchronousTaskToolAdapter(
        WriteLocalFileTool(),
        checkpointArgumentNames: {
          'path',
          'content',
          'mode',
          'encoding',
          'create_parents',
        },
      ),
    ];
  }

  void read([Map<String, Object?> extra = const {}]) => h.models.tool(
    name: 'read_local_file',
    arguments: {'path': source.path, ...extra},
  );

  Map<String, dynamic> modelState() =>
      jsonDecode(h.models.requests.last.messages.last.content)
          as Map<String, dynamic>;

  Future<void> approve() async {
    final snapshot = await h.snapshot;
    committed(
      await h.db.repository.decideApproval(
        taskId: snapshot.task.taskId,
        approvalId: snapshot.approvals.last.approvalId,
        expectedRevision: snapshot.task.revision,
        decision: TaskApprovalDecision.approved,
        actorId: 'test-user',
        decidedAt: h.clock.now(),
      ),
    );
  }

  test('full Markdown survives restart and reaches the generated HTML', () async {
    await open(limits: TaskSegmentLimits(maxToolCalls: 1), steps: 2);
    final markdown =
        '# Report\n\n${'Table | Value\n--- | ---\nItem | 42\n' * 180}\n## Final section\nEnd marker.\n';
    await source.writeAsString(markdown);
    read();
    expect(await h.run(), isA<TaskContinueSegment>());
    expect(
      (await h.snapshot).checkpoint!.execution!.fileReads.single.content,
      markdown,
    );
    await h.db.reopen();
    h.models.completeStep();
    final destination = File('${h.db.directory.path}/report.html');
    h.models.turns.add(() {
      final state = modelState();
      final pages = state['file_reads'] as List;
      expect((pages.single as Map)['content'], markdown);
      expect((pages.single as Map)['truncated'], isFalse);
      expect((state['observations'] as List).single['error_code'], '');
      return Stream.fromIterable([
        ToolCallRequested(
          callId: 'write',
          name: 'write_local_file',
          arguments: {
            'path': destination.path,
            'content': '<html><pre>$markdown</pre></html>',
            'mode': 'create',
          },
        ),
        const ModelTurnCompleted(stopReason: 'tool_calls'),
      ]);
    });
    expect(await h.run(), isA<TaskContinueSegment>());
    expect(
      await destination.readAsString(),
      '<html><pre>$markdown</pre></html>',
    );
    await h.db.reopen();
    h.models.completeStep();
    h.models.candidate();
    expect(await h.run(), isA<TaskCompletionCandidate>());
    expect(h.tool.starts, 1);
    expect(
      (await h.snapshot).attempts.every((a) => a.errorCode.isEmpty),
      isTrue,
    );
  });

  test(
    'equivalent and larger reads reuse the approved complete page after restart',
    () async {
      await open();
      await source.writeAsString('# Report\nBody\n');
      h.policy.outcome = ToolPolicyOutcome.requireApproval;
      read();
      expect(await h.run(), isA<TaskApprovalWait>());
      await h.db.reopen();
      await approve();
      read({'max_bytes': 65536});
      read({'encoding': 'utf8', 'offset_bytes': 0, 'max_bytes': 262144});
      read({'max_bytes': 12000});
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      final snapshot = await h.snapshot;
      expect(h.tool.starts, 1);
      expect(snapshot.approvals, hasLength(1));
      expect(snapshot.attempts, hasLength(1));
      expect(snapshot.attempts.single.errorCode, isEmpty);
      expect(
        snapshot.checkpoint!.execution!.fileReads.single.content,
        '# Report\nBody\n',
      );
    },
  );

  test(
    'bounded UTF-8 pages provide exact continuation offsets across restart',
    () async {
      await open(limits: TaskSegmentLimits(maxToolCalls: 1));
      final content = '${'界' * 50000}\nEnd.\n';
      await source.writeAsString(content);
      var offset = 0;
      final pages = <String>[];
      do {
        read({'offset_bytes': offset, 'max_bytes': 262144});
        expect(await h.run(), isA<TaskContinueSegment>());
        await h.db.reopen();
        final page = (await h.snapshot).checkpoint!.execution!.fileReads.last;
        expect(page.offsetBytes, offset);
        expect(page.nextOffsetBytes - offset, utf8.encode(page.content).length);
        expect(page.nextOffsetBytes - offset, lessThanOrEqualTo(65536));
        pages.add(page.content);
        offset = page.nextOffsetBytes;
        if (!page.truncated) break;
        expect(pages.length, lessThan(4));
      } while (true);
      expect(pages.join(), content);
      expect(h.tool.starts, 3);
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      final context = modelState()['file_reads'] as List;
      expect(context.last['next_offset_bytes'], utf8.encode(content).length);
      expect(context.last['truncated'], isFalse);
    },
  );

  test(
    'missing retained pages are reread with approval and legacy success codes are hidden',
    () async {
      await open(limits: TaskSegmentLimits(maxToolCalls: 1));
      await source.writeAsString('# Report\nOriginal body.\n');
      read();
      await h.run();
      // Simulate a checkpoint that contains only the old audit summaries, or an
      // evicted page. Existing successful attempts must remain immutable.
      final row =
          (await h.db.database.query('conversation_task_checkpoints')).single;
      final checkpoint = jsonDecode(row['checkpoint_json']! as String) as Map;
      (checkpoint['execution'] as Map).remove('fileReads');
      await h.db.database.update('conversation_task_checkpoints', {
        'checkpoint_json': jsonEncode(checkpoint),
      });
      await h.db.database.update('tool_execution_records', {
        'error_code': 'tool_failed',
      });
      await h.db.reopen();
      h.policy.outcome = ToolPolicyOutcome.requireApproval;
      read();
      expect(await h.run(), isA<TaskApprovalWait>());
      expect((modelState()['observations'] as List).single['error_code'], '');
      await approve();
      expect(await h.run(), isA<TaskContinueSegment>());
      final snapshot = await h.snapshot;
      expect(h.tool.starts, 2);
      expect(snapshot.attempts, hasLength(2));
      expect(
        snapshot.checkpoint!.execution!.fileReads.single.content,
        '# Report\nOriginal body.\n',
      );
      expect(
        snapshot.attemptLinks.map((link) => link.idempotencyKey).toSet(),
        hasLength(2),
      );
    },
  );

  test(
    'UTF-8 BOM bytes remain included in page continuation offsets',
    () async {
      await open(limits: TaskSegmentLimits(maxToolCalls: 1));
      final content = '${'界' * 23000}\nEnd\n';
      final bytes = [0xef, 0xbb, 0xbf, ...utf8.encode(content)];
      await source.writeAsBytes(bytes);
      read({'max_bytes': 262144});
      expect(await h.run(), isA<TaskContinueSegment>());
      await h.db.reopen();
      final first = (await h.snapshot).checkpoint!.execution!.fileReads.single;
      expect(first.nextOffsetBytes, utf8.encode(first.content).length + 3);
      expect(first.nextOffsetBytes, lessThanOrEqualTo(65536));
      read({'offset_bytes': first.nextOffsetBytes});
      expect(await h.run(), isA<TaskContinueSegment>());
      final last = (await h.snapshot).checkpoint!.execution!.fileReads.last;
      expect(first.content + last.content, content);
      expect(last.nextOffsetBytes, bytes.length);
      expect(last.truncated, isFalse);
    },
  );

  test(
    'successful writes invalidate cached pages within the same step',
    () async {
      await open();
      await source.writeAsString('Before\n');
      h.models.events([
        ToolCallRequested(
          callId: 'before',
          name: 'read_local_file',
          arguments: {'path': source.path},
        ),
        ToolCallRequested(
          callId: 'write',
          name: 'write_local_file',
          arguments: {
            'path': source.path,
            'content': 'After\n',
            'mode': 'overwrite',
          },
        ),
        ToolCallRequested(
          callId: 'after',
          name: 'read_local_file',
          arguments: {'path': source.path},
        ),
        const ModelTurnCompleted(stopReason: 'tool_calls'),
      ]);
      h.models.tool(
        name: 'write_local_file',
        arguments: {
          'path': source.path,
          'content': 'Final\n',
          'mode': 'overwrite',
        },
      );
      read();
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(h.tool.starts, 3);
      expect(h.tool.keys.toSet(), hasLength(3));
      expect(
        (await h.snapshot).checkpoint!.execution!.fileReads.single.content,
        'Final\n',
      );
    },
  );

  test(
    'redaction preserves source offsets and safe Markdown formatting',
    () async {
      await open(limits: TaskSegmentLimits(maxToolCalls: 1));
      const content = '# Report\n\npassword=private-value\n\n## End\n界\n';
      await source.writeAsString(content);
      read();
      expect(await h.run(), isA<TaskContinueSegment>());
      await h.db.reopen();
      final page = (await h.snapshot).checkpoint!.execution!.fileReads.single;
      expect(page.content, '# Report\n\npassword=[redacted]\n\n## End\n界\n');
      expect(page.redacted, isTrue);
      expect(page.nextOffsetBytes, utf8.encode(content).length);
      expect(page.truncated, isFalse);
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(
        h.models.requests.last.messages.last.content,
        isNot(contains('private-value')),
      );
      expect(
        (modelState()['file_reads'] as List).single['content_redacted'],
        isTrue,
      );
    },
  );

  test(
    'base64 pages retain binary bytes and resume at the source offset',
    () async {
      await open(limits: TaskSegmentLimits(maxToolCalls: 1));
      final bytes = List.generate(70000, (index) => index % 256);
      await source.writeAsBytes(bytes);
      read({'encoding': 'base64', 'max_bytes': 262144});
      expect(await h.run(), isA<TaskContinueSegment>());
      await h.db.reopen();
      final first = (await h.snapshot).checkpoint!.execution!.fileReads.single;
      expect(base64Decode(first.content), bytes.take(65536));
      expect(first.nextOffsetBytes, 65536);
      expect(first.truncated, isTrue);
      read({'encoding': 'base64', 'offset_bytes': first.nextOffsetBytes});
      expect(await h.run(), isA<TaskContinueSegment>());
      final last = (await h.snapshot).checkpoint!.execution!.fileReads.last;
      expect(base64Decode(last.content), bytes.skip(65536));
      expect(last.nextOffsetBytes, bytes.length);
      expect(last.truncated, isFalse);
    },
  );

  test('a later step reads again to observe external file changes', () async {
    await open(limits: TaskSegmentLimits(maxToolCalls: 1), steps: 2);
    await source.writeAsString('Before\n');
    read();
    expect(await h.run(), isA<TaskContinueSegment>());
    await source.writeAsString('Changed externally\n');
    h.models.completeStep();
    read();
    expect(await h.run(), isA<TaskContinueSegment>());
    expect(h.tool.starts, 2);
    final pages = (await h.snapshot).checkpoint!.execution!.fileReads;
    expect(pages.map((page) => page.stepId).toSet(), hasLength(2));
    expect(pages.last.content, 'Changed externally\n');
  });

  test(
    'file content and success roll back together when checkpoint storage fails',
    () async {
      await open();
      await source.writeAsString('# Report\nBody\n');
      await h.db.failWrite(
        'conversation_task_checkpoints',
        operation: 'UPDATE',
        when: "instr(NEW.checkpoint_json, '\"fileReads\"') > 0",
      );
      read();
      await expectLater(h.run(), throwsA(isA<Exception>()));
      final snapshot = await h.snapshot;
      expect(snapshot.attempts.single.status, ToolInvocationStatus.running);
      expect(snapshot.checkpoint!.execution!.fileReads, isEmpty);
      expect(snapshot.evidence, isEmpty);
    },
  );
}
