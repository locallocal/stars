import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_progress_narration_policy.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_progress.dart';

void main() {
  const policy = TaskProgressNarrationPolicy();
  final time = DateTime.utc(2026, 9, 15);
  final summary = ConversationTaskProgressSummary(
    taskId: 'task:abcdef123',
    chatId: 'chat',
    title: 'Report',
    status: ConversationTaskStatus.waitingForUser,
    phase: ConversationTaskPhase.executing,
    planRevision: 1,
    summaryRevision: 8,
    updatedAt: time,
    waitingReason: TaskWaitingReason.approval,
    progress: TaskProgress(
      totalSteps: 5,
      completedSteps: 3,
      lastMeaningfulProgressAt: time,
      currentStepSummary: 'Read notes',
      recoveries: 2,
      pendingApprovalId: 'approval-1',
      pendingApprovalSummary: 'Save notes api_key=private-key',
      approvalRequestedAt: time,
      latestTool: TaskToolProgress(
        attemptId: 'a',
        name: 'read_file',
        status: ToolInvocationStatus.succeeded,
        safeSummary: 'Read notes password=secret',
      ),
    ),
  );
  Future<String> narrate({
    NarrateConversationTaskProgress? useCase,
    TaskProgressPolisher? polish,
    AgentCancellationToken? cancellation,
    String language = 'zh-CN',
  }) => (useCase ?? NarrateConversationTaskProgress())(
    chatId: 'chat',
    summaries: [summary],
    question: '做到哪一步了，需要我做什么？',
    language: language,
    polish: polish,
    cancellation: cancellation,
  );

  test(
    'accepts model wording instead of a fixed list of allowed answers',
    () async {
      for (final reply in [
        '笔记已经读完，目前完成了五步中的三步。保存笔记需要你先批准。',
        'The notes have been read. Saving them is waiting for your approval.',
        'メモの読み取りは終わりました。保存するには承認が必要です。',
        'Die Notizen wurden gelesen. Das Speichern wartet auf deine Freigabe.',
      ]) {
        expect(await narrate(polish: (_, _) async => reply), reply);
      }
    },
  );

  test('passes the question, language and redacted committed facts', () async {
    TaskProgressNarrationRequest? captured;
    await narrate(
      polish: (request, _) async {
        captured = request;
        return '笔记已经读完，保存操作还在等待你批准。';
      },
    );
    expect(captured!.question, '做到哪一步了，需要我做什么？');
    expect(captured!.language, 'zh-CN');
    expect(captured!.summaries.single['summaryRevision'], 8);
    expect(captured!.summaries.single['completedSteps'], 3);
    expect(captured!.summaries.single['status'], 'waitingForUser');
    final serialized = jsonEncode(captured!.summaries);
    expect(serialized, isNot(contains('private-key')));
    expect(serialized, isNot(contains('password=secret')));
    expect(() => captured!.summaries.clear(), throwsUnsupportedError);
    expect(() => captured!.summaries.single.clear(), throwsUnsupportedError);
    expect(captured!.timeout, const Duration(seconds: 15));
  });

  test('includes recorded failure details for a useful stopped-task reply', () {
    final failed = ConversationTaskProgressSummary(
      taskId: summary.taskId,
      chatId: summary.chatId,
      title: summary.title,
      status: ConversationTaskStatus.failed,
      phase: summary.phase,
      planRevision: 1,
      summaryRevision: 9,
      updatedAt: time,
      progress: summary.progress,
      terminalSummary: TaskTerminalSummary(
        status: ConversationTaskStatus.failed,
        reasonCode: 'disk_full',
        safeReason: 'The report could not be saved because the disk is full.',
        completedWorkSummary: 'Read and organized the notes.',
        sideEffectStatus: TaskSideEffectStatus.none,
        canRetry: true,
      ),
    );
    final facts = policy.facts(failed);
    expect(
      facts['terminal'],
      containsPair('completedWork', 'Read and organized the notes.'),
    );
    expect(facts['terminal'], containsPair('reason', contains('disk is full')));
  });

  for (final draft in [
    '',
    '   ',
    '{}',
    '[{"status":"running"}]',
    '```json\n{}\n```',
  ]) {
    test('rejects empty or serialized query output: $draft', () {
      expect(policy.validate(draft), isNull);
    });
  }
  test('rejects oversized output and redacts credentials in prose', () {
    expect(policy.validate('x' * 12001), isNull);
    expect(
      policy.validate('Read notes with api_key=private-key.'),
      isNot(contains('private-key')),
    );
  });
  test(
    'repairs malformed output once without feeding it back as context',
    () async {
      final requests = <TaskProgressNarrationRequest>[];
      final useCase = NarrateConversationTaskProgress();
      const reply = '笔记已经读完，保存操作还在等待你批准。';
      expect(
        await narrate(
          useCase: useCase,
          polish: (request, _) async {
            requests.add(request);
            return requests.length == 1 ? '{}' : reply;
          },
        ),
        reply,
      );
      expect(requests, hasLength(2));
      expect(requests.last.repair, isTrue);
      expect(requests.first.summaries, requests.last.summaries);
      expect(useCase.metrics.failures, 0);
    },
  );
  test('invalid replies fail without a hard-coded task summary', () async {
    final useCase = NarrateConversationTaskProgress();
    await expectLater(
      narrate(useCase: useCase, polish: (_, _) async => '{}'),
      throwsA(isA<TaskProgressNarrationException>()),
    );
    expect(useCase.metrics.modelCalls, 2);
    expect(useCase.metrics.repairs, 1);
    expect(useCase.metrics.failureRatio, 1);
  });
  test('provider failure is safe and does not request a repair', () async {
    final useCase = NarrateConversationTaskProgress();
    await expectLater(
      narrate(
        useCase: useCase,
        polish: (_, _) async => throw StateError('provider secret'),
      ),
      throwsA(isA<TaskProgressNarrationException>()),
    );
    expect(useCase.metrics.modelCalls, 1);
    expect(useCase.metrics.repairs, 0);
  });
  test(
    'timeout cancels the session without generating fallback prose',
    () async {
      final useCase = NarrateConversationTaskProgress(
        timeout: const Duration(milliseconds: 5),
      );
      AgentCancellationToken? token;
      await expectLater(
        narrate(
          useCase: useCase,
          polish: (_, value) {
            token = value;
            return Completer<String>().future;
          },
        ),
        throwsA(isA<TaskProgressNarrationException>()),
      );
      expect(token!.isCancelled, isTrue);
      expect(useCase.metrics.failures, 1);
    },
  );
  test(
    'foreground cancellation promptly cancels a stalled narration',
    () async {
      final cancellation = AgentCancellationToken();
      final started = Completer<void>();
      AgentCancellationToken? token;
      final result = narrate(
        cancellation: cancellation,
        polish: (_, value) {
          token = value;
          started.complete();
          return Completer<String>().future;
        },
      );
      final expectation = expectLater(
        result,
        throwsA(isA<AgentRunCancelledException>()),
      );
      await started.future;
      cancellation.cancel();
      await expectation;
      expect(token!.isCancelled, isTrue);
    },
  );
  test('missing provider fails without a model call or canned reply', () async {
    final useCase = NarrateConversationTaskProgress();
    await expectLater(
      narrate(useCase: useCase),
      throwsA(isA<TaskProgressNarrationException>()),
    );
    expect(useCase.metrics.modelCalls, 0);
    expect(useCase.metrics.failures, 1);
  });
}
