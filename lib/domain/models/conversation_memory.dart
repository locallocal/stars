import 'package:stars/domain/models/message.dart';

enum ModelContextProfileSource {
  builtInCatalog,
  provider,
  userConfigured,
  conservativeFallback,
}

final class ModelContextProfile {
  const ModelContextProfile({
    required this.contextWindowTokens,
    this.defaultMaxOutputTokens = 4096,
    this.tokenizerId = '',
    this.supportsStructuredOutput = false,
    this.source = ModelContextProfileSource.conservativeFallback,
  }) : assert(contextWindowTokens > 0),
       assert(defaultMaxOutputTokens >= 0);

  final int contextWindowTokens;
  final int defaultMaxOutputTokens;
  final String tokenizerId;
  final bool supportsStructuredOutput;
  final ModelContextProfileSource source;

  bool get isEstimated =>
      source == ModelContextProfileSource.conservativeFallback;
}

final class ContextBudgetPolicy {
  const ContextBudgetPolicy({
    this.protocolOverheadTokens = 256,
    this.minimumSafetyMarginTokens = 512,
    this.safetyMarginRatio = 0.05,
    this.softCompactionRatio = 0.70,
    this.hardCompactionRatio = 0.90,
    this.actualInputCompactionRatio = 0.85,
    this.historyLookupReserveRatio = 0.10,
    this.maximumHistoryLookupReserveTokens = 4096,
    this.minimumRecentTurns = 4,
    this.minimumCompactionTurns = 3,
    this.minimumCompactionSavingsTokens = 1024,
    this.pinnedMemoryRatio = 0.10,
    this.summaryRatio = 0.25,
    this.automaticMemoryRatio = 0.15,
  }) : assert(protocolOverheadTokens >= 0),
       assert(minimumSafetyMarginTokens >= 0),
       assert(safetyMarginRatio >= 0 && safetyMarginRatio < 1),
       assert(softCompactionRatio > 0 && softCompactionRatio < 1),
       assert(hardCompactionRatio > 0 && hardCompactionRatio <= 1),
       assert(softCompactionRatio < hardCompactionRatio),
       assert(
         actualInputCompactionRatio > 0 && actualInputCompactionRatio <= 1,
       ),
       assert(historyLookupReserveRatio >= 0 && historyLookupReserveRatio < 1),
       assert(maximumHistoryLookupReserveTokens >= 0),
       assert(minimumRecentTurns >= 0),
       assert(minimumCompactionTurns >= 0),
       assert(minimumCompactionSavingsTokens >= 0);

  final int protocolOverheadTokens;
  final int minimumSafetyMarginTokens;
  final double safetyMarginRatio;
  final double softCompactionRatio;
  final double hardCompactionRatio;
  final double actualInputCompactionRatio;
  final double historyLookupReserveRatio;
  final int maximumHistoryLookupReserveTokens;
  final int minimumRecentTurns;
  final int minimumCompactionTurns;
  final int minimumCompactionSavingsTokens;
  final double pinnedMemoryRatio;
  final double summaryRatio;
  final double automaticMemoryRatio;
}

enum ConversationCompactionStatus { idle, background, synchronous, failed }

enum ContextCompressionAction {
  none,
  backgroundReady,
  synchronous,
  fallbackTrim,
}

final class ContextAssemblyReport {
  ContextAssemblyReport({
    required this.contextWindowTokens,
    required this.inputBudgetTokens,
    required this.estimatedInputTokens,
    this.systemTokens = 0,
    this.skillTokens = 0,
    this.memoryTokens = 0,
    this.summaryTokens = 0,
    this.recentTurnTokens = 0,
    List<String> includedTurnIds = const [],
    List<String> omittedTurnIds = const [],
    List<String> includedMemoryIds = const [],
    this.historyLookupAvailable = false,
    this.historyLookupReserveTokens = 0,
    this.memoryRevision = 0,
    this.compressionAction = ContextCompressionAction.none,
    List<String> warnings = const [],
  }) : includedTurnIds = List.unmodifiable(includedTurnIds),
       omittedTurnIds = List.unmodifiable(omittedTurnIds),
       includedMemoryIds = List.unmodifiable(includedMemoryIds),
       warnings = List.unmodifiable(warnings);

  static final empty = ContextAssemblyReport(
    contextWindowTokens: 0,
    inputBudgetTokens: 0,
    estimatedInputTokens: 0,
  );

  final int contextWindowTokens;
  final int inputBudgetTokens;
  final int estimatedInputTokens;
  final int systemTokens;
  final int skillTokens;
  final int memoryTokens;
  final int summaryTokens;
  final int recentTurnTokens;
  final List<String> includedTurnIds;
  final List<String> omittedTurnIds;
  final List<String> includedMemoryIds;
  final bool historyLookupAvailable;
  final int historyLookupReserveTokens;
  final int memoryRevision;
  final ContextCompressionAction compressionAction;
  final List<String> warnings;

  int get safetyRemainingTokens => inputBudgetTokens - estimatedInputTokens;
}

final class ConversationMemoryState {
  const ConversationMemoryState({
    required this.chatId,
    this.revision = 0,
    this.activeSummaryId = '',
    this.coveredThroughMessageId = '',
    this.autoMemoryEnabled = true,
    this.compactionStatus = ConversationCompactionStatus.idle,
    this.lastError = '',
    this.lastCompactedAt,
    required this.updatedAt,
  });

