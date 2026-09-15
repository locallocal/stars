import 'package:stars/data/services/local_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/sqlite_chat_repository.dart';
import 'package:stars/domain/models/app_failure.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/bot_commands.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/delete_conversation.dart';
import 'package:stars/domain/use_cases/get_conversation_task_progress.dart';
import 'package:stars/domain/use_cases/recover_conversation_tasks.dart';

import '../../support/task_scheduler_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  late RunnerClock clock;
  setUp(() async {
    h = TaskRepositoryHarness();
    clock = RunnerClock();
    await h.open();
  });
  tearDown(() => h.close());

  test(
    'recovery preserves a live owner; expiry becomes paused with unchanged checkpoint facts',
    () async {
      await h.start();
      clock.time = h.time;
      final before = await h.facts();
      final recover = RecoverConversationTasks(
        repository: h.repository,
        clock: clock,
      );
      await recover();
      expect(await h.facts(), before);
      clock.advance(const Duration(minutes: 2));
      await h.reopen();
      final reopened = RecoverConversationTasks(
        repository: h.repository,
        clock: clock,
      );
      await reopened();
      final task = await h.task;
      expect(task.status, ConversationTaskStatus.paused);
      expect(task.lease, isNull);
      expect(task.progress.recoveries, 1);
      expect(task.completedAt, isNull);
      final after = await h.facts();
      await reopened();
      expect(await h.facts(), after);
      expect(reopened.metrics.leaseExpirations, 1);
    },
  );

  test(
    'query reports live running only while the committed lease is valid',
    () async {
      await h.start();
      clock.time = h.time;
      final query = GetConversationTaskProgress(
        repository: h.repository,
        clock: clock,
      );
      expect(
        (await query(chatId: 'chat-1', taskId: 'task-1'))!.status,
        ConversationTaskStatus.running,
      );
      clock.time = (await h.task).lease!.expiresAt;
      final summary = (await query(chatId: 'chat-1', taskId: 'task-1'))!;
      expect(summary.status, ConversationTaskStatus.paused);
      expect((await h.task).status, ConversationTaskStatus.running);
      expect(summary.summaryRevision, (await h.task).revision);
    },
  );

  test(
    'failed command transaction sends no wakeup and retains user intent on successful retry',
    () async {
      committed(await h.accept());
      final wakes = <String>[];
      final commands = ConversationTaskCommands(
        repository: h.repository,
        wake: wakes.add,
        clock: clock,
      );
      await h.failWrite('conversation_task_events');
      await expectLater(
        commands.cancel(taskId: 'task-1', expectedRevision: 0),
        throwsA(isA<Exception>()),
      );
      expect(wakes, isEmpty);
      expect((await h.task).cancelRequestedAt, isNull);
      await h.clearFailure();
      committed(await commands.cancel(taskId: 'task-1', expectedRevision: 0));
      expect(wakes, ['task-1']);
      await h.reopen();
      expect((await h.task).status, ConversationTaskStatus.cancelRequested);
    },
  );

  test(
    'configuration resume is revision fenced and never widens accepted configuration',
    () async {
      committed(await h.accept());
      final original = (await h.task).acceptance;
      committed(
        await h.repository.waitForTaskInput(
          taskId: 'task-1',
          expectedRevision: 0,
          reason: TaskWaitingReason.authentication,
          reasonCode: TaskReasonCode.missingCredentials,
          now: clock.now(),
        ),
      );
      await h.reopen();
      expect(await h.repository.listDue(now: clock.now()), isEmpty);
      expect(
        await h.repository.resumeTask(
          taskId: 'task-1',
          expectedRevision: 0,
          now: clock.now(),
        ),
        conflict(TaskWriteConflictReason.revisionMismatch),
      );
      committed(
        await h.repository.resumeTask(
          taskId: 'task-1',
          expectedRevision: 1,
          now: clock.now(),
        ),
      );
      final task = await h.task;
      expect(task.status, ConversationTaskStatus.queued);
      expect(task.acceptance.configurationDigest, original.configurationDigest);
      expect(task.acceptance.allowedToolNames, original.allowedToolNames);
    },
  );

  test(
    'deleting a conversation persists cancellation and retains all records for reconciliation',
    () async {
      committed(await h.accept());
      final wakeFacts = <ConversationTaskStatus>[];
      final chats = SqliteChatRepository(localDatabase: h.local);
      final commands = ConversationTaskCommands(
        repository: h.repository,
        clock: clock,
        wake: (_) {
          wakeFacts.add(ConversationTaskStatus.cancelRequested);
        },
      );
      final delete = DeleteConversation(
        chats: chats,
        tasks: h.repository,
        commands: commands,
      );
      await expectLater(
        delete('chat-1'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.code,
            'code',
            'conversation_tasks_stopping',
          ),
        ),
      );
      expect(
        (await h.task).cancellationSource,
        TaskCancellationSource.conversationDeletion,
      );
      expect(await h.local.loadChat('chat-1'), hasLength(1));
      expect(await h.local.loadMessages('chat-1'), hasLength(2));
      expect(wakeFacts, hasLength(1));
      await h.reopen();
      expect((await h.task).cancelRequestedAt, isNotNull);
    },
  );

  test(
    'repository and database deletion guards also protect callers bypassing the use case',
    () async {
      await h.start();
      final before = await h.facts();
      final chats = SqliteChatRepository(localDatabase: h.local);
      for (final action in <Future<void> Function()>[
        () => chats.deleteChat('chat-1'),
        () => chats.deleteChatsForBot('bot-1'),
        () => chats.clearHistory('chat-1'),
        () => h.local.deleteChat('chat-1'),
        () => h.local.clearChatHistory('chat-1', clock.now()),
        () => h.local.deleteBot('bot-1'),
      ]) {
        await expectLater(action(), throwsA(isA<AppFailure>()));
      }
      expect(await h.facts(), before);
      // Actual terminal commit is required; a released completion candidate alone
      // is still protected. Once terminal, SQL cascades remove owned task facts.
      final terminal = await h.terminal(ConversationTaskStatus.failed);
      committed(await terminal.commit(h.repository));
      await h.local.deleteChat('chat-1');
      expect(await h.repository.getById('task-1'), isNull);
      expect(await h.local.loadMessages('chat-1'), isEmpty);
    },
  );

  test('bot deletion is blocked before its repository is called', () async {
    committed(await h.accept());
    final bots = _Bots();
    final delete = DeleteBot(repository: bots, tasks: h.repository);
    await expectLater(
      delete('bot-1'),
      throwsA(
        isA<AppFailure>().having((e) => e.code, 'code', 'bot_has_active_tasks'),
      ),
    );
    expect(bots.deleted, isEmpty);
    expect((await h.task).status, ConversationTaskStatus.queued);
    await delete('unrelated-bot');
    expect(bots.deleted, ['unrelated-bot']);
  });
}

class _Bots implements BotRepository {
  final deleted = <String>[];
  @override
  Future<void> deleteBot(String id) async {
    deleted.add(id);
  }

  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
