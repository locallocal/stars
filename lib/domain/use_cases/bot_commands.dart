import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

final class BotDraft {
  const BotDraft({
    required this.id,
    required this.name,
    required this.avatar,
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.apiType,
    required this.model,
    required this.systemPrompt,
    required this.supportsMcp,
    required this.supportsAutomaticSkillActivation,
    required this.mcpServerIds,
    required this.mcpTools,
    required this.createdAt,
    required this.modifiedAt,
    this.supportsSkills,
    this.contextWindowTokens,
    this.inputModalities = const [],
    this.outputModalities = const [],
  });

  final String id;
  final String name;
  final String avatar;
  final String provider;
  final String baseUrl;
  final String apiKey;
  final String apiType;
  final String model;
  final String systemPrompt;
  final bool supportsMcp;
  final bool supportsAutomaticSkillActivation;
  final bool? supportsSkills;
  final int? contextWindowTokens;
  final List<InputModality> inputModalities;
  final List<OutputModality> outputModalities;
  final Set<String> mcpServerIds;
  final Set<McpToolConfiguration> mcpTools;
  final DateTime createdAt;
  final DateTime modifiedAt;
}

/// Converts form state into the single current Bot persistence shape.
final class BuildBot {
  const BuildBot();

  Bot call(BotDraft draft) => Bot(
    id: draft.id,
    name: draft.name.trim(),
    avatar: draft.avatar,
    provider: draft.provider.trim(),
    baseURL: draft.baseUrl.trim(),
    apiKey: draft.apiKey.trim(),
    apiType: draft.apiType.trim(),
    model: draft.model.trim(),
    systemPrompt: draft.systemPrompt.trim(),
    parameters: {
      Bot.parameterSupportsMcp: draft.supportsMcp,
      Bot.parameterSupportsAutomaticSkillActivation:
          draft.supportsAutomaticSkillActivation,
      if (draft.supportsSkills != null)
        Bot.parameterSupportsSkills: draft.supportsSkills,
      if (draft.contextWindowTokens != null)
        Bot.parameterContextWindowTokens: draft.contextWindowTokens,
      if (draft.inputModalities.isNotEmpty)
        Bot.parameterInputModalities: [
          for (final modality in draft.inputModalities) modality.value,
        ],
      if (draft.outputModalities.isNotEmpty)
        Bot.parameterOutputModalities: [
          for (final modality in draft.outputModalities) modality.value,
        ],
      Bot.parameterMcpServers:
          draft.supportsMcp
              ? (draft.mcpServerIds.toList()..sort())
              : const <String>[],
      Bot.parameterMcpTools:
          draft.supportsMcp
              ? ((draft.mcpTools.toList()
                    ..sort((left, right) => left.key.compareTo(right.key)))
                  .map((configuration) => configuration.toMap())
                  .toList(growable: false))
              : const <Map<String, Object?>>[],
    },
    createTimestamp: draft.createdAt,
    modifyTimestamp: draft.modifiedAt,
  );
}

final class CreateBot {
  const CreateBot({
    required BotRepository repository,
    BotSkillBindingRepository? bindingRepository,
  }) : _repository = repository,
       _bindingRepository = bindingRepository;

  final BotRepository _repository;
  final BotSkillBindingRepository? _bindingRepository;

  Future<void> call(
    Bot bot, {
    List<BotSkillBinding> skillBindings = const [],
  }) async {
    final repository = _repository;
    if (repository is BotAggregateRepository) {
      await repository.addBotWithSkillBindings(bot, skillBindings);
      return;
    }
    await repository.addBot(bot);
    if (skillBindings.isEmpty) return;
    final bindings = _bindingRepository;
    if (bindings == null) {
      await repository.deleteBot(bot.id);
      throw StateError('No Bot Skill binding repository was configured.');
    }
    try {
      for (final binding in skillBindings) {
        await bindings.save(binding);
      }
    } on Object {
      await repository.deleteBot(bot.id);
      rethrow;
    }
  }
}

final class UpdateBot {
  const UpdateBot({required BotRepository repository})
    : _repository = repository;

  final BotRepository _repository;

  Future<void> call(Bot bot) => _repository.updateBot(bot);
}

final class DeleteBot {
  const DeleteBot({
    required BotRepository repository,
    ConversationTaskRepository? tasks,
  }) : _repository = repository,
       _tasks = tasks;

  final BotRepository _repository;
  final ConversationTaskRepository? _tasks;

  Future<void> call(String id) async {
    final tasks = _tasks;
    if (tasks != null) {
      String? cursor;
      do {
        final page = await tasks.listRecoverable(afterTaskId: cursor);
        if (page.isEmpty) break;
        if (page.any((task) => task.botId == id)) {
          throw const AppFailure.validation('bot_has_active_tasks');
        }
        cursor = page.last.taskId;
      } while (true);
    }
    await _repository.deleteBot(id);
  }
}
