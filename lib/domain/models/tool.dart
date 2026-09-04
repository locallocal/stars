import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/mcp_installer.dart';
import 'package:stars/domain/models/skill_installer.dart';

part 'tool_json_schema_validator.dart';
part 'tool_evidence.dart';
part 'tool_evidence_contract.dart';

enum ToolSource { builtIn, mcp, skillScript, providerNative }

enum ToolRiskLevel { readOnly, write, destructive }

enum ToolCapability {
  compute,
  localRead,
  network,
  externalRead,
  localWrite,
  externalWrite,
  process,
}

final class ToolDefinition {
  ToolDefinition({
    required this.name,
    this.title = '',
    this.mcpServerName = '',
    required this.description,
    required Map<String, Object?> inputSchema,
    Map<String, Object?>? outputSchema,
    required this.source,
    required this.riskLevel,
    Set<ToolCapability> capabilities = const {},
    this.toolVersion = 'unversioned',
    Set<EvidenceKind> evidenceCapabilities = const {},
    this.evidenceScope,
    this.defaultEvidenceValidity,
    this.requiresReadAfterWrite = false,
  }) : inputSchema = Map<String, Object?>.unmodifiable(inputSchema),
       outputSchema =
           outputSchema == null
               ? null
               : Map<String, Object?>.unmodifiable(outputSchema),
       capabilities = Set<ToolCapability>.unmodifiable(capabilities),
       evidenceCapabilities = Set<EvidenceKind>.unmodifiable(
         evidenceCapabilities,
       ) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Tool name cannot be empty.');
    }
    if (this.inputSchema['type'] != 'object') {
      throw ArgumentError.value(
        inputSchema,
        'inputSchema',
        'Tool input schema must describe an object.',
      );
    }
    _validateToolEvidenceDefinition(this);
  }

  final String name;
  final String title;
  final String mcpServerName;
  final String description;
  final Map<String, Object?> inputSchema;
  final Map<String, Object?>? outputSchema;
  final ToolSource source;
  final ToolRiskLevel riskLevel;
  final Set<ToolCapability> capabilities;
  final String toolVersion;
  final Set<EvidenceKind> evidenceCapabilities;
  final ToolEvidenceScopeRule? evidenceScope;
  final Duration? defaultEvidenceValidity;
  final bool requiresReadAfterWrite;

  bool get producesEvidence => evidenceCapabilities.isNotEmpty;
}

final class ToolCallRequest {
  ToolCallRequest({
    required this.callId,
    required this.name,
    Map<String, Object?> arguments = const {},
  }) : arguments = Map<String, Object?>.unmodifiable(arguments);

  final String callId;
  final String name;
  final Map<String, Object?> arguments;
}

final class ToolResult {
  ToolResult({
    required this.callId,
    required this.name,
    required this.content,
    this.invocationId = '',
    this.attemptId = '',
    this.evidenceId = '',
    this.structuredContent,
    this.isError = false,
    this.errorCode = '',
    this.source = ToolSource.builtIn,
    this.truncated = false,
    this.schemaValid = false,
    this.evidenceKind,
    this.subject = '',
    Map<String, Object?> scope = const {},
    List<StructuredFact> structuredFacts = const [],
    DateTime? observedAt,
    DateTime? validUntil,
    String resultDigest = '',
  }) : scope = _freezeJsonMap(scope, 'scope'),
       structuredFacts = List<StructuredFact>.unmodifiable(structuredFacts),
       observedAt = observedAt?.toUtc(),
       validUntil = validUntil?.toUtc(),
       resultDigest = _toolResultDigest(
         content,
         structuredContent,
         supplied: resultDigest,
       );

  final String callId;
  final String name;
  final String content;
  final String invocationId;
  final String attemptId;
  final String evidenceId;
  final Object? structuredContent;
  final bool isError;
  final String errorCode;
  final ToolSource source;
  final bool truncated;
  final bool schemaValid;
  final EvidenceKind? evidenceKind;
  final String subject;
  final Map<String, Object?> scope;
  final List<StructuredFact> structuredFacts;
  final DateTime? observedAt;
  final DateTime? validUntil;
  final String resultDigest;

