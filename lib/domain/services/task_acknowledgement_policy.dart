final class TaskAcknowledgement {
  const TaskAcknowledgement(this.text, {required this.usedFallback});
  final String text;
  final bool usedFallback;
}

/// Uses a small acceptance grammar, rather than guessing whether arbitrary model
/// prose contains promises. Quoted titles supply relevance; verbs only describe
/// recording the task. Callers may show this text only after durable acceptance.
final class TaskAcknowledgementPolicy {
  const TaskAcknowledgementPolicy();

  TaskAcknowledgement evaluate({
    required String draft,
    required String title,
    required String language,
    String objective = '',
  }) {
    final expected = template(
      language,
    ).replaceAll('{title}', displayTitle(title));
    final candidate = draft.trim();
    final valid =
        candidate == expected ||
        _acceptsNaturalDraft(
          candidate,
          displayTitle(title),
          objective,
          language,
        );
    return TaskAcknowledgement(
      valid ? candidate : expected,
      usedFallback: !valid,
    );
  }

  bool _acceptsNaturalDraft(
    String draft,
    String title,
    String objective,
    String language,
  ) {
    if (draft.isEmpty || draft.length > 280 || draft.contains('\n')) {
      return false;
    }
    final locale = language.toLowerCase();
    // The entire sentence must fit an acceptance-only grammar. A blacklist of
    // completion words alone would miss paraphrased execution/time promises.
    if (locale.startsWith('zh') &&
        !locale.contains('hant') &&
        !locale.endsWith('tw') &&
        !locale.endsWith('hk')) {
      final subjects = <String>{'“$title”', '「$title」'};
      final topic = '$title $objective';
      for (final entry
          in {
            '调研报告': '这份调研报告',
            '报告': '这份报告',
            '文件': '这些文件',
            '分析': '这个分析任务',
          }.entries) {
        if (topic.contains(entry.key)) subjects.add(entry.value);
      }
      final subject = subjects.map(RegExp.escape).join('|');
      return RegExp(
        '^(?:$subject)(?:我)?需要(?:花点|一些|一点)时间，'
        '(?:已经记录|已记录|我已经记下了)[。！]'
        '(?:完成后|完成之后)(?:我会|会)(?:在这里)?(?:发送|回复|提供)(?:完整的结果|完整结果)[。！]\$',
      ).hasMatch(draft);
    }
    if (locale.startsWith('en')) {
      final subjects = <String>{'“$title”', '"$title"'};
      for (final noun in ['research report', 'report', 'files', 'analysis']) {
        if ('$title $objective'.toLowerCase().contains(noun)) {
          subjects.addAll(['This $noun', 'The $noun']);
        }
      }
      final subject = subjects.map(RegExp.escape).join('|');
      return RegExp(
        '^(?:$subject) (?:needs|will take|may take) (?:some|a little) time; '
        '(?:I have|I\'ve|I’ve) (?:recorded|queued) it\\. '
        '(?:I will|I\'ll|I’ll) (?:send|share|post) the (?:full|complete) results? '
        '(?:when it is ready|when ready|when finished|once complete)\\.\$',
        caseSensitive: false,
      ).hasMatch(draft);
    }
    return false;
  }

  String displayTitle(String title) {
    final clean =
        title
            .replaceAll(RegExp(r'[\x00-\x1f\x7f"“”「」«»<>]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    final runes = clean.runes.toList();
    return runes.length <= 80
        ? clean
        : '${String.fromCharCodes(runes.take(79))}…';
  }

  /// Also supplied to the main routing prompt. No acknowledgement model call.
  String template(String language) {
    final locale = language.toLowerCase().replaceAll('_', '-');
    if (locale.startsWith('zh')) {
      return locale.contains('hant') ||
              locale.endsWith('-tw') ||
              locale.endsWith('-hk')
          ? '「{title}」需要一些時間，已經記錄。完成後我會發送完整的結果。'
          : '“{title}”需要一些时间，已经记录。完成后我会发送完整的结果。';
    }
    return switch (locale.split('-').first) {
      'de' =>
        '„{title}“ braucht etwas Zeit und ist vorgemerkt. Nach Abschluss sende ich das vollständige Ergebnis.',
      'es' =>
        '«{title}» llevará algo de tiempo y ya está registrada. Enviaré el resultado completo al terminar.',
      'fr' =>
        '«{title}» prendra un peu de temps ; la tâche est enregistrée. Je vous enverrai le résultat complet une fois terminé.',
      'hi' =>
        '“{title}” में कुछ समय लगेगा; कार्य दर्ज कर लिया गया है। पूरा होने पर मैं संपूर्ण परिणाम भेजूँगा।',
      'it' =>
        '«{title}» richiederà un po’ di tempo ed è stata registrata. Invierò il risultato completo al termine.',
      'ja' => '「{title}」は少し時間がかかるため、タスクとして記録しました。完了後に結果全体をお送りします。',
      'ko' => '“{title}”은 시간이 조금 필요하여 작업으로 기록했습니다. 완료되면 전체 결과를 보내드리겠습니다.',
      'pt' =>
        '«{title}» vai demorar algum tempo e já está registada. Enviarei o resultado completo quando terminar.',
      'ru' =>
        '«{title}» потребует некоторого времени; задача записана. По завершении отправлю полный результат.',
      _ =>
        '“{title}” will take some time; I have recorded it. I will send the full result when ready.',
    };
  }
}
