import '../../../../support/idle_chat_generation.dart';
import 'package:stars/domain/use_cases/conversation_task_telemetry.dart';
import 'package:stars/domain/use_cases/prepare_conversation_task_retry.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/sqlite_chat_repository.dart';
import 'package:stars/domain/models/profile.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/profile_repository.dart';
import 'package:stars/domain/use_cases/bot_commands.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/delete_conversation.dart';
import 'package:stars/ui/core/dependency_injection/app_dependencies.dart';
import 'package:stars/ui/features/app/view_models/startup_view_model.dart';

import '../../../../support/task_scheduler_harness.dart';

void main() {
  late TaskSchedulerHarness h;
  late AppConversationTasks tasks;
  setUp(() async {
    h = TaskSchedulerHarness();
    await h.open();
    final scheduler = h.scheduler();
    final commands = ConversationTaskCommands(
      repository: h.db.repository,
      wake: scheduler.enqueue,
      clock: h.clock,
    );
    tasks = AppConversationTasks(
      telemetry: ConversationTaskTelemetry(),
      dispatcher: unusedForegroundDispatcher(),
      progress: unusedTaskProgress(),
      retry: PrepareConversationTaskRetry(
        tasks: h.db.repository,
        messages: SqliteMessageRepository(localDatabase: h.db.local),
      ),
      repository: h.db.repository,
      scheduler: scheduler,
      commands: commands,
      deleteConversation: DeleteConversation(
        chats: SqliteChatRepository(localDatabase: h.db.local),
        tasks: h.db.repository,
        commands: commands,
      ),
      deleteBot: DeleteBot(repository: _Bots(), tasks: h.db.repository),
    );
  });
  tearDown(() async {
    await tasks.dispose();
    await h.close();
  });

  test(
    'startup starts application scheduling before publishing the profile',
    () async {
      await h.add('startup');
      final model = StartupViewModel(
        profileRepository: _Profile(() {
          expect(tasks.scheduler.isStarted, isTrue);
          expect(tasks.scheduler.runningCount, 1);
        }),
        recoveryInitializer: tasks.start,
      );
      addTearDown(model.dispose);
      await model.load();
      await until(() => h.started.contains('startup'));
      expect(model.hasError, isFalse);
      expect(model.profile, isNotNull);
      model.dispose();
      // Closing the startup/page view model does not own the scheduler lifetime.
      expect(tasks.scheduler.isStarted, isTrue);
      expect(tasks.scheduler.runningCount, 1);
    },
  );

  test(
    'pause before startup preserves the queue; resume starts it and dispose prevents restart',
    () async {
      await h.add('paused');
      await tasks.setSuspended(true);
      await tasks.start();
      expect(tasks.scheduler.isStarted, isFalse);
      expect(h.started, isEmpty);
      await tasks.setSuspended(false);
      await until(() => h.started.contains('paused'));
      await tasks.setSuspended(true);
      expect(tasks.scheduler.runningCount, 0);
      expect(
        (await h.db.repository.getById('paused'))!.cancelRequestedAt,
        isNull,
      );
      await tasks.dispose();
      await tasks.setSuspended(false);
      await tasks.start();
      expect(tasks.scheduler.isStarted, isFalse);
    },
  );

  test(
    'rapid pause and resume ends in the most recent platform state',
    () async {
      await tasks.start();
      await Future.wait([tasks.setSuspended(true), tasks.setSuspended(false)]);
      expect(tasks.scheduler.isStarted, isTrue);
      await Future.wait([tasks.setSuspended(false), tasks.setSuspended(true)]);
      expect(tasks.scheduler.isStarted, isFalse);
    },
  );
}

class _Bots implements BotRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile implements ProfileRepository {
  _Profile(this.onRead);
  final void Function() onRead;
  @override
  Future<Profile> getProfile() async {
    onRead();
    return Profile(
      name: '',
      avatar: '',
      fontSize: 14,
      themeMode: 0,
      language: 'zh-CN',
      createTimestamp: taskTime,
      modifyTimestamp: taskTime,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
