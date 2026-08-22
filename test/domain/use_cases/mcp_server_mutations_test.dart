import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/catalog_controller.dart';
import 'package:stars/domain/repositories/mcp_credential_store.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/use_cases/mcp_server_mutations.dart';

void main() {
  late _MemoryMcpServerRepository repository;
  late _MemoryMcpCredentialStore credentials;
  late _MemoryBotRepository bots;
  late _FakeMcpCatalogController catalog;
  late SaveAndConnectMcpServer saveAndConnect;
  late DeleteMcpServer deleteServer;

  setUp(() {
    repository = _MemoryMcpServerRepository();
    credentials = _MemoryMcpCredentialStore();
    bots = _MemoryBotRepository();
    catalog = _FakeMcpCatalogController(repository);
    saveAndConnect = SaveAndConnectMcpServer(
      repository: repository,
      credentialStore: credentials,
      catalogController: catalog,
      now: () => DateTime(2026, 8, 15, 10),
    );
    deleteServer = DeleteMcpServer(
      repository: repository,
      botRepository: bots,
      credentialStore: credentials,
      catalogController: catalog,
    );
  });

  group('SaveAndConnectMcpServer', () {
    test(
      'commits local state before discovery and returns committed',
      () async {
        McpServerCommit? commit;

        final result = await saveAndConnect(
          const McpServerDraft(
            name: 'Example',
            endpoint: 'https://example.com/mcp',
            authType: McpAuthType.oauthAccessToken,
            accessToken: 'secret-token',
          ),
          onCommitted: (value) => commit = value,
        );

        expect(result.outcome, McpServerMutationOutcome.committed);
        expect(result.server?.status, McpConnectionStatus.connected);
        expect(commit?.server.status, McpConnectionStatus.disconnected);
        expect(commit?.clearTools, isFalse);
        expect(repository.servers, hasLength(1));
        expect(
          credentials.values[commit?.server.id]?.accessToken,
          'secret-token',
        );
      },
    );

    test('returns warning when discovery fails after local commit', () async {
      catalog.refreshError = const McpException('mcp_remote_unavailable');

      final result = await saveAndConnect(
        const McpServerDraft(
          name: 'Offline',
          endpoint: 'https://example.com/offline',
        ),
      );

      expect(result.outcome, McpServerMutationOutcome.warning);
      expect(result.warning?.code, 'mcp_remote_unavailable');
      expect(result.failure, isNull);
      expect(repository.servers, hasLength(1));
    });

    test('rejects malformed environment without changing resources', () async {
      final result = await saveAndConnect(
        const McpServerDraft(
          name: 'Local',
          transportType: McpTransportType.stdio,
          command: 'npx',
          environment: 'NOT VALID',
        ),
      );

      expect(result.outcome, McpServerMutationOutcome.failure);
      expect(result.failure?.code, 'mcp_invalid_stdio_environment');
      expect(repository.servers, isEmpty);
      expect(credentials.values, isEmpty);
      expect(catalog.refreshCount, 0);
    });

    test('restores the previous credential when persistence fails', () async {
      const id = 'mcp-existing';
      repository.servers[id] = _server(id: id, name: 'Existing');
      credentials.values[id] = McpCredential(accessToken: 'old-secret');
      repository.saveError = StateError('database write failed');

      final result = await saveAndConnect(
        const McpServerDraft(
          id: id,
          name: 'Updated',
          endpoint: 'https://example.com/updated',
          authType: McpAuthType.oauthAccessToken,
          accessToken: 'new-secret',
        ),
      );

      expect(result.outcome, McpServerMutationOutcome.failure);
      expect(result.failure?.code, 'mcp_save_failed');
      expect(credentials.values[id]?.accessToken, 'old-secret');
      expect(repository.servers[id]?.name, 'Existing');
    });
  });

  group('DeleteMcpServer', () {
    test('rejects deletion while an agent references the server', () async {
      final server = _server(id: 'mcp-in-use', name: 'In use');
      repository.servers[server.id] = server;
      credentials.values[server.id] = McpCredential(accessToken: 'keep-secret');
      bots.bots.add(_bot(mcpServerId: server.id));

      final result = await deleteServer(server);

      expect(result.outcome, McpServerMutationOutcome.failure);
      expect(result.failure?.code, 'mcp_server_in_use_by_bot');
      expect(repository.servers[server.id], same(server));
      expect(credentials.values[server.id]?.accessToken, 'keep-secret');
      expect(catalog.disconnectCount, 0);
      expect(bots.lastForceRefresh, isTrue);
    });

    test('restores the credential when persistence fails', () async {
      final server = _server(id: 'mcp-delete', name: 'Delete');
      repository.servers[server.id] = server;
      credentials.values[server.id] = McpCredential(accessToken: 'keep-secret');
      repository.deleteError = StateError('database delete failed');

      final result = await deleteServer(server);

      expect(result.outcome, McpServerMutationOutcome.failure);
      expect(result.failure?.code, 'mcp_delete_failed');
      expect(credentials.values[server.id]?.accessToken, 'keep-secret');
      expect(repository.servers[server.id], isNotNull);
    });

    test('reports rollback failure explicitly', () async {
      final server = _server(id: 'mcp-rollback', name: 'Rollback');
      repository.servers[server.id] = server;
      credentials.values[server.id] = McpCredential(accessToken: 'keep-secret');
      repository.deleteError = StateError('database delete failed');
      credentials.writeError = StateError('credential restore failed');

      final result = await deleteServer(server);

      expect(result.outcome, McpServerMutationOutcome.failure);
      expect(result.failure?.code, 'mcp_credential_rollback_failed');
      expect(repository.servers[server.id], isNotNull);
    });

    test('deletes local state but returns a disconnect warning', () async {
      final server = _server(id: 'mcp-warning', name: 'Warning');
      repository.servers[server.id] = server;
      credentials.values[server.id] = McpCredential(accessToken: 'secret');
      catalog.disconnectError = const McpException('mcp_disconnect_failed');

      final result = await deleteServer(server);

      expect(result.outcome, McpServerMutationOutcome.warning);
      expect(result.warning?.code, 'mcp_disconnect_failed');
      expect(repository.servers[server.id], isNull);
      expect(credentials.values[server.id], isNull);
    });
  });
}

