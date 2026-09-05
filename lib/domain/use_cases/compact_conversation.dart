import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/app_failure.dart';
import 'package:stars/domain/models/conversation_memory.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/repositories/context_summarizer.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/services/token_estimator.dart';

typedef ContextSummarizerFactory = ContextSummarizer Function(Bot bot);
typedef CompactionClock = DateTime Function();
typedef CompactionUsagePersister =
    Future<void> Function(
      String operationId,
      String chatId,
      Bot bot,
      ModelTokenUsage usage,
    );

enum ConversationCompactionResult {
  committed,
  noCandidates,
  revisionConflict,
  invalidSummary,
}

/// Creates one immutable rolling summary over a continuous closed-turn prefix.
final class CompactConversation {
  CompactConversation({
    required MessageRepository messageRepository,
    required ConversationMemoryRepository memoryRepository,
    ToolEvidenceRepository? toolEvidenceRepository,
    required ContextSummarizerFactory summarizerFactory,
    TokenEstimator tokenEstimator = const ConservativeTokenEstimator(),
    CompactionClock? clock,
    CompactionUsagePersister? usagePersister,
    this.protectedRecentTurns = 4,
    this.maximumTurnsPerSegment = 12,
  }) : _messageRepository = messageRepository,
       _memoryRepository = memoryRepository,
       _toolEvidenceRepository = toolEvidenceRepository,
       _summarizerFactory = summarizerFactory,
       _tokenEstimator = tokenEstimator,
       _usagePersister = usagePersister,
       _clock = clock ?? DateTime.now;

  final MessageRepository _messageRepository;
  final ConversationMemoryRepository _memoryRepository;
  final ToolEvidenceRepository? _toolEvidenceRepository;
  final ContextSummarizerFactory _summarizerFactory;
  final TokenEstimator _tokenEstimator;
  final CompactionClock _clock;
  final CompactionUsagePersister? _usagePersister;
  final int protectedRecentTurns;
  final int maximumTurnsPerSegment;
  final Map<String, Future<void>> _chatTails = {};
  int _sequence = 0;

  Future<ConversationCompactionResult> call({
    required Bot bot,
    required String chatId,
    bool manual = false,
  }) {
    final previous = _chatTails[chatId] ?? Future<void>.value();
    final completer = previous.catchError((_) {}).then((_) async {});
    final result = completer.then(
      (_) => _compact(bot: bot, chatId: chatId, manual: manual),
    );
    final tail = result.then<void>((_) {}, onError: (_, _) {});
    _chatTails[chatId] = tail;
    tail.whenComplete(() {
      if (identical(_chatTails[chatId], tail)) _chatTails.remove(chatId);
    });
    return result;
  }

  Future<ConversationCompactionResult> _compact({
    required Bot bot,
    required String chatId,
    required bool manual,
  }) async {
    await _memoryRepository.setCompactionStatus(
      chatId,
      manual
          ? ConversationCompactionStatus.synchronous
          : ConversationCompactionStatus.background,
    );
    try {
      final result = await _compactCore(
        bot: bot,
        chatId: chatId,
        manual: manual,
      );
      if (result != ConversationCompactionResult.committed) {
        await _memoryRepository.setCompactionStatus(
          chatId,
          result == ConversationCompactionResult.invalidSummary
              ? ConversationCompactionStatus.failed
              : ConversationCompactionStatus.idle,
          lastError:
              result == ConversationCompactionResult.invalidSummary
                  ? 'invalid_summary'
                  : '',
        );
      }
      return result;
    } on Object catch (error) {
      await _memoryRepository.setCompactionStatus(
        chatId,
        ConversationCompactionStatus.failed,
        lastError:
            AppFailure.from(error, code: 'conversation_compaction_failed').code,
      );
      rethrow;
    }
  }

