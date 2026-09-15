import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/sqlite_chat_repository.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/services/strict_grounding_policy.dart';

import '../../support/task_terminal_harness.dart';
import '../../support/task_scheduler_harness.dart'
    show until, createRunnerScheduler;

void main() {
  late TaskTerminalHarness h;
  setUp(() => h = TaskTerminalHarness());
  tearDown(() => h.close());

  test(
    'commit publishes message and preview once and appends after newer requests',
    () async {
      await h.open();
      await h.observe();
      await h.candidate();
      final messages = SqliteMessageRepository(
        localDatabase: h.runner.db.local,
      );
      final chats = SqliteChatRepository(localDatabase: h.runner.db.local);
      addTearDown(messages.dispose);
      addTearDown(chats.dispose);
      final later = Message(
        messageId: 'later',
        turnId: 'later-turn',
        chatId: 'chat-1',
        botId: 'bot-1',
        senderId: 'user',
        content: '另一条请求',
        timestamp: h.runner.clock.now().add(const Duration(hours: 1)),
      );
      await messages.upsertMessage(later);
      await messages.getMessagePage('chat-1');
      await chats.getChats();
      var updates = 0, previews = 0;
      final sub = messages.taskMessageChanges.listen((id) {
        expect(id, 'chat-1');
        updates++;
      });
      final preview = chats.changes.listen((_) => previews++);
      addTearDown(sub.cancel);
      addTearDown(preview.cancel);
      final finish = h.finalizer();
      await finish('task-1');
      await until(() => updates == 1 && previews == 1);
      final result = await h.result();
      final page = await messages.getMessagePage('chat-1');
      expect(page.messages.last.messageId, result.messageId);
      expect(result.timestamp.isAfter(later.timestamp), isTrue);
      expect((await chats.getChat('chat-1'))!.lastMessage, result.content);
      await finish('task-1');
      await Future<void>.delayed(Duration.zero);
      expect(updates, 1);
      expect(previews, 1);
      expect(
        (await h.runner.db.database.query(
          'token_usage_records',
          where: "message_id = 'task-1:result'",
        )),
        hasLength(1),
      );
    },
  );

  test('failed commit notifies neither messages nor previews', () async {
    await h.open();
    await h.observe();
    await h.candidate();
    var updates = 0;
    final sub = h.runner.db.local.taskMessageChanges.listen((_) => updates++);
    addTearDown(sub.cancel);
    await h.runner.db.failWrite('messages');
    await expectLater(h.finalizer()('task-1'), throwsA(isA<Exception>()));
    await Future<void>.delayed(Duration.zero);
    expect(updates, 0);
  });

  test(
    'saved task presentation survives restart and current settings changes',
    () async {
      await h.open(strict: false, showStatus: false);
      await h.observe();
      await h.candidate(unsupported: true);
      await h.finalizer()('task-1');
      await h.runner.db.reopen();
      final result = await h.result();
      expect(result.usesStrictGrounding(true), isFalse);
      expect(result.showsVerificationStatus(true), isFalse);
      expect(
        const StrictGroundingPolicy().present(result).content,
        result.content,
      );
    },
  );

  test(
    'acknowledgements stay operational under strict mode and trust display',
    () async {
      await h.open();
      final ack = (await h.messages()).singleWhere(
        (m) => m.taskMessageKind == TaskMessageKind.acknowledgement,
      );
      expect(ack.usesStrictGrounding(true), isFalse);
      expect(ack.showsVerificationStatus(true), isFalse);
      final presentation = const StrictGroundingPolicy().present(ack);
      expect(presentation.suppressedFacts, isFalse);
      expect(presentation.content, ack.content);
    },
  );

  test(
    'application scheduler recovers a candidate and completes it without another model turn',
    () async {
      await h.open();
      await h.observe();
      await h.candidate();
      await h.runner.db.reopen();
      final turns = h.runner.models.requests.length;
      final scheduler = createRunnerScheduler(
        h.runner,
        onReady: h.finalizer().onReady,
      );
      addTearDown(scheduler.stop);
      await scheduler.start(periodic: false);
      await until(() async => (await h.runner.db.task).status.isTerminal);
      expect(h.runner.models.requests.length, turns);
      expect(
        (await h.result()).terminalOutcome,
        MessageTerminalOutcome.completed,
      );
    },
  );

  test(
    'scheduler retries a callback that could not acquire capacity',
    () async {
      await h.open();
      await h.candidate();
      var callbacks = 0;
      final finish = h.finalizer();
      final scheduler = createRunnerScheduler(
        h.runner,
        onReady: (result) async {
          callbacks++;
          if (callbacks > 1) await finish.onReady(result);
        },
      );
      addTearDown(scheduler.stop);
      await scheduler.start(periodic: false);
      expect(callbacks, 1);
      await scheduler.tick();
      expect(callbacks, 2);
      await until(() async => (await h.runner.db.task).status.isTerminal);
      expect((await h.runner.db.task).status, ConversationTaskStatus.succeeded);
    },
  );

  test(
    'no-progress task completes through scheduling with one friendly failure',
    () async {
      await h.runner.open(
        limits: TaskSegmentLimits(maxModelTurns: 1, maxNoProgressSegments: 2),
      );
      for (var i = 0; i < 2; i++) {
        h.runner.models.events([
          const ReasoningDelta('private incomplete reasoning'),
        ]);
        await h.runner.run();
      }
      final scheduler = createRunnerScheduler(
        h.runner,
        onReady: h.finalizer().onReady,
      );
      addTearDown(scheduler.stop);
      await scheduler.start(periodic: false);
      await until(() async => (await h.runner.db.task).status.isTerminal);
      final result = await h.result();
      expect(result.terminalOutcome, MessageTerminalOutcome.failed);
      expect(result.content, contains('未取得新的可用进展'));
      expect(result.content, isNot(contains('private')));
      expect(
        (await h.runner.db.task).terminalSummary!.reasonCode,
        TaskReasonCode.noProgress,
      );
    },
  );
}
