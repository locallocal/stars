import 'package:stars/data/services/ai/task_model_session_factory.dart';
import 'package:stars/data/services/task_tool_adapters.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';
import 'package:stars/domain/use_cases/conversation_task_scheduler.dart';

/// Resolves current secure configuration at each segment; only the immutable
/// acceptance determines provider/model/prompt/tool scope. No key is persisted.
final class TaskRuntimeFactory {
  const TaskRuntimeFactory({
    required this.tasks,
    required this.bots,
    required this.providers,
    required this.registry,
    required this.policy,
    this.scopedTools,
    this.adapters = const {},
    this.clock = const SystemTaskRunnerClock(),
  });
  final ConversationTaskRepository tasks;
  final BotRepository bots;
  final AiProviderRepository providers;
  final ToolRegistry registry;
  final ToolPolicy policy;
  final Future<List<ExecutableTool>> Function(ConversationTask)? scopedTools;
  final Map<String, TaskToolAdapter> adapters;
  final TaskRunnerClock clock;

  Future<TaskSegmentExecutor> resolve(ConversationTask task) async {
    Bot? bot;
    final cancelling = task.cancelRequestedAt != null;
    if (!cancelling) {
      try {
        bot =
            (await bots.getBots(
              forceRefresh: true,
            )).where((bot) => bot.id == task.botId).firstOrNull;
      } on Object {
        throw const TaskRuntimeUnavailable(
          TaskWaitingReason.authentication,
          TaskReasonCode.missingCredentials,
        );
      }
      if (bot == null) {
        throw const TaskRuntimeUnavailable(
          TaskWaitingReason.requiredInput,
          TaskReasonCode.botUnavailable,
        );
      }
      if (bot.apiType != task.acceptance.providerId ||
          bot.model != task.acceptance.modelId ||
          taskProviderConfigurationDigest(bot) !=
              task.acceptance.configurationDigest) {
        throw const TaskRuntimeUnavailable(
          TaskWaitingReason.requiredInput,
          TaskReasonCode.providerUnavailable,
        );
      }
      if (bot.apiKey.trim().isEmpty && bot.apiType != Bot.apiTypeOllama) {
        throw const TaskRuntimeUnavailable(
          TaskWaitingReason.authentication,
          TaskReasonCode.missingCredentials,
        );
      }
      try {
        if (!providers.create(bot).capabilities.supportsAgentLoop) {
          throw const TaskRuntimeUnavailable(
            TaskWaitingReason.requiredInput,
            TaskReasonCode.providerUnavailable,
          );
        }
      } on TaskRuntimeUnavailable {
        rethrow;
      } on Object {
        throw const TaskRuntimeUnavailable(
          TaskWaitingReason.requiredInput,
          TaskReasonCode.providerUnavailable,
        );
      }
    }
    final snapshot = await tasks.getExecutionSnapshot(task.taskId);
    if (snapshot == null) {
      throw const TaskRuntimeUnavailable(
        TaskWaitingReason.requiredInput,
        TaskReasonCode.invalidPlan,
      );
    }
    // Acceptance freezes the candidate tool scope. Only the committed plan's
    // selected tools are execution dependencies, including after a restart.
    final requiredTools = snapshot.plan.allowedToolNames;
    final available = {
      for (final name in requiredTools)
        if (registry.find(name) case final tool?) name: tool,
      for (final tool in await scopedTools?.call(task) ?? <ExecutableTool>[])
        tool.definition.name: tool,
    };
    final resolved = <TaskToolAdapter>[];
    for (final name in requiredTools) {
      final supplied = adapters[name];
      if (supplied != null) {
        resolved.add(supplied);
        continue;
      }
      final tool = available[name];
      final arguments = taskCheckpointArguments[name];
      if (tool == null || arguments == null) {
        if (cancelling) continue;
        throw const TaskRuntimeUnavailable(
          TaskWaitingReason.requiredInput,
          TaskReasonCode.invalidPlan,
        );
      }
      resolved.add(
        SynchronousTaskToolAdapter(tool, checkpointArgumentNames: arguments),
      );
    }
    return ConversationTaskRunner(
      repository: tasks,
      sessions:
          bot == null
              ? (_, _) => throw StateError('cancel_has_no_model_session')
              : TaskProviderSessionFactory(providers: providers, bot: bot).open,
      tools: resolved,
      policy: policy,
      clock: clock,
    ).run;
  }
}
