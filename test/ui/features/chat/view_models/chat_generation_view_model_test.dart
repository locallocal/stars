import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/model/model.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';

void main() {
  group('ChatGenerationViewModel', () {
    test('completed terminal is idempotent and ignores late tokens', () async {
      final harness = _ControllerHarness(cancellable: true);
      final controller = harness.controller;
      addTearDown(controller.dispose);

      expect(
        await controller.startText(
          userMessage: _userMessage(),
          messages: <ChatMessage>[ChatMessage(role: 'user', content: 'Hello')],
        ),
        isTrue,
      );
      final provider = harness.runProvider;
      provider.emitToken('answer');
      provider.emitTerminal(ProviderTerminalType.completed);
      await _waitFor(
        () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
      );

      provider.emitTerminal(ProviderTerminalType.completed);
      provider.emitToken(' too late');
      await _flushAsyncWork();

      expect(controller.snapshot.lifecycle, ChatRunLifecycle.completed);
      expect(controller.snapshot.streamingResponse, 'answer');
      expect(controller.snapshot.terminalMessage?.content, 'answer');
      expect(
        harness.persisted.where((message) => message.senderId == _bot.id),
        hasLength(1),
      );
      expect(harness.lastMessages, <String>['Hello', 'answer']);
    });

    test('cancellation persists partial content as cancelled', () async {
      final harness = _ControllerHarness(cancellable: true);
      final controller = harness.controller;
      addTearDown(controller.dispose);

      expect(
        await controller.startText(
          userMessage: _userMessage(),
          messages: <ChatMessage>[ChatMessage(role: 'user', content: 'Hello')],
        ),
        isTrue,
      );
      final provider = harness.runProvider;
      provider.emitToken('partial');

      expect(await controller.cancel(), ChatRunLifecycle.cancelled);

      final terminal = controller.snapshot.terminalMessage;
      expect(provider.cancelRequests, 1);
      expect(controller.snapshot.lifecycle, ChatRunLifecycle.cancelled);
      expect(terminal, isNotNull);
      expect(terminal!.content, 'partial');
      expect(terminal.terminalOutcome, MessageTerminalOutcome.cancelled);
      expect(terminal.hasPartialContent, isTrue);
      expect(harness.lastMessages, <String>['Hello', 'partial']);
    });

    test('cancellation during submit never starts the provider', () async {
      final factory = _FakeProviderFactory(cancellable: true);
      final userPersist = Completer<Message>();
      final controller = ChatGenerationViewModel(
        chatId: 'chat-1',
        bot: _bot,
        providerFactory: factory.create,
        messagePersister: (message) => userPersist.future,
        lastMessageUpdater: (_, _) async {},
      );
      addTearDown(controller.dispose);

      final start = controller.startText(
        userMessage: _userMessage(),
        messages: <ChatMessage>[ChatMessage(role: 'user', content: 'Hello')],
      );
      await _flushAsyncWork();
      expect(controller.snapshot.lifecycle, ChatRunLifecycle.submitting);

      final cancellation = controller.cancel(
        timeout: const Duration(seconds: 1),
      );
      expect(controller.snapshot.lifecycle, ChatRunLifecycle.stopping);
      expect(factory.instances.last.cancelRequests, 0);

      userPersist.complete(_userMessage());
      expect(await cancellation, ChatRunLifecycle.cancelled);
      expect(await start, isFalse);
      expect(factory.instances.last.generateCalls, 0);
      expect(controller.snapshot.userPersisted, isTrue);
    });

    test('chat preview failure does not roll back a persisted user', () async {
      final factory = _FakeProviderFactory(cancellable: true);
      final persisted = <Message>[];
      final controller = ChatGenerationViewModel(
        chatId: 'chat-1',
        bot: _bot,
        providerFactory: factory.create,
        messagePersister: (message) async {
          persisted.add(message);
          return message;
        },
        lastMessageUpdater: (_, _) async => throw StateError('preview'),
      );
      addTearDown(controller.dispose);

      expect(
        await controller.startText(
          userMessage: _userMessage(),
          messages: <ChatMessage>[ChatMessage(role: 'user', content: 'Hello')],
        ),
        isTrue,
      );

      expect(controller.snapshot.userPersisted, isTrue);
      expect(controller.snapshot.lifecycle, ChatRunLifecycle.active);
      expect(persisted, hasLength(1));
    });

    test(
      'late tokens are ignored while terminal persistence is pending',
      () async {
        final factory = _FakeProviderFactory(cancellable: true);
        final terminalPersist = Completer<Message>();
        final controller = ChatGenerationViewModel(
          chatId: 'chat-1',
          bot: _bot,
          providerFactory: factory.create,
          messagePersister: (message) async {
            if (message.senderId == _bot.id) return terminalPersist.future;
            return message;
          },
          lastMessageUpdater: (_, _) async {},
        );
        addTearDown(controller.dispose);

        await controller.startText(
          userMessage: _userMessage(),
          messages: <ChatMessage>[ChatMessage(role: 'user', content: 'Hello')],
        );
        final provider = factory.instances.last;
        provider.emitToken('kept');
        provider.emitTerminal(ProviderTerminalType.completed);
        await _flushAsyncWork();
        provider.emitToken(' discarded');
        expect(controller.snapshot.streamingResponse, 'kept');

        terminalPersist.complete(
          Message(
            messageId: 'assistant',
            chatId: 'chat-1',
            botId: _bot.id,
            senderId: _bot.id,
            content: 'kept',
            timestamp: _timestamp,
          ),
        );
        await _waitFor(
          () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
        );
        expect(controller.snapshot.terminalMessage?.content, 'kept');
      },
    );

    test(
      'completed empty response persists an empty-response terminal',
      () async {
        final harness = _ControllerHarness(cancellable: true);
        final controller = harness.controller;
        addTearDown(controller.dispose);

        expect(
          await controller.startText(
            userMessage: _userMessage(),
            messages: <ChatMessage>[
              ChatMessage(role: 'user', content: 'Hello'),
            ],
          ),
          isTrue,
        );
        harness.runProvider.emitTerminal(ProviderTerminalType.completed);
        await _waitFor(
          () => controller.snapshot.lifecycle == ChatRunLifecycle.emptyResponse,
        );

        final terminal = controller.snapshot.terminalMessage;
        expect(terminal, isNotNull);
        expect(terminal!.content, isEmpty);
        expect(terminal.terminalOutcome, MessageTerminalOutcome.emptyResponse);
        expect(terminal.hasPartialContent, isFalse);
        expect(
          harness.persisted.where((message) => message.senderId == _bot.id),
          hasLength(1),
        );
        expect(harness.lastMessages, <String>['Hello']);
      },
    );

    test('non-cancellable generation blocks navigation', () async {
      final harness = _ControllerHarness(cancellable: false);
      final controller = harness.controller;
      addTearDown(controller.dispose);

      expect(
        await controller.startText(
          userMessage: _userMessage(),
          messages: <ChatMessage>[ChatMessage(role: 'user', content: 'Hello')],
        ),
        isTrue,
      );

      expect(await controller.stopForNavigation(), isFalse);
      expect(harness.runProvider.cancelRequests, 0);
      expect(controller.snapshot.lifecycle, ChatRunLifecycle.active);
      expect(controller.hasBlockingRun, isTrue);
    });

    test('registry blocks navigation for a non-text generation', () async {
      final registry = ChatGenerationRegistry(
        messagePersister: (message) async => message,
        lastMessageUpdater: (_, _) async {},
        providerFactory: _FakeProviderFactory(cancellable: true).create,
      );
      addTearDown(registry.clear);

      registry.setNonCancellableRunActive('media-chat', true);
      expect(registry.hasBlockingRun('media-chat'), isTrue);
      expect(await registry.stopForNavigation('media-chat'), isFalse);

      registry.setNonCancellableRunActive('media-chat', false);
      expect(registry.hasBlockingRun('media-chat'), isFalse);
      expect(await registry.stopForNavigation('media-chat'), isTrue);
    });
  });
}

