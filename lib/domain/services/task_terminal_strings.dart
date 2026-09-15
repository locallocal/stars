part of 'task_terminal_narration_policy.dart';

/// Domain fallbacks use the accepted language, without a UI locale dependency.
final class TaskTerminalStrings {
  TaskTerminalStrings(String language)
    : locale = language.toLowerCase().replaceAll('_', '-');
  final String locale;
  bool get zh => locale.startsWith('zh');
  bool get traditional =>
      zh &&
      (locale.contains('hant') ||
          locale.endsWith('-tw') ||
          locale.endsWith('-hk'));
  List<String> get _words =>
      _terminalWords[traditional ? 'zh-hant' : locale.split('-').first] ??
      _terminalWords['en']!;
  String get failed => _words[0];
  String get cancelled => _words[1];
  String get noResults => _words[2];
  String get noArtifacts => _words[3];
  String get artifacts => _words[4];
  String get noEffects => _words[5];
  String get irreversible => _words[6];
  String get reconciled => _words[7];
  String get unknown => _words[8];
  String get retry => _words[9];
  String get review => _words[10];
  String get genericReason => _words[11];

  String reason(String code) {
    if (traditional) {
      return switch (code) {
        TaskReasonCode.cancelled => '已按取消請求停止後續執行並核對執行狀態。',
        TaskReasonCode.noProgress => '多次嘗試後仍未取得新的可用進展。',
        TaskReasonCode.permissionDenied => '所需操作未獲批准。',
        TaskReasonCode.verificationFailed => '無法驗證完成任務所需的全部關鍵聲明。',
        TaskReasonCode.invalidPlan => '目前的執行方案無法繼續。',
        TaskReasonCode.missingCredentials => '目前的認證設定無法使用。',
        TaskReasonCode.providerUnavailable => '服務目前無法使用。',
        _ => genericReason,
      };
    }
    if (!zh && !locale.startsWith('en') && code == TaskReasonCode.cancelled) {
      return reconciled;
    }
    if (!zh && !locale.startsWith('en')) return genericReason;
    return switch (code) {
      TaskReasonCode.cancelled =>
        zh
            ? '已按取消请求停止后续执行并核对执行状态。'
            : 'Further execution stopped and execution status was checked as requested.',
      TaskReasonCode.noProgress =>
        zh
            ? '多次尝试后仍未取得新的可用进展。'
            : 'Repeated attempts produced no further usable progress.',
      TaskReasonCode.permissionDenied =>
        zh ? '所需操作未获批准。' : 'A required action was not approved.',
      TaskReasonCode.verificationFailed =>
        zh
            ? '无法验证完成任务所需的全部关键声明。'
            : 'The evidence could not verify all claims needed to complete the task.',
      TaskReasonCode.invalidPlan =>
        zh ? '当前执行方案无法继续。' : 'The current execution plan could not continue.',
      TaskReasonCode.missingCredentials =>
        zh ? '当前认证配置不可用。' : 'Authentication is unavailable.',
      TaskReasonCode.providerUnavailable =>
        zh ? '服务当前不可用。' : 'The service is unavailable.',
      _ => genericReason,
    };
  }
}

