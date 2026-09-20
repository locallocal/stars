import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import '../../support/task_runner_harness.dart';

void main() {
  late TaskRunnerHarness h;
  var preparations = 0;
  setUp(() async {
    h = TaskRunnerHarness();
    preparations = 0;
    await h.open(
      acceptance: taskAcceptance(
        deferredPreparation: true,
        allowedToolNames: const {},
        limits: TaskSegmentLimits(maxModelTurns: 1),
      ),
    );
    h.prepare = (task, token) async {
      preparations++;
      expect((await h.db.task).status, ConversationTaskStatus.running);
      expect(task.acceptance.allowedToolNames, isEmpty);
      return TaskExecutionPreparation(
        snapshot: TaskPreparationSnapshot(
          context: [
            TaskContextMessage(
              role: TaskContextRole.user,
              content: 'Fresh background context',
            ),
          ],
          allowedToolNames: {'read_file'},
          approvalExemptToolNames: {'read_file'},
        ),
        tools: [h.tool],
      );
    };
  });
  tearDown(() => h.close());

  void plan({String tool = 'read_file'}) => h.models.tool(
    name: 'stars_revise_task_plan',
    arguments: {
      'steps': [
        {'id': 'inspect', 'summary': 'Inspect the source'},
        {'id': 'summarize', 'summary': 'Summarize the findings'},
      ],
      'allowedToolNames': [tool],
    },
  );

  test(
    'fresh activation precedes planning; saved steps execute in order',
    () async {
      expect((await h.snapshot).plan.isPending, isTrue);
      expect((await h.snapshot).plan.steps, isEmpty);
      plan();
      expect(await h.run(), isA<TaskContinueSegment>());
      final planned = await h.snapshot;
      expect(preparations, 1);
      expect(planned.plan.allowedToolNames, {'read_file'});
      expect(planned.task.acceptance.allowedToolNames, isEmpty);
      expect(planned.approvalExemptToolNames, {'read_file'});
      expect(planned.plan.steps.map((step) => step.stepId), [
        'inspect',
        'summarize',
      ]);
      expect(planned.checkpoint!.nextStepId, 'inspect');
      expect(planned.attempts, isEmpty);
      expect(
        planned.events.where(
          (event) => event.kind == TaskEventKind.stepStarted,
        ),
        isEmpty,
      );
      final request = h.models.requests.single;
      expect(request.messages.first.content, 'Fresh background context');
      expect(request.tools.map((tool) => tool.name), [
        'stars_revise_task_plan',
      ]);
      final context = jsonDecode(request.messages.last.content) as Map;
      expect((context['available_tools'] as List).single['name'], 'read_file');

      await h.db.reopen();
      h.prepare = (_, _) => throw StateError('Already prepared');
      h.models.completeStep();
      await h.run();
      expect((await h.snapshot).checkpoint!.completedStepIds, ['inspect']);
      expect((await h.snapshot).checkpoint!.nextStepId, 'summarize');
      h.models.completeStep();
      await h.run();
      expect((await h.snapshot).checkpoint!.completedStepIds, [
        'inspect',
        'summarize',
      ]);
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(preparations, 1);
    },
  );

  test('planning failure resumes with the committed preparation', () async {
    plan(tool: 'unavailable_tool');
    expect(await h.run(), isA<TaskContinueSegment>());
    final pending = await h.snapshot;
    expect(pending.plan.isPending, isTrue);
    expect(pending.plan.preparation, isNotNull);
    expect(pending.attempts, isEmpty);
    await h.db.reopen();
    plan();
    await h.run();
    expect(preparations, 1);
    expect((await h.snapshot).plan.isPending, isFalse);
  });

  test(
    'interruption cancels activation and leaves a resumable pending task',
    () async {
      final entered = Completer<AgentCancellationToken>();
      final never = Completer<TaskExecutionPreparation>();
      h.prepare = (_, token) {
        entered.complete(token);
        return never.future;
      };
      final interruption = AgentCancellationToken();
      final running = h.run(interruption: interruption);
      final token = await entered.future;
      interruption.cancel();
      expect(await running, isA<TaskContinueSegment>());
      expect(token.isCancelled, isTrue);
      final pending = await h.snapshot;
      expect(pending.plan.preparation, isNull);
      expect(pending.plan.steps, isEmpty);
      expect(pending.task.lease, isNull);
      expect(h.models.requests, isEmpty);
    },
  );

  test(
    'saved preparation cannot be replaced to broaden tool permissions',
    () async {
      plan();
      await h.run();
      final task = await h.db.task;
      committed(
        await h.db.repository.tryAcquireLease(
          taskId: task.taskId,
          expectedRevision: task.revision,
          lease: taskLease(),
          now: h.clock.now(),
        ),
      );
      final current = await h.snapshot;
      final changed = ConversationTaskPlan(
        taskId: task.taskId,
        revision: current.plan.revision + 1,
        objective: task.objective,
        steps: current.plan.steps,
        allowedToolNames: {'read_file', 'shell'},
        preparation: TaskPreparationSnapshot(
          context: current.context,
          allowedToolNames: {'read_file', 'shell'},
        ),
        createdAt: h.db.nextTime,
      );
      await expectLater(
        h.db.repository.appendProgress(
          await h.db.update(TaskEventKind.planRevised, plan: changed),
        ),
        throwsArgumentError,
      );
      expect((await h.snapshot).toolScope, {'read_file'});
    },
  );
}