final _bot = Bot(
  id: 'bot-1',
  name: 'Test bot',
  avatar: '',
  provider: 'test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: _timestamp,
  modifyTimestamp: _timestamp,
);

final _timestamp = DateTime.fromMillisecondsSinceEpoch(1);

Message _userMessage() => Message(
  chatId: 'chat-1',
  botId: _bot.id,
  senderId: 'user-1',
  content: 'Hello',
  timestamp: _timestamp,
);

class _ControllerHarness {
  _ControllerHarness({required bool cancellable})
    : factory = _FakeProviderFactory(cancellable: cancellable) {
    controller = ChatGenerationViewModel(
      chatId: 'chat-1',
      bot: _bot,
      providerFactory: factory.create,
      messagePersister: (message) async {
        persisted.add(message);
        return message;
      },
      lastMessageUpdater: (chatId, content) async {
        expect(chatId, 'chat-1');
        lastMessages.add(content);
      },
    );
  }

  final _FakeProviderFactory factory;
  final List<Message> persisted = <Message>[];
  final List<String> lastMessages = <String>[];
  late final ChatGenerationViewModel controller;

  _FakeProvider get runProvider {
    expect(factory.instances, hasLength(2));
    return factory.instances.last;
  }
}

class _FakeProviderFactory {
  _FakeProviderFactory({required this.cancellable});

  final bool cancellable;
  final List<_FakeProvider> instances = <_FakeProvider>[];

  AiProvider create(Bot bot) {
    final provider = _FakeProvider(bot, cancellable: cancellable);
    instances.add(provider);
    return provider;
  }
}

class _FakeProvider extends AiProvider {
  _FakeProvider(super.bot, {required this.cancellable});

  final bool cancellable;
  final Completer<void> _generation = Completer<void>();
  int cancelRequests = 0;
  int generateCalls = 0;

  @override
  bool get supportsCancellation => cancellable;

  @override
  Future<void> generateText(List<ChatMessage> messages) {
    generateCalls += 1;
    return _generation.future;
  }

  void emitToken(String token) => onResponse(token);

  void emitTerminal(ProviderTerminalType type) {
    onTerminal?.call(ProviderTerminalEvent(type: type));
    if (!_generation.isCompleted) _generation.complete();
  }

  @override
  Future<ProviderCancellationResult> cancelRequest() async {
    cancelRequests += 1;
    if (!cancellable) {
      return const ProviderCancellationResult(
        ProviderCancellationStatus.unsupported,
      );
    }
    isCancelled = true;
    emitTerminal(ProviderTerminalType.cancelled);
    return const ProviderCancellationResult(
      ProviderCancellationStatus.requested,
    );
  }
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    if (predicate()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the generation state to settle.');
}

Future<void> _flushAsyncWork() async {
  for (var turn = 0; turn < 5; turn += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}