  ToolResult copyWith({
    String? content,
    String? invocationId,
    String? attemptId,
    String? evidenceId,
    Object? structuredContent,
    bool clearStructuredContent = false,
    bool? isError,
    String? errorCode,
    ToolSource? source,
    bool? truncated,
    bool? schemaValid,
    EvidenceKind? evidenceKind,
    bool clearEvidenceKind = false,
    String? subject,
    Map<String, Object?>? scope,
    List<StructuredFact>? structuredFacts,
    DateTime? observedAt,
    DateTime? validUntil,
    bool clearValidUntil = false,
    String? resultDigest,
  }) {
    return ToolResult(
      callId: callId,
      name: name,
      content: content ?? this.content,
      invocationId: invocationId ?? this.invocationId,
      attemptId: attemptId ?? this.attemptId,
      evidenceId: evidenceId ?? this.evidenceId,
      structuredContent:
          clearStructuredContent
              ? null
              : structuredContent ?? this.structuredContent,
      isError: isError ?? this.isError,
      errorCode: errorCode ?? this.errorCode,
      source: source ?? this.source,
      truncated: truncated ?? this.truncated,
      schemaValid: schemaValid ?? this.schemaValid,
      evidenceKind:
          clearEvidenceKind ? null : evidenceKind ?? this.evidenceKind,
      subject: subject ?? this.subject,
      scope: scope ?? this.scope,
      structuredFacts: structuredFacts ?? this.structuredFacts,
      observedAt: observedAt ?? this.observedAt,
      validUntil: clearValidUntil ? null : validUntil ?? this.validUntil,
      resultDigest: resultDigest ?? this.resultDigest,
    );
  }
}

/// Encodes a tool result with explicit reliability and provenance metadata.
/// Provider adapters must send this envelope instead of bare tool text.
String encodeToolResultForModel(ToolResult result) {
  Object? structured;
  if (result.structuredContent != null) {
    try {
      structured = jsonDecode(jsonEncode(result.structuredContent));
    } on Object {
      structured = null;
    }
  }
  return jsonEncode({
    'type': 'stars_tool_result',
    'version': 3,
    'data_classification': 'untrusted_tool_data',
    'instructions_allowed': false,
    'evidence_id': result.evidenceId,
    'invocation_id': result.invocationId,
    'attempt_id': result.attemptId,
    'provider_call_id': result.callId,
    'call_id': result.callId,
    'tool_name': result.name,
    'source': result.source.name,
    'status': result.isError ? 'error' : 'success',
    'error_code': result.errorCode,
    'truncated': result.truncated,
    'schema_valid': result.schemaValid,
    'observed_at': result.observedAt?.toIso8601String(),
    'valid_until': result.validUntil?.toIso8601String(),
    'result_digest': result.resultDigest,
    'evidence_kind': result.evidenceKind?.name,
    'subject': result.subject,
    'scope': result.scope,
    'facts': [
      for (final fact in result.structuredFacts) _structuredFactJson(fact),
    ],
    'content': result.content,
    if (structured != null) 'structured_data': structured,
  });
}

enum ToolPolicyOutcome { allow, requireApproval, deny }

final class ToolPolicyDecision {
  const ToolPolicyDecision({required this.outcome, this.reason = ''});

  const ToolPolicyDecision.allow({this.reason = ''})
    : outcome = ToolPolicyOutcome.allow;

  const ToolPolicyDecision.requireApproval({this.reason = ''})
    : outcome = ToolPolicyOutcome.requireApproval;

  const ToolPolicyDecision.deny({this.reason = ''})
    : outcome = ToolPolicyOutcome.deny;

  final ToolPolicyOutcome outcome;
  final String reason;
}

