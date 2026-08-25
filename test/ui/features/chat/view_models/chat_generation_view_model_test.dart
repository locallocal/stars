import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';

void main() {
  group('ChatGenerationViewModel', () {
    test(
      'dispose cancels an active run without publishing terminal state',
      () async {
        final harness = _ControllerHarness(cancellable: true);
        final controller = harness.controller;

        expect(
          await controller.startText(
            userMessage: _userMessage(),
            messages: <ChatMessage>[
              ChatMessage(role: 'user', content: 'Hello'),
            ],
          ),
          isTrue,
        );
        final provider = harness.runProvider;
        expect(controller.snapshot.lifecycle, ChatRunLifecycle.active);

        controller.dispose();
        provider.emitToken('too late');
        await _flushAsyncWork();

        expect(provider.cancelRequests, 1);
        expect(controller.snapshot.lifecycle, ChatRunLifecycle.active);
        expect(controller.snapshot.streamingResponse, isEmpty);
        controller.dispose();
      },
    );

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

    test(
      'registry keeps generating and persists incremental drafts after detach',
      () async {
        final factory = _FakeProviderFactory(cancellable: true);
        final stored = <String, Message>{};
        final lastMessages = <String>[];
        final registry = ChatGenerationRegistry(
          messagePersister: (message) async {
            stored[message.messageId] = message;
            return message;
          },
          lastMessageUpdater: (_, content) async {
            lastMessages.add(content);
          },
          providerFactory: factory.create,
          messageIdFactory: (prefix) => '$prefix-fixed',
          partialPersistenceInterval: Duration.zero,
        );
        addTearDown(registry.clear);
        final controller = registry.viewModelFor('chat-1', _bot);
        void pageListener() {}
        controller.addListener(pageListener);

        expect(
          await controller.startText(
            userMessage: _userMessage(),
            messages: <ChatMessage>[
              ChatMessage(role: 'user', content: 'Hello'),
            ],
          ),
          isTrue,
        );
        controller.removeListener(pageListener);

        final provider = factory.instances.last;
        provider.emitToken('incremental');
        await _waitFor(
          () => stored['run-fixed:assistant']?.content == 'incremental',
        );

        final partial = stored['run-fixed:assistant'];
        expect(partial, isNotNull);
        expect(partial!.terminalOutcome, isNull);
        expect(partial.hasPartialContent, isTrue);
        expect(controller.snapshot.lifecycle, ChatRunLifecycle.active);

        provider.emitToken(' response');
        await _waitFor(
          () =>
              stored['run-fixed:assistant']?.content == 'incremental response',
        );

        final returnedController = registry.viewModelFor('chat-1', _bot);
        expect(returnedController, same(controller));
        expect(returnedController.snapshot.userPersisted, isTrue);
        expect(
          returnedController.snapshot.submittedUserMessage?.messageId,
          'run-fixed:user',
        );
        expect(
          returnedController.snapshot.streamingResponse,
          'incremental response',
        );

        provider.emitTerminal(ProviderTerminalType.completed);
        await _waitFor(
          () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
        );

        final completed = stored['run-fixed:assistant'];
        expect(completed?.content, 'incremental response');
        expect(completed?.terminalOutcome, MessageTerminalOutcome.completed);
        expect(completed?.hasPartialContent, isFalse);
        expect(lastMessages, <String>['Hello', 'incremental response']);
      },
    );

    test(
      'provider token usage is attached once to the terminal message',
      () async {
        final harness = _ControllerHarness(cancellable: true);
        final controller = harness.controller;
        addTearDown(controller.dispose);

        await controller.startText(
          userMessage: _userMessage(),
          messages: <ChatMessage>[ChatMessage(role: 'user', content: 'Hello')],
        );
        final provider = harness.runProvider;
        provider.emitUsage(
          const ModelTokenUsage(
            model: 'test-model',
            inputTokens: 120,
            outputTokens: 30,
            totalTokens: 150,
          ),
        );
        provider.emitToken('answer');
        provider.emitTerminal(ProviderTerminalType.completed);
        await _waitFor(
          () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
        );

        final assistantMessages = harness.persisted.where(
          (message) => message.senderId == _bot.id,
        );
        expect(assistantMessages, hasLength(1));
        expect(assistantMessages.single.tokenUsage.inputTokens, 120);
        expect(assistantMessages.single.tokenUsage.outputTokens, 30);
        expect(assistantMessages.single.tokenUsage.effectiveTotalTokens, 150);
      },
    );

    test('persists the exact activated Skill identity for the run', () async {
      final factory = _FakeProviderFactory(cancellable: true);
      final activations = <SkillActivationRecord>[];
      final persisted = <Message>[];
      final controller = ChatGenerationViewModel(
        chatId: 'chat-1',
        bot: _bot,
        providerFactory: factory.create,
        messageIdFactory: (prefix) => '$prefix-fixed',
        messagePersister: (message) async {
          persisted.add(message);
          return message;
        },
        lastMessageUpdater: (_, _) async {},
        skillActivationPersister: (records) async {
          activations.addAll(records);
        },
      );
      addTearDown(controller.dispose);

      expect(
        await controller.startText(
          userMessage: _userMessage().copyWith(
            processInfo: const MessageProcessInfo(
              fileEdits: [
                MessageFileEdit(
                  path: '/tmp/spec.md',
                  type: 'file',
                  status: 'attached',
                ),
              ],
            ),
          ),
          messages: <ChatMessage>[ChatMessage(role: 'user', content: 'Hello')],
          activatedSkills: const [
            ActivatedSkill(
              id: 'user:release-notes',
              name: 'release-notes',
              contentDigest: 'abc123',
              trigger: SkillActivationTrigger.model,
            ),
          ],
          skillToolCalls: const [
            MessageToolCall(
              name: 'activate_skill',
              status: 'completed',
              detail: 'release-notes',
            ),
          ],
        ),
        isTrue,
      );

      expect(persisted, hasLength(1));
      final user = persisted.single;
      expect(user.senderId, 'user-1');
      expect(user.processInfo.fileEdits, hasLength(1));
      expect(user.processInfo.toolCalls, isEmpty);
      expect(user.processInfo.skillActivations, isEmpty);
      expect(controller.snapshot.toolCalls.single.name, 'activate_skill');
      expect(controller.snapshot.skillActivations.single.name, 'release-notes');

      expect(activations, hasLength(1));
      expect(activations.single.runId, 'run-fixed');
      expect(activations.single.messageId, 'run-fixed:assistant');
      expect(activations.single.chatId, 'chat-1');
      expect(activations.single.skillId, 'user:release-notes');
      expect(activations.single.skillName, 'release-notes');
      expect(activations.single.contentDigest, 'abc123');
      expect(activations.single.trigger, SkillActivationTrigger.model);
      expect(activations.single.status, SkillActivationStatus.activated);

      final provider = factory.instances.last;
      provider.emitToken('done');
      provider.emitTerminal(ProviderTerminalType.completed);
      await _waitFor(
        () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
      );

      final assistant = persisted.last;
      expect(assistant.senderId, _bot.id);
      expect(assistant.processInfo.fileEdits, isEmpty);
      expect(assistant.processInfo.toolCalls.single.name, 'activate_skill');
      expect(
        assistant.processInfo.skillActivations.single.name,
        'release-notes',
      );
    });

    test(
      'persists activation attempts and includes preflight token usage',
      () async {
        final factory = _FakeProviderFactory(cancellable: true);
        final activations = <SkillActivationRecord>[];
        final persisted = <Message>[];
        final controller = ChatGenerationViewModel(
          chatId: 'chat-1',
          bot: _bot,
          providerFactory: factory.create,
          messageIdFactory: (prefix) => '$prefix-fixed',
          messagePersister: (message) async {
            persisted.add(message);
            return message;
          },
          lastMessageUpdater: (_, _) async {},
          skillActivationPersister: (records) async {
            activations.addAll(records);
          },
        );
        addTearDown(controller.dispose);
        final now = DateTime(2026, 7, 28);

        await controller.startText(
          userMessage: _userMessage(),
          messages: <ChatMessage>[ChatMessage(role: 'user', content: 'Hello')],
          activationAttempts: [
            SkillActivationAttempt(
              skillId: 'user:auto',
              skillName: 'auto',
              contentDigest: 'digest',
              trigger: SkillActivationTrigger.model,
              status: SkillActivationStatus.failed,
              startedAt: now,
              completedAt: now,
              errorCode: 'load_failed',
            ),
          ],
          preflightTokenUsage: const ModelTokenUsage(
            model: 'test-model',
            inputTokens: 40,
            outputTokens: 5,
            totalTokens: 45,
          ),
        );

        expect(activations.single.status, SkillActivationStatus.failed);
        expect(activations.single.errorCode, 'load_failed');
        final provider = factory.instances.last;
        provider.emitUsage(
          const ModelTokenUsage(
            model: 'test-model',
            inputTokens: 100,
            outputTokens: 20,
            totalTokens: 120,
          ),
        );
        provider.emitToken('answer');
        provider.emitTerminal(ProviderTerminalType.completed);
        await _waitFor(
          () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
        );

        final assistant = persisted.last;
        expect(assistant.tokenUsage.inputTokens, 140);
        expect(assistant.tokenUsage.outputTokens, 25);
        expect(assistant.tokenUsage.effectiveTotalTokens, 165);
      },
    );

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

    test(
      'slow turn preparation is immediately cancellable and never starts provider',
      () async {
        final harness = _ControllerHarness(cancellable: false);
        final controller = harness.controller;
        final preparation = Completer<PreparedTextGeneration>();
        addTearDown(controller.dispose);

        final start = controller.startTextWithPreparation(
          userMessage: _userMessage(),
          prepare: (_) => preparation.future,
        );
        await _flushAsyncWork();

        expect(controller.snapshot.lifecycle, ChatRunLifecycle.submitting);
        expect(controller.snapshot.canCancel, isTrue);
        expect(await controller.cancel(), ChatRunLifecycle.cancelled);
        expect(controller.snapshot.userPersisted, isFalse);
        expect(harness.persisted, isEmpty);
        expect(harness.runProvider.generateCalls, 0);

        preparation.complete(
          PreparedTextGeneration(
            userMessage: _userMessage(),
            messages: <ChatMessage>[
              ChatMessage(role: 'user', content: 'Hello'),
            ],
          ),
        );
        expect(await start, isFalse);
        expect(harness.runProvider.generateCalls, 0);
        expect(harness.persisted, isEmpty);
      },
    );

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

    test('registry cancels a non-text generation for navigation', () async {
      final registry = ChatGenerationRegistry(
        messagePersister: (message) async => message,
        lastMessageUpdater: (_, _) async {},
        providerFactory: _FakeProviderFactory(cancellable: true).create,
      );
      addTearDown(registry.clear);

      var cancellations = 0;
      registry.setCancellableExternalRun('media-chat', () async {
        cancellations += 1;
        return true;
      });
      expect(registry.hasBlockingRun('media-chat'), isTrue);
      expect(registry.supportsCancellationForRun('media-chat'), isTrue);
      expect(await registry.stopForNavigation('media-chat'), isTrue);
      expect(cancellations, 1);

      registry.setCancellableExternalRun('media-chat', null);
      expect(registry.hasBlockingRun('media-chat'), isFalse);
      expect(await registry.stopForNavigation('media-chat'), isTrue);
    });

    test(
      'agent loop exposes approval and persists structured tool state',
      () async {
        final tool = _ViewModelTool();
        final factory = _AgentProviderFactory();
        final persisted = <Message>[];
        final toolAudits = <MessageToolCall>[];
        final controller = ChatGenerationViewModel(
          chatId: 'chat-1',
          bot: _bot,
          providerFactory: factory.create,
          messagePersister: (message) async {
            persisted.add(message);
            return message;
          },
          lastMessageUpdater: (_, _) async {},
          toolInvocationPersister: (_, _, _, audit) async {
            toolAudits.add(audit);
          },
          toolRegistry: StaticToolRegistry([tool]),
        );
        addTearDown(controller.dispose);

        expect(
          await controller.startText(
            userMessage: _userMessage(),
            messages: [ChatMessage(role: 'user', content: 'Save it')],
            requestedToolNames: const {'mcp.notes.save_note'},
          ),
          isTrue,
        );
        await _waitFor(() => controller.snapshot.pendingToolApproval != null);
        expect(
          controller.snapshot.toolCalls.single.status,
          ToolInvocationStatus.awaitingApproval.name,
        );

        controller.resolveToolApproval(ToolApprovalDecision.allowOnce);
        await _waitFor(
          () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
        );

        expect(tool.executions, 1);
        expect(controller.snapshot.pendingToolApproval, isNull);
        expect(controller.snapshot.streamingResponse, 'Saved.');
        expect(controller.snapshot.toolCalls.single.callId, 'save-1');
        expect(
          controller.snapshot.toolCalls.single.status,
          ToolInvocationStatus.succeeded.name,
        );
        expect(
          controller.snapshot.toolCalls.single.argumentsSummary,
          contains('"api_token":"[redacted]"'),
        );
        expect(
          controller.snapshot.toolCalls.single.argumentsSummary,
          contains('[text:140 chars]'),
        );
        final assistant = persisted.last;
        expect(assistant.content, 'Saved.');
        expect(
          assistant.processInfo.toolCalls.single.name,
          'mcp.notes.save_note',
        );
        expect(assistant.processInfo.toolCalls.single.title, 'Save note');
        expect(assistant.processInfo.toolCalls.single.mcpServerName, 'Notes');
        expect(
          assistant.processInfo.toolCalls.single.approvalStatus,
          ToolApprovalDecision.allowOnce.name,
        );
        await _flushAsyncWork();
        expect(toolAudits, isNotEmpty);
        expect(
          toolAudits.every(
            (audit) => !audit.argumentsSummary.contains('do-not-persist'),
          ),
          isTrue,
        );
        expect(
          toolAudits.last.argumentsSummary,
          contains('"api_token":"[redacted]"'),
        );
      },
    );

    test('successful local file tools attach artifacts to the reply', () async {
      final tool = _LocalFileArtifactTool();
      final factory = _AgentProviderFactory(
        toolName: writeLocalFileToolName,
        arguments: const {
          'path': '  /tmp/generated-report.md  ',
          'content': '# Report',
        },
      );
      final persisted = <Message>[];
      final controller = ChatGenerationViewModel(
        chatId: 'chat-1',
        bot: _bot,
        providerFactory: factory.create,
        messagePersister: (message) async {
          persisted.add(message);
          return message;
        },
        lastMessageUpdater: (_, _) async {},
        toolRegistry: StaticToolRegistry([tool]),
      );
      addTearDown(controller.dispose);

      expect(
        await controller.startText(
          userMessage: _userMessage(),
          messages: [ChatMessage(role: 'user', content: 'Create a report')],
          requestedToolNames: const {writeLocalFileToolName},
        ),
        isTrue,
      );
      await _waitFor(() => controller.snapshot.pendingToolApproval != null);
      controller.resolveToolApproval(ToolApprovalDecision.allowOnce);
      await _waitFor(
        () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
      );

      expect(controller.snapshot.localFiles, ['/tmp/generated-report.md']);
      expect(persisted.last.files, ['/tmp/generated-report.md']);

      controller.acknowledgeTerminal();
      expect(controller.snapshot.localFiles, isEmpty);
    });

    test(
      'shell command is recorded in process info while audit stays hashed',
      () async {
        const command = 'printf detailed-command';
        const workingDirectory = '/private/shell-workspace';
        final tool = _ShellAuditTool();
        final factory = _AgentProviderFactory(
          toolName: shellCommandToolName,
          arguments: const {
            'command': command,
            'working_directory': workingDirectory,
            'timeout_seconds': 8,
          },
        );
        final toolAudits = <MessageToolCall>[];
        final persisted = <Message>[];
        final controller = ChatGenerationViewModel(
          chatId: 'chat-1',
          bot: _bot,
          providerFactory: factory.create,
          messagePersister: (message) async {
            persisted.add(message);
            return message;
          },
          lastMessageUpdater: (_, _) async {},
          toolInvocationPersister: (_, _, _, audit) async {
            toolAudits.add(audit);
          },
          toolRegistry: StaticToolRegistry([tool]),
          toolPolicy: const DefaultToolPolicy(allowProcessExecution: true),
        );
        addTearDown(controller.dispose);

        expect(
          await controller.startText(
            userMessage: _userMessage(),
            messages: [ChatMessage(role: 'user', content: 'Run it')],
            requestedToolNames: shellCommandToolNames,
          ),
          isTrue,
        );
        await _waitFor(() => controller.snapshot.pendingToolApproval != null);
        expect(controller.snapshot.commandExecutions, hasLength(1));
        expect(controller.snapshot.commandExecutions.single.callId, 'save-1');
        expect(controller.snapshot.commandExecutions.single.command, command);
        expect(
          controller.snapshot.commandExecutions.single.status,
          ToolInvocationStatus.awaitingApproval.name,
        );
        controller.resolveToolApproval(ToolApprovalDecision.allowOnce);
        await _waitFor(
          () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
        );
        await _flushAsyncWork();

        expect(tool.executions, 1);
        expect(controller.snapshot.commandExecutions, hasLength(1));
        expect(controller.snapshot.commandExecutions.single.command, command);
        expect(
          controller.snapshot.commandExecutions.single.status,
          ToolInvocationStatus.succeeded.name,
        );
        final assistant = persisted.last;
        expect(assistant.processInfo.commandExecutions, hasLength(1));
        expect(assistant.processInfo.commandExecutions.single.command, command);
        expect(toolAudits, isNotEmpty);
        for (final audit in toolAudits) {
          expect(audit.argumentsSummary, contains('"command_hash"'));
          expect(audit.argumentsSummary, contains('"command_characters":23'));
          expect(audit.argumentsSummary, contains('"working_directory_hash"'));
          expect(audit.argumentsSummary, contains('"timeout_seconds":8'));
          expect(audit.argumentsSummary, isNot(contains(command)));
          expect(audit.argumentsSummary, isNot(contains(workingDirectory)));
        }
      },
    );

    test('add MCP server audit never persists connection secrets', () async {
      const endpoint = 'https://example.com/mcp?credential=do-not-persist';
      const command = '/private/do-not-persist/server';
      final tool = _AddMcpServerAuditTool();
      final factory = _AgentProviderFactory(
        toolName: addMcpServerToolName,
        arguments: const {
          'name': 'Private MCP',
          'transport_type': 'stdio',
          'endpoint': endpoint,
          'auth_type': 'oauth_access_token',
          'access_token': 'do-not-persist-token',
          'command': command,
          'arguments': ['--token', 'do-not-persist-argument'],
          'environment': {'CUSTOM_CREDENTIAL': 'do-not-persist-environment'},
          'connect': true,
        },
      );
      final toolAudits = <MessageToolCall>[];
      final controller = ChatGenerationViewModel(
        chatId: 'chat-1',
        bot: _bot,
        providerFactory: factory.create,
        messagePersister: (message) async => message,
        lastMessageUpdater: (_, _) async {},
        toolInvocationPersister: (_, _, _, audit) async {
          toolAudits.add(audit);
        },
        toolRegistry: StaticToolRegistry([tool]),
        toolPolicy: const DefaultToolPolicy(allowProcessExecution: true),
      );
      addTearDown(controller.dispose);

      expect(
        await controller.startText(
          userMessage: _userMessage(),
          messages: [ChatMessage(role: 'user', content: 'Add it')],
          requestedToolNames: addMcpServerToolNames,
        ),
        isTrue,
      );
      await _waitFor(() => controller.snapshot.pendingToolApproval != null);
      controller.resolveToolApproval(ToolApprovalDecision.allowOnce);
      await _waitFor(
        () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
      );
      await _flushAsyncWork();

      expect(tool.executions, 1);
      expect(toolAudits, isNotEmpty);
      for (final audit in toolAudits) {
        expect(audit.argumentsSummary, contains('"endpoint_hash"'));
        expect(audit.argumentsSummary, contains('"command_hash"'));
        expect(audit.argumentsSummary, contains('"argument_count":2'));
        expect(
          audit.argumentsSummary,
          contains('"environment_variable_count":1'),
        );
        expect(audit.argumentsSummary, isNot(contains(endpoint)));
        expect(audit.argumentsSummary, isNot(contains(command)));
        expect(audit.argumentsSummary, isNot(contains('do-not-persist')));
      }
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

  void emitUsage(ModelTokenUsage usage) => onTokenUsage?.call(usage);

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

final class _ViewModelTool implements ExecutableTool {
  @override
  final ToolDefinition definition = ToolDefinition(
    name: 'mcp.notes.save_note',
    title: 'Save note',
    mcpServerName: 'Notes',
    description: 'Save a note on the device.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'value': {'type': 'string'},
        'api_token': {'type': 'string'},
        'body': {'type': 'string'},
      },
      'required': ['value'],
      'additionalProperties': false,
    },
    source: ToolSource.mcp,
    riskLevel: ToolRiskLevel.write,
    capabilities: const {ToolCapability.network, ToolCapability.externalWrite},
  );

  int executions = 0;

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    executions += 1;
    return ToolResult(callId: call.callId, name: call.name, content: 'saved');
  }
}

final class _ShellAuditTool implements ExecutableTool {
  @override
  final ToolDefinition definition = ToolDefinition(
    name: shellCommandToolName,
    title: 'Shell command',
    description: 'Run a native shell command.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'command': {'type': 'string'},
        'working_directory': {'type': 'string'},
        'timeout_seconds': {'type': 'integer'},
      },
      'required': ['command'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.destructive,
    capabilities: const {ToolCapability.process},
  );

  int executions = 0;

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    executions += 1;
    return ToolResult(callId: call.callId, name: call.name, content: 'done');
  }
}

final class _LocalFileArtifactTool implements ExecutableTool {
  @override
  final ToolDefinition definition = ToolDefinition(
    name: writeLocalFileToolName,
    title: 'Write local file',
    description: 'Write an artifact to a local file.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'content': {'type': 'string'},
      },
      'required': ['path', 'content'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.write,
    capabilities: const {ToolCapability.localWrite},
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    return ToolResult(callId: call.callId, name: call.name, content: 'written');
  }
}

final class _AddMcpServerAuditTool implements ExecutableTool {
  @override
  final ToolDefinition definition = ToolDefinition(
    name: addMcpServerToolName,
    title: 'Add MCP server',
    description: 'Add an MCP server.',
    inputSchema: const {'type': 'object', 'additionalProperties': true},
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.write,
    capabilities: const {ToolCapability.localWrite, ToolCapability.process},
  );

  int executions = 0;

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    executions += 1;
    return ToolResult(callId: call.callId, name: call.name, content: 'added');
  }
}

