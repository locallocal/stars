part of 'conversation_task_store.dart';

extension ConversationTaskStoreWrites on ConversationTaskStore {
  Future<TaskWriteResult<ConversationTask>> createWithAcknowledgement({
    required ConversationTask task,
    required ConversationTaskPlan plan,
    required ConversationTaskEvent initialEvent,
    required Message acknowledgement,
  }) => _write(
    task.taskId,
    (tx) async {
      if (task.status != ConversationTaskStatus.queued ||
          task.phase != ConversationTaskPhase.planning ||
          task.revision != 0 ||
          task.planRevision != 1 ||
          task.lease != null ||
          task.cancelRequestedAt != null ||
          plan.taskId != task.taskId ||
          plan.revision != 1 ||
          plan.steps.any((step) => step.status != TaskPlanStepStatus.pending) ||
          plan.isPending != task.acceptance.deferredPreparation ||
          plan.preparation != null ||
          (task.acceptance.deferredPreparation &&
              (task.acceptance.allowedToolNames.isNotEmpty ||
                  task.acceptance.approvalExemptToolNames.isNotEmpty)) ||
          !task.acceptance.allowedToolNames.containsAll(
            plan.allowedToolNames,
          ) ||
          initialEvent.taskId != task.taskId ||
          initialEvent.sequence != 1 ||
          initialEvent.planRevision != 1 ||
          initialEvent.modelTurns != 0 ||
          initialEvent.verificationStatus != null ||
          initialEvent.segmentId != null ||
          !{
            TaskEventKind.queued,
            TaskEventKind.planCreated,
          }.contains(initialEvent.kind) ||
          initialEvent.occurredAt != task.createdAt ||
          task.updatedAt != task.createdAt ||
          plan.createdAt != task.createdAt) {
        throw ArgumentError('Invalid initial task, plan or event.');
      }
      if (task.retryOfTaskId != null) {
        final original = await _task(tx, task.retryOfTaskId!);
        if (original == null ||
            original.chatId != task.chatId ||
            original.botId != task.botId ||
            !original.status.isTerminal ||
            original.terminalSummary?.canRetry != true ||
            original.terminalSummary!.sideEffectStatus !=
                TaskSideEffectStatus.none) {
          throw ArgumentError('Task is not eligible for a safe retry.');
        }
      }
      _validateEventReferences(initialEvent);
      final taskValues = _taskValues(task);
      final planValues = _planValues(plan);
      final messageValues = _messageValues(
        task,
        acknowledgement,
        terminal: false,
      );
      final existing = await tx.query(
        'conversation_tasks',
        where:
            'origin_turn_id = ? OR task_id = ? OR origin_user_message_id = ?',
        whereArgs: [task.originTurnId, task.taskId, task.originUserMessageId],
      );
      if (existing.isNotEmpty) {
        final row = existing.first;
        if (existing.length != 1 || !_sameAcceptance(row, taskValues)) {
          throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
        }
        final oldPlan =
            (await tx.query(
              'conversation_task_plans',
              where: 'task_id = ? AND plan_revision = 1',
              whereArgs: [row['task_id']],
            )).single;
        final oldMessage =
            (await tx.query(
              'messages',
              where: 'message_id = ?',
              whereArgs: [row['ack_message_id']],
            )).single;
        if (oldPlan['plan_json'] != planValues['plan_json'] ||
            !_sameMessage(oldMessage, messageValues, ignoreIdentity: true)) {
          throw _TaskConflict(
            TaskWriteConflictReason.duplicateIdentity,
            row['revision']! as int,
          );
        }
        final original = (await _task(tx, row['task_id']! as String))!;
        return TaskWriteCommitted(
          original,
          revision: original.revision,
          reused: true,
        );
      }
      final origins = await tx.query(
        'messages',
        where: 'message_id = ? AND turn_id = ? AND chat_id = ? AND bot_id = ?',
        whereArgs: [
          task.originUserMessageId,
          task.originTurnId,
          task.chatId,
          task.botId,
        ],
      );
      if (origins.isEmpty ||
          origins.single['sender_id'] == task.botId ||
          origins.single['sender_id'] == 'assistant' ||
          origins.single['task_message_kind'] != null) {
        throw ArgumentError(
          'Task acceptance requires its already saved user message.',
        );
      }
      await tx.insert('conversation_tasks', taskValues);
      await tx.insert('conversation_task_plans', planValues);
      await _event(tx, initialEvent);
      await _insertMessage(tx, messageValues);
      final progress = await _project(tx, taskValues);
      await _saveProjection(tx, taskValues, progress);
      final saved = ConversationTaskRecord(
        taskValues,
      ).toDomain(progress: progress);
      return TaskWriteCommitted(saved, revision: saved.revision);
    },
    acceptance: true,
    message: true,
  );

