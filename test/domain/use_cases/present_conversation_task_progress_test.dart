import 'dart:async';
import 'package:stars/data/services/local_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_list_item.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_progress.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
import '../../support/conversation_task_repository_harness.dart';
import '../../support/task_scheduler_harness.dart' show until;

void main() {
  late TaskRepositoryHarness h;
  late PresentConversationTaskProgress present;
  final requests = <TaskProgressNarrationRequest>[];
  const reply = '已读完报告，接下来需要核验结果。';
  setUp(() async {
    requests.clear();
    h = TaskRepositoryHarness();
    await h.open();
    present = PresentConversationTaskProgress(
      repository: h.repository,
      newId: (p) => '$p:1',
      now: () => h.time,
      polisher:
          (_) => (request, _) async {
            requests.add(request);
            return reply;
          },
    );
  });
  tearDown(() async {
    await present.settle();
    await h.close();
  });
  Future<Message> query({String? id, String? turnId}) => present(
    chatId: 'chat-1',
    botId: 'bot-1',
    language: 'zh-CN',
    question: '报告进展怎么样？',
    taskId: id,
    turnId: turnId,
  );
  Future<List<Message>> messages() async =>
      (await h.local.loadMessages(
        'chat-1',
      )).map((m) => MessageRecord(m).toDomain()).toList();

  test(
    'model reply and frozen task facts restore after database reopen',
    () async {
      committed(await h.accept());
      final result = await query();
      await present.settle();
      await h.reopen();
      final saved = (await messages()).singleWhere(
        (m) => m.messageId == result.messageId,
      );
      expect(saved.content, reply);
      expect(requests.single.question, '报告进展怎么样？');
      expect(saved.taskId, 'task-1');
      expect(saved.summaryRevision, 0);
      expect(saved.taskStatusSummaries.single.progress.totalSteps, 2);
      expect(saved.showsVerificationStatus(true), isFalse);
      expect(saved.usesStrictGrounding(true), isFalse);
    },
  );
  test(
    'all candidates reach the model without inventing a selection',
    () async {
      committed(await h.accept());
      committed(await h.accept(task: taskFixture(id: 'task-2')));
      final result = await query();
      expect(result.taskId, isNull);
      expect(result.taskStatusSummaries, hasLength(2));
      expect(result.content, reply);
      expect(requests.single.summaries, hasLength(2));
      expect(present.narrate.metrics.requests, 1);
      final selected = await query(id: 'task-2', turnId: 'select');
      expect(selected.taskId, 'task-2');
    },
  );
  test('model explains empty results and the latest terminal facts', () async {
    await seedTaskOrigin(h.database, taskFixture(id: 'seed-empty'));
    final empty = await query(turnId: 'empty');
    expect(empty.taskStatusSummaries, isEmpty);
    expect(empty.content, reply);
    expect(requests.single.summaries, isEmpty);
    await h.start();
    committed(
      await (await h.terminal(
        ConversationTaskStatus.failed,
      )).commit(h.repository),
    );
    final result = await query(turnId: 'recent');
    expect(
      result.taskStatusSummaries.single.status,
      ConversationTaskStatus.failed,
    );
  });
  test('explicit reference validates chat ownership', () async {
    committed(await h.accept());
    final selection = await SelectConversationTask(h.repository)(
      'another-chat',
      taskId: 'task-1',
    );
    expect(selection, isEmpty);
    final missing = await query(id: 'missing');
    expect(missing.content, reply);
    expect(requests.single.summaries, isEmpty);
    expect(requests.single.requestedTaskId, 'missing');
  });
  test('only the completed model reply is committed, once per turn', () async {
    committed(await h.accept());
    final pending = Completer<String>();
    present = PresentConversationTaskProgress(
      repository: h.repository,
      newId: (p) => p,
      polisher:
          (_) => (request, _) {
            requests.add(request);
            return pending.future;
          },
    );
    final first = query(turnId: 'question');
    final repeated = query(turnId: 'question');
    await until(() => requests.isNotEmpty);
    expect(
      (await messages()).where(
        (m) => m.taskMessageKind == TaskMessageKind.status,
      ),
      isEmpty,
    );
    expect(requests, hasLength(1));
    pending.complete(reply);
    final result = await first;
    expect(await repeated, same(result));
    expect(result.content, reply);
    expect(
      (await messages()).where(
        (m) => m.taskMessageKind == TaskMessageKind.status,
      ),
      hasLength(1),
    );
  });
  test(
    'progress during generation preserves the queried snapshot and reply',
    () async {
      await h.start();
      final pending = Completer<String>();
      present = PresentConversationTaskProgress(
        repository: h.repository,
        newId: (p) => p,
        polisher:
            (_) => (request, _) {
              requests.add(request);
              return pending.future;
            },
      );
      final response = query();
      await until(() => requests.isNotEmpty);
      final queriedRevision =
          requests.single.summaries.single['summaryRevision'];
      committed(await h.advance(TaskEventKind.stepCompleted, stepId: 'read'));
      pending.complete(reply);
      final result = await response;
      expect(result.content, reply);
      expect(result.summaryRevision, queriedRevision);
      expect(
        (await h.repository.getById('task-1'))!.revision,
        greaterThan(result.summaryRevision!),
      );
      expect(
        (await messages()).where(
          (m) => m.taskMessageKind == TaskMessageKind.status,
        ),
        hasLength(1),
      );
    },
  );
  test('model failure saves no raw query or template message', () async {
    committed(await h.accept());
    present = PresentConversationTaskProgress(
      repository: h.repository,
      newId: (p) => p,
      polisher: (_) => (_, _) async => throw StateError('provider secret'),
    );
    await expectLater(query(), throwsA(isA<TaskProgressNarrationException>()));
    expect(
      (await messages()).where(
        (m) => m.taskMessageKind == TaskMessageKind.status,
      ),
      isEmpty,
    );
    expect(present.narrate.metrics.cards, 0);
  });
  test(
    'cross-conversation facts are rejected before calling the model',
    () async {
      committed(await h.accept());
      final summary = (await h.repository.getProgressSummary('task-1'))!;
      await expectLater(
        present(
          chatId: 'other-chat',
          botId: 'bot-1',
          language: 'en',
          summaries: [summary],
        ),
        throwsArgumentError,
      );
      expect(requests, isEmpty);
    },
  );
  test(
    'cancellation while composing saves no reply and leaves the task alone',
    () async {
      committed(await h.accept());
      final cancellation = AgentCancellationToken();
      final started = Completer<void>();
      present = PresentConversationTaskProgress(
        repository: h.repository,
        newId: (p) => p,
        polisher:
            (_) => (_, _) {
              started.complete();
              return Completer<String>().future;
            },
      );
      final result = present(
        chatId: 'chat-1',
        botId: 'bot-1',
        language: 'en',
        cancellation: cancellation,
      );
      final expectation = expectLater(
        result,
        throwsA(isA<AgentRunCancelledException>()),
      );
      await started.future;
      cancellation.cancel();
      await expectation;
      expect(
        (await messages()).where(
          (m) => m.taskMessageKind == TaskMessageKind.status,
        ),
        isEmpty,
      );
      expect((await h.repository.getById('task-1'))!.cancelRequestedAt, isNull);
    },
  );
  test(
    'status persistence failure rolls back the whole message transaction',
    () async {
      committed(await h.accept());
      await h.failWrite('token_usage_records');
      final before = await h.facts();
      await expectLater(query(), throwsA(isA<Exception>()));
      expect(await h.facts(), before);
      expect(present.narrate.metrics.cards, 0);
    },
  );
  test('repeated status turn preserves its original card version', () async {
    await h.start();
    final old = await query(turnId: 'same');
    await present.settle();
    committed(await h.advance(TaskEventKind.stepCompleted, stepId: 'read'));
    final repeated = await query(turnId: 'same');
    expect(repeated.summaryRevision, old.summaryRevision);
    expect(
      (await messages()).where(
        (m) => m.taskMessageKind == TaskMessageKind.status,
      ),
      hasLength(1),
    );
  });
  test(
    'chat subscription discovers committed tasks and skips other chats',
    () async {
      final updates = <List<ConversationTaskListItem>>[];
      final sub = h.repository.watchForChat('chat-1').listen(updates.add);
      addTearDown(sub.cancel);
      await until(() => updates.isNotEmpty);
      expect(updates.last, isEmpty);
      committed(await h.accept());
      await until(() => updates.last.isNotEmpty);
      expect(updates.last.single.taskId, 'task-1');
      final before = updates.length;
      await h.failWrite('conversation_task_events');
      await expectLater(
        h.accept(task: taskFixture(id: 'task-2')),
        throwsA(isA<Exception>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(updates.length, before);
    },
  );
}
