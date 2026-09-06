import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/add_mcp_server_tool.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/mcp_credential_store.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';

void main() {
  late _MemoryMcpServerRepository repository;
  late _MemoryMcpCredentialStore credentials;
  late DateTime timestamp;

  setUp(() {
    repository = _MemoryMcpServerRepository();
    credentials = _MemoryMcpCredentialStore();
    timestamp = DateTime(2026, 8, 9, 18);
  });

  AddMcpServerTool createTool({McpServerConnector? connector}) =>
      AddMcpServerTool(
        repository: repository,
        credentialStore: credentials,
        connector:
            connector ??
            (serverId, cancellationToken) async {
              cancellationToken.throwIfCancelled();
              final server = (await repository.getServer(serverId))!;
              final connected = server.copyWith(
                status: McpConnectionStatus.connected,
                updatedAt: timestamp,
              );
              await repository.replaceCatalog(connected, [
                _tool(serverId, timestamp),
              ]);
              return connected;
            },
        now: () => timestamp,
        idFactory: (_) => 'mcp-generated',
      );

  test('requires approval and exposes both transport contracts', () {
    final tool = createTool();
    final definition = tool.definition;
    final call = ToolCallRequest(
      callId: 'add-policy',
      name: addMcpServerToolName,
      arguments: const {
        'name': 'Example',
        'transport_type': 'streamable_http',
        'endpoint': 'https://example.com/mcp',
      },
    );
    final context = ToolPolicyContext(
      runId: 'run-1',
      chatId: 'chat-1',
      botId: 'bot-1',
      requestedToolNames: addMcpServerToolNames,
    );

    expect(definition.riskLevel, ToolRiskLevel.write);
    expect(definition.capabilities, contains(ToolCapability.localWrite));
    expect(definition.capabilities, contains(ToolCapability.network));
    expect(definition.capabilities, contains(ToolCapability.process));
    expect(
      (definition.inputSchema['properties']! as Map<String, Object?>).keys,
      containsAll(<String>[
        'name',
        'transport_type',
        'endpoint',
        'auth_type',
        'access_token',
        'command',
        'arguments',
        'environment',
        'connect',
      ]),
    );
    expect(
      const DefaultToolPolicy().evaluate(definition, call, context).outcome,
      ToolPolicyOutcome.deny,
    );
    expect(
      const DefaultToolPolicy(
        allowProcessExecution: true,
      ).evaluate(definition, call, context).outcome,
      ToolPolicyOutcome.requireApproval,
    );
  });

  test('adds and connects an HTTPS server with a secure token', () async {
    final result = await createTool().execute(
      ToolCallRequest(
        callId: 'add-http',
        name: addMcpServerToolName,
        arguments: const {
          'name': 'Remote search',
          'transport_type': 'streamable_http',
          'endpoint': 'https://mcp.example.com/v1',
          'auth_type': 'oauth_access_token',
          'access_token': 'secret-token',
          'connect': true,
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isFalse);
    final server = (await repository.getServers()).single;
    expect(server.id, 'mcp-generated');
    expect(server.name, 'Remote search');
    expect(server.status, McpConnectionStatus.connected);
    final transport = server.transport as McpStreamableHttpServerTransport;
    expect(transport.endpoint, Uri.parse('https://mcp.example.com/v1'));
    expect(transport.authType, McpAuthType.oauthAccessToken);
    expect(credentials.values[server.id]?.accessToken, 'secret-token');
    expect(result.structuredContent, {
      'server_id': 'mcp-generated',
      'name': 'Remote search',
      'transport_type': 'streamable_http',
      'connection_status': 'connected',
      'tool_count': 1,
      'credential_stored': true,
    });
    expect(result.content, isNot(contains('secret-token')));
  });

  test('adds a disconnected stdio server with secure environment', () async {
    var connectorCalls = 0;
    final result = await createTool(
      connector: (serverId, cancellationToken) async {
        connectorCalls += 1;
        return (await repository.getServer(serverId))!;
      },
    ).execute(
      ToolCallRequest(
        callId: 'add-stdio',
        name: addMcpServerToolName,
        arguments: const {
          'name': 'Local files',
          'transport_type': 'stdio',
          'auth_type': 'none',
          'command': 'npx',
          'arguments': [
            '-y',
            '@modelcontextprotocol/server-filesystem',
            '/workspace',
          ],
          'environment': {'API_KEY': 'local-secret', 'MCP_MODE': 'read_only'},
          'connect': false,
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isFalse);
    expect(connectorCalls, 0);
    final server = (await repository.getServers()).single;
    final transport = server.transport as McpStdioServerTransport;
    expect(transport.command, 'npx');
    expect(transport.arguments, [
      '-y',
      '@modelcontextprotocol/server-filesystem',
      '/workspace',
    ]);
    expect(server.status, McpConnectionStatus.disconnected);
    expect(credentials.values[server.id]?.environment, {
      'API_KEY': 'local-secret',
      'MCP_MODE': 'read_only',
    });
  });

  test('refuses a duplicate name without overwriting the server', () async {
    final original = McpServer(
      id: 'existing',
      name: 'Remote Search',
      transport: McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://original.example.com/mcp'),
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await repository.saveServer(original);

    final result = await createTool().execute(
      ToolCallRequest(
        callId: 'duplicate',
        name: addMcpServerToolName,
        arguments: const {
          'name': ' remote search ',
          'transport_type': 'streamable_http',
          'endpoint': 'https://replacement.example.com/mcp',
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isTrue);
    expect(result.errorCode, 'mcp_server_already_exists');
    expect(await repository.getServers(), hasLength(1));
    expect(
      (await repository.getServer('existing'))?.transport,
      original.transport,
    );
  });

  test('rejects invalid stdio environment before persisting', () async {
    final result = await createTool().execute(
      ToolCallRequest(
        callId: 'bad-env',
        name: addMcpServerToolName,
        arguments: const {
          'name': 'Local',
          'transport_type': 'stdio',
          'command': 'npx',
          'environment': {'NOT VALID': 'secret'},
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isTrue);
    expect(result.errorCode, 'mcp_invalid_stdio_environment');
    expect(await repository.getServers(), isEmpty);
    expect(credentials.values, isEmpty);
  });

  test('rejects non-string credential values before persisting', () async {
    final result = await createTool().execute(
      ToolCallRequest(
        callId: 'bad-token',
        name: addMcpServerToolName,
        arguments: const {
          'name': 'Remote',
          'transport_type': 'streamable_http',
          'endpoint': 'https://remote.example.com/mcp',
          'auth_type': 'oauth_access_token',
          'access_token': 42,
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.errorCode, 'mcp_invalid_credential');
    expect(repository.servers, isEmpty);
    expect(credentials.values, isEmpty);
  });

  test('keeps an added server when immediate connection fails', () async {
    final result = await createTool(
      connector: (serverId, cancellationToken) async {
        final server = (await repository.getServer(serverId))!;
        await repository.saveServer(
          server.copyWith(
            status: McpConnectionStatus.error,
            lastErrorCode: 'mcp_dns_failed',
            updatedAt: timestamp,
          ),
        );
        throw const McpException('mcp_dns_failed');
      },
    ).execute(
      ToolCallRequest(
        callId: 'connection-failed',
        name: addMcpServerToolName,
        arguments: const {
          'name': 'Unavailable',
          'transport_type': 'streamable_http',
          'endpoint': 'https://unavailable.example.com/mcp',
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isFalse);
    expect(await repository.getServers(), hasLength(1));
    expect(
      result.structuredContent,
      containsPair('connection_error', 'mcp_dns_failed'),
    );
    expect(result.content, contains('remains configured'));
  });

  test('database save failure rolls back the secure credential', () async {
    repository.saveError = StateError('database save failed');

    final result = await createTool().execute(
      ToolCallRequest(
        callId: 'save-failed',
        name: addMcpServerToolName,
        arguments: const {
          'name': 'Save failure',
          'transport_type': 'streamable_http',
          'endpoint': 'https://save-failure.example.com/mcp',
          'auth_type': 'oauth_access_token',
          'access_token': 'secret-token',
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isTrue);
    expect(result.errorCode, 'mcp_server_add_failed');
    expect(repository.servers, isEmpty);
    expect(credentials.values, isEmpty);
  });

  test('credential failure never persists the database row', () async {
    credentials.writeError = StateError('secure storage write failed');

    final result = await createTool().execute(
      ToolCallRequest(
        callId: 'credential-failed',
        name: addMcpServerToolName,
        arguments: const {
          'name': 'Credential failure',
          'transport_type': 'streamable_http',
          'endpoint': 'https://credential-failure.example.com/mcp',
          'auth_type': 'oauth_access_token',
          'access_token': 'secret-token',
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isTrue);
    expect(result.errorCode, 'mcp_credential_store_failed');
    expect(repository.servers, isEmpty);
    expect(credentials.values, isEmpty);
  });

  test(
    'credential-free servers do not depend on secure-store cleanup',
    () async {
      credentials.deleteError = StateError('secure storage unavailable');

      final result = await createTool().execute(
        ToolCallRequest(
          callId: 'no-credential',
          name: addMcpServerToolName,
          arguments: const {
            'name': 'Public server',
            'transport_type': 'streamable_http',
            'endpoint': 'https://public.example.com/mcp',
            'connect': false,
          },
        ),
        AgentCancellationToken(),
      );

      expect(result.isError, isFalse);
      expect(credentials.deleteCalls, 0);
      expect(await repository.getServers(), hasLength(1));
    },
  );

  test('reports a retained server when post-connect reads fail', () async {
    final result = await createTool(
      connector: (serverId, cancellationToken) async {
        repository.getServerError = StateError('database read failed');
        repository.getToolsError = StateError('catalog read failed');
        throw const McpException('mcp_connection_failed');
      },
    ).execute(
      ToolCallRequest(
        callId: 'post-connect-read-failure',
        name: addMcpServerToolName,
        arguments: const {
          'name': 'Retained server',
          'transport_type': 'streamable_http',
          'endpoint': 'https://retained.example.com/mcp',
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isFalse);
    expect(
      result.structuredContent,
      containsPair('server_id', 'mcp-generated'),
    );
    expect(result.structuredContent, containsPair('tool_count', 0));
    expect(result.content, contains('remains configured'));
    expect(repository.servers, hasLength(1));
  });
}

McpToolDescriptor _tool(String serverId, DateTime timestamp) =>
    McpToolDescriptor(
      serverId: serverId,
      remoteName: 'search',
      title: 'Search',
      description: 'Search remote data.',
      inputSchema: const {'type': 'object'},
      updatedAt: timestamp,
    );

final class _MemoryMcpServerRepository implements McpServerRepository {
  final Map<String, McpServer> servers = {};
  final Map<String, List<McpToolDescriptor>> tools = {};
  Object? saveError;
  Object? getServerError;
  Object? getToolsError;

  @override
  Stream<List<McpServer>> get changes => const Stream.empty();

  @override
  Future<void> deleteServer(String id) async {
    servers.remove(id);
    tools.remove(id);
  }

  @override
  Future<McpServer?> getServer(String id) async {
    if (getServerError case final error?) throw error;
    return servers[id];
  }

  @override
  Future<List<McpServer>> getServers() async =>
      List<McpServer>.unmodifiable(servers.values);

  @override
  Future<List<McpToolDescriptor>> getTools(String serverId) async {
    if (getToolsError case final error?) throw error;
    return List<McpToolDescriptor>.unmodifiable(tools[serverId] ?? const []);
  }

  @override
  Future<void> replaceCatalog(
    McpServer server,
    List<McpToolDescriptor> tools,
  ) async {
    servers[server.id] = server;
    this.tools[server.id] = List<McpToolDescriptor>.of(tools);
  }

  @override
  Future<void> saveServer(McpServer server) async {
    if (saveError case final error?) throw error;
    servers[server.id] = server;
  }
}

final class _MemoryMcpCredentialStore implements McpCredentialStore {
  final Map<String, McpCredential> values = {};
  Object? writeError;
  Object? deleteError;
  int deleteCalls = 0;

  @override
  Future<void> delete(String serverId) async {
    deleteCalls += 1;
    if (deleteError case final error?) throw error;
    values.remove(serverId);
  }

  @override
  Future<McpCredential?> read(String serverId) async => values[serverId];

  @override
  Future<void> write(String serverId, McpCredential credential) async {
    if (writeError case final error?) throw error;
    values[serverId] = credential;
  }
}
