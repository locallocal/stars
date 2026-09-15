import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import '../../../../support/foreground_dispatch_harness.dart';
import '../../../../support/task_scheduler_harness.dart' show until;

void main() {
  late ForegroundDispatchHarness h;
  late ChatGenerationRegistry registry;
  late ChatGenerationViewModel vm;
  late PresentConversationTaskProgress progress;
  setUp(() async {
    h = ForegroundDispatchHarness();
    await h.open();
    progress = PresentConversationTaskProgress(
      repository: h.storage.repository,
      newId: h.messages.createId,
    );
    registry = ChatGenerationRegistry(
      dispatcher: h.dispatcher,
      taskProgress: progress,
      messagePersister: h.messages.upsertMessage,
      lastMessageUpdater: (_, _) async {},
      providerFactory: h.providers.create,
    );
    vm = registry.viewModelFor('chat-1', foregroundBot());
  });
  tearDown(() async {
    registry.clear();
    await progress.settle();
    await h.close();
  });
  Future<bool> send([String id = 'turn-1']) {
    final input = foregroundInput(turnId: id);
    return vm.dispatchText(
      userMessage: input.userMessage,
      language: input.language,
      verification: input.verification,
    );
  }

  test(
    'acceptance releases typing and subsequent chat leaves task unchanged',
    () async {
      h.background();
      expect(await send(), isTrue);
      final task =
          (await h.storage.repository.listActiveForChat('chat-1')).single;
      expect(vm.snapshot.isRunning, isFalse);
      expect(registry.hasBlockingRun('chat-1'), isFalse);
      h.response = routeFrames('directReply', [
        {'text': 'Hello'},
      ]);
      expect(await send('follow-up'), isTrue);
      expect(vm.snapshot.terminalMessage!.content, 'Hello');
      final after = (await h.storage.repository.getById(task.taskId))!;
      expect(after.revision, task.revision);
      expect(after.objective, task.objective);
      expect(after.cancelRequestedAt, isNull);
      expect(h.tool.calls, 0);
    },
  );
  test('double submit is blocked during preparation', () async {
    final prepared = Completer<void>();
    h.onPrepare = (_) => prepared.future;
    final first = send();
    await until(() => h.preparations == 1);
    expect(vm.snapshot.isRunning, isTrue);
    expect(await send('duplicate'), isFalse);
    prepared.complete();
    expect(await first, isTrue);
    expect(h.preparations, 1);
    expect(h.mainCalls, 1);
  });
  test(
    'foreground cancellation stops preparation without accepting a task',
    () async {
      h.background();
      final prepared = Completer<void>();
      h.onPrepare = (_) => prepared.future;
      final first = send();
      await until(() => h.preparations == 1);
      expect(await vm.cancel(), ChatRunLifecycle.cancelled);
      expect(await first, isFalse);
      prepared.complete();
      await Future<void>.delayed(Duration.zero);
      expect(await h.storage.repository.listActiveForChat('chat-1'), isEmpty);
      expect(h.mainCalls, 0);
    },
  );
  test('navigation and registry removal do not cancel accepted work', () async {
    h.background();
    await send();
    final task =
        (await h.storage.repository.listActiveForChat('chat-1')).single;
    expect(await registry.stopForNavigation('chat-1'), isTrue);
    registry.remove('chat-1');
    final replacement = registry.viewModelFor('chat-1', foregroundBot());
    expect(identical(vm, replacement), isFalse);
    expect(replacement.hasBlockingRun, isFalse);
    expect(
      (await h.storage.repository.getById(task.taskId))!.cancelRequestedAt,
      isNull,
    );
  });
  test(
    'task creation failure retries the same identity without routing twice',
    () async {
      h.background();
      await h.storage.failWrite('conversation_tasks');
      expect(await send(), isFalse);
      expect(vm.canRetryDispatch, isTrue);
      final turn = vm.snapshot.turnId;
      await h.storage.clearFailure();
      expect(await vm.retryDispatch(), isTrue);
      expect(vm.snapshot.turnId, turn);
      expect(h.mainCalls, 1);
      expect(h.preparations, 1);
      expect(await h.count('conversation_tasks'), 1);
      final messages = await h.messages.getMessages('chat-1');
      expect(
        messages.where(
          (m) => m.taskMessageKind == TaskMessageKind.acknowledgement,
        ),
        hasLength(1),
      );
    },
  );
  test(
    'status persistence failure retries status without repeating routing',
    () async {
      h.response = routeFrames('taskStatusRequest', [
        {'taskId': null},
      ]);
      await h.storage.failWrite(
        'messages',
        when: "NEW.task_message_kind = 'taskStatus'",
      );
      expect(await send(), isFalse);
      expect(vm.canRetryDispatch, isTrue);
      await h.storage.clearFailure();
      expect(await vm.retryDispatch(), isTrue);
      expect(h.mainCalls, 1);
      expect(
        vm.snapshot.terminalMessage!.taskMessageKind,
        TaskMessageKind.status,
      );
    },
  );
  test(
    'status messages do not launch an agent loop or block on narration',
    () async {
      h.background();
      await send();
      final pending = Completer<String>();
      final customProgress = PresentConversationTaskProgress(
        repository: h.storage.repository,
        newId: h.messages.createId,
        polisher: (_) => (_, _) => pending.future,
      );
      final statusVm = ChatGenerationViewModel(
        chatId: 'chat-1',
        bot: foregroundBot(),
        dispatcher: h.dispatcher,
        taskProgress: customProgress,
        messagePersister: h.messages.upsertMessage,
        lastMessageUpdater: (_, _) async {},
        providerFactory: h.providers.create,
      );
      addTearDown(statusVm.dispose);
      h.response = routeFrames('taskStatusRequest', [
        {'taskId': null},
      ]);
      final input = foregroundInput(turnId: 'status');
      expect(
        await statusVm.dispatchText(
          userMessage: input.userMessage,
          language: 'en',
          verification: input.verification,
        ),
        isTrue,
      );
      expect(statusVm.hasBlockingRun, isFalse);
      expect(pending.isCompleted, isFalse);
      expect(
        statusVm.snapshot.terminalMessage!.taskStatusSummaries,
        hasLength(1),
      );
      pending.complete('invalid');
      await customProgress.settle();
      expect(h.tool.calls, 0);
    },
  );
}
