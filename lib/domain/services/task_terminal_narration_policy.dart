import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/services/task_execution_details.dart';

part 'task_terminal_strings.dart';

final class TaskTerminalNarration {
  const TaskTerminalNarration(this.candidate, {required this.usedFallback});
  final GroundedAnswerCandidate candidate;
  String get text => candidate.renderedText;
  final bool usedFallback;
}

/// Accepts natural wording; factual claims are validated by the task finalizer.
final class TaskTerminalNarrationPolicy {
  const TaskTerminalNarrationPolicy();

  TaskTerminalNarration fallback({
    required TaskTerminalSummary summary,
    required String language,
    List<AnswerClaim> verifiedClaims = const [],
  }) {
    final words = TaskTerminalStrings(language);
    return TaskTerminalNarration(
      GroundedAnswerCandidate(
        claims: [
          AnswerClaim(
            claimId: 'terminal:outcome',
            text:
                '${summary.status == ConversationTaskStatus.cancelled ? words.cancelled : words.failed} ${summary.safeReason}',
            kind: ClaimKind.nonFactual,
          ),
          ...verifiedClaims,
          if (summary.sideEffectStatus == TaskSideEffectStatus.irreversible)
            AnswerClaim(
              claimId: 'terminal:effects',
              text: words.irreversible,
              kind: ClaimKind.nonFactual,
            ),
        ],
      ),
      usedFallback: true,
    );
  }

  TaskTerminalNarration evaluate({
    required TaskTerminalSummary summary,
    required String language,
    GroundedAnswerCandidate? draft,
    List<AnswerClaim> verifiedClaims = const [],
  }) {
    if (draft != null &&
        draft.renderedText.length <= 16000 &&
        taskExecutionText(draft.renderedText, maximum: 16000) ==
            draft.renderedText &&
        (draft.nonFactualText.isNotEmpty ||
            draft.claims.any((claim) => claim.kind == ClaimKind.nonFactual))) {
      return TaskTerminalNarration(draft, usedFallback: false);
    }
    return fallback(
      summary: summary,
      language: language,
      verifiedClaims: verifiedClaims,
    );
  }
}
