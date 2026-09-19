import 'dart:convert';

import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_execution.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/shell_command.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/services/task_execution_details.dart';
import 'package:stars/domain/services/task_safe_data.dart';

/// Projects the task's own attempt links, including prior segments and retries.
final class GetConversationTaskExecution {
  const GetConversationTaskExecution(this.repository);

  final ConversationTaskRepository repository;

  Future<ConversationTaskExecution?> call({
    required String taskId,
    required String chatId,
    required String botId,
  }) async {
    final snapshot = await repository.getExecutionSnapshot(taskId);
    if (snapshot == null ||
        snapshot.task.chatId != chatId ||
        snapshot.task.botId != botId) {
      return null;
    }
    final events = [...snapshot.events]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final firstSequence = <String, int>{};
    for (final event in events) {
      if (event.attemptId case final id?) {
        firstSequence.putIfAbsent(id, () => event.sequence);
      }
    }
    final attempts = [...snapshot.attempts]..sort((a, b) {
      final order = (firstSequence[a.attemptId] ?? snapshot.lastSequence + 1)
          .compareTo(firstSequence[b.attemptId] ?? snapshot.lastSequence + 1);
      if (order != 0) return order;
      final time = a.startedAt.compareTo(b.startedAt);
      return time == 0 ? a.attemptId.compareTo(b.attemptId) : time;
    });
    final names = {
      for (final attempt in attempts) attempt.attemptId: attempt.name,
    };
    return ConversationTaskExecution(
      revision: snapshot.task.revision,
      processInfo: MessageProcessInfo(
        toolCalls: List.unmodifiable([
          for (final attempt in attempts)
            MessageToolCall(
              executionId: attempt.executionId,
              invocationId: attempt.invocationId,
              attemptId: attempt.attemptId,
              providerCallId: attempt.providerCallId,
              callId: attempt.callId,
              name: taskSafeText(attempt.name),
              title: taskSafeText(attempt.title),
              mcpServerName: taskSafeText(attempt.mcpServerName),
              status: attempt.status.name,
              source: attempt.source.name,
              riskLevel: attempt.riskLevel.name,
              argumentsSummary: taskExecutionArguments(
                attempt.argumentsSummary,
              ),
              resultSummary: taskExecutionOutput(
                attempt.detail.isEmpty ||
                        attempt.detail.startsWith('Task execution:')
                    ? attempt.resultSummary
                    : attempt.detail,
              ),
              approvalStatus: attempt.approvalStatus,
              errorCode: attempt.errorCode,
              durationMs: attempt.durationMs,
            ),
        ]),
        commandExecutions: List.unmodifiable([
          for (final attempt in attempts)
            if (attempt.name == shellCommandToolName)
              if (_command(attempt.argumentsSummary) case final command?)
                MessageCommandExecution(
                  callId: attempt.attemptId,
                  command: command,
                  status: attempt.status.name,
                  durationMs: attempt.durationMs,
                ),
        ]),
      ),
      activities: [
        for (final event in events)
          TaskExecutionActivity(
            event: event,
            terminalStatus:
                event.kind == TaskEventKind.terminal &&
                        snapshot.task.status.isTerminal
                    ? snapshot.task.status
                    : null,
            subject: taskSafeText(
              names[event.attemptId] ??
                  (event.stepId != null &&
                          !event.safeSummary.startsWith('Task execution:')
                      ? event.safeSummary
                      : ''),
            ),
          ),
      ],
    );
  }
}

String? _command(String arguments) {
  try {
    final decoded = jsonDecode(taskExecutionArguments(arguments));
    if (decoded case {'command': final String command}) return command;
  } on FormatException {
    // Older audit records may have no arguments or only a text summary.
  }
  return null;
}
