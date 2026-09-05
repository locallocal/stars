part of 'agent_run_coordinator.dart';

final class _AgentRunStateMachine {
  _AgentRunStateMachine({required this.runId, this.observer});

  final String runId;
  final AgentRunEventObserver? observer;
  final List<AgentRunStateChanged> _history = <AgentRunStateChanged>[];
  AgentRunPhase? _phase;
  var _sequence = 0;

  List<AgentRunStateChanged> get history =>
      List<AgentRunStateChanged>.unmodifiable(_history);

  bool get isTerminal => _phase?.isTerminal ?? false;

  void transition(
    AgentRunPhase phase, {
    String reasonCode = '',
    List<String> missingRequirementIds = const [],
  }) {
    if (isTerminal) return;
    if (_phase == phase &&
        reasonCode.isEmpty &&
        missingRequirementIds.isEmpty) {
      return;
    }
    _sequence += 1;
    _phase = phase;
    final event = AgentRunStateChanged(
      runId: runId,
      occurredAt: DateTime.now().toUtc(),
      phase: phase,
      sequence: _sequence,
      reasonCode: reasonCode,
      missingRequirementIds: List<String>.unmodifiable(missingRequirementIds),
    );
    _history.add(event);
    _notify(event);
  }

  void modelEvent(ModelEvent event) {
    if (isTerminal) return;
    _notify(
      AgentRunModelEventObserved(
        runId: runId,
        occurredAt: DateTime.now().toUtc(),
        event: event,
      ),
    );
  }

  void toolInvocation(ToolInvocationRecord invocation) {
    if (isTerminal || invocation.runId != runId) return;
    _notify(
      AgentRunToolInvocationObserved(
        runId: runId,
        occurredAt: DateTime.now().toUtc(),
        invocation: invocation,
      ),
    );
  }

  void _notify(AgentRunEvent event) {
    try {
      observer?.call(event);
    } on Object {
      // Diagnostic observers cannot change the run outcome.
    }
  }
}

extension on AgentRunPhase {
  bool get isTerminal => switch (this) {
    AgentRunPhase.completed ||
    AgentRunPhase.cancelled ||
    AgentRunPhase.failed ||
    AgentRunPhase.timedOut ||
    AgentRunPhase.limitExceeded => true,
    AgentRunPhase.planning ||
    AgentRunPhase.awaitingApproval ||
    AgentRunPhase.executing ||
    AgentRunPhase.observing ||
    AgentRunPhase.verifying ||
    AgentRunPhase.synthesizing ||
    AgentRunPhase.committing => false,
  };
}