final class ToolPolicyContext {
  ToolPolicyContext({
    required this.runId,
    required this.chatId,
    required this.botId,
    Set<String> requestedToolNames = const {},
    Set<String> approvalExemptToolNames = const {},
  }) : requestedToolNames = Set<String>.unmodifiable(requestedToolNames),
       approvalExemptToolNames = Set<String>.unmodifiable(
         approvalExemptToolNames,
       );

  final String runId;
  final String chatId;
  final String botId;
  final Set<String> requestedToolNames;
  final Set<String> approvalExemptToolNames;
}

abstract interface class ToolPolicy {
  ToolPolicyDecision evaluate(
    ToolDefinition definition,
    ToolCallRequest call,
    ToolPolicyContext context,
  );
}

final class DefaultToolPolicy implements ToolPolicy {
  const DefaultToolPolicy({
    this.allowNetwork = false,
    this.allowLocalRead = false,
    this.allowExternalRead = false,
    this.allowDestructiveWithApproval = false,
    this.allowSkillScripts = false,
    this.allowProcessExecution = false,
  });

  final bool allowNetwork;
  final bool allowLocalRead;
  final bool allowExternalRead;
  final bool allowDestructiveWithApproval;
  final bool allowSkillScripts;
  final bool allowProcessExecution;

  @override
  ToolPolicyDecision evaluate(
    ToolDefinition definition,
    ToolCallRequest call,
    ToolPolicyContext context,
  ) {
    if (!context.requestedToolNames.contains(definition.name)) {
      return const ToolPolicyDecision.deny(
        reason: 'tool_not_requested_by_active_skill',
      );
    }
    if (definition.source == ToolSource.mcp &&
        context.approvalExemptToolNames.contains(definition.name)) {
      return const ToolPolicyDecision.allow(
        reason: 'bot_mcp_tool_approval_exempt',
      );
    }
    const historyTools = {
      'search_conversation_history',
      'read_conversation_history',
    };
    if (definition.source == ToolSource.builtIn &&
        definition.riskLevel == ToolRiskLevel.readOnly &&
        definition.capabilities.length == 1 &&
        definition.capabilities.contains(ToolCapability.localRead) &&
        historyTools.contains(definition.name) &&
        context.approvalExemptToolNames.contains(definition.name)) {
      return const ToolPolicyDecision.allow(
        reason: 'conversation_history_read_only_exempt',
      );
    }
    const inventoryTools = {
      ...skillInventoryToolNames,
      ...mcpInventoryToolNames,
    };
    if (definition.source == ToolSource.builtIn &&
        definition.riskLevel == ToolRiskLevel.readOnly &&
        definition.capabilities.length == 1 &&
        definition.capabilities.contains(ToolCapability.localRead) &&
        inventoryTools.contains(definition.name) &&
        context.approvalExemptToolNames.contains(definition.name)) {
      return const ToolPolicyDecision.allow(
        reason: 'application_inventory_read_only_exempt',
      );
    }
    if (definition.source == ToolSource.skillScript) {
      return allowSkillScripts
          ? const ToolPolicyDecision.requireApproval(
            reason: 'skill_script_requires_approval',
          )
          : const ToolPolicyDecision.deny(reason: 'process_execution_disabled');
    }
    if (definition.capabilities.contains(ToolCapability.process)) {
      return allowProcessExecution
          ? const ToolPolicyDecision.requireApproval(
            reason: 'process_execution_requires_approval',
          )
          : const ToolPolicyDecision.deny(reason: 'process_execution_disabled');
    }
    if (definition.riskLevel == ToolRiskLevel.destructive) {
      return allowDestructiveWithApproval
          ? const ToolPolicyDecision.requireApproval(
            reason: 'destructive_write_requires_approval',
          )
          : const ToolPolicyDecision.deny(reason: 'destructive_tools_disabled');
    }
    if (definition.capabilities.isEmpty) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'unspecified_capability_requires_approval',
      );
    }
    if (definition.riskLevel == ToolRiskLevel.write ||
        definition.capabilities.contains(ToolCapability.localWrite) ||
        definition.capabilities.contains(ToolCapability.externalWrite)) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'write_requires_approval',
      );
    }
    if (definition.capabilities.contains(ToolCapability.network) &&
        !allowNetwork) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'network_requires_approval',
      );
    }
    if (definition.capabilities.contains(ToolCapability.localRead) &&
        !allowLocalRead) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'local_read_requires_approval',
      );
    }
    if (definition.capabilities.contains(ToolCapability.externalRead) &&
        !allowExternalRead) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'external_read_requires_approval',
      );
    }
    return const ToolPolicyDecision.allow();
  }
}

