import 'package:stars/domain/models/models.dart';

abstract interface class McpServerRepository {
  Stream<List<McpServer>> get changes;

  Future<List<McpServer>> getServers();

  Future<McpServer?> getServer(String id);

  /// Inserts without overwriting an ID or a normalized name. [beforeCommit]
  /// runs only after conflict checks, inside the insert transaction. It must
  /// not access this repository; callers compensate external writes on failure.
  Future<void> createServer(
    McpServer server, {
    Future<void> Function()? beforeCommit,
  });

  Future<void> saveServer(McpServer server);

  Future<void> deleteServer(String id);

  Future<List<McpToolDescriptor>> getTools(String serverId);

  Future<void> replaceCatalog(McpServer server, List<McpToolDescriptor> tools);
}
