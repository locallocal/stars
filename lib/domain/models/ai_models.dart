import 'package:stars/domain/models/models.dart';

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.reasoning = '',
    List<String> images = const [],
    List<String> files = const [],
  }) : images = List<String>.unmodifiable(images),
       files = List<String>.unmodifiable(files);

  final String role;
  final String content;
  final String reasoning;
  final List<String> images;
  final List<String> files;
}

final class ModelGenerationOptions {
  const ModelGenerationOptions({
    this.stream = true,
    this.allowParallelToolCalls = false,
    this.webSearch = false,
    this.deepThinking = false,
  });

  final bool stream;
  final bool allowParallelToolCalls;
  final bool webSearch;
  final bool deepThinking;
}

final class ModelRequest {
  ModelRequest({
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
    this.options = const ModelGenerationOptions(),
  }) : messages = List<ChatMessage>.unmodifiable(messages),
       tools = List<ToolDefinition>.unmodifiable(tools);

  final List<ChatMessage> messages;
  final List<ToolDefinition> tools;
  final ModelGenerationOptions options;
}

sealed class ModelEvent {
  const ModelEvent();
}

final class TextDelta extends ModelEvent {
  const TextDelta(this.text);

  final String text;
}

final class ReasoningDelta extends ModelEvent {
  const ReasoningDelta(this.text);

  final String text;
}

final class ToolCallStarted extends ModelEvent {
  const ToolCallStarted({required this.callId, required this.name});

  final String callId;
  final String name;
}

final class ToolCallArgumentsDelta extends ModelEvent {
  const ToolCallArgumentsDelta({
    required this.callId,
    required this.argumentsDelta,
  });

  final String callId;
  final String argumentsDelta;
}

final class ToolCallRequested extends ModelEvent {
  ToolCallRequested({
    required this.callId,
    required this.name,
    Map<String, Object?> arguments = const {},
  }) : arguments = Map<String, Object?>.unmodifiable(arguments);

  final String callId;
  final String name;
  final Map<String, Object?> arguments;

  ToolCallRequest toToolCallRequest() =>
      ToolCallRequest(callId: callId, name: name, arguments: arguments);
}

/// A Provider-hosted Tool execution normalized by an application adapter.
///
/// Unlike [ToolCallRequested], this execution already happened remotely. The
/// coordinator records its lifecycle and revalidates its [result], but never
/// invokes it again.
final class ProviderNativeToolResult extends ModelEvent {
  ProviderNativeToolResult({
    required this.definition,
    required this.call,
    required this.result,
    required DateTime reportedAt,
  }) : reportedAt = reportedAt.toUtc() {
    if (definition.source != ToolSource.providerNative) {
      throw ArgumentError.value(
        definition.source,
        'definition',
        'Provider-native results require a Provider-native Tool definition.',
      );
    }
    if (call.callId.trim().isEmpty ||
        call.name != definition.name ||
        result.callId != call.callId ||
        result.name != definition.name ||
        result.source != ToolSource.providerNative) {
      throw ArgumentError(
        'Provider-native definition, call, and result identities must match.',
      );
    }
  }

  final ToolDefinition definition;
  final ToolCallRequest call;
  final ToolResult result;
  final DateTime reportedAt;
}

/// Application evidence made available to one structured synthesis turn.
final class GroundedEvidenceReference {
  GroundedEvidenceReference({
    required this.evidenceId,
    required this.providerCallId,
    required this.toolName,
    required this.isError,
  }) {
    if (evidenceId.trim().isEmpty || toolName.trim().isEmpty) {
      throw ArgumentError('Grounded evidence identities cannot be empty.');
    }
  }

  final String evidenceId;

  /// Opaque migration alias used only to translate legacy evidence footers.
  final String providerCallId;

  final String toolName;
  final bool isError;
}

/// Provider-independent input for the final structured answer turn.
final class GroundedAnswerSynthesisRequest {
  GroundedAnswerSynthesisRequest({
    required this.draftText,
    List<GroundedEvidenceReference> evidence = const [],
    this.reliabilityFeedback = '',
  }) : evidence = List<GroundedEvidenceReference>.unmodifiable(evidence) {
    final evidenceIds = <String>{};
    for (final reference in this.evidence) {
      if (!evidenceIds.add(reference.evidenceId)) {
        throw ArgumentError.value(
          reference.evidenceId,
          'evidence',
          'Evidence IDs must be unique.',
        );
      }
    }
  }

  final String draftText;
  final List<GroundedEvidenceReference> evidence;

  /// Application-authored correction constraints from a prior synthesis.
  /// Provider output is never copied into this field.
  final String reliabilityFeedback;

  Set<String> get allowedEvidenceIds => Set<String>.unmodifiable(
    evidence.map((reference) => reference.evidenceId),
  );

  Map<String, String> get legacyEvidenceAliases {
    final aliases = <String, String>{};
    final ambiguous = <String>{};
    for (final reference in evidence) {
      final providerCallId = reference.providerCallId;
      if (providerCallId.isEmpty || ambiguous.contains(providerCallId)) {
        continue;
      }
      if (aliases.containsKey(providerCallId)) {
        aliases.remove(providerCallId);
        ambiguous.add(providerCallId);
      } else {
        aliases[providerCallId] = reference.evidenceId;
      }
    }
    return Map<String, String>.unmodifiable(aliases);
  }
}

