part of 'agent_run_coordinator.dart';

extension _AgentRunGroundedAnswer on AgentRunCoordinator {
  Future<_GroundedSynthesisResult> _synthesizeGroundedAnswer({
    required AgentModelSession session,
    required String draftText,
    required List<ToolInvocationRecord> invocations,
    required AgentCancellationToken cancellationToken,
    required _AgentRunStateMachine state,
    String reliabilityFeedback = '',
    ModelEventObserver? onModelEvent,
  }) async {
    final request = GroundedAnswerSynthesisRequest(
      draftText: draftText,
      evidence: _groundedEvidenceReferences(invocations),
      reliabilityFeedback: reliabilityFeedback,
    );
    GroundedAnswerCandidate? candidate;
    var reasoning = '';
    var usage = ModelTokenUsage.empty;
    var completed = false;
    var invalidEvent = false;
    await _consumeEvents(
      session.synthesizeGroundedAnswer(request),
      cancellationToken,
      (event) {
        state.modelEvent(event);
        onModelEvent?.call(event);
        switch (event) {
          case GroundedAnswerProduced():
            if (candidate != null) {
              invalidEvent = true;
            } else {
              candidate = event.candidate;
            }
          case ReasoningDelta():
            reasoning += event.text;
          case UsageReported():
            usage = usage + event.usage;
          case ModelTurnCompleted():
            completed = true;
          case ModelTurnFailed():
            throw _AgentModelFailure(
              event.error,
              event.code,
              event.providerFailure,
            );
          case TextDelta():
          case ToolCallStarted():
          case ToolCallArgumentsDelta():
          case ToolCallRequested():
          case ProviderNativeToolResult():
            invalidEvent = true;
        }
      },
    );
    if (invalidEvent || !completed || candidate == null) {
      throw const _AgentModelFailure(
        'invalid_grounded_answer_protocol',
        'invalid_grounded_answer_protocol',
        null,
      );
    }
    return _GroundedSynthesisResult(
      candidate: candidate!,
      reasoning: reasoning,
      usage: usage,
    );
  }

  Future<_ValidatedSynthesisResult> _synthesizeValidatedAnswer({
    required AgentModelSession session,
    required String draftText,
    required List<ToolInvocationRecord> invocations,
    required AgentRunRequest request,
    required AgentCancellationToken cancellationToken,
    required _AgentRunStateMachine state,
    ModelEventObserver? onModelEvent,
  }) async {
    var feedback = '';
    var reasoning = '';
    var usage = ModelTokenUsage.empty;
    for (
      var attempt = 0;
      attempt <= _limits.maxReliabilityRepairs;
      attempt += 1
    ) {
      state.transition(
        AgentRunPhase.synthesizing,
        reasonCode: attempt == 0 ? '' : 'grounded_answer_repair',
      );
      _GroundedSynthesisResult synthesis;
      try {
        synthesis = await _synthesizeGroundedAnswer(
          session: session,
          draftText: draftText,
          invocations: invocations,
          cancellationToken: cancellationToken,
          state: state,
          reliabilityFeedback: feedback,
          onModelEvent: onModelEvent,
        );
      } on _AgentModelFailure catch (error) {
        if (attempt >= _limits.maxReliabilityRepairs) rethrow;
        feedback = _groundedProtocolRepairFeedback(error.code);
        continue;
      }
      reasoning += synthesis.reasoning;
      usage = usage + synthesis.usage;

      final validator = _groundedAnswerValidator;
      if (request.verificationRequirements.isEmpty || validator == null) {
        return _ValidatedSynthesisResult(
          candidate: synthesis.candidate,
          validation: null,
          reasoning: reasoning,
          usage: usage,
          degradedReason:
              request.verificationRequirements.isEmpty
                  ? ''
                  : 'grounded_validator_unavailable',
        );
      }
      state.transition(AgentRunPhase.verifying);
      final validation = await _raceCancellation(
        validator.validate(
          runId: request.runId,
          candidate: synthesis.candidate,
          requirements: request.verificationRequirements,
          validatedAt: DateTime.now(),
        ),
        cancellationToken,
      );
      if (validation.trustLevel == AnswerTrustLevel.verified &&
          validation.unmatchedRequirementIds.isEmpty) {
        return _ValidatedSynthesisResult(
          candidate: synthesis.candidate,
          validation: validation,
          reasoning: reasoning,
          usage: usage,
        );
      }
      if (attempt >= _limits.maxReliabilityRepairs) {
        return _ValidatedSynthesisResult(
          candidate: synthesis.candidate,
          validation: validation,
          reasoning: reasoning,
          usage: usage,
          degradedReason: 'claim_validation_incomplete',
        );
      }
      feedback = _groundedClaimRepairFeedback(validation);
    }
    throw StateError('Grounded synthesis attempts were exhausted.');
  }

