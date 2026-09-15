part of 'database_service.dart';

const _conversationTaskTables = {
  'conversation_tasks',
  'conversation_task_plans',
  'conversation_task_events',
  'conversation_task_progress',
  'conversation_task_approvals',
  'conversation_task_checkpoints',
  'conversation_task_tool_attempts',
  'conversation_task_evidence_links',
};
const _conversationTaskIndexes = {
  'conversation_tasks_chat_status_index',
  'conversation_tasks_due_index',
  'conversation_tasks_lease_expiry_index',
  'conversation_task_approvals_pending_index',
  'conversation_task_tool_attempts_segment_index',
  'conversation_task_evidence_links_segment_index',
  'messages_task_id_index',
};
const _conversationTaskImmutableTables = {
  'conversation_task_plans':
      'task_id = NEW.task_id AND plan_revision = NEW.plan_revision',
  'conversation_task_events':
      'task_id = NEW.task_id AND sequence = NEW.sequence',
  'conversation_task_tool_attempts':
      'attempt_id = NEW.attempt_id OR '
      '(task_id = NEW.task_id AND idempotency_key = NEW.idempotency_key AND attempt_number = NEW.attempt_number)',
  'conversation_task_evidence_links': 'evidence_id = NEW.evidence_id',
};
final _conversationTaskTriggers = {
  for (final table in _conversationTaskImmutableTables.keys) ...[
    '${table}_prevent_update',
    '${table}_prevent_replace',
    '${table}_prevent_delete',
  ],
  'conversation_task_tool_attempts_validate_scope',
  'conversation_task_evidence_links_validate_scope',
  'conversation_tasks_validate_origin',
  'conversation_tasks_preserve_acceptance',
  'conversation_tasks_preserve_terminal',
  'conversation_tasks_prevent_replace',
  'messages_validate_task_scope_insert',
  'messages_validate_task_scope_update',
};

