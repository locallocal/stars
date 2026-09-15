import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/repositories/conversation_turn_router.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';

import '../../support/foreground_dispatch_harness.dart';

void main() {
  late ForegroundDispatchHarness h;
  setUp(() async {
    h = ForegroundDispatchHarness();
    await h.open();
  });
  tearDown(() async {
    await h.close();
  });

  test(
    'unsupported tools are hidden from routing and cannot create a task',
    () async {
      final dispatcher = h.createDispatcher(supportsTaskTool: (_) => false);
      h.background();
      final failed =
          await dispatcher.dispatch(foregroundInput()) as TurnDispatchFailed;
      expect(failed.context.acceptance!.allowedToolNames, isEmpty);
      expect(failed.code, TurnDispatchFailureCode.routingFailed);
      expect(await h.count('conversation_tasks'), 0);
      expect(await h.count('messages'), 1);
      expect(h.enqueuer.calls, isEmpty);
      expect(h.tool.calls, 0);
    },
  );

  test(
    'direct replies remain available when no background tools are supported',
    () async {
      final dispatcher = h.createDispatcher(supportsTaskTool: (_) => false);
      final result =
          await dispatcher.dispatch(foregroundInput()) as TurnDirectReplySaved;
      expect(result.context.acceptance!.allowedToolNames, isEmpty);
      expect(result.message.content, '你好！');
    },
  );

  test(
    'acceptance retries recheck tool support before committing the saved plan',
    () async {
      var available = true;
      final dispatcher = h.createDispatcher(supportsTaskTool: (_) => available);
      h.background();
      await h.storage.failWrite('conversation_task_events');
      final failed =
          await dispatcher.dispatch(foregroundInput()) as TurnDispatchFailed;
      await h.storage.clearFailure();
      available = false;
      final rejected =
          await dispatcher.retry(failed.retry!) as TurnDispatchFailed;
      expect(rejected.code, TurnDispatchFailureCode.routingFailed);
      expect(await h.count('conversation_tasks'), 0);
      expect(await h.count('messages'), 1);
      expect(h.enqueuer.calls, isEmpty);
      expect(h.mainCalls, 1);
      h.response = routeFrames('backgroundTaskPlan', [
        {...foregroundPlan(), 'allowedToolNames': <String>[]},
      ]);
      final accepted =
          await dispatcher.retry(rejected.retry!) as TurnTaskAccepted;
      final snapshot =
          (await h.storage.repository.getExecutionSnapshot(
            accepted.task.taskId,
          ))!;
      expect(snapshot.task.acceptance.allowedToolNames, isEmpty);
      expect(snapshot.plan.allowedToolNames, isEmpty);
      expect(h.mainCalls, 2);
    },
  );

  for (final content in ['你好', '解释一下递归，不需要外部资料', '把上面的句子改得更简洁']) {
    test('direct reply with tools available: $content', () async {
      final input = foregroundInput(content: content);
      final updates = <TurnDispatchUpdate>[];
      final result =
          await h.dispatcher.dispatch(input, onUpdate: updates.add)
              as TurnDirectReplySaved;
      expect(h.preparations, 1);
      expect(h.mainCalls, 1);
      expect(h.tool.calls, 0);
      expect(result.context.prepared, isNotNull);
      expect(result.context.acceptance!.allowedToolNames, {'read_file'});
      expect(h.mainProviders.last.sessions.single.request.tools, isEmpty);
      expect(result.message.messageId, 'turn-1:assistant');
      expect(result.message.taskMessageKind, TaskMessageKind.directReply);
      expect(result.message.taskId, isNull);
      expect(result.message.hasPartialContent, isFalse);
      expect(result.message.processInfo.toolCalls, isEmpty);
      expect(result.message.reasoning, isEmpty);
      expect(result.message.grounding.trustLevel, AnswerTrustLevel.unverified);
      expect(result.message.grounding.reasonCode, 'no_tool_evidence');
      expect(result.message.tokenUsage.effectiveTotalTokens, 17);
      expect(await h.count('messages'), 2);
      expect(await h.count('conversation_tasks'), 0);
      expect(h.enqueuer.calls, isEmpty);
      expect(updates.map((e) => e.context.turnId).toSet(), {'turn-1'});
      expect(updates.first.event, isA<TurnDispositionStarted>());
      expect(result.metrics.mainReplyCalls, 1);
      expect(result.metrics.preparationCalls, 1);
      expect(result.metrics.preflightUsage.effectiveTotalTokens, 5);
      expect(result.metrics.directFirstCharacterLatency, isNotNull);
      expect(
        result.metrics.directCompletionLatency,
        greaterThanOrEqualTo(result.metrics.directFirstCharacterLatency!),
      );
      expect(h.dispatcher.isAccepting('chat-1'), isFalse);
    });
  }

  test(
    'duplicate direct submission after completion reuses the final message',
    () async {
      final input = foregroundInput();
      final first = await h.dispatcher.dispatch(input) as TurnDirectReplySaved;
      h.response = routeFrames('backgroundTaskPlan', [foregroundPlan()]);
      final second = await h.dispatcher.dispatch(input) as TurnDirectReplySaved;
      expect(second.reused, isTrue);
      expect(second.message.messageId, first.message.messageId);
      expect(second.metrics.mainReplyCalls, 0);
      expect(h.mainCalls, 1);
      expect(await h.count('messages'), 2);
      expect(await h.count('conversation_tasks'), 0);
    },
  );

  test('empty direct response has empty terminal trust, no task', () async {
    h.response = routeFrames('directReply', []);
    final result =
        await h.dispatcher.dispatch(foregroundInput()) as TurnDirectReplySaved;
    expect(
      result.message.terminalOutcome,
      MessageTerminalOutcome.emptyResponse,
    );
    expect(result.message.grounding.reasonCode, 'empty_response');
    expect(result.message.content, isEmpty);
    expect(result.message.hasPartialContent, isFalse);
  });

  test(
    'task, plan, initial facts and acknowledgement are visible before enqueue',
    () async {
      const draft = '这份报告需要一些时间，已经记录。完成后我会发送完整的结果。';
      h.background(draft: draft);
      h.enqueuer.onEnqueue = (taskId) async {
        expect(h.dispatcher.isAccepting('chat-1'), isTrue);
        final task = await h.storage.repository.getById(taskId);
        expect(task!.status, ConversationTaskStatus.queued);
        expect(await h.count('conversation_task_plans'), 1);
        expect(await h.count('conversation_task_events'), 1);
        expect(await h.count('conversation_task_progress'), 1);
        final messages = await h.messages.getMessages('chat-1');
        expect(
          messages
              .singleWhere((message) => message.messageId == task.ackMessageId)
              .content,
          draft,
        );
      };
      final updates = <TurnDispatchUpdate>[];
      final input = foregroundInput(files: ['artifact:report']);
      final result =
          await h.dispatcher.dispatch(input, onUpdate: updates.add)
              as TurnTaskAccepted;
      expect(result.notificationDelivered, isTrue);
      expect(result.task.originTurnId, input.userMessage.turnId);
      expect(result.task.originUserMessageId, input.userMessage.messageId);
      expect(result.task.progress.modelTurns, 0);
      expect(result.task.progress.totalSteps, 2);
      expect(result.task.acceptance.context.last.assetReferences, [
        'artifact:report',
      ]);
      expect(result.task.acceptance.segmentLimits.maxModelTurns, 7);
      expect(result.task.verificationPolicy.strictGroundingEnabled, isTrue);
      expect(h.mainCalls, 1);
      expect(h.tool.calls, 0);
      expect(result.metrics.acknowledgementCommitLatency, isNotNull);
      expect(result.metrics.acknowledgementFallbacks, 0);
      expect(updates.length, 1);
      expect(updates.single.event, isA<TurnDispositionStarted>());
      expect(h.dispatcher.isAccepting('chat-1'), isFalse);
    },
  );

  test(
    'unsafe acknowledgement uses local fallback in the same transaction',
    () async {
      h.background(draft: '报告已完成，工具调用成功，30 秒后发送。');
      final result =
          await h.dispatcher.dispatch(foregroundInput()) as TurnTaskAccepted;
      final ack = (await h.messages.getMessages('chat-1')).singleWhere(
        (message) => message.messageId == result.task.ackMessageId,
      );
      expect(ack.messageId, result.task.ackMessageId);
      expect(ack.content, '“整理报告”需要一些时间，已经记录。完成后我会发送完整的结果。');
      expect(result.metrics.acknowledgementFallbacks, 1);
      expect(h.mainCalls, 1);
    },
  );

  test(
    'acceptance failure publishes no ack and retries the original plan/turn',
    () async {
      h.background();
      await h.storage.failWrite('conversation_task_events');
      final input = foregroundInput();
      final updates = <TurnDispatchUpdate>[];
      final failed =
          await h.dispatcher.dispatch(input, onUpdate: updates.add)
              as TurnDispatchFailed;
      expect(failed.code, TurnDispatchFailureCode.taskCreationFailed);
      expect(failed.userPersisted, isTrue);
      expect(failed.draftToRestore, isNull);
      expect(await h.count('messages'), 1);
      expect(await h.count('conversation_tasks'), 0);
      expect(h.enqueuer.calls, isEmpty);
      expect(
        updates.where((update) => update.event is DirectReplyDelta),
        isEmpty,
      );
      expect(h.dispatcher.isAccepting('chat-1'), isFalse);
      await h.storage.clearFailure();
      h.response = 'changed response must not be requested';
      final success =
          await h.dispatcher.retry(failed.retry!) as TurnTaskAccepted;
      expect(success.task.originTurnId, input.userMessage.turnId);
      expect(h.mainCalls, 1);
      expect(h.preparations, 1);
      expect(success.metrics.mainReplyCalls, 0);
      expect(success.metrics.acknowledgementFallbacks, 0);
      expect(await h.count('messages'), 2);
      final duplicate = await h.dispatcher.dispatch(input) as TurnTaskAccepted;
      expect(duplicate.task.taskId, success.task.taskId);
      expect(duplicate.reused, isTrue);
      expect(await h.count('conversation_tasks'), 1);
      expect(await h.count('messages'), 2);
    },
  );

  test(
    'lost commit response is reconciled from durable origin identity',
    () async {
      h.background();
      final repository = AmbiguousAcceptanceRepository(h.storage.repository);
      final dispatcher = h.createDispatcher(tasks: repository);
      final failed =
          await dispatcher.dispatch(foregroundInput()) as TurnDispatchFailed;
      expect(await h.count('messages'), 2);
      expect(h.enqueuer.calls, isEmpty);
      final accepted =
          await dispatcher.retry(failed.retry!) as TurnTaskAccepted;
      expect(accepted.reused, isTrue);
      expect(repository.writes, 1);
      expect(h.mainCalls, 1);
      expect(await h.count('conversation_tasks'), 1);
    },
  );

  test(
    'lost enqueue notification leaves a queued task recoverable after reopen',
    () async {
      h.background();
      h.enqueuer.onEnqueue = (_) async => throw StateError('notification lost');
      final result =
          await h.dispatcher.dispatch(foregroundInput()) as TurnTaskAccepted;
      expect(result.notificationDelivered, isFalse);
      await h.storage.reopen();
      final due = await h.storage.repository.listDue(now: foregroundTime);
      expect(due.single.taskId, result.task.taskId);
      expect(due.single.status, ConversationTaskStatus.queued);
      expect(
        (await h.storage.repository.listRecoverable()).single.taskId,
        result.task.taskId,
      );
    },
  );

  test(
    'save failure restores text and attachments without a model call',
    () async {
      await h.storage.failWrite('messages');
      final input = foregroundInput(
        images: ['image.png'],
        files: ['report.pdf'],
      );
      final failed = await h.dispatcher.dispatch(input) as TurnDispatchFailed;
      expect(failed.code, TurnDispatchFailureCode.userPersistenceFailed);
      expect(failed.userPersisted, isFalse);
      expect(failed.draftRestored, isTrue);
      expect(failed.draftToRestore!.text, input.userMessage.content);
      expect(h.drafts.values['chat-1']!.imagePaths, ['image.png']);
      expect(h.drafts.values['chat-1']!.filePaths, ['report.pdf']);
      expect(h.mainCalls, 0);
      expect(h.preparations, 0);
      await h.storage.clearFailure();
      final result = await h.dispatcher.retry(failed.retry!);
      expect(result, isA<TurnDirectReplySaved>());
      expect(h.drafts.values, isEmpty);
      expect(await h.count('messages'), 2);
    },
  );

  test('failed draft store still returns draft restoration material', () async {
    await h.storage.failWrite('messages');
    h.drafts.failWrite = true;
    final result =
        await h.dispatcher.dispatch(foregroundInput()) as TurnDispatchFailed;
    expect(result.draftRestored, isFalse);
    expect(result.draftToRestore!.text, '整理报告');
  });

  test('preparation failure retries saved user without duplication', () async {
    h.preparationFails = true;
    final failed =
        await h.dispatcher.dispatch(foregroundInput()) as TurnDispatchFailed;
    expect(failed.code, TurnDispatchFailureCode.preparationFailed);
    expect(await h.count('messages'), 1);
    h.preparationFails = false;
    await h.dispatcher.retry(failed.retry!);
    expect(h.mainCalls, 1);
    expect(await h.count('messages'), 2);
    expect(h.preparedHistory, isEmpty);
  });

  test(
    'reply commit failure retries text without another main reply call',
    () async {
      await h.storage.failWrite('messages', when: "NEW.sender_id = 'bot-1'");
      final failed =
          await h.dispatcher.dispatch(foregroundInput()) as TurnDispatchFailed;
      expect(failed.code, TurnDispatchFailureCode.replyPersistenceFailed);
      expect(await h.count('messages'), 1);
      await h.storage.clearFailure();
      final result =
          await h.dispatcher.retry(failed.retry!) as TurnDirectReplySaved;
      expect(result.message.messageId, 'turn-1:assistant');
      expect(h.mainCalls, 1);
      expect(await h.count('messages'), 2);
    },
  );

  for (final malformed in [
    'not json',
    routeFrames('backgroundTaskPlan', [
      {
        ...foregroundPlan(),
        'allowedToolNames': ['shell'],
      },
    ]),
    routeFrames('backgroundTaskPlan', [foregroundPlan()], done: false),
  ]) {
    test(
      'bad route creates no task or assistant and returns original retry',
      () async {
        h.response = malformed;
        final result =
            await h.dispatcher.dispatch(foregroundInput())
                as TurnDispatchFailed;
        expect(result.code, TurnDispatchFailureCode.routingFailed);
        expect(result.routingFailure, TurnRoutingFailure.invalidProtocol);
        expect(result.metrics.routingFallbacks, 1);
        expect(result.retry!.input.userMessage.turnId, 'turn-1');
        expect(await h.count('conversation_tasks'), 0);
        expect(await h.count('messages'), 1);
        expect(h.enqueuer.calls, isEmpty);
      },
    );
  }

  test(
    'interrupted direct stream never persists partial assistant text',
    () async {
      h.terminal = false;
      final updates = <TurnDispatchUpdate>[];
      final result =
          await h.dispatcher.dispatch(foregroundInput(), onUpdate: updates.add)
              as TurnDispatchFailed;
      expect(updates.where((e) => e.event is DirectReplyDelta), isNotEmpty);
      expect(result.routingFailure, TurnRoutingFailure.incompleteResponse);
      expect(await h.count('messages'), 1);
      expect(await h.count('conversation_tasks'), 0);
    },
  );

  test(
    'foreground gate rejects same-chat duplicates but allows another chat',
    () async {
      await seedTaskOrigin(
        h.storage.database,
        changeTask(taskFixture(id: 'seed-2'), {'chat_id': 'chat-2'}),
      );
      final entered = Completer<void>();
      final release = Completer<void>();
      h.onPrepare = (user) async {
        if (user.chatId == 'chat-1') {
          entered.complete();
          await release.future;
        }
      };
      final first = h.dispatcher.dispatch(foregroundInput());
      await entered.future;
      expect(
        await h.dispatcher.dispatch(foregroundInput()),
        isA<TurnDispatchBusy>(),
      );
      expect(
        await h.dispatcher.dispatch(
          foregroundInput(chatId: 'chat-2', turnId: 'turn-2'),
        ),
        isA<TurnDirectReplySaved>(),
      );
      release.complete();
      await first;
      expect(h.mainCalls, 2);
    },
  );

  test('accepted background tasks never occupy the foreground gate', () async {
    h.background();
    await h.dispatcher.dispatch(foregroundInput());
    h.response = routeFrames('directReply', [
      {'text': 'Hello again'},
    ]);
    final direct = await h.dispatcher.dispatch(
      foregroundInput(turnId: 'turn-2'),
    );
    expect(direct, isA<TurnDirectReplySaved>());
    expect(await h.count('conversation_tasks'), 1);
    expect(h.mainCalls, 2);
  });

  test(
    'same identity with changed user content is rejected without overwrite',
    () async {
      await h.dispatcher.dispatch(foregroundInput());
      final result =
          await h.dispatcher.dispatch(foregroundInput(content: 'different'))
              as TurnDispatchFailed;
      expect(result.code, TurnDispatchFailureCode.identityConflict);
      expect(result.retry, isNull);
      expect(h.mainCalls, 1);
      expect(
        (await h.messages.getMessages(
          'chat-1',
        )).singleWhere((message) => message.senderId == 'user').content,
        '整理报告',
      );
    },
  );

  test(
    'input snapshots mutable configuration and attachment lists before work',
    () async {
      final parameters = <String, dynamic>{
        'temperature': 0.4,
        'nested': <String, dynamic>{'mode': 'original'},
      };
      final files = ['artifact:original'];
      final input = foregroundInput(
        bot: foregroundBot(parameters: parameters),
        files: files,
      );
      parameters['temperature'] = 1;
      (parameters['nested'] as Map<String, dynamic>)['mode'] = 'changed';
      files.add('artifact:changed');
      h.background();
      final result = await h.dispatcher.dispatch(input) as TurnTaskAccepted;
      expect(result.context.input.bot.parameters!['temperature'], 0.4);
      expect(
        (input.bot.parameters!['nested'] as Map<String, dynamic>)['mode'],
        'original',
      );
      expect(result.task.acceptance.context.last.assetReferences, [
        'artifact:original',
      ]);
      final stored = jsonEncode(
        await h.storage.database.query('conversation_tasks'),
      );
      expect(stored, isNot(contains('test-credential-not-persisted')));
      expect(stored, isNot(contains('private system thought')));
      expect(stored, isNot(contains('https://provider.invalid/')));
      expect(
        result.task.acceptance.configurationDigest,
        matches(r'^[a-f0-9]{64}$'),
      );
      expect(
        () => input.bot.parameters!['temperature'] = 3,
        throwsUnsupportedError,
      );
    },
  );

  test(
    'prepared reliability and accepting policy determine immutable task policy',
    () async {
      h.preparedReliability = false;
      h.background();
      final result =
          await h.dispatcher.dispatch(foregroundInput()) as TurnTaskAccepted;
      h.preparedReliability = true;
      expect(result.task.verificationPolicy.reliabilityEnabled, isFalse);
    },
  );

  test('throwing UI callbacks cannot stop accepted work or metrics', () async {
    h.background();
    final result = await h.dispatcher.dispatch(
      foregroundInput(),
      onUpdate: (_) => throw StateError('view disposed'),
    );
    expect(result, isA<TurnTaskAccepted>());
    expect(h.metrics, hasLength(1));
    expect(h.enqueuer.calls, hasLength(1));
  });

  test('domain boundary rejects a router delta before kind', () async {
    final router = _InvalidRouter();
    final result =
        await h.createDispatcher(router: router).dispatch(foregroundInput())
            as TurnDispatchFailed;
    expect(result.routingFailure, TurnRoutingFailure.invalidProtocol);
    expect(await h.count('messages'), 1);
  });

  test('direct display remains ephemeral until terminal persistence', () async {
    final stream = StreamController<TurnRoutingEvent>();
    final dispatcher = h.createDispatcher(router: _StreamRouter(stream.stream));
    final shown = Completer<void>();
    final done = dispatcher.dispatch(
      foregroundInput(),
      onUpdate: (update) {
        if (update.event is DirectReplyDelta) shown.complete();
      },
    );
    stream.add(const TurnRoutingCallStarted());
    stream.add(const TurnDispositionStarted(TurnDispositionKind.directReply));
    stream.add(const DirectReplyDelta('complete text'));
    await shown.future;
    expect(await h.count('messages'), 1);
    stream.add(const TurnDispositionCompleted(DirectReply('complete text')));
    await stream.close();
    expect(await done, isA<TurnDirectReplySaved>());
    expect(await h.count('messages'), 2);
  });

  test(
    'a stalled enqueue cannot keep the accepted foreground turn locked',
    () async {
      h.background();
      final notification = Completer<void>();
      h.enqueuer.onEnqueue = (_) => notification.future;
      final dispatcher = h.createDispatcher(
        enqueueTimeout: const Duration(milliseconds: 10),
      );
      final result =
          await dispatcher.dispatch(foregroundInput()) as TurnTaskAccepted;
      expect(result.notificationDelivered, isFalse);
      expect(dispatcher.isAccepting('chat-1'), isFalse);
      expect(await h.count('messages'), 2);
      notification.complete();
    },
  );

  test(
    'shared gate prevents concurrent entry through separate dispatchers',
    () async {
      final gate = ForegroundTurnGate();
      final firstDispatcher = h.createDispatcher(gate: gate);
      final secondDispatcher = h.createDispatcher(gate: gate);
      final started = Completer<void>();
      final release = Completer<void>();
      h.onPrepare = (_) async {
        started.complete();
        await release.future;
      };
      final first = firstDispatcher.dispatch(foregroundInput());
      await started.future;
      expect(
        await secondDispatcher.dispatch(foregroundInput()),
        isA<TurnDispatchBusy>(),
      );
      release.complete();
      await first;
      expect(h.mainCalls, 1);
    },
  );

  test('retry does not clear a newer unrelated draft', () async {
    h.drafts.values['chat-1'] = const ConversationDraft(
      text: 'my next question',
    );
    await h.dispatcher.dispatch(foregroundInput());
    expect(h.drafts.values['chat-1']!.text, 'my next question');
  });

  test('user identity cannot collide with the final direct reply identity', () {
    final input = foregroundInput();
    expect(
      () => ConversationTurnInput(
        bot: input.bot,
        userMessage: input.userMessage.copyWith(messageId: 'turn-1:assistant'),
        language: input.language,
        verification: input.verification,
        segmentLimits: input.segmentLimits,
      ),
      throwsArgumentError,
    );
  });
}

final class _InvalidRouter implements ConversationTurnRouter {
  @override
  Stream<TurnRoutingEvent> route(TurnRoutingRequest request) async* {
    yield const TurnRoutingCallStarted();
    yield const DirectReplyDelta('before kind');
  }
}

final class _StreamRouter implements ConversationTurnRouter {
  _StreamRouter(this.events);
  final Stream<TurnRoutingEvent> events;
  @override
  Stream<TurnRoutingEvent> route(TurnRoutingRequest request) => events;
}
