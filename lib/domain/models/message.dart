import 'package:stars/domain/models/grounded_answer.dart';

class MessageToolCall {
  const MessageToolCall({
    this.executionId = '',
    this.invocationId = '',
    this.attemptId = '',
    this.providerCallId = '',
    this.callId = '',
    required this.name,
    this.title = '',
    this.mcpServerName = '',
    this.status = '',
    this.detail = '',
    this.source = '',
    this.riskLevel = '',
    this.argumentsSummary = '',
    this.resultSummary = '',
    this.approvalStatus = '',
    this.errorCode = '',
    this.durationMs,
  });

  final String executionId;
  final String invocationId;
  final String attemptId;
  final String providerCallId;
  final String callId;
  final String name;
  final String title;
  final String mcpServerName;
  final String status;
  final String detail;
  final String source;
  final String riskLevel;
  final String argumentsSummary;
  final String resultSummary;
  final String approvalStatus;
  final String errorCode;
  final int? durationMs;

  MessageToolCall copyWith({
    String? status,
    String? detail,
    String? resultSummary,
    String? approvalStatus,
    String? errorCode,
    int? durationMs,
  }) {
    return MessageToolCall(
      executionId: executionId,
      invocationId: invocationId,
      attemptId: attemptId,
      providerCallId: providerCallId,
      callId: callId,
      name: name,
      title: title,
      mcpServerName: mcpServerName,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      source: source,
      riskLevel: riskLevel,
      argumentsSummary: argumentsSummary,
      resultSummary: resultSummary ?? this.resultSummary,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      errorCode: errorCode ?? this.errorCode,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

class MessageCommandExecution {
  const MessageCommandExecution({
    this.callId = '',
    required this.command,
    this.status = '',
    this.detail = '',
    this.durationMs,
  });

  final String callId;
  final String command;
  final String status;
  final String detail;
  final int? durationMs;
}

class MessageFileEdit {
  const MessageFileEdit({
    required this.path,
    this.type = '',
    this.status = '',
    this.detail = '',
  });

  final String path;
  final String type;
  final String status;
  final String detail;
}

class MessageSkillActivation {
  const MessageSkillActivation({
    required this.name,
    required this.contentDigest,
    required this.trigger,
    this.status = 'recorded',
  });

  final String name;
  final String contentDigest;
  final String trigger;
  final String status;
}

class MessageProcessInfo {
  const MessageProcessInfo({
    this.reasoningStatus = '',
    this.durationMs,
    this.toolCalls = const [],
    this.commandExecutions = const [],
    this.fileEdits = const [],
    this.skillActivations = const [],
  });

  final String reasoningStatus;
  final int? durationMs;
  final List<MessageToolCall> toolCalls;
  final List<MessageCommandExecution> commandExecutions;
  final List<MessageFileEdit> fileEdits;
  final List<MessageSkillActivation> skillActivations;

  bool get hasData =>
      reasoningStatus.isNotEmpty ||
      durationMs != null ||
      toolCalls.isNotEmpty ||
      commandExecutions.isNotEmpty ||
      fileEdits.isNotEmpty ||
      skillActivations.isNotEmpty;
}

enum MessageTerminalOutcome { completed, cancelled, failed, emptyResponse }

/// Application-computed trust state for an assistant answer.
///
/// This state is independent from [MessageTerminalOutcome]: completing a
/// generation does not make its content verified.
enum AnswerTrustLevel { verified, partiallyVerified, unverified, failed }

/// Immutable grounding metadata attached to a message.
///
/// Evidence identifiers only establish provenance at this layer. Later
/// grounding protocol phases are responsible for checking that referenced
/// evidence is persisted and actually supports individual claims.
final class MessageGrounding {
  factory MessageGrounding({
    int protocolVersion = currentProtocolVersion,
    AnswerTrustLevel trustLevel = AnswerTrustLevel.unverified,
    String reasonCode = '',
    List<String> evidenceIds = const [],
    List<MessageClaimGrounding> claims = const [],
  }) {
    if (protocolVersion < 0) {
      throw ArgumentError.value(
        protocolVersion,
        'protocolVersion',
        'Grounding protocol version cannot be negative.',
      );
    }
    final copiedClaims = List<MessageClaimGrounding>.unmodifiable(claims);
    final claimIds = <String>{};
    for (final claim in copiedClaims) {
      if (!claimIds.add(claim.claim.claimId)) {
        throw ArgumentError.value(
          claims,
          'claims',
          'Claim identifiers must be unique within one message.',
        );
      }
    }
    final acceptedClaimEvidenceIds = <String>{
      for (final claim in copiedClaims) ...claim.acceptedEvidenceIds,
    };
    final effectiveEvidenceIds =
        evidenceIds.isEmpty && acceptedClaimEvidenceIds.isNotEmpty
            ? acceptedClaimEvidenceIds.toList(growable: false)
            : evidenceIds;
    final copiedEvidenceIds = List<String>.unmodifiable(effectiveEvidenceIds);
    final uniqueEvidenceIds = <String>{};
    for (final evidenceId in copiedEvidenceIds) {
      if (evidenceId.isEmpty || evidenceId.trim() != evidenceId) {
        throw ArgumentError.value(
          evidenceId,
          'evidenceIds',
          'Evidence identifiers must be non-empty and normalized.',
        );
      }
      if (!uniqueEvidenceIds.add(evidenceId)) {
        throw ArgumentError.value(
          evidenceId,
          'evidenceIds',
          'Evidence identifiers must be unique.',
        );
      }
    }
    if ((trustLevel == AnswerTrustLevel.verified ||
            trustLevel == AnswerTrustLevel.partiallyVerified) &&
        copiedEvidenceIds.isEmpty) {
      throw ArgumentError.value(
        trustLevel,
        'trustLevel',
        'A verified trust state requires evidence.',
      );
    }
    if (copiedClaims.isNotEmpty &&
        (copiedEvidenceIds.toSet().length != acceptedClaimEvidenceIds.length ||
            !copiedEvidenceIds.toSet().containsAll(acceptedClaimEvidenceIds))) {
      throw ArgumentError.value(
        evidenceIds,
        'evidenceIds',
        'Message evidence must exactly match accepted claim evidence.',
      );
    }
    return MessageGrounding._(
      protocolVersion: protocolVersion,
      trustLevel: trustLevel,
      reasonCode: reasonCode,
      evidenceIds: copiedEvidenceIds,
      claims: copiedClaims,
    );
  }

  const MessageGrounding.unverified()
    : protocolVersion = currentProtocolVersion,
      trustLevel = AnswerTrustLevel.unverified,
      reasonCode = '',
      evidenceIds = const [],
      claims = const [];

  const MessageGrounding._({
    required this.protocolVersion,
    required this.trustLevel,
    required this.reasonCode,
    required this.evidenceIds,
    required this.claims,
  });

  static const int currentProtocolVersion = 3;

  final int protocolVersion;
  final AnswerTrustLevel trustLevel;
  final String reasonCode;
  final List<String> evidenceIds;
  final List<MessageClaimGrounding> claims;

  MessageGrounding copyWith({
    int? protocolVersion,
    AnswerTrustLevel? trustLevel,
    String? reasonCode,
    List<String>? evidenceIds,
    List<MessageClaimGrounding>? claims,
  }) {
    return MessageGrounding(
      protocolVersion: protocolVersion ?? this.protocolVersion,
      trustLevel: trustLevel ?? this.trustLevel,
      reasonCode: reasonCode ?? this.reasonCode,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      claims: claims ?? this.claims,
    );
  }
}

/// Immutable token accounting for one model response or an aggregate.
///
/// Providers do not all return a total, so [effectiveTotalTokens] falls back
/// to the input/output sum. [model] is populated for per-response records and
/// intentionally left empty for aggregates that may span multiple models.
class ModelTokenUsage {
  const ModelTokenUsage({
    this.model = '',
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
  });

  static const empty = ModelTokenUsage();

  final String model;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  int get effectiveTotalTokens =>
      totalTokens > 0 ? totalTokens : inputTokens + outputTokens;

  bool get hasData => inputTokens > 0 || outputTokens > 0 || totalTokens > 0;

  ModelTokenUsage merge(ModelTokenUsage newer) {
    return ModelTokenUsage(
      model: newer.model.isNotEmpty ? newer.model : model,
      inputTokens: newer.inputTokens > 0 ? newer.inputTokens : inputTokens,
      outputTokens: newer.outputTokens > 0 ? newer.outputTokens : outputTokens,
      totalTokens: newer.totalTokens > 0 ? newer.totalTokens : totalTokens,
    );
  }

  ModelTokenUsage operator +(ModelTokenUsage other) {
    return ModelTokenUsage(
      inputTokens: inputTokens + other.inputTokens,
      outputTokens: outputTokens + other.outputTokens,
      totalTokens: effectiveTotalTokens + other.effectiveTotalTokens,
    );
  }

  static ModelTokenUsage sum(Iterable<ModelTokenUsage> usages) {
    return usages.fold(empty, (total, usage) => total + usage);
  }
}

/// Immutable accounting record for one model response.
///
/// The record is stored independently from message content so clearing a
/// conversation does not erase historical usage.
class ModelTokenUsageRecord {
  const ModelTokenUsageRecord({
    required this.messageId,
    required this.chatId,
    required this.botId,
    required this.timestamp,
    required this.usage,
    this.operationKind = 'chat_reply',
  });

  final String messageId;
  final String chatId;
  final String botId;
  final DateTime timestamp;
  final ModelTokenUsage usage;
  final String operationKind;
}

class Message {
  Message({
    this.messageId = '',
    this.turnId = '',
    this.runId = '',
    required this.chatId,
    required this.botId,
    required this.senderId,
    required this.content,
    this.reasoning = '',
    this.processInfo = const MessageProcessInfo(),
    this.images = const [],
    this.files = const [],
    this.audio = '',
    this.music = '',
    this.video = '',
    this.tokenUsage = ModelTokenUsage.empty,
    this.grounding = const MessageGrounding.unverified(),
    this.terminalOutcome,
    this.hasPartialContent = false,
    required this.timestamp,
  }) {
    final trustLevel = grounding.trustLevel;
    final hasUnsuccessfulTerminalOutcome =
        terminalOutcome == MessageTerminalOutcome.cancelled ||
        terminalOutcome == MessageTerminalOutcome.failed ||
        terminalOutcome == MessageTerminalOutcome.emptyResponse;
    if (hasUnsuccessfulTerminalOutcome &&
        trustLevel != AnswerTrustLevel.unverified &&
        trustLevel != AnswerTrustLevel.failed) {
      throw ArgumentError.value(
        trustLevel,
        'grounding',
        'Cancelled, failed, and empty responses cannot be verified.',
      );
    }
  }

  final String messageId;
  final String turnId;
  final String runId;
  final String chatId;
  final String botId;
  final String senderId;
  final String content;
  final String reasoning;
  final MessageProcessInfo processInfo;
  final List<String> images;
  final List<String> files;
  final String audio;
  final String music;
  final String video;
  final ModelTokenUsage tokenUsage;
  final MessageGrounding grounding;
  final MessageTerminalOutcome? terminalOutcome;
  final bool hasPartialContent;
  final DateTime timestamp;

  Message copyWith({
    String? messageId,
    String? turnId,
    String? runId,
    String? chatId,
    String? botId,
    String? senderId,
    String? content,
    String? reasoning,
    MessageProcessInfo? processInfo,
    List<String>? images,
    List<String>? files,
    String? audio,
    String? music,
    String? video,
    ModelTokenUsage? tokenUsage,
    MessageGrounding? grounding,
    MessageTerminalOutcome? terminalOutcome,
    bool clearTerminalOutcome = false,
    bool? hasPartialContent,
    DateTime? timestamp,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      turnId: turnId ?? this.turnId,
      runId: runId ?? this.runId,
      chatId: chatId ?? this.chatId,
      botId: botId ?? this.botId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      reasoning: reasoning ?? this.reasoning,
      processInfo: processInfo ?? this.processInfo,
      images: images ?? this.images,
      files: files ?? this.files,
      audio: audio ?? this.audio,
      music: music ?? this.music,
      video: video ?? this.video,
      tokenUsage: tokenUsage ?? this.tokenUsage,
      grounding: grounding ?? this.grounding,
      terminalOutcome:
          clearTerminalOutcome ? null : terminalOutcome ?? this.terminalOutcome,
      hasPartialContent: hasPartialContent ?? this.hasPartialContent,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
