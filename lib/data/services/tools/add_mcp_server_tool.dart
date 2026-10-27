import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/mcp_credential_store.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/services/mcp_configuration_policy.dart';
import 'package:stars/domain/services/mcp_server_identity.dart';

typedef McpServerConnector =
    Future<McpServer> Function(
      String serverId,
      AgentCancellationToken cancellationToken,
    );

final class AddMcpServerTool implements ExecutableTool {
  AddMcpServerTool({
    required McpServerRepository repository,
    required McpCredentialStore credentialStore,
    required McpServerConnector connector,
    DateTime Function()? now,
    String Function(DateTime timestamp)? idFactory,
  }) : _repository = repository,
       _credentialStore = credentialStore,
       _connector = connector,
       _now = now ?? DateTime.now,
       _idFactory = idFactory ?? ((_) => newMcpServerId());

  final McpServerRepository _repository;
  final McpCredentialStore _credentialStore;
  final McpServerConnector _connector;
  final DateTime Function() _now;
  final String Function(DateTime timestamp) _idFactory;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: addMcpServerToolName,
    title: 'Add MCP server',
    description:
        'Create one new Stars MCP server from explicit Streamable HTTP or '
        'stdio connection details, store credentials securely, and optionally '
        'connect it to discover Tools. Existing servers are never overwritten.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'minLength': 1, 'maxLength': 128},
        'transport_type': {
          'type': 'string',
          'enum': ['streamable_http', 'stdio'],
        },
        'endpoint': {'type': 'string', 'maxLength': 4096},
        'auth_type': {
          'type': 'string',
          'enum': ['none', 'oauth_access_token'],
          'default': 'none',
        },
        'access_token': {'type': 'string', 'maxLength': 16384},
        'command': {'type': 'string', 'maxLength': 4096},
        'arguments': {
          'type': 'array',
          'items': {'type': 'string', 'maxLength': 4096},
          'maxItems': 128,
        },
        'environment': {
          'type': 'object',
          'additionalProperties': {'type': 'string', 'maxLength': 16384},
          'maxProperties': 128,
        },
        'connect': {'type': 'boolean', 'default': true},
      },
      'required': ['name', 'transport_type'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'server_id': {'type': 'string'},
        'name': {'type': 'string'},
        'transport_type': {
          'type': 'string',
          'enum': ['streamable_http', 'stdio'],
        },
        'connection_status': {'type': 'string'},
        'tool_count': {'type': 'integer'},
        'credential_stored': {'type': 'boolean'},
        'connection_error': {'type': 'string'},
      },
      'required': [
        'server_id',
        'name',
        'transport_type',
        'connection_status',
        'tool_count',
        'credential_stored',
      ],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.write,
    capabilities: const {
      ToolCapability.localRead,
      ToolCapability.localWrite,
      ToolCapability.network,
      ToolCapability.process,
    },
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    try {
      final name = _requiredName(call.arguments['name']);
      final existing = await _repository.getServers();
      cancellationToken.throwIfCancelled();
      if (existing.any(
        (server) => server.name.trim().toLowerCase() == name.toLowerCase(),
      )) {
        return _error(
          call,
          'An MCP server named "$name" already exists.',
          'mcp_server_already_exists',
        );
      }

      final transportType = call.arguments['transport_type'];
      final transport = switch (transportType) {
        'streamable_http' => _httpTransport(call.arguments),
        'stdio' => _stdioTransport(call.arguments),
        _ =>
          throw const _AddMcpServerException(
            'invalid_mcp_transport',
            'MCP transport_type must be streamable_http or stdio.',
          ),
      };
      McpConfigurationPolicy.validateTransport(transport);
      final credential = _credential(call.arguments, transport);
      final shouldConnect = _optionalBool(call.arguments['connect']) ?? true;
      final timestamp = _now();
      final id = _uniqueId(existing, timestamp);
      final server = McpServer(
        id: id,
        name: name,
        transport: transport,
        createdAt: timestamp,
        updatedAt: timestamp,
      );
      var credentialAttempted = false;
      try {
        cancellationToken.throwIfCancelled();
        await _repository.createServer(
          server,
          beforeCommit: () async {
            cancellationToken.throwIfCancelled();
            if (credential != null) {
              credentialAttempted = true;
              try {
                await _credentialStore.write(id, credential);
              } on Object {
                throw const _AddMcpServerException(
                  'mcp_credential_store_failed',
                  'The MCP credential could not be stored securely.',
                );
              }
            }
            cancellationToken.throwIfCancelled();
          },
        );
      } on Object {
        if (credentialAttempted && !await _rollbackCredential(id, credential)) {
          throw const _AddMcpServerException(
            'mcp_credential_rollback_failed',
            'The MCP credential rollback failed.',
          );
        }
        rethrow;
      }

      if (!shouldConnect) {
        return _success(
          call,
          server: server,
          toolCount: 0,
          credentialStored: credential != null,
        );
      }

      try {
        cancellationToken.throwIfCancelled();
        final connected = await _connector(id, cancellationToken);
        if (connected.id != id) {
          throw const McpException('mcp_connection_identity_mismatch');
        }
        final tools = await _repository.getTools(id);
        return _success(
          call,
          server: connected,
          toolCount: tools.length,
          credentialStored: credential != null,
        );
      } on AgentRunCancelledException {
        rethrow;
      } on Object catch (error) {
        final code =
            error is McpException && error.code.isNotEmpty
                ? error.code
                : 'mcp_connection_failed';
        return _success(
          call,
          server: await _retainedServer(id, fallback: server),
          toolCount: await _retainedToolCount(id),
          credentialStored: credential != null,
          connectionError: code,
        );
      }
    } on AgentRunCancelledException {
      rethrow;
    } on _AddMcpServerException catch (error) {
      return _error(call, error.message, error.code);
    } on McpException catch (error) {
      return _error(call, switch (error.code) {
        'mcp_server_already_exists' =>
          'An MCP server with this name already exists.',
        'mcp_server_id_conflict' =>
          'The new MCP server identity conflicts with an existing server. Retry the request.',
        'mcp_credentials_in_configuration' =>
          'Use secure access_token or environment fields for credentials, not URLs, commands, or arguments.',
        _ => 'The MCP server could not be added.',
      }, error.code);
    } on ArgumentError catch (error) {
      return _error(call, error.message.toString(), 'invalid_mcp_server');
    } on Object {
      return _error(
        call,
        'The MCP server could not be added.',
        'mcp_server_add_failed',
      );
    }
  }

  String _requiredName(Object? value) {
    if (value is! String || value.trim().isEmpty || value.trim().length > 128) {
      throw const _AddMcpServerException(
        'invalid_mcp_server_name',
        'MCP server name must contain 1-128 characters.',
      );
    }
    return value.trim();
  }

  McpServerTransport _httpTransport(Map<String, Object?> arguments) {
    _rejectPresent(arguments, const ['command', 'arguments', 'environment']);
    final endpointSource = arguments['endpoint'];
    final endpoint =
        endpointSource is String ? Uri.tryParse(endpointSource.trim()) : null;
    if (endpointSource is! String ||
        endpointSource.length > 4096 ||
        endpoint == null ||
        endpoint.scheme.toLowerCase() != 'https' ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.fragment.isNotEmpty) {
      throw const _AddMcpServerException(
        'mcp_invalid_endpoint',
        'A Streamable HTTP MCP endpoint must be an absolute HTTPS URI.',
      );
    }
    final authType = switch (arguments['auth_type'] ?? 'none') {
      'none' => McpAuthType.none,
      'oauth_access_token' => McpAuthType.oauthAccessToken,
      _ =>
        throw const _AddMcpServerException(
          'mcp_invalid_auth_type',
          'MCP auth_type must be none or oauth_access_token.',
        ),
    };
    final accessTokenValue = arguments['access_token'];
    if (accessTokenValue != null && accessTokenValue is! String) {
      throw const _AddMcpServerException(
        'mcp_invalid_credential',
        'The MCP access token is invalid.',
      );
    }
    final accessToken =
        accessTokenValue is String ? accessTokenValue.trim() : '';
    if (accessToken.length > 16384) {
      throw const _AddMcpServerException(
        'mcp_invalid_credential',
        'The MCP access token is too long.',
      );
    }
    if (authType == McpAuthType.none && accessToken.isNotEmpty) {
      throw const _AddMcpServerException(
        'mcp_unexpected_credential',
        'access_token requires auth_type oauth_access_token.',
      );
    }
    if (authType == McpAuthType.oauthAccessToken &&
        (accessToken.isEmpty || _isPlaceholder(accessToken))) {
      throw const _AddMcpServerException(
        'mcp_access_token_required',
        'A real MCP access token is required. Replace the placeholder in your '
            'configuration and send a new installation request.',
      );
    }
    if (accessToken.contains('\r') || accessToken.contains('\n')) {
      throw const _AddMcpServerException(
        'mcp_invalid_credential',
        'The MCP access token is invalid.',
      );
    }
    return McpStreamableHttpServerTransport(
      endpoint: endpoint,
      authType: authType,
    );
  }

  McpServerTransport _stdioTransport(Map<String, Object?> arguments) {
    _rejectPresent(arguments, const ['endpoint', 'access_token']);
    final authType = arguments['auth_type'];
    if (authType != null && authType != 'none') {
      throw const _AddMcpServerException(
        'mcp_transport_field_mismatch',
        'auth_type is not valid for the stdio MCP transport.',
      );
    }
    final command = arguments['command'];
    if (command is! String ||
        command.trim().isEmpty ||
        command.trim().length > 4096 ||
        command.contains('\r') ||
        command.contains('\n')) {
      throw const _AddMcpServerException(
        'mcp_invalid_stdio_command',
        'A stdio MCP server requires one executable command.',
      );
    }
    final rawArguments = arguments['arguments'];
    if (rawArguments != null && rawArguments is! List) {
      throw const _AddMcpServerException(
        'mcp_invalid_stdio_arguments',
        'stdio arguments must be a string array.',
      );
    }
    if (rawArguments is List && rawArguments.length > 128) {
      throw const _AddMcpServerException(
        'mcp_invalid_stdio_arguments',
        'stdio arguments must contain at most 128 values.',
      );
    }
    final commandArguments = <String>[];
    for (final value in rawArguments as List? ?? const []) {
      if (value is! String || value.length > 4096) {
        throw const _AddMcpServerException(
          'mcp_invalid_stdio_arguments',
          'stdio arguments must be strings of at most 4096 characters.',
        );
      }
      commandArguments.add(value);
    }
    return McpStdioServerTransport(
      command: command.trim(),
      arguments: commandArguments,
    );
  }

  McpCredential? _credential(
    Map<String, Object?> arguments,
    McpServerTransport transport,
  ) {
    return switch (transport) {
      McpStreamableHttpServerTransport(
        authType: McpAuthType.oauthAccessToken,
      ) =>
        McpCredential(
          accessToken: (arguments['access_token']! as String).trim(),
        ),
      McpStreamableHttpServerTransport() => null,
      McpStdioServerTransport() => switch (_environment(
        arguments['environment'],
      )) {
        final environment when environment.isNotEmpty => McpCredential(
          environment: environment,
        ),
        _ => null,
      },
    };
  }

  Map<String, String> _environment(Object? value) {
    if (value == null) return const {};
    if (value is! Map || value.length > 128) {
      throw const _AddMcpServerException(
        'mcp_invalid_stdio_environment',
        'stdio environment must be a string map with at most 128 entries.',
      );
    }
    final environment = <String, String>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final item = entry.value;
      if (key is! String ||
          !RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key) ||
          item is! String ||
          item.length > 16384) {
        throw const _AddMcpServerException(
          'mcp_invalid_stdio_environment',
          'stdio environment names and values are invalid.',
        );
      }
      environment[key] = item;
      if (_isPlaceholder(item)) {
        throw const _AddMcpServerException(
          'mcp_environment_value_required',
          'Replace placeholder environment values before installing this MCP server.',
        );
      }
    }
    return Map<String, String>.unmodifiable(environment);
  }

  void _rejectPresent(Map<String, Object?> arguments, List<String> keys) {
    for (final key in keys) {
      final value = arguments[key];
      final present = switch (value) {
        null => false,
        final String text => text.trim().isNotEmpty,
        final List<Object?> items => items.isNotEmpty,
        final Map<Object?, Object?> items => items.isNotEmpty,
        _ => true,
      };
      if (present) {
        throw _AddMcpServerException(
          'mcp_transport_field_mismatch',
          '$key is not valid for the selected MCP transport.',
        );
      }
    }
  }

  bool? _optionalBool(Object? value) => switch (value) {
    null => null,
    final bool enabled => enabled,
    _ =>
      throw const _AddMcpServerException(
        'invalid_mcp_connect_option',
        'connect must be a boolean.',
      ),
  };

  Future<bool> _rollbackCredential(
    String serverId,
    McpCredential? credential,
  ) async {
    if (credential == null) return true;
    try {
      await _credentialStore.delete(serverId);
      return true;
    } on Object {
      return false;
    }
  }

  Future<McpServer> _retainedServer(
    String serverId, {
    required McpServer fallback,
  }) async {
    try {
      return await _repository.getServer(serverId) ?? fallback;
    } on Object {
      return fallback;
    }
  }

  Future<int> _retainedToolCount(String serverId) async {
    try {
      return (await _repository.getTools(serverId)).length;
    } on Object {
      return 0;
    }
  }

  String _uniqueId(List<McpServer> existing, DateTime timestamp) {
    final usedIds = existing.map((server) => server.id).toSet();
    final base = _idFactory(timestamp);
    if (!usedIds.contains(base)) return base;
    var suffix = 2;
    while (usedIds.contains('$base-$suffix')) {
      suffix += 1;
    }
    return '$base-$suffix';
  }

  ToolResult _success(
    ToolCallRequest call, {
    required McpServer server,
    required int toolCount,
    required bool credentialStored,
    String connectionError = '',
  }) {
    final transportType = switch (server.transport.type) {
      McpTransportType.streamableHttp => 'streamable_http',
      McpTransportType.stdio => 'stdio',
    };
    final structured = <String, Object?>{
      'server_id': server.id,
      'name': server.name,
      'transport_type': transportType,
      'connection_status': server.status.name,
      'tool_count': toolCount,
      'credential_stored': credentialStored,
      if (connectionError.isNotEmpty) 'connection_error': connectionError,
    };
    final connectionMessage =
        connectionError.isEmpty
            ? 'Connection status: ${server.status.name}.'
            : 'The server remains configured, but connection failed '
                '($connectionError).';
    return ToolResult(
      callId: call.callId,
      name: call.name,
      content:
          'Added MCP server ${server.name} (${server.id}). '
          '$connectionMessage Discovered Tools: $toolCount.',
      structuredContent: structured,
    );
  }

  ToolResult _error(ToolCallRequest call, String message, String code) =>
      ToolResult(
        callId: call.callId,
        name: call.name,
        content: message,
        isError: true,
        errorCode: code,
      );
}

bool _isPlaceholder(String value) => RegExp(
  r'^(?:<(?:YOUR[_ -])?(?:API[_ -]?KEY|ACCESS[_ -]?TOKEN|TOKEN|SECRET|PASSWORD)(?:[_ -]HERE)?>|\$\{[^}]+\}|\[(?:redacted|your[^\]]*)\]|YOUR[_ -](?:API[_ -]?KEY|ACCESS[_ -]?TOKEN|TOKEN)(?:[_ -]HERE)?|REPLACE[_ -]?ME|CHANGEME)$',
  caseSensitive: false,
).hasMatch(value.trim());

final class _AddMcpServerException implements Exception {
  const _AddMcpServerException(this.code, this.message);

  final String code;
  final String message;
}
