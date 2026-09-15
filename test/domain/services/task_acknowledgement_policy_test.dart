import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/services/task_acknowledgement_policy.dart';

void main() {
  const policy = TaskAcknowledgementPolicy();
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
    '你好！',
    '晚餐需要一些时间，已经记录。完成后我会发送完整的结果。',
    '报告已经完成，验证通过。',
    '工具已经调用，报告正在生成。',
    '报告会在 30 秒内完成。',
    '“报告”需要一些时间，已经记录。完成后我会发送完整的结果。已经调用工具。',
    'The report is already complete.',
    '报告' * 500,
    '这份报告需要一些时间，已经记录。完成后我会发送完整的结果。\napi_key=secret',
  ]) {
    test('unsafe/unrelated draft falls back: ${draft.takeLabel()}', () {
      final result = policy.evaluate(
        draft: draft,
        title: '报告',
        language: 'zh-CN',
      );
      expect(result.usedFallback, isTrue);
      expect(result.text, '“报告”需要一些时间，已经记录。完成后我会发送完整的结果。');
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
}

extension on String {
  String takeLabel() => length < 32 ? this : substring(0, 32);
}
