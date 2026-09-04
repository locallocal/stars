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
       assert(maxReliabilityRepairs >= 0),
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
    AgentCancellationToken? cancellationToken,
  }) : messages = List<ChatMessage>.unmodifiable(messages),
       requestedToolNames = Set<String>.unmodifiable(requestedToolNames),
       approvalExemptToolNames = Set<String>.unmodifiable(
         approvalExemptToolNames,
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
  final AgentCancellationToken cancellationToken;
}

enum AgentRunStatus { completed, cancelled, failed, timedOut, limitExceeded }

final class AgentRunResult {
  AgentRunResult({
    required this.status,
    required this.text,
    required this.reasoning,
    required this.tokenUsage,
    required List<ToolInvocationRecord> toolInvocations,
    this.groundedAnswer,
    this.error = '',
    this.providerFailure,
  }) : toolInvocations = List<ToolInvocationRecord>.unmodifiable(
         toolInvocations,
       );

  final AgentRunStatus status;
  final String text;
  final String reasoning;
  final ModelTokenUsage tokenUsage;
  final List<ToolInvocationRecord> toolInvocations;
  final GroundedAnswerCandidate? groundedAnswer;
  final String error;
  final ProviderFailure? providerFailure;
}

typedef ModelEventObserver = void Function(ModelEvent event);
typedef ToolInvocationObserver = void Function(ToolInvocationRecord invocation);
