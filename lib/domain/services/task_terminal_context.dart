import 'dart:convert';

import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/services/task_execution_details.dart';
import 'package:stars/domain/services/task_safe_data.dart';

/// Bounded, redacted task facts for the final reply; tool text is untrusted data.
String taskTerminalContext(TaskExecutionSnapshot snapshot) {
  final task = snapshot.task;
  final attempts =
      snapshot.attempts.toList()
        ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
  final completed = snapshot.checkpoint?.completedStepIds.toSet() ?? {};
  return jsonEncode({
    'objective': taskExecutionText(task.objective, maximum: 4000),
    'conversation': [
      for (final message
          in task.acceptance.context.reversed.take(8).toList().reversed)
        {
          'role': message.role.name,
          'content': taskExecutionText(message.content, maximum: 2000),
        },
    ],
    'current_step': taskExecutionText(task.progress.currentStepSummary),
    'steps': [
      for (final step in snapshot.plan.steps.take(24))
        {
          'summary': taskExecutionText(step.summary, maximum: 500),
          'completed': completed.contains(step.stepId),
        },
    ],
    'recent_attempts': [
      for (final attempt in attempts.reversed.take(8).toList().reversed)
        {
          'tool': attempt.name,
          'status': attempt.status.name,
          'arguments': _detail(attempt.argumentsSummary),
          'result': _detail(attempt.resultSummary),
          'detail': _detail(attempt.detail),
          'error_code': taskExecutionText(attempt.errorCode, maximum: 500),
        },
    ],
  });
}

String _detail(String value) {
  var source = value;
  try {
    source = jsonEncode(
      taskSafeObject(jsonDecode(value), preserveFormatting: true),
    );
  } on FormatException {
    // Plain-text stdout/stderr use the same redaction as structured results.
  }
  final safe = taskExecutionText(source, maximum: source.length * 4 + 2000);
  if (safe.length <= 2000) return safe;
  // Errors often follow a large stdout block. Keep both ends after redaction.
  return '${safe.substring(0, 900)}\n… [truncated]\n${safe.substring(safe.length - 1000)}';
}
