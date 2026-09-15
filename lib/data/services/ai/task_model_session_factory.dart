import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/provider_failure.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';

/// Binds a scheduler-resolved runtime bot to the accepted configuration.
/// The scheduler owns bot lookup; only this short-lived factory sees its key.
final class TaskProviderSessionFactory {
  const TaskProviderSessionFactory({
    required this.providers,
    required this.bot,
  });
  final AiProviderRepository providers;
  final Bot bot;

  AgentModelSession open(
    TaskAcceptanceSnapshot acceptance,
    ModelRequest request,
  ) {
    if (bot.apiType != acceptance.providerId ||
        bot.model != acceptance.modelId ||
        taskProviderConfigurationDigest(bot) !=
            acceptance.configurationDigest) {
      throw ProviderFailure.configuration(
        endpointKind: ProviderEndpointKind.unknown,
        code: 'task_provider_configuration_changed',
      );
    }
    final provider = providers.create(bot);
    if (!provider.capabilities.supportsAgentLoop) {
      throw ProviderFailure.configuration(
        endpointKind: ProviderEndpointKind.unknown,
        code: 'task_provider_session_unavailable',
      );
    }
    provider.setWebSearch(false);
    provider.setDeepThinking(false);
    return provider.openModelSession(request);
  }
}
