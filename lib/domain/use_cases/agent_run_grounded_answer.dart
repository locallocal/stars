part of 'agent_run_coordinator.dart';

extension _AgentRunGroundedAnswer on AgentRunCoordinator {
  Future<_GroundedSynthesisResult> _synthesizeGroundedAnswer({
    required AgentModelSession session,
    required String draftText,
    required List<ToolInvocationRecord> invocations,
    required AgentCancellationToken cancellationToken,
    ModelEventObserver? onModelEvent,
  }) async {
    final request = GroundedAnswerSynthesisRequest(
      draftText: draftText,
      evidence: [
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
      ],
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
}

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
