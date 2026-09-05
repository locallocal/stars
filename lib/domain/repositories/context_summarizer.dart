import 'package:stars/domain/models/conversation_memory.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/tool.dart';

enum ContextSourceRole { user, assistant }

final class ContextEvidenceSummary {
  const ContextEvidenceSummary({
    required this.evidenceId,
    required this.toolName,
    required this.source,
    required this.resultSummary,
    required this.observedAt,
    this.validUntil,
  });

  factory ContextEvidenceSummary.fromRecord(ToolEvidenceRecord record) =>
      ContextEvidenceSummary(
        evidenceId: record.evidenceId,
        toolName: record.toolName,
        source: record.source,
        resultSummary: record.resultSummary,
        observedAt: record.observedAt.toUtc(),
        validUntil: record.validUntil?.toUtc(),
      );

  final String evidenceId;
  final String toolName;
  final ToolSource source;
  final String resultSummary;
  final DateTime observedAt;
  final DateTime? validUntil;
}

final class ContextClaimEvidence {
  ContextClaimEvidence({
    required this.referenceId,
    required this.claimId,
    required this.text,
    required this.kind,
    required this.trustLevel,
    required List<String> evidenceIds,
    required List<ContextEvidenceSummary> evidence,
  }) : evidenceIds = List.unmodifiable(evidenceIds),
       evidence = List.unmodifiable(evidence);

  final String referenceId;
  final String claimId;
  final String text;
  final ClaimKind kind;
  final ClaimTrustLevel trustLevel;
  final List<String> evidenceIds;
  final List<ContextEvidenceSummary> evidence;

  bool isVerifiedAt(DateTime instant) {
    if (trustLevel != ClaimTrustLevel.verified || evidenceIds.isEmpty) {
      return false;
    }
    final evaluatedAt = instant.toUtc();
    final summaries = {for (final item in evidence) item.evidenceId: item};
    if (summaries.length != evidenceIds.length ||
        !summaries.keys.toSet().containsAll(evidenceIds)) {
      return false;
    }
    if (evidence.any(
      (item) =>
          item.observedAt.isAfter(evaluatedAt) ||
          (item.validUntil != null && !item.validUntil!.isAfter(evaluatedAt)),
    )) {
      return false;
    }
    if (kind != ClaimKind.currentFact) return true;
    return evidence.every((item) => item.validUntil != null);
  }

  bool requiresReverificationAt(DateTime instant) =>
      kind == ClaimKind.currentFact && !isVerifiedAt(instant);

  DateTime? get expiresAt {
    if (kind != ClaimKind.currentFact || evidence.isEmpty) return null;
    final values =
        evidence.map((item) => item.validUntil).whereType<DateTime>();
    if (values.length != evidence.length) return null;
    return values.reduce((left, right) => left.isBefore(right) ? left : right);
  }
}

String contextClaimReference(String messageId, String claimId) =>
    '$messageId#$claimId';

final class ContextSourceEvidence {
  ContextSourceEvidence({
    required this.messageId,
    required this.role,
    List<ContextClaimEvidence> claims = const [],
  }) : claims = List.unmodifiable(claims);

  factory ContextSourceEvidence.fromMessage(
    Message message, {
    Map<String, ToolEvidenceRecord> evidenceById = const {},
  }) {
    final isAssistant = message.senderId == message.botId;
    final canRetainClaimTrust =
        isAssistant &&
        message.terminalOutcome == MessageTerminalOutcome.completed &&
        !message.hasPartialContent &&
        (message.grounding.trustLevel == AnswerTrustLevel.verified ||
            message.grounding.trustLevel == AnswerTrustLevel.partiallyVerified);
    return ContextSourceEvidence(
      messageId: message.messageId,
      role: isAssistant ? ContextSourceRole.assistant : ContextSourceRole.user,
      claims: [
        if (isAssistant)
          for (final grounding in message.grounding.claims)
            ContextClaimEvidence(
              referenceId: contextClaimReference(
                message.messageId,
                grounding.claim.claimId,
              ),
              claimId: grounding.claim.claimId,
              text: grounding.claim.text,
              kind: grounding.claim.kind,
              trustLevel:
                  canRetainClaimTrust
                      ? grounding.trustLevel
                      : ClaimTrustLevel.unverified,
              evidenceIds: grounding.acceptedEvidenceIds,
              evidence: [
                for (final evidenceId in grounding.acceptedEvidenceIds)
                  if (evidenceById[evidenceId] case final record?)
                    ContextEvidenceSummary.fromRecord(record),
              ],
            ),
      ],
    );
  }

