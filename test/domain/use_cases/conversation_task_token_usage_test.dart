import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/provider_failure.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import '../../support/task_runner_harness.dart';

void main() {
  late TaskRunnerHarness h;
  setUp(() => h = TaskRunnerHarness());
  tearDown(() => h.close());

  test(
    'cumulative streaming reports count once per attempt across restart',
    () async {
      await h.open(limits: TaskSegmentLimits(maxModelTurns: 1));
      h.models.events([
        const UsageReported(ModelTokenUsage(inputTokens: 100)),
        const TextDelta('done'),
        const UsageReported(ModelTokenUsage(inputTokens: 100, outputTokens: 5)),
        const ModelTurnCompleted(stopReason: 'stop'),
        const UsageReported(
          ModelTokenUsage(inputTokens: 100, outputTokens: 12, totalTokens: 112),
        ),
      ]);
      await h.run();
      expect((await h.db.task).progress.tokenUsage!.inputTokens, 100);
      expect((await h.db.task).progress.tokenUsage!.outputTokens, 12);
      await h.db.reopen();
      await h.advanceToDue();
      h.models.candidate();
      final candidate = h.models.turns.removeLast();
      h.models.turns.add(() async* {
        yield const UsageReported(
          ModelTokenUsage(inputTokens: 200, outputTokens: 30),
        );
        yield* candidate();
      });
      await h.run();
      final usage = (await h.db.task).progress.tokenUsage!;
      expect(usage.inputTokens, 300);
      expect(usage.outputTokens, 42);
      expect(usage.effectiveTotalTokens, 342);
      expect((await h.db.task).progress.modelTurns, 2);
    },
  );

  test('failed model usage is retained before a successful retry', () async {
    await h.open(limits: TaskSegmentLimits(maxModelTurns: 1));
    h.models.events([
      const UsageReported(ModelTokenUsage(inputTokens: 80, outputTokens: 3)),
      ModelTurnFailed.fromProvider(
        ProviderFailure.fromHttp(
          statusCode: 503,
          endpointKind: ProviderEndpointKind.unknown,
        ),
      ),
    ]);
    expect(await h.run(), isA<TaskBackoff>());
    await h.db.reopen();
    await h.advanceToDue();
    h.models.events([
      const UsageReported(ModelTokenUsage(inputTokens: 90, outputTokens: 8)),
      const TextDelta('done'),
      const ModelTurnCompleted(stopReason: 'stop'),
    ]);
    await h.run();
    expect((await h.db.task).progress.tokenUsage!.inputTokens, 170);
    expect((await h.db.task).progress.tokenUsage!.outputTokens, 11);
  });

  test('cancellation saves received usage and ignores late reports', () async {
    await h.open();
    final events = StreamController<ModelEvent>();
    addTearDown(events.close);
    final started = Completer<void>();
    h.models.turns.add(() {
      started.complete();
      return events.stream;
    });
    final run = h.run();
    await started.future;
    events.add(
      const UsageReported(ModelTokenUsage(inputTokens: 60, outputTokens: 2)),
    );
    final task = await h.db.task;
    committed(
      await h.db.repository.requestCancellation(
        taskId: task.taskId,
        expectedRevision: task.revision,
        source: TaskCancellationSource.user,
        requestedAt: h.clock.now(),
      ),
    );
    expect(await run, isA<TaskNeedsSafeFinalization>());
    events.add(
      const UsageReported(ModelTokenUsage(inputTokens: 600, outputTokens: 200)),
    );
    await Future<void>.delayed(Duration.zero);
    expect((await h.db.task).progress.tokenUsage!.inputTokens, 60);
    expect((await h.db.task).progress.tokenUsage!.outputTokens, 2);
    expect((await h.db.task).progress.modelTurns, 1);
  });
}
