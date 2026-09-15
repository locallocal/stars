part of 'mcp_servers_page_test.dart';

McpServersViewModel _createMcpServersViewModel({
  required McpServerRepository repository,
  BotRepository botRepository = const _FakeBotRepository(),
  required McpCredentialStore credentialStore,
  required McpCatalogService catalogService,
}) => McpServersViewModel(
  repository: repository,
  catalogService: catalogService,
  saveAndConnect: SaveAndConnectMcpServer(
    repository: repository,
    credentialStore: credentialStore,
    catalogController: catalogService,
  ),
  deleteServer: DeleteMcpServer(
    repository: repository,
    botRepository: botRepository,
    credentialStore: credentialStore,
    catalogController: catalogService,
  ),
);

final class _FakeBotRepository implements BotRepository {
  const _FakeBotRepository([this.bots = const []]);

  final List<Bot> bots;

  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async => bots;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Bot operation is not used by this test.');
}

Bot _botUsingMcpServer(String serverId, {required DateTime now}) => Bot(
  id: 'agent',
  name: 'Agent',
  avatar: '',
  provider: 'OpenAI',
  baseURL: 'https://example.com',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'model',
  systemPrompt: '',
  parameters: {
    Bot.parameterMcpServers: [serverId],
  },
  createTimestamp: now,
  modifyTimestamp: now,
);

Widget _harness(McpServersViewModel viewModel) {
  final shadTheme = buildStarsShadTheme(
    brightness: Brightness.light,
    fontSize: 16,
  );
  return ShadApp.custom(
    themeMode: ThemeMode.light,
    theme: shadTheme,
    appBuilder:
        (shadContext) => MaterialApp(
          theme: buildShadMaterialBridgeTheme(
            context: shadContext,
            fontSize: 16,
          ),
          locale: const Locale('zh', 'CN'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: McpServersPage(viewModel: viewModel),
        ),
  );
}

final class _FakeMcpServerRepository implements McpServerRepository {
  const _FakeMcpServerRepository({
    this.servers = const [],
    this.toolsByServer = const {},
    this.getServersError,
  });

  final List<McpServer> servers;
  final Map<String, List<McpToolDescriptor>> toolsByServer;
  final Object? getServersError;

  @override
  Stream<List<McpServer>> get changes => const Stream.empty();

  @override
  Future<void> deleteServer(String id) async {}

  @override
  Future<McpServer?> getServer(String id) async {
    for (final server in servers) {
      if (server.id == id) return server;
    }
    return null;
  }

  @override
  Future<List<McpServer>> getServers() async {
    if (getServersError case final error?) throw error;
    return servers;
  }

  @override
  Future<List<McpToolDescriptor>> getTools(String serverId) async =>
      toolsByServer[serverId] ?? const [];

  @override
  Future<void> replaceCatalog(
    McpServer server,
    List<McpToolDescriptor> tools,
  ) async {}

  @override
  Future<void> saveServer(McpServer server) async {}
}

final class _UnusedCredentialStore implements McpCredentialStore {
  const _UnusedCredentialStore();

  @override
  Future<void> delete(String serverId) => throw UnimplementedError();

  @override
  Future<McpCredential?> read(String serverId) => throw UnimplementedError();

  @override
  Future<void> write(String serverId, McpCredential credential) =>
      throw UnimplementedError();
}

final class _UnusedMcpClient implements McpClient, McpStdioProcessInfoSource {
  const _UnusedMcpClient({this.processInfoByServerId = const {}});

  final Map<String, McpStdioProcessInfo> processInfoByServerId;

  @override
  McpStdioProcessInfo? getStdioProcessInfo(String serverId) =>
      processInfoByServerId[serverId];

  @override
  Future<McpToolCallResult> callTool({
    required McpServer server,
    required String remoteName,
    required Map<String, Object?> arguments,
    required AgentCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<void> disconnect(McpServer server) => throw UnimplementedError();

  @override
  Future<McpServerCatalog> discoverTools(
    McpServer server, {
    AgentCancellationToken? cancellationToken,
  }) => throw UnimplementedError();
}

final class _SavingMcpServerRepository implements McpServerRepository {
  final Map<String, McpServer> _servers = {};
  final Map<String, List<McpToolDescriptor>> _tools = {};

  @override
  Stream<List<McpServer>> get changes => const Stream.empty();

  @override
  Future<void> deleteServer(String id) async {
    _servers.remove(id);
    _tools.remove(id);
  }

  @override
  Future<McpServer?> getServer(String id) async => _servers[id];

  @override
  Future<List<McpServer>> getServers() async {
    final servers =
        _servers.values.toList()
          ..sort((left, right) => left.name.compareTo(right.name));
    return List<McpServer>.unmodifiable(servers);
  }

  @override
  Future<List<McpToolDescriptor>> getTools(String serverId) async =>
      _tools[serverId] ?? const [];

  @override
  Future<void> replaceCatalog(
    McpServer server,
    List<McpToolDescriptor> tools,
  ) async {
    _servers[server.id] = server;
    _tools[server.id] = List<McpToolDescriptor>.unmodifiable(tools);
  }

  @override
  Future<void> saveServer(McpServer server) async {
    _servers[server.id] = server;
  }
}

final class _NoOpCredentialStore implements McpCredentialStore {
  const _NoOpCredentialStore();

  @override
  Future<void> delete(String serverId) async {}

  @override
  Future<McpCredential?> read(String serverId) async => null;

  @override
  Future<void> write(String serverId, McpCredential credential) async {}
}

final class _BlockingMcpClient implements McpClient {
  final Completer<void> discoveryStarted = Completer<void>();
  final Completer<void> continueDiscovery = Completer<void>();

  @override
  Future<McpToolCallResult> callTool({
    required McpServer server,
    required String remoteName,
    required Map<String, Object?> arguments,
    required AgentCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<void> disconnect(McpServer server) async {}

  @override
  Future<McpServerCatalog> discoverTools(
    McpServer server, {
    AgentCancellationToken? cancellationToken,
  }) async {
    discoveryStarted.complete();
    await continueDiscovery.future;
    return McpServerCatalog(
      serverName: 'Slow MCP',
      serverVersion: '1.0.0',
      capabilities: McpServerCapabilities(tools: true),
      tools: [],
    );
  }
}
