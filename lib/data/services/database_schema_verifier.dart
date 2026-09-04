part of 'database_service.dart';

Future<void> _verifyCurrentDatabaseSchema(
  Database database, {
  bool allowMissingToolExecutionSchema = false,
  bool allowMissingToolEvidenceSchema = false,
}) async {
  final tables = await database.rawQuery('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
  ''');
  final tableNames =
      tables.map((row) => row['name']).whereType<String>().toSet();
  if (!_matchesSchemaNames(tableNames, _currentTableNames, [
    if (allowMissingToolExecutionSchema) const {'tool_execution_records'},
    if (allowMissingToolEvidenceSchema) _toolEvidenceTableNames,
  ])) {
    throw const FormatException(
      'Database tables do not match the current Stars schema.',
    );
  }

  final indexes = await database.rawQuery('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'index' AND name NOT LIKE 'sqlite_autoindex_%'
  ''');
  final indexNames =
      indexes.map((row) => row['name']).whereType<String>().toSet();
  if (!_matchesSchemaNames(indexNames, _currentIndexNames, [
    if (allowMissingToolExecutionSchema) _toolExecutionIndexNames,
    if (allowMissingToolEvidenceSchema) _toolEvidenceIndexNames,
  ])) {
    throw const FormatException(
      'Database indexes do not match the current Stars schema.',
    );
  }

  final triggers = await database.rawQuery('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'trigger'
  ''');
  final triggerNames =
      triggers.map((row) => row['name']).whereType<String>().toSet();
  if (!_matchesSchemaNames(triggerNames, _currentTriggerNames, [
    if (allowMissingToolEvidenceSchema) _toolEvidenceTriggerNames,
  ])) {
    throw const FormatException(
      'Database triggers do not match the current Stars schema.',
    );
  }
}

Future<void> _createBotSkillReferenceValidationTriggers(
  DatabaseExecutor database,
) async {
  await _createSkillReferenceValidationTrigger(
    database,
    name: 'bot_skill_bindings_validate_skill_insert',
    timing: 'INSERT',
    table: 'bot_skill_bindings',
  );
  await _createSkillReferenceValidationTrigger(
    database,
    name: 'bot_skill_bindings_validate_skill_update',
    timing: 'UPDATE OF skill_id',
    table: 'bot_skill_bindings',
  );
}

Future<void> _createConversationSkillReferenceValidationTriggers(
  DatabaseExecutor database,
) async {
  await _createSkillReferenceValidationTrigger(
    database,
    name: 'conversation_skill_pins_validate_skill_insert',
    timing: 'INSERT',
    table: 'conversation_skill_pins',
  );
  await _createSkillReferenceValidationTrigger(
    database,
    name: 'conversation_skill_pins_validate_skill_update',
    timing: 'UPDATE OF skill_id',
    table: 'conversation_skill_pins',
  );
}

Future<void> _createSkillReferenceValidationTrigger(
  DatabaseExecutor database, {
  required String name,
  required String timing,
  required String table,
}) => database.execute('''
  CREATE TRIGGER $name
  BEFORE $timing ON $table
  WHEN substr(NEW.skill_id, 1, 7) != 'system:'
    AND NOT EXISTS (SELECT 1 FROM skills WHERE id = NEW.skill_id)
  BEGIN
    SELECT RAISE(ABORT, 'Referenced Skill is not installed');
  END
''');

bool _setsEqual<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);

bool _matchesSchemaNames(
  Set<String> actual,
  Set<String> current,
  List<Set<String>> optionalGroups,
) {
  var expectedSets = <Set<String>>[current];
  for (final group in optionalGroups) {
    expectedSets = <Set<String>>[
      ...expectedSets,
      for (final expected in expectedSets)
        <String>{...expected}..removeAll(group),
    ];
  }
  return expectedSets.any((expected) => _setsEqual(actual, expected));
}

const Set<String> _currentTableNames = <String>{
  'bots',
  'chats',
  'messages',
  'tool_execution_records',
  'tool_invocation_events',
  'tool_evidence_records',
  'answer_claim_evidence',
  'token_usage_records',
  'skills',
  'bot_skill_bindings',
  'skill_activations',
  'skill_publishers',
  'skill_catalogs',
  'skill_script_grants',
  'skill_organization_policy',
  'skill_compliance_events',
  'conversation_skill_pins',
  'mcp_servers',
  'mcp_tools',
  'conversation_memory_state',
  'conversation_summary_segments',
  'conversation_memory_items',
  'profile',
};

const Set<String> _currentIndexNames = <String>{
  'messages_message_id_unique',
  'messages_bot_id_index',
  'tool_execution_records_run_id_index',
  'tool_execution_records_chat_started_at_index',
  'tool_invocation_events_run_id_index',
  'tool_invocation_events_message_id_index',
  'tool_invocation_events_chat_time_index',
  'tool_evidence_records_run_id_index',
  'tool_evidence_records_message_id_index',
  'tool_evidence_records_observed_at_index',
  'tool_evidence_records_chat_observed_index',
  'answer_claim_evidence_evidence_id_index',
  'token_usage_records_chat_id_index',
  'token_usage_records_bot_id_index',
  'bot_skill_bindings_skill_id_index',
  'skill_activations_run_id_index',
  'skill_activations_chat_id_index',
  'skill_compliance_events_skill_id_index',
  'conversation_skill_pins_skill_id_index',
  'conversation_summary_chat_status_index',
  'conversation_memory_chat_key_index',
  'messages_chat_timestamp_message_index',
  'mcp_tools_server_id_index',
};

const Set<String> _toolEvidenceTableNames = <String>{
  'tool_invocation_events',
  'tool_evidence_records',
  'answer_claim_evidence',
};

const Set<String> _toolExecutionIndexNames = <String>{
  'tool_execution_records_run_id_index',
  'tool_execution_records_chat_started_at_index',
};

const Set<String> _toolEvidenceIndexNames = <String>{
  'tool_invocation_events_run_id_index',
  'tool_invocation_events_message_id_index',
  'tool_invocation_events_chat_time_index',
  'tool_evidence_records_run_id_index',
  'tool_evidence_records_message_id_index',
  'tool_evidence_records_observed_at_index',
  'tool_evidence_records_chat_observed_index',
  'answer_claim_evidence_evidence_id_index',
};

const Set<String> _currentTriggerNames = <String>{
  'bot_skill_bindings_validate_skill_insert',
  'bot_skill_bindings_validate_skill_update',
  'conversation_skill_pins_validate_skill_insert',
  'conversation_skill_pins_validate_skill_update',
  'tool_invocation_events_prevent_update',
  'tool_evidence_records_prevent_update',
  'answer_claim_evidence_prevent_update',
};

const Set<String> _toolEvidenceTriggerNames = <String>{
  'tool_invocation_events_prevent_update',
  'tool_evidence_records_prevent_update',
  'answer_claim_evidence_prevent_update',
};
