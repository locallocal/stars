part of 'database_service.dart';

Future<void> _createGroundingReliabilitySchema(
  DatabaseExecutor database,
) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS agent_run_answer_checkpoints (
      run_id TEXT PRIMARY KEY CHECK (length(run_id) > 0),
      chat_id TEXT NOT NULL CHECK (length(chat_id) > 0),
      message_id TEXT NOT NULL UNIQUE CHECK (length(message_id) > 0),
      terminal_message_json TEXT NOT NULL
        CHECK (length(terminal_message_json) > 0),
      created_at INTEGER NOT NULL,
      FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS grounding_metric_counters (
      metric TEXT NOT NULL CHECK (length(metric) > 0),
      category TEXT NOT NULL DEFAULT '',
      count INTEGER NOT NULL DEFAULT 0 CHECK (count >= 0),
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (metric, category)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS grounding_metric_observations (
      observation_id TEXT PRIMARY KEY
        CHECK (
          length(observation_id) = 72
          AND observation_id GLOB 'message_[0-9a-f]*'
          AND substr(observation_id, 9) NOT GLOB '*[^0-9a-f]*'
        ),
      recorded_at INTEGER NOT NULL
    )
  ''');
}