enum ToolApprovalDecision { allowOnce, deny }

final class ToolApprovalRequest {
  const ToolApprovalRequest({
    required this.runId,
    required this.call,
    required this.definition,
    required this.reason,
  });

  final String runId;
  final ToolCallRequest call;
  final ToolDefinition definition;
  final String reason;
}

abstract interface class ToolApprovalHandler {
  Future<ToolApprovalDecision> requestApproval(
    ToolApprovalRequest request,
    AgentCancellationToken cancellationToken,
  );
}

final class DenyToolApprovalHandler implements ToolApprovalHandler {
  const DenyToolApprovalHandler();

  @override
  Future<ToolApprovalDecision> requestApproval(
    ToolApprovalRequest request,
    AgentCancellationToken cancellationToken,
  ) async {
    return ToolApprovalDecision.deny;
  }
}

final class AgentCancellationToken {
  final Completer<void> _cancelled = Completer<void>();

  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  void throwIfCancelled() {
    if (isCancelled) throw const AgentRunCancelledException();
  }
}

final class AgentRunCancelledException implements Exception {
  const AgentRunCancelledException();

  @override
  String toString() => 'Agent run cancelled.';
}

abstract interface class ExecutableTool {
  ToolDefinition get definition;

  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  );
}

abstract interface class ToolRegistry {
  List<ToolDefinition> list({Set<String> allowedNames = const {}});

  ExecutableTool? find(String name);
}

final class StaticToolRegistry implements ToolRegistry {
  factory StaticToolRegistry(Iterable<ExecutableTool> tools) {
    final items = List<ExecutableTool>.of(tools);
    final indexed = <String, ExecutableTool>{
      for (final tool in items) tool.definition.name: tool,
    };
    if (indexed.length != items.length) {
      throw ArgumentError('Tool names must be globally unique.');
    }
    return StaticToolRegistry._(Map.unmodifiable(indexed));
  }

  const StaticToolRegistry._(this._tools);

  final Map<String, ExecutableTool> _tools;

  @override
  ExecutableTool? find(String name) => _tools[name];

  @override
  List<ToolDefinition> list({Set<String> allowedNames = const {}}) {
    final definitions = [
      for (final entry in _tools.entries)
        if (allowedNames.isEmpty || allowedNames.contains(entry.key))
          entry.value.definition,
    ]..sort((left, right) => left.name.compareTo(right.name));
    return List<ToolDefinition>.unmodifiable(definitions);
  }
}

final class DynamicToolRegistry implements ToolRegistry {
  factory DynamicToolRegistry(Iterable<ExecutableTool> fixedTools) {
    final fixed = <String, ExecutableTool>{};
    for (final tool in fixedTools) {
      if (fixed.containsKey(tool.definition.name)) {
        throw ArgumentError('Tool names must be globally unique.');
      }
      fixed[tool.definition.name] = tool;
    }
    return DynamicToolRegistry._(Map.unmodifiable(fixed));
  }

  DynamicToolRegistry._(this._fixedTools);

  final Map<String, ExecutableTool> _fixedTools;
  Map<String, Map<String, ExecutableTool>> _dynamicSources = const {};

  void replaceDynamic(Iterable<ExecutableTool> tools) {
    replaceDynamicSource('default', tools);
  }

