import 'dart:async';
import 'dart:convert';

import 'package:stars/domain/models/mcp_installer.dart';
import 'package:stars/domain/models/skill_installer.dart';

part 'tool_json_schema_validator.dart';

enum ToolSource { builtIn, mcp, skillScript }

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
  }) : inputSchema = Map<String, Object?>.unmodifiable(inputSchema),
       outputSchema =
           outputSchema == null
               ? null
               : Map<String, Object?>.unmodifiable(outputSchema),
       capabilities = Set<ToolCapability>.unmodifiable(capabilities) {
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
    this.structuredContent,
    this.isError = false,
    this.errorCode = '',
    this.source = ToolSource.builtIn,
    this.truncated = false,
  });

  final String callId;
  final String name;
  final String content;
  final Object? structuredContent;
  final bool isError;
  final String errorCode;
  final ToolSource source;
  final bool truncated;

  ToolResult copyWith({
    String? content,
    Object? structuredContent,
    bool clearStructuredContent = false,
    bool? isError,
    String? errorCode,
    ToolSource? source,
    bool? truncated,
  }) {
    return ToolResult(
      callId: callId,
      name: name,
      content: content ?? this.content,
      structuredContent:
          clearStructuredContent
              ? null
              : structuredContent ?? this.structuredContent,
      isError: isError ?? this.isError,
      errorCode: errorCode ?? this.errorCode,
      source: source ?? this.source,
      truncated: truncated ?? this.truncated,
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
    'version': 1,
    'evidence_id': result.callId,
    'call_id': result.callId,
    'tool_name': result.name,
    'source': result.source.name,
    'status': result.isError ? 'error' : 'success',
    'error_code': result.errorCode,
    'truncated': result.truncated,
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
  duplicate,
}

final class ToolInvocationRecord {
  ToolInvocationRecord({
    required this.callId,
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
  }) : arguments = Map<String, Object?>.unmodifiable(arguments);

  final String callId;
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

  ToolInvocationRecord copyWith({
    ToolInvocationStatus? status,
    String? resultSummary,
    String? errorCode,
    String? approvalDecision,
    DateTime? completedAt,
    int? durationMs,
  }) {
    return ToolInvocationRecord(
      callId: callId,
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
    );
  }
}
