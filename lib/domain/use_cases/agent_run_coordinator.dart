import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';
import 'package:stars/domain/services/post_write_verification_policy.dart';

part 'agent_run_coordinator_support.dart';
part 'agent_run_evidence.dart';
part 'agent_run_grounded_answer.dart';
part 'agent_run_models.dart';
part 'agent_run_persistence.dart';
part 'agent_run_provider_tools.dart';
part 'agent_run_state_machine.dart';

final class AgentRunCoordinator {
  const AgentRunCoordinator({
    required ToolRegistry toolRegistry,
    required ToolPolicy toolPolicy,
    ToolApprovalHandler approvalHandler = const DenyToolApprovalHandler(),
    JsonSchemaValidator schemaValidator = const JsonSchemaValidator(),
    AgentRunLimits limits = const AgentRunLimits(),
    ToolInvocationPersister? toolInvocationPersister,
    GroundedAnswerValidator? groundedAnswerValidator,
    PostWriteVerificationPolicy postWriteVerificationPolicy =
        const PostWriteVerificationPolicy(),
  }) : _toolRegistry = toolRegistry,
       _toolPolicy = toolPolicy,
       _approvalHandler = approvalHandler,
       _schemaValidator = schemaValidator,
       _limits = limits,
       _toolInvocationPersister = toolInvocationPersister,
       _groundedAnswerValidator = groundedAnswerValidator,
       _postWriteVerificationPolicy = postWriteVerificationPolicy;

  final ToolRegistry _toolRegistry;
  final ToolPolicy _toolPolicy;
  final ToolApprovalHandler _approvalHandler;
  final JsonSchemaValidator _schemaValidator;
  final AgentRunLimits _limits;
  final ToolInvocationPersister? _toolInvocationPersister;
  final GroundedAnswerValidator? _groundedAnswerValidator;
  final PostWriteVerificationPolicy _postWriteVerificationPolicy;

