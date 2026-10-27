import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/services/mcp/mcp_client_service.dart';
import 'package:stars/data/services/mcp/mcp_endpoint_policy.dart';
import 'package:stars/data/services/mcp/mcp_http_transport.dart';
import 'package:stars/data/services/mcp/mcp_stdio_transport.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/mcp_credential_store.dart';

void main() {
  test(
    'negotiates a session, paginates Tool discovery, and calls a Tool',
    () async {
      final requests = <http.Request>[];
      Future<http.Response> handler(http.Request request) async {
        requests.add(request);
        final payload =
            request.body.isEmpty
                ? const <String, Object?>{}
                : (jsonDecode(request.body) as Map<String, dynamic>);
        switch (payload['method']) {
          case 'initialize':
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': payload['id'],
                'result': {
                  'protocolVersion': '2025-11-25',
                  'capabilities': {
                    'tools': {'listChanged': true},
                  },
                  'serverInfo': {'name': 'Example MCP', 'version': '2.1.0'},
                },
              }),
              200,
              headers: {
                'content-type': 'application/json',
                'mcp-session-id': 'session-123',
              },
            );
          case 'notifications/initialized':
            return http.Response('', 202);
          case 'tools/list':
            final params = payload['params'] as Map<String, dynamic>;
            final secondPage = params['cursor'] == 'page-2';
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': payload['id'],
                'result': {
                  'tools': [
                    {
                      'name': secondPage ? 'create_note' : 'search_notes',
                      if (secondPage) 'title': 'Create note',
                      'description': 'Example Tool',
                      'inputSchema': {
                        'type': 'object',
                        'properties': {
                          'query': {'type': 'string'},
                        },
                      },
                      'annotations': {
                        if (!secondPage) 'title': 'Search notes',
                        'readOnlyHint': !secondPage,
                        'destructiveHint': secondPage,
                      },
                      'execution': {
                        'taskSupport': secondPage ? 'required' : 'optional',
                      },
                    },
                  ],
                  if (!secondPage) 'nextCursor': 'page-2',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          case 'tools/call':
            return http.Response(
              'event: endpoint\n'
              'id: prime-1\n'
              'data:\n\n'
              'event: message\n'
              'data: ${jsonEncode({
                'jsonrpc': '2.0',
                'method': 'notifications/progress',
                'params': {'progress': 0.5},
              })}\n\n'
              'event: message\n'
              'data: ${jsonEncode({
                'jsonrpc': '2.0',
                'id': payload['id'],
                'result': {
                  'content': [
                    {'type': 'text', 'text': 'Found 2 notes'},
                    {'type': 'image', 'mimeType': 'image/png', 'data': 'not-forwarded'},
                  ],
                  'structuredContent': {'count': 2},
                },
              })}\n\n',
              200,
              headers: {'content-type': 'text/event-stream'},
            );
        }
        return http.Response('not found', 404);
      }

      final credentials =
          _MemoryCredentialStore()
            ..value = McpCredential(accessToken: 'secret-token');
      final client = McpClientService(
        transports: [
          McpHttpTransport(
            endpointPolicy: McpEndpointPolicy(
              resolver: (_) async => [InternetAddress('8.8.8.8')],
            ),
            clientFactory: () => MockClient(handler),
          ),
          McpStdioTransport(),
        ],
        credentialStore: credentials,
      );
      final server = _server();

      final tools = (await client.discoverTools(server)).tools;

      expect(tools.map((tool) => tool.remoteName), [
        'search_notes',
        'create_note',
      ]);
      expect(tools.first.annotations.readOnlyHint, isTrue);
      expect(tools.first.title, 'Search notes');
      expect(tools.last.annotations.destructiveHint, isTrue);
      expect(tools.last.taskSupport, McpToolTaskSupport.required);
      expect(tools.last.isSupportedByClient, isFalse);
      expect(
        requests
            .skip(1)
            .every(
              (request) => request.headers['Mcp-Session-Id'] == 'session-123',
            ),
        isTrue,
      );
      expect(
        requests.every(
          (request) =>
              request.headers['Authorization'] == 'Bearer secret-token',
        ),
        isTrue,
      );

      final result = await client.callTool(
        server: server,
        remoteName: 'search_notes',
        arguments: const {'query': 'release'},
        cancellationToken: AgentCancellationToken(),
      );

      expect(result.content, contains('Found 2 notes'));
      expect(result.content, contains('[Image content: image/png]'));
      expect(result.content, isNot(contains('not-forwarded')));
      expect(result.structuredContent, {'count': 2});
      expect(requests.last.headers['MCP-Protocol-Version'], '2025-11-25');
    },
  );

  test('rejects protocol revisions other than the current contract', () async {
    final client = McpClientService(
      transports: [
        McpHttpTransport(
          endpointPolicy: McpEndpointPolicy(
            resolver: (_) async => [InternetAddress('8.8.8.8')],
          ),
          clientFactory:
              () => MockClient((request) async {
                final payload =
                    jsonDecode(request.body) as Map<String, dynamic>;
                return http.Response(
                  jsonEncode({
                    'jsonrpc': '2.0',
                    'id': payload['id'],
                    'result': {
                      'protocolVersion': '2025-06-18',
                      'capabilities': <String, Object?>{},
                      'serverInfo': {'name': 'Old MCP', 'version': '1.0.0'},
                    },
                  }),
                  200,
                  headers: {'content-type': 'application/json'},
                );
              }),
        ),
        McpStdioTransport(),
      ],
      credentialStore:
          _MemoryCredentialStore()
            ..value = McpCredential(accessToken: 'secret-token'),
    );

    await expectLater(
      client.discoverTools(_server()),
      throwsA(
        isA<McpException>().having(
          (error) => error.code,
          'code',
          'mcp_unsupported_protocol',
        ),
      ),
    );
  });

  test('reinitializes once when an HTTP session expires', () async {
    var initializeCount = 0;
    var toolCallCount = 0;
    Future<http.Response> handler(http.Request request) async {
      if (request.method == 'DELETE') return http.Response('', 404);
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      switch (payload['method']) {
        case 'initialize':
          initializeCount += 1;
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': payload['id'],
              'result': {
                'protocolVersion': '2025-11-25',
                'capabilities': {'tools': <String, Object?>{}},
                'serverInfo': {'name': 'Session MCP', 'version': '1.0.0'},
              },
            }),
            200,
            headers: {
              'content-type': 'application/json',
              'mcp-session-id': 'session-$initializeCount',
            },
          );
        case 'notifications/initialized':
          return http.Response('', 202);
        case 'tools/list':
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': payload['id'],
              'result': {'tools': <Object?>[]},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        case 'tools/call':
          toolCallCount += 1;
          if (toolCallCount == 1) return http.Response('', 404);
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': payload['id'],
              'result': {
                'content': [
                  {'type': 'text', 'text': 'recovered'},
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
      }
      return http.Response('', 500);
    }

    final client = McpClientService(
      transports: [
        McpHttpTransport(
          endpointPolicy: McpEndpointPolicy(
            resolver: (_) async => [InternetAddress('8.8.8.8')],
          ),
          clientFactory: () => MockClient(handler),
        ),
        McpStdioTransport(),
      ],
      credentialStore:
          _MemoryCredentialStore()
            ..value = McpCredential(accessToken: 'secret-token'),
    );
    final server = _server();
    await client.discoverTools(server);

    final result = await client.callTool(
      server: server,
      remoteName: 'recover',
      arguments: const {},
      cancellationToken: AgentCancellationToken(),
    );

    expect(result.content, 'recovered');
    expect(initializeCount, 2);
    expect(toolCallCount, 2);
  });

  test('surfaces OAuth metadata without including credential values', () async {
    final credentials =
        _MemoryCredentialStore()
          ..value = McpCredential(accessToken: 'do-not-leak');
    final client = McpClientService(
      transports: [
        McpHttpTransport(
          endpointPolicy: McpEndpointPolicy(
            resolver: (_) async => [InternetAddress('8.8.8.8')],
          ),
          clientFactory:
              () => MockClient(
                (_) async => http.Response(
                  '',
                  401,
                  headers: {
                    'www-authenticate':
                        'Bearer resource_metadata="https://auth.example.com/.well-known/oauth-protected-resource"',
                  },
                ),
              ),
        ),
        McpStdioTransport(),
      ],
      credentialStore: credentials,
    );

    Object? caught;
    try {
      await client.discoverTools(_server());
    } on Object catch (error) {
      caught = error;
    }

    expect(caught, isA<McpException>());
    final error = caught! as McpException;
    expect(error.code, 'mcp_authorization_required');
    expect(
      error.authorizationMetadataUri,
      Uri.parse(
        'https://auth.example.com/.well-known/oauth-protected-resource',
      ),
    );
    expect(error.toString(), isNot(contains('do-not-leak')));
  });

  test(
    'initializes, calls, and disconnects a local stdio MCP process',
    () async {
      final credentials =
          _MemoryCredentialStore()
            ..value = McpCredential(
              environment: {'STARS_MCP_TEST_VALUE': 'secure-environment'},
            );
      final processStartedAt = DateTime.utc(2026, 7, 30, 9, 45);
      final stdioTransport = McpStdioTransport(
        requestTimeout: const Duration(seconds: 10),
        now: () => processStartedAt,
        parentEnvironment: {
          ...Platform.environment,
          'OPENAI_API_KEY': 'must-not-be-inherited',
          'STARS_MCP_TEST_VALUE': 'must-be-overridden',
        },
      );
      final client = McpClientService(
        transports: [
          McpHttpTransport(
            endpointPolicy: McpEndpointPolicy(
              resolver: (_) async => [InternetAddress('8.8.8.8')],
            ),
          ),
          stdioTransport,
        ],
        credentialStore: credentials,
      );
      final timestamp = DateTime(2026, 7, 30);
      final server = McpServer(
        id: 'stdio-server',
        name: 'Fixture',
        transport: McpStdioServerTransport(
          command: 'dart',
          arguments: const [
            'test/fixtures/mcp_stdio_server.dart',
            'fixture-argument',
          ],
        ),
        createdAt: timestamp,
        updatedAt: timestamp,
      );
      addTearDown(() => client.disconnect(server));

      final tools = (await client.discoverTools(server)).tools;
      final result = await client.callTool(
        server: server,
        remoteName: 'echo',
        arguments: const {'message': 'hello', 'inspect_environment': true},
        cancellationToken: AgentCancellationToken(),
      );

      expect(tools.single.remoteName, 'echo');
      expect(result.content, 'hello|secure-environment|fixture-argument');
      final environment =
          (result.structuredContent!['environment']! as Map)
              .cast<String, Object?>();
      expect(environment, isNot(contains('OPENAI_API_KEY')));
      expect(environment['STARS_MCP_TEST_VALUE'], 'secure-environment');
      for (final key in [
        'AWS_SECRET_ACCESS_KEY',
        'GITHUB_TOKEN',
        'NODE_OPTIONS',
        'LD_PRELOAD',
      ]) {
        expect(environment, isNot(contains(key)));
      }
      final processInfo = stdioTransport.getProcessInfo(server.id);
      expect(processInfo, isNotNull);
      expect(processInfo!.processId, greaterThan(0));
      expect(processInfo.command, 'dart');
      expect(processInfo.arguments, [
        'test/fixtures/mcp_stdio_server.dart',
        'fixture-argument',
      ]);
      expect(processInfo.environmentVariableCount, 1);
      expect(processInfo.startedAt, processStartedAt);
      await client.disconnect(server);
      expect(stdioTransport.getProcessInfo(server.id), isNull);
    },
  );
}

McpServer _server() {
  final timestamp = DateTime(2026, 7, 29);
  return McpServer(
    id: 'server-1',
    name: 'Example',
    transport: McpStreamableHttpServerTransport(
      endpoint: Uri.parse('https://mcp.example.com/mcp'),
      authType: McpAuthType.oauthAccessToken,
    ),
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

final class _MemoryCredentialStore implements McpCredentialStore {
  McpCredential? value;

  @override
  Future<void> delete(String serverId) async => value = null;

  @override
  Future<McpCredential?> read(String serverId) async => value;

  @override
  Future<void> write(String serverId, McpCredential credential) async {
    value = credential;
  }
}
