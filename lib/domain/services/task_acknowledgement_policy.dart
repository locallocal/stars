import 'package:stars/domain/services/task_safe_data.dart';

final class TaskAcknowledgement {
  const TaskAcknowledgement(this.text, {required this.usedFallback});
  final String text;
  final bool usedFallback;
}

/// Preserves the main model's contextual reply without imposing a sentence
/// template. Callers may show it only after durable task acceptance.
final class TaskAcknowledgementPolicy {
  const TaskAcknowledgementPolicy();

  TaskAcknowledgement evaluate({
    required String draft,
    required String title,
    required String language,
  }) {
    final candidate = draft.trim();
    final valid = _acceptsDraft(candidate);
    return TaskAcknowledgement(
      valid
          ? candidate
          : _fallback(language).replaceAll('{title}', _displayTitle(title)),
      usedFallback: !valid,
    );
  }

  bool _acceptsDraft(String draft) =>
      draft.isNotEmpty &&
      draft.length <= 280 &&
      !RegExp(r'[\x00-\x08\x0b-\x1f\x7f]').hasMatch(draft) &&
      !RegExp(r'^\x60{3}').hasMatch(draft) &&
      taskSafeText(draft, maximum: 280) == draft &&
      !_unsupportedExecution.hasMatch(draft) &&
      !_completionDeadline.hasMatch(draft);

  // Reject obvious premature execution claims, without requiring an approved
  // wording, literal task title, or language-specific acceptance grammar.
  // Context, notification intent and broader semantics belong to the model
  // instruction; these checks do not attempt to prove arbitrary prose true.
  static final _unsupportedExecution = RegExp(
    r'(?:已经|已經|已)(?:完成|执行|執行|调用|調用|启动|啟動|开始|開始|生成|写入|寫入|保存|验证|驗證)(?!的)'
    r'|正在(?:执行|執行|调用|調用|生成|写入|寫入|运行|運行)'
    r'|(?:验证|驗證|核验|核驗)通过(?!后|後)'
    r'|\balready\s+(?:complete(?:d)?|done|finished|started|running|executed|verified|saved|written)\b',
    caseSensitive: false,
  );
  static final _completionDeadline = RegExp(
    r'(?:\d+(?:\.\d+)?|[一二两兩三四五六七八九十百]+)\s*'
    r'(?:秒|分钟|分鐘|小时|小時)(?:内|內|后|後)[^，。！？\n]{0,16}'
    r'(?:完成|做好|发|發|回复|回覆|返回)'
    r'|\b(?:within|in)\s+(?:\d+(?:\.\d+)?|one|two|three|five|ten)\s*'
    r'(?:seconds?|minutes?|hours?)\b',
    caseSensitive: false,
  );

  String _displayTitle(String title) {
    final clean =
        taskSafeText(title, maximum: title.length, structured: true)
            .replaceAll(RegExp(r'[\x00-\x1f\x7f"“”「」«»<>]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    final runes = clean.runes.toList();
    return runes.length <= 80
        ? clean
        : String.fromCharCodes([...runes.take(79), 0x2026]);
  }

  /// Used only for missing, malformed or clearly unsuitable model output.
  /// Never included in the model prompt or used to match a valid draft.
  String _fallback(String language) {
    final locale = language.toLowerCase().replaceAll('_', '-');
    if (locale.startsWith('zh')) {
      return locale.contains('hant') ||
              locale.endsWith('-tw') ||
              locale.endsWith('-hk')
          ? '我會處理「{title}」，完成後告訴你。'
          : '我会处理“{title}”，完成后告诉你。';
    }
    return switch (locale.split('-').first) {
      'de' =>
        'Ich kümmere mich um „{title}“ und melde mich, sobald es fertig ist.',
      'es' => 'Me encargaré de «{title}» y te avisaré cuando esté listo.',
      'fr' =>
        'Je vais m’occuper de «{title}» et vous prévenir quand ce sera prêt.',
      'hi' => 'मैं “{title}” पर काम करूँगा और पूरा होने पर आपको बताऊँगा।',
      'it' => 'Mi occuperò di «{title}» e ti avviserò quando sarà pronto.',
      'ja' => '「{title}」に取り組みます。終わったらお知らせします。',
      'ko' => '“{title}”을 처리하고 완료되면 알려드리겠습니다.',
      'pt' => 'Vou cuidar de «{title}» e aviso quando estiver pronto.',
      'ru' => 'Займусь задачей «{title}» и сообщу, когда всё будет готово.',
      _ => 'I’ll handle “{title}” and let you know when it’s ready.',
    };
  }
}
