import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/chat_workflow_facade.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';

/// Joins conversation commands with the long-running generation lifecycle.
final class ChatInteractionFacade {
  const ChatInteractionFacade({
    required this.workflow,
    required this.messageActions,
    required this.generationRegistry,
    required this.generationViewModel,
  });

  final ChatWorkflowFacade workflow;
  final MessageActionViewModel messageActions;
  final ChatGenerationRegistry generationRegistry;
  final ChatGenerationViewModel generationViewModel;

  String get chatId => workflow.chatId;
  Bot get bot => workflow.bot;

  void updateBot(Bot bot) {
    workflow.updateBot(bot);
    generationViewModel.updateBot(bot);
  }

  Future<MediaTurnResult> generateMediaTurn(
    MediaTurnRequest request, {
    MediaUserPersisted? onUserPersisted,
  }) async {
    generationRegistry.setCancellableExternalRun(chatId, workflow.cancelMedia);
    try {
      return await workflow.generateMediaTurn(
        request,
        onUserPersisted: onUserPersisted,
      );
    } finally {
      generationRegistry.setCancellableExternalRun(chatId, null);
    }
  }

  bool get hasBlockingRun => generationRegistry.hasBlockingRun(chatId);

  bool get supportsRunCancellation =>
      generationRegistry.supportsCancellationForRun(chatId);

  Future<bool> stopActiveRun() => generationRegistry.stopForNavigation(chatId);
}
