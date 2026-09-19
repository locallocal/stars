import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_execution.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/ui/features/chat/view_models/task_execution_presentation.dart';

void main() {
  test(
    'retains each retry and separates shell fields without losing options',
    () {
      final presentation = TaskExecutionPresentation(
        _execution(
          calls: const [
            MessageToolCall(
              attemptId: 'first',
              invocationId: 'shell-1',
              name: 'run_shell_command',
              status: 'failed',
              argumentsSummary:
                  '{"command":"flutter test\\n--reporter expanded","working_directory":"/project","timeout_seconds":30}',
            ),
            MessageToolCall(
              attemptId: 'second',
              invocationId: 'shell-1',
              name: 'run_shell_command',
              status: 'running',
            ),
            MessageToolCall(name: 'read_file', status: 'succeeded'),
            MessageToolCall(name: 'write_file', status: 'cancelled'),
            MessageToolCall(name: 'write_file', status: 'awaitingApproval'),
          ],
        ),
      );
      final first = presentation.attempts.first;
      expect(first.command, 'flutter test\n--reporter expanded');
      expect(first.preview, 'flutter test --reporter expanded');
      expect(first.workingDirectory, '/project');
      expect(first.arguments, '{\n  "timeout_seconds": 30\n}');
      expect(presentation.attempts[1].id, 'second');
      expect(presentation.attempts[1].attemptNumber, 2);
      expect(presentation.attempts[2].attemptNumber, 1);
      expect(presentation.counts, {
        TaskAttemptTone.completed: 1,
        TaskAttemptTone.active: 1,
        TaskAttemptTone.attention: 2,
        TaskAttemptTone.stopped: 1,
      });
    },
  );

  test(
    'keeps historical summaries and malformed command fields inspectable',
    () {
      final presentation = TaskExecutionPresentation(
        _execution(
          calls: const [
            MessageToolCall(
              name: 'run_shell_command',
              argumentsSummary: 'Historical command summary…',
            ),
            MessageToolCall(
              name: 'run_shell_command',
              argumentsSummary: '{"command":null,"working_directory":42}',
            ),
            MessageToolCall(name: 'read_file', argumentsSummary: '{}'),
          ],
        ),
      );
      expect(presentation.attempts[0].arguments, 'Historical command summary…');
      expect(presentation.attempts[1].command, isEmpty);
      expect(presentation.attempts[1].arguments, contains('"command": null'));
      expect(presentation.attempts[1].arguments, contains('42'));
      expect(presentation.attempts[2].arguments, isEmpty);
      expect(presentation.attempts.map((a) => a.id).toSet().length, 3);
    },
  );

  test(
    'shows newest progress first and retains checkpoints in the full ledger',
    () {
      final execution = _execution(
        activities: [
          _activity(2, TaskEventKind.segmentCheckpoint),
          _activity(1, TaskEventKind.queued),
          _activity(3, TaskEventKind.toolFailed),
        ],
      );
      final presentation = TaskExecutionPresentation(execution);
      expect(presentation.activities.map((a) => a.event.sequence), [3, 2, 1]);
      expect(presentation.milestones.map((a) => a.event.sequence), [3, 1]);
      expect(execution.activities.first.event.sequence, 2);
      expect(() => presentation.activities.clear(), throwsUnsupportedError);
      expect(() => presentation.attempts.clear(), throwsUnsupportedError);
    },
  );
}

ConversationTaskExecution _execution({
  List<MessageToolCall> calls = const [],
  List<TaskExecutionActivity> activities = const [],
}) => ConversationTaskExecution(
  revision: 1,
  processInfo: MessageProcessInfo(toolCalls: calls),
  activities: activities,
);

TaskExecutionActivity _activity(int sequence, TaskEventKind kind) =>
    TaskExecutionActivity(
      event: ConversationTaskEvent(
        taskId: 'task-1',
        sequence: sequence,
        kind: kind,
        occurredAt: DateTime(2026, 9, 19),
        safeSummary: 'Progress',
      ),
    );