/// A strictly parsed final answer. Raw Provider JSON is never exposed here.
final class GroundedAnswerProduced extends ModelEvent {
  const GroundedAnswerProduced(this.candidate);

  final GroundedAnswerCandidate candidate;
}

final class UsageReported extends ModelEvent {
  const UsageReported(this.usage);

  final ModelTokenUsage usage;
}

final class ModelTurnCompleted extends ModelEvent {
  const ModelTurnCompleted({this.stopReason = ''});

  final String stopReason;
}

final class ModelTurnFailed extends ModelEvent {
  const ModelTurnFailed({
    required this.error,
    this.code = '',
    this.providerFailure,
  });

  factory ModelTurnFailed.fromProvider(ProviderFailure failure) =>
      ModelTurnFailed(
        error: failure.code,
        code: failure.code,
        providerFailure: failure,
      );

  final String error;
  final String code;
  final ProviderFailure? providerFailure;
}

typedef StreamResponseCallback = void Function(String text);
typedef ToolCallCallback = void Function(MessageToolCall toolCall);
typedef CommandExecutionCallback =
    void Function(MessageCommandExecution commandExecution);
typedef TokenUsageCallback = void Function(ModelTokenUsage usage);
typedef ProviderCompleteCallback = void Function();
typedef ProviderErrorCallback = void Function(String error);

enum ProviderTerminalType { completed, cancelled, failed }

class ProviderTerminalEvent {
  const ProviderTerminalEvent({required this.type, this.error});

  final ProviderTerminalType type;
  final String? error;
}

typedef ProviderTerminalCallback = void Function(ProviderTerminalEvent event);

final class AiProviderCapabilities {
  const AiProviderCapabilities({
    this.supportsStructuredToolCalls = false,
    this.supportsToolResults = false,
    this.supportsParallelToolCalls = false,
    this.supportsHostedSkills = false,
    this.supportsNativeToolEvidence = false,
  });

  static const legacy = AiProviderCapabilities();

  final bool supportsStructuredToolCalls;
  final bool supportsToolResults;
  final bool supportsParallelToolCalls;
  final bool supportsHostedSkills;
  final bool supportsNativeToolEvidence;

  bool get supportsAutomaticSkillActivation =>
      supportsStructuredToolCalls && supportsToolResults;

  bool get supportsAgentLoop =>
      supportsStructuredToolCalls && supportsToolResults;
}

final class SkillToolCall {
  SkillToolCall({
    required this.callId,
    required this.name,
    Map<String, Object?> arguments = const {},
  }) : arguments = Map<String, Object?>.unmodifiable(arguments);

  final String callId;
  final String name;
  final Map<String, Object?> arguments;
}

final class SkillToolResult {
  const SkillToolResult({
    required this.callId,
    required this.name,
    required this.content,
    this.isError = false,
  });

  final String callId;
  final String name;
  final String content;
  final bool isError;
}

enum HostedSkillPreparationStatus { unavailable, prepared, rejected }

final class HostedSkillDescriptor {
  const HostedSkillDescriptor({
    required this.id,
    required this.name,
    required this.version,
    required this.contentDigest,
  });

  final String id;
  final String name;
  final String version;
  final String contentDigest;
}

final class HostedSkillPreparation {
  HostedSkillPreparation({
    required this.status,
    Map<String, String> providerReferences = const {},
    this.reason = '',
  }) : providerReferences = Map.unmodifiable(providerReferences);

  const HostedSkillPreparation.unavailable()
    : status = HostedSkillPreparationStatus.unavailable,
      providerReferences = const {},
      reason = '';

  final HostedSkillPreparationStatus status;
  final Map<String, String> providerReferences;
  final String reason;
}

final class SkillToolTurn {
  SkillToolTurn({
    List<SkillToolCall> calls = const [],
    this.isComplete = false,
    this.tokenUsage = ModelTokenUsage.empty,
  }) : calls = List<SkillToolCall>.unmodifiable(calls);

  final List<SkillToolCall> calls;
  final bool isComplete;
  final ModelTokenUsage tokenUsage;
}

final class SkillToolSessionRequest {
  SkillToolSessionRequest({
    required List<ChatMessage> messages,
    required List<SkillCatalogEntry> catalog,
  }) : messages = List<ChatMessage>.unmodifiable(messages),
       catalog = List<SkillCatalogEntry>.unmodifiable(catalog);

  final List<ChatMessage> messages;
  final List<SkillCatalogEntry> catalog;
}

abstract interface class SkillToolSession {
  Future<SkillToolTurn> start();

  Future<SkillToolTurn> continueWith(List<SkillToolResult> results);

  void close();
}

abstract interface class AgentModelSession {
  Stream<ModelEvent> start();

  Stream<ModelEvent> continueWith(List<ToolResult> results);

  /// Requests a corrected final answer after deterministic reliability checks
  /// reject a model turn. The feedback is application-authored data, not a new
  /// end-user request.
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback);

  /// Produces one schema-validated, Provider-independent answer candidate.
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request,
  );

  Future<void> cancel();

  void close();
}

enum ProviderCancellationStatus { requested, alreadyRequested, unsupported }

class ProviderCancellationResult {
  const ProviderCancellationResult(this.status);

  final ProviderCancellationStatus status;

  bool get accepted =>
      status == ProviderCancellationStatus.requested ||
      status == ProviderCancellationStatus.alreadyRequested;
}