  Future<ConversationCompactionResult> _compactCore({
    required Bot bot,
    required String chatId,
    required bool manual,
  }) async {
    final state = await _memoryRepository.getState(chatId);
    final previousSummary = await _memoryRepository.getActiveSummary(chatId);
    final messages = await _messageRepository.getMessages(chatId);
    final turns = _closedTurns(messages);
    if (turns.length <= protectedRecentTurns) {
      return ConversationCompactionResult.noCandidates;
    }
    var start = 0;
    if (state.coveredThroughMessageId.isNotEmpty) {
      final coveredIndex = turns.indexWhere(
        (turn) => turn.messages.any(
          (message) => message.messageId == state.coveredThroughMessageId,
        ),
      );
      if (coveredIndex >= 0) start = coveredIndex + 1;
    }
    final candidateEnd = turns.length - protectedRecentTurns;
    if (start >= candidateEnd) {
      return ConversationCompactionResult.noCandidates;
    }
    final candidates = turns.sublist(
      start,
      (start + maximumTurnsPerSegment).clamp(start, candidateEnd),
    );
    if (!manual && candidates.length < 3) {
      return ConversationCompactionResult.noCandidates;
    }
    final sourceMessages = [for (final turn in candidates) ...turn.messages];
    if (sourceMessages.isEmpty) {
      return ConversationCompactionResult.noCandidates;
    }
    final now = _clock();
    _sequence = (_sequence + 1) & 0x7fffffff;
    final summaryId = 'summary_${now.microsecondsSinceEpoch}_$_sequence';
    final currentSourceIds =
        sourceMessages.map((message) => message.messageId).toSet();
    final allowedSourceIds = <String>{
      ...?previousSummary?.metadata.sourceMessageIds,
      ...currentSourceIds,
    };
    final messageById = {
      for (final message in messages) message.messageId: message,
    };
    final evidenceById = await _loadContextEvidence([
      for (final id in allowedSourceIds)
        if (messageById[id] case final message?) message,
    ]);
    final sourceEvidence = [
      for (final id in allowedSourceIds)
        if (messageById[id] case final message?)
          ContextSourceEvidence.fromMessage(
            message,
            evidenceById: evidenceById,
          ),
    ];
    final sourceEvidenceByMessageId = {
      for (final source in sourceEvidence) source.messageId: source,
    };
    final result = await _summarizerFactory(bot).summarize(
      ContextSummaryRequest(
        chatId: chatId,
        summaryId: summaryId,
        sourceMessages: sourceMessages,
        sourceEvidence: sourceEvidence,
        previousSummary: previousSummary,
        targetTokens: 2048,
        evaluatedAt: now,
      ),
    );
    final usagePersister = _usagePersister;
    if (usagePersister != null) {
      await usagePersister(
        'context_compaction:$summaryId',
        chatId,
        bot,
        result.usage,
      );
    }
    if (!_validResult(
      result,
      allowedSourceIds,
      sourceEvidenceByMessageId,
      now,
    )) {
      return ConversationCompactionResult.invalidSummary;
    }
    final profile = ModelContextProfile(
      contextWindowTokens: bot.configuredContextWindowTokens ?? 32768,
    );
    final sourceDigest =
        sha256
            .convert(
              utf8.encode(
                jsonEncode([
                  if (previousSummary != null)
                    {
                      'previous_summary_id': previousSummary.metadata.id,
                      'previous_source_digest':
                          previousSummary.metadata.sourceDigest,
                    },
                  for (final message in sourceMessages)
                    {
                      'id': message.messageId,
                      'turn': message.turnId,
                      'sender': message.senderId,
                      'content': message.content,
                      'terminal': message.terminalOutcome?.name,
                      'partial': message.hasPartialContent,
                      'grounding': {
                        'trust': message.grounding.trustLevel.name,
                        'claims': [
                          for (final grounding in message.grounding.claims)
                            {
                              'claim_id': grounding.claim.claimId,
                              'kind': grounding.claim.kind.wireName,
                              'trust': grounding.trustLevel.name,
                              'evidence_ids': grounding.acceptedEvidenceIds,
                            },
                        ],
                      },
                      'claim_evidence': [
                        if (sourceEvidenceByMessageId[message.messageId]
                            case final source?)
                          for (final claim in source.claims)
                            {
                              'claim_id': claim.claimId,
                              'evidence': [
                                for (final evidence in claim.evidence)
                                  {
                                    'evidence_id': evidence.evidenceId,
                                    'observed_at':
                                        evidence.observedAt.toIso8601String(),
                                    'valid_until':
                                        evidence.validUntil?.toIso8601String(),
                                  },
                              ],
                            },
                      ],
                    },
                ]),
              ),
            )
            .toString();
    final metadata = ConversationSummaryMetadata(
      id: summaryId,
      chatId: chatId,
      fileName: '$summaryId.md',
      markdownSchemaVersion: 3,
      contentDigest: '',
      sourceStartMessageId:
          previousSummary?.metadata.sourceStartMessageId ??
          sourceMessages.first.messageId,
      sourceEndMessageId: sourceMessages.last.messageId,
      sourceMessageIds: allowedSourceIds.toList(growable: false),
      sourceDigest: sourceDigest,
      estimatedTokenCount: await _tokenEstimator.estimateText(
        profile,
        result.markdown,
      ),
      provider: result.provider,
      model: result.model,
      promptVersion: 3,
      baseRevision: state.revision,
      createdAt: now,
      updatedAt: now,
    );
    final committed = await _memoryRepository.commitCompaction(
      chatId: chatId,
      expectedRevision: state.revision,
      summary: ConversationSummaryDocument(
        metadata: metadata,
        markdown: result.markdown,
      ),
      items: state.autoMemoryEnabled ? result.items : const [],
    );
    return committed
        ? ConversationCompactionResult.committed
        : ConversationCompactionResult.revisionConflict;
  }

