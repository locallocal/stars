import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';

/// Persisted marker rendered as a localized strict-mode notice in chat lists.
///
/// Keeping the marker language-neutral lets previews follow the current app
/// locale without ever persisting an unverified factual answer as the preview.
const strictGroundingPreviewMarker = '[[stars:verification-unavailable]]';

/// The content that may cross a strict-mode presentation or export boundary.
final class StrictGroundingPresentation {
  const StrictGroundingPresentation({
    required this.content,
    required this.suppressedFacts,
    required this.hasNotFactCheckedContent,
  });

  final String content;
  final bool suppressedFacts;
  final bool hasNotFactCheckedContent;
}

/// Removes non-verified factual claims without mutating the audit record.
final class StrictGroundingPolicy {
  const StrictGroundingPolicy();

  StrictGroundingPresentation present(Message message) {
    final grounding = message.grounding;
    final claims = grounding.claims;
    if (claims.isEmpty) {
      final isDeclaredNonFactual =
          grounding.reasonCode == 'no_verifiable_claims';
      return StrictGroundingPresentation(
        content: isDeclaredNonFactual ? message.content : '',
        suppressedFacts: message.content.isNotEmpty && !isDeclaredNonFactual,
        hasNotFactCheckedContent:
            message.content.isNotEmpty && isDeclaredNonFactual,
      );
    }

    final safeSegments = <String>[];
    var suppressedFacts = false;
    var hasNotFactCheckedContent = false;
    for (final grounding in claims) {
      if (_requiresVerification(grounding.claim.kind)) {
        if (grounding.trustLevel == ClaimTrustLevel.verified) {
          safeSegments.add(grounding.claim.text);
        } else {
          suppressedFacts = true;
        }
      } else {
        safeSegments.add(grounding.claim.text);
        hasNotFactCheckedContent = true;
      }
    }
    final structuredContent = claims
        .map((grounding) => grounding.claim.text)
        .join('\n\n');
    if (message.content.trim() != structuredContent) {
      suppressedFacts = message.content.trim().isNotEmpty;
    }

    return StrictGroundingPresentation(
      content: safeSegments.join('\n\n'),
      suppressedFacts: suppressedFacts,
      hasNotFactCheckedContent: hasNotFactCheckedContent,
    );
  }

  String previewFor(Message message) {
    final presentation = present(message);
    if (presentation.suppressedFacts) return strictGroundingPreviewMarker;
    return presentation.content;
  }
}

bool _requiresVerification(ClaimKind kind) => switch (kind) {
  ClaimKind.externalFact ||
  ClaimKind.currentFact ||
  ClaimKind.completedAction ||
  ClaimKind.executionFailure => true,
  ClaimKind.userAssertion || ClaimKind.nonFactual => false,
};
