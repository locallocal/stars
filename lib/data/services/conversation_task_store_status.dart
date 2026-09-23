part of 'conversation_task_store.dart';

extension ConversationTaskStoreStatus on ConversationTaskStore {
  Stream<List<ConversationTaskListItem>> watchForChat(
    String chatId, {
    bool refresh = false,
  }) {
    late StreamController<List<ConversationTaskListItem>> controller;
    StreamSubscription<void>? subscription;
    _ConversationTaskListCache? cache;
    _ConversationTaskListEntry? entry;
    var cancelled = false, ready = false;
    List<ConversationTaskListItem>? lastEmitted;

    void emit() {
      final snapshot = entry?.snapshot;
      if (!cancelled && snapshot != null && !identical(snapshot, lastEmitted)) {
        lastEmitted = snapshot;
        controller.add(snapshot);
      }
    }

    Future<void> start() async {
      try {
        final db = await _databaseProvider();
        if (cancelled) return;
        cache = _listCache(db);
        final current = entry = cache!.acquire(chatId);
        subscription = current.changes.stream.listen((_) {
          if (ready) emit();
        });
        await current.load(() {
          metrics.taskListSnapshotReads++;
          return db.transaction((tx) async {
            final rows = await tx.rawQuery(
              r'''
              SELECT t.task_id, t.chat_id, t.title, t.status, t.phase,
                t.revision, t.created_at, t.updated_at, t.lease_expires_at,
                json_extract(p.progress_json, '$.completedSteps') AS completed_steps,
                json_extract(p.progress_json, '$.totalSteps') AS total_steps,
                json_extract(p.progress_json, '$.currentStepSummary') AS current_step_summary,
                json_extract(p.progress_json, '$.latestTool.name') AS latest_tool_name,
                json_extract(p.progress_json, '$.tokenUsage.inputTokens') AS input_tokens,
                json_extract(p.progress_json, '$.tokenUsage.outputTokens') AS output_tokens,
                json_extract(p.progress_json, '$.tokenUsage.totalTokens') AS total_tokens
              FROM conversation_tasks t
              LEFT JOIN conversation_task_progress p
                ON p.task_id = t.task_id AND p.summary_revision = t.revision
              WHERE t.chat_id = ?
              ORDER BY t.created_at, t.task_id
              ''',
              [chatId],
            );
            return rows.map(ConversationTaskListRecord.decode).toList();
          });
        }, refresh: refresh);
        ready = true;
        emit();
      } on Object catch (error, stack) {
        if (!cancelled) controller.addError(error, stack);
        await subscription?.cancel();
        if (!cancelled) unawaited(controller.close());
      } finally {
        cache?.trim();
      }
    }

    controller = StreamController(
      onListen: start,
      onCancel: () async {
        cancelled = true;
        await subscription?.cancel();
        if (entry case final current?) cache!.release(current);
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
