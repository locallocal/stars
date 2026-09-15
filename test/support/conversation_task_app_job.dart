part of 'conversation_task_app_harness.dart';

final class AcceptanceReportTool implements ExecutableTool {
  @override
  final definition = ToolDefinition(
    name: 'inspect_report',
    description: 'Read report count',
    toolVersion: '1',
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: {ToolCapability.externalRead},
    inputSchema: {
      'type': 'object',
      'properties': {
        'report': {'type': 'string'},
      },
      'required': ['report'],
      'additionalProperties': false,
    },
    outputSchema: {
      'type': 'object',
      'properties': toolEvidenceOutputSchemaProperties,
      'required': toolEvidenceOutputRequiredFields,
      'additionalProperties': false,
    },
    evidenceCapabilities: {EvidenceKind.observation},
    evidenceScope: ToolEvidenceScopeRule(
      subject: 'report',
      fixedScope: {'report': 'acceptance'},
    ),
    defaultEvidenceValidity: const Duration(hours: 1),
  );
  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async => throw StateError('The job adapter owns execution');
}

/// Disk-backed stand-in for a remote job service. It is outside the app database
/// and survives rebuilding every application/repository/provider/client object.
final class AcceptanceJobClient implements TaskJobClient {
  AcceptanceJobClient(this.ledger, this.clock);
  final File ledger;
  final RunnerClock clock;
  Map<String, dynamic> read() =>
      ledger.existsSync()
          ? jsonDecode(ledger.readAsStringSync()) as Map<String, dynamic>
          : {};
  void write(Map<String, dynamic> value) =>
      ledger.writeAsStringSync(jsonEncode(value), flush: true);
  void ready() => write({...read(), 'ready': true});
  ToolJobStarted pending() => ToolJobStarted(
    externalJobId: 'report-job',
    resumeHandle: 'handle:acceptance-report',
    safeStatus: 'Report pending',
    nextPollAt: clock.now().add(const Duration(hours: 1)),
  );

  @override
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String key,
    AgentCancellationToken token,
  ) async {
    final state = read();
    if (state.isNotEmpty && state['key'] != key) {
      throw StateError('A different job key would duplicate external work');
    }
    write({
      ...state,
      'key': key,
      'callId': call.callId,
      'starts': (state['starts'] as int? ?? 0) + 1,
      'created': 1,
      'ready': state['ready'] ?? false,
    });
    return pending();
  }

  @override
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) async {
    final state = read();
    // This callback can run while native WidgetTester is pumping a frame.
    // Do not invoke its guarded expect() API from application background work.
    if (job.externalJobId != 'report-job') {
      throw StateError('Unknown external job');
    }
    write({...state, 'polls': (state['polls'] as int? ?? 0) + 1});
    return state['ready'] == true
        ? complete(state['callId'] as String)
        : pending();
  }

  @override
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) async {
    final state = read();
    write({
      ...state,
      'cancelled': true,
      'cancels': (state['cancels'] as int? ?? 0) + 1,
    });
    return const ToolNotStarted();
  }

  @override
  Future<ToolReconciliation> lookup(
    ToolCallRequest call,
    String key,
    TaskExternalJob? job,
    AgentCancellationToken token,
  ) async {
    final state = read();
    write({...state, 'lookups': (state['lookups'] as int? ?? 0) + 1});
    if (state['key'] != key) return const ToolNotStarted();
    return ToolReconciled(
      state['ready'] == true ? complete(call.callId) : pending(),
    );
  }

  ToolCompleted complete(String callId) {
    final facts = [StructuredFact(name: 'report.count', value: 42)];
    return ToolCompleted(
      ToolResult(
        callId: callId,
        name: 'inspect_report',
        content: 'Report count read.',
        structuredContent: toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.observation,
          subject: 'report',
          scope: {'report': 'acceptance'},
          structuredFacts: facts,
          observedAt: clock.now(),
        ),
        evidenceKind: EvidenceKind.observation,
        subject: 'report',
        scope: {'report': 'acceptance'},
        structuredFacts: facts,
        observedAt: clock.now(),
      ),
    );
  }
}
