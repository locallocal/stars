import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/local_file_system_tools.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import '../../support/task_runner_harness.dart';

void main() {
  late TaskRunnerHarness h;
  setUp(() => h = TaskRunnerHarness());
  tearDown(() => h.close());

  final tools = [
    ReadLocalFileTool().definition,
    WriteLocalFileTool().definition,
    ToolDefinition(
      name: 'mcp.server-1.save',
      description: 'Save a remote report',
      inputSchema: const {'type': 'object'},
      source: ToolSource.mcp,
      riskLevel: ToolRiskLevel.write,
      capabilities: const {
        ToolCapability.network,
        ToolCapability.externalWrite,
      },
    ),
  ];
  for (final definition in tools) {
    for (final exempt in [true, false]) {
      test(
        '${definition.name} preserves exempt=$exempt across restart',
        () async {
          final name = definition.name;
          await h.open(
            acceptance: taskAcceptance(
              allowedToolNames: {name, 'other_tool'},
              approvalExemptToolNames: {if (exempt) name, 'other_tool'},
              limits: TaskSegmentLimits(maxModelTurns: 1, maxToolCalls: 1),
            ),
          );
          h.clock.time = DateTime.now().toUtc().add(const Duration(minutes: 1));
          final file = File('${h.db.directory.path}/report.txt');
          await file.writeAsString('original report');
          h.tool = RunnerTool(
            definition: definition,
            checkpointArgumentNames: {'path', 'content', 'mode'},
          );
          final ExecutableTool? local = switch (name) {
            'read_local_file' => ReadLocalFileTool(),
            'write_local_file' => WriteLocalFileTool(),
            _ => null,
          };
          if (local != null) {
            h.tool.onStart =
                (call) async => ToolCompleted(
                  await local.execute(call, AgentCancellationToken()),
                );
          }
          h.policyOverride = const DefaultToolPolicy(
            allowDestructiveWithApproval: true,
          );
          h.models.tool(
            name: name,
            arguments: {
              if (local != null) 'path': file.path,
              if (name == 'write_local_file') ...{
                'content': 'updated report',
                'mode': 'overwrite',
              },
            },
          );
          expect(await h.run(), isA<TaskContinueSegment>());
          expect(h.tool.starts, 0);
          await h.db.reopen();

          final result = await h.run();
          if (exempt) {
            expect(result, isA<TaskContinueSegment>());
            expect(h.tool.starts, 1);
            expect(result.snapshot.approvals, isEmpty);
            expect(
              result.snapshot.attempts.single.status,
              ToolInvocationStatus.succeeded,
            );
            expect(
              result.snapshot.events.map((event) => event.kind),
              isNot(contains(TaskEventKind.approvalRequested)),
            );
          } else {
            expect(result, isA<TaskApprovalWait>());
            expect(h.tool.starts, 0);
            expect(result.snapshot.approvals, hasLength(1));
            expect(
              result.snapshot.task.waitingReason,
              TaskWaitingReason.approval,
            );
          }
          expect(
            await file.readAsString(),
            exempt && name == 'write_local_file'
                ? 'updated report'
                : 'original report',
          );
        },
      );
    }
  }

  test('a frozen grant does not override a disabled tool capability', () async {
    final definition = tools[1];
    await h.open(
      acceptance: taskAcceptance(
        allowedToolNames: {definition.name},
        approvalExemptToolNames: {definition.name},
      ),
    );
    h.policyOverride = const DefaultToolPolicy();
    h.tool = RunnerTool(
      definition: definition,
      checkpointArgumentNames: {'path', 'content', 'mode'},
    );
    h.models.tool(
      name: definition.name,
      arguments: {
        'path': '${h.db.directory.path}/denied.txt',
        'content': 'not written',
        'mode': 'create',
      },
    );
    final result = await h.run() as TaskNeedsSafeFinalization;
    expect(result.reasonCode, TaskReasonCode.permissionDenied);
    expect(h.tool.starts, 0);
    expect(result.snapshot.approvals, isEmpty);
  });
}