  Future<TaskWriteResult<ConversationTask>> appendProgress(
    ConversationTaskProgressUpdate update,
  ) => _write(update.task.taskId, (tx) async {
    final old = await _current(tx, update.task.taskId, update.expectedRevision);
    _fence(old, update.lease, update.now);
    _validateNext(old, update.task, update.event, update.now);
    if (update.task.status.isTerminal ||
        (update.task.status == ConversationTaskStatus.cancelRequested &&
            old.cancelRequestedAt == null) ||
        update.task.cancellationSource != old.cancellationSource ||
        update.task.cancelRequestedAt != old.cancelRequestedAt) {
      throw ArgumentError('Use the durable command or terminal entry point.');
    }
    if (!_sameLease(update.task.lease, old.lease)) {
      throw ArgumentError('Progress cannot change an execution lease.');
    }
    await _validateProgressFacts(tx, old, update);
    if (update.plan case final plan?) {
      await tx.insert('conversation_task_plans', _planValues(plan));
    }
    await _writeTool(tx, old, update);
    await _writeApproval(tx, update);
    await _writeCheckpoint(tx, update);
    await _writeEvidence(tx, update);
    await _event(tx, update.event);
    await _writeModelUsage(tx, update);
    final saved = await _saveTask(tx, _taskValues(update.task));
    return TaskWriteCommitted(saved, revision: saved.revision);
  }, progress: true);

