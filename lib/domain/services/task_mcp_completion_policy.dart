import 'dart:convert';

import 'package:stars/domain/models/mcp_installer.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/tool.dart';

/// A saved configuration is a completed installation only when the requested
/// connection succeeded, or the user explicitly requested save-only behavior.
bool taskMcpInstallationIncomplete(TaskExecutionSnapshot snapshot) {
  final installs = snapshot.attempts.where(
    (a) => a.name == addMcpServerToolName,
  );
  if (installs.isEmpty) {
    return snapshot.plan.allowedToolNames.contains(addMcpServerToolName);
  }
  final completed = <String>{};
  for (final attempt in installs) {
    if (attempt.status != ToolInvocationStatus.succeeded) continue;
    final observation =
        snapshot.checkpoint?.execution?.toolResults
            .where((item) => item.attemptId == attempt.attemptId)
            .firstOrNull;
    final data = observation?.structuredContent;
    if (data is! Map<String, Object?> ||
        data['server_id'] is! String ||
        (data['server_id']! as String).isEmpty ||
        data['connection_error'] != null) {
      continue;
    }
    final Map<String, Object?> arguments;
    try {
      final decoded = jsonDecode(attempt.argumentsSummary);
      if (decoded is! Map<String, Object?>) continue;
      arguments = decoded;
    } on FormatException {
      continue;
    }
    if (arguments['connect'] == false ||
        data['connection_status'] == 'connected') {
      completed.add(attempt.invocationId);
    }
  }
  return installs.any((attempt) => !completed.contains(attempt.invocationId));
}
