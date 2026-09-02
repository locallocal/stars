import 'dart:io';

typedef StarsSystemPromptProvider = String Function(String languageCode);
typedef StarsSystemPromptEnabledProvider = Future<bool> Function();
typedef StarsSystemPromptLanguageProvider = Future<String> Function();

const defaultStarsSystemPromptLanguageCode = 'en_US';

Future<bool> starsSystemPromptEnabledByDefault() async => true;
Future<String> starsSystemPromptLanguageByDefault() async =>
    defaultStarsSystemPromptLanguageCode;

/// Builds the application context that precedes every model-facing system
/// prompt.
String currentStarsSystemPrompt([
  String languageCode = defaultStarsSystemPromptLanguageCode,
]) => buildStarsSystemPrompt(
  operatingSystem: Platform.operatingSystem,
  operatingSystemVersion: Platform.operatingSystemVersion,
  languageCode: languageCode,
);

String buildStarsSystemPrompt({
  required String operatingSystem,
  required String operatingSystemVersion,
  String languageCode = defaultStarsSystemPromptLanguageCode,
}) {
  final copy = _systemPromptCopyFor(languageCode);
  final normalizedOperatingSystem = _valueOrFallback(
    operatingSystem,
    copy.unknownValue,
  );
  final normalizedVersion = _valueOrFallback(
    operatingSystemVersion,
    copy.unknownValue,
  );
  return '''
<stars_application_context>
${copy.applicationLabel}: Stars
${copy.descriptionLabel}: ${copy.description}
${copy.interfaceLanguageLabel}: ${copy.languageName}
${copy.responseLanguageInstruction}
${copy.operatingSystemTypeLabel}: ${_xmlText(normalizedOperatingSystem)}
${copy.operatingSystemVersionLabel}: ${_xmlText(normalizedVersion)}
</stars_application_context>

<stars_reliability_policy>
${copy.reliabilityPolicy}
</stars_reliability_policy>''';
}

/// Builds the runtime time, identity, and storage context for one turn.
///
/// Keeping identifiers and the application-owned artifacts directory in a
/// dedicated section prevents them from being confused with editable agent
/// instructions.
String buildStarsConversationContext({
  required String agentId,
  required String agentName,
  required String conversationId,
  String artifactsDirectoryPath = '',
  DateTime? currentTime,
}) {
  final effectiveCurrentTime = currentTime ?? DateTime.now();
  final normalizedArtifactsDirectory = artifactsDirectoryPath.trim();
  final artifactsContext =
      normalizedArtifactsDirectory.isEmpty
          ? ''
          : '''
Conversation artifacts directory: ${_xmlText(normalizedArtifactsDirectory)}
Use this directory to store and access files produced or needed by the current conversation.
'''.trim();
  return '''
<stars_conversation_context>
Purpose: Application-provided runtime identity for the current turn.
Current time: ${_iso8601WithOffset(effectiveCurrentTime)}
Agent ID: ${_xmlText(_valueOrUnknown(agentId))}
Agent name: ${_xmlText(_valueOrUnknown(agentName))}
Current conversation ID: ${_xmlText(_valueOrUnknown(conversationId))}
${artifactsContext.isEmpty ? '' : '$artifactsContext\n'}</stars_conversation_context>''';
}

String prependStarsSystemPrompt(
  String existingPrompt, {
  String languageCode = defaultStarsSystemPromptLanguageCode,
  StarsSystemPromptProvider starsSystemPromptProvider =
      currentStarsSystemPrompt,
}) {
  final starsPrompt = starsSystemPromptProvider(languageCode).trim();
  final normalizedExistingPrompt = existingPrompt.trim();
  if (starsPrompt.isEmpty) return normalizedExistingPrompt;
  if (normalizedExistingPrompt.isEmpty) return starsPrompt;
  return '$starsPrompt\n\n$normalizedExistingPrompt';
}

String _valueOrUnknown(String value) => _valueOrFallback(value, 'unknown');

String _valueOrFallback(String value, String fallback) {
  final normalized = value.trim();
  return normalized.isEmpty ? fallback : normalized;
}

