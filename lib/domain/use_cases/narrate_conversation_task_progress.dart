import 'dart:async';

import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_progress_narration_policy.dart';
import 'package:stars/domain/services/task_safe_data.dart';

final class TaskProgressMetrics {
  int cards = 0, requests = 0, modelCalls = 0, repairs = 0, failures = 0;
  Duration cardLatency = Duration.zero, narrationLatency = Duration.zero;
  double get failureRatio => requests == 0 ? 0 : failures / requests;
}

final class TaskProgressNarrationRequest {
  TaskProgressNarrationRequest({
    required this.chatId,
    required List<Map<String, Object?>> summaries,
    required this.question,
    required this.language,
    required this.repair,
    required this.timeout,
    this.requestedTaskId,
  }) : summaries = List.unmodifiable(
         summaries.map(Map<String, Object?>.unmodifiable),
       );

  final List<Map<String, Object?>> summaries;
  final String chatId;
  final String question;
  final String language;
  final String? requestedTaskId;
  final bool repair;
  final Duration timeout;
}

typedef TaskProgressPolisher =
    Future<String> Function(
      TaskProgressNarrationRequest request,
      AgentCancellationToken cancellation,
    );

final class TaskProgressNarrationException implements Exception {
  const TaskProgressNarrationException();
}

/// Generates a reply from frozen task facts without substituting canned prose.
final class NarrateConversationTaskProgress {
  NarrateConversationTaskProgress({
    this.policy = const TaskProgressNarrationPolicy(),
    this.timeout = const Duration(seconds: 15),
    TaskProgressMetrics? metrics,
  }) : metrics = metrics ?? TaskProgressMetrics();
  final TaskProgressNarrationPolicy policy;
  final Duration timeout;
  final TaskProgressMetrics metrics;

  Future<String> call({
    required String chatId,
    required List<ConversationTaskProgressSummary> summaries,
    required String language,
    String question = '',
    String? requestedTaskId,
    TaskProgressPolisher? polish,
    AgentCancellationToken? cancellation,
  }) async {
    metrics.requests++;
    final elapsed = Stopwatch()..start();
    try {
      cancellation?.throwIfCancelled();
      if (polish != null) {
        final facts = summaries.map(policy.facts).toList(growable: false);
        for (var attempt = 0; attempt < 2; attempt++) {
          final token = AgentCancellationToken();
          try {
            cancellation?.throwIfCancelled();
            metrics.modelCalls++;
            final draft = await Future.any([
              polish(
                TaskProgressNarrationRequest(
                  chatId: chatId,
                  summaries: facts,
                  question: taskSafeText(
                    question,
                    maximum: 8000,
                    structured: true,
                  ),
                  language: language,
                  requestedTaskId: requestedTaskId,
                  repair: attempt > 0,
                  timeout: timeout,
                ),
                token,
              ).timeout(timeout),
              if (cancellation != null)
                cancellation.whenCancelled.then<String>((_) {
                  throw const AgentRunCancelledException();
                }),
            ]);
            cancellation?.throwIfCancelled();
            final text = policy.validate(draft);
            if (text != null) return text;
            if (attempt == 0) metrics.repairs++;
          } on AgentRunCancelledException {
            rethrow;
          } on Object {
            break;
          } finally {
            token.cancel();
          }
        }
      }
      metrics.failures++;
      throw const TaskProgressNarrationException();
    } finally {
      metrics.narrationLatency += elapsed.elapsed;
    }
  }
}
