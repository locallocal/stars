import 'dart:convert';

import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_execution.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/shell_command.dart';

enum TaskAttemptTone { completed, active, attention, stopped }

/// Immutable display data prepared outside widget builds.
final class TaskExecutionPresentation {
  TaskExecutionPresentation(ConversationTaskExecution execution) {
    final attemptsByInvocation = <String, int>{};
    attempts = List.unmodifiable([
      for (final (index, call) in execution.processInfo.toolCalls.indexed)
        TaskAttemptPresentation(
          call,
          index: index,
          attemptNumber:
              call.invocationId.isEmpty
                  ? 1
                  : attemptsByInvocation.update(
                    call.invocationId,
                    (n) => n + 1,
                    ifAbsent: () => 1,
                  ),
        ),
    ]);
    counts = Map.unmodifiable({
      for (final tone in TaskAttemptTone.values)
        tone: attempts.where((attempt) => attempt.tone == tone).length,
    });
    final ordered = [...execution.activities]
      ..sort((a, b) => b.event.sequence.compareTo(a.event.sequence));
    activities = List.unmodifiable(ordered);
    milestones = List.unmodifiable(
      ordered.where(
        (activity) =>
            !{
              TaskEventKind.modelTurnCompleted,
              TaskEventKind.segmentCheckpoint,
              TaskEventKind.segmentProgress,
              TaskEventKind.toolQueued,
              TaskEventKind.evidenceAccepted,
              TaskEventKind.externalJobUpdated,
            }.contains(activity.event.kind),
      ),
    );
  }

  late final List<TaskAttemptPresentation> attempts;
  late final Map<TaskAttemptTone, int> counts;
  late final List<TaskExecutionActivity> activities, milestones;
}

final class TaskAttemptPresentation {
  TaskAttemptPresentation(
    this.call, {
    required int index,
    required this.attemptNumber,
  }) {
    id =
        call.attemptId.isNotEmpty
            ? call.attemptId
            : call.executionId.isNotEmpty
            ? call.executionId
            : '${call.callId}:$index';
    var commandValue = '';
    var directoryValue = '';
    var argumentsValue = call.argumentsSummary;
    try {
      final decoded = jsonDecode(argumentsValue);
      if (decoded is Map<String, dynamic>) {
        final fields = Map<String, Object?>.from(decoded);
        if (call.name == shellCommandToolName) {
          if (fields['command'] case final String value) {
            commandValue = value;
            fields.remove('command');
          }
          if (fields['working_directory'] case final String value) {
            directoryValue = value;
            fields.remove('working_directory');
          }
        }
        argumentsValue =
            fields.isEmpty
                ? ''
                : const JsonEncoder.withIndent('  ').convert(fields);
      }
    } on FormatException {
      // Historical arguments may be a text summary rather than JSON.
    }
    command = commandValue;
    workingDirectory = directoryValue;
    arguments = argumentsValue;
  }

  final MessageToolCall call;
  final int attemptNumber;
  late final String id;
  late final String command, workingDirectory, arguments;

  bool get isCommand => call.name == shellCommandToolName;
  String get title =>
      call.title.trim().isNotEmpty ? call.title.trim() : call.name;
  String get preview => command.trim().replaceAll(RegExp(r'\s+'), ' ');
  TaskAttemptTone get tone => switch (call.status) {
    'succeeded' ||
    'completed' ||
    'duplicateReused' => TaskAttemptTone.completed,
    'requested' || 'running' || 'streaming' => TaskAttemptTone.active,
    'cancelled' || 'skipped' => TaskAttemptTone.stopped,
    _ => TaskAttemptTone.attention,
  };
}
