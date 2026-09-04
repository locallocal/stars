import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';

part 'agent_run_coordinator_support.dart';
part 'agent_run_evidence.dart';
part 'agent_run_persistence.dart';

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
  final String error;
  final ProviderFailure? providerFailure;
}

typedef ModelEventObserver = void Function(ModelEvent event);
typedef ToolInvocationObserver = void Function(ToolInvocationRecord invocation);

final class AgentRunCoordinator {
  const AgentRunCoordinator({
    required ToolRegistry toolRegistry,
    required ToolPolicy toolPolicy,
    ToolApprovalHandler approvalHandler = const DenyToolApprovalHandler(),
    JsonSchemaValidator schemaValidator = const JsonSchemaValidator(),
    AgentRunLimits limits = const AgentRunLimits(),
    ToolInvocationPersister? toolInvocationPersister,
  }) : _toolRegistry = toolRegistry,
       _toolPolicy = toolPolicy,
       _approvalHandler = approvalHandler,
       _schemaValidator = schemaValidator,
       _limits = limits,
       _toolInvocationPersister = toolInvocationPersister;

  final ToolRegistry _toolRegistry;
  final ToolPolicy _toolPolicy;
  final ToolApprovalHandler _approvalHandler;
  final JsonSchemaValidator _schemaValidator;
  final AgentRunLimits _limits;
  final ToolInvocationPersister? _toolInvocationPersister;

