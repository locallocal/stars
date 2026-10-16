import 'dart:convert';

import 'package:stars/domain/models/skill_installer.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_tool_observation.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_skill_source_policy.dart';

/// Finishing a plan or writing a disclaimer is not an installation receipt.
/// Check committed attempts independently of the model's completion wording.
bool taskSkillInstallationIncomplete(TaskExecutionSnapshot snapshot) {
  final installs = snapshot.attempts.where(
    (attempt) => attempt.name == installSkillToolName,
  );
  if (installs.isEmpty) {
    return snapshot.plan.allowedToolNames.contains(installSkillToolName);
  }
  final successfulKeys = {
    for (final attempt in installs)
      if (attempt.status == ToolInvocationStatus.succeeded)
        attempt.invocationId,
  };
  if (installs.any(
    (attempt) => !successfulKeys.contains(attempt.invocationId),
  )) {
    return true;
  }

  final installedSources = <String>{};
  for (final attempt in installs.where(
    (a) => a.status == ToolInvocationStatus.succeeded,
  )) {
    final arguments = _arguments(attempt.argumentsSummary);
    if (arguments != null) {
      if (_sourceKey(arguments) case final key?) installedSources.add(key);
    }
  }
  final observations = <String, TaskToolObservation>{
    for (final item
        in snapshot.checkpoint?.execution?.toolResults ??
            const <TaskToolObservation>[])
      item.attemptId: item,
  };
  final latestResolutions = <String, ToolExecutionRecord>{};
  for (final attempt in snapshot.attempts.where(
    (a) =>
        a.name == resolveSkillSourceToolName &&
        a.status == ToolInvocationStatus.succeeded,
  )) {
    final source = _arguments(attempt.argumentsSummary)?['source'];
    latestResolutions[source is String ? source : attempt.attemptId] = attempt;
  }
  for (final attempt in latestResolutions.values) {
    final result = observations[attempt.attemptId];
    if (result == null || !usableTaskSkillSources(result)) return true;
    final data = result.structuredContent! as Map<String, Object?>;
    final sources = data['skills']! as List<Object?>;
    if (sources.any(
      (source) =>
          !installedSources.contains(
            _sourceKey(source! as Map<String, Object?>),
          ),
    )) {
      return true;
    }
  }
  return false;
}

Map<String, Object?>? _arguments(String encoded) {
  try {
    final value = jsonDecode(encoded);
    return value is Map<String, Object?> ? value : null;
  } on FormatException {
    return null;
  }
}

String? _sourceKey(Map<String, Object?> source) {
  const fields = ['source_type', 'source', 'ref', 'subdirectory'];
  if (fields.any((key) => source[key] != null && source[key] is! String)) {
    return null;
  }
  return jsonEncode([
    for (final key in fields) (source[key] as String? ?? '').trim(),
  ]);
}
