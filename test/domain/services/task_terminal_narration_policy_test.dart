import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_terminal_narration_policy.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_terminal.dart';

void main() {
  const policy = TaskTerminalNarrationPolicy();
  TaskTerminalSummary summary({bool cancelled = false}) => TaskTerminalSummary(
    status:
        cancelled
            ? ConversationTaskStatus.cancelled
            : ConversationTaskStatus.failed,
    reasonCode:
        cancelled ? TaskReasonCode.cancelled : TaskReasonCode.noProgress,
    safeReason: '多次尝试后仍未取得新的可用进展。',
    completedWorkSummary: 'report.count: 42',
    retainedArtifacts: ['evidence:evidence:read-1'],
    sideEffectStatus: TaskSideEffectStatus.irreversible,
    canRetry: false,
    suggestedNextActions: ['请核对影响后决定下一步。'],
    cancellationSource: cancelled ? TaskCancellationSource.user : null,
  );

  test('accepted narration preserves every fact and next action', () async {
    final value = summary();
    final narrator = NarrateConversationTaskTerminal();
    final result = await narrator(
      summary: value,
      language: 'zh-CN',
      polish: (request, _) async {
        expect(request.summary, same(value));
        return request.allowedNarrations.last;
      },
    );
    expect(result.usedFallback, isFalse);
    expect(result.text, contains('report.count: 42'));
    expect(result.text, contains('未作回滚'));
    expect(narrator.metrics.narrationAttempts, 1);
  });

  for (final draft in [
    '任务已全部完成，全部内容已保留。',
    '任务已取消，所有更改都已回滚。',
    '基本完成了，只有一点小问题，直接重试即可。',
    '报告保存在 /home/private/report.txt，api_key=secret-value',
    '任务失败。已保留此前从未确认的附件。',
  ]) {
    test('unsafe terminal narration is rejected: $draft', () async {
      var calls = 0;
      final narrator = NarrateConversationTaskTerminal();
      final value = summary(cancelled: draft.contains('取消'));
      final result = await narrator(
        summary: value,
        language: 'zh-CN',
        polish: (_, _) async {
          calls++;
          return draft;
        },
      );
      expect(calls, 1);
      expect(result.usedFallback, isTrue);
      expect(result.text, policy.alternatives(value, 'zh-CN').first);
      expect(narrator.metrics.narrationFallbacks, 1);
    });
  }

  test(
    'narration timeout cancels one attempt and falls back without repair',
    () async {
      final pending = Completer<String>();
      AgentCancellationToken? token;
      final narrator = NarrateConversationTaskTerminal(
        timeout: const Duration(milliseconds: 5),
      );
      final result = await narrator(
        summary: summary(),
        language: 'en',
        polish: (_, cancellation) {
          token = cancellation;
          return pending.future;
        },
      );
      expect(result.usedFallback, isTrue);
      expect(token!.isCancelled, isTrue);
      expect(narrator.metrics.narrationFailures, 1);
      pending.complete('Too late: all work completed.');
      expect(result.text, isNot(contains('Too late')));
    },
  );

  test(
    'fallbacks cover supported locales and do not expose raw reason codes',
    () {
      for (final locale in [
        'en',
        'zh-CN',
        'zh-TW',
        'de',
        'es',
        'fr',
        'hi',
        'it',
        'ja',
        'ko',
        'pt',
        'ru',
      ]) {
        final words = TaskTerminalStrings(locale);
        final value = TaskTerminalSummary(
          status: ConversationTaskStatus.failed,
          reasonCode: TaskReasonCode.noProgress,
          safeReason: words.reason(TaskReasonCode.noProgress),
          completedWorkSummary: '',
          sideEffectStatus: TaskSideEffectStatus.none,
          canRetry: true,
          suggestedNextActions: [words.retry],
        );
        final text = policy.evaluate(summary: value, language: locale).text;
        expect(text, startsWith(words.failed));
        expect(text, contains(words.noResults));
        expect(text, contains(words.retry));
        expect(text, isNot(contains(TaskReasonCode.noProgress)));
      }
    },
  );
}
