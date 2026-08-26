import 'package:stars/domain/models/conversation_memory.dart';
import 'package:stars/domain/models/message.dart';

enum ContextSourceRole { user, assistant }

final class ContextSourceEvidence {
  ContextSourceEvidence({
    required this.messageId,
    required this.role,
    List<String> successfulToolCallIds = const [],
  }) : successfulToolCallIds = List.unmodifiable(successfulToolCallIds);

  factory ContextSourceEvidence.fromMessage(Message message) {
    final isAssistant = message.senderId == message.botId;
    return ContextSourceEvidence(
      messageId: message.messageId,
      role: isAssistant ? ContextSourceRole.assistant : ContextSourceRole.user,
      successfulToolCallIds: [
        for (final call in message.processInfo.toolCalls)
          if (call.status == 'succeeded' && call.errorCode.isEmpty) call.callId,
      ],
    );
  }

  final String messageId;
  final ContextSourceRole role;
  final List<String> successfulToolCallIds;

  bool get isToolGrounded => successfulToolCallIds.isNotEmpty;
}

final class ContextSummaryRequest {
  ContextSummaryRequest({
    required this.chatId,
    required this.summaryId,
    required List<Message> sourceMessages,
    List<ContextSourceEvidence> sourceEvidence = const [],
    this.previousSummary,
    required this.targetTokens,
  }) : sourceMessages = List.unmodifiable(sourceMessages),
       sourceEvidence = List.unmodifiable(
         _mergeSourceEvidence(sourceMessages, sourceEvidence),
       );

  final String chatId;
  final String summaryId;
  final List<Message> sourceMessages;
  final List<ContextSourceEvidence> sourceEvidence;
  final ConversationSummaryDocument? previousSummary;
  final int targetTokens;
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
  Map<String, ContextSourceEvidence> evidenceById,
) {
  final evidence = [
    for (final id in ids)
      if (evidenceById[id] case final item?) item,
  ];
  if (evidence.length != ids.length) return false;
  final hasUser = evidence.any((item) => item.role == ContextSourceRole.user);
  final hasGroundedAssistant = evidence.any(
    (item) => item.role == ContextSourceRole.assistant && item.isToolGrounded,
  );
  return switch (kind) {
    ConversationMemoryKind.preference ||
    ConversationMemoryKind.decision => hasUser,
    ConversationMemoryKind.fact ||
    ConversationMemoryKind.correction ||
    ConversationMemoryKind.artifactReference => hasUser || hasGroundedAssistant,
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
