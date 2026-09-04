import 'package:stars/domain/models/tool.dart';

/// Append-only persistence boundary for tool audit events and evidence.
abstract interface class ToolEvidenceRepository {
  /// Atomically commits the ledger records produced by one run.
  ///
  /// Repeating an identical record is idempotent. Reusing an event or
  /// evidence identity with different content must fail the whole batch.
  Future<void> commitRun({
    required String runId,
    required String chatId,
    required List<ToolInvocationEvent> invocationEvents,
    required List<ToolEvidenceRecord> evidenceRecords,
  });

  Future<ToolEvidenceRecord?> getById(String evidenceId);

  Future<List<ToolEvidenceRecord>> getForMessage(String messageId);

  Future<List<ToolInvocationEvent>> getInvocationEventsForRun(String runId);

  /// Recomputes the stored record digest without returning untrusted fields.
  Future<bool> verifyDigest(String evidenceId);
}
