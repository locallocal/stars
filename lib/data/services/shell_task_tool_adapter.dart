import 'package:stars/data/services/tools/shell_command_tool.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';

/// Bounded shell execution under the runner's durable approval and attempt log.
/// A process may change external state before it loses its result, so interrupted
/// attempts require reconciliation and must never be automatically replayed.
final class ShellTaskToolAdapter implements TaskToolAdapter {
  const ShellTaskToolAdapter(this.tool);

  final ShellCommandTool tool;

  @override
  ToolDefinition get definition => tool.definition;

  @override
  Set<String> get checkpointArgumentNames => const {
    'command',
    'working_directory',
    'timeout_seconds',
  };

  @override
  bool get guaranteesIdempotency => false;

  @override
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String idempotencyKey,
    AgentCancellationToken cancellation,
  ) async => ToolCompleted(await tool.execute(call, cancellation));

  @override
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken cancellation,
  ) => Future.error(StateError('Bounded shell commands have no external job.'));

  @override
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken cancellation,
  ) async => const ToolOutcomeUnknown();

  @override
  Future<ToolReconciliation> reconcile(
    ToolCallRequest call,
    String idempotencyKey,
    TaskExternalJob? job,
    AgentCancellationToken cancellation,
  ) async => const ToolOutcomeUnknown();
}