  void replaceDynamicSource(String source, Iterable<ExecutableTool> tools) {
    if (source.trim().isEmpty) {
      throw ArgumentError.value(source, 'source', 'Source cannot be empty.');
    }
    final next = <String, ExecutableTool>{};
    for (final tool in tools) {
      final name = tool.definition.name;
      final usedByOtherSource = _dynamicSources.entries.any(
        (entry) => entry.key != source && entry.value.containsKey(name),
      );
      if (_fixedTools.containsKey(name) ||
          usedByOtherSource ||
          next.containsKey(name)) {
        throw ArgumentError.value(
          name,
          'tools',
          'Tool names must be globally unique.',
        );
      }
      next[name] = tool;
    }
    _dynamicSources = Map<String, Map<String, ExecutableTool>>.unmodifiable({
      ..._dynamicSources,
      source: Map<String, ExecutableTool>.unmodifiable(next),
    });
  }

  @override
  ExecutableTool? find(String name) {
    final fixed = _fixedTools[name];
    if (fixed != null) return fixed;
    for (final tools in _dynamicSources.values) {
      final dynamic = tools[name];
      if (dynamic != null) return dynamic;
    }
    return null;
  }

  @override
  List<ToolDefinition> list({Set<String> allowedNames = const {}}) {
    final definitions = [
      for (final entry in [
        ..._fixedTools.entries,
        for (final source in _dynamicSources.values) ...source.entries,
      ])
        if (allowedNames.isEmpty || allowedNames.contains(entry.key))
          entry.value.definition,
    ]..sort((left, right) => left.name.compareTo(right.name));
    return List<ToolDefinition>.unmodifiable(definitions);
  }
}

/// A request-local overlay used for tools that must capture immutable run data.
final class OverlayToolRegistry implements ToolRegistry {
  factory OverlayToolRegistry({
    required ToolRegistry parent,
    required Iterable<ExecutableTool> overlayTools,
  }) {
    final overlay = <String, ExecutableTool>{};
    for (final tool in overlayTools) {
      final name = tool.definition.name;
      if (overlay.containsKey(name) || parent.find(name) != null) {
        throw ArgumentError.value(
          name,
          'overlayTools',
          'Tool name is reserved.',
        );
      }
      overlay[name] = tool;
    }
    return OverlayToolRegistry._(parent, Map.unmodifiable(overlay));
  }

  const OverlayToolRegistry._(this._parent, this._overlay);

  final ToolRegistry _parent;
  final Map<String, ExecutableTool> _overlay;

  @override
  ExecutableTool? find(String name) => _overlay[name] ?? _parent.find(name);

  @override
  List<ToolDefinition> list({Set<String> allowedNames = const {}}) {
    final definitions = [
      ..._parent.list(allowedNames: allowedNames),
      for (final entry in _overlay.entries)
        if (allowedNames.isEmpty || allowedNames.contains(entry.key))
          entry.value.definition,
    ]..sort((left, right) => left.name.compareTo(right.name));
    return List.unmodifiable(definitions);
  }
}

enum ToolInvocationStatus {
  requested,
  awaitingApproval,
  running,
  succeeded,
  failed,
  denied,
  cancelled,
  timedOut,
  duplicateReused,
  duplicateConflict,

  /// Retained so audit records written before GRD-004 remain readable.
  duplicate,
}

final class ToolInvocationRecord {
  ToolInvocationRecord({
    String invocationId = '',
    String attemptId = '',
    String providerCallId = '',
    String executionId = '',
    String callId = '',
    required this.name,
    this.title = '',
    this.mcpServerName = '',
    required this.source,
    required this.riskLevel,
    required this.status,
    Map<String, Object?> arguments = const {},
    this.resultSummary = '',
    this.errorCode = '',
    this.approvalDecision = '',
    required this.startedAt,
    this.completedAt,
    this.durationMs,
    this.evidenceCandidate,
  }) : invocationId = invocationId.isEmpty ? executionId : invocationId,
       attemptId = attemptId.isEmpty ? executionId : attemptId,
       providerCallId = providerCallId.isEmpty ? callId : providerCallId,
       arguments = Map<String, Object?>.unmodifiable(arguments);

