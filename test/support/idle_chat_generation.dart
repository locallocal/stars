import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/repositories/conversation_turn_router.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'foreground_turn_fixtures.dart';

ChatGenerationRegistry idleChatGenerationRegistry({
  required ProviderFactory providerFactory,
}) => ChatGenerationRegistry(
  dispatcher: unusedForegroundDispatcher(),
  taskProgress: unusedTaskProgress(),
  providerFactory: providerFactory,
);

ConversationTurnDispatcher unusedForegroundDispatcher() =>
    ConversationTurnDispatcher(
      supportsTaskTool: (_) => false,
      prepare: PrepareTextGeneration(
        aiProviderRepository: ForegroundProviders(
          (_) => throw StateError('Unexpected provider'),
        ),
        composeChatTurn:
            ({
              required bot,
              required history,
              required userMessage,
              required currentUserId,
              skillToolProvider,
            }) => throw StateError('Unexpected preparation'),
      ),
      router: _UnusedRouter(),
      messages: _UnusedMessages(),
      drafts: ForegroundDrafts(),
      tasks: _UnusedTasks(),
      enqueuer: ForegroundEnqueuer(),
      toolRegistry: StaticToolRegistry(const []),
    );
PresentConversationTaskProgress unusedTaskProgress() =>
    PresentConversationTaskProgress(
      repository: _UnusedTasks(),
      newId: (_) => throw StateError('Unexpected status query'),
    );

final class _UnusedTasks implements ConversationTaskRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedMessages implements MessageRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedRouter implements ConversationTurnRouter {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
