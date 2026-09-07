import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  test('MCP Tool canonical names are stable and server scoped', () {
    expect(
      McpToolDescriptor.canonicalNameFor('github', 'create_issue'),
      'mcp.github.create_issue',
    );
    final first = McpToolDescriptor.canonicalNameFor(
      'docs',
      'search documents/v2',
    );
    final second = McpToolDescriptor.canonicalNameFor(
      'docs',
      'search documents/v2',
    );

    expect(first, second);
    expect(first, startsWith('mcp.docs.search_documents_v2_'));
    expect(first, isNot(contains(' ')));
    expect(
      McpToolDescriptor.canonicalNameFor('server-1', 'search'),
      isNot(McpToolDescriptor.canonicalNameFor('server-2', 'search')),
    );
  });

  test('MCP server rejects invalid ids', () {
    expect(
      () => McpServer(
        id: 'not valid',
        name: 'Example',
        transport: McpStreamableHttpServerTransport(
          endpoint: Uri.parse('https://example.com/mcp'),
        ),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      throwsArgumentError,
    );
  });

  test('stdio MCP servers require a command and copy their arguments', () {
    final timestamp = DateTime(2026);
    expect(
      () => McpServer(
        id: 'stdio-1',
        name: 'Local',
        transport: McpStdioServerTransport(command: ''),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      throwsArgumentError,
    );

    final arguments = <String>['-y', 'example-server'];
    final server = McpServer(
      id: 'stdio-1',
      name: 'Local',
      transport: McpStdioServerTransport(command: 'npx', arguments: arguments),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    arguments.add('--mutated');

    final transport = server.transport as McpStdioServerTransport;
    expect(transport.arguments, ['-y', 'example-server']);
    expect(() => transport.arguments.add('blocked'), throwsUnsupportedError);
  });

  test('MCP tools fail closed when the client cannot execute them', () {
    final descriptor = McpToolDescriptor(
      serverId: 'server-1',
      remoteName: 'search',
      title: 'Search',
      description: 'Search.',
      inputSchema: const {
        'type': 'object',
        'properties': {
          'query': {r'$ref': r'#/$defs/query'},
        },
        r'$defs': {
          'query': {'type': 'string'},
        },
      },
      updatedAt: DateTime(2026),
    );

    expect(descriptor.isSupportedByClient, isFalse);
  });

  test('MCP tools accept FastMCP wrapped output schemas', () {
    final descriptor = McpToolDescriptor(
      serverId: 'basic-memory',
      remoteName: 'write_note',
      title: 'Write Note',
      description: 'Write a note.',
      inputSchema: const {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
        },
        'required': ['title'],
        'additionalProperties': false,
      },
      outputSchema: const {
        'type': 'object',
        'properties': {
          'result': {
            'anyOf': [
              {'type': 'object', 'additionalProperties': true},
              {'type': 'string'},
            ],
          },
        },
        'required': ['result'],
        'x-fastmcp-wrap-result': true,
      },
      updatedAt: DateTime(2026),
    );

    expect(descriptor.isSupportedByClient, isTrue);
    expect(
      const JsonSchemaValidator().validate(const {
        'result': 'created',
      }, descriptor.outputSchema!),
      isEmpty,
    );
  });

  test('task-required MCP Tools stay out of the direct execution registry', () {
    final descriptor = McpToolDescriptor(
      serverId: 'server-1',
      remoteName: 'long_running',
      title: 'Long running',
      description: 'Requires the MCP task protocol.',
      inputSchema: const {'type': 'object'},
      taskSupport: McpToolTaskSupport.required,
      updatedAt: DateTime(2026),
    );

    expect(descriptor.isSupportedByClient, isFalse);
  });

  test('MCP Tool configuration is strict and round-trips approval policy', () {
    final configuration = McpToolConfiguration(
      serverId: 'server-1',
      remoteName: 'search',
      requiresApproval: false,
    );

    expect(McpToolConfiguration.fromMap(configuration.toMap()), configuration);
    expect(
      () => McpToolConfiguration.fromMap(const {
        'server_id': 'server-1',
        'remote_name': 'search',
      }),
      throwsFormatException,
    );
  });

  test('Dynamic Tool registry atomically replaces remote Tools', () {
    final fixed = _FakeTool('calculate');
    final registry = DynamicToolRegistry([fixed]);
    registry.replaceDynamic([_FakeTool('mcp.docs.search')]);

    expect(registry.list().map((definition) => definition.name), [
      'calculate',
      'mcp.docs.search',
    ]);
    expect(registry.find('mcp.docs.search'), isNotNull);

    registry.replaceDynamic([_FakeTool('mcp.github.issue')]);
    expect(registry.find('mcp.docs.search'), isNull);
    expect(registry.find('mcp.github.issue'), isNotNull);
    expect(
      () => registry.replaceDynamic([_FakeTool('calculate')]),
      throwsArgumentError,
    );
  });

  test('Dynamic Tool registry keeps independent capability sources', () {
    final registry = DynamicToolRegistry([_FakeTool('calculate')]);
    registry.replaceDynamicSource('mcp', [_FakeTool('mcp.docs.search')]);
    registry.replaceDynamicSource('skill-scripts', [
      _FakeTool('skill.example.transform'),
    ]);

    registry.replaceDynamicSource('mcp', [_FakeTool('mcp.github.issue')]);

    expect(registry.find('mcp.docs.search'), isNull);
    expect(registry.find('mcp.github.issue'), isNotNull);
    expect(registry.find('skill.example.transform'), isNotNull);
  });

  test('Skill script tools remain approval-gated when enabled', () {
    final definition = ToolDefinition(
      name: 'skill.example.transform',
      description: 'Transform input.',
      inputSchema: const {'type': 'object'},
      source: ToolSource.skillScript,
      riskLevel: ToolRiskLevel.readOnly,
      capabilities: const {ToolCapability.compute, ToolCapability.process},
    );
    final call = ToolCallRequest(callId: 'call-1', name: definition.name);
    final context = ToolPolicyContext(
      runId: 'run-1',
      chatId: 'chat-1',
      botId: 'bot-1',
      requestedToolNames: {definition.name},
    );

    expect(
      const DefaultToolPolicy().evaluate(definition, call, context).outcome,
      ToolPolicyOutcome.deny,
    );
    final enabled = const DefaultToolPolicy(
      allowSkillScripts: true,
    ).evaluate(definition, call, context);
    expect(enabled.outcome, ToolPolicyOutcome.requireApproval);
    expect(enabled.reason, 'skill_script_requires_approval');

    final approvalExempt = const DefaultToolPolicy(
      allowSkillScripts: true,
    ).evaluate(
      definition,
      call,
      ToolPolicyContext(
        runId: 'run-1',
        chatId: 'chat-1',
        botId: 'bot-1',
        requestedToolNames: {definition.name},
        approvalExemptToolNames: {definition.name},
      ),
    );
    expect(approvalExempt.outcome, ToolPolicyOutcome.allow);
    expect(approvalExempt.reason, 'bot_skill_tool_approval_exempt');
  });

  test('an explicitly exempt MCP Tool bypasses approval', () {
    final definition = ToolDefinition(
      name: 'mcp.example.write',
      description: 'Write remotely.',
      inputSchema: const {'type': 'object'},
      source: ToolSource.mcp,
      riskLevel: ToolRiskLevel.destructive,
      capabilities: const {
        ToolCapability.network,
        ToolCapability.externalWrite,
      },
    );
    final decision = const DefaultToolPolicy().evaluate(
      definition,
      ToolCallRequest(callId: 'call-1', name: definition.name),
      ToolPolicyContext(
        runId: 'run-1',
        chatId: 'chat-1',
        botId: 'bot-1',
        requestedToolNames: {definition.name},
        approvalExemptToolNames: {definition.name},
      ),
    );

    expect(decision.outcome, ToolPolicyOutcome.allow);
    expect(decision.reason, 'bot_mcp_tool_approval_exempt');
  });
}

final class _FakeTool implements ExecutableTool {
  _FakeTool(String name)
    : definition = ToolDefinition(
        name: name,
        description: name,
        inputSchema: const {'type': 'object'},
        source: ToolSource.builtIn,
        riskLevel: ToolRiskLevel.readOnly,
        capabilities: const {ToolCapability.compute},
      );

  @override
  final ToolDefinition definition;

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    return ToolResult(callId: call.callId, name: call.name, content: 'ok');
  }
}