  /// Application-owned identity for one logical tool invocation.
  final String invocationId;

  /// Application-owned identity for this execution or duplicate attempt.
  final String attemptId;

  /// Provider-owned correlation value. It is never used as an audit identity.
  final String providerCallId;

  /// Compatibility alias for callers that still render an execution ID.
  String get executionId => attemptId;

  /// Compatibility alias for provider adapters and legacy projections.
  String get callId => providerCallId;
  final String name;
  final String title;
  final String mcpServerName;
  final ToolSource source;
  final ToolRiskLevel riskLevel;
  final ToolInvocationStatus status;
  final Map<String, Object?> arguments;
  final String resultSummary;
  final String errorCode;
  final String approvalDecision;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationMs;
  final ToolEvidenceCandidate? evidenceCandidate;

  ToolInvocationRecord copyWith({
    ToolInvocationStatus? status,
    String? resultSummary,
    String? errorCode,
    String? approvalDecision,
    DateTime? completedAt,
    int? durationMs,
    ToolEvidenceCandidate? evidenceCandidate,
  }) {
    return ToolInvocationRecord(
      invocationId: invocationId,
      attemptId: attemptId,
      providerCallId: providerCallId,
      name: name,
      title: title,
      mcpServerName: mcpServerName,
      source: source,
      riskLevel: riskLevel,
      status: status ?? this.status,
      arguments: arguments,
      resultSummary: resultSummary ?? this.resultSummary,
      errorCode: errorCode ?? this.errorCode,
      approvalDecision: approvalDecision ?? this.approvalDecision,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMs: durationMs ?? this.durationMs,
      evidenceCandidate: evidenceCandidate ?? this.evidenceCandidate,
    );
  }
}

/// A redacted, durable audit record for one tool execution in a chat run.
///
/// [attemptId] is stable while one attempt moves through requested, approval,
/// running, and a terminal state. Multiple attempts can share [invocationId],
/// while [providerCallId] is correlation metadata only. Raw tool arguments and
/// results are intentionally excluded from this model so credentials cannot
/// cross the persistence boundary.
final class ToolExecutionRecord {
  const ToolExecutionRecord({
    required this.executionId,
    this.invocationId = '',
    this.attemptId = '',
    this.providerCallId = '',
    required this.runId,
    required this.turnId,
    required this.messageId,
    required this.chatId,
    required this.botId,
    required this.callId,
    required this.name,
    this.title = '',
    this.mcpServerName = '',
    required this.source,
    required this.riskLevel,
    required this.status,
    this.detail = '',
    this.argumentsSummary = '',
    this.resultSummary = '',
    this.approvalStatus = '',
    this.errorCode = '',
    this.durationMs,
    required this.startedAt,
    this.completedAt,
    required this.updatedAt,
    this.eventSequence = 0,
    this.evidenceCandidate,
  });

  final String executionId;
  final String invocationId;
  final String attemptId;
  final String providerCallId;
  final String runId;
  final String turnId;
  final String messageId;
  final String chatId;
  final String botId;
  final String callId;
  final String name;
  final String title;
  final String mcpServerName;
  final ToolSource source;
  final ToolRiskLevel riskLevel;
  final ToolInvocationStatus status;
  final String detail;
  final String argumentsSummary;
  final String resultSummary;
  final String approvalStatus;
  final String errorCode;
  final int? durationMs;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  /// Monotonic lifecycle event number for this attempt.
  ///
  /// The current-state projection does not persist this value; the immutable
  /// event ledger uses it to derive an application-owned event identity.
  final int eventSequence;
  final ToolEvidenceCandidate? evidenceCandidate;
}
