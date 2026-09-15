import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/domain/models/models.dart';

import 'conversation_task_fixtures.dart';

Future<Database> openTaskDatabase([
  String databasePath = inMemoryDatabasePath,
]) => databaseFactoryFfi.openDatabase(
  databasePath,
  options: OpenDatabaseOptions(
    version: DatabaseService.databaseVersion,
    onConfigure: DatabaseService.configure,
    onCreate: DatabaseService.createSchema,
  ),
);

/// A schema fixture, not a production implementation of task acceptance.
Future<void> seedTask(Database database, ConversationTask task) =>
    database.transaction((tx) async {
      await seedTaskOrigin(tx, task);
      await tx.insert(
        'conversation_tasks',
        ConversationTaskRecord.fromDomain(task).values,
      );
      await tx.insert(
        'conversation_task_plans',
        ConversationTaskPlanRecord.fromDomain(taskPlan(task)).values,
      );
      await tx.insert(
        'conversation_task_progress',
        TaskProgressRecord.fromDomain(
          task.taskId,
          task.revision,
          task.progress,
        ).values,
      );
      await tx.insert(
        'conversation_task_events',
        ConversationTaskEventRecord.fromDomain(
          ConversationTaskEvent(
            taskId: task.taskId,
            sequence: 1,
            kind: TaskEventKind.queued,
            occurredAt: taskTime,
            safeSummary: '已记录任务',
          ),
        ).values,
      );
      await tx.insert(
        'messages',
        MessageRecord.fromDomain(
          Message(
            messageId: task.ackMessageId,
            turnId: task.originTurnId,
            chatId: task.chatId,
            botId: task.botId,
            senderId: 'assistant',
            taskId: task.taskId,
            taskMessageKind: TaskMessageKind.acknowledgement,
            content: '已记录任务',
            timestamp: taskTime,
          ),
        ).values,
      );
    });

Future<void> seedTaskOrigin(DatabaseExecutor tx, ConversationTask task) async {
  await tx.insert('bots', <String, Object?>{
    'id': task.botId,
    'name': 'Bot',
    'avatar': '',
    'provider': 'provider',
    'base_url': '',
    'api_key': '',
    'api_type': 'openai',
    'model': 'model',
    'system_prompt': '',
    'parameters': '{}',
    'create_timestamp': 1,
    'modify_timestamp': 1,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
  await tx.insert(
    'chats',
    ChatRecord.fromDomain(
      Chat(
        id: task.chatId,
        botId: task.botId,
        lastMessageTimestamp: taskTime,
        createTimestamp: taskTime,
        modifyTimestamp: taskTime,
      ),
    ).values,
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
  await tx.insert(
    'messages',
    MessageRecord.fromDomain(
      Message(
        messageId: task.originUserMessageId,
        turnId: task.originTurnId,
        chatId: task.chatId,
        botId: task.botId,
        senderId: 'user',
        content: task.objective,
        timestamp: taskTime,
      ),
    ).values,
  );
}