const _terminalWords = <String, List<String>>{
  'zh-hant': [
    '這項任務未能完成。',
    '這項任務已取消。',
    '目前沒有可驗證的部分結果。',
    '未確認有保留的產物。',
    '已保留的結果參照：',
    '沒有記錄到寫入操作影響。',
    '已執行的寫入操作仍然生效，未作復原。重試前請核對這些影響。',
    '已核對執行狀態；不表示發生了復原。',
    '部分執行影響尚未確定。',
    '你可以調整請求後發起新任務。',
    '請先核對已記錄的結果和影響，再決定下一步。',
    '執行無法安全繼續。',
  ],
  'en': [
    'The task could not be completed.',
    'The task has been cancelled.',
    'No verified partial result is available.',
    'No retained artifact has been confirmed.',
    'Retained result references:',
    'No write effects were recorded.',
    'Completed writes remain in effect and were not rolled back. Review their effects before retrying.',
    'Execution status was reconciled; no rollback is claimed.',
    'Some effects remain uncertain.',
    'You can revise the request and start a new task.',
    'Review the recorded results and effects before deciding what to do next.',
    'Execution could not safely continue.',
  ],
  'zh': [
    '这项任务未能完成。',
    '这项任务已取消。',
    '目前没有可验证的部分结果。',
    '未确认有保留的产物。',
    '已保留的结果引用：',
    '没有记录到写操作影响。',
    '已执行的写操作仍然生效，未作回滚。重试前请核对这些影响。',
    '已核对执行状态；不表示发生了回滚。',
    '部分执行影响尚未确定。',
    '你可以调整请求后发起新任务。',
    '请先核对已记录的结果和影响，再决定下一步。',
    '执行无法安全继续。',
  ],
  'de': [
    'Die Aufgabe konnte nicht abgeschlossen werden.',
    'Die Aufgabe wurde abgebrochen.',
    'Kein verifiziertes Teilergebnis verfügbar.',
    'Kein gespeichertes Artefakt bestätigt.',
    'Gespeicherte Ergebnisreferenzen:',
    'Keine Schreibauswirkungen aufgezeichnet.',
    'Ausgeführte Schreibvorgänge bleiben wirksam und wurden nicht rückgängig gemacht. Vor einem neuen Versuch prüfen.',
    'Der Ausführungsstatus wurde abgeglichen; eine Rücknahme wird nicht behauptet.',
    'Einige Auswirkungen sind noch unklar.',
    'Sie können die Anfrage anpassen und eine neue Aufgabe starten.',
    'Prüfen Sie die Ergebnisse und Auswirkungen vor dem nächsten Schritt.',
    'Die Ausführung konnte nicht sicher fortgesetzt werden.',
  ],
  'es': [
    'No se pudo completar la tarea.',
    'La tarea se ha cancelado.',
    'No hay resultados parciales verificados.',
    'No se ha confirmado ningún archivo conservado.',
    'Referencias de resultados conservados:',
    'No se registraron efectos de escritura.',
    'Las escrituras realizadas siguen vigentes y no se revirtieron. Revise sus efectos antes de reintentar.',
    'Se comprobó el estado de ejecución; no se afirma una reversión.',
    'Algunos efectos siguen sin confirmarse.',
    'Puede modificar la solicitud e iniciar una tarea nueva.',
    'Revise los resultados y efectos antes de decidir el siguiente paso.',
    'No se pudo continuar la ejecución de forma segura.',
  ],
  'fr': [
    'La tâche n’a pas pu être terminée.',
    'La tâche a été annulée.',
    'Aucun résultat partiel vérifié n’est disponible.',
    'Aucun artefact conservé n’a été confirmé.',
    'Références des résultats conservés :',
    'Aucun effet d’écriture enregistré.',
    'Les écritures effectuées restent actives et n’ont pas été annulées. Vérifiez leurs effets avant de réessayer.',
    'L’état d’exécution a été vérifié ; aucun retour arrière n’est affirmé.',
    'Certains effets restent incertains.',
    'Vous pouvez modifier la demande et lancer une nouvelle tâche.',
    'Vérifiez les résultats et les effets avant de choisir la suite.',
    'L’exécution ne pouvait pas continuer en toute sécurité.',
  ],
  'hi': [
    'कार्य पूरा नहीं हो सका।',
    'कार्य रद्द कर दिया गया है।',
    'कोई सत्यापित आंशिक परिणाम उपलब्ध नहीं है।',
    'किसी सुरक्षित रखी गई सामग्री की पुष्टि नहीं हुई है।',
    'सुरक्षित परिणाम संदर्भ:',
    'लेखन का कोई प्रभाव दर्ज नहीं हुआ।',
    'पूरे हुए लेखन के प्रभाव बने हुए हैं; उन्हें वापस नहीं किया गया। पुनः प्रयास से पहले जाँचें।',
    'निष्पादन स्थिति जाँची गई; वापस किए जाने का दावा नहीं है।',
    'कुछ प्रभाव अभी अनिश्चित हैं।',
    'आप अनुरोध बदलकर नया कार्य शुरू कर सकते हैं।',
    'अगला कदम तय करने से पहले परिणाम और प्रभाव जाँचें।',
    'निष्पादन सुरक्षित रूप से जारी नहीं रह सका।',
  ],
  'it': [
    'Non è stato possibile completare l’attività.',
    'L’attività è stata annullata.',
    'Nessun risultato parziale verificato disponibile.',
    'Nessun artefatto conservato confermato.',
    'Riferimenti ai risultati conservati:',
    'Nessun effetto di scrittura registrato.',
    'Le scritture eseguite restano valide e non sono state annullate. Verificarne gli effetti prima di riprovare.',
    'Lo stato di esecuzione è stato verificato; non si dichiara alcun ripristino.',
    'Alcuni effetti sono ancora incerti.',
    'Puoi modificare la richiesta e avviare una nuova attività.',
    'Controlla risultati ed effetti prima di decidere il passo successivo.',
    'Non era possibile continuare l’esecuzione in sicurezza.',
  ],
  'ja': [
    'タスクを完了できませんでした。',
    'タスクをキャンセルしました。',
    '検証済みの部分結果はありません。',
    '保持された成果物は確認されていません。',
    '保持された結果の参照：',
    '書き込みによる影響は記録されていません。',
    '実行済みの書き込みは有効なままで、取り消されていません。再試行前に影響を確認してください。',
    '実行状態を照合しました。ロールバックを意味しません。',
    '一部の影響は未確認です。',
    '依頼を調整して新しいタスクを開始できます。',
    '次の操作を決める前に結果と影響を確認してください。',
    '安全に実行を続けられませんでした。',
  ],
  'ko': [
    '작업을 완료하지 못했습니다.',
    '작업이 취소되었습니다.',
    '검증된 부분 결과가 없습니다.',
    '보존된 산출물이 확인되지 않았습니다.',
    '보존된 결과 참조:',
    '기록된 쓰기 영향이 없습니다.',
    '완료된 쓰기는 유지되며 되돌려지지 않았습니다. 재시도 전에 영향을 확인하세요.',
    '실행 상태를 확인했으며 롤백을 의미하지 않습니다.',
    '일부 영향은 아직 불확실합니다.',
    '요청을 수정하여 새 작업을 시작할 수 있습니다.',
    '다음 단계를 결정하기 전에 결과와 영향을 확인하세요.',
    '안전하게 실행을 계속할 수 없었습니다.',
  ],
  'pt': [
    'Não foi possível concluir a tarefa.',
    'A tarefa foi cancelada.',
    'Não há resultados parciais verificados.',
    'Nenhum artefacto retido foi confirmado.',
    'Referências dos resultados retidos:',
    'Não foram registados efeitos de escrita.',
    'As escritas concluídas continuam em vigor e não foram revertidas. Verifique os efeitos antes de tentar novamente.',
    'O estado de execução foi verificado; não se afirma uma reversão.',
    'Alguns efeitos continuam incertos.',
    'Pode ajustar o pedido e iniciar uma nova tarefa.',
    'Verifique os resultados e efeitos antes de decidir o próximo passo.',
    'A execução não pôde continuar com segurança.',
  ],
  'ru': [
    'Задачу не удалось завершить.',
    'Задача отменена.',
    'Проверенных частичных результатов нет.',
    'Сохранённые артефакты не подтверждены.',
    'Ссылки на сохранённые результаты:',
    'Последствия записи не зафиксированы.',
    'Выполненные записи остаются в силе и не были отменены. Перед повтором проверьте последствия.',
    'Состояние выполнения сверено; откат не заявляется.',
    'Некоторые последствия пока неясны.',
    'Можно изменить запрос и начать новую задачу.',
    'Проверьте результаты и последствия перед следующим действием.',
    'Безопасное продолжение выполнения невозможно.',
  ],
};
