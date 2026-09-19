import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_terminal_narration_policy.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_terminal.dart';

void main() {
  const policy = TaskTerminalNarrationPolicy();
  TaskTerminalSummary summary() => TaskTerminalSummary(
    status: ConversationTaskStatus.failed,
    reasonCode: TaskReasonCode.noProgress,
    safeReason: '多次尝试后仍未取得新的可用进展。',
    completedWorkSummary: '',
    sideEffectStatus: TaskSideEffectStatus.none,
    canRetry: true,
    suggestedNextActions: ['可以调整请求后重试。'],
  );

  for (final text in [
    '销售汇总没能生成：读取你指定的表格时，文件不存在。请确认文件位置。',
    '这次没有导出 PDF。网页服务返回了 403，当前账号无法读取该页面。',
  ]) {
    test('contextual wording is preserved without a template: $text', () async {
      final narrator = NarrateConversationTaskTerminal();
      const context = '{"objective":"整理销售汇总"}';
      final result = await narrator(
        summary: summary(),
        language: 'zh-CN',
        context: context,
        polish: (request, _) async {
          expect(request.context, context);
          expect(request.timeout, const Duration(seconds: 15));
          return GroundedAnswerCandidate(nonFactualText: text);
        },
      );
      expect(result.usedFallback, isFalse);
      expect(result.text, text);
      expect(narrator.metrics.narrationAttempts, 1);
    });
  }

  test(
    'failed evidence validation uses a short fallback, without repair',
    () async {
      var calls = 0;
      final narrator = NarrateConversationTaskTerminal();
      final result = await narrator(
        summary: summary(),
        language: 'zh-CN',
        polish: (_, _) async {
          calls++;
          return GroundedAnswerCandidate(
            claims: [
              AnswerClaim(
                claimId: 'invented',
                text: '附件已保存。',
                kind: ClaimKind.completedAction,
              ),
            ],
            nonFactualText: '任务未完成。',
          );
        },
        validate: (_) async => false,
      );
      expect(calls, 1);
      expect(result.usedFallback, isTrue);
      expect(result.text, isNot(contains('附件已保存')));
      expect(narrator.metrics.narrationFallbacks, 1);
    },
  );

  test('credentials cannot pass through generated prose', () {
    final result = policy.evaluate(
      summary: summary(),
      language: 'zh-CN',
      draft: GroundedAnswerCandidate(
        nonFactualText: '认证失败，api_key=private-key',
      ),
    );
    expect(result.usedFallback, isTrue);
    expect(result.text, isNot(contains('private-key')));
  });

  test(
    'timeout cancels one attempt and ignores late output and usage',
    () async {
      final pending = Completer<GroundedAnswerCandidate>();
      AgentCancellationToken? token;
      TaskTerminalNarrationRequest? request;
      var usageCalls = 0;
      final narrator = NarrateConversationTaskTerminal(
        timeout: const Duration(milliseconds: 5),
      );
      final result = await narrator(
        summary: summary(),
        language: 'en',
        polish: (input, cancellation) {
          request = input;
          token = cancellation;
          return pending.future;
        },
        onTokenUsage: (_) => usageCalls++,
      );
      expect(result.usedFallback, isTrue);
      expect(token!.isCancelled, isTrue);
      expect(narrator.metrics.narrationFailures, 1);
      pending.complete(GroundedAnswerCandidate(nonFactualText: 'Too late'));
      request!.onTokenUsage!(const ModelTokenUsage(inputTokens: 100));
      expect(usageCalls, 0);
      expect(result.text, isNot(contains('Too late')));
    },
  );

  test('fallbacks omit boilerplate lists and internal evidence identities', () {
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
      expect(text, contains(value.safeReason));
      expect(text, isNot(contains(words.noResults)));
      expect(text, isNot(contains(words.noArtifacts)));
      expect(text, isNot(contains(words.retry)));
      expect(text, isNot(contains(TaskReasonCode.noProgress)));
    }
  });
}
