import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/catalog_controller.dart';
import 'package:stars/domain/repositories/mcp_credential_store.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';

enum McpServerMutationOutcome { committed, warning, failure }

final class McpServerMutationResult {
  const McpServerMutationResult.committed({this.server})
    : outcome = McpServerMutationOutcome.committed,
      _warning = null,
      _failure = null;

  const McpServerMutationResult.warning({
    this.server,
    required AppFailure warning,
  }) : outcome = McpServerMutationOutcome.warning,
       _warning = warning,
       _failure = null;

  const McpServerMutationResult.failed(AppFailure failure)
    : outcome = McpServerMutationOutcome.failure,
      server = null,
      _warning = null,
      _failure = failure;

  final McpServerMutationOutcome outcome;
  final McpServer? server;
  final AppFailure? _warning;
  final AppFailure? _failure;

  AppFailure? get warning => _warning;
  AppFailure? get failure => _failure;

  bool get isCommitted => outcome != McpServerMutationOutcome.failure;
}

final class McpServerCommit {
  const McpServerCommit({required this.server, required this.clearTools});

  final McpServer server;
  final bool clearTools;
}

typedef McpServerCommitObserver = void Function(McpServerCommit commit);

final class SaveAndConnectMcpServer {
  SaveAndConnectMcpServer({
    required McpServerRepository repository,
    required McpCredentialStore credentialStore,
    required McpCatalogController catalogController,
    DateTime Function()? now,
  }) : _repository = repository,
       _credentialStore = credentialStore,
       _catalogController = catalogController,
       _now = now ?? DateTime.now;

  final McpServerRepository _repository;
  final McpCredentialStore _credentialStore;
  final McpCatalogController _catalogController;
  final DateTime Function() _now;

  Future<McpServerMutationResult> call(
    McpServerDraft draft, {
    McpServerCommitObserver? onCommitted,
  }) async {
    final timestamp = _now();
    final McpServer? existing;
    try {
      existing =
          draft.id == null ? null : await _repository.getServer(draft.id!);
    } on Object catch (error) {
      return McpServerMutationResult.failed(
        AppFailure.from(error, code: 'mcp_server_read_failed'),
      );
    }

    final id =
        existing?.id ??
        'mcp-${timestamp.microsecondsSinceEpoch.toRadixString(36)}';
    final transportResult = _buildTransport(draft);
    if (transportResult case final AppFailure failure) {
      return McpServerMutationResult.failed(failure);
    }
    final transport = transportResult as McpServerTransport;
    final environment = _parseEnvironment(draft.environment);
    if (environment == null) {
      return const McpServerMutationResult.failed(
        AppFailure.validation('mcp_invalid_stdio_environment'),
      );
    }

    final McpCredential? previousCredential;
    try {
      previousCredential = await _readCredentialForRollback(id);
    } on Object catch (error) {
      return McpServerMutationResult.failed(
        AppFailure.from(error, code: 'mcp_credential_read_failed'),
      );
    }

    late final McpServer server;
    var credentialChanged = false;
    try {
      server = McpServer(
        id: id,
        name: draft.name.trim(),
        transport: transport,
        remoteServerName: existing?.remoteServerName ?? '',
        remoteServerVersion: existing?.remoteServerVersion ?? '',
        capabilities: existing?.capabilities ?? const McpServerCapabilities(),
        status: McpConnectionStatus.disconnected,
        createdAt: existing?.createdAt ?? timestamp,
        updatedAt: timestamp,
      );
      credentialChanged = true;
      await _saveCredential(
        id: id,
        existing: existing,
        draft: draft,
        environment: environment,
      );
      await _repository.saveServer(server);
    } on Object catch (error) {
      if (credentialChanged) {
        try {
          await _restoreCredential(id, previousCredential);
        } on Object catch (rollbackError) {
          return McpServerMutationResult.failed(
            AppFailure.storage(
              'mcp_credential_rollback_failed',
              cause: (error, rollbackError),
            ),
          );
        }
      }
      return McpServerMutationResult.failed(
        AppFailure.from(error, code: 'mcp_save_failed'),
      );
    }

    onCommitted?.call(
      McpServerCommit(
        server: server,
        clearTools: existing != null && existing.transport != server.transport,
      ),
    );

    try {
      final connected = await _catalogController.refreshServer(id);
      return McpServerMutationResult.committed(server: connected);
    } on Object catch (error) {
      return McpServerMutationResult.warning(
        server: server,
        warning: AppFailure.from(error, code: 'mcp_operation_failed'),
      );
    }
  }

