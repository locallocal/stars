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
  });

  static const legacy = AiProviderCapabilities();

  final bool supportsStructuredToolCalls;
  final bool supportsToolResults;
  final bool supportsParallelToolCalls;
  final bool supportsHostedSkills;

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
