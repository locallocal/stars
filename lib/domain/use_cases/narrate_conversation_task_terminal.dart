import 'dart:async';

import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_terminal_metrics.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_terminal_narration_policy.dart';

final class TaskTerminalNarrationRequest {
  TaskTerminalNarrationRequest({
    required this.summary,
    required this.language,
    required List<String> allowedNarrations,
  }) : allowedNarrations = List.unmodifiable(allowedNarrations);
  final TaskTerminalSummary summary;
  final String language;
  final List<String> allowedNarrations;
}

typedef TaskTerminalPolisher =
    Future<String> Function(
      TaskTerminalNarrationRequest request,
      AgentCancellationToken cancellation,
    );

/// One bounded attempt outside the commit transaction, with no repair call.
final class NarrateConversationTaskTerminal {
  NarrateConversationTaskTerminal({
    this.policy = const TaskTerminalNarrationPolicy(),
    this.timeout = const Duration(seconds: 2),
    TaskTerminalMetrics? metrics,
  }) : metrics = metrics ?? TaskTerminalMetrics();
  final TaskTerminalNarrationPolicy policy;
  final Duration timeout;
  final TaskTerminalMetrics metrics;

  Future<TaskTerminalNarration> call({
    required TaskTerminalSummary summary,
    required String language,
    TaskTerminalPolisher? polish,
  }) async {
    metrics.narrationAttempts++;
    final token = AgentCancellationToken();
    var draft = '';
    try {
      if (polish != null) {
        draft = await polish(
          TaskTerminalNarrationRequest(
            summary: summary,
            language: language,
            allowedNarrations: policy.alternatives(summary, language),
          ),
          token,
        ).timeout(timeout);
      }
    } on Object {
      metrics.narrationFailures++;
    } finally {
      token.cancel();
    }
    final result = policy.evaluate(
      summary: summary,
      language: language,
      draft: draft,
    );
    if (result.usedFallback) metrics.narrationFallbacks++;
    return result;
  }
}
