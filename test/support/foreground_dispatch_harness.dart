import 'dart:async';

import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/services/ai/provider_conversation_turn_router.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/repositories/conversation_turn_router.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';

import 'conversation_task_repository_harness.dart';
import 'foreground_turn_fixtures.dart';

export 'conversation_task_repository_harness.dart';
export 'foreground_turn_fixtures.dart';

final class ForegroundDispatchHarness {
  final storage = TaskRepositoryHarness();
  late SqliteMessageRepository messages;
  final drafts = ForegroundDrafts();
  final enqueuer = ForegroundEnqueuer();
  final tool = ForegroundTool();
  late ForegroundProviders providers;
  final mainProviders = <ForegroundProvider>[];
  late ConversationTurnDispatcher dispatcher;
  late PrepareTextGeneration prepare;
  final metrics = <TurnDispatchMetrics>[];
  String response = routeFrames('directReply', [
    {'text': '你好！'},
  ]);
  bool terminal = true;
  String stopReason = 'stop';
  bool preparationFails = false;
  bool preparedReliability = true;
  int preparations = 0;
  List<Message>? preparedHistory;
  List<ChatMessage>? contextOverride;
  Future<void> Function(Message)? onPrepare;

  Future<void> open() async {
    await storage.open();
    await seedTaskOrigin(storage.database, taskFixture());
    await storage.database.delete('messages');
    messages = SqliteMessageRepository(localDatabase: storage.local);
    providers = ForegroundProviders((bot) {
      final provider = ForegroundProvider(
        bot,
        events: () async* {
          yield TextDelta(response);
          yield const UsageReported(
            ModelTokenUsage(inputTokens: 5, outputTokens: 7),
          );
          if (terminal) yield ModelTurnCompleted(stopReason: stopReason);
        },
      );
      mainProviders.add(provider);
      return provider;
    });
    dispatcher = createDispatcher();
  }

  ConversationTurnDispatcher createDispatcher({
    ConversationTaskRepository? tasks,
    ConversationTurnRouter? router,
    ForegroundTurnGate? gate,
    Duration enqueueTimeout = const Duration(seconds: 1),
    bool Function(ExecutableTool)? supportsTaskTool,
  }) {
    prepare = PrepareTextGeneration(
      aiProviderRepository: providers,
      composeChatTurn: ({
        required bot,
        required history,
        required userMessage,
        required currentUserId,
        skillToolProvider,
      }) async {
        preparations++;
        preparedHistory = history;
        await onPrepare?.call(userMessage);
        if (preparationFails) throw StateError('private provider error');
        return PreparedChatTurn(
          messages:
              contextOverride ??
              [
                ChatMessage(
                  role: 'system',
                  content: 'Task context',
                  reasoning: 'private system thought',
                ),
                for (final message in history)
                  ChatMessage(
                    role: message.senderId == 'user' ? 'user' : 'assistant',
                    content: message.content,
                  ),
                ChatMessage(
                  role: 'user',
                  content: userMessage.content,
                  images: userMessage.images,
                  files: userMessage.files,
                ),
              ],
          activatedSkills: const [],
          requestedToolNames: {'read_file', 'missing_tool'},
          approvalExemptToolNames: {'read_file'},
          reliabilityPolicyEnabled: preparedReliability,
          preflightTokenUsage: const ModelTokenUsage(
            inputTokens: 2,
            outputTokens: 3,
          ),
        );
      },
    );
    return ConversationTurnDispatcher(
      prepare: prepare,
      router: router ?? ProviderConversationTurnRouter(providers: providers),
      messages: messages,
      drafts: drafts,
      tasks: tasks ?? storage.repository,
      enqueuer: enqueuer,
      toolRegistry: StaticToolRegistry([tool]),
      supportsTaskTool: supportsTaskTool ?? (_) => true,
      now: () => foregroundTime,
      gate: gate,
      enqueueTimeout: enqueueTimeout,
      onMetrics: metrics.add,
    );
  }

  int get mainCalls => mainProviders.fold(
    0,
    (total, provider) =>
        total +
        provider.sessions.fold(0, (total, session) => total + session.starts),
  );

  Future<void> close() async {
    await messages.dispose();
    await storage.close();
  }

  Future<int> count(String table) async =>
      (await storage.database.query(table)).length;

  void background({String draft = ''}) {
    response = routeFrames('backgroundTaskPlan', [
      foregroundPlan(draft: draft),
    ]);
  }
}

/// Simulates an acknowledgement lost after the real SQLite commit.
final class AmbiguousAcceptanceRepository
    implements ConversationTaskRepository {
  AmbiguousAcceptanceRepository(this.delegate);
  final ConversationTaskRepository delegate;
  int writes = 0;
  @override
  Future<ConversationTask?> getByOriginTurnId(String id) =>
      delegate.getByOriginTurnId(id);
  @override
  Future<TaskWriteResult<ConversationTask>> createWithAcknowledgement({
    required ConversationTask task,
    required ConversationTaskPlan plan,
    required ConversationTaskEvent initialEvent,
    required Message acknowledgement,
  }) async {
    writes++;
    await delegate.createWithAcknowledgement(
      task: task,
      plan: plan,
      initialEvent: initialEvent,
      acknowledgement: acknowledgement,
    );
    throw StateError('commit response lost');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
