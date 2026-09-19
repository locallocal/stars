import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';

ToolEvidenceRecord filePreviewEvidence({
  required String path,
  String messageId = 'message-with-local-files',
  String chatId = 'chat-1',
  String id = 'file',
  String toolName = 'custom.export',
  Set<ToolCapability> capabilities = const {ToolCapability.localWrite},
  bool persisted = true,
  DateTime? observedAt,
  DateTime? validUntil,
  Map<String, Object?>? scope,
  List<StructuredFact>? facts,
}) => ToolEvidenceRecord(
  evidenceId: ToolEvidenceRecord.evidenceIdForAttempt('$id:attempt:1'),
  runId: 'run-1',
  turnId: 'turn-1',
  chatId: chatId,
  messageId: messageId,
  invocationId: '$id:invocation:1',
  attemptId: '$id:attempt:1',
  toolName: toolName,
  toolVersion: '1.0.0',
  source: ToolSource.mcp,
  capabilities: capabilities,
  terminalStatus: ToolInvocationStatus.succeeded,
  evidenceKind: EvidenceKind.actionReceipt,
  subject: 'file:content',
  scope: scope ?? {'path': path},
  resultSummary: 'File operation completed.',
  argumentsDigest: 'a' * 64,
  resultDigest: 'b' * 64,
  structuredFacts:
      facts ??
      [
        StructuredFact(name: 'action.completed', value: true),
        StructuredFact(name: 'file.size_bytes', value: 3622),
      ],
  observedAt: observedAt ?? DateTime(2025, 12, 31, 23, 59, 30),
  validUntil: validUntil,
  persisted: persisted,
);

final class FilePreviewEvidenceRepository implements ToolEvidenceRepository {
  FilePreviewEvidenceRepository(this.records);

  final List<ToolEvidenceRecord> records;
  final invalidDigests = <String>{};
  final queriedMessages = <String>[];
  bool unavailable = false;

  @override
  Future<List<ToolEvidenceRecord>> getForMessage(String messageId) async {
    queriedMessages.add(messageId);
    if (unavailable) throw StateError('Evidence unavailable');
    return records.where((record) => record.messageId == messageId).toList();
  }

  @override
  Future<ToolEvidenceRecord?> getById(String evidenceId) async =>
      records.where((record) => record.evidenceId == evidenceId).firstOrNull;

  @override
  Future<bool> verifyDigest(String evidenceId) async =>
      !invalidDigests.contains(evidenceId);

  @override
  Future<List<ToolInvocationEvent>> getInvocationEventsForRun(
    String runId,
  ) async => const [];

  @override
  Future<void> commitRun({
    required String runId,
    required String chatId,
    required List<ToolInvocationEvent> invocationEvents,
    required List<ToolEvidenceRecord> evidenceRecords,
  }) async => throw UnsupportedError('Read-only test repository');
}
