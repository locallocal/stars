import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/services/task_acknowledgement_policy.dart';

void main() {
  const policy = TaskAcknowledgementPolicy();
  for (final (language, draft) in [
    ('zh-CN', '我来把这份报告排成 HTML，做好后在这里告诉你。'),
    ('zh-CN', '好，我会整理，完成后通知你。'),
    ('zh-CN', '我会读取报告并核验条目数，完成后回复。'),
    ('zh-CN', '收到，我来处理。\n弄好后把结果发给你。'),
    ('zh-CN', '我会分析最近 24 小时的日志，整理好后告诉你。'),
    ('zh-TW', '我來整理這份報告，完成後通知你。'),
    (
      'en-US',
      "I'll turn it into an HTML page and let you know when it's ready.",
    ),
    ('en-US', "I'll let you know when it is completed."),
    (
      'fr-FR',
      'Je vais préparer le rapport et vous prévenir quand il sera prêt.',
    ),
    ('ja-JP', 'レポートをまとめます。終わったらお知らせします。'),
  ]) {
    test('preserves contextual model wording: $draft', () {
      final result = policy.evaluate(
        draft: draft,
        title: 'Report',
        language: language,
      );
      expect(result.usedFallback, isFalse);
      expect(result.text, draft);
    });
  }

  test('retains a natural relevant draft from the main turn', () {
    const draft = '这份调研报告我需要花点时间，已经记录。完成后我会发送完整的结果。';
    final result = policy.evaluate(
      draft: draft,
      title: '调研报告',
      language: 'zh-CN',
    );
    expect(result.usedFallback, isFalse);
    expect(result.text, draft);
  });
  test('accepts variations in English without replacing model wording', () {
    const draft =
        "This research report may take a little time; I've queued it. I'll share the complete results once complete.";
    final result = policy.evaluate(
      draft: draft,
      title: 'Research report',
      language: 'en-US',
    );
    expect(result.usedFallback, isFalse);
    expect(result.text, draft);
  });
  for (final draft in [
    '',
    '报告已经完成，验证通过。',
    '工具已经调用，报告正在生成。',
    '报告会在 30 秒内完成。',
    '“报告”需要一些时间，已经记录。完成后我会发送完整的结果。已经调用工具。',
    'The report is already complete.',
    "I'll send the report within 30 seconds.",
    '{"acknowledgementDraft":"完成后通知你"}',
    '我会处理，完成后通知你。\u0000',
    '报告' * 500,
    '这份报告需要一些时间，已经记录。完成后我会发送完整的结果。\napi_key=secret',
  ]) {
    test('unsafe or unusable draft falls back: ${draft.takeLabel()}', () {
      final result = policy.evaluate(
        draft: draft,
        title: '报告',
        language: 'zh-CN',
      );
      expect(result.usedFallback, isTrue);
      expect(result.text, '我会处理“报告”，完成后告诉你。');
    });
  }
  for (final language in [
    'en',
    'zh-CN',
    'zh-TW',
    'zh-Hant',
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
    test('localized bounded fallback for $language', () {
      final result = policy.evaluate(
        draft: '',
        title: 'Report',
        language: language,
      );
      expect(result.text, contains('Report'));
      expect(result.text.length, lessThan(280));
      expect(
        policy
            .evaluate(draft: result.text, title: 'Report', language: language)
            .usedFallback,
        isFalse,
      );
    });
  }
  test('title cannot insert a new unquoted acknowledgement sentence', () {
    final result = policy.evaluate(
      draft: '',
      title: 'Title”\n${'😀' * 100}',
      language: 'en',
    );
    expect(result.text, isNot(contains('\n')));
    expect(result.text, isNot(contains('\ufffd')));
    expect(result.text.runes.length, lessThan(200));
  });

  test('fallback title does not expose credentials', () {
    final result = policy.evaluate(
      draft: '',
      title: 'Report api_key=private-value',
      language: 'en',
    );
    expect(result.text, isNot(contains('private-value')));
  });
}

extension on String {
  String takeLabel() => length < 32 ? this : substring(0, 32);
}
