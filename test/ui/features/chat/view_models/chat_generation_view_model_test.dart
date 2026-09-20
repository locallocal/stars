import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import '../../../../support/foreground_dispatch_harness.dart';
import '../../../../support/task_scheduler_harness.dart' show until;

void main() {
  late ForegroundDispatchHarness h;
  late ChatGenerationRegistry registry;
  late PresentConversationTaskProgress progress;
  setUp(() async {
    h = ForegroundDispatchHarness();
    await h.open();
    progress = PresentConversationTaskProgress(
      repository: h.storage.repository,
      newId: h.messages.createId,
    );
  });
  tearDown(() async {
    registry.clear();
    await progress.settle();
    await h.close();
  });
  ChatGenerationViewModel create() {
    registry = ChatGenerationRegistry(
      dispatcher: h.dispatcher,
      taskProgress: progress,
      providerFactory: h.providers.create,
    );
    return registry.viewModelFor('chat-1', foregroundBot());
  }

  Future<bool> send(ChatGenerationViewModel vm, [String turn = 'turn-1']) {
    final input = foregroundInput(turnId: turn);
    return vm.dispatchText(
      userMessage: input.userMessage,
      language: input.language,
      verification: input.verification,
    );
  }

  test(
    'direct text streams in memory and only a complete reply is saved',
    () async {
      final events = StreamController<ModelEvent>();
      h.providers = ForegroundProviders(
        (bot) => ForegroundProvider(bot, events: () => events.stream),
      );
      h.dispatcher = h.createDispatcher();
      final vm = create();
      final result = send(vm);
      events.add(const TextDelta('{"kind":"directReply"}\n{"text":"Hello"}\n'));
      await until(() => vm.snapshot.streamingResponse == 'Hello');
      expect(vm.contextAssemblyReport, isNotNull);
      expect(
        (await h.messages.getMessages(
          'chat-1',
        )).where((m) => m.senderId == 'bot-1'),
        isEmpty,
      );
      events.add(
        const UsageReported(ModelTokenUsage(inputTokens: 7, outputTokens: 11)),
      );
      events.add(const TextDelta('{"done":true}\n'));
      events.add(const ModelTurnCompleted());
      await events.close();
      expect(await result, isTrue);
      final messages = await h.messages.getMessages('chat-1');
      expect(
        messages.where((m) => m.taskMessageKind == TaskMessageKind.directReply),
        hasLength(1),
      );
      expect(messages.every((m) => !m.hasPartialContent), isTrue);
      expect(vm.snapshot.terminalMessage!.content, 'Hello');
      final saved = messages.singleWhere(
        (m) => m.messageId == vm.snapshot.terminalMessage!.messageId,
      );
      expect(vm.snapshot.tokenUsage.inputTokens, saved.tokenUsage.inputTokens);
      expect(
        vm.snapshot.tokenUsage.outputTokens,
        saved.tokenUsage.outputTokens,
      );
      expect(vm.snapshot.tokenUsage.outputTokens, 11);
      vm.acknowledgeTerminal();
      expect(vm.snapshot.lifecycle, ChatRunLifecycle.idle);
      expect(vm.snapshot.streamingResponse, isEmpty);
    },
  );
  test(
    'navigation cancellation discards partial text without writing a failed assistant',
    () async {
      final events = StreamController<ModelEvent>();
      final providers = <ForegroundProvider>[];
      h.providers = ForegroundProviders((bot) {
        final provider = ForegroundProvider(bot, events: () => events.stream);
        providers.add(provider);
        return provider;
      });
      h.dispatcher = h.createDispatcher();
      final vm = create();
      final result = send(vm);
      events.add(
        const TextDelta('{"kind":"directReply"}\n{"text":"Partial"}\n'),
      );
      await until(() => vm.snapshot.streamingResponse == 'Partial');
      expect(await vm.stopForNavigation(), isTrue);
      expect(await result, isFalse);
      expect(vm.snapshot.lifecycle, ChatRunLifecycle.cancelled);
      expect(vm.snapshot.streamingResponse, isEmpty);
      expect(vm.canRetryDispatch, isFalse);
      await until(() => providers.any((p) => p.sessions.any((s) => s.closed)));
      expect(await h.messages.getMessages('chat-1'), hasLength(1));
      events.add(const TextDelta('{"text":"late"}\n{"done":true}\n'));
      await events.close();
      expect(vm.snapshot.lifecycle, ChatRunLifecycle.cancelled);
    },
  );
  test(
    'bot changes wait for foreground completion and apply to the next turn',
    () async {
      final gate = Completer<void>();
      h.onPrepare = (_) => gate.future;
      final vm = create();
      final first = send(vm);
      await until(() => h.preparations == 1);
      final replacement = foregroundBot(model: 'replacement');
      vm.updateBot(replacement);
      expect(vm.capabilityProvider.bot.model, 'test-model');
      gate.complete();
      expect(await first, isTrue);
      expect(vm.capabilityProvider.bot, same(replacement));
      expect(await send(vm, 'turn-2'), isTrue);
      expect(h.mainProviders.last.bot.model, 'replacement');
    },
  );
  test(
    'disposing a stalled foreground drops late callbacks and releases its gate',
    () async {
      final gate = Completer<void>();
      h.onPrepare = (_) => gate.future;
      final vm = create();
      final first = send(vm);
      await until(() => h.preparations == 1);
      vm.dispose();
      expect(await first, isFalse);
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(h.mainCalls, 0);
      expect(h.dispatcher.isAccepting('chat-1'), isFalse);
    },
  );
  test(
    'media cancellation and non-cancellable navigation guards remain independent',
    () async {
      create();
      var cancellations = 0;
      registry.setCancellableExternalRun('media', () async {
        cancellations++;
        registry.setCancellableExternalRun('media', null);
        return true;
      });
      expect(registry.hasBlockingRun('media'), isTrue);
      expect(await registry.stopForNavigation('media'), isTrue);
      expect(cancellations, 1);
      expect(registry.hasBlockingRun('media'), isFalse);
      registry.setNonCancellableRunActive('media', true);
      expect(await registry.stopForNavigation('media'), isFalse);
      registry.setNonCancellableRunActive('media', false);
      expect(await registry.stopForNavigation('media'), isTrue);
    },
  );
}