  final String messageId;
  final ContextSourceRole role;
  final List<ContextClaimEvidence> claims;
}

final class ContextSummaryRequest {
  ContextSummaryRequest({
    required this.chatId,
    required this.summaryId,
    required List<Message> sourceMessages,
    List<ContextSourceEvidence> sourceEvidence = const [],
    this.previousSummary,
    required this.targetTokens,
    DateTime? evaluatedAt,
  }) : sourceMessages = List.unmodifiable(sourceMessages),
       sourceEvidence = List.unmodifiable(
         _mergeSourceEvidence(sourceMessages, sourceEvidence),
       ),
       evaluatedAt = (evaluatedAt ?? DateTime.now()).toUtc();

  final String chatId;
  final String summaryId;
  final List<Message> sourceMessages;
  final List<ContextSourceEvidence> sourceEvidence;
  final ConversationSummaryDocument? previousSummary;
  final int targetTokens;
  final DateTime evaluatedAt;
}

List<ContextSourceEvidence> _mergeSourceEvidence(
  List<Message> messages,
  List<ContextSourceEvidence> supplied,
) {
  final byId = {for (final item in supplied) item.messageId: item};
  for (final message in messages) {
    byId.putIfAbsent(
      message.messageId,
      () => ContextSourceEvidence.fromMessage(message),
    );
  }
  return byId.values.toList(growable: false);
}

bool canSourceEvidenceSupportMemory(
  ConversationMemoryKind kind,
  List<String> ids,
  Map<String, ContextSourceEvidence> evidenceById, {
  List<String> sourceClaimIds = const [],
  DateTime? evaluatedAt,
}) {
  final evidence = [
    for (final id in ids)
      if (evidenceById[id] case final item?) item,
  ];
  if (evidence.length != ids.length) return false;
  final hasOnlyUserSources =
      evidence.isNotEmpty &&
      evidence.every((item) => item.role == ContextSourceRole.user);
  final claimsByReference = <String, ContextClaimEvidence>{
    for (final source in evidence)
      if (source.role == ContextSourceRole.assistant)
        for (final claim in source.claims) claim.referenceId: claim,
  };
  final referencedClaims = [
    for (final reference in sourceClaimIds)
      if (claimsByReference[reference] case final claim?) claim,
  ];
  final hasOnlyVerifiedClaims =
      sourceClaimIds.isNotEmpty &&
      referencedClaims.length == sourceClaimIds.length &&
      referencedClaims.every(
        (claim) => claim.isVerifiedAt(evaluatedAt ?? DateTime.now().toUtc()),
      );
  return switch (kind) {
    ConversationMemoryKind.userAssertion ||
    ConversationMemoryKind.preference ||
    ConversationMemoryKind.decision => hasOnlyUserSources,
    ConversationMemoryKind.fact ||
    ConversationMemoryKind.correction ||
    ConversationMemoryKind.artifactReference => hasOnlyVerifiedClaims,
    ConversationMemoryKind.openTask ||
    ConversationMemoryKind.unresolvedQuestion => true,
  };
}

final class ContextSummaryResult {
  ContextSummaryResult({
    required this.markdown,
    List<ConversationMemoryItem> items = const [],
    this.usage = ModelTokenUsage.empty,
    this.provider = '',
    this.model = '',
  }) : items = List.unmodifiable(items);

  final String markdown;
  final List<ConversationMemoryItem> items;
  final ModelTokenUsage usage;
  final String provider;
  final String model;
}

abstract interface class ContextSummarizer {
  Future<ContextSummaryResult> summarize(ContextSummaryRequest request);
}