  Future<AgentRunResult> run({
    required AiProvider provider,
    required AgentRunRequest request,
    ModelEventObserver? onModelEvent,
    ToolInvocationObserver? onToolInvocation,
  }) async {
    final exposedTools =
        request.requestedToolNames.isEmpty
            ? const <ToolDefinition>[]
            : _toolRegistry.list(allowedNames: request.requestedToolNames);
    final exposedNames = exposedTools.map((tool) => tool.name).toSet();
    final policyContext = ToolPolicyContext(
      runId: request.runId,
      chatId: request.chatId,
      botId: request.botId,
      requestedToolNames: request.requestedToolNames,
      approvalExemptToolNames: request.approvalExemptToolNames,
    );
    final supportsParallelToolCalls =
        provider.capabilities.supportsParallelToolCalls;
    final invocations = <ToolInvocationRecord>[];
    final invocationIndexes = <String, int>{};
    final completedCalls = <String, _CompletedCall>{};
    final invocationIdentities = _InvocationIdentityRegistry(request.runId);
    final persistence = _RunToolPersistence(
      request: request,
      persister: _toolInvocationPersister,
    );
    var text = '';
    var reasoning = '';
    var usage = ModelTokenUsage.empty;
    var timedOut = false;
    var toolCallCount = 0;
    var reliabilityRepairs = 0;
    var reliabilityFeedback = '';
    AgentModelSession? session;
    final timeoutTimer = Timer(_limits.totalTimeout, () {
      timedOut = true;
      request.cancellationToken.cancel();
    });

    Future<void> observeInvocation(ToolInvocationRecord invocation) async {
      final existingIndex = invocationIndexes[invocation.attemptId];
      if (existingIndex == null) {
        invocationIndexes[invocation.attemptId] = invocations.length;
        invocations.add(invocation);
      } else {
        invocations[existingIndex] = invocation;
      }
      onToolInvocation?.call(invocation);
      await persistence.record(invocation);
    }

    try {
      request.cancellationToken.throwIfCancelled();
      session = provider.openModelSession(
        ModelRequest(
          messages: request.messages,
          tools: exposedTools,
          options: ModelGenerationOptions(
            allowParallelToolCalls:
                provider.capabilities.supportsParallelToolCalls,
            webSearch: provider.getWebSearch(),
            deepThinking: provider.getDeepThinking(),
          ),
        ),
      );
      final activeSession = session;
      unawaited(
        request.cancellationToken.whenCancelled.then((_) async {
          await activeSession.cancel();
        }),
      );

      var results = const <ToolResult>[];
      for (
        var modelTurn = 0;
        modelTurn < _limits.maxModelTurns;
        modelTurn += 1
      ) {
        request.cancellationToken.throwIfCancelled();
        final calls = <ToolCallRequested>[];
        final turnText = StringBuffer();
        final events = switch ((modelTurn, reliabilityFeedback)) {
          (0, _) => activeSession.start(),
          (_, final feedback) when feedback.isNotEmpty => activeSession
              .continueWithReliabilityFeedback(feedback),
          _ => activeSession.continueWith(results),
        };
        reliabilityFeedback = '';
        await _consumeEvents(events, request.cancellationToken, (event) {
          if (event is! TextDelta) onModelEvent?.call(event);
          switch (event) {
            case TextDelta():
              turnText.write(event.text);
            case ReasoningDelta():
              reasoning += event.text;
            case ToolCallRequested():
              calls.add(event);
            case UsageReported():
              usage = usage + event.usage;
            case ModelTurnFailed():
              throw _AgentModelFailure(
                event.error,
                event.code,
                event.providerFailure,
              );
            case ToolCallStarted():
            case ToolCallArgumentsDelta():
            case ModelTurnCompleted():
              break;
          }
        });

        if (calls.isEmpty) {
          final validation = _validateFinalAnswer(
            turnText.toString(),
            completedCalls: completedCalls,
          );
          if (!validation.isValid) {
            if (reliabilityRepairs < _limits.maxReliabilityRepairs &&
                modelTurn + 1 < _limits.maxModelTurns) {
              reliabilityRepairs += 1;
              reliabilityFeedback = _reliabilityFeedback(
                validation.reason,
                completedCalls,
              );
              results = const [];
              continue;
            }
            return AgentRunResult(
              status: AgentRunStatus.failed,
              text: '',
              reasoning: reasoning,
              tokenUsage: usage,
              toolInvocations: invocations,
              error: 'ungrounded_final_answer',
            );
          }
          text = validation.text;
          if (text.isNotEmpty) onModelEvent?.call(TextDelta(text));
          return AgentRunResult(
            status: AgentRunStatus.completed,
            text: text,
            reasoning: reasoning,
            tokenUsage: usage,
            toolInvocations: invocations,
          );
        }
        if (calls.any(
          (call) => call.callId.trim().isEmpty || call.name.trim().isEmpty,
        )) {
          return AgentRunResult(
            status: AgentRunStatus.failed,
            text: text,
            reasoning: reasoning,
            tokenUsage: usage,
            toolInvocations: invocations,
            error: 'invalid_provider_tool_call',
          );
        }
        if (modelTurn + 1 >= _limits.maxModelTurns) {
          return AgentRunResult(
            status: AgentRunStatus.limitExceeded,
            text: text,
            reasoning: reasoning,
            tokenUsage: usage,
            toolInvocations: invocations,
            error: 'model_turn_limit_reached',
          );
        }

        if (toolCallCount + calls.length > _limits.maxToolCalls) {
          return AgentRunResult(
            status: AgentRunStatus.limitExceeded,
            text: text,
            reasoning: reasoning,
            tokenUsage: usage,
            toolInvocations: invocations,
            error: 'tool_call_limit_reached',
          );
        }
        toolCallCount += calls.length;
        final callRequests =
            calls.map((event) => event.toToolCallRequest()).toList();
        final canRunInParallel =
            supportsParallelToolCalls &&
            callRequests.length > 1 &&
            callRequests.map((call) => call.callId).toSet().length ==
                callRequests.length &&
            callRequests.every(_isParallelSafe);
        final nextResults =
            canRunInParallel
                ? await Future.wait([
                  for (final call in callRequests)
                    _executeToolCall(
                      call: call,
                      runId: request.runId,
                      exposedNames: exposedNames,
                      policyContext: policyContext,
                      cancellationToken: request.cancellationToken,
                      completedCalls: completedCalls,
                      invocationIdentities: invocationIdentities,
                      observeInvocation: observeInvocation,
                    ),
                ])
                : await _executeSequentially(
                  calls: callRequests,
                  runId: request.runId,
                  exposedNames: exposedNames,
                  policyContext: policyContext,
                  cancellationToken: request.cancellationToken,
                  completedCalls: completedCalls,
                  invocationIdentities: invocationIdentities,
                  observeInvocation: observeInvocation,
                );
        results = List<ToolResult>.unmodifiable(nextResults);
      }

      return AgentRunResult(
        status: AgentRunStatus.limitExceeded,
        text: text,
        reasoning: reasoning,
        tokenUsage: usage,
        toolInvocations: invocations,
        error: 'model_turn_limit_reached',
      );
    } on AgentRunCancelledException {
      return AgentRunResult(
        status: timedOut ? AgentRunStatus.timedOut : AgentRunStatus.cancelled,
        text: text,
        reasoning: reasoning,
        tokenUsage: usage,
        toolInvocations: invocations,
        error: timedOut ? 'agent_run_timeout' : '',
      );
    } on _AgentModelFailure catch (error) {
      return AgentRunResult(
        status: AgentRunStatus.failed,
        text: text,
        reasoning: reasoning,
        tokenUsage: usage,
        toolInvocations: invocations,
        error:
            error.providerFailure?.code ??
            (error.code.isEmpty
                ? AppFailure.from(
                  error.message,
                  code: 'agent_model_failed',
                ).code
                : error.code),
        providerFailure: error.providerFailure,
      );
    } on ProviderFailure catch (error) {
      return AgentRunResult(
        status: AgentRunStatus.failed,
        text: '',
        reasoning: reasoning,
        tokenUsage: usage,
        toolInvocations: invocations,
        error: error.code,
        providerFailure: error,
      );
    } catch (error) {
      return AgentRunResult(
        status: AgentRunStatus.failed,
        text: text,
        reasoning: reasoning,
        tokenUsage: usage,
        toolInvocations: invocations,
        error: AppFailure.from(error, code: 'agent_run_failed').code,
      );
    } finally {
      timeoutTimer.cancel();
      session?.close();
    }
  }

