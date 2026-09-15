part of 'conversation_task_store.dart';

extension ConversationTaskStoreStatus on ConversationTaskStore {
  Stream<List<ConversationTaskProgressSummary>> watchForChat(String chatId) {
    late StreamController<List<ConversationTaskProgressSummary>> controller;
    StreamSubscription<ConversationTaskProgressSummary>? subscription;
    final values = <String, ConversationTaskProgressSummary>{};
    var cancelled = false, ready = false;
    void accept(ConversationTaskProgressSummary value) {
      final old = values[value.taskId];
      if (old == null || value.summaryRevision > old.summaryRevision) {
        values[value.taskId] = value;
      }
    }

    void emit() {
      if (!cancelled) controller.add(List.unmodifiable(values.values));
    }

    Future<void> start() async {
      try {
        final db = await _databaseProvider();
        if (cancelled) return;
        subscription = _bus(db).stream.where((s) => s.chatId == chatId).listen((
          s,
        ) {
          accept(s);
          if (ready) emit();
        });
        final initial = await db.transaction((tx) async {
          final rows = await tx.rawQuery(
            '''
            SELECT task_id FROM conversation_tasks WHERE chat_id = ? AND
            (completed_at IS NULL OR task_id = (SELECT task_id FROM conversation_tasks
              WHERE chat_id = ? AND completed_at IS NOT NULL
              ORDER BY completed_at DESC, task_id DESC LIMIT 1)) ORDER BY created_at, task_id
          ''',
            [chatId, chatId],
          );
          return [
            for (final row in rows)
              (await _summary(tx, row['task_id']! as String))!,
          ];
        });
        for (final summary in initial) {
          accept(summary);
        }
        ready = true;
        emit();
      } on Object catch (error, stack) {
        if (!cancelled) controller.addError(error, stack);
      }
    }

    controller = StreamController(
      onListen: start,
      onCancel: () async {
        cancelled = true;
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  Future<Message> saveStatusMessage(Message message) async {
    if (message.taskMessageKind != TaskMessageKind.status) {
      throw ArgumentError('Expected a status message.');
    }
    final db = await _databaseProvider();
    final saved = await db.transaction((tx) async {
      final existing = await tx.query(
        'messages',
        where: 'message_id = ?',
        whereArgs: [message.messageId],
      );
      if (existing.isNotEmpty) {
        final old = MessageRecord(existing.single).toDomain();
        if (old.chatId != message.chatId ||
            old.botId != message.botId ||
            old.turnId != message.turnId ||
            old.taskMessageKind != TaskMessageKind.status) {
          throw StateError('status_message_identity_conflict');
        }
        return old;
      }
      for (final summary in message.taskStatusSummaries) {
        final task = await _task(tx, summary.taskId);
        if (task == null ||
            task.chatId != message.chatId ||
            task.botId != message.botId ||
            summary.summaryRevision > task.revision) {
          throw StateError('status_message_scope_conflict');
        }
      }
      await _insertMessage(
        tx,
        MessageRecord.fromDomain(message).values,
        terminal: true,
      );
      final rows = await tx.query(
        'messages',
        where: 'message_id = ?',
        whereArgs: [message.messageId],
      );
      return MessageRecord(rows.single).toDomain();
    });
    _onMessageCommitted(message.chatId);
    return saved;
  }

  Future<bool> updateStatusNarration(Message message) async {
    if (message.taskMessageKind != TaskMessageKind.status ||
        message.taskId == null) {
      return false;
    }
    final db = await _databaseProvider();
    final changed = await db.transaction((tx) async {
      final rows = await tx.query(
        'messages',
        where: 'message_id = ?',
        whereArgs: [message.messageId],
      );
      if (rows.isEmpty) return false;
      final old = MessageRecord(rows.single).toDomain();
      final snapshot =
          MessageRecord.fromDomain(message).values['task_summary_json'];
      if (old.chatId != message.chatId ||
          old.botId != message.botId ||
          old.taskId != message.taskId ||
          old.turnId != message.turnId ||
          old.taskMessageKind != TaskMessageKind.status ||
          old.summaryRevision != message.summaryRevision ||
          rows.single['task_summary_json'] != snapshot) {
        return false;
      }
      final task = await _task(tx, message.taskId!);
      // Late prose cannot replace a card whose task already advanced.
      if (task == null || task.revision != message.summaryRevision) {
        return false;
      }
      await tx.update(
        'messages',
        {'content': message.content},
        where: 'message_id = ?',
        whereArgs: [message.messageId],
      );
      return true;
    });
    if (changed) _onMessageCommitted(message.chatId);
    return changed;
  }
}
