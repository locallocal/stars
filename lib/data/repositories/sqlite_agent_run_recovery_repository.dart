import 'dart:convert';

import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/models/tool_evidence_record.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/agent_run_recovery_repository.dart';

final class SqliteAgentRunRecoveryRepository
    implements AgentRunRecoveryRepository {
  const SqliteAgentRunRecoveryRepository({
    required LocalDatabaseService localDatabase,
  }) : _localDatabase = localDatabase;

  final LocalDatabaseService _localDatabase;

  @override
  Future<void> stageAnswer(Message terminalMessage) async {
    if (terminalMessage.runId.isEmpty ||
        terminalMessage.messageId.isEmpty ||
        terminalMessage.terminalOutcome != MessageTerminalOutcome.completed ||
        terminalMessage.grounding.evidenceIds.isEmpty) {
      throw ArgumentError.value(
        terminalMessage,
        'terminalMessage',
        'Recovery checkpoints require a completed evidence-backed answer.',
      );
    }
    await _localDatabase.upsertAgentRunAnswerCheckpoint(<String, Object?>{
      'run_id': terminalMessage.runId,
      'chat_id': terminalMessage.chatId,
      'message_id': terminalMessage.messageId,
      'terminal_message_json': jsonEncode(
        MessageRecord.fromDomain(terminalMessage).values,
      ),
      'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<Message>> loadPendingAnswers() async {
    final rows = await _localDatabase.loadAgentRunAnswerCheckpoints();
    final messages = <Message>[];
    for (final row in rows) {
      try {
        final source = row['terminal_message_json'];
        if (source is! String) {
          throw const FormatException(
            'Recovery checkpoint payload is invalid.',
          );
        }
        final decoded = jsonDecode(source);
        if (decoded is! Map) {
          throw const FormatException('Recovery checkpoint must be an object.');
        }
        final message =
            MessageRecord(Map<String, Object?>.from(decoded)).toDomain();
        if (message.runId != row['run_id'] ||
            message.chatId != row['chat_id'] ||
            message.messageId != row['message_id']) {
          throw const FormatException('Recovery identity mismatch.');
        }
        messages.add(message);
      } on Object {
        final runId = row['run_id']?.toString() ?? '';
        final chatId = row['chat_id']?.toString() ?? '';
        final messageId = row['message_id']?.toString() ?? '';
        final botId = await _localDatabase.loadRecoveryBotIdForChat(chatId);
        if (runId.isEmpty ||
            chatId.isEmpty ||
            messageId.isEmpty ||
            botId == null) {
          throw const FormatException(
            'Recovery checkpoint has no recoverable identity.',
          );
        }
        messages.add(
          Message(
            messageId: messageId,
            turnId: runId,
            runId: runId,
            chatId: chatId,
            botId: botId,
            senderId: botId,
            content: '',
            grounding: MessageGrounding(
              trustLevel: AnswerTrustLevel.failed,
              reasonCode: 'recovery_checkpoint_invalid',
            ),
            terminalOutcome: MessageTerminalOutcome.failed,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              row['created_at'] is int ? row['created_at']! as int : 0,
              isUtc: true,
            ),
          ),
        );
      }
    }
    return List<Message>.unmodifiable(messages);
  }

  @override
  Future<void> clearAnswer(String runId) =>
      _localDatabase.deleteAgentRunAnswerCheckpoint(runId);

  @override
  Future<List<ToolInvocationEvent>> loadLatestNonTerminalInvocations() async {
    final rows =
        await _localDatabase.loadLatestNonTerminalToolInvocationEvents();
    return List<ToolInvocationEvent>.unmodifiable(
      rows.map((row) => ToolInvocationEventDbRecord(row).toDomain()),
    );
  }

  @override
  Future<void> appendInterruptedInvocation(
    ToolInvocationEvent latest, {
    required DateTime occurredAt,
  }) {
    if (latest.isTerminal) return Future<void>.value();
    final interrupted = ToolInvocationEvent(
      eventId: ToolInvocationEvent.eventIdForAttempt(
        latest.attemptId,
        latest.sequence + 1,
      ),
      runId: latest.runId,
      turnId: latest.turnId,
      chatId: latest.chatId,
      messageId: latest.messageId,
      invocationId: latest.invocationId,
      attemptId: latest.attemptId,
      providerCallId: latest.providerCallId,
      toolName: latest.toolName,
      toolVersion: latest.toolVersion,
      source: latest.source,
      status: ToolInvocationStatus.interrupted,
      sequence: latest.sequence + 1,
      occurredAt: occurredAt.toUtc(),
      errorCode: 'agent_run_interrupted',
    );
    return _localDatabase.appendInterruptedToolInvocation(
      ToolInvocationEventDbRecord.fromDomain(interrupted).values,
    );
  }

  @override
  Future<List<ToolEvidenceRecord>> loadEvidenceAwaitingAnswer() async {
    final rows = await _localDatabase.loadEvidenceAwaitingAnswer();
    return List<ToolEvidenceRecord>.unmodifiable(
      rows.map((row) => ToolEvidenceDbRecord(row).toDomain()),
    );
  }

  @override
  Future<String?> loadBotIdForChat(String chatId) =>
      _localDatabase.loadRecoveryBotIdForChat(chatId);
}