  Future<ToolResult> _executeToolCall({
    required ToolCallRequest call,
    required String runId,
    required Set<String> exposedNames,
    required ToolPolicyContext policyContext,
    required AgentCancellationToken cancellationToken,
    required Map<String, _CompletedCall> completedCalls,
    required _InvocationIdentityRegistry invocationIdentities,
    required Future<void> Function(ToolInvocationRecord) observeInvocation,
  }) async {
    final fingerprint = _fingerprint(call);
    final identity = invocationIdentities.startAttempt(
      providerCallId: call.callId,
      fingerprint: fingerprint,
    );
    final invocationId = identity.invocationId;
    final attemptId = identity.attemptId;
    final previous = completedCalls[call.callId];
    if (identity.hasFingerprintConflict) {
      final definition = _toolRegistry.find(call.name)?.definition;
      final now = DateTime.now();
      await observeInvocation(
        ToolInvocationRecord(
          invocationId: invocationId,
          attemptId: attemptId,
          providerCallId: call.callId,
          name: call.name,
          title: definition?.title ?? '',
          mcpServerName: definition?.mcpServerName ?? '',
          source: definition?.source ?? ToolSource.builtIn,
          riskLevel: definition?.riskLevel ?? ToolRiskLevel.readOnly,
          status: ToolInvocationStatus.duplicateConflict,
          arguments: call.arguments,
          resultSummary: 'duplicate_call_id_conflict',
          errorCode: 'duplicate_call_id_conflict',
          startedAt: now,
          completedAt: now,
          durationMs: 0,
        ),
      );
      return _identifyResult(
        ToolResult(
          callId: call.callId,
          name: call.name,
          content: 'The call id was already used with different arguments.',
          isError: true,
          errorCode: 'duplicate_call_id_conflict',
          source: definition?.source ?? ToolSource.builtIn,
        ),
        identity,
      );
    }
    if (identity.matchingAttemptNumber > _limits.maxSameCallRetries + 1) {
      final definition = _toolRegistry.find(call.name)?.definition;
      final now = DateTime.now();
      const errorCode = 'tool_retry_limit_reached';
      await observeInvocation(
        ToolInvocationRecord(
          invocationId: invocationId,
          attemptId: attemptId,
          providerCallId: call.callId,
          name: call.name,
          title: definition?.title ?? '',
          mcpServerName: definition?.mcpServerName ?? '',
          source: definition?.source ?? ToolSource.builtIn,
          riskLevel: definition?.riskLevel ?? ToolRiskLevel.readOnly,
          status: ToolInvocationStatus.failed,
          arguments: call.arguments,
          resultSummary: errorCode,
          errorCode: errorCode,
          startedAt: now,
          completedAt: now,
          durationMs: 0,
        ),
      );
      return _identifyResult(
        ToolResult(
          callId: call.callId,
          name: call.name,
          content: 'The tool retry limit was reached.',
          isError: true,
          errorCode: errorCode,
          source: definition?.source ?? ToolSource.builtIn,
        ),
        identity,
      );
    }
    if (previous != null) {
      final definition = _toolRegistry.find(call.name)?.definition;
      final now = DateTime.now();
      await observeInvocation(
        ToolInvocationRecord(
          invocationId: invocationId,
          attemptId: attemptId,
          providerCallId: call.callId,
          name: call.name,
          title: definition?.title ?? '',
          mcpServerName: definition?.mcpServerName ?? '',
          source: definition?.source ?? ToolSource.builtIn,
          riskLevel: definition?.riskLevel ?? ToolRiskLevel.readOnly,
          status: ToolInvocationStatus.duplicateReused,
          arguments: call.arguments,
          resultSummary: 'duplicate_call_reused',
          startedAt: now,
          completedAt: now,
          durationMs: 0,
        ),
      );
      return previous.result;
    }

    final tool = _toolRegistry.find(call.name);
    if (tool == null || !exposedNames.contains(call.name)) {
      final now = DateTime.now();
      final result = _identifyResult(
        ToolResult(
          callId: call.callId,
          name: call.name,
          content: 'The requested tool is not available for this run.',
          isError: true,
          errorCode: 'tool_not_available',
          source: tool?.definition.source ?? ToolSource.builtIn,
        ),
        identity,
      );
      await observeInvocation(
        ToolInvocationRecord(
          invocationId: invocationId,
          attemptId: attemptId,
          providerCallId: call.callId,
          name: call.name,
          title: tool?.definition.title ?? '',
          mcpServerName: tool?.definition.mcpServerName ?? '',
          source: tool?.definition.source ?? ToolSource.builtIn,
          riskLevel: tool?.definition.riskLevel ?? ToolRiskLevel.readOnly,
          status: ToolInvocationStatus.denied,
          arguments: call.arguments,
          resultSummary: result.content,
          errorCode: result.errorCode,
          startedAt: now,
          completedAt: now,
          durationMs: 0,
        ),
      );
      completedCalls[call.callId] = _CompletedCall(result);
      return result;
    }
    final definition = tool.definition;
    final startedAt = DateTime.now();
    var record = ToolInvocationRecord(
      invocationId: invocationId,
      attemptId: attemptId,
      providerCallId: call.callId,
      name: call.name,
      title: definition.title,
      mcpServerName: definition.mcpServerName,
      source: definition.source,
      riskLevel: definition.riskLevel,
      status: ToolInvocationStatus.requested,
      arguments: call.arguments,
      startedAt: startedAt,
    );
    await observeInvocation(record);

    final inputIssues = _schemaValidator.validate(
      call.arguments,
      definition.inputSchema,
    );
    if (inputIssues.isNotEmpty) {
      final result = _identifyResult(
        ToolResult(
          callId: call.callId,
          name: call.name,
          content: 'Tool arguments failed schema validation.',
          isError: true,
          errorCode: 'invalid_tool_arguments',
          source: definition.source,
        ),
        identity,
      );
      record = _completeRecord(
        record,
        status: ToolInvocationStatus.failed,
        errorCode: result.errorCode,
        resultSummary: _issuesSummary(inputIssues),
      );
      await observeInvocation(record);
      completedCalls[call.callId] = _CompletedCall(result);
      return result;
    }

    final policyDecision = _toolPolicy.evaluate(
      definition,
      call,
      policyContext,
    );
    if (policyDecision.outcome == ToolPolicyOutcome.deny) {
      final result = _identifyResult(
        ToolResult(
          callId: call.callId,
          name: call.name,
          content: 'The tool call was blocked by application policy.',
          isError: true,
          errorCode:
              policyDecision.reason.isEmpty
                  ? 'tool_policy_denied'
                  : policyDecision.reason,
          source: definition.source,
        ),
        identity,
      );
      record = _completeRecord(
        record,
        status: ToolInvocationStatus.denied,
        errorCode: result.errorCode,
        resultSummary: policyDecision.reason,
        approvalDecision: ToolApprovalDecision.deny.name,
      );
      await observeInvocation(record);
      completedCalls[call.callId] = _CompletedCall(result);
      return result;
    }

    if (policyDecision.outcome == ToolPolicyOutcome.requireApproval) {
      record = record.copyWith(status: ToolInvocationStatus.awaitingApproval);
      await observeInvocation(record);
      ToolApprovalDecision approval;
      try {
        approval = await _raceCancellation(
          _approvalHandler
              .requestApproval(
                ToolApprovalRequest(
                  runId: runId,
                  call: call,
                  definition: definition,
                  reason: policyDecision.reason,
                ),
                cancellationToken,
              )
              .timeout(_limits.approvalTimeout),
          cancellationToken,
        );
      } on AgentRunCancelledException {
        record = _completeRecord(
          record,
          status: ToolInvocationStatus.cancelled,
          errorCode: 'agent_run_cancelled',
          approvalDecision: ToolApprovalDecision.deny.name,
        );
        await observeInvocation(record);
        rethrow;
      } on TimeoutException {
        final result = _identifyResult(
          ToolResult(
            callId: call.callId,
            name: call.name,
            content: 'Tool approval timed out.',
            isError: true,
            errorCode: 'tool_approval_timeout',
            source: definition.source,
          ),
          identity,
        );
        record = _completeRecord(
          record,
          status: ToolInvocationStatus.timedOut,
          errorCode: result.errorCode,
          approvalDecision: ToolApprovalDecision.deny.name,
        );
        await observeInvocation(record);
        completedCalls[call.callId] = _CompletedCall(result);
        return result;
      }
      if (approval != ToolApprovalDecision.allowOnce) {
        final result = _identifyResult(
          ToolResult(
            callId: call.callId,
            name: call.name,
            content: 'The user denied the tool call.',
            isError: true,
            errorCode: 'tool_approval_denied',
            source: definition.source,
          ),
          identity,
        );
        record = _completeRecord(
          record,
          status: ToolInvocationStatus.denied,
          errorCode: result.errorCode,
          approvalDecision: approval.name,
        );
        await observeInvocation(record);
        completedCalls[call.callId] = _CompletedCall(result);
        return result;
      }
      record = record.copyWith(approvalDecision: approval.name);
    }

    cancellationToken.throwIfCancelled();
    record = record.copyWith(status: ToolInvocationStatus.running);
    await observeInvocation(record);
    ToolResult result;
    try {
      result = await _raceCancellation(
        tool.execute(call, cancellationToken).timeout(_limits.toolTimeout),
        cancellationToken,
      );
    } on TimeoutException {
      result = _identifyResult(
        ToolResult(
          callId: call.callId,
          name: call.name,
          content: 'Tool execution timed out.',
          isError: true,
          errorCode: 'tool_execution_timeout',
          source: definition.source,
        ),
        identity,
      );
      record = _completeRecord(
        record,
        status: ToolInvocationStatus.timedOut,
        errorCode: result.errorCode,
      );
      await observeInvocation(record);
      completedCalls[call.callId] = _CompletedCall(result);
      return result;
    } on AgentRunCancelledException {
      record = _completeRecord(
        record,
        status: ToolInvocationStatus.cancelled,
        errorCode: 'agent_run_cancelled',
      );
      await observeInvocation(record);
      rethrow;
    } catch (_) {
      result = ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'Tool execution failed.',
        isError: true,
        errorCode: 'tool_execution_failed',
        source: definition.source,
      );
    }

    result = result.copyWith(source: definition.source);
    if (!result.isError &&
        result.content.trim().isEmpty &&
        result.structuredContent == null) {
      result = ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'The tool returned no usable result.',
        isError: true,
        errorCode: 'empty_tool_result',
        source: definition.source,
      );
    }

    final validated = _validateToolResultContract(definition, call, result);
    result = _identifyResult(_truncateResult(validated.result), identity);
    record = _completeRecord(
      record,
      status:
          result.isError
              ? ToolInvocationStatus.failed
              : ToolInvocationStatus.succeeded,
      errorCode: result.errorCode,
      resultSummary: _auditResultSummary(definition, result),
      evidenceCandidate: result.truncated ? null : validated.evidenceCandidate,
    );
    await observeInvocation(record);
    completedCalls[call.callId] = _CompletedCall(result);
    return result;
  }
}