  Future<AgentRunResult> run({
    required AiProvider provider,
    required AgentRunRequest request,
    ModelEventObserver? onModelEvent,
    ToolInvocationObserver? onToolInvocation,
    AgentRunEventObserver? onRunEvent,
  }) async {
    final state = _AgentRunStateMachine(
      runId: request.runId,
      observer: onRunEvent,
    )..transition(AgentRunPhase.planning);
    final requestedExposureNames = <String>{
      ...request.requestedToolNames,
      ...request.verificationToolNames,
    };
    final exposedTools =
        requestedExposureNames.isEmpty
            ? const <ToolDefinition>[]
            : _toolRegistry.list(allowedNames: requestedExposureNames);
    final exposedNames = exposedTools.map((tool) => tool.name).toSet();
    final policyContext = ToolPolicyContext(
      runId: request.runId,
      chatId: request.chatId,
      botId: request.botId,
      requestedToolNames: request.requestedToolNames,
      verificationToolNames: request.verificationToolNames,
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
    final verificationRequirements = <ClaimEvidenceRequirement>[
      ...request.verificationRequirements,
    ];
    final verificationRequirementIds =
        verificationRequirements
            .map((requirement) => requirement.claimId)
            .toSet();
    var text = '';
    var reasoning = '';
    var usage = ModelTokenUsage.empty;
    var timedOut = false;
    var toolCallCount = 0;
    var pendingVerificationFeedback = '';
    var verificationRetryTurn = false;
    var degradedReason = request.verificationUnavailableReason;
    var verificationAuthorizationDenied = false;
    GroundedAnswerValidationResult? groundedValidation;
    AgentModelSession? session;
    final timeoutTimer = Timer(_limits.totalTimeout, () {
      timedOut = true;
      request.cancellationToken.cancel();
    });

    Future<void> observeInvocation(ToolInvocationRecord invocation) async {
      if (state.isTerminal || invocation.runId != request.runId) return;
      switch (invocation.status) {
        case ToolInvocationStatus.awaitingApproval:
          state.transition(AgentRunPhase.awaitingApproval);
        case ToolInvocationStatus.running:
          state.transition(AgentRunPhase.executing);
        case ToolInvocationStatus.requested:
        case ToolInvocationStatus.succeeded:
        case ToolInvocationStatus.failed:
        case ToolInvocationStatus.denied:
        case ToolInvocationStatus.cancelled:
        case ToolInvocationStatus.timedOut:
        case ToolInvocationStatus.duplicateReused:
        case ToolInvocationStatus.duplicateConflict:
        case ToolInvocationStatus.duplicate:
          break;
      }
      final existingIndex = invocationIndexes[invocation.attemptId];
      if (existingIndex == null) {
        invocationIndexes[invocation.attemptId] = invocations.length;
        invocations.add(invocation);
      } else {
        invocations[existingIndex] = invocation;
      }
      state.toolInvocation(invocation);
      onToolInvocation?.call(invocation);
      await _raceCancellation(
        persistence.record(invocation),
        request.cancellationToken,
      );
      if (request.verificationToolNames.contains(invocation.name) &&
          invocation.status == ToolInvocationStatus.denied) {
        verificationAuthorizationDenied = true;
        degradedReason = 'verification_tool_denied';
      }
      final definition = _toolRegistry.find(invocation.name)?.definition;
      if (definition != null) {
        final plan = _postWriteVerificationPolicy.plan(
          invocation: invocation,
          writeTool: definition,
          exposedTools: exposedTools,
          reservedClaimIds: verificationRequirementIds,
        );
        if (plan != null) {
          for (final requirement in <ClaimEvidenceRequirement>[
            plan.actionRequirement,
            plan.stateRequirement,
          ]) {
            verificationRequirementIds.add(requirement.claimId);
            verificationRequirements.add(requirement);
          }
          if (!plan.hasPairedRead && degradedReason.isEmpty) {
            degradedReason = 'post_write_verification_unavailable';
          }
        }
      }
      if (_terminalInvocationStatuses.contains(invocation.status)) {
        state.transition(AgentRunPhase.observing);
      }
    }

    AgentRunResult finish(
      AgentRunStatus status, {
      GroundedAnswerCandidate? groundedAnswer,
      String error = '',
      ProviderFailure? providerFailure,
    }) {
      if (status == AgentRunStatus.completed) {
        state.transition(AgentRunPhase.committing);
      }
      state.transition(
        _phaseForStatus(status),
        reasonCode: error.isNotEmpty ? error : degradedReason,
      );
      return AgentRunResult(
        status: status,
        text: text,
        reasoning: reasoning,
        tokenUsage: usage,
        toolInvocations: invocations,
        groundedAnswer: groundedAnswer,
        groundedValidation: groundedValidation,
        verificationRequirements: verificationRequirements,
        stateTransitions: state.history,
        degradedReason: degradedReason,
        error: error,
        providerFailure: providerFailure,
      );
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
        final providerToolResults = <ProviderNativeToolResult>[];
        final turnText = StringBuffer();
        state.transition(
          AgentRunPhase.planning,
          reasonCode:
              pendingVerificationFeedback.isEmpty
                  ? ''
                  : 'missing_evidence_retry',
        );
        final events =
            modelTurn == 0
                ? activeSession.start()
                : pendingVerificationFeedback.isNotEmpty
                ? activeSession.continueWithReliabilityFeedback(
                  pendingVerificationFeedback,
                )
                : activeSession.continueWith(results);
        verificationRetryTurn = pendingVerificationFeedback.isNotEmpty;
        pendingVerificationFeedback = '';
        results = const <ToolResult>[];
        await _consumeEvents(events, request.cancellationToken, (event) {
          state.modelEvent(event);
          if (event is! TextDelta) onModelEvent?.call(event);
          switch (event) {
            case TextDelta():
              turnText.write(event.text);
            case ReasoningDelta():
              reasoning += event.text;
            case ToolCallRequested():
              calls.add(event);
            case ProviderNativeToolResult():
              providerToolResults.add(event);
            case GroundedAnswerProduced():
              throw const _AgentModelFailure(
                'unexpected_grounded_answer_event',
                'unexpected_grounded_answer_event',
                null,
              );
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

        for (final providerToolResult in providerToolResults) {
          await _recordProviderNativeToolResult(
            runId: request.runId,
            event: providerToolResult,
            completedCalls: completedCalls,
            invocationIdentities: invocationIdentities,
            observeInvocation: observeInvocation,
          );
        }
        toolCallCount += providerToolResults.length;
        if (toolCallCount > _limits.maxToolCalls) {
          return finish(
            AgentRunStatus.limitExceeded,
            error: 'tool_call_limit_reached',
          );
        }

        if (calls.any(
          (call) => call.callId.trim().isEmpty || call.name.trim().isEmpty,
        )) {
          return finish(
            AgentRunStatus.failed,
            error: 'invalid_provider_tool_call',
          );
        }
        if (calls.isNotEmpty && modelTurn + 1 >= _limits.maxModelTurns) {
          return finish(
            AgentRunStatus.limitExceeded,
            error: 'model_turn_limit_reached',
          );
        }

        if (toolCallCount + calls.length > _limits.maxToolCalls) {
          return finish(
            AgentRunStatus.limitExceeded,
            error: 'tool_call_limit_reached',
          );
        }
        toolCallCount += calls.length;
        var executedCalls = false;
        if (calls.isNotEmpty) {
          final callRequests =
              calls.map((event) => event.toToolCallRequest()).toList();
          if (verificationRetryTurn &&
              callRequests.any((call) => !_isVerificationRetrySafe(call))) {
            degradedReason = 'verification_retry_side_effect_blocked';
          } else {
            state.transition(AgentRunPhase.executing);
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
                      shouldContinue: () => !verificationAuthorizationDenied,
                    );
            results = List<ToolResult>.unmodifiable(nextResults);
            executedCalls = true;
          }
        }

        state.transition(AgentRunPhase.observing);
        state.transition(AgentRunPhase.verifying);
        final coverage = await _raceCancellation(
          _evaluateEvidenceCoverage(
            runId: request.runId,
            requirements: verificationRequirements,
            invocations: invocations,
          ),
          request.cancellationToken,
        );
        request.cancellationToken.throwIfCancelled();
        if (executedCalls && !verificationAuthorizationDenied) continue;

        final hasObservationBudget =
            modelTurn + 1 < _limits.maxModelTurns &&
            toolCallCount < _limits.maxToolCalls;
        if (!coverage.isComplete &&
            degradedReason.isEmpty &&
            hasObservationBudget) {
          pendingVerificationFeedback = _missingEvidenceFeedback(
            runId: request.runId,
            requirements: verificationRequirements,
            missingRequirementIds: coverage.missingRequirementIds,
          );
          state.transition(
            AgentRunPhase.planning,
            reasonCode: 'missing_evidence',
            missingRequirementIds: coverage.missingRequirementIds,
          );
          continue;
        }
        if (!coverage.isComplete && degradedReason.isEmpty) {
          degradedReason = 'verification_budget_exhausted';
        }

        final synthesis = await _synthesizeValidatedAnswer(
          session: activeSession,
          draftText: turnText.toString(),
          invocations: invocations,
          request: request,
          verificationRequirements: verificationRequirements,
          cancellationToken: request.cancellationToken,
          state: state,
          onModelEvent: onModelEvent,
        );
        reasoning += synthesis.reasoning;
        usage = usage + synthesis.usage;
        groundedValidation = synthesis.validation;
        if (degradedReason.isEmpty && synthesis.degradedReason.isNotEmpty) {
          degradedReason = synthesis.degradedReason;
        }
        text = synthesis.candidate.renderedText;
        if (text.isNotEmpty) {
          final event = TextDelta(text);
          state.modelEvent(event);
          onModelEvent?.call(event);
        }
        return finish(
          AgentRunStatus.completed,
          groundedAnswer: synthesis.candidate,
        );
      }

      return finish(
        AgentRunStatus.limitExceeded,
        error: 'model_turn_limit_reached',
      );
    } on AgentRunCancelledException {
      return finish(
        timedOut ? AgentRunStatus.timedOut : AgentRunStatus.cancelled,
        error: timedOut ? 'agent_run_timeout' : '',
      );
    } on _AgentModelFailure catch (error) {
      final reason =
          error.providerFailure?.code ??
          (error.code.isEmpty
              ? AppFailure.from(error.message, code: 'agent_model_failed').code
              : error.code);
      return finish(
        AgentRunStatus.failed,
        error: reason,
        providerFailure: error.providerFailure,
      );
    } on ProviderFailure catch (error) {
      text = '';
      return finish(
        AgentRunStatus.failed,
        error: error.code,
        providerFailure: error,
      );
    } catch (error) {
      return finish(
        AgentRunStatus.failed,
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
          runId: runId,
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
          runId: runId,
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
          runId: runId,
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
          runId: runId,
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
      runId: runId,
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
