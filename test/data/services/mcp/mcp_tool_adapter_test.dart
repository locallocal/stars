import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/mcp/mcp_tool_adapter.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/mcp_client.dart';

void main() {
  test('maps untrusted MCP annotations to local risk and capabilities', () {
    final adapter = McpToolAdapter(
      server: _server(),
      descriptor: _tool(
        annotations: const McpToolAnnotations(
          readOnlyHint: true,
          destructiveHint: false,
          openWorldHint: false,
        ),
      ),
      client: _FakeMcpClient(),
    );

    expect(adapter.definition.name, 'mcp.server-1.search');
    expect(adapter.definition.title, 'Search');
    expect(adapter.definition.mcpServerName, 'Example');
    expect(adapter.definition.source, ToolSource.mcp);
    expect(adapter.definition.producesEvidence, isFalse);
    expect(adapter.definition.riskLevel, ToolRiskLevel.readOnly);
    expect(
      adapter.definition.capabilities,
      containsAll(<ToolCapability>[
        ToolCapability.network,
        ToolCapability.externalRead,
      ]),
    );
  });

  test('validates MCP structured output against outputSchema', () async {
    final client =
        _FakeMcpClient()
          ..callResult = const McpToolCallResult(
            content: '',
            structuredContent: {'count': 'not-an-integer'},
          );
    final adapter = McpToolAdapter(
      server: _server(),
      descriptor: _tool(
        outputSchema: const {
          'type': 'object',
          'properties': {
            'count': {'type': 'integer'},
          },
          'required': ['count'],
        },
      ),
      client: client,
    );

    final result = await adapter.execute(
      ToolCallRequest(callId: 'call-1', name: adapter.definition.name),
      AgentCancellationToken(),
    );

    expect(result.isError, isTrue);
    expect(result.errorCode, 'mcp_output_schema_validation_failed');
    expect(result.schemaValid, isFalse);
    expect(result.source, ToolSource.mcp);
  });

  test('preserves validated MCP result reliability metadata', () async {
    final observedAt = DateTime.utc(2026, 9, 4, 10);
    final client =
        _FakeMcpClient()
          ..callResult = const McpToolCallResult(
            content: '',
            structuredContent: {'count': 2},
          );
    final adapter = McpToolAdapter(
      server: _server(),
      descriptor: _tool(
        outputSchema: const {
          'type': 'object',
          'properties': {
            'count': {'type': 'integer'},
          },
          'required': ['count'],
        },
      ),
      client: client,
      now: () => observedAt,
    );

    final result = await adapter.execute(
      ToolCallRequest(callId: 'call-1', name: adapter.definition.name),
      AgentCancellationToken(),
    );

    expect(result.isError, isFalse);
    expect(result.schemaValid, isTrue);
    expect(result.source, ToolSource.mcp);
    expect(result.observedAt, observedAt);
    expect(result.resultDigest, hasLength(64));
    expect(result.evidenceKind, isNull);
  });

  test('returns sanitized MCP failures to the Agent Loop', () async {
    final client =
        _FakeMcpClient()
          ..error = const McpException(
            'mcp_authorization_required',
            message: 'server response with sensitive detail',
          );
    final adapter = McpToolAdapter(
      server: _server(),
      descriptor: _tool(),
      client: client,
    );

    final result = await adapter.execute(
      ToolCallRequest(callId: 'call-1', name: adapter.definition.name),
      AgentCancellationToken(),
    );

    expect(result.isError, isTrue);
    expect(result.errorCode, 'mcp_authorization_required');
    expect(result.content, isNot(contains('sensitive detail')));
  });

  test('rechecks Tool availability immediately before execution', () async {
    final client = _FakeMcpClient();
    final adapter = McpToolAdapter(
      server: _server(),
      descriptor: _tool(),
      client: client,
      availabilityCheck: () async => false,
    );

    final result = await adapter.execute(
      ToolCallRequest(callId: 'call-1', name: adapter.definition.name),
      AgentCancellationToken(),
    );

    expect(result.errorCode, 'mcp_tool_unavailable');
    expect(client.callCount, 0);
  });

  test('destructive MCP Tools require explicit approval when enabled', () {
    final definition =
        McpToolAdapter(
          server: _server(),
          descriptor: _tool(
            annotations: const McpToolAnnotations(destructiveHint: true),
          ),
          client: _FakeMcpClient(),
        ).definition;
    final decision = const DefaultToolPolicy(
      allowDestructiveWithApproval: true,
    ).evaluate(
      definition,
      ToolCallRequest(callId: 'call-1', name: definition.name),
      ToolPolicyContext(
        runId: 'run-1',
        chatId: 'chat-1',
        botId: 'bot-1',
        requestedToolNames: {definition.name},
      ),
    );

    expect(decision.outcome, ToolPolicyOutcome.requireApproval);
    expect(decision.reason, 'destructive_write_requires_approval');
  });
}

McpServer _server() {
  final timestamp = DateTime(2026, 7, 29);
  return McpServer(
    id: 'server-1',
    name: 'Example',
    transport: McpStreamableHttpServerTransport(
      endpoint: Uri.parse('https://example.com/mcp'),
    ),
    status: McpConnectionStatus.connected,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

McpToolDescriptor _tool({
  McpToolAnnotations annotations = const McpToolAnnotations(
    readOnlyHint: true,
    destructiveHint: false,
  ),
  Map<String, Object?>? outputSchema,
}) {
  return McpToolDescriptor(
    serverId: 'server-1',
    remoteName: 'search',
    title: 'Search',
    description: 'Search remote records.',
    inputSchema: const {'type': 'object'},
    outputSchema: outputSchema,
    annotations: annotations,
    updatedAt: DateTime(2026, 7, 29),
  );
}

final class _FakeMcpClient implements McpClient {
  McpToolCallResult callResult = const McpToolCallResult(content: 'ok');
  McpException? error;
  int callCount = 0;

  @override
  Future<McpToolCallResult> callTool({
    required McpServer server,
    required String remoteName,
    required Map<String, Object?> arguments,
    required AgentCancellationToken cancellationToken,
  }) async {
    callCount += 1;
    final failure = error;
    if (failure != null) throw failure;
    return callResult;
  }

  @override
  Future<void> disconnect(McpServer server) async {}

  @override
  Future<McpServerCatalog> discoverTools(
    McpServer server, {
    AgentCancellationToken? cancellationToken,
  }) {
    throw UnimplementedError();
  }
}
