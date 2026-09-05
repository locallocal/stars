import 'package:stars/domain/models/models.dart';

/// Durable recovery data. Implementations may mutate only local protocol state;
/// recovery never invokes a tool or contacts a Provider.
abstract interface class AgentRunRecoveryRepository {
  Future<void> stageAnswer(Message terminalMessage);

  Future<List<Message>> loadPendingAnswers();

  Future<void> clearAnswer(String runId);

  Future<List<ToolInvocationEvent>> loadLatestNonTerminalInvocations();

  Future<void> appendInterruptedInvocation(
    ToolInvocationEvent latest, {
    required DateTime occurredAt,
  });

  Future<List<ToolEvidenceRecord>> loadEvidenceAwaitingAnswer();

  Future<String?> loadBotIdForChat(String chatId);
}
