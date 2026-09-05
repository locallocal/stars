import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/agent_run_recovery_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/repositories/tool_execution_repository.dart';

typedef RecoveredMessageObserver = Future<void> Function(Message message);

final class AgentRunRecoveryReport {
  const AgentRunRecoveryReport({
    this.interruptedInvocations = 0,
    this.recoveredAnswers = 0,
    this.failedAnswers = 0,
  });

  final int interruptedInvocations;
  final int recoveredAnswers;
  final int failedAnswers;
}

/// Deterministically reconciles durable Agent Loop state during startup.
///
/// It appends terminal audit events and commits messages only. In particular,
/// it has no dependency capable of executing a tool or opening a model session.
final class RecoverAgentRuns {
  const RecoverAgentRuns({
    required AgentRunRecoveryRepository recoveryRepository,
    required MessageRepository messageRepository,
    required GroundedMessageRepository groundedMessageRepository,
    required ToolEvidenceRepository evidenceRepository,
    required ToolExecutionRepository executionRepository,
    RecoveredMessageObserver? onRecoveredMessage,
  }) : _recoveryRepository = recoveryRepository,
       _messageRepository = messageRepository,
       _groundedMessageRepository = groundedMessageRepository,
       _evidenceRepository = evidenceRepository,
       _executionRepository = executionRepository,
       _onRecoveredMessage = onRecoveredMessage;

  final AgentRunRecoveryRepository _recoveryRepository;
  final MessageRepository _messageRepository;
  final GroundedMessageRepository _groundedMessageRepository;
  final ToolEvidenceRepository _evidenceRepository;
  final ToolExecutionRepository _executionRepository;
  final RecoveredMessageObserver? _onRecoveredMessage;

  Future<AgentRunRecoveryReport> call({DateTime? recoveredAt}) async {
    final instant = (recoveredAt ?? DateTime.now()).toUtc();
    var interrupted = 0;
    var recovered = 0;
    var failed = 0;

    final nonTerminal =
        await _recoveryRepository.loadLatestNonTerminalInvocations();
    for (final invocation in nonTerminal) {
      await _recoveryRepository.appendInterruptedInvocation(
        invocation,
        occurredAt: instant,
      );
      interrupted += 1;
    }

    final messagesByChat = <String, List<Message>>{};
    Future<List<Message>> messagesFor(String chatId) async {
      final cached = messagesByChat[chatId];
      if (cached != null) return cached;
      return _loadMessages(messagesByChat, chatId);
    }

    final handledRuns = <String>{};
    final pending = await _recoveryRepository.loadPendingAnswers();
    for (final target in pending) {
      handledRuns.add(target.runId);
      final messages = await messagesFor(target.chatId);
      final current = _findMessage(messages, target.messageId);
      if (_isCommittedTerminal(current)) {
        await _onRecoveredMessage?.call(current!);
        await _recoveryRepository.clearAnswer(target.runId);
        continue;
      }
      if (await _hasValidEvidence(target)) {
        try {
          final committed = await _groundedMessageRepository
              .upsertGroundedMessage(target);
          _replaceMessage(messages, committed);
          await _onRecoveredMessage?.call(committed);
          await _recoveryRepository.clearAnswer(target.runId);
          recovered += 1;
          continue;
        } on Object {
          // A deterministic failed message below closes an unrecoverable gap.
        }
      }
      final failure = _safeFailure(
        current ?? target,
        reasonCode: 'recovery_answer_commit_failed',
      );
      final persisted = await _messageRepository.upsertMessage(failure);
      _replaceMessage(messages, persisted);
      await _onRecoveredMessage?.call(persisted);
      await _recoveryRepository.clearAnswer(target.runId);
      failed += 1;
    }

    final evidence = await _recoveryRepository.loadEvidenceAwaitingAnswer();
    final evidenceByRun = <String, List<ToolEvidenceRecord>>{};
    for (final item in evidence) {
      (evidenceByRun[item.runId] ??= <ToolEvidenceRecord>[]).add(item);
    }
    for (final entry in evidenceByRun.entries) {
      if (handledRuns.contains(entry.key)) continue;
      final first = entry.value.first;
      final messages = await messagesFor(first.chatId);
      final current = _findMessage(messages, first.messageId);
      if (_isCommittedTerminal(current)) continue;
      final draft = current ?? await _orphanFailureDraft(first, instant);
      if (draft == null) continue;
      final persisted = await _messageRepository.upsertMessage(
        _safeFailure(draft, reasonCode: 'recovery_answer_checkpoint_missing'),
      );
      _replaceMessage(messages, persisted);
      await _onRecoveredMessage?.call(persisted);
      failed += 1;
    }

    return AgentRunRecoveryReport(
      interruptedInvocations: interrupted,
      recoveredAnswers: recovered,
      failedAnswers: failed,
    );
  }

  Future<List<Message>> _loadMessages(
    Map<String, List<Message>> cache,
    String chatId,
  ) async {
    final loaded = (await _messageRepository.getMessages(chatId)).toList();
    cache[chatId] = loaded;
    return loaded;
  }

