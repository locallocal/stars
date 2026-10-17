import 'dart:convert';

import 'package:stars/data/services/mcp/mcp_task_configuration.dart';
import 'package:stars/data/services/tools/add_mcp_server_tool.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';

/// Resolves credential-bearing user configuration only at the approved start.
/// Interrupted writes are never replayed without reconciliation.
final class McpTaskToolAdapter implements TaskToolAdapter {
  McpTaskToolAdapter(
    this.tool, {
    List<McpTaskConfiguration> configurations = const [],
  }) : _configurations = {
         for (final config in configurations) config.reference: config,
       };

  final AddMcpServerTool tool;
  final Map<String, McpTaskConfiguration> _configurations;

  @override
  late final definition = ToolDefinition(
    name: tool.definition.name,
    title: tool.definition.title,
    description:
        '${tool.definition.description} '
        'For user-supplied mcpServers JSON, copy the supplied safe connection '
        'fields and configuration_ref exactly. Stars resolves its credentials '
        'after approval. Never pass access_token or environment in task calls. '
        'Without a configuration_ref, only credential-free settings are supported.',
    inputSchema: {
      ...tool.definition.inputSchema,
      'properties': {
        for (final entry
            in (tool.definition.inputSchema['properties']!
                    as Map<String, Object?>)
                .entries)
          if (entry.key != 'access_token' && entry.key != 'environment')
            entry.key: entry.value,
        'configuration_ref': {'type': 'string', 'pattern': r'^[a-f0-9]{64}$'},
      },
    },
    outputSchema: tool.definition.outputSchema,
    source: tool.definition.source,
    riskLevel: tool.definition.riskLevel,
    capabilities: tool.definition.capabilities,
    toolVersion: 'mcp-task-v1',
  );

  @override
  Set<String> get checkpointArgumentNames => const {
    'name',
    'transport_type',
    'endpoint',
    'auth_type',
    'command',
    'arguments',
    'connect',
    'configuration_ref',
  };

  @override
  bool get guaranteesIdempotency => false;

  @override
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String idempotencyKey,
    AgentCancellationToken cancellation,
  ) async {
    cancellation.throwIfCancelled();
    if (const JsonSchemaValidator()
        .validate(call.arguments, definition.inputSchema)
        .isNotEmpty) {
      return _error(
        call,
        'invalid_mcp_server',
        'Invalid MCP installation fields.',
      );
    }
    final arguments = Map<String, Object?>.of(call.arguments);
    final reference = arguments.remove('configuration_ref');
    if (reference != null) {
      final config = _configurations[reference];
      if (config == null) {
        return _error(
          call,
          'mcp_configuration_unavailable',
          'The accepted user configuration is unavailable. Supply it in a new request.',
        );
      }
      final expected = Map<String, Object?>.of(config.safeArguments)
        ..remove('configuration_ref');
      final supplied = Map<String, Object?>.of(arguments)..remove('connect');
      if (expected.length != supplied.length ||
          expected.entries.any(
            (entry) =>
                jsonEncode(supplied[entry.key]) != jsonEncode(entry.value),
          )) {
        return _error(
          call,
          'mcp_configuration_mismatch',
          'Connection settings must exactly match the referenced user configuration.',
        );
      }
      if (config.errorCode case final code?) {
        return _error(
          call,
          code,
          'This MCP configuration contains unsupported transport settings or headers.',
        );
      }
      arguments.addAll(config.arguments);
    }
    return ToolCompleted(
      await tool.execute(
        ToolCallRequest(
          callId: call.callId,
          name: call.name,
          arguments: arguments,
        ),
        cancellation,
      ),
    );
  }

  ToolCompleted _error(ToolCallRequest call, String code, String message) =>
      ToolCompleted(
        ToolResult(
          callId: call.callId,
          name: call.name,
          content: message,
          isError: true,
          errorCode: code,
        ),
      );

  @override
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken cancellation,
  ) => Future.error(StateError('MCP installation has no external job.'));

  @override
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken cancellation,
  ) async => const ToolOutcomeUnknown();

  @override
  Future<ToolReconciliation> reconcile(
    ToolCallRequest call,
    String idempotencyKey,
    TaskExternalJob? job,
    AgentCancellationToken cancellation,
  ) async => const ToolOutcomeUnknown();
}