  Future<TaskWriteResult<ConversationTask>> commitTerminalMessage({
    required ConversationTask terminalTask,
    required ConversationTaskEvent event,
    required Message message,
    required int expectedRevision,
    required TaskLease lease,
    required DateTime now,
  }) => _write(
    terminalTask.taskId,
    (tx) async {
      if (!terminalTask.status.isTerminal ||
          event.kind != TaskEventKind.terminal ||
          event.verificationStatus != null ||
          terminalTask.revision != expectedRevision + 1) {
        throw ArgumentError(
          'Terminal commit requires a terminal task and event.',
        );
      }
      final values = _taskValues(terminalTask);
      final messageValues = _messageValues(
        terminalTask,
        message,
        terminal: true,
      );
      final current = await _task(tx, terminalTask.taskId);
      if (current == null) {
        throw const _TaskConflict(TaskWriteConflictReason.notFound);
      }
      if (current.status.isTerminal) {
        final messages = await tx.query(
          'messages',
          where: 'message_id = ?',
          whereArgs: [current.resultMessageId],
        );
        final events = await tx.query(
          'conversation_task_events',
          where: 'task_id = ? AND kind = ?',
          whereArgs: [current.taskId, TaskEventKind.terminal.name],
        );
        if (_sameMap(_taskValues(current), values) &&
            messages.length == 1 &&
            _sameMessage(messages.single, messageValues) &&
            events.length == 1 &&
            _sameMap(events.single, _eventValues(event))) {
          return TaskWriteCommitted(
            current,
            revision: current.revision,
            reused: true,
          );
        }
        throw _TaskConflict(
          TaskWriteConflictReason.alreadyTerminal,
          current.revision,
        );
      }
      final old = await _current(tx, current.taskId, expectedRevision);
      _fence(old, lease, now);
      _validateNext(old, terminalTask, event, now);
      if (terminalTask.planRevision != old.planRevision ||
          terminalTask.cancelRequestedAt != old.cancelRequestedAt ||
          terminalTask.cancellationSource != old.cancellationSource) {
        throw ArgumentError(
          'Terminal commit cannot change the plan or cancellation intent.',
        );
      }
      final pending = await tx.query(
        'conversation_task_approvals',
        where: 'task_id = ? AND decision IS NULL',
        whereArgs: [old.taskId],
      );
      if (pending.isNotEmpty &&
          terminalTask.status == ConversationTaskStatus.succeeded) {
        throw ArgumentError('Pending approval cannot be reported as success.');
      }
      await _event(tx, event);
      await _insertMessage(tx, messageValues, terminal: true);
      final saved = await _saveTask(tx, values);
      for (final claim in message.grounding.claims) {
        for (final evidenceId in claim.acceptedEvidenceIds) {
          final evidence = await tx.rawQuery(
            'SELECT e.* FROM conversation_task_evidence_links link '
            'JOIN tool_evidence_records e ON e.evidence_id = link.evidence_id '
            'JOIN tool_execution_records a ON a.attempt_id = link.attempt_id '
            "WHERE link.task_id = ? AND link.evidence_id = ? AND a.status = 'succeeded' "
            "AND e.terminal_status = 'succeeded' AND e.persisted = 1 AND e.schema_valid = 1 AND e.truncated = 0 "
            'AND e.observed_at <= ? AND (e.valid_until IS NULL OR e.valid_until > ?)',
            [
              old.taskId,
              evidenceId,
              now.millisecondsSinceEpoch,
              now.millisecondsSinceEpoch,
            ],
          );
          if (evidence.length != 1 ||
              !ToolEvidenceDbRecord(evidence.single).hasValidDigest) {
            throw ArgumentError(
              'Terminal claim requires intact task evidence.',
            );
          }
          await tx.insert('answer_claim_evidence', {
            'message_id': message.messageId,
            'claim_id': claim.claim.claimId,
            'evidence_id': evidenceId,
            'created_at': now.millisecondsSinceEpoch,
          });
        }
      }
      return TaskWriteCommitted(saved, revision: saved.revision);
    },
    message: true,
    progress: true,
  );
}

Future<void> _insertMessage(
  DatabaseExecutor tx,
  Map<String, Object?> input, {
  bool terminal = false,
}) async {
  final values = {...input};
  if (terminal) {
    final latest =
        (await tx.rawQuery(
              'SELECT MAX(timestamp) AS latest FROM messages WHERE chat_id = ?',
              [values['chat_id']],
            )).single['latest']
            as int?;
    if (latest != null && (values['timestamp']! as int) <= latest) {
      // Monotonic per-conversation commit order, including equal millisecond
      // clocks and older requests finishing after newer foreground replies.
      values['timestamp'] = latest + 1;
    }
  }
  final existing = await tx.query(
    'messages',
    columns: ['message_id'],
    where: 'message_id = ?',
    whereArgs: [values['message_id']],
  );
  if (existing.isNotEmpty) {
    throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
  }
  await tx.insert('messages', values);
  await tx.insert('token_usage_records', {
    'message_id': values['message_id'],
    'chat_id': values['chat_id'],
    'bot_id': values['bot_id'],
    'operation_kind': 'chat_reply',
    'token_model': values['token_model'],
    'input_token_count': values['input_token_count'],
    'output_token_count': values['output_token_count'],
    'total_token_count': values['total_token_count'],
    'timestamp': values['timestamp'],
  });
  await tx.rawUpdate(
    'UPDATE chats SET last_message = ?, last_message_timestamp = ?, modify_timestamp = ? '
    'WHERE id = ? AND last_message_timestamp <= ?',
    [
      values['content'],
      values['timestamp'],
      values['timestamp'],
      values['chat_id'],
      values['timestamp'],
    ],
  );
}