  Object _buildTransport(McpServerDraft draft) {
    switch (draft.transportType) {
      case McpTransportType.streamableHttp:
        final parsedEndpoint = Uri.tryParse(draft.endpoint.trim());
        if (parsedEndpoint == null ||
            !parsedEndpoint.hasScheme ||
            parsedEndpoint.host.isEmpty) {
          return const AppFailure.validation('mcp_invalid_endpoint');
        }
        return McpStreamableHttpServerTransport(
          endpoint: parsedEndpoint,
          authType: draft.authType,
        );
      case McpTransportType.stdio:
        if (draft.command.trim().isEmpty) {
          return const AppFailure.validation('mcp_invalid_stdio_command');
        }
        return McpStdioServerTransport(
          command: draft.command.trim(),
          arguments: draft.arguments
              .split(RegExp(r'\r?\n'))
              .map((argument) => argument.trim())
              .where((argument) => argument.isNotEmpty)
              .toList(growable: false),
        );
    }
  }

  Future<McpCredential?> _readCredentialForRollback(String id) async {
    try {
      return await _credentialStore.read(id);
    } on Object catch (error) {
      throw AppFailure.storage('mcp_credential_read_failed', cause: error);
    }
  }

  Future<void> _restoreCredential(String id, McpCredential? credential) async {
    if (credential == null) {
      await _credentialStore.delete(id);
    } else {
      await _credentialStore.write(id, credential);
    }
  }

  Future<void> _saveCredential({
    required String id,
    required McpServer? existing,
    required McpServerDraft draft,
    required Map<String, String> environment,
  }) async {
    if (draft.transportType == McpTransportType.stdio) {
      if (environment.isNotEmpty) {
        await _credentialStore.write(
          id,
          McpCredential(environment: environment),
        );
      } else if (existing?.transport is! McpStdioServerTransport) {
        await _credentialStore.delete(id);
      }
      return;
    }

    if (draft.authType == McpAuthType.none) {
      await _credentialStore.delete(id);
      return;
    }
    final accessToken = draft.accessToken.trim();
    if (accessToken.isNotEmpty) {
      await _credentialStore.write(id, McpCredential(accessToken: accessToken));
    } else if (existing?.transport case McpStreamableHttpServerTransport(
      authType: McpAuthType.oauthAccessToken,
    )) {
      return;
    } else {
      await _credentialStore.delete(id);
    }
  }
}

final class DeleteMcpServer {
  const DeleteMcpServer({
    required McpServerRepository repository,
    required BotRepository botRepository,
    required McpCredentialStore credentialStore,
    required McpCatalogController catalogController,
  }) : _repository = repository,
       _botRepository = botRepository,
       _credentialStore = credentialStore,
       _catalogController = catalogController;

  final McpServerRepository _repository;
  final BotRepository _botRepository;
  final McpCredentialStore _credentialStore;
  final McpCatalogController _catalogController;

  Future<McpServerMutationResult> call(McpServer server) async {
    try {
      final bots = await _botRepository.getBots(forceRefresh: true);
      if (bots.any((bot) => bot.mcpServerIds.contains(server.id))) {
        return const McpServerMutationResult.failed(
          AppFailure.validation('mcp_server_in_use_by_bot'),
        );
      }
      final previousCredential = await _readCredentialForRollback(server.id);
      AppFailure? warning;
      try {
        await _catalogController.disconnect(server);
      } on Object catch (error) {
        warning = AppFailure.from(error, code: 'mcp_disconnect_failed');
      }
      await _credentialStore.delete(server.id);
      try {
        await _repository.deleteServer(server.id);
      } on Object catch (error) {
        try {
          await _restoreCredential(server.id, previousCredential);
        } on Object catch (rollbackError) {
          throw AppFailure.storage(
            'mcp_credential_rollback_failed',
            cause: (error, rollbackError),
          );
        }
        rethrow;
      }
      try {
        await _catalogController.hydrateFromCache();
      } on Object catch (error) {
        warning = AppFailure.from(error, code: 'mcp_cache_refresh_failed');
      }
      return warning == null
          ? const McpServerMutationResult.committed()
          : McpServerMutationResult.warning(warning: warning);
    } on Object catch (error) {
      return McpServerMutationResult.failed(
        AppFailure.from(error, code: 'mcp_delete_failed'),
      );
    }
  }

  Future<McpCredential?> _readCredentialForRollback(String id) async {
    try {
      return await _credentialStore.read(id);
    } on Object catch (error) {
      throw AppFailure.storage('mcp_credential_read_failed', cause: error);
    }
  }

  Future<void> _restoreCredential(String id, McpCredential? credential) async {
    if (credential == null) {
      await _credentialStore.delete(id);
    } else {
      await _credentialStore.write(id, credential);
    }
  }
}

Map<String, String>? _parseEnvironment(String source) {
  final environment = <String, String>{};
  for (final rawLine in source.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final separator = line.indexOf('=');
    if (separator <= 0) return null;
    final key = line.substring(0, separator).trim();
    if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key)) return null;
    environment[key] = line.substring(separator + 1);
  }
  return Map<String, String>.unmodifiable(environment);
}
