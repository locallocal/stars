import 'dart:async';
import 'dart:convert';

import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/sqlite_chat_repository.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/conversation_history_repository.dart';
import 'package:stars/domain/repositories/mcp_inventory_repository.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/domain/repositories/skill_inventory_repository.dart';
import 'package:stars/domain/use_cases/create_user_message.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/domain/use_cases/persist_conversation_assets.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_dependencies.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/views/chat.dart';
import 'package:stars/ui/features/chat/views/message_input.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import '../../../../support/foreground_dispatch_harness.dart';
import '../../../../support/task_runner_harness.dart' show RunnerModels;
import '../../../../support/widget_test_support.dart'
    show shadHarness, withDesktopPlatform;

void main() {
  late ForegroundDispatchHarness h;
  late _Dependencies deps;
  late RunnerModels models;
  late Completer<void> backgroundGate;
  void compose() {
    final providers = ForegroundProviders(
      (bot) => _FlowProvider(bot, h, models),
    );
    final chats = SqliteChatRepository(localDatabase: h.storage.local);

    final tasks = createAppConversationTasks(
      database: h.storage.local,
      messages: h.messages,
      drafts: h.drafts,
      prepare: h.prepare,
      bots: _Bots(),
      chats: chats,
      providers: providers,
      registry: StaticToolRegistry([h.tool]),
      adapters: {
        h.tool.definition.name: SynchronousTaskToolAdapter(
          h.tool,
          checkpointArgumentNames: {"path"},
        ),
      },
      policy: const DefaultToolPolicy(),
      history: _History(),
      skills: _Skills(),
      mcp: _Mcp(),
    );
    deps = _Dependencies(h, chats, providers, tasks);
  }

  setUp(() async {
    h = ForegroundDispatchHarness();
    await h.open();
    h.background();
    backgroundGate = Completer<void>();
    models = RunnerModels();
    models.turns.add(() async* {
      await backgroundGate.future;
      yield const TextDelta('private draft');
      yield const ModelTurnCompleted();
    });
    models.completeStep();
    models.candidate(
      GroundedAnswerCandidate(nonFactualText: 'Final report ready'),
    );
    compose();
    await deps.conversationTasks.start();
    await h.messages.getMessagePage('chat-1');
  });
  tearDown(() async {
    if (!backgroundGate.isCompleted) backgroundGate.complete();
    await deps.conversationTasks.dispose();
    await deps.conversationTasks.progress.settle();
    deps.generationRegistry.clear();
    await deps.chatRepository.dispose();
    await h.close();
  });
  test(
    'production composition resumes a persisted checkpoint after database restart',
    () async {
      // Complete the first plan step before the second model turn is interrupted.
      models.turns.addFirst(() async* {
        yield const TextDelta('first step private draft');
        yield const ModelTurnCompleted();
      });
      await deps.conversationTasks.dispatcher.dispatch(foregroundInput());
      await _until(() async => models.requests.length == 2);
      final task =
          (await deps.conversationTasks.repository.listActiveForChat(
            'chat-1',
          )).single;
      await deps.conversationTasks.dispose();
      await deps.conversationTasks.progress.settle();
      final before =
          (await deps.conversationTasks.repository.getExecutionSnapshot(
            task.taskId,
          ))!;
      expect(before.checkpoint!.completedStepIds, ['read']);
      expect(before.task.cancelRequestedAt, isNull);
      expect(before.task.status.isTerminal, isFalse);
      deps.generationRegistry.clear();
      await deps.chatRepository.dispose();
      await h.messages.dispose();
      await h.storage.reopen();
      h.messages = SqliteMessageRepository(localDatabase: h.storage.local);
      // Fresh providers and production dependencies have no old model session.
      models =
          RunnerModels()
            ..completeStep()
            ..candidate(
              GroundedAnswerCandidate(nonFactualText: 'Recovered report'),
            );
      compose();
      await deps.conversationTasks.start();
      await _until(
        () async =>
            (await deps.conversationTasks.repository.getById(
              task.taskId,
            ))!.status.isTerminal,
      );
      final after =
          (await deps.conversationTasks.repository.getExecutionSnapshot(
            task.taskId,
          ))!;
      expect(after.task.status, ConversationTaskStatus.succeeded);
      expect(after.checkpoint!.completedStepIds, ['read', 'write']);
      expect(
        models.requests,
        hasLength(2),
      ); // Remaining step, then grounded synthesis.
      expect(
        models.requests.first.messages.map((m) => m.content).join('\n'),
        contains('read'),
      );
      final messages = await h.messages.getMessages('chat-1');
      expect(
        messages.where(
          (m) => m.senderId == foregroundInput().userMessage.senderId,
        ),
        hasLength(1),
      );
      expect(
        messages.where(
          (m) => m.taskMessageKind == TaskMessageKind.acknowledgement,
        ),
        hasLength(1),
      );
      expect(
        messages.where((m) => m.taskMessageKind == TaskMessageKind.result),
        hasLength(1),
      );
      expect(messages.last.content, 'Recovered report');
      expect(
        messages.map((m) => m.content).join(),
        isNot(contains('private draft')),
      );
      await deps.conversationTasks.scheduler.tick();
      expect((await h.messages.getMessages('chat-1')).length, messages.length);
    },
  );
  Widget page({String key = 'first'}) => AppScope(
    dependencies: deps,
    child: shadHarness(
      brightness: Brightness.light,
      homeBuilder:
          (_) => Scaffold(
            body: ChatPage(
              key: ValueKey(key),
              id: 'chat-1',
              bot: foregroundBot(),
            ),
          ),
    ),
  );
  testWidgets(
    'routing failure preserves history and reports generation failure',
    (tester) async {
      await withDesktopPlatform(() async {
        tester.view.physicalSize = const Size(1200, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        h.response = 'invalid routing response';
        await tester.pumpWidget(page());
        await _drive(tester);
        final input = tester.widget<MessageInput>(find.byType(MessageInput));
        input.controller.text = 'Hello';
        input.onSend();
        final alert = find.byKey(
          const ValueKey('chat-generation-error-message'),
        );
        await _drive(tester, until: () => alert.evaluate().isNotEmpty);
        final strings = S.of(tester.element(alert));
        expect(tester.widget<Text>(alert).data, strings.generationFailed);
        expect(find.text(strings.errorLoadingContent), findsNothing);
        expect(
          find.byKey(const ValueKey('chat-history-error-alert')),
          findsNothing,
        );
        expect(
          tester
              .widget<MessageInput>(find.byType(MessageInput))
              .requestInProgress,
          isFalse,
        );
        final vm = deps.generationRegistry.maybeViewModel('chat-1')!;
        expect(vm.canRetryDispatch, isTrue);

        h.response = routeFrames('directReply', [
          {'text': 'Recovered reply'},
        ]);
        final retry = vm.retryDispatch();
        await _drive(
          tester,
          until: () => find.text('Recovered reply').evaluate().isNotEmpty,
        );
        expect(await retry, isTrue);
        expect(alert, findsNothing);
        final messages =
            (await tester.runAsync(() => h.messages.getMessages('chat-1')))!;
        expect(
          messages.where((message) => message.content == 'Hello'),
          hasLength(1),
        );
        expect(
          messages.where(
            (message) => message.taskMessageKind == TaskMessageKind.directReply,
          ),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await _drive(tester);
      });
    },
  );

  testWidgets(
    'production composition keeps chat usable across page rebuild and delivers terminal once',
    (tester) async {
      await withDesktopPlatform(() async {
        tester.view.physicalSize = const Size(1200, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(page());
        await _drive(tester);
        var input = tester.widget<MessageInput>(find.byType(MessageInput));
        input.controller.text = 'Prepare report';
        input.onSend();
        await _drive(
          tester,
          until:
              () =>
                  models.requests.isNotEmpty &&
                  !deps.generationRegistry.hasBlockingRun('chat-1'),
          diagnostic: () async {
            final snapshot =
                deps.generationRegistry.maybeViewModel('chat-1')!.snapshot;
            final tasks = await h.storage.repository.listActiveForChat(
              'chat-1',
            );
            return 'foreground=${snapshot.lifecycle} error=${snapshot.error} tasks=${tasks.map((t) => '${t.status}/${t.waitingReason}')} messages=${(await h.messages.getMessagePage('chat-1')).messages.map((m) => m.content)}';
          },
        );
        input = tester.widget<MessageInput>(find.byType(MessageInput));
        expect(input.requestInProgress, isFalse);
        expect(backgroundGate.isCompleted, isFalse);
        final task =
            (await tester.runAsync(
              () => h.storage.repository.listActiveForChat('chat-1'),
            ))!.single;
        await tester.runAsync(
          () => deps.conversationTasks.progress(
            chatId: 'chat-1',
            botId: task.botId,
            language: 'en',
            taskId: task.taskId,
          ),
        );
        await _drive(
          tester,
          until:
              () => tester
                  .widget<MessageList>(find.byType(MessageList))
                  .messages
                  .any(
                    (m) =>
                        m.taskMessageKind == TaskMessageKind.status &&
                        m.content.contains('\n\n'),
                  ),
        );
        final status = tester
            .widget<MessageList>(find.byType(MessageList))
            .messages
            .singleWhere((m) => m.taskMessageKind == TaskMessageKind.status);
        expect(
          status.taskStatusSummaries.single.summaryRevision,
          status.summaryRevision,
        );
        expect(status.taskId, task.taskId);
        expect(deps.conversationTasks.progress.narrate.metrics.fallbacks, 0);
        h.response = routeFrames('directReply', [
          {'text': 'Hello while working'},
        ]);
        input.controller.text = 'Hello';
        input.onSend();
        await _drive(
          tester,
          until: () => find.text('Hello while working').evaluate().isNotEmpty,
        );
        expect(find.text('Hello while working'), findsOneWidget);
        await tester.pumpWidget(page(key: 'rebuilt'));
        await _drive(tester);
        expect(
          tester
              .widget<MessageInput>(find.byType(MessageInput))
              .requestInProgress,
          isFalse,
        );
        expect(
          (await tester.runAsync(
            () => h.storage.repository.getById(task.taskId),
          ))!.cancelRequestedAt,
          isNull,
        );
        backgroundGate.complete();
        await _drive(
          tester,
          until:
              () =>
                  find.byType(MessageList).evaluate().isNotEmpty &&
                  tester
                      .widget<MessageList>(find.byType(MessageList))
                      .messages
                      .any((m) => m.taskMessageKind == TaskMessageKind.result),
        );
        final displayed =
            tester.widget<MessageList>(find.byType(MessageList)).messages;
        expect(
          displayed.where((m) => m.taskMessageKind == TaskMessageKind.result),
          hasLength(1),
        );
        expect(displayed.last.content, 'Final report ready');
        expect(
          displayed.where((m) => m.taskMessageKind == TaskMessageKind.status),
          hasLength(1),
        );
        expect(
          displayed
              .singleWhere((m) => m.taskMessageKind == TaskMessageKind.status)
              .content,
          status.content,
        );
        expect(
          displayed.last.timestamp.isAfter(
            displayed
                .singleWhere((m) => m.content == 'Hello while working')
                .timestamp,
          ),
          isTrue,
        );
        expect(
          tester
              .widget<MessageInput>(find.byType(MessageInput))
              .requestInProgress,
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await _drive(tester);
      });
    },
  );
}

// SQLite FFI uses a real isolate while WidgetTester schedules UI continuations
// in its fake clock. Drive both queues without advancing the UI by minutes.
Future<void> _drive(
  WidgetTester tester, {
  bool Function()? until,
  Future<String> Function()? diagnostic,
}) async {
  for (var i = 0; i < 200; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    if (until != null && until() || until == null && i >= 12) {
      await tester.pump();
      return;
    }
  }
  fail(
    'Conversation UI did not reach the expected committed state: ${diagnostic == null ? '' : await tester.runAsync(diagnostic)}',
  );
}

class _FlowProvider extends AiProvider {
  _FlowProvider(super.bot, this.h, this.models);
  final ForegroundDispatchHarness h;
  final RunnerModels models;
  @override
  Future<void> generateText(List<ChatMessage> messages) async =>
      throw StateError("Legacy generation must not run");
  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );
  @override
  ForegroundRoutingTransport get foregroundRoutingTransport =>
      ForegroundRoutingTransport.modelSession;
  @override
  AgentModelSession openModelSession(ModelRequest request) {
    if (request.options.foregroundRouting) {
      return ForegroundModelSession(
        request,
        () => Stream.fromIterable([
          TextDelta(h.response),
          const ModelTurnCompleted(),
        ]),
      );
    }
    if (request.messages.first.content.startsWith('Return JSON')) {
      final payload =
          jsonDecode(request.messages.last.content) as Map<String, dynamic>;
      final summary = payload['summary'] as Map<String, dynamic>;
      return ForegroundModelSession(
        request,
        () => Stream.fromIterable([
          TextDelta(
            jsonEncode({
              'taskId': summary['taskId'],
              'summaryRevision': summary['summaryRevision'],
              'content': (payload['allowedNarrations'] as List).last,
            }),
          ),
          const ModelTurnCompleted(),
        ]),
      );
    }
    return models.open(taskAcceptance(), request);
  }
}

class _History implements ConversationHistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Skills implements SkillInventoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Mcp implements McpInventoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bots implements BotRepository {
  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async => [
    foregroundBot(),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Attachments implements ConversationAssetRepository {
  @override
  Future<List<String>> persistAssets({
    required String chatId,
    required Iterable<String> sourcePaths,
  }) async {
    expectSync(sourcePaths, isEmpty);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Actions implements MessageActionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Dependencies implements AppDependencies {
  _Dependencies(
    this.h,
    this.chatRepository,
    this.aiProviderRepository,
    this.conversationTasks,
  ) {
    generationRegistry = ChatGenerationRegistry(
      dispatcher: conversationTasks.dispatcher,
      taskProgress: conversationTasks.progress,
      providerFactory: aiProviderRepository.create,
    );
  }
  final ForegroundDispatchHarness h;
  @override
  final SqliteChatRepository chatRepository;
  @override
  final AiProviderRepository aiProviderRepository;
  @override
  final AppConversationTasks conversationTasks;
  @override
  late final ChatGenerationRegistry generationRegistry;
  @override
  SqliteMessageRepository get messageRepository => h.messages;
  @override
  ForegroundDrafts get conversationDraftRepository => h.drafts;
  @override
  AttachmentRepository get attachmentRepository => _Attachments();
  @override
  MessageActionRepository get messageActionRepository => _Actions();
  @override
  SqliteToolEvidenceRepository get toolEvidenceRepository =>
      SqliteToolEvidenceRepository(localDatabase: h.storage.local);
  @override
  CreateUserMessage get createUserMessage =>
      CreateUserMessage(messageRepository: h.messages);
  @override
  PersistConversationAssets get persistConversationAssets =>
      PersistConversationAssets(repository: attachmentRepository);
  @override
  GenerateMediaTurn get generateMediaTurn => GenerateMediaTurn(
    messageRepository: h.messages,
    chatRepository: chatRepository,
    providerRepository: aiProviderRepository,
    attachmentRepository: attachmentRepository,
    persistConversationAssets: persistConversationAssets,
  );
  @override
  PrepareTextGeneration get prepareTextGeneration => h.prepare;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _until(Future<bool> Function() condition) async {
  for (var i = 0; i < 300; i++) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Production task did not reach its expected persisted state.');
}