  Future<EvidenceRequirementCoverage> _evaluateEvidenceCoverage({
    required AgentRunRequest request,
    required List<ToolInvocationRecord> invocations,
  }) {
    final requirements = request.verificationRequirements;
    if (requirements.isEmpty) {
      return Future<EvidenceRequirementCoverage>.value(
        EvidenceRequirementCoverage(
          coveredRequirementIds: const [],
          missingRequirementIds: const [],
          evidenceIds: const [],
        ),
      );
    }
    final validator = _groundedAnswerValidator;
    if (validator == null) {
      return Future<EvidenceRequirementCoverage>.value(
        EvidenceRequirementCoverage(
          coveredRequirementIds: const [],
          missingRequirementIds: [
            for (final requirement in requirements) requirement.claimId,
          ],
          evidenceIds: const [],
        ),
      );
    }
    return validator.evaluateCoverage(
      runId: request.runId,
      requirements: requirements,
      evidenceIds: _groundedEvidenceReferences(
        invocations,
      ).map((reference) => reference.evidenceId),
      validatedAt: DateTime.now(),
    );
  }
}

List<GroundedEvidenceReference> _groundedEvidenceReferences(
  List<ToolInvocationRecord> invocations,
) => List<GroundedEvidenceReference>.unmodifiable([
  for (final invocation in invocations)
    if (_canReferenceAsEvidence(invocation))
      GroundedEvidenceReference(
        evidenceId: ToolEvidenceRecord.evidenceIdForAttempt(
          invocation.attemptId,
        ),
        providerCallId: invocation.providerCallId,
        toolName: invocation.name,
        isError: invocation.status != ToolInvocationStatus.succeeded,
      ),
]);

String _missingEvidenceFeedback({
  required String runId,
  required List<ClaimEvidenceRequirement> requirements,
  required List<String> missingRequirementIds,
}) {
  final missing = missingRequirementIds.toSet();
  return jsonEncode(<String, Object?>{
    'type': 'stars_missing_evidence',
    'version': 1,
    'run_id': runId,
    'instructions':
        'Request only the least-privileged eligible read-only Tool needed '
        'to cover these requirements. Do not repeat successful writes.',
    'requirements': [
      for (final requirement in requirements)
        if (missing.contains(requirement.claimId))
          <String, Object?>{
            'claim_id': requirement.claimId,
            'claim_kind': requirement.claimKind?.wireName,
            'allowed_evidence_kinds': [
              for (final kind in requirement.allowedEvidenceKinds) kind.name,
            ],
            'subject': requirement.subject,
            'scope': requirement.scope,
            'required_capabilities': [
              for (final capability in requirement.requiredCapabilities)
                capability.name,
            ],
            'required_fact_names': requirement.requiredFactNames.toList(),
          },
    ],
  });
}

String _groundedProtocolRepairFeedback(String reasonCode) =>
    jsonEncode(<String, Object?>{
      'type': 'stars_grounded_answer_repair',
      'version': 1,
      'reason': reasonCode.isEmpty ? 'invalid_grounded_answer' : reasonCode,
      'instructions':
          'Return one valid structured answer. Do not request or invoke Tools.',
    });

String _groundedClaimRepairFeedback(
  GroundedAnswerValidationResult validation,
) => jsonEncode(<String, Object?>{
  'type': 'stars_grounded_answer_repair',
  'version': 1,
  'instructions':
      'Correct or remove rejected claim-evidence bindings. Do not request '
      'or invoke Tools.',
  'unmatched_requirement_ids': validation.unmatchedRequirementIds,
  'claims': [
    for (final claim in validation.claims)
      if (claim.trustLevel == ClaimTrustLevel.unverified)
        <String, Object?>{
          'claim_id': claim.claim.claimId,
          'reasons': [for (final issue in claim.issues) issue.reason.name],
        },
  ],
});

bool _canReferenceAsEvidence(ToolInvocationRecord invocation) {
  if (invocation.attemptId.isEmpty) return false;
  if (invocation.status == ToolInvocationStatus.succeeded) {
    return invocation.evidenceCandidate != null;
  }
  return const <ToolInvocationStatus>{
    ToolInvocationStatus.failed,
    ToolInvocationStatus.denied,
    ToolInvocationStatus.cancelled,
    ToolInvocationStatus.timedOut,
  }.contains(invocation.status);
}

final class _GroundedSynthesisResult {
  const _GroundedSynthesisResult({
    required this.candidate,
    required this.reasoning,
    required this.usage,
  });

  final GroundedAnswerCandidate candidate;
  final String reasoning;
  final ModelTokenUsage usage;
}

final class _ValidatedSynthesisResult {
  const _ValidatedSynthesisResult({
    required this.candidate,
    required this.validation,
    required this.reasoning,
    required this.usage,
    this.degradedReason = '',
  });

  final GroundedAnswerCandidate candidate;
  final GroundedAnswerValidationResult? validation;
  final String reasoning;
  final ModelTokenUsage usage;
  final String degradedReason;
}
