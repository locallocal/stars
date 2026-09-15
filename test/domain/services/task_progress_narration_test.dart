import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_progress_narration_policy.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
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
  String draft({String? id, int? revision, String? text}) => jsonEncode({
    'taskId': id ?? summary.taskId,
    'summaryRevision': revision ?? summary.summaryRevision,
    'content': text ?? policy.alternatives(summary, 'en').first,
  });
  for (final language in [
    'en',
    'zh-CN',
    'zh-TW',
    'de-DE',
    'es-ES',
    'fr-FR',
    'hi-IN',
    'it-IT',
    'ja-JP',
    'ko-KR',
    'pt-BR',
    'ru-RU',
  ]) {
    test('localized facts and fallback remain valid in $language', () async {
      final w = TaskProgressStrings(language);
      final text = await NarrateConversationTaskProgress()(
        summary: summary,
        language: language,
      );
      expect(text, contains('${w.steps}: 3/5'));
      expect(text, contains(w.status(ConversationTaskStatus.waitingForUser)));
      expect(
        policy.validate(
          jsonEncode({
            'taskId': summary.taskId,
            'summaryRevision': summary.summaryRevision,
            'content': text,
          }),
          summary,
          language,
        ),
        text,
      );
      if (language != 'en') {
        expect(w.noTasks, isNot(TaskProgressStrings('en').noTasks));
        expect(w.choose, isNot(TaskProgressStrings('en').choose));
        expect(
          w.retryConfirmation,
          isNot(TaskProgressStrings('en').retryConfirmation),
        );
      }
    });
  }
  test('accepts exact safe narration bound to a task revision', () {
    final text = policy.validate(draft(), summary, 'en');
    expect(text, contains('3/5'));
    expect(text, isNot(contains('private-key')));
    expect(text, isNot(contains('password=secret')));
  });
  for (final entry
      in <String, String Function()>{
        'task identity': () => draft(id: 'other'),
        'revision': () => draft(revision: 9),
        'numbers':
            () => draft(
              text: policy
                  .alternatives(summary, 'en')
                  .first
                  .replaceAll('3/5', '5/5'),
            ),
        'tools':
            () => draft(
              text: policy
                  .alternatives(summary, 'en')
                  .first
                  .replaceAll('read_file', 'write_file'),
            ),
        'approval':
            () => draft(
              text: policy
                  .alternatives(summary, 'en')
                  .first
                  .replaceAll('Approval required', 'Approved'),
            ),
        'terminal claim':
            () => draft(
              text:
                  '${policy.alternatives(summary, 'en').first}\nCompleted successfully.',
            ),
        'completion percent':
            () => draft(
              text: '${policy.alternatives(summary, 'en').first}\n60% complete',
            ),
        'extra fields':
            () => jsonEncode({
              'taskId': summary.taskId,
              'summaryRevision': 8,
              'content': '',
              'secret': true,
            }),
      }.entries) {
    test(
      'rejects invented ${entry.key}',
      () => expect(policy.validate(entry.value(), summary, 'en'), isNull),
    );
  }
  test(
    'repairs once using the same safe facts without raw invalid prose',
    () async {
      final requests = <TaskProgressNarrationRequest>[];
      final useCase = NarrateConversationTaskProgress();
      final result = await useCase(
        summary: summary,
        language: 'en',
        polish: (request, _) async {
          requests.add(request);
          return requests.length == 1 ? 'raw invalid provider output' : draft();
        },
      );
      expect(result, policy.alternatives(summary, 'en').first);
      expect(requests, hasLength(2));
      expect(requests.last.repair, isTrue);
      expect(requests.first.summary, requests.last.summary);
      expect(jsonEncode(requests.last.summary), isNot(contains('private-key')));
      expect(useCase.metrics.fallbacks, 0);
    },
  );
  test('two invalid attempts fall back to localized text', () async {
    final useCase = NarrateConversationTaskProgress();
    final result = await useCase(
      summary: summary,
      language: 'zh-CN',
      polish: (_, _) async => 'All done',
    );
    expect(result, contains('步骤: 3/5'));
    expect(result, contains('等待用户'));
    expect(useCase.metrics.modelCalls, 2);
    expect(useCase.metrics.repairs, 1);
    expect(useCase.metrics.fallbackRatio, 1);
  });
  test('unavailable provider returns fallback without a repair call', () async {
    final useCase = NarrateConversationTaskProgress();
    final result = await useCase(
      summary: summary,
      language: 'en',
      polish: (_, _) async => throw StateError('provider secret'),
    );
    expect(result, isNot(contains('provider secret')));
    expect(useCase.metrics.modelCalls, 1);
    expect(useCase.metrics.repairs, 0);
  });
  test('timeout cancels stalled session and falls back', () async {
    final useCase = NarrateConversationTaskProgress(
      timeout: const Duration(milliseconds: 5),
    );
    AgentCancellationToken? token;
    final result = await useCase(
      summary: summary,
      language: 'en',
      polish: (_, value) {
        token = value;
        return Completer<String>().future;
      },
    );
    expect(token!.isCancelled, isTrue);
    expect(result, contains('3/5'));
    expect(useCase.metrics.fallbacks, 1);
  });
  test('missing provider makes no model call', () async {
    final useCase = NarrateConversationTaskProgress();
    await useCase(summary: summary, language: 'en');
    expect(useCase.metrics.modelCalls, 0);
    expect(useCase.metrics.fallbacks, 1);
  });
}