Bot _bot({required String mcpServerId}) {
  final timestamp = DateTime(2026, 8, 15, 8);
  return Bot(
    id: 'bot-1',
    name: 'Agent',
    avatar: '',
    provider: 'OpenAI',
    baseURL: 'https://example.com',
    apiKey: '',
    apiType: Bot.apiTypeOpenAI,
    model: 'model',
    systemPrompt: '',
    parameters: {
      Bot.parameterMcpServers: [mcpServerId],
    },
    createTimestamp: timestamp,
    modifyTimestamp: timestamp,
  );
}

McpServer _server({required String id, required String name}) {
  final timestamp = DateTime(2026, 8, 15, 9);
  return McpServer(
    id: id,
    name: name,
    transport: McpStreamableHttpServerTransport(
      endpoint: Uri.parse('https://example.com/$id'),
      authType: McpAuthType.oauthAccessToken,
    ),
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

final class _MemoryMcpServerRepository implements McpServerRepository {
  final Map<String, McpServer> servers = {};
  final Map<String, List<McpToolDescriptor>> tools = {};
  Object? saveError;
  Object? deleteError;

  @override
  Stream<List<McpServer>> get changes => const Stream.empty();

  @override
  Future<void> deleteServer(String id) async {
    if (deleteError case final error?) throw error;
    servers.remove(id);
    tools.remove(id);
  }

  @override
  Future<McpServer?> getServer(String id) async => servers[id];

  @override
  Future<List<McpServer>> getServers() async =>
      List<McpServer>.unmodifiable(servers.values);

  @override
  Future<List<McpToolDescriptor>> getTools(String serverId) async =>
      tools[serverId] ?? const [];

  @override
  Future<void> replaceCatalog(
    McpServer server,
    List<McpToolDescriptor> tools,
  ) async {
    servers[server.id] = server;
    this.tools[server.id] = List<McpToolDescriptor>.unmodifiable(tools);
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

  @override
  Future<void> delete(String serverId) async {
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

final class _MemoryBotRepository implements BotRepository {
  final List<Bot> bots = [];
  bool? lastForceRefresh;

  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async {
    lastForceRefresh = forceRefresh;
    return List<Bot>.unmodifiable(bots);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Bot operation is not used by this test.');
}

final class _FakeMcpCatalogController implements McpCatalogController {
  _FakeMcpCatalogController(this.repository);

  final _MemoryMcpServerRepository repository;
  Object? refreshError;
  Object? disconnectError;
  Object? hydrateError;
  int refreshCount = 0;
  int disconnectCount = 0;

  @override
  Future<void> disconnect(McpServer server) async {
    disconnectCount += 1;
    if (disconnectError case final error?) throw error;
  }

  @override
  McpStdioProcessInfo? getStdioProcessInfo(String serverId) => null;

  @override
  Future<void> hydrateFromCache() async {
    if (hydrateError case final error?) throw error;
  }

  @override
  Future<McpServer> refreshServer(String serverId) async {
    refreshCount += 1;
    if (refreshError case final error?) throw error;
    final server = repository.servers[serverId]!;
    final connected = server.copyWith(status: McpConnectionStatus.connected);
    repository.servers[serverId] = connected;
    return connected;
  }
}
