import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_cancellation_result.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';

import '../../support/foreground_dispatch_harness.dart';

void main() {
  late ForegroundDispatchHarness h;
  setUp(() async {
    h = ForegroundDispatchHarness();
    await h.open();
  });
  tearDown(() => h.close());

  void request({String? taskId, bool all = false}) {
    h.response = routeFrames('taskCancellationRequest', [
      {'taskId': taskId, 'all': all},
    ]);
  }

  Future<TurnTaskStatusRead> cancel({String turnId = 'cancel-turn'}) async =>
      await h.dispatcher.dispatch(
            foregroundInput(turnId: turnId, content: '取消后台任务'),
          )
          as TurnTaskStatusRead;

  Future<List<Map<String, Object?>>> cancellationEvents() =>
      h.storage.database.query(
        'conversation_task_events',
        where: 'kind = ?',
        whereArgs: [TaskEventKind.cancellationRequested.name],
      );

  test(
    'agent cancels the sole task after commit and wakes its scheduler',
    () async {
      await h.storage.accept();
      request();
      h.enqueuer.onEnqueue = (id) async {
        expect(
          (await h.storage.repository.getById(id))!.cancelRequestedAt,
          isNotNull,
        );
      };
      final result = await cancel();
      expect(result.cancellation!.outcomes, {
        'task-1': TaskCancellationOutcome.requested,
      });
      expect(
        result.summaries.single.status,
        ConversationTaskStatus.cancelRequested,
      );
      expect(result.needsSelection, isFalse);
      expect(
        (await h.storage.task).cancellationSource,
        TaskCancellationSource.user,
      );
      expect(h.enqueuer.calls, ['task-1']);
      expect(await cancellationEvents(), hasLength(1));
      expect(await h.count('conversation_tasks'), 1);
      expect(h.mainCalls, 1);
      expect(h.tool.calls, 0);
      final prompt =
          h.mainProviders.single.sessions.single.request.messages.last.content;
      expect(prompt, contains('"taskId":"task-1"'));
      expect(prompt, contains('整理报告'));
    },
  );

  test(
    'ambiguous request asks for selection without cancelling anything',
    () async {
      await h.storage.accept();
      await h.storage.accept(task: taskFixture(id: 'task-2'));
      request();
      final result = await cancel();
      expect(result.needsSelection, isTrue);
      expect(result.summaries, hasLength(2));
      expect(result.cancellation!.outcomes, isEmpty);
      expect(await cancellationEvents(), isEmpty);
      expect(h.enqueuer.calls, isEmpty);
    },
  );

  test('explicit identity cancels only that task', () async {
    await h.storage.accept();
    await h.storage.accept(task: taskFixture(id: 'task-2'));
    request(taskId: 'task-2');
    final result = await cancel();
    expect(result.cancellation!.outcomes.keys, ['task-2']);
    expect((await h.storage.task).cancelRequestedAt, isNull);
    expect(h.enqueuer.calls, ['task-2']);
  });

  test('explicit all cancels current conversation candidates only', () async {
    await h.storage.accept();
    await h.storage.accept(task: taskFixture(id: 'task-2'));
    await h.storage.accept(
      task: changeTask(taskFixture(id: 'foreign'), {'chat_id': 'other-chat'}),
    );
    request(all: true);
    final result = await cancel();
    expect(result.cancellation!.outcomes, {
      'task-1': TaskCancellationOutcome.requested,
      'task-2': TaskCancellationOutcome.requested,
    });
    expect(result.needsSelection, isFalse);
    expect(
      (await h.storage.repository.getById('foreign'))!.cancelRequestedAt,
      isNull,
    );
    expect(await cancellationEvents(), hasLength(2));
  });

  for (final id in ['missing', 'foreign']) {
    test(
      'rejects $id identity without falling back to the active task',
      () async {
        await h.storage.accept();
        await h.storage.accept(
          task: changeTask(taskFixture(id: 'foreign'), {
            'chat_id': 'other-chat',
          }),
        );
        request(taskId: id);
        final result = await cancel();
        expect(result.cancellation!.outcomes, {
          id: TaskCancellationOutcome.notFound,
        });
        expect(result.summaries, isEmpty);
        expect(await cancellationEvents(), isEmpty);
      },
    );
  }

  test('no active task does not create new background work', () async {
    request();
    final result = await cancel();
    expect(result.cancellation!.outcomes, isEmpty);
    expect(result.summaries, isEmpty);
    expect(await h.count('conversation_tasks'), 0);
  });

  test(
    'completed task remains terminal and is not reported as cancelled',
    () async {
      await h.storage.start();
      await (await h.storage.terminal(
        ConversationTaskStatus.succeeded,
      )).commit(h.storage.repository);
      request(taskId: 'task-1');
      final result = await cancel();
      expect(result.cancellation!.outcomes, {
        'task-1': TaskCancellationOutcome.alreadyFinished,
      });
      expect(result.summaries.single.status, ConversationTaskStatus.succeeded);
      expect(await cancellationEvents(), isEmpty);
    },
  );

  test(
    'repeated cancellation preserves the first intent and audit event',
    () async {
      await h.storage.accept();
      request();
      await cancel();
      final before = await h.storage.task;
      final result = await cancel(turnId: 'second-cancel');
      expect(result.cancellation!.outcomes, {
        'task-1': TaskCancellationOutcome.alreadyRequested,
      });
      final after = await h.storage.task;
      expect(after.cancelRequestedAt, before.cancelRequestedAt);
      expect(after.revision, before.revision);
      expect(await cancellationEvents(), hasLength(1));
    },
  );

  test(
    'failed batch retry keeps its original candidates and reuses committed intent',
    () async {
      await h.storage.accept();
      await h.storage.accept(task: taskFixture(id: 'task-2'));
      await h.storage.failWrite(
        'conversation_task_events',
        when: "NEW.task_id = 'task-2' AND NEW.kind = 'cancellationRequested'",
      );
      request(all: true);
      final result =
          await h.dispatcher.dispatch(foregroundInput()) as TurnDispatchFailed;
      expect(result.code, TurnDispatchFailureCode.taskCancellationFailed);
      expect((await h.storage.task).cancelRequestedAt, isNotNull);
      await h.storage.clearFailure();
      await h.storage.accept(task: taskFixture(id: 'new-task'));
      final retried =
          await h.dispatcher.retry(result.retry!) as TurnTaskStatusRead;
      expect(retried.cancellation!.outcomes, {
        'task-1': TaskCancellationOutcome.alreadyRequested,
        'task-2': TaskCancellationOutcome.requested,
      });
      expect(
        (await h.storage.repository.getById('new-task'))!.cancelRequestedAt,
        isNull,
      );
      expect(await cancellationEvents(), hasLength(2));
      expect(h.mainCalls, 1);
    },
  );

  test(
    'an older user turn cannot cancel tasks created after its submission',
    () async {
      final later = foregroundTime.add(const Duration(seconds: 1));
      await h.storage.accept(
        task: changeTask(taskFixture(), {
          'created_at': later.microsecondsSinceEpoch,
          'updated_at': later.microsecondsSinceEpoch,
        }),
      );
      request(all: true);
      expect((await cancel()).summaries, isEmpty);
      request(taskId: 'task-1');
      expect((await cancel(turnId: 'explicit')).cancellation!.outcomes, {
        'task-1': TaskCancellationOutcome.notFound,
      });
      expect(await cancellationEvents(), isEmpty);
    },
  );

  test('incomplete model response cannot request cancellation', () async {
    await h.storage.accept();
    request();
    h.terminal = false;
    expect(
      await h.dispatcher.dispatch(foregroundInput()),
      isA<TurnDispatchFailed>(),
    );
    expect(await cancellationEvents(), isEmpty);
  });

  test('cancellation retries a revision race against the same task', () async {
    await h.storage.start();
    final repository = _RacingRepository(h.storage.repository, () async {
      committed(await h.storage.advance(TaskEventKind.segmentCheckpoint));
    });
    h.dispatcher = h.createDispatcher(tasks: repository);
    request(taskId: 'task-1');
    final result = await cancel();
    expect(repository.writes, 2);
    expect(result.cancellation!.outcomes, {
      'task-1': TaskCancellationOutcome.requested,
    });
    expect(await cancellationEvents(), hasLength(1));
  });

  test('finishing during cancellation does not overwrite the result', () async {
    await h.storage.start();
    final repository = _RacingRepository(h.storage.repository, () async {
      await (await h.storage.terminal(
        ConversationTaskStatus.succeeded,
      )).commit(h.storage.repository);
    });
    h.dispatcher = h.createDispatcher(tasks: repository);
    request(taskId: 'task-1');
    final result = await cancel();
    expect(result.cancellation!.outcomes, {
      'task-1': TaskCancellationOutcome.alreadyFinished,
    });
    expect((await h.storage.task).status, ConversationTaskStatus.succeeded);
    expect(await cancellationEvents(), isEmpty);
  });

  test('foreground interruption before a command prevents its write', () async {
    await h.storage.accept();
    final token = AgentCancellationToken();
    final repository = _RacingRepository(h.storage.repository, () async {})
      ..beforeRead = token.cancel;
    h.dispatcher = h.createDispatcher(tasks: repository);
    request();
    final result =
        await h.dispatcher.dispatch(foregroundInput(), cancellation: token)
            as TurnDispatchFailed;
    expect(result.code, TurnDispatchFailureCode.cancelled);
    expect(repository.writes, 0);
    expect(await cancellationEvents(), isEmpty);
  });
}

final class _RacingRepository implements ConversationTaskRepository {
  _RacingRepository(this.delegate, this.beforeFirstWrite);
  final ConversationTaskRepository delegate;
  final Future<void> Function() beforeFirstWrite;
  void Function()? beforeRead;
  int writes = 0;

  @override
  Future<ConversationTask?> getById(String id) {
    beforeRead?.call();
    return delegate.getById(id);
  }

  @override
  Future<ConversationTask?> getByOriginTurnId(String id) =>
      delegate.getByOriginTurnId(id);
  @override
  Future<List<ConversationTask>> listActiveForChat(String id) =>
      delegate.listActiveForChat(id);
  @override
  Future<ConversationTaskProgressSummary?> getProgressSummary(String id) =>
      delegate.getProgressSummary(id);
  @override
  Future<TaskWriteResult<ConversationTask>> requestCancellation({
    required String taskId,
    required int expectedRevision,
    required TaskCancellationSource source,
    required DateTime requestedAt,
  }) async {
    if (++writes == 1) await beforeFirstWrite();
    return delegate.requestCancellation(
      taskId: taskId,
      expectedRevision: expectedRevision,
      source: source,
      requestedAt: requestedAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