Future<void> _createConversationTaskSchema(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE conversation_tasks (
      task_id TEXT PRIMARY KEY NOT NULL CHECK (length(task_id) > 0),
      chat_id TEXT NOT NULL,
      bot_id TEXT NOT NULL,
      origin_turn_id TEXT NOT NULL UNIQUE CHECK (length(origin_turn_id) > 0),
      origin_user_message_id TEXT NOT NULL UNIQUE,
      retry_of_task_id TEXT REFERENCES conversation_tasks(task_id) DEFERRABLE INITIALLY DEFERRED,
      ack_message_id TEXT NOT NULL UNIQUE CHECK (ack_message_id = task_id || ':ack'),
      result_message_id TEXT UNIQUE CHECK (result_message_id = task_id || ':result'),
      title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 200),
      objective TEXT NOT NULL CHECK (length(objective) BETWEEN 1 AND 16000),
      status TEXT NOT NULL CHECK (status IN (
        'queued', 'running', 'waitingForUser', 'paused', 'cancelRequested',
        'succeeded', 'failed', 'cancelled')),
      phase TEXT NOT NULL CHECK (phase IN (
        'planning', 'executing', 'observing', 'verifying', 'synthesizing', 'committing')),
      plan_revision INTEGER NOT NULL CHECK (plan_revision > 0),
      revision INTEGER NOT NULL CHECK (revision >= 0),
      acceptance_json TEXT NOT NULL CHECK (json_valid(acceptance_json)),
      waiting_reason TEXT CHECK (waiting_reason IN (
        'approval', 'authentication', 'requiredInput', 'reconciliation')),
      terminal_summary_json TEXT CHECK (json_valid(terminal_summary_json)),
      lease_owner_id TEXT,
      lease_token TEXT,
      lease_acquired_at INTEGER,
      lease_expires_at INTEGER,
      next_run_at INTEGER,
      cancellation_source TEXT CHECK (cancellation_source IN (
        'user', 'conversationDeletion', 'botDeletion')),
      cancel_requested_at INTEGER,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL CHECK (updated_at >= created_at),
      completed_at INTEGER CHECK (completed_at >= created_at),
      CHECK ((status = 'waitingForUser') = (waiting_reason IS NOT NULL)),
      CHECK ((status IN ('succeeded', 'failed', 'cancelled')) = (completed_at IS NOT NULL)),
      CHECK ((completed_at IS NOT NULL) = (result_message_id IS NOT NULL)),
      CHECK ((status IN ('failed', 'cancelled')) = (terminal_summary_json IS NOT NULL)),
      CHECK ((cancellation_source IS NULL) = (cancel_requested_at IS NULL)),
      CHECK (status NOT IN ('cancelRequested', 'cancelled') OR cancellation_source IS NOT NULL),
      CHECK (cancellation_source IS NULL OR status NOT IN ('queued', 'running', 'succeeded')),
      CHECK ((lease_token IS NULL AND lease_owner_id IS NULL AND lease_acquired_at IS NULL AND lease_expires_at IS NULL)
        OR (lease_token IS NOT NULL AND length(lease_token) > 0 AND lease_owner_id IS NOT NULL
          AND length(lease_owner_id) > 0 AND lease_acquired_at IS NOT NULL
          AND lease_expires_at IS NOT NULL AND lease_expires_at > lease_acquired_at)),
      CHECK (completed_at IS NULL OR (lease_token IS NULL AND next_run_at IS NULL)),
      CHECK (status != 'running' OR lease_token IS NOT NULL),
      CHECK (completed_at IS NULL OR completed_at <= updated_at),
      CHECK (cancel_requested_at IS NULL OR (cancel_requested_at >= created_at AND cancel_requested_at <= updated_at)),
      FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE RESTRICT,
      FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE RESTRICT,
      FOREIGN KEY (origin_user_message_id) REFERENCES messages(message_id)
        DEFERRABLE INITIALLY DEFERRED,
      FOREIGN KEY (ack_message_id) REFERENCES messages(message_id)
        DEFERRABLE INITIALLY DEFERRED,
      FOREIGN KEY (result_message_id) REFERENCES messages(message_id)
        DEFERRABLE INITIALLY DEFERRED,
      FOREIGN KEY (task_id, plan_revision) REFERENCES conversation_task_plans(task_id, plan_revision)
        DEFERRABLE INITIALLY DEFERRED
    )
  ''');
  await db.execute('''
    CREATE TABLE conversation_task_plans (
      task_id TEXT NOT NULL,
      plan_revision INTEGER NOT NULL CHECK (plan_revision > 0),
      plan_json TEXT NOT NULL CHECK (json_valid(plan_json)),
      created_at INTEGER NOT NULL,
      PRIMARY KEY (task_id, plan_revision),
      FOREIGN KEY (task_id) REFERENCES conversation_tasks(task_id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE conversation_task_events (
      task_id TEXT NOT NULL,
      sequence INTEGER NOT NULL CHECK (sequence > 0),
      kind TEXT NOT NULL CHECK (kind IN (
        'queued', 'started', 'paused', 'resumed', 'cancellationRequested', 'terminal',
        'planCreated', 'planRevised', 'stepStarted', 'stepCompleted', 'toolQueued',
        'toolStarted', 'toolSucceeded', 'toolFailed', 'toolRetry', 'externalJobUpdated',
        'approvalRequested', 'waitingForUser', 'approvalApproved', 'approvalDenied',
        'verificationStarted', 'evidenceAccepted', 'evidenceRejected', 'verificationCompleted',
        'resultCommitting', 'leaseExpired', 'processRecovered', 'retryScheduled', 'noProgress',
        'modelTurnCompleted', 'segmentCheckpoint', 'segmentProgress')),
      occurred_at INTEGER NOT NULL,
      safe_summary TEXT NOT NULL CHECK (length(safe_summary) BETWEEN 1 AND 2000),
      plan_revision INTEGER NOT NULL DEFAULT 1 CHECK (plan_revision > 0),
      model_turns INTEGER NOT NULL DEFAULT 0 CHECK (model_turns >= 0),
      verification_status TEXT CHECK (verification_status IN (
        'notStarted', 'verifying', 'verified', 'partial', 'failed')),
      segment_id TEXT, step_id TEXT, attempt_id TEXT, approval_id TEXT, evidence_id TEXT,
      reason_code TEXT,
      PRIMARY KEY (task_id, sequence),
      FOREIGN KEY (task_id) REFERENCES conversation_tasks(task_id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE conversation_task_progress (
      task_id TEXT PRIMARY KEY NOT NULL,
      summary_revision INTEGER NOT NULL CHECK (summary_revision >= 0),
      progress_json TEXT NOT NULL CHECK (json_valid(progress_json)),
      FOREIGN KEY (task_id) REFERENCES conversation_tasks(task_id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE conversation_task_approvals (
      approval_id TEXT PRIMARY KEY NOT NULL CHECK (length(approval_id) > 0),
      task_id TEXT NOT NULL,
      request_revision INTEGER NOT NULL CHECK (request_revision >= 0),
      attempt_id TEXT,
      safe_action_summary TEXT NOT NULL CHECK (length(safe_action_summary) BETWEEN 1 AND 2000),
      requested_at INTEGER NOT NULL,
      decision TEXT CHECK (decision IN ('approved', 'denied')),
      decided_by TEXT,
      decided_at INTEGER CHECK (decided_at >= requested_at),
      CHECK ((decision IS NULL AND decided_by IS NULL AND decided_at IS NULL)
        OR (decision IS NOT NULL AND decided_by IS NOT NULL AND length(decided_by) > 0 AND decided_at IS NOT NULL)),
      FOREIGN KEY (task_id) REFERENCES conversation_tasks(task_id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE conversation_task_checkpoints (
      task_id TEXT NOT NULL,
      plan_revision INTEGER NOT NULL CHECK (plan_revision > 0),
      segment_id TEXT NOT NULL CHECK (length(segment_id) > 0),
      sequence INTEGER NOT NULL CHECK (sequence > 0),
      checkpoint_json TEXT NOT NULL CHECK (json_valid(checkpoint_json)),
      saved_at INTEGER NOT NULL,
      PRIMARY KEY (task_id, plan_revision),
      FOREIGN KEY (task_id, plan_revision) REFERENCES conversation_task_plans(task_id, plan_revision) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE conversation_task_tool_attempts (
      attempt_id TEXT PRIMARY KEY NOT NULL,
      task_id TEXT NOT NULL,
      segment_id TEXT NOT NULL CHECK (length(segment_id) > 0),
      idempotency_key TEXT NOT NULL CHECK (length(idempotency_key) > 0),
      attempt_number INTEGER NOT NULL CHECK (attempt_number > 0),
      UNIQUE (task_id, idempotency_key, attempt_number),
      UNIQUE (task_id, segment_id, attempt_id),
      FOREIGN KEY (task_id) REFERENCES conversation_tasks(task_id) ON DELETE CASCADE,
      FOREIGN KEY (attempt_id) REFERENCES tool_execution_records(attempt_id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE conversation_task_evidence_links (
      evidence_id TEXT PRIMARY KEY NOT NULL,
      task_id TEXT NOT NULL,
      segment_id TEXT NOT NULL,
      attempt_id TEXT NOT NULL,
      CHECK (evidence_id = attempt_id || ':evidence'),
      FOREIGN KEY (task_id, segment_id, attempt_id)
        REFERENCES conversation_task_tool_attempts(task_id, segment_id, attempt_id) ON DELETE CASCADE,
      FOREIGN KEY (evidence_id) REFERENCES tool_evidence_records(evidence_id) ON DELETE CASCADE
    )
  ''');
  for (final (name, table, columns) in [
    (
      'conversation_tasks_chat_status_index',
      'conversation_tasks',
      'chat_id, status, updated_at',
    ),
    (
      'conversation_tasks_due_index',
      'conversation_tasks',
      'status, next_run_at',
    ),
    (
      'conversation_tasks_lease_expiry_index',
      'conversation_tasks',
      'lease_expires_at',
    ),
    (
      'conversation_task_approvals_pending_index',
      'conversation_task_approvals',
      'task_id, decision',
    ),
    (
      'conversation_task_tool_attempts_segment_index',
      'conversation_task_tool_attempts',
      'task_id, segment_id',
    ),
    (
      'conversation_task_evidence_links_segment_index',
      'conversation_task_evidence_links',
      'task_id, segment_id',
    ),
    ('messages_task_id_index', 'messages', 'task_id, task_message_kind'),
  ]) {
    await db.execute('CREATE INDEX $name ON $table($columns)');
  }
  for (final entry in _conversationTaskImmutableTables.entries) {
    await db.execute('''
      CREATE TRIGGER ${entry.key}_prevent_update BEFORE UPDATE ON ${entry.key}
      BEGIN SELECT RAISE(ABORT, 'Task facts are immutable'); END
    ''');
    await db.execute('''
      CREATE TRIGGER ${entry.key}_prevent_replace BEFORE INSERT ON ${entry.key}
      WHEN EXISTS (SELECT 1 FROM ${entry.key} WHERE ${entry.value})
      BEGIN SELECT RAISE(ABORT, 'Task facts cannot be replaced'); END
    ''');
    await db.execute('''
      CREATE TRIGGER ${entry.key}_prevent_delete BEFORE DELETE ON ${entry.key}
      WHEN EXISTS (SELECT 1 FROM conversation_tasks WHERE task_id = OLD.task_id)
      BEGIN SELECT RAISE(ABORT, 'Task facts can only be deleted with their task'); END
    ''');
  }
  await db.execute('''
    CREATE TRIGGER conversation_tasks_validate_origin BEFORE INSERT ON conversation_tasks
    WHEN NOT EXISTS (
      SELECT 1 FROM messages message JOIN chats chat ON chat.id = message.chat_id
      WHERE message.message_id = NEW.origin_user_message_id
        AND message.turn_id = NEW.origin_turn_id AND message.chat_id = NEW.chat_id
        AND message.bot_id = NEW.bot_id AND chat.bot_id = NEW.bot_id)
    BEGIN SELECT RAISE(ABORT, 'Task requires a matching persisted origin message'); END
  ''');
  await db.execute('''
    CREATE TRIGGER conversation_tasks_preserve_acceptance BEFORE UPDATE ON conversation_tasks
    WHEN OLD.retry_of_task_id IS NOT NEW.retry_of_task_id
      OR OLD.task_id IS NOT NEW.task_id OR OLD.chat_id IS NOT NEW.chat_id
      OR OLD.bot_id IS NOT NEW.bot_id OR OLD.origin_turn_id IS NOT NEW.origin_turn_id
      OR OLD.origin_user_message_id IS NOT NEW.origin_user_message_id
      OR OLD.ack_message_id IS NOT NEW.ack_message_id OR OLD.title IS NOT NEW.title
      OR OLD.objective IS NOT NEW.objective OR OLD.acceptance_json IS NOT NEW.acceptance_json
      OR OLD.created_at IS NOT NEW.created_at
      OR (OLD.cancel_requested_at IS NOT NULL AND (
        OLD.cancel_requested_at IS NOT NEW.cancel_requested_at OR OLD.cancellation_source IS NOT NEW.cancellation_source))
    BEGIN SELECT RAISE(ABORT, 'Task acceptance and cancellation intent are immutable'); END
  ''');
  await db.execute('''
    CREATE TRIGGER conversation_tasks_preserve_terminal BEFORE UPDATE ON conversation_tasks
    WHEN OLD.status IN ('succeeded', 'failed', 'cancelled')
    BEGIN SELECT RAISE(ABORT, 'Task terminal state is immutable'); END
  ''');
  await db.execute('''
    CREATE TRIGGER conversation_tasks_prevent_replace BEFORE INSERT ON conversation_tasks
    WHEN EXISTS (SELECT 1 FROM conversation_tasks WHERE task_id = NEW.task_id
      OR origin_turn_id = NEW.origin_turn_id OR origin_user_message_id = NEW.origin_user_message_id)
    BEGIN SELECT RAISE(ABORT, 'An accepted task cannot be replaced'); END
  ''');
  for (final timing in ['INSERT', 'UPDATE']) {
    await db.execute('''
      CREATE TRIGGER messages_validate_task_scope_${timing.toLowerCase()} BEFORE $timing ON messages
      WHEN NEW.task_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM conversation_tasks task WHERE task.task_id = NEW.task_id
          AND task.chat_id = NEW.chat_id AND task.bot_id = NEW.bot_id)
      BEGIN SELECT RAISE(ABORT, 'Message belongs to another task scope'); END
    ''');
  }
  await db.execute('''
    CREATE TRIGGER conversation_task_tool_attempts_validate_scope
    BEFORE INSERT ON conversation_task_tool_attempts
    WHEN NOT EXISTS (
      SELECT 1 FROM conversation_tasks task JOIN tool_execution_records execution
        ON execution.chat_id = task.chat_id AND execution.bot_id = task.bot_id
        AND execution.turn_id = task.origin_turn_id
      WHERE task.task_id = NEW.task_id AND execution.attempt_id = NEW.attempt_id)
    BEGIN SELECT RAISE(ABORT, 'Tool attempt belongs to another task scope'); END
  ''');
  await db.execute('''
    CREATE TRIGGER conversation_task_evidence_links_validate_scope
    BEFORE INSERT ON conversation_task_evidence_links
    WHEN NOT EXISTS (
      SELECT 1 FROM conversation_tasks task JOIN tool_evidence_records evidence
        ON evidence.chat_id = task.chat_id AND evidence.turn_id = task.origin_turn_id
      WHERE task.task_id = NEW.task_id AND evidence.evidence_id = NEW.evidence_id
        AND evidence.attempt_id = NEW.attempt_id)
    BEGIN SELECT RAISE(ABORT, 'Evidence belongs to another task scope'); END
  ''');
}