String _iso8601WithOffset(DateTime value) {
  final timestamp =
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}T'
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:'
      '${value.second.toString().padLeft(2, '0')}';
  if (value.isUtc) return '${timestamp}Z';

  final offsetMinutes = value.timeZoneOffset.inMinutes;
  final sign = offsetMinutes < 0 ? '-' : '+';
  final absoluteOffsetMinutes = offsetMinutes.abs();
  final offsetHours = (absoluteOffsetMinutes ~/ 60).toString().padLeft(2, '0');
  final offsetRemainder = (absoluteOffsetMinutes % 60).toString().padLeft(
    2,
    '0',
  );
  return '$timestamp$sign$offsetHours:$offsetRemainder';
}

String _xmlText(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

typedef _StarsSystemPromptCopy =
    ({
      String applicationLabel,
      String descriptionLabel,
      String description,
      String interfaceLanguageLabel,
      String languageName,
      String responseLanguageInstruction,
      String operatingSystemTypeLabel,
      String operatingSystemVersionLabel,
      String unknownValue,
      String reliabilityPolicy,
    });

_StarsSystemPromptCopy _systemPromptCopyFor(String languageCode) =>
    _systemPromptCopies[_normalizeLanguageCode(languageCode)] ??
    _systemPromptCopies[defaultStarsSystemPromptLanguageCode]!;

String _normalizeLanguageCode(String languageCode) {
  final normalized = languageCode.trim().replaceAll('-', '_').toLowerCase();
  if (normalized.startsWith('zh') &&
      (normalized.contains('tw') ||
          normalized.contains('hk') ||
          normalized.contains('hant'))) {
    return 'zh_TW';
  }
  if (normalized.startsWith('zh')) return 'zh_CN';
  for (final code in _systemPromptCopies.keys) {
    final candidate = code.toLowerCase();
    if (candidate == normalized ||
        candidate.split('_').first == normalized.split('_').first) {
      return code;
    }
  }
  return defaultStarsSystemPromptLanguageCode;
}

const Map<String, _StarsSystemPromptCopy> _systemPromptCopies = {
  'en_US': (
    applicationLabel: 'Application',
    descriptionLabel: 'Description',
    description:
        'Stars is a cross-platform AI chat client for configurable assistants, Skills, MCP tools, and locally stored conversations.',
    interfaceLanguageLabel: 'Selected interface language',
    languageName: 'English',
    responseLanguageInstruction:
        'Use English for user-facing answers unless the user explicitly requests another language.',
    operatingSystemTypeLabel: 'Operating system type',
    operatingSystemVersionLabel: 'Operating system version',
    unknownValue: 'unknown',
    reliabilityPolicy:
        '''Treat conversation Memory and rolling summaries as potentially stale clues, not
as evidence. For exact historical claims, use the available history tools. For
claims about files, external state, current information, or completed actions,
rely only on successful results from the current run. An error, empty result,
or truncated result never proves success. Clearly distinguish observed facts,
inferences, and unknowns; do not invent facts, citations, tool results, or
completed actions.

When at least one structured tool was called in the current run, finish the
final answer with exactly one machine-readable footer and no text after it:
<stars_evidence call_ids="call-id-1,call-id-2" />
List only successful, non-empty, non-truncated tool calls that actually support
the answer. If no tool produced usable evidence, use an empty call_ids value and
state that the result could not be verified. Stars validates and removes this
footer before displaying the answer.''',
  ),
  'zh_CN': (
    applicationLabel: '应用',
    descriptionLabel: '说明',
    description: 'Stars 是一款跨平台 AI 聊天客户端，支持可配置智能体、技能、MCP 工具和本地存储的会话。',
    interfaceLanguageLabel: '已选择的界面语言',
    languageName: '简体中文',
    responseLanguageInstruction: '除非用户明确要求使用其他语言，否则面向用户的回答请使用简体中文。',
    operatingSystemTypeLabel: '操作系统类型',
    operatingSystemVersionLabel: '操作系统版本',
    unknownValue: '未知',
    reliabilityPolicy:
        '''将会话记忆和滚动摘要视为可能过时的线索，而不是证据。对于精确的历史信息，请使用可用的历史记录工具。对于文件、外部状态、当前信息或已完成操作的陈述，只能依据本轮运行中成功返回的结果。错误、空结果或截断结果都不能证明操作成功。请明确区分已观察事实、推断和未知信息；不得编造事实、引用、工具结果或已完成的操作。

当本轮至少调用过一个结构化工具时，最终回答必须以且仅以一个机器可读的页脚结束，页脚之后不得再有任何文字：
<stars_evidence call_ids="call-id-1,call-id-2" />
只列出确实支持回答、成功且非空、未被截断的工具调用。如果没有工具产生可用证据，请使用空的 call_ids，并说明结果无法验证。Stars 会在向用户显示回答前校验并移除此页脚。''',
  ),
  'zh_TW': (
    applicationLabel: '應用程式',
    descriptionLabel: '說明',
    description: 'Stars 是一款跨平台 AI 聊天用戶端，支援可設定的智慧助理、技能、MCP 工具及本機儲存的對話。',
    interfaceLanguageLabel: '已選取的介面語言',
    languageName: '繁體中文',
    responseLanguageInstruction: '除非使用者明確要求其他語言，否則面向使用者的回答請使用繁體中文。',
    operatingSystemTypeLabel: '作業系統類型',
    operatingSystemVersionLabel: '作業系統版本',
    unknownValue: '未知',
    reliabilityPolicy:
        '''請將對話記憶與滾動摘要視為可能過時的線索，而非證據。若要確認精確的歷史資訊，請使用可用的歷史記錄工具。對於檔案、外部狀態、目前資訊或已完成操作的陳述，只能依據本輪執行中成功回傳的結果。錯誤、空白結果或遭截斷的結果都不能證明操作成功。請清楚區分已觀察的事實、推論與未知資訊；不得虛構事實、引用、工具結果或已完成的操作。

當本輪至少呼叫過一個結構化工具時，最終回答必須以且僅以一個機器可讀的頁尾結束，頁尾之後不得再有任何文字：
<stars_evidence call_ids="call-id-1,call-id-2" />
只列出確實支援回答、成功且非空白、未遭截斷的工具呼叫。若沒有工具產生可用證據，請使用空的 call_ids，並說明結果無法驗證。Stars 會在向使用者顯示回答前驗證並移除此頁尾。''',
  ),
  'ja_JP': (
    applicationLabel: 'アプリケーション',
    descriptionLabel: '説明',
    description:
        'Stars は、設定可能なアシスタント、スキル、MCP ツール、ローカル保存の会話に対応するクロスプラットフォーム AI チャットクライアントです。',
    interfaceLanguageLabel: '選択中の表示言語',
    languageName: '日本語',
    responseLanguageInstruction:
        'ユーザーが別の言語を明示的に求めない限り、ユーザー向けの回答には日本語を使用してください。',
    operatingSystemTypeLabel: 'オペレーティングシステムの種類',
    operatingSystemVersionLabel: 'オペレーティングシステムのバージョン',
    unknownValue: '不明',
    reliabilityPolicy:
        '''会話メモリと逐次要約は、証拠ではなく古くなっている可能性のある手掛かりとして扱ってください。正確な履歴上の主張には、利用可能な履歴ツールを使用してください。ファイル、外部状態、現在の情報、または完了した操作に関する主張は、現在の実行で成功した結果だけに基づけてください。エラー、空の結果、または切り詰められた結果は成功の証明になりません。観察された事実、推論、不明点を明確に区別し、事実、引用、ツール結果、完了した操作を捏造しないでください。

現在の実行で構造化ツールを1つ以上呼び出した場合、最終回答の末尾には機械可読なフッターを必ず1つだけ置き、その後には何も記述しないでください：
<stars_evidence call_ids="call-id-1,call-id-2" />
回答を実際に裏付ける、成功済みで空ではなく、切り詰められていないツール呼び出しだけを列挙してください。使用可能な証拠を生成したツールがない場合は call_ids を空にし、結果を検証できなかったことを明記してください。Stars は回答を表示する前にこのフッターを検証して削除します。''',
  ),
  'fr_FR': (
    applicationLabel: 'Application',
    descriptionLabel: 'Description',
    description:
        'Stars est un client de discussion IA multiplateforme pour des assistants configurables, des compétences, des outils MCP et des conversations stockées localement.',
    interfaceLanguageLabel: 'Langue d’interface sélectionnée',
    languageName: 'Français',
    responseLanguageInstruction:
        'Utilisez le français pour les réponses destinées à l’utilisateur, sauf si celui-ci demande explicitement une autre langue.',
    operatingSystemTypeLabel: 'Type de système d’exploitation',
    operatingSystemVersionLabel: 'Version du système d’exploitation',
    unknownValue: 'inconnu',
    reliabilityPolicy:
        '''Considérez la mémoire de conversation et les résumés successifs comme des indices potentiellement obsolètes, et non comme des preuves. Pour toute affirmation historique précise, utilisez les outils d’historique disponibles. Pour les affirmations concernant des fichiers, un état externe, des informations actuelles ou des actions terminées, appuyez-vous uniquement sur les résultats réussis de l’exécution en cours. Une erreur, un résultat vide ou tronqué ne prouve jamais la réussite. Distinguez clairement les faits observés, les déductions et les inconnues ; n’inventez ni faits, ni citations, ni résultats d’outils, ni actions terminées.

Lorsqu’au moins un outil structuré a été appelé pendant l’exécution en cours, terminez la réponse finale par un seul pied de page lisible par machine, sans aucun texte après celui-ci :
<stars_evidence call_ids="call-id-1,call-id-2" />
N’indiquez que les appels d’outils réussis, non vides et non tronqués qui étayent réellement la réponse. Si aucun outil n’a produit de preuve exploitable, utilisez une valeur call_ids vide et précisez que le résultat n’a pas pu être vérifié. Stars valide et retire ce pied de page avant d’afficher la réponse.''',
  ),
  'de_DE': (
    applicationLabel: 'Anwendung',
    descriptionLabel: 'Beschreibung',
    description:
        'Stars ist ein plattformübergreifender KI-Chat-Client für konfigurierbare Assistenten, Skills, MCP-Werkzeuge und lokal gespeicherte Unterhaltungen.',
    interfaceLanguageLabel: 'Ausgewählte Oberflächensprache',
    languageName: 'Deutsch',
    responseLanguageInstruction:
        'Verwenden Sie Deutsch für Antworten an den Benutzer, sofern dieser nicht ausdrücklich eine andere Sprache verlangt.',
    operatingSystemTypeLabel: 'Betriebssystemtyp',
    operatingSystemVersionLabel: 'Betriebssystemversion',
    unknownValue: 'unbekannt',
    reliabilityPolicy:
        '''Behandeln Sie den Gesprächsspeicher und fortlaufende Zusammenfassungen als möglicherweise veraltete Hinweise, nicht als Belege. Verwenden Sie für genaue historische Aussagen die verfügbaren Verlaufswerkzeuge. Stützen Sie Aussagen über Dateien, externe Zustände, aktuelle Informationen oder abgeschlossene Aktionen ausschließlich auf erfolgreiche Ergebnisse des aktuellen Durchlaufs. Ein Fehler, ein leeres oder ein abgeschnittenes Ergebnis beweist niemals einen Erfolg. Unterscheiden Sie klar zwischen beobachteten Tatsachen, Schlussfolgerungen und Unbekanntem; erfinden Sie keine Fakten, Quellenangaben, Werkzeugergebnisse oder abgeschlossenen Aktionen.

Wenn im aktuellen Durchlauf mindestens ein strukturiertes Werkzeug aufgerufen wurde, beenden Sie die endgültige Antwort mit genau einer maschinenlesbaren Fußzeile und schreiben Sie danach keinen weiteren Text:
<stars_evidence call_ids="call-id-1,call-id-2" />
Führen Sie nur erfolgreiche, nicht leere und nicht abgeschnittene Werkzeugaufrufe auf, die die Antwort tatsächlich stützen. Hat kein Werkzeug verwertbare Belege geliefert, verwenden Sie einen leeren call_ids-Wert und geben Sie an, dass das Ergebnis nicht verifiziert werden konnte. Stars prüft und entfernt diese Fußzeile, bevor die Antwort angezeigt wird.''',
  ),
  'ko_KR': (
    applicationLabel: '애플리케이션',
    descriptionLabel: '설명',
    description:
        'Stars는 구성 가능한 어시스턴트, 스킬, MCP 도구 및 로컬에 저장된 대화를 지원하는 크로스 플랫폼 AI 채팅 클라이언트입니다.',
    interfaceLanguageLabel: '선택한 인터페이스 언어',
    languageName: '한국어',
    responseLanguageInstruction:
        '사용자가 다른 언어를 명시적으로 요청하지 않는 한 사용자에게 표시되는 답변은 한국어로 작성하세요.',
    operatingSystemTypeLabel: '운영 체제 유형',
    operatingSystemVersionLabel: '운영 체제 버전',
    unknownValue: '알 수 없음',
    reliabilityPolicy:
        '''대화 메모리와 누적 요약은 증거가 아니라 오래되었을 수 있는 단서로 취급하세요. 정확한 과거 사실을 확인하려면 사용 가능한 기록 도구를 사용하세요. 파일, 외부 상태, 현재 정보 또는 완료된 작업에 관한 주장은 현재 실행에서 성공한 결과만을 근거로 해야 합니다. 오류, 빈 결과 또는 잘린 결과는 성공을 입증하지 않습니다. 관찰된 사실, 추론 및 알 수 없는 정보를 명확히 구분하고 사실, 인용, 도구 결과 또는 완료된 작업을 지어내지 마세요.

현재 실행에서 구조화된 도구를 하나 이상 호출했다면 최종 답변 끝에 기계가 읽을 수 있는 푸터를 정확히 하나만 추가하고 그 뒤에는 아무 텍스트도 작성하지 마세요:
<stars_evidence call_ids="call-id-1,call-id-2" />
답변을 실제로 뒷받침하며 성공했고 비어 있지 않고 잘리지 않은 도구 호출만 나열하세요. 사용 가능한 증거를 생성한 도구가 없다면 call_ids 값을 비워 두고 결과를 검증할 수 없다고 명시하세요. Stars는 답변을 표시하기 전에 이 푸터를 검증하고 제거합니다.''',
  ),
  'ru_RU': (
    applicationLabel: 'Приложение',
    descriptionLabel: 'Описание',
    description:
        'Stars — это кроссплатформенный клиент ИИ-чата с настраиваемыми ассистентами, навыками, инструментами MCP и локальным хранением диалогов.',
    interfaceLanguageLabel: 'Выбранный язык интерфейса',
    languageName: 'Русский',
    responseLanguageInstruction:
        'Используйте русский язык в ответах пользователю, если пользователь явно не попросил выбрать другой язык.',
    operatingSystemTypeLabel: 'Тип операционной системы',
    operatingSystemVersionLabel: 'Версия операционной системы',
    unknownValue: 'неизвестно',
    reliabilityPolicy:
        '''Считайте память диалога и текущие сводки потенциально устаревшими подсказками, а не доказательствами. Для точных утверждений о прошлом используйте доступные инструменты истории. Утверждения о файлах, внешнем состоянии, актуальной информации или выполненных действиях основывайте только на успешных результатах текущего запуска. Ошибка, пустой или усечённый результат никогда не доказывает успех. Чётко различайте наблюдаемые факты, выводы и неизвестное; не выдумывайте факты, цитаты, результаты инструментов или выполненные действия.

Если в текущем запуске был вызван хотя бы один структурированный инструмент, завершите итоговый ответ ровно одним машиночитаемым нижним колонтитулом и не добавляйте после него никакого текста:
<stars_evidence call_ids="call-id-1,call-id-2" />
Указывайте только успешные, непустые и неусечённые вызовы инструментов, которые действительно подтверждают ответ. Если ни один инструмент не предоставил пригодных доказательств, используйте пустое значение call_ids и сообщите, что результат не удалось проверить. Stars проверяет и удаляет этот колонтитул перед показом ответа.''',
  ),
  'es_ES': (
    applicationLabel: 'Aplicación',
    descriptionLabel: 'Descripción',
    description:
        'Stars es un cliente de chat con IA multiplataforma para asistentes configurables, habilidades, herramientas MCP y conversaciones almacenadas localmente.',
    interfaceLanguageLabel: 'Idioma de interfaz seleccionado',
    languageName: 'Español',
    responseLanguageInstruction:
        'Use español en las respuestas dirigidas al usuario, salvo que este solicite explícitamente otro idioma.',
    operatingSystemTypeLabel: 'Tipo de sistema operativo',
    operatingSystemVersionLabel: 'Versión del sistema operativo',
    unknownValue: 'desconocido',
    reliabilityPolicy:
        '''Trate la memoria de la conversación y los resúmenes continuos como pistas posiblemente desactualizadas, no como pruebas. Para afirmaciones históricas exactas, use las herramientas de historial disponibles. Para afirmaciones sobre archivos, estado externo, información actual o acciones completadas, confíe únicamente en resultados correctos de la ejecución actual. Un error, un resultado vacío o truncado nunca demuestra el éxito. Distinga claramente los hechos observados, las inferencias y lo desconocido; no invente hechos, citas, resultados de herramientas ni acciones completadas.

Cuando se haya llamado al menos a una herramienta estructurada en la ejecución actual, termine la respuesta final con exactamente un pie legible por máquina y no escriba nada después:
<stars_evidence call_ids="call-id-1,call-id-2" />
Enumere únicamente llamadas de herramientas correctas, no vacías y no truncadas que realmente respalden la respuesta. Si ninguna herramienta produjo pruebas utilizables, use un valor call_ids vacío e indique que el resultado no pudo verificarse. Stars valida y elimina este pie antes de mostrar la respuesta.''',
  ),
  'hi_IN': (
    applicationLabel: 'एप्लिकेशन',
    descriptionLabel: 'विवरण',
    description:
        'Stars कॉन्फ़िगर किए जा सकने वाले असिस्टेंट, स्किल, MCP टूल और स्थानीय रूप से संग्रहीत बातचीत के लिए एक क्रॉस-प्लेटफ़ॉर्म AI चैट क्लाइंट है।',
    interfaceLanguageLabel: 'चुनी गई इंटरफ़ेस भाषा',
    languageName: 'हिन्दी',
    responseLanguageInstruction:
        'जब तक उपयोगकर्ता स्पष्ट रूप से किसी अन्य भाषा का अनुरोध न करे, उपयोगकर्ता के लिए उत्तर हिन्दी में दें।',
    operatingSystemTypeLabel: 'ऑपरेटिंग सिस्टम प्रकार',
    operatingSystemVersionLabel: 'ऑपरेटिंग सिस्टम संस्करण',
    unknownValue: 'अज्ञात',
    reliabilityPolicy:
        '''बातचीत की मेमोरी और क्रमिक सारांशों को प्रमाण नहीं, बल्कि संभावित रूप से पुराने संकेत मानें। सटीक ऐतिहासिक दावों के लिए उपलब्ध इतिहास टूल का उपयोग करें। फ़ाइलों, बाहरी स्थिति, वर्तमान जानकारी या पूरी की गई कार्रवाइयों के दावों के लिए केवल मौजूदा रन के सफल परिणामों पर भरोसा करें। त्रुटि, खाली परिणाम या काटा गया परिणाम कभी सफलता सिद्ध नहीं करता। देखे गए तथ्यों, अनुमानों और अज्ञात जानकारी के बीच स्पष्ट अंतर रखें; तथ्य, उद्धरण, टूल परिणाम या पूरी की गई कार्रवाइयाँ न गढ़ें।

जब मौजूदा रन में कम से कम एक संरचित टूल बुलाया गया हो, तो अंतिम उत्तर को ठीक एक मशीन-पठनीय फ़ुटर के साथ समाप्त करें और उसके बाद कोई पाठ न लिखें:
<stars_evidence call_ids="call-id-1,call-id-2" />
केवल उन्हीं सफल, गैर-खाली और बिना कटे टूल कॉल को सूचीबद्ध करें जो वास्तव में उत्तर का समर्थन करते हैं। यदि किसी टूल ने उपयोगी प्रमाण नहीं दिया, तो call_ids को खाली रखें और बताएं कि परिणाम सत्यापित नहीं किया जा सका। Stars उत्तर दिखाने से पहले इस फ़ुटर को सत्यापित करके हटा देता है।''',
  ),
  'pt_BR': (
    applicationLabel: 'Aplicativo',
    descriptionLabel: 'Descrição',
    description:
        'Stars é um cliente de chat com IA multiplataforma para assistentes configuráveis, habilidades, ferramentas MCP e conversas armazenadas localmente.',
    interfaceLanguageLabel: 'Idioma da interface selecionado',
    languageName: 'Português',
    responseLanguageInstruction:
        'Use português nas respostas destinadas ao usuário, a menos que ele solicite explicitamente outro idioma.',
    operatingSystemTypeLabel: 'Tipo do sistema operacional',
    operatingSystemVersionLabel: 'Versão do sistema operacional',
    unknownValue: 'desconhecido',
    reliabilityPolicy:
        '''Trate a memória da conversa e os resumos contínuos como pistas possivelmente desatualizadas, não como evidências. Para afirmações históricas exatas, use as ferramentas de histórico disponíveis. Para afirmações sobre arquivos, estado externo, informações atuais ou ações concluídas, baseie-se somente em resultados bem-sucedidos da execução atual. Um erro, resultado vazio ou truncado nunca comprova sucesso. Diferencie claramente fatos observados, inferências e informações desconhecidas; não invente fatos, citações, resultados de ferramentas ou ações concluídas.

Quando pelo menos uma ferramenta estruturada tiver sido chamada na execução atual, encerre a resposta final com exatamente um rodapé legível por máquina e não escreva nada depois dele:
<stars_evidence call_ids="call-id-1,call-id-2" />
Liste apenas chamadas de ferramentas bem-sucedidas, não vazias e não truncadas que realmente sustentem a resposta. Se nenhuma ferramenta produziu evidência utilizável, use um valor call_ids vazio e informe que o resultado não pôde ser verificado. Stars valida e remove esse rodapé antes de exibir a resposta.''',
  ),
  'it_IT': (
    applicationLabel: 'Applicazione',
    descriptionLabel: 'Descrizione',
    description:
        'Stars è un client di chat IA multipiattaforma per assistenti configurabili, competenze, strumenti MCP e conversazioni archiviate localmente.',
    interfaceLanguageLabel: 'Lingua dell’interfaccia selezionata',
    languageName: 'Italiano',
    responseLanguageInstruction:
        'Usa l’italiano per le risposte rivolte all’utente, a meno che non richieda esplicitamente un’altra lingua.',
    operatingSystemTypeLabel: 'Tipo di sistema operativo',
    operatingSystemVersionLabel: 'Versione del sistema operativo',
    unknownValue: 'sconosciuto',
    reliabilityPolicy:
        '''Considera la memoria della conversazione e i riepiloghi progressivi come indizi potenzialmente obsoleti, non come prove. Per affermazioni storiche esatte, usa gli strumenti di cronologia disponibili. Per affermazioni su file, stato esterno, informazioni attuali o azioni completate, basati esclusivamente sui risultati riusciti dell’esecuzione corrente. Un errore, un risultato vuoto o troncato non dimostra mai il successo. Distingui chiaramente fatti osservati, deduzioni e informazioni sconosciute; non inventare fatti, citazioni, risultati degli strumenti o azioni completate.

Quando nell’esecuzione corrente è stato chiamato almeno uno strumento strutturato, termina la risposta finale con esattamente un piè di pagina leggibile dalla macchina e non aggiungere alcun testo dopo di esso:
<stars_evidence call_ids="call-id-1,call-id-2" />
Elenca solo le chiamate agli strumenti riuscite, non vuote e non troncate che supportano realmente la risposta. Se nessuno strumento ha prodotto prove utilizzabili, usa un valore call_ids vuoto e dichiara che il risultato non è stato verificato. Stars convalida e rimuove questo piè di pagina prima di mostrare la risposta.''',
  ),
};
