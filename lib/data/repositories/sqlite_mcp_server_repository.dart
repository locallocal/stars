import 'dart:async';

import 'package:stars/data/models/mcp_records.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/services/mcp_configuration_policy.dart';

final class SqliteMcpServerRepository implements McpServerRepository {
  SqliteMcpServerRepository({required LocalDatabaseService localDatabase})
    : _localDatabase = localDatabase;

  final LocalDatabaseService _localDatabase;
  final StreamController<List<McpServer>> _changes =
      StreamController<List<McpServer>>.broadcast();

  @override
  Stream<List<McpServer>> get changes => _changes.stream;

  @override
  Future<List<McpServer>> getServers() async {
    final records = await _localDatabase.loadMcpServers();
    return List<McpServer>.unmodifiable(
      records.map((record) => McpServerRecord(record).toDomain()),
    );
  }

  @override
  Future<McpServer?> getServer(String id) async {
    final records = await _localDatabase.loadMcpServer(id);
    return records.isEmpty ? null : McpServerRecord(records.single).toDomain();
  }

  @override
  Future<void> createServer(
    McpServer server, {
    Future<void> Function()? beforeCommit,
  }) async {
    McpConfigurationPolicy.validateTransport(server.transport);
    await _localDatabase.insertMcpServer(
      McpServerRecord.fromDomain(server).values,
      beforeCommit: beforeCommit,
    );
    await _emitServers();
  }

  @override
  Future<void> saveServer(McpServer server) async {
    McpConfigurationPolicy.validateTransport(server.transport);
    final existing = await getServer(server.id);
    await _localDatabase.upsertMcpServer(
      McpServerRecord.fromDomain(server).values,
      clearTools: existing != null && existing.transport != server.transport,
    );
    await _emitServers();
  }

  @override
  Future<void> deleteServer(String id) async {
    await _localDatabase.deleteMcpServer(id);
    await _emitServers();
  }

  @override
  Future<List<McpToolDescriptor>> getTools(String serverId) async {
    final records = await _localDatabase.loadMcpTools(serverId);
    return List<McpToolDescriptor>.unmodifiable(
      records.map((record) => McpToolRecord(record).toDomain()),
    );
  }

  @override
  Future<void> replaceCatalog(
    McpServer server,
    List<McpToolDescriptor> tools,
  ) async {
    McpConfigurationPolicy.validateTransport(server.transport);
    final records = await _catalogRecords(server, tools);
    await _localDatabase.replaceMcpCatalog(
      McpServerRecord.fromDomain(server).values,
      records,
    );
    await _emitServers();
  }

  Future<List<Map<String, Object?>>> _catalogRecords(
    McpServer server,
    List<McpToolDescriptor> tools,
  ) async {
    return [
      for (final tool in tools)
        if (tool.serverId != server.id)
          throw ArgumentError.value(
            tool.remoteName,
            'tools',
            'MCP Tool ownership does not match its server.',
          )
        else
          McpToolRecord.fromDomain(tool).values,
    ];
  }

  Future<void> _emitServers() async {
    // A notification failure must not turn a committed write into a failure
    // and cause its secure credentials to be rolled back by the caller.
    try {
      final servers = await getServers();
      if (!_changes.isClosed) _changes.add(servers);
    } on Object {
      // Consumers can reload; the database commit remains authoritative.
    }
  }

  Future<void> dispose() => _changes.close();
}
