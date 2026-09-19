import 'dart:async';

import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart' show ModelTokenUsage;
import 'package:stars/domain/models/task_terminal_metrics.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_terminal_narration_policy.dart';

final class TaskTerminalNarrationRequest {
  TaskTerminalNarrationRequest({
    required this.summary,
    required this.language,
    this.context = '',
    List<AnswerClaim> verifiedClaims = const [],
    List<GroundedClaimSynthesisRequirement> availableClaims = const [],
    List<GroundedEvidenceReference> evidence = const [],
    this.timeout = const Duration(seconds: 15),
    this.onTokenUsage,
  }) : verifiedClaims = List.unmodifiable(verifiedClaims),
       availableClaims = List.unmodifiable(availableClaims),
       evidence = List.unmodifiable(evidence);
  final TaskTerminalSummary summary;
  final String language;
  final String context;
  final List<AnswerClaim> verifiedClaims;
  final List<GroundedClaimSynthesisRequirement> availableClaims;
  final List<GroundedEvidenceReference> evidence;
  final Duration timeout;
  final void Function(ModelTokenUsage)? onTokenUsage;
}

typedef TaskTerminalPolisher =
    Future<GroundedAnswerCandidate> Function(
      TaskTerminalNarrationRequest request,
      AgentCancellationToken cancellation,
    );

/// One bounded attempt outside the commit transaction, with no repair call.
final class NarrateConversationTaskTerminal {
  NarrateConversationTaskTerminal({
    this.policy = const TaskTerminalNarrationPolicy(),
    this.timeout = const Duration(seconds: 15),
    TaskTerminalMetrics? metrics,
  }) : metrics = metrics ?? TaskTerminalMetrics();
  final TaskTerminalNarrationPolicy policy;
  final Duration timeout;
  final TaskTerminalMetrics metrics;

  Future<TaskTerminalNarration> call({
    required TaskTerminalSummary summary,
    required String language,
    String context = '',
    List<AnswerClaim> verifiedClaims = const [],
    List<GroundedClaimSynthesisRequirement> availableClaims = const [],
    List<GroundedEvidenceReference> evidence = const [],
    Future<bool> Function(GroundedAnswerCandidate)? validate,
    TaskTerminalPolisher? polish,
    void Function(ModelTokenUsage)? onTokenUsage,
  }) async {
    metrics.narrationAttempts++;
    final token = AgentCancellationToken();
    GroundedAnswerCandidate? draft;
    try {
      if (polish != null) {
        draft = await polish(
          TaskTerminalNarrationRequest(
            summary: summary,
            language: language,
            context: context,
            verifiedClaims: verifiedClaims,
            availableClaims: availableClaims,
            evidence: evidence,
            timeout: timeout,
            onTokenUsage: (usage) {
              if (!token.isCancelled &&
                  usage.inputTokens >= 0 &&
                  usage.outputTokens >= 0 &&
                  usage.totalTokens >= 0) {
                onTokenUsage?.call(usage);
              }
            },
          ),
          token,
        ).timeout(timeout);
      }
    } on Object {
      metrics.narrationFailures++;
    } finally {
      token.cancel();
    }
    var result = policy.evaluate(
      summary: summary,
      language: language,
      draft: draft,
      verifiedClaims: verifiedClaims,
    );
    if (!result.usedFallback &&
        validate != null &&
        !await validate(result.candidate)) {
      result = policy.fallback(
        summary: summary,
        language: language,
        verifiedClaims: verifiedClaims,
      );
    }
    if (result.usedFallback) metrics.narrationFallbacks++;
    return result;
  }
}