  final String chatId;
  final int revision;
  final String activeSummaryId;
  final String coveredThroughMessageId;
  final bool autoMemoryEnabled;
  final ConversationCompactionStatus compactionStatus;
  final String lastError;
  final DateTime? lastCompactedAt;
  final DateTime updatedAt;
}

enum ConversationSummaryStatus { pending, active, superseded, stale, invalid }

final class ConversationSummaryMetadata {
  ConversationSummaryMetadata({
    required this.id,
    required this.chatId,
    this.status = ConversationSummaryStatus.pending,
    required this.fileName,
    this.markdownSchemaVersion = 1,
    required this.contentDigest,
    this.contentBytes = 0,
    required this.sourceStartMessageId,
    required this.sourceEndMessageId,
    List<String> sourceMessageIds = const [],
    required this.sourceDigest,
    this.estimatedTokenCount = 0,
    this.provider = '',
    this.model = '',
    this.promptVersion = 1,
    required this.baseRevision,
    required this.createdAt,
    required this.updatedAt,
  }) : sourceMessageIds = List.unmodifiable(sourceMessageIds);

  final String id;
  final String chatId;
  final ConversationSummaryStatus status;
  final String fileName;
  final int markdownSchemaVersion;
  final String contentDigest;
  final int contentBytes;
  final String sourceStartMessageId;
  final String sourceEndMessageId;
  final List<String> sourceMessageIds;
  final String sourceDigest;
  final int estimatedTokenCount;
  final String provider;
  final String model;
  final int promptVersion;
  final int baseRevision;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationSummaryMetadata copyWith({
    ConversationSummaryStatus? status,
    String? contentDigest,
    int? contentBytes,
    DateTime? updatedAt,
  }) => ConversationSummaryMetadata(
    id: id,
    chatId: chatId,
    status: status ?? this.status,
    fileName: fileName,
    markdownSchemaVersion: markdownSchemaVersion,
    contentDigest: contentDigest ?? this.contentDigest,
    contentBytes: contentBytes ?? this.contentBytes,
    sourceStartMessageId: sourceStartMessageId,
    sourceEndMessageId: sourceEndMessageId,
    sourceMessageIds: sourceMessageIds,
    sourceDigest: sourceDigest,
    estimatedTokenCount: estimatedTokenCount,
    provider: provider,
    model: model,
    promptVersion: promptVersion,
    baseRevision: baseRevision,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

final class ConversationSummaryDocument {
  const ConversationSummaryDocument({
    required this.metadata,
    required this.markdown,
  });

  final ConversationSummaryMetadata metadata;
  final String markdown;
}

enum ConversationMemoryKind {
  fact,
  userAssertion,
  preference,
  decision,
  openTask,
  unresolvedQuestion,
  artifactReference,
  correction,
}

enum ConversationMemoryItemState {
  active,
  pinned,
  conflicted,
  expired,
  forgotten,
}

enum ConversationMemoryOrigin { auto, user }

final class ConversationMemoryItem {
  ConversationMemoryItem({
    required this.id,
    required this.chatId,
    required this.memoryKey,
    required this.kind,
    required this.content,
    this.state = ConversationMemoryItemState.active,
    this.origin = ConversationMemoryOrigin.auto,
    this.importance = 0.5,
    this.confidence = 0.5,
    List<String> sourceMessageIds = const [],
    List<String> sourceClaimIds = const [],
    this.sourceDigest = '',
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  }) : sourceMessageIds = List.unmodifiable(sourceMessageIds),
       sourceClaimIds = List.unmodifiable(sourceClaimIds),
       assert(importance >= 0 && importance <= 1),
       assert(confidence >= 0 && confidence <= 1);

  final String id;
  final String chatId;
  final String memoryKey;
  final ConversationMemoryKind kind;
  final String content;
  final ConversationMemoryItemState state;
  final ConversationMemoryOrigin origin;
  final double importance;
  final double confidence;
  final List<String> sourceMessageIds;
  final List<String> sourceClaimIds;
  final String sourceDigest;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRecallable => isRecallableAt(DateTime.now());

  bool isRecallableAt(DateTime instant) =>
      (state == ConversationMemoryItemState.active ||
          state == ConversationMemoryItemState.pinned) &&
      (expiresAt == null || expiresAt!.isAfter(instant)) &&
      (state == ConversationMemoryItemState.pinned || confidence >= 0.5);

  ConversationMemoryItem copyWith({
    String? content,
    ConversationMemoryItemState? state,
    ConversationMemoryOrigin? origin,
    double? importance,
    double? confidence,
    DateTime? updatedAt,
  }) => ConversationMemoryItem(
    id: id,
    chatId: chatId,
    memoryKey: memoryKey,
    kind: kind,
    content: content ?? this.content,
    state: state ?? this.state,
    origin: origin ?? this.origin,
    importance: importance ?? this.importance,
    confidence: confidence ?? this.confidence,
    sourceMessageIds: sourceMessageIds,
    sourceClaimIds: sourceClaimIds,
    sourceDigest: sourceDigest,
    expiresAt: expiresAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

final class ConversationTurn {
  ConversationTurn({
    required this.id,
    required List<Message> messages,
    required this.estimatedTokens,
    this.isClosed = true,
  }) : messages = List.unmodifiable(messages);

  final String id;
  final List<Message> messages;
  final int estimatedTokens;
  final bool isClosed;

  String get lastMessageId => messages.isEmpty ? '' : messages.last.messageId;
}
