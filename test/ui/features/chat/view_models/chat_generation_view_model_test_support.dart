part of 'chat_generation_view_model_test.dart';

final class _ViewModelAgentSession implements AgentModelSession {
  _ViewModelAgentSession({
    required this.toolName,
    required this.arguments,
    required this.repeatCall,
  });

  final String toolName;
  final Map<String, Object?> arguments;
  final bool repeatCall;

  @override
  Stream<ModelEvent> start() {
    final call = ToolCallRequested(
      callId: 'save-1',
      name: toolName,
      arguments: arguments,
    );
    return Stream.fromIterable([
      call,
      if (repeatCall) call,
      const ModelTurnCompleted(stopReason: 'tool_calls'),
    ]);
  }

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) {
    expect(results, hasLength(repeatCall ? 2 : 1));
    expect(results.every((result) => !result.isError), isTrue);
    return Stream.fromIterable([
      const TextDelta('Saved.'),
      const ModelTurnCompleted(stopReason: 'stop'),
    ]);
  }

  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) {
    throw StateError('The valid test answer must not require repair.');
  }

  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request, {
    List<ToolResult> pendingToolResults = const [],
  }) => Stream.fromIterable([
    GroundedAnswerProduced(
      GroundedAnswerCandidate(
        claims: [
          AnswerClaim(
            claimId: 'completed-action-1',
            text: 'Saved.',
            kind: ClaimKind.completedAction,
          ),
        ],
      ),
    ),
    const ModelTurnCompleted(stopReason: 'stop'),
  ]);

  @override
  Future<void> cancel() async {}

  @override
  void close() {}
}
