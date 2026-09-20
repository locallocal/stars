part of 'conversation_task_app_harness.dart';

final class AcceptanceProviders implements AiProviderRepository {
  String route = 'backgroundTaskPlan';
  bool unsupportedClaim = false, failNarration = false;
  int mainReplies = 0, backgroundSessions = 0, closed = 0, cancelled = 0;
  @override
  AiProvider create(Bot bot) => _AcceptanceProvider(bot, this);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected provider operation');
}

final class _AcceptanceProvider extends AiProvider {
  _AcceptanceProvider(super.bot, this.owner);
  final AcceptanceProviders owner;
  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );
  @override
  ForegroundRoutingTransport get foregroundRoutingTransport =>
      ForegroundRoutingTransport.modelSession;
  @override
  AgentModelSession openModelSession(ModelRequest request) =>
      _AcceptanceSession(owner, request);
  @override
  Future<void> generateText(List<ChatMessage> messages) async =>
      throw StateError('Must use foreground routing');
}

final class _AcceptanceSession implements AgentModelSession {
  _AcceptanceSession(this.owner, this.request);
  final AcceptanceProviders owner;
  final ModelRequest request;
  @override
  Stream<ModelEvent> start() async* {
    if (request.options.foregroundRouting) {
      owner.mainReplies++;
      yield TextDelta(
        routeFrames(owner.route, [
          switch (owner.route) {
            'directReply' => {'text': 'Hello while the report is running'},
            'taskStatusRequest' => <String, Object?>{'taskId': null},
            _ => {
              'title': '读取报告',
              'objective': '读取报告并核验报告条目数',
              'steps': [
                {'stepId': 'read', 'summary': '读取报告'},
                {'stepId': 'verify', 'summary': '核验结果'},
              ],
              'allowedToolNames': ['inspect_report'],
              'acknowledgementDraft': '我会读取报告并核验条目数，完成后回复。',
            },
          },
        ]),
      );
    } else if (request.messages.first.content.startsWith(
      "Answer the user's question about task progress",
    )) {
      yield TextDelta(
        owner.failNarration ? '{}' : '报告读取已启动，目前在等外部处理返回结果，还没有完成核验。',
      );
    } else {
      owner.backgroundSessions++;
      final state =
          jsonDecode(request.messages.last.content) as Map<String, dynamic>;
      final observations = state['observations'] as List;
      if (!observations.any((raw) => (raw as Map)['status'] == 'succeeded')) {
        yield ToolCallRequested(
          callId: 'report-call',
          name: 'inspect_report',
          arguments: {'report': 'acceptance'},
        );
        yield const ModelTurnCompleted(stopReason: 'tool_calls');
        return;
      }
      yield ReasoningDelta('private acceptance reasoning must never be stored');
      yield const TextDelta('private acceptance draft must never be stored');
    }
    yield const ModelTurnCompleted();
  }

  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest synthesis, {
    List<ToolResult> pendingToolResults = const [],
  }) async* {
    owner.backgroundSessions++;
    yield GroundedAnswerProduced(
      GroundedAnswerCandidate(
        claims: [
          AnswerClaim(
            claimId: synthesis.availableClaims.single.claimId,
            text: '报告共 42 条。',
            kind: ClaimKind.currentFact,
            evidenceIds: [
              for (final evidence in synthesis.evidence) evidence.evidenceId,
            ],
          ),
          if (owner.unsupportedClaim)
            AnswerClaim(
              claimId: 'unsupported',
              text: '未经验证的文件已删除。',
              kind: ClaimKind.completedAction,
            ),
        ],
      ),
    );
    yield const ModelTurnCompleted();
  }

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) =>
      throw StateError('Rebuild sessions from durable facts');
  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) =>
      throw StateError('Rebuild sessions from durable facts');
  @override
  Future<void> cancel() async {
    owner.cancelled++;
  }

  @override
  void close() {
    owner.closed++;
  }
}
