import 'dart:async';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_progress_narration_policy.dart';

final class TaskProgressMetrics {
  int cards = 0,
      requests = 0,
      modelCalls = 0,
      repairs = 0,
      fallbacks = 0,
      stale = 0;
  Duration cardLatency = Duration.zero, narrationLatency = Duration.zero;
  double get fallbackRatio => requests == 0 ? 0 : fallbacks / requests;
}

final class TaskProgressNarrationRequest {
  TaskProgressNarrationRequest({
    required this.chatId,
    required this.summary,
    required this.language,
    required this.allowedNarrations,
    required this.repair,
  });
  final Map<String, Object?> summary;
  final String chatId;
  final String language;
  final List<String> allowedNarrations;
  final bool repair;
}

typedef TaskProgressPolisher =
    Future<String> Function(
      TaskProgressNarrationRequest request,
      AgentCancellationToken cancellation,
    );

final class NarrateConversationTaskProgress {
  NarrateConversationTaskProgress({
    this.policy = const TaskProgressNarrationPolicy(),
    this.timeout = const Duration(seconds: 2),
    TaskProgressMetrics? metrics,
  }) : metrics = metrics ?? TaskProgressMetrics();
  final TaskProgressNarrationPolicy policy;
  final Duration timeout;
  final TaskProgressMetrics metrics;

  Future<String> call({
    required ConversationTaskProgressSummary summary,
    required String language,
    TaskProgressPolisher? polish,
  }) async {
    metrics.requests++;
    final elapsed = Stopwatch()..start();
    try {
      if (polish != null) {
        for (var attempt = 0; attempt < 2; attempt++) {
          final token = AgentCancellationToken();
          try {
            metrics.modelCalls++;
            final draft = await polish(
              TaskProgressNarrationRequest(
                chatId: summary.chatId,
                summary: Map.unmodifiable(policy.facts(summary)),
                language: language,
                allowedNarrations: List.unmodifiable(
                  policy.alternatives(summary, language),
                ),
                repair: attempt > 0,
              ),
              token,
            ).timeout(timeout);
            final text = policy.validate(draft, summary, language);
            if (text != null) return text;
            if (attempt == 0) metrics.repairs++;
          } on Object {
            break;
          } finally {
            token.cancel();
          }
        }
      }
      metrics.fallbacks++;
      return policy.alternatives(summary, language).first;
    } finally {
      metrics.narrationLatency += elapsed.elapsed;
    }
  }
}
