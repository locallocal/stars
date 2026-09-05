part of 'agent_run_coordinator.dart';

final class AgentRunLimits {
  const AgentRunLimits({
    this.maxModelTurns = 6,
    this.maxToolCalls = 12,
    this.maxSameCallRetries = 1,
    this.maxReliabilityRepairs = 1,
    this.totalTimeout = const Duration(minutes: 3),
    this.toolTimeout = const Duration(seconds: 30),
    this.approvalTimeout = const Duration(minutes: 2),
    this.maxToolOutputCharacters = 16000,
  }) : assert(maxModelTurns > 0),
       assert(maxToolCalls > 0),
       assert(maxSameCallRetries >= 0),
       assert(maxReliabilityRepairs >= 0 && maxReliabilityRepairs <= 1),
       assert(maxToolOutputCharacters > 0);

  final int maxModelTurns;
  final int maxToolCalls;
  final int maxSameCallRetries;
  final int maxReliabilityRepairs;
  final Duration totalTimeout;
  final Duration toolTimeout;
  final Duration approvalTimeout;
  final int maxToolOutputCharacters;
}

final class AgentRunRequest {
  AgentRunRequest({
    required this.runId,
    required this.chatId,
    required this.botId,
    this.turnId = '',
    this.messageId = '',
    required List<ChatMessage> messages,
    required Set<String> requestedToolNames,
    Set<String> approvalExemptToolNames = const {},
    List<ClaimEvidenceRequirement> verificationRequirements = const [],
    AgentCancellationToken? cancellationToken,
  }) : messages = List<ChatMessage>.unmodifiable(messages),
       requestedToolNames = Set<String>.unmodifiable(requestedToolNames),
       approvalExemptToolNames = Set<String>.unmodifiable(
         approvalExemptToolNames,
       ),
       verificationRequirements = List<ClaimEvidenceRequirement>.unmodifiable(
         verificationRequirements,
       ),
       cancellationToken = cancellationToken ?? AgentCancellationToken();

  final String runId;
  final String chatId;
  final String botId;
  final String turnId;
  final String messageId;
  final List<ChatMessage> messages;
  final Set<String> requestedToolNames;
  final Set<String> approvalExemptToolNames;
  final List<ClaimEvidenceRequirement> verificationRequirements;
  final AgentCancellationToken cancellationToken;
}

enum AgentRunStatus { completed, cancelled, failed, timedOut, limitExceeded }

enum AgentRunPhase {
  planning,
  awaitingApproval,
  executing,
  observing,
  verifying,
  synthesizing,
  committing,
  completed,
  cancelled,
  failed,
  timedOut,
  limitExceeded,
}

sealed class AgentRunEvent {
  const AgentRunEvent({required this.runId, required this.occurredAt});

  final String runId;
  final DateTime occurredAt;
}

final class AgentRunStateChanged extends AgentRunEvent {
  AgentRunStateChanged({
    required super.runId,
    required super.occurredAt,
    required this.phase,
    required this.sequence,
    this.reasonCode = '',
    List<String> missingRequirementIds = const [],
  }) : missingRequirementIds = List<String>.unmodifiable(missingRequirementIds);

  final AgentRunPhase phase;
  final int sequence;
  final String reasonCode;
  final List<String> missingRequirementIds;
}

final class AgentRunModelEventObserved extends AgentRunEvent {
  const AgentRunModelEventObserved({
    required super.runId,
    required super.occurredAt,
    required this.event,
  });

  final ModelEvent event;
}

final class AgentRunToolInvocationObserved extends AgentRunEvent {
  const AgentRunToolInvocationObserved({
    required super.runId,
    required super.occurredAt,
    required this.invocation,
  });

  final ToolInvocationRecord invocation;
}

final class AgentRunResult {
  AgentRunResult({
    required this.status,
    required this.text,
    required this.reasoning,
    required this.tokenUsage,
    required List<ToolInvocationRecord> toolInvocations,
    this.groundedAnswer,
    this.groundedValidation,
    List<ClaimEvidenceRequirement> verificationRequirements = const [],
    List<AgentRunStateChanged> stateTransitions = const [],
    this.degradedReason = '',
    this.error = '',
    this.providerFailure,
  }) : toolInvocations = List<ToolInvocationRecord>.unmodifiable(
         toolInvocations,
       ),
       verificationRequirements = List<ClaimEvidenceRequirement>.unmodifiable(
         verificationRequirements,
       ),
       stateTransitions = List<AgentRunStateChanged>.unmodifiable(
         stateTransitions,
       );

  final AgentRunStatus status;
  final String text;
  final String reasoning;
  final ModelTokenUsage tokenUsage;
  final List<ToolInvocationRecord> toolInvocations;
  final GroundedAnswerCandidate? groundedAnswer;
  final GroundedAnswerValidationResult? groundedValidation;
  final List<ClaimEvidenceRequirement> verificationRequirements;
  final List<AgentRunStateChanged> stateTransitions;
  final String degradedReason;
  final String error;
  final ProviderFailure? providerFailure;
}

typedef ModelEventObserver = void Function(ModelEvent event);
typedef ToolInvocationObserver = void Function(ToolInvocationRecord invocation);
typedef AgentRunEventObserver = void Function(AgentRunEvent event);
