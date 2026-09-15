import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';

/// Audited argument names; schemas alone do not authorize durable credentials.
/// Dynamic integrations must register an adapter with their own audited fields.
const taskCheckpointArguments = <String, Set<String>>{
  'calculate': {'operation', 'left', 'right'},
  'get_current_time': {'utc_offset_minutes'},
  'list_local_directory': {'path', 'recursive', 'max_entries'},
  'create_local_directory': {'path', 'recursive'},
  'delete_local_directory': {'path', 'recursive'},
  'query_local_files': {
    'root_path',
    'query',
    'match_mode',
    'case_sensitive',
    'recursive',
    'max_results',
    'max_entries',
  },
  'read_local_file': {'path', 'encoding', 'offset_bytes', 'max_bytes'},
  'write_local_file': {'path', 'content', 'encoding', 'mode', 'create_parents'},
  'copy_local_file': {
    'source_path',
    'destination_path',
    'overwrite',
    'create_parents',
  },
  'move_local_file': {
    'source_path',
    'destination_path',
    'overwrite',
    'create_parents',
  },
  'delete_local_file': {'path'},
  'search_conversation_history': {
    'query',
    'role',
    'after',
    'before',
    'limit',
    'cursor',
  },
  'read_conversation_history': {'references', 'surrounding_turns', 'cursor'},
  'list_installed_skills': {'query', 'limit'},
  'list_current_conversation_skills': {},
  'list_installed_mcp_servers': {'query', 'limit'},
  'list_current_conversation_mcp': {},
};

/// A runtime client resolves credentials independently of the checkpoint. A
/// lookup must find jobs by the stable key even if creation lost its response.
abstract interface class TaskJobClient {
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String key,
    AgentCancellationToken token,
  );
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken token,
  );
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken token,
  );
  Future<ToolReconciliation> lookup(
    ToolCallRequest call,
    String key,
    TaskExternalJob? job,
    AgentCancellationToken token,
  );
}

/// Integrates a real job service without treating tool metadata as proof of
/// idempotency. Reconciliation uses the client's lookup, never its start API.
final class JobTaskToolAdapter implements TaskToolAdapter {
  JobTaskToolAdapter({
    required this.definition,
    required this.client,
    required Set<String> checkpointArgumentNames,
    this.guaranteesIdempotency = false,
  }) : checkpointArgumentNames = Set.unmodifiable(checkpointArgumentNames);
  final TaskJobClient client;
  @override
  final ToolDefinition definition;
  @override
  final Set<String> checkpointArgumentNames;
  @override
  final bool guaranteesIdempotency;
  @override
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String idempotencyKey,
    AgentCancellationToken token,
  ) => client.start(call, idempotencyKey, token);
  @override
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) => client.poll(job, token);
  @override
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) => client.cancel(job, token);
  @override
  Future<ToolReconciliation> reconcile(
    ToolCallRequest call,
    String idempotencyKey,
    TaskExternalJob? job,
    AgentCancellationToken token,
  ) => client.lookup(call, idempotencyKey, job, token);
}
