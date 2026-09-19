import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_terminal_context.dart';

import '../../support/conversation_task_repository_harness.dart';

void main() {
  test(
    'long diagnostic output retains the final error within the context budget',
    () {
      final task = taskFixture();
      final data =
          jsonDecode(
                taskTerminalContext(
                  TaskExecutionSnapshot(
                    task: task,
                    plan: taskPlan(task),
                    lastSequence: 1,
                    attempts: [
                      taskTool(
                        at: taskTime,
                        status: ToolInvocationStatus.failed,
                        summary:
                            'stdout:\n${'Reading data\n' * 500}\nstderr:\nPermission denied: sales.xlsx',
                      ),
                    ],
                  ),
                ),
              )
              as Map<String, dynamic>;
      final result =
          ((data['recent_attempts'] as List).single as Map)['result'] as String;
      expect(result, startsWith('stdout:'));
      expect(result, endsWith('Permission denied: sales.xlsx'));
      expect(result, contains('[truncated]'));
      expect(result.length, lessThanOrEqualTo(2000));
    },
  );

  test(
    'terminal context keeps recent execution causes and redacts before truncation',
    () {
      final task = taskFixture();
      final snapshot = TaskExecutionSnapshot(
        task: task,
        plan: taskPlan(task),
        lastSequence: 20,
        attempts:
            [
              for (var i = 0; i < 12; i++)
                taskTool(
                  at: taskTime.add(Duration(seconds: i)),
                  name: 'tool_$i',
                  status:
                      i == 11
                          ? ToolInvocationStatus.failed
                          : ToolInvocationStatus.succeeded,
                  arguments: jsonEncode({
                    'path': 'sales.xlsx',
                    'secret': 'hidden-value',
                    'reasoning': 'hidden-reasoning',
                  }),
                  summary:
                      'Missing file sales.xlsx. api_key=${'secret' * 1000}',
                ),
            ].reversed.toList(),
      );
      final encoded = taskTerminalContext(snapshot);
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      final attempts = data['recent_attempts'] as List;
      expect(attempts, hasLength(8));
      expect((attempts.first as Map)['tool'], 'tool_4');
      expect((attempts.last as Map)['status'], 'failed');
      expect(encoded, contains('Missing file sales.xlsx'));
      expect(encoded, isNot(contains('hidden-value')));
      expect(encoded, isNot(contains('hidden-reasoning')));
      expect(encoded, isNot(contains('secretsecret')));
      expect(encoded, contains('[redacted]'));
      expect(data['objective'], task.objective);
      expect((data['conversation'] as List).single['content'], '整理报告');
    },
  );
}
