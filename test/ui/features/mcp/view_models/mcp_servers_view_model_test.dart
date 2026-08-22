import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/sqlite_mcp_server_repository.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/data/services/mcp/mcp_catalog_service.dart';
import 'package:stars/data/services/tools/add_mcp_server_tool.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/catalog_controller.dart';
import 'package:stars/domain/repositories/mcp_client.dart';
import 'package:stars/domain/repositories/mcp_credential_store.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/use_cases/mcp_server_mutations.dart';
import 'package:stars/ui/features/mcp/view_models/mcp_servers_view_model.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late SqliteMcpServerRepository repository;
  late _MemoryCredentialStore credentials;
  late DynamicToolRegistry registry;
  late _FakeMcpClient client;
  late McpServersViewModel viewModel;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onConfigure: DatabaseService.configure,
        onCreate: DatabaseService.createSchema,
      ),
    );
    repository = SqliteMcpServerRepository(
      localDatabase: LocalDatabaseService(
        databaseProvider: () async => database,
      ),
    );
    credentials = _MemoryCredentialStore();
    registry = DynamicToolRegistry(const []);
    client = _FakeMcpClient();
    final catalog = McpCatalogService(
      repository: repository,
      client: client,
      toolRegistry: registry,
    );
    viewModel = McpServersViewModel(
      repository: repository,
      catalogService: catalog,
      saveAndConnect: SaveAndConnectMcpServer(
        repository: repository,
        credentialStore: credentials,
        catalogController: catalog,
        now: () => DateTime(2026, 7, 29, 10),
      ),
      deleteServer: DeleteMcpServer(
        repository: repository,
        botRepository: const _EmptyBotRepository(),
        credentialStore: credentials,
        catalogController: catalog,
      ),
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await repository.dispose();
    await database.close();
  });

  test('persists and connects a new server', () async {
    final saved = await viewModel.saveAndConnect(
      const McpServerDraft(
        name: 'Example',
        endpoint: 'https://example.com/mcp',
        authType: McpAuthType.oauthAccessToken,
        accessToken: 'secret-token',
      ),
    );

    expect(saved, isTrue);
    expect(viewModel.servers, hasLength(1));
    final server = viewModel.servers.single;
    expect(server.status, McpConnectionStatus.connected);
    expect(credentials.values[server.id]?.accessToken, 'secret-token');
    expect(viewModel.toolsFor(server.id), hasLength(1));
  });

  test('publishes a server installed through the built-in MCP tool', () async {
    await viewModel.load();
    final serverPublished = Completer<void>();
    viewModel.addListener(() {
      if (!serverPublished.isCompleted &&
          viewModel.servers.any((server) => server.name == 'Installed MCP')) {
        serverPublished.complete();
      }
    });
    final installer = AddMcpServerTool(
      repository: repository,
      credentialStore: credentials,
      connector:
          (_, _) => throw StateError('Disconnected install must not connect.'),
      now: () => DateTime(2026, 8, 10, 12),
      idFactory: (_) => 'mcp-installed',
    );

    final result = await installer.execute(
      ToolCallRequest(
        callId: 'install-mcp',
        name: addMcpServerToolName,
        arguments: const {
          'name': 'Installed MCP',
          'transport_type': 'streamable_http',
          'endpoint': 'https://installed.example.com/mcp',
          'connect': false,
        },
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isFalse);
    await serverPublished.future.timeout(const Duration(seconds: 1));
    expect(viewModel.servers.single.id, 'mcp-installed');
  });

  test('publishes a new server before Tool discovery completes', () async {
    final discoveryStarted = Completer<void>();
    final continueDiscovery = Completer<void>();
    client.discoveryStarted = discoveryStarted;
    client.continueDiscovery = continueDiscovery;

    final save = viewModel.saveAndConnect(
      const McpServerDraft(
        name: 'Slow server',
        endpoint: 'https://example.com/slow-mcp',
      ),
    );
    await discoveryStarted.future;

    expect(viewModel.servers, hasLength(1));
    expect(viewModel.servers.single.name, 'Slow server');
    expect(viewModel.servers.single.status, McpConnectionStatus.disconnected);
    expect(viewModel.busyServerId, viewModel.servers.single.id);
    expect(viewModel.toolsFor(viewModel.servers.single.id), isEmpty);

    continueDiscovery.complete();
    expect(await save, isTrue);
    expect(viewModel.servers.single.status, McpConnectionStatus.connected);
  });

  test('a discovered Tool is available in the runtime registry', () async {
    await viewModel.saveAndConnect(
      const McpServerDraft(
        name: 'Example',
        endpoint: 'https://example.com/mcp',
        authType: McpAuthType.none,
      ),
    );
    final tool = viewModel.toolsFor(viewModel.servers.single.id).single;

    expect(registry.find(tool.canonicalName), isNotNull);
  });

  test('publishes immutable server and Tool snapshots', () async {
    final timestamp = DateTime(2026, 7, 29, 11);
    final firstServer = McpServer(
      id: 'first',
      name: 'First',
      transport: McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://example.com/first'),
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final firstTool = McpToolDescriptor(
      serverId: firstServer.id,
      remoteName: 'first_tool',
      title: 'First Tool',
      description: 'First tool.',
      inputSchema: const {'type': 'object'},
      updatedAt: timestamp,
    );
    final mutableRepository = _MutableMcpServerRepository(
      servers: [firstServer],
      toolsByServer: {
        firstServer.id: [firstTool],
      },
    );
    final catalog = _StubMcpCatalogController();
    final mutableViewModel = McpServersViewModel(
      repository: mutableRepository,
      catalogService: catalog,
      saveAndConnect: SaveAndConnectMcpServer(
        repository: mutableRepository,
        credentialStore: _MemoryCredentialStore(),
        catalogController: catalog,
      ),
      deleteServer: DeleteMcpServer(
        repository: mutableRepository,
        botRepository: const _EmptyBotRepository(),
        credentialStore: _MemoryCredentialStore(),
        catalogController: catalog,
      ),
    );
    addTearDown(mutableViewModel.dispose);
    await mutableViewModel.load();
    final serversSnapshot = mutableViewModel.servers;
    final toolsSnapshot = mutableViewModel.toolsFor(firstServer.id);

    expect(() => serversSnapshot.clear(), throwsUnsupportedError);
    expect(() => toolsSnapshot.clear(), throwsUnsupportedError);

    mutableRepository.servers.add(
      McpServer(
        id: 'second',
        name: 'Second',
        transport: McpStreamableHttpServerTransport(
          endpoint: Uri.parse('https://example.com/second'),
        ),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    mutableRepository.toolsByServer[firstServer.id]!.add(
      McpToolDescriptor(
        serverId: firstServer.id,
        remoteName: 'second_tool',
        title: 'Second Tool',
        description: 'Second tool.',
        inputSchema: const {'type': 'object'},
        updatedAt: timestamp,
      ),
    );

    expect(serversSnapshot, hasLength(1));
    expect(toolsSnapshot, hasLength(1));
    await mutableViewModel.load();
    expect(mutableViewModel.servers, hasLength(2));
    expect(mutableViewModel.toolsFor(firstServer.id), hasLength(2));
    expect(serversSnapshot, hasLength(1));
    expect(toolsSnapshot, hasLength(1));
  });

  test('a new server remains saved when remote discovery fails', () async {
    client.initializeError = const McpException('mcp_stdio_start_failed');

    final saved = await viewModel.saveAndConnect(
      const McpServerDraft(
        name: 'Local files',
        transportType: McpTransportType.stdio,
        command: 'missing-mcp-server',
      ),
    );

    expect(saved, isTrue);
    expect(viewModel.servers, hasLength(1));
    expect(viewModel.servers.single.status, McpConnectionStatus.error);
    expect(viewModel.error, isNull);
    expect(viewModel.warning?.code, 'mcp_stdio_start_failed');
  });

  test('saves stdio process settings and secure environment', () async {
    final saved = await viewModel.saveAndConnect(
      const McpServerDraft(
        name: 'Local files',
        transportType: McpTransportType.stdio,
        command: 'npx',
        arguments: '-y\n@modelcontextprotocol/server-filesystem\n/tmp',
        environment: 'API_KEY=local-secret\nMCP_MODE=read_only',
      ),
    );

    expect(saved, isTrue);
    final server = viewModel.servers.single;
    final transport = server.transport as McpStdioServerTransport;
    expect(transport.command, 'npx');
    expect(transport.arguments, [
      '-y',
      '@modelcontextprotocol/server-filesystem',
      '/tmp',
    ]);
    expect(credentials.values[server.id]?.environment, {
      'API_KEY': 'local-secret',
      'MCP_MODE': 'read_only',
    });
  });

  test('rejects malformed stdio environment variables', () async {
    final saved = await viewModel.saveAndConnect(
      const McpServerDraft(
        name: 'Local',
        transportType: McpTransportType.stdio,
        command: 'npx',
        environment: 'NOT VALID',
      ),
    );

    expect(saved, isFalse);
    expect(viewModel.error, isA<AppFailure>());
    expect(viewModel.error?.code, 'mcp_invalid_stdio_environment');
    expect(viewModel.servers, isEmpty);
  });

  test('restores the previous credential when database save fails', () async {
    const id = 'mcp-existing';
    final timestamp = DateTime(2026, 7, 29, 10);
    await repository.saveServer(
      McpServer(
        id: id,
        name: 'Existing',
        transport: McpStreamableHttpServerTransport(
          endpoint: Uri.parse('https://example.com/old'),
          authType: McpAuthType.oauthAccessToken,
        ),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await credentials.write(id, McpCredential(accessToken: 'old-secret'));
    await database.execute('''
      CREATE TRIGGER fail_mcp_update
      BEFORE UPDATE ON mcp_servers
      BEGIN
        SELECT RAISE(ABORT, 'injected MCP save failure');
      END
    ''');

    final saved = await viewModel.saveAndConnect(
      const McpServerDraft(
        id: id,
        name: 'Updated',
        endpoint: 'https://example.com/new',
        authType: McpAuthType.oauthAccessToken,
        accessToken: 'new-secret',
      ),
    );

    expect(saved, isFalse);
    expect(credentials.values[id]?.accessToken, 'old-secret');
    expect((await repository.getServer(id))?.name, 'Existing');
  });

  test('restores a credential when database deletion fails', () async {
    const id = 'mcp-delete';
    final timestamp = DateTime(2026, 7, 29, 10);
    final server = McpServer(
      id: id,
      name: 'Delete',
      transport: McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://example.com/delete'),
        authType: McpAuthType.oauthAccessToken,
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await repository.saveServer(server);
    await credentials.write(id, McpCredential(accessToken: 'keep-secret'));
    await database.execute('''
      CREATE TRIGGER fail_mcp_delete
      BEFORE DELETE ON mcp_servers
      BEGIN
        SELECT RAISE(ABORT, 'injected MCP delete failure');
      END
    ''');

    await viewModel.deleteServer(server);

    expect(viewModel.error?.code, 'mcp_delete_failed');
    expect(credentials.values[id]?.accessToken, 'keep-secret');
    expect(await repository.getServer(id), isNotNull);
  });

  test('credential write failure does not persist a server', () async {
    credentials.writeError = StateError('secure storage write failed');

    final saved = await viewModel.saveAndConnect(
      const McpServerDraft(
        name: 'Write failure',
        endpoint: 'https://example.com/write-failure',
        authType: McpAuthType.oauthAccessToken,
        accessToken: 'secret',
      ),
    );

    expect(saved, isFalse);
    expect(viewModel.error?.code, 'mcp_save_failed');
    expect(await repository.getServers(), isEmpty);
    expect(credentials.values, isEmpty);
  });

  test('credential delete failure preserves the server', () async {
    const id = 'mcp-credential-delete';
    final timestamp = DateTime(2026, 7, 29, 10);
    final server = McpServer(
      id: id,
      name: 'Credential delete failure',
      transport: McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://example.com/delete-failure'),
        authType: McpAuthType.oauthAccessToken,
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await repository.saveServer(server);
    await credentials.write(id, McpCredential(accessToken: 'keep-secret'));
    credentials.deleteError = StateError('secure storage delete failed');

    await viewModel.deleteServer(server);

    expect(viewModel.error?.code, 'mcp_delete_failed');
    expect(await repository.getServer(id), isNotNull);
    expect(credentials.values[id]?.accessToken, 'keep-secret');
  });

  test('credential read failure becomes presentation state', () async {
    credentials.readError = StateError('secure storage read failed');

    final saved = await viewModel.saveAndConnect(
      const McpServerDraft(
        name: 'Read failure',
        endpoint: 'https://example.com/read-failure',
      ),
    );

    expect(saved, isFalse);
    expect(viewModel.error?.code, 'mcp_credential_read_failed');
    expect(await repository.getServers(), isEmpty);
  });
}

final class _EmptyBotRepository implements BotRepository {
  const _EmptyBotRepository();

  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Bot operation is not used by this test.');
}

final class _MemoryCredentialStore implements McpCredentialStore {
  final Map<String, McpCredential> values = {};
  Object? readError;
  Object? writeError;
  Object? deleteError;

  @override
  Future<void> delete(String serverId) async {
    if (deleteError case final error?) throw error;
    values.remove(serverId);
  }

  @override
  Future<McpCredential?> read(String serverId) async {
    if (readError case final error?) throw error;
    return values[serverId];
  }

  @override
  Future<void> write(String serverId, McpCredential credential) async {
    if (writeError case final error?) throw error;
    values[serverId] = credential;
  }
}

final class _MutableMcpServerRepository implements McpServerRepository {
  _MutableMcpServerRepository({
    required this.servers,
    required this.toolsByServer,
  });

  final List<McpServer> servers;
  final Map<String, List<McpToolDescriptor>> toolsByServer;

  @override
  Stream<List<McpServer>> get changes => const Stream.empty();

  @override
  Future<List<McpServer>> getServers() async => servers;

  @override
  Future<List<McpToolDescriptor>> getTools(String serverId) async =>
      toolsByServer[serverId] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _StubMcpCatalogController implements McpCatalogController {
  @override
  McpStdioProcessInfo? getStdioProcessInfo(String serverId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeMcpClient implements McpClient {
  Object? initializeError;
  Completer<void>? discoveryStarted;
  Completer<void>? continueDiscovery;

  @override
  Future<McpServerCatalog> discoverTools(
    McpServer server, {
    AgentCancellationToken? cancellationToken,
  }) async {
    if (initializeError case final error?) throw error;
    discoveryStarted?.complete();
    if (continueDiscovery case final gate?) await gate.future;
    return McpServerCatalog(
      serverName: 'Remote Example',
      serverVersion: '1.0.0',
      capabilities: const McpServerCapabilities(tools: true),
      tools: [
        McpToolDescriptor(
          serverId: server.id,
          remoteName: 'search',
          title: 'Search',
          description: 'Search remote data.',
          inputSchema: const {'type': 'object'},
          annotations: const McpToolAnnotations(
            readOnlyHint: true,
            destructiveHint: false,
          ),
          updatedAt: DateTime(2026, 7, 29),
        ),
      ],
    );
  }

  @override
  Future<McpToolCallResult> callTool({
    required McpServer server,
    required String remoteName,
    required Map<String, Object?> arguments,
    required AgentCancellationToken cancellationToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> disconnect(McpServer server) async {}
}