  Message? _findMessage(List<Message> messages, String messageId) {
    for (final message in messages) {
      if (message.messageId == messageId) return message;
    }
    return null;
  }

  bool _isCommittedTerminal(Message? message) =>
      message?.terminalOutcome != null &&
      message!.grounding.reasonCode != 'evidence_commit_pending';

  Future<bool> _hasValidEvidence(Message target) async {
    if (target.terminalOutcome != MessageTerminalOutcome.completed ||
        target.grounding.evidenceIds.isEmpty) {
      return false;
    }
    for (final evidenceId in target.grounding.evidenceIds) {
      try {
        final evidence = await _evidenceRepository.getById(evidenceId);
        if (evidence == null ||
            !evidence.persisted ||
            evidence.runId != target.runId ||
            evidence.turnId != target.turnId ||
            evidence.chatId != target.chatId ||
            evidence.messageId != target.messageId ||
            !await _evidenceRepository.verifyDigest(evidenceId)) {
          return false;
        }
      } on Object {
        return false;
      }
    }
    return true;
  }

  Future<Message?> _orphanFailureDraft(
    ToolEvidenceRecord evidence,
    DateTime instant,
  ) async {
    final executions = await _executionRepository.getForRun(evidence.runId);
    if (evidence.messageId.isEmpty) return null;
    final botId =
        executions.isEmpty
            ? await _recoveryRepository.loadBotIdForChat(evidence.chatId) ?? ''
            : executions.first.botId;
    if (botId.isEmpty) return null;
    return Message(
      messageId: evidence.messageId,
      turnId: evidence.turnId,
      runId: evidence.runId,
      chatId: evidence.chatId,
      botId: botId,
      senderId: botId,
      content: '',
      processInfo: MessageProcessInfo(
        reasoningStatus: MessageTerminalOutcome.failed.name,
        toolCalls: [for (final item in executions) _messageToolCall(item)],
      ),
      grounding: MessageGrounding(
        trustLevel: AnswerTrustLevel.failed,
        reasonCode: 'recovery_answer_checkpoint_missing',
      ),
      terminalOutcome: MessageTerminalOutcome.failed,
      timestamp: instant,
    );
  }

  Message _safeFailure(Message source, {required String reasonCode}) {
    return source.copyWith(
      content: '',
      reasoning: '',
      processInfo: MessageProcessInfo(
        reasoningStatus: MessageTerminalOutcome.failed.name,
        durationMs: source.processInfo.durationMs,
        toolCalls: [
          for (final call in source.processInfo.toolCalls)
            _interruptMessageToolCall(call),
        ],
        commandExecutions: source.processInfo.commandExecutions,
        fileEdits: source.processInfo.fileEdits,
        skillActivations: source.processInfo.skillActivations,
      ),
      grounding: MessageGrounding(
        trustLevel: AnswerTrustLevel.failed,
        reasonCode: reasonCode,
      ),
      terminalOutcome: MessageTerminalOutcome.failed,
      hasPartialContent: false,
    );
  }

  MessageToolCall _interruptMessageToolCall(MessageToolCall call) {
    if (call.status != ToolInvocationStatus.requested.name &&
        call.status != ToolInvocationStatus.awaitingApproval.name &&
        call.status != ToolInvocationStatus.running.name) {
      return call;
    }
    return call.copyWith(
      status: ToolInvocationStatus.interrupted.name,
      detail: 'agent_run_interrupted',
      errorCode: 'agent_run_interrupted',
    );
  }

  MessageToolCall _messageToolCall(ToolExecutionRecord record) =>
      MessageToolCall(
        executionId: record.executionId,
        invocationId: record.invocationId,
        attemptId: record.attemptId,
        providerCallId: record.providerCallId,
        callId: record.callId,
        name: record.name,
        title: record.title,
        mcpServerName: record.mcpServerName,
        status:
            record.status == ToolInvocationStatus.requested ||
                    record.status == ToolInvocationStatus.awaitingApproval ||
                    record.status == ToolInvocationStatus.running
                ? ToolInvocationStatus.interrupted.name
                : record.status.name,
        detail:
            record.status == ToolInvocationStatus.requested ||
                    record.status == ToolInvocationStatus.awaitingApproval ||
                    record.status == ToolInvocationStatus.running
                ? 'agent_run_interrupted'
                : record.detail,
        source: record.source.name,
        riskLevel: record.riskLevel.name,
        argumentsSummary: record.argumentsSummary,
        resultSummary: record.resultSummary,
        approvalStatus: record.approvalStatus,
        errorCode:
            record.status == ToolInvocationStatus.requested ||
                    record.status == ToolInvocationStatus.awaitingApproval ||
                    record.status == ToolInvocationStatus.running
                ? 'agent_run_interrupted'
                : record.errorCode,
        durationMs: record.durationMs,
      );

  void _replaceMessage(List<Message> messages, Message message) {
    final index = messages.indexWhere(
      (existing) => existing.messageId == message.messageId,
    );
    if (index < 0) {
      messages.add(message);
    } else {
      messages[index] = message;
    }
  }
}