final class _AgentProviderFactory {
  _AgentProviderFactory({String? toolName, Map<String, Object?>? arguments})
    : toolName = toolName ?? 'mcp.notes.save_note',
      arguments =
          arguments ??
          {
            'value': 'hello',
            'api_token': 'do-not-persist',
            'body': List.filled(140, 'x').join(),
          };

  final String toolName;
  final Map<String, Object?> arguments;

  AiProvider create(Bot bot) =>
      _AgentProvider(bot, toolName: toolName, arguments: arguments);
}

final class _AgentProvider extends AiProvider {
  _AgentProvider(super.bot, {required this.toolName, required this.arguments});

  final String toolName;
  final Map<String, Object?> arguments;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  AgentModelSession openModelSession(ModelRequest request) {
    return _ViewModelAgentSession(toolName: toolName, arguments: arguments);
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) {
    throw StateError('Legacy generation must not be used.');
  }
}

final class _ViewModelAgentSession implements AgentModelSession {
  _ViewModelAgentSession({required this.toolName, required this.arguments});

  final String toolName;
  final Map<String, Object?> arguments;

  @override
  Stream<ModelEvent> start() => Stream.fromIterable([
    ToolCallRequested(callId: 'save-1', name: toolName, arguments: arguments),
    const ModelTurnCompleted(stopReason: 'tool_calls'),
  ]);

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) {
    expect(results.single.isError, isFalse);
    return Stream.fromIterable([
      const TextDelta('Saved.'),
      const ModelTurnCompleted(stopReason: 'stop'),
    ]);
  }

  @override
  Future<void> cancel() async {}

  @override
  void close() {}
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
