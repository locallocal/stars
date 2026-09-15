import 'dart:async';
import 'package:stars/data/services/local_database_service.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_progress.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
import '../../support/conversation_task_repository_harness.dart';
import '../../support/task_scheduler_harness.dart' show until;

void main() {
  late TaskRepositoryHarness h;
  late PresentConversationTaskProgress present;
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
    present = PresentConversationTaskProgress(
      repository: h.repository,
      newId: (p) => '$p:1',
      now: () => h.time,
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
    taskId: id,
    turnId: turnId,
  );
  Future<List<Message>> messages() async =>
      (await h.local.loadMessages(
        'chat-1',
      )).map((m) => MessageRecord(m).toDomain()).toList();

  test(
    'one active task is selected; saved card restores after database reopen',
    () async {
      committed(await h.accept());
      final result = await query();
      await present.settle();
      await h.reopen();
      final saved = (await messages()).singleWhere(
        (m) => m.messageId == result.messageId,
      );
      expect(saved.taskId, 'task-1');
      expect(saved.summaryRevision, 0);
      expect(saved.taskStatusSummaries.single.progress.totalSteps, 2);
      expect(saved.showsVerificationStatus(true), isFalse);
      expect(saved.usesStrictGrounding(true), isFalse);
    },
  );
  test('multiple tasks require explicit selection', () async {
    committed(await h.accept());
    committed(await h.accept(task: taskFixture(id: 'task-2')));
    final result = await query();
    expect(result.taskId, isNull);
    expect(result.taskStatusSummaries, hasLength(2));
    expect(result.content, contains('请选择'));
    expect(present.narrate.metrics.requests, 0);
    final selected = await query(id: 'task-2', turnId: 'select');
    expect(selected.taskId, 'task-2');
  });
  test(
    'no active task shows latest terminal; empty chat has deterministic copy',
    () async {
      await seedTaskOrigin(h.database, taskFixture(id: 'seed-empty'));
      final empty = await query(turnId: 'empty');
      expect(empty.taskStatusSummaries, isEmpty);
      expect(empty.content, contains('没有任务'));
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
    },
  );
  test('explicit reference validates chat ownership', () async {
    committed(await h.accept());
    final selection = await SelectConversationTask(h.repository)(
      'another-chat',
      taskId: 'task-1',
    );
    expect(selection, isEmpty);
    final missing = await query(id: 'missing');
    expect(missing.content, contains('未找到'));
  });
  test(
    'card commits before narration and narration updates the same message',
    () async {
      committed(await h.accept());
      final pending = Completer<String>();
      TaskProgressNarrationRequest? request;
      present = PresentConversationTaskProgress(
        repository: h.repository,
        newId: (p) => p,
        polisher:
            (_) => (value, _) {
              request = value;
              return pending.future;
            },
      );
      final card = await query();
      expect((await messages()).last.messageId, card.messageId);
      expect(card.content, isNotEmpty);
      pending.complete(
        jsonEncode({
          'taskId': card.taskId,
          'summaryRevision': card.summaryRevision,
          'content': request!.allowedNarrations.last,
        }),
      );
      await present.settle();
      final result =
          (await messages())
              .where((m) => m.taskMessageKind == TaskMessageKind.status)
              .single;
      expect(result.messageId, card.messageId);
      expect(result.content, request!.allowedNarrations.last);
      expect(result.timestamp, card.timestamp);
      expect(result.summaryRevision, card.summaryRevision);
    },
  );
  test(
    'old narration cannot overwrite a newer revision or create a second reply',
    () async {
      await h.start();
      final pending = Completer<String>();
      TaskProgressNarrationRequest? request;
      present = PresentConversationTaskProgress(
        repository: h.repository,
        newId: (p) => p,
        polisher:
            (_) => (value, _) {
              request = value;
              return pending.future;
            },
      );
      final card = await query();
      committed(await h.advance(TaskEventKind.stepCompleted, stepId: 'read'));
      pending.complete(
        jsonEncode({
          'taskId': card.taskId,
          'summaryRevision': card.summaryRevision,
          'content': request!.allowedNarrations.last,
        }),
      );
      await present.settle();
      final result =
          (await messages())
              .where((m) => m.taskMessageKind == TaskMessageKind.status)
              .single;
      expect(result.content, card.content);
      expect(result.summaryRevision, card.summaryRevision);
      expect(present.narrate.metrics.stale, 1);
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
      final updates = <List<ConversationTaskProgressSummary>>[];
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
