import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
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
    'explicit task reference queries persisted facts without preparation or routing',
    () async {
      await h.storage.accept();
      h.response = 'must not call Provider';
      final result =
          await h.dispatcher.dispatch(foregroundInput(explicitTaskId: 'task-1'))
              as TurnTaskStatusRead;
      expect(result.summaries.single.taskId, 'task-1');
      expect(result.summaries.single.status, ConversationTaskStatus.queued);
      expect(result.summaries.single.progress.toolAttempts, 0);
      expect(h.preparations, 0);
      expect(h.mainCalls, 0);
      expect(result.metrics.mainReplyCalls, 0);
      expect(h.providers.creates, 0);
      expect(h.tool.calls, 0);
      expect(h.enqueuer.calls, isEmpty);
      expect(result.context.input.userMessage.turnId, 'turn-1');
    },
  );

  test(
    'natural status query uses one routing call and selects only active task',
    () async {
      await h.storage.accept();
      h.response = routeFrames('taskStatusRequest', [
        {'taskId': null},
      ]);
      final before = await h.count('messages');
      final result =
          await h.dispatcher.dispatch(foregroundInput(content: '进度如何？'))
              as TurnTaskStatusRead;
      expect(result.summaries.single.taskId, 'task-1');
      expect(result.needsSelection, isFalse);
      expect(h.mainCalls, 1);
      expect(h.tool.calls, 0);
      expect(h.enqueuer.calls, isEmpty);
      expect(await h.count('messages'), before + 1);
      expect(await h.count('conversation_tasks'), 1);
    },
  );

  test(
    'multiple active candidates are returned without inventing a selection',
    () async {
      await h.storage.accept();
      await h.storage.accept(task: taskFixture(id: 'task-2'));
      h.response = routeFrames('taskStatusRequest', [
        {'taskId': null},
      ]);
      final result =
          await h.dispatcher.dispatch(foregroundInput()) as TurnTaskStatusRead;
      expect(result.needsSelection, isTrue);
      expect(result.summaries.map((value) => value.taskId).toSet(), {
        'task-1',
        'task-2',
      });
    },
  );

  test('no active tasks returns latest persisted terminal summary', () async {
    await h.storage.start();
    final terminal = await h.storage.terminal(ConversationTaskStatus.succeeded);
    await terminal.commit(h.storage.repository);
    h.response = routeFrames('taskStatusRequest', [
      {'taskId': null},
    ]);
    final result =
        await h.dispatcher.dispatch(foregroundInput()) as TurnTaskStatusRead;
    expect(result.summaries.single.status, ConversationTaskStatus.succeeded);
    expect(result.summaries.single.summaryRevision, terminal.task.revision);
  });

  test(
    'no tasks returns an empty fact list with no guessed progress',
    () async {
      h.response = routeFrames('taskStatusRequest', [
        {'taskId': null},
      ]);
      final result =
          await h.dispatcher.dispatch(foregroundInput()) as TurnTaskStatusRead;
      expect(result.summaries, isEmpty);
      expect(result.needsSelection, isFalse);
      expect(await h.count('conversation_tasks'), 0);
    },
  );

  test(
    'explicit missing task does not silently substitute another active task',
    () async {
      await h.storage.accept();
      final result =
          await h.dispatcher.dispatch(
                foregroundInput(explicitTaskId: 'missing'),
              )
              as TurnTaskStatusRead;
      expect(result.summaries, isEmpty);
      expect(result.explicitTaskId, 'missing');
      expect(h.mainCalls, 0);
    },
  );

  test('explicit reference cannot read another conversation', () async {
    await h.storage.accept(
      task: changeTask(taskFixture(), {'chat_id': 'other-chat'}),
    );
    final result =
        await h.dispatcher.dispatch(foregroundInput(explicitTaskId: 'task-1'))
            as TurnTaskStatusRead;
    expect(result.summaries, isEmpty);
  });

  test('model-supplied reference cannot read another conversation', () async {
    await h.storage.accept(
      task: changeTask(taskFixture(), {'chat_id': 'other-chat'}),
    );
    h.response = routeFrames('taskStatusRequest', [
      {'taskId': 'task-1'},
    ]);
    final result =
        await h.dispatcher.dispatch(foregroundInput()) as TurnTaskStatusRead;
    expect(result.summaries, isEmpty);
    expect(h.mainCalls, 1);
    expect(h.tool.calls, 0);
  });

  for (final outcome in [
    MessageTerminalOutcome.cancelled,
    MessageTerminalOutcome.failed,
  ]) {
    test(
      'typed direct $outcome applies trust rules without persisting partial text',
      () async {
        final dispatcher = h.createDispatcher(router: _TerminalRouter(outcome));
        final result =
            await dispatcher.dispatch(foregroundInput())
                as TurnDirectReplySaved;
        expect(result.message.terminalOutcome, outcome);
        expect(result.message.content, isEmpty);
        expect(result.message.hasPartialContent, isFalse);
        expect(
          result.message.grounding.trustLevel,
          outcome == MessageTerminalOutcome.failed
              ? AnswerTrustLevel.failed
              : AnswerTrustLevel.unverified,
        );
        expect(await h.count('conversation_tasks'), 0);
      },
    );
  }
}

final class _TerminalRouter implements ConversationTurnRouter {
  _TerminalRouter(this.outcome);
  final MessageTerminalOutcome outcome;
  @override
  Stream<TurnRoutingEvent> route(TurnRoutingRequest request) async* {
    yield const TurnRoutingCallStarted();
    yield const TurnDispositionStarted(TurnDispositionKind.directReply);
    yield const DirectReplyDelta('partial');
    yield TurnDispositionCompleted(DirectReply('partial', outcome: outcome));
  }
}
