part of 'task_progress_strings.dart';

const _taskProgressKeys =
    "Tasks|Status|Phase|Steps|Current step|Latest tool|Approval required|Updated|Waiting for|Recoveries|Verification|View status|Cancel task|Approve|Deny|Recheck and resume|Review and retry|Create new task|Refresh tasks|Retry sending|Close|queued|running|waitingForUser|paused|cancelRequested|succeeded|failed|cancelled|planning|executing|observing|verifying|synthesizing|committing|approval|credentials|configuration|external outcome reconciliation|notStarted|verified|partial|waitingApproval|Task input|strict|standard";
const _taskProgressRows = <String, String>{
  "de":
      "Aufgaben|Status|Phase|Schritte|Aktueller Schritt|Letztes Werkzeug|Genehmigung erforderlich|Aktualisiert|"
      "Wartet auf|Wiederherstellungen|Überprüfung|Status anzeigen|Aufgabe abbrechen|Genehmigen|Ablehnen|Prüfen und fortsetzen|"
      "Prüfen und wiederholen|Neue Aufgabe erstellen|Aufgaben aktualisieren|Erneut senden|Schließen|In Warteschlange|Wird ausgeführt|Wartet auf Benutzer|"
      "Pausiert|Wird abgebrochen|Erfolgreich|Fehlgeschlagen|Abgebrochen|Planung|Ausführung|Beobachtung|"
      "Überprüfung|Ergebnisaufbereitung|Ergebnisspeicherung|Genehmigung|Zugangsdaten|Konfiguration|Abgleich externer Ergebnisse|Nicht begonnen|"
      "Überprüft|Teilweise überprüft|Wartet auf Genehmigung|Aufgabeneingabe|Streng|Standard",
  "es":
      "Tareas|Estado|Fase|Pasos|Paso actual|Última herramienta|Aprobación necesaria|Actualizado|"
      "Esperando|Recuperaciones|Verificación|Ver estado|Cancelar tarea|Aprobar|Rechazar|Revisar y continuar|"
      "Revisar y reintentar|Crear nueva tarea|Actualizar tareas|Reintentar envío|Cerrar|En cola|En ejecución|Esperando al usuario|"
      "En pausa|Cancelando|Completada|Fallida|Cancelada|Planificación|Ejecución|Observación|"
      "Verificación|Preparación del resultado|Guardando resultado|aprobación|credenciales|configuración|conciliación del resultado externo|Sin iniciar|"
      "Verificado|Parcialmente verificado|Esperando aprobación|Entrada de la tarea|Estricta|Estándar",
  "fr":
      "Tâches|État|Phase|Étapes|Étape actuelle|Dernier outil|Approbation requise|Mis à jour|"
      "En attente de|Récupérations|Vérification|Voir l’état|Annuler la tâche|Approuver|Refuser|Vérifier et reprendre|"
      "Vérifier et réessayer|Créer une tâche|Actualiser les tâches|Renvoyer|Fermer|En file d’attente|En cours|En attente de l’utilisateur|"
      "En pause|Annulation en cours|Terminée|Échouée|Annulée|Planification|Exécution|Observation|"
      "Vérification|Préparation du résultat|Enregistrement du résultat|approbation|identifiants|configuration|rapprochement des résultats externes|Non commencée|"
      "Vérifiée|Partiellement vérifiée|En attente d’approbation|Entrée de la tâche|Stricte|Standard",
  "it":
      "Attività|Stato|Fase|Passaggi|Passaggio attuale|Ultimo strumento|Approvazione richiesta|Aggiornato|"
      "In attesa di|Ripristini|Verifica|Visualizza stato|Annulla attività|Approva|Rifiuta|Verifica e riprendi|"
      "Verifica e riprova|Crea nuova attività|Aggiorna attività|Riprova invio|Chiudi|In coda|In esecuzione|In attesa dell’utente|"
      "In pausa|Annullamento in corso|Completata|Non riuscita|Annullata|Pianificazione|Esecuzione|Osservazione|"
      "Verifica|Preparazione del risultato|Salvataggio del risultato|approvazione|credenziali|configurazione|riconciliazione del risultato esterno|Non iniziata|"
      "Verificata|Parzialmente verificata|In attesa di approvazione|Input dell’attività|Rigorosa|Standard",
  "pt":
      "Tarefas|Estado|Fase|Etapas|Etapa atual|Última ferramenta|Aprovação necessária|Atualizado|"
      "Aguardando|Recuperações|Verificação|Ver estado|Cancelar tarefa|Aprovar|Recusar|Verificar e continuar|"
      "Revisar e tentar novamente|Criar nova tarefa|Atualizar tarefas|Reenviar|Fechar|Na fila|Em execução|Aguardando usuário|"
      "Pausada|Cancelando|Concluída|Falhou|Cancelada|Planejamento|Execução|Observação|"
      "Verificação|Preparação do resultado|Salvando resultado|aprovação|credenciais|configuração|conciliação do resultado externo|Não iniciada|"
      "Verificada|Parcialmente verificada|Aguardando aprovação|Entrada da tarefa|Rigorosa|Padrão",
  "ru":
      "Задачи|Состояние|Этап|Шаги|Текущий шаг|Последний инструмент|Требуется одобрение|Обновлено|"
      "Ожидание|Восстановления|Проверка|Показать состояние|Отменить задачу|Одобрить|Отклонить|Проверить и продолжить|"
      "Проверить и повторить|Создать новую задачу|Обновить задачи|Повторить отправку|Закрыть|В очереди|Выполняется|Ожидание пользователя|"
      "Приостановлена|Отменяется|Завершена|Ошибка|Отменена|Планирование|Выполнение|Наблюдение|"
      "Проверка|Подготовка результата|Сохранение результата|одобрения|учётных данных|настройки|сверки внешних результатов|Не начата|"
      "Проверено|Частично проверено|Ожидание одобрения|Ввод задачи|Строгая|Стандартная",
  "hi":
      "कार्य|स्थिति|चरण|कदम|वर्तमान कदम|अंतिम उपकरण|अनुमोदन आवश्यक|अद्यतन|"
      "प्रतीक्षा|पुनर्प्राप्तियाँ|सत्यापन|स्थिति देखें|कार्य रद्द करें|अनुमोदित करें|अस्वीकार करें|जाँचें और जारी रखें|"
      "जाँचें और पुनः प्रयास करें|नया कार्य बनाएँ|कार्य ताज़ा करें|फिर से भेजें|बंद करें|कतार में|चल रहा है|उपयोगकर्ता की प्रतीक्षा|"
      "रुका हुआ|रद्द हो रहा है|पूर्ण|विफल|रद्द|योजना|निष्पादन|अवलोकन|"
      "सत्यापन|परिणाम की तैयारी|परिणाम सहेजना|अनुमोदन|प्रमाण-पत्र|कॉन्फ़िगरेशन|बाहरी परिणाम का मिलान|शुरू नहीं हुआ|"
      "सत्यापित|आंशिक सत्यापन|अनुमोदन की प्रतीक्षा|कार्य इनपुट|सख्त|मानक",
  "ja":
      "タスク|状態|段階|ステップ|現在のステップ|最新のツール|承認が必要|更新日時|"
      "待機理由|復旧回数|検証|状態を表示|タスクをキャンセル|承認|拒否|再確認して続行|"
      "確認して再試行|新しいタスクを作成|タスクを更新|送信を再試行|閉じる|待機中|実行中|ユーザーの入力待ち|"
      "一時停止|キャンセル中|完了|失敗|キャンセル済み|計画|実行|観察|"
      "検証中|結果の整理|結果の保存|承認|認証情報|設定|外部処理の結果確認|未開始|"
      "検証済み|一部検証済み|承認待ち|タスクの入力|厳格|標準",
  "ko":
      "작업|상태|단계|진행 단계|현재 단계|최근 도구|승인 필요|업데이트|"
      "대기 사유|복구 횟수|검증|상태 보기|작업 취소|승인|거부|다시 확인 후 계속|"
      "확인 후 재시도|새 작업 만들기|작업 새로고침|전송 재시도|닫기|대기 중|실행 중|사용자 대기|"
      "일시 중지|취소 중|완료|실패|취소됨|계획|실행|관찰|"
      "검증 중|결과 정리|결과 저장|승인|인증 정보|설정|외부 결과 확인|시작 전|"
      "검증됨|부분 검증됨|승인 대기|작업 입력|엄격|표준",
  "zh-TW":
      "任務|狀態|階段|步驟|目前步驟|最近工具|待審批動作|更新時間|"
      "等待原因|恢復次數|驗證狀態|查看狀態|取消任務|批准|拒絕|重新檢查並繼續|"
      "檢查後重試|建立新任務|重新整理任務|重試傳送|關閉|已排隊|執行中|等待使用者|"
      "已暫停|正在取消|已完成|失敗|已取消|規劃|執行|觀察|"
      "驗證中|整理結果|提交結果|審批|憑據|設定輸入|外部操作對帳|未開始|"
      "驗證通過|部分驗證通過|等待審批|任務輸入|嚴格|標準",
};

final _taskProgressTranslations = {
  for (final row in _taskProgressRows.entries)
    row.key: Map<String, String>.fromIterables(
      _taskProgressKeys.split('|'),
      row.value.split('|'),
    ),
};
