part of 'local_database_service.dart';

extension LocalDatabaseToolEvidence on LocalDatabaseService {
  Future<void> upsertGroundedMessage(
    Map<String, Object?> values, {
    required Map<String, Iterable<String>> claimEvidenceIds,
  }) async {
    final messageId = values['message_id']?.toString() ?? '';
    if (messageId.isEmpty) {
      throw ArgumentError('Grounded messages require an identity.');
    }
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await _upsertMessageAndTokenUsage(transaction, values);
      for (final entry in claimEvidenceIds.entries) {
        final identifiers = entry.value.toSet().toList(growable: false)..sort();
        for (final evidenceId in identifiers) {
          await transaction.insert('answer_claim_evidence', <String, Object?>{
            'message_id': messageId,
            'claim_id': entry.key,
            'evidence_id': evidenceId,
            'created_at': values['timestamp'] ?? 0,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    });
    final chatId = values['chat_id']?.toString() ?? '';
    if (chatId.isNotEmpty) _advanceMessageRevision(chatId);
  }

  Future<void> commitToolEvidenceRun({
    required Iterable<Map<String, Object?>> invocationEvents,
    required Iterable<Map<String, Object?>> evidenceRecords,
  }) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      for (final event in invocationEvents) {
        await _insertImmutableLedgerRecord(
          transaction,
          table: 'tool_invocation_events',
          identityColumn: 'event_id',
          values: event,
        );
      }
      for (final evidence in evidenceRecords) {
        await _insertImmutableLedgerRecord(
          transaction,
          table: 'tool_evidence_records',
          identityColumn: 'evidence_id',
          values: evidence,
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> loadToolEvidenceById(
    String evidenceId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'tool_evidence_records',
      where: 'evidence_id = ?',
      whereArgs: [evidenceId],
      limit: 1,
    );
  }

  Future<List<Map<String, Object?>>> loadToolEvidenceForMessage(
    String messageId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'tool_evidence_records',
      where: 'message_id = ?',
      whereArgs: [messageId],
      orderBy: 'observed_at ASC, evidence_id ASC',
    );
  }

  Future<List<Map<String, Object?>>> loadToolInvocationEventsForRun(
    String runId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'tool_invocation_events',
      where: 'run_id = ?',
      whereArgs: [runId],
      orderBy: 'occurred_at ASC, sequence ASC, event_id ASC',
    );
  }

  Future<void> deleteToolEvidenceForChat(String chatId) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await transaction.delete(
        'agent_run_answer_checkpoints',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
      await transaction.delete(
        'tool_evidence_records',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
      await transaction.delete(
        'tool_invocation_events',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
    });
  }
}

Future<void> _insertImmutableLedgerRecord(
  DatabaseExecutor database, {
  required String table,
  required String identityColumn,
  required Map<String, Object?> values,
}) async {
  final identity = values[identityColumn];
  final digest = values['record_digest'];
  final existing = await database.query(
    table,
    columns: const ['record_digest'],
    where: '$identityColumn = ?',
    whereArgs: [identity],
    limit: 1,
  );
  if (existing.isEmpty) {
    await database.insert(table, values);
    return;
  }
  if (existing.single['record_digest'] != digest) {
    throw StateError(
      'Immutable ledger identity conflict in $table for $identity.',
    );
  }
}