  List<ConversationTurn> _closedTurns(List<Message> messages) {
    final grouped = <String, List<Message>>{};
    final order = <String>[];
    var legacyTurn = '';
    var legacySequence = 0;
    for (final message in messages) {
      var id = message.turnId;
      if (id.isEmpty) {
        if (message.senderId != message.botId || legacyTurn.isEmpty) {
          legacyTurn = 'legacy_${legacySequence++}';
        }
        id = legacyTurn;
      }
      if (!grouped.containsKey(id)) order.add(id);
      grouped.putIfAbsent(id, () => []).add(message);
    }
    return [
      for (final id in order)
        if (_isClosed(grouped[id]!))
          ConversationTurn(id: id, messages: grouped[id]!, estimatedTokens: 0),
    ];
  }

  bool _isClosed(List<Message> messages) {
    final assistants = messages.where(
      (message) => message.senderId == message.botId,
    );
    final hasUser = messages.any(
      (message) => message.senderId != message.botId,
    );
    if (!hasUser || assistants.isEmpty) return false;
    return assistants.every(
      (message) => message.terminalOutcome != null || message.runId.isEmpty,
    );
  }

  bool _validResult(
    ContextSummaryResult result,
    Set<String> sourceIds,
    Map<String, ContextSourceEvidence> evidenceById,
    DateTime evaluatedAt,
  ) {
    if (result.markdown.trim().isEmpty || result.markdown.length > 200000) {
      return false;
    }
    if (!result.markdown.trimLeft().startsWith('# 会话摘要')) {
      return false;
    }
    for (final item in result.items) {
      if (item.content.trim().isEmpty || item.content.length > 4000) {
        return false;
      }
      if (item.sourceMessageIds.any((id) => !sourceIds.contains(id))) {
        return false;
      }
      if (!canSourceEvidenceSupportMemory(
        item.kind,
        item.sourceMessageIds,
        evidenceById,
        sourceClaimIds: item.sourceClaimIds,
        evaluatedAt: evaluatedAt,
      )) {
        return false;
      }
    }
    return true;
  }

  Future<Map<String, ToolEvidenceRecord>> _loadContextEvidence(
    List<Message> messages,
  ) async {
    final repository = _toolEvidenceRepository;
    if (repository == null) return const {};
    final ownerByEvidenceId = <String, Message>{
      for (final message in messages)
        for (final claim in message.grounding.claims)
          for (final evidenceId in claim.acceptedEvidenceIds)
            evidenceId: message,
    };
    final loaded = await Future.wait(
      ownerByEvidenceId.entries.map((entry) async {
        try {
          final record = await repository.getById(entry.key);
          if (record == null ||
              !record.persisted ||
              record.messageId != entry.value.messageId ||
              record.chatId != entry.value.chatId ||
              !await repository.verifyDigest(entry.key)) {
            return null;
          }
          return record;
        } on Object {
          return null;
        }
      }),
    );
    return {
      for (final record in loaded)
        if (record != null) record.evidenceId: record,
    };
  }
}
