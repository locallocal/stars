import 'package:stars/data/models/tool_evidence_record.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';

final class SqliteToolEvidenceRepository implements ToolEvidenceRepository {
  const SqliteToolEvidenceRepository({
    required LocalDatabaseService localDatabase,
  }) : _localDatabase = localDatabase;

  final LocalDatabaseService _localDatabase;

  @override
  Future<void> commitRun({
    required String runId,
    required String chatId,
    required List<ToolInvocationEvent> invocationEvents,
    required List<ToolEvidenceRecord> evidenceRecords,
  }) {
    if (runId.trim().isEmpty || chatId.trim().isEmpty) {
      throw ArgumentError('Run and chat identities cannot be empty.');
    }
    for (final event in invocationEvents) {
      if (event.runId != runId || event.chatId != chatId) {
        throw ArgumentError(
          'Invocation events must belong to the committed run and chat.',
        );
      }
    }
    for (final evidence in evidenceRecords) {
      if (evidence.runId != runId || evidence.chatId != chatId) {
        throw ArgumentError(
          'Evidence records must belong to the committed run and chat.',
        );
      }
    }
    return _localDatabase.commitToolEvidenceRun(
      invocationEvents: invocationEvents.map(
        (event) => ToolInvocationEventDbRecord.fromDomain(event).values,
      ),
      evidenceRecords: evidenceRecords.map(
        (evidence) => ToolEvidenceDbRecord.fromDomain(evidence).values,
      ),
    );
  }

  @override
  Future<ToolEvidenceRecord?> getById(String evidenceId) async {
    final rows = await _localDatabase.loadToolEvidenceById(evidenceId);
    if (rows.isEmpty) return null;
    return ToolEvidenceDbRecord(rows.single).toDomain();
  }

  @override
  Future<List<ToolEvidenceRecord>> getForMessage(String messageId) async {
    final rows = await _localDatabase.loadToolEvidenceForMessage(messageId);
    return List<ToolEvidenceRecord>.unmodifiable(
      rows.map((row) => ToolEvidenceDbRecord(row).toDomain()),
    );
  }

  @override
  Future<List<ToolInvocationEvent>> getInvocationEventsForRun(
    String runId,
  ) async {
    final rows = await _localDatabase.loadToolInvocationEventsForRun(runId);
    return List<ToolInvocationEvent>.unmodifiable(
      rows.map((row) => ToolInvocationEventDbRecord(row).toDomain()),
    );
  }

  @override
  Future<bool> verifyDigest(String evidenceId) async {
    final rows = await _localDatabase.loadToolEvidenceById(evidenceId);
    return rows.isNotEmpty && ToolEvidenceDbRecord(rows.single).hasValidDigest;
  }
}
