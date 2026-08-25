// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru_RU locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ru_RU';

  static String m0(name) => "Бот \"${name}\" был добавлен";

  static String m1(botName) => "\"${botName}\" был удален";

  static String m2(botName) =>
      "Здравствуйте! Я ${botName}, ИИ-ассистент. Вы можете задать мне любой вопрос, и я постараюсь помочь вам наилучшим образом.";

  static String m3(botName) => "${botName} печатает...";

  static String m4(botName) => "Бот ${botName} был обновлен";

  static String m5(botName) => "Чат с ${botName} удален";

  static String m6(error) => "Could not clear chat history: ${error}";

  static String m7(botName) =>
      "Вы уверены, что хотите очистить всю историю чата с \"${botName}\"? Это действие нельзя отменить.";

  static String m8(botName) =>
      "Удаление бота также удалит все связанные чаты. Вы уверены, что хотите удалить ${botName}?";

  static String m9(botName) =>
      "Удаление чата приведет к стиранию всей истории переписки. Вы уверены, что хотите удалить чат с ${botName}?";

  static String m10(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m11(name) =>
      "Удалить ${name}? Привязки к ботам также будут удалены.";

  static String m12(year) => "© ${year} Команда Stars";

  static String m13(error) => "Could not create the chat: ${error}";

  static String m14(error) => "Could not delete the chat: ${error}";

  static String m15(milliseconds) => "${milliseconds} мс";

  static String m16(seconds) => "${seconds} с";

  static String m17(name) =>
      "Разрешить ${name} зарегистрировать объявленные скрипты как инструменты. Каждый вызов потребует подтверждения.";

  static String m18(count) => "${count} files";

  static String m19(error) => "Generate image failed: ${error}";

  static String m20(error) => "Could not generate music: ${error}";

  static String m21(error) => "Could not generate speech: ${error}";

  static String m22(error) => "Could not generate video: ${error}";

  static String m23(count) => "${count} items";

  static String m24(language) => "Язык изменен на ${language}";

  static String m25(error) => "MCP connection failed: ${error}";

  static String m26(count) => "${count} configured (values hidden)";

  static String m27(minutes) => "${minutes} минут назад";

  static String m28(count) => "Успешно получено ${count} моделей";

  static String m29(count) => "${count} запусков команд";

  static String m30(duration) => "Длительность ${duration}";

  static String m31(count) => "${count} изменений файлов";

  static String m32(count) => "${count} вызовов инструментов";

  static String m33(error) => "Ошибка получения ответа: ${error}";

  static String m34(error) => "Could not save image: ${error}";

  static String m35(error) => "Could not share image: ${error}";

  static String m36(error) => "Не удалось импортировать навык: ${error}";

  static String m37(duration) => "Размышление завершено · ${duration}";

  static String m38(error) => "Ошибка воспроизведения видео: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Боты"),
    "about": MessageLookupByLibrary.simpleMessage("О приложении"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("О приложении Stars"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("Добавить бота"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("Добавить навык"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Настроить размер шрифта приложения",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Настроить размер шрифта",
    ),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Все установленные навыки добавлены.",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("Всегда включён"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Добавляет этот навык в каждый текстовый запрос.",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("Всегда включён"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("Адрес API:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API ключ"),
    "apiType": MessageLookupByLibrary.simpleMessage("Тип API:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "Простое, но мощное приложение для чата с ИИ, которое позволяет общаться с искусственным интеллектом в любое время и в любом месте.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Stars - ИИ чат-ассистент",
    ),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "Системный промпт",
    ),
    "applicationInjectedPromptDescription": MessageLookupByLibrary.simpleMessage(
      "Управляется Stars и добавляется к каждому запросу модели. Идентификаторы текущего агента и беседы подставляются во время выполнения и недоступны для редактирования.",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("Автоматически"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Поддерживаемые модели могут активировать этот навык по его описанию.",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "Этот провайдер поддерживает только ручные навыки.",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage(
      "Автоматическая память",
    ),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "Автоматические сводки могут быть неточными. Текущее сообщение всегда имеет приоритет.",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage(
      "Вернуться к ежедневному использованию",
    ),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Основная информация",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Аватар бота"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "Включите инструменты MCP для этого агента. По умолчанию вызовы требуют подтверждения.",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("Имя бота"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "Поиск фильтрует список по имени бота.",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("Навыки"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "Выберите повторно используемые инструкции, доступные этому боту.",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("Отмена"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("Изменить аватар"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("Сохранено"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage(
      "Статус выполнения чата",
    ),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "История чата очищена",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Чаты"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("Очистить"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage(
      "Очистить автоматическую память",
    ),
    "clearChat": MessageLookupByLibrary.simpleMessage("Очистить чат"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Очистить историю чата",
    ),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage(
      "Снять закрепление навыков",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "Выберите день для просмотра почасового использования",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Нажмите + в правом верхнем углу, чтобы добавить бота",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Нажмите «Новый чат», чтобы создать беседу",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage(
      "Выполнение команд",
    ),
    "compactNow": MessageLookupByLibrary.simpleMessage("Сжать сейчас"),
    "compactingContext": MessageLookupByLibrary.simpleMessage(
      "Упорядочивание контекста…",
    ),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("Ошибка"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage(
      "Состояние сжатия",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Подтвердить"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage(
      "Подтвердить удаление",
    ),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Контактная информация (необязательно)",
    ),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage(
      "Контекст и память",
    ),
    "contextCompacted": MessageLookupByLibrary.simpleMessage("Контекст сжат"),
    "contextWindow": MessageLookupByLibrary.simpleMessage("Окно контекста"),
    "conversationSummary": MessageLookupByLibrary.simpleMessage(
      "Сводка разговора",
    ),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage(
      "Доля токенов по диалогам",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("Копировать ключ API"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m12,
    "createChatFailed": m13,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Время создания"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Пользовательский провайдер...",
    ),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage(
      "Ежедневное использование",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Тёмная тема"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "Эта база данных создана более новой версией Stars. Обновите приложение, прежде чем открывать её.",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "Проверка целостности базы данных завершилась ошибкой, восстановить её из резервной копии этой версии не удалось.",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage("Глубокое мышление"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Вы полезный ИИ-ассистент. Пожалуйста, отвечайте на русском языке.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Удалить"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Удалить бота"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Удалить чат"),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "О приложении и правовая информация",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "Внешний вид и язык",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Измените аватар и отображаемое имя.",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("Общие"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage(
      "Помощь и поддержка",
    ),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage(
      "Личная информация",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "Изменения применяются сразу и сохраняются локально.",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Управляйте профилем, внешним видом, языком и поддержкой приложения.",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Сведения"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Отключить без подтверждения для всех",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Отключить все инструменты",
    ),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Отключить скрипты",
    ),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("Редактировать"),
    "editBot": MessageLookupByLibrary.simpleMessage("Редактировать бота"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("Изменить память"),
    "editName": MessageLookupByLibrary.simpleMessage("Изменить имя"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Ошибка получения ответа: сервер вернул пустой ответ",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Включить без подтверждения для всех",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Включить все инструменты",
    ),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Включить скрипты",
    ),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "Включить изолированные скрипты?",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "Введите адрес API...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("Введите ключ API..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("Введите имя бота..."),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage(
      "Введите отображаемое имя",
    ),
    "enterNewName": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите новое имя",
    ),
    "enterProviderName": MessageLookupByLibrary.simpleMessage(
      "Введите имя провайдера...",
    ),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Введите системный промпт...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "Ошибка при загрузке содержимого, пожалуйста, повторите попытку позже.",
    ),
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage(
      "Оценка использования",
    ),
    "executionStatus": MessageLookupByLibrary.simpleMessage(
      "Статус выполнения",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите содержание отзыва",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, расскажите нам о ваших мыслях, проблемах или предложениях, чтобы помочь нам улучшить приложение",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Введите ваш отзыв здесь...",
    ),
    "feedbackInformation": MessageLookupByLibrary.simpleMessage(
      "Информация об обратной связи",
    ),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "Ошибка отправки, пожалуйста, попробуйте позже",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "Спасибо за ваш отзыв!",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage(
      "Получить список моделей",
    ),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "Сначала получите список моделей",
    ),
    "fileAttachment": MessageLookupByLibrary.simpleMessage("File attachment"),
    "fileCount": m18,
    "fileMissing": MessageLookupByLibrary.simpleMessage(
      "This file no longer exists.",
    ),
    "fileOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this file.",
    ),
    "filePreviewUnavailable": MessageLookupByLibrary.simpleMessage(
      "Preview is not available for this file type. Open it with a system app.",
    ),
    "fileResult": MessageLookupByLibrary.simpleMessage("File result"),
    "fileStatus": MessageLookupByLibrary.simpleMessage("Статус файлов"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("Музыка"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("Речь"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("Видео"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, заполните имя бота, адрес API и ключ API",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Системная"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("Размер шрифта"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "Размер шрифта обновлен",
    ),
    "forgetMemory": MessageLookupByLibrary.simpleMessage("Забыть"),
    "generateImageFailed": m19,
    "generateMusicFailed": m20,
    "generateSpeechFailed": m21,
    "generateVideoFailed": m22,
    "generatedImage": MessageLookupByLibrary.simpleMessage("Image generated"),
    "generating": MessageLookupByLibrary.simpleMessage("Generating…"),
    "generatingImage": MessageLookupByLibrary.simpleMessage(
      "Generating image, please wait...",
    ),
    "generationFailed": MessageLookupByLibrary.simpleMessage(
      "Ошибка генерации",
    ),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "Ошибка генерации · Частичный ответ сохранён",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage(
      "Помощь и обратная связь",
    ),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("Скрыть ключ API"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("Главная"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage(
      "Почасовое использование",
    ),
    "idle": MessageLookupByLibrary.simpleMessage("Ожидание"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage(
      "Импортировать папку навыка",
    ),
    "importSkillZip": MessageLookupByLibrary.simpleMessage(
      "Импортировать ZIP навыка",
    ),
    "importingSkill": MessageLookupByLibrary.simpleMessage("Импорт навыка…"),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("Входные токены"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage(
      "Установить обновление",
    ),
    "invalidSummary": MessageLookupByLibrary.simpleMessage(
      "Созданная сводка не прошла проверку",
    ),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("Только что"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage("Настройки языка"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Светлая тема"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("Управление памятью"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("Для сообщения"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "При необходимости выберите навык в поле сообщения.",
    ),
    "mcpAccessToken": MessageLookupByLibrary.simpleMessage(
      "OAuth / bearer access token",
    ),
    "mcpArguments": MessageLookupByLibrary.simpleMessage("Arguments"),
    "mcpArgumentsDescription": MessageLookupByLibrary.simpleMessage(
      "Enter one argument per line.",
    ),
    "mcpAuthentication": MessageLookupByLibrary.simpleMessage("Authentication"),
    "mcpAuthorizationRequired": MessageLookupByLibrary.simpleMessage(
      "Authorization required",
    ),
    "mcpCommand": MessageLookupByLibrary.simpleMessage("Command"),
    "mcpCommandDescription": MessageLookupByLibrary.simpleMessage(
      "Executable name or absolute path. The command runs directly without a shell.",
    ),
    "mcpCommunicationChannel": MessageLookupByLibrary.simpleMessage(
      "Communication channel",
    ),
    "mcpConnected": MessageLookupByLibrary.simpleMessage("Connected"),
    "mcpConnecting": MessageLookupByLibrary.simpleMessage("Connecting"),
    "mcpConnectionError": MessageLookupByLibrary.simpleMessage(
      "Connection error",
    ),
    "mcpConnectionFailed": m25,
    "mcpConnectionSettings": MessageLookupByLibrary.simpleMessage("Connection"),
    "mcpDisconnected": MessageLookupByLibrary.simpleMessage("Disconnected"),
    "mcpEndpoint": MessageLookupByLibrary.simpleMessage(
      "Streamable HTTP endpoint",
    ),
    "mcpEnvironment": MessageLookupByLibrary.simpleMessage(
      "Environment variables",
    ),
    "mcpEnvironmentDescription": MessageLookupByLibrary.simpleMessage(
      "Enter one KEY=VALUE per line. Values are stored in the operating system\'s secure credential store; leave blank while editing to keep existing values.",
    ),
    "mcpHiddenEnvironmentVariableCount": m26,
    "mcpHttpsRequired": MessageLookupByLibrary.simpleMessage(
      "Remote MCP endpoints must use HTTPS.",
    ),
    "mcpInvalidStdioEnvironment": MessageLookupByLibrary.simpleMessage(
      "Environment variables must use one KEY=VALUE entry per line.",
    ),
    "mcpLocalProcessSecurityDescription": MessageLookupByLibrary.simpleMessage(
      "stdio servers run commands on this computer. Only add servers and environment variables you trust.",
    ),
    "mcpLocalProcessSecurityTitle": MessageLookupByLibrary.simpleMessage(
      "Local process security",
    ),
    "mcpNoApprovalRequired": MessageLookupByLibrary.simpleMessage(
      "Без подтверждения",
    ),
    "mcpNoAuthentication": MessageLookupByLibrary.simpleMessage("None"),
    "mcpPrivateEndpointBlocked": MessageLookupByLibrary.simpleMessage(
      "Private, local, and link-local MCP endpoints are blocked.",
    ),
    "mcpProcessId": MessageLookupByLibrary.simpleMessage("Process ID (PID)"),
    "mcpProcessNotRunning": MessageLookupByLibrary.simpleMessage("Not running"),
    "mcpProcessRunning": MessageLookupByLibrary.simpleMessage("Running"),
    "mcpProcessStartedAt": MessageLookupByLibrary.simpleMessage("Started at"),
    "mcpProcessStatus": MessageLookupByLibrary.simpleMessage("Process status"),
    "mcpProgressiveDiscoveryDescription": MessageLookupByLibrary.simpleMessage(
      "Stars stores discovered Tool catalogs. Enable individual Tools when editing an agent; only that agent can expose them to the model.",
    ),
    "mcpRequestTimedOut": MessageLookupByLibrary.simpleMessage(
      "The MCP request timed out.",
    ),
    "mcpSecureEnvironmentVariables": MessageLookupByLibrary.simpleMessage(
      "Secure environment variables",
    ),
    "mcpServerDetails": MessageLookupByLibrary.simpleMessage("Server details"),
    "mcpServerInUseByBot": MessageLookupByLibrary.simpleMessage(
      "This MCP server is used by an agent. Remove it from the agent before deleting it.",
    ),
    "mcpServerName": MessageLookupByLibrary.simpleMessage("Server name"),
    "mcpServers": MessageLookupByLibrary.simpleMessage("Серверы MCP"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Подключайте серверы MCP и находите их каталоги инструментов. Настройте инструменты после создания агента.",
    ),
    "mcpStdioPipeChannel": MessageLookupByLibrary.simpleMessage(
      "stdin / stdout / stderr (operating system pipes)",
    ),
    "mcpStdioProcessAndChannel": MessageLookupByLibrary.simpleMessage(
      "Local process and communication",
    ),
    "mcpStdioStartFailed": MessageLookupByLibrary.simpleMessage(
      "The stdio MCP command could not be started.",
    ),
    "mcpTokenLeaveBlank": MessageLookupByLibrary.simpleMessage(
      "Leave blank to keep the existing secure credential.",
    ),
    "mcpTokenStoredSecurely": MessageLookupByLibrary.simpleMessage(
      "Stored in the operating system\'s secure credential store.",
    ),
    "mcpToolSchemaUnsupported": MessageLookupByLibrary.simpleMessage(
      "This Tool has an unsupported input schema and cannot be selected.",
    ),
    "mcpTools": MessageLookupByLibrary.simpleMessage("Tools"),
    "mcpTransport": MessageLookupByLibrary.simpleMessage("Transport"),
    "mcpTransportStdio": MessageLookupByLibrary.simpleMessage(
      "stdio (local process)",
    ),
    "mcpTransportStreamableHttp": MessageLookupByLibrary.simpleMessage(
      "Streamable HTTP",
    ),
    "mcpUnsupportedProtocol": MessageLookupByLibrary.simpleMessage(
      "The MCP server uses an unsupported protocol version.",
    ),
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("Артефакт"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "Память изменилась; повторите попытку",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("Исправление"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("Решение"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("Факт"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("Предпочтение"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("Открытый вопрос"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("Задача"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage("Введите сообщение..."),
    "messageSkills": MessageLookupByLibrary.simpleMessage("Навыки"),
    "minutesAgo": m27,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("Аудио"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("Файл"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("Изображение"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("Мультимодальный"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("Музыка"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("Реальное время"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("Речь"),
    "modalityText": MessageLookupByLibrary.simpleMessage("Текст"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("Видео"),
    "model": MessageLookupByLibrary.simpleMessage("Модель"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "Настройка модели",
    ),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage(
      "Размер контекста модели",
    ),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("Ввод"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("Вывод"),
    "modelsRetrievedSuccess": m28,
    "modificationTime": MessageLookupByLibrary.simpleMessage("Время изменения"),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("Имя"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Имя обновлено"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("Новый чат"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "Нет доступных подключённых инструментов MCP.",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Навыки не добавлены",
    ),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "Добавьте установленные навыки, необходимые этому боту.",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "Нет доступных ботов",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("Пока нет чатов"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "Содержимое не возвращено",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "Сводка разговора пока недоступна.",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "Подходящие боты не найдены",
    ),
    "noMatchingChats": MessageLookupByLibrary.simpleMessage(
      "No matching chats found",
    ),
    "noMatchingMcpServers": MessageLookupByLibrary.simpleMessage(
      "No matching MCP servers found",
    ),
    "noMatchingMcpTools": MessageLookupByLibrary.simpleMessage(
      "No matching tools found",
    ),
    "noMatchingSkills": MessageLookupByLibrary.simpleMessage(
      "Подходящие навыки не найдены",
    ),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "Модели не получены",
    ),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage(
      "Навыки не установлены",
    ),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "Импортируйте папку Agent Skills или ZIP-архив с файлом SKILL.md.",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "Нет данных об использовании токенов",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("Не поддерживается"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "Недостаточно старого контекста для сжатия",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openWithSystem": MessageLookupByLibrary.simpleMessage(
      "Open with system app",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("Выходные токены"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("Частичный ответ"),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("Приостановить аудио"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage(
      "Приостановить генерацию",
    ),
    "pinMemory": MessageLookupByLibrary.simpleMessage("Закрепить"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "Закрепить выбранное для этого разговора",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("Закреплён"),
    "playAudio": MessageLookupByLibrary.simpleMessage("Воспроизвести аудио"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Сначала введите ключ API",
    ),
    "pleaseEnterImageDescription": MessageLookupByLibrary.simpleMessage(
      "Please enter a description for image generation",
    ),
    "pleaseEnterMusicDescription": MessageLookupByLibrary.simpleMessage(
      "Enter a description for music generation",
    ),
    "pleaseEnterSpeechDescription": MessageLookupByLibrary.simpleMessage(
      "Enter a description for speech generation",
    ),
    "pleaseEnterVideoDescription": MessageLookupByLibrary.simpleMessage(
      "Enter a description for video generation",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage(
      "Предварительный просмотр текста",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Политика конфиденциальности",
    ),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "Информация о процессе",
    ),
    "processToolCount": m32,
    "profile": MessageLookupByLibrary.simpleMessage("Профиль"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Поделитесь своими предложениями и отзывами",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Провайдер"),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "Информация о провайдере",
    ),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage(
      "Рассуждение завершено",
    ),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage(
      "Рассуждение выполняется",
    ),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage(
      "Рассуждение прервано",
    ),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("Перестроить"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("Обновить"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Обновить каталоги",
    ),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Обновление каталогов…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("Удалить навык"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("Ответ отменен"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "Остановлено · Частичный ответ сохранён",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage(
      "Восстановить значения по умолчанию",
    ),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("Восстановить"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage(
      "Сохранённые последние ходы",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage(
      "Запустить проверку",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Сохранить"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Сохранить изменения"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("Сохранение..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("Поиск ботов"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage("Поиск в памяти"),
    "searchSkills": MessageLookupByLibrary.simpleMessage("Поиск навыков"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Выбрать бота"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Выбрать язык"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Выберите модель:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage(
      "Выберите провайдера:",
    ),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Выбрать тему"),
    "send": MessageLookupByLibrary.simpleMessage("Отправить"),
    "settings": MessageLookupByLibrary.simpleMessage("Настройки"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("Показать ключ API"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Показывать сведения о выполнении в сообщениях беседы.",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage(
      "Доступны ресурсы",
    ),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage("Совместимость"),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "Этот пример должен активировать навык",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "Пример запроса пользователя",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage(
      "Результат активации",
    ),
    "skillDetails": MessageLookupByLibrary.simpleMessage("Сведения о навыке"),
    "skillDigest": MessageLookupByLibrary.simpleMessage("Хеш содержимого"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("Выключен"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("Включён"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("Файлы"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "Навык импортирован",
    ),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("Навыки"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "Устанавливайте повторно используемые инструкции и привязывайте их к ботам.",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "В этой версии скрипты и команды из навыков не выполняются.",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("Издатель"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "Доступны справочные файлы",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md загружается только как управляемая инструкция для модели; скрипты, команды и внешние инструменты остаются отключёнными.",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "Песочница скриптов доступна",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "Скрипты отключены до вашего разрешения. Каждый вызов по-прежнему требует подтверждения.",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "Скрипты навыков недоступны",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "На этой платформе нет требуемой изоляции. Инструкции и ресурсы остаются доступными.",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "Настройка скриптов обновлена.",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "Скрипты установлены, но их выполнение отключено.",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage(
      "Скрипты включены",
    ),
    "skillSignature": MessageLookupByLibrary.simpleMessage("Подпись"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage(
      "Недействительная подпись",
    ),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "Неизвестный издатель",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage(
      "Без подписи",
    ),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "Подпись проверена",
    ),
    "skillSource": MessageLookupByLibrary.simpleMessage("Источник"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage(
      "Автоматически",
    ),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Доступно обновление",
    ),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("Вручную"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("Уведомлять"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("Закреплено"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage(
      "Политика обновлений",
    ),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("Пользователь"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage(
      "Примечания проверки",
    ),
    "skillVersion": MessageLookupByLibrary.simpleMessage("Версия"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Отправьте сообщение в поле ввода ниже, чтобы начать чат",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Начать общение"),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "Не удалось запустить приложение. Повторите попытку.",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage("Запуск…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("Активировано"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("Прикреплено"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage(
      "Ожидает подтверждения",
    ),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Отменено"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Завершено"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("Отклонено"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage("Повторный вызов"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("Ошибка"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("Создано"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("В процессе"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("Записано"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("Запрошено"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("Выполняется"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("Пропущено"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage(
      "Время ожидания истекло",
    ),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("Неизвестно"),
    "stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "stopAndContinue": MessageLookupByLibrary.simpleMessage(
      "Stop and continue",
    ),
    "stopGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Stop generation before leaving?",
    ),
    "stopGenerationBeforeLeavingDescription":
        MessageLookupByLibrary.simpleMessage(
          "The partial response will be kept.",
        ),
    "stopping": MessageLookupByLibrary.simpleMessage("Stopping…"),
    "structuredProcessInfo": MessageLookupByLibrary.simpleMessage(
      "Структурированная информация о процессе",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("Отправить отзыв"),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage("Сводка сообщений"),
    "supported": MessageLookupByLibrary.simpleMessage("Поддерживается"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("Поддерживает MCP"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage(
      "Поддерживает навыки",
    ),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("Системный промпт"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("Тест"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage(
      "Проверить описание",
    ),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "Установлена тёмная тема",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "Установлена светлая тема",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "Установлена системная тема",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage("Настройки темы"),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage(
      "Размышление завершено",
    ),
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("Размышление…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("Использование токенов"),
    "tokens": MessageLookupByLibrary.simpleMessage("токенов"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage(
      "Разрешено один раз",
    ),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("Отклонено"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("Вызовы инструментов"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage(
      "Разрушительный",
    ),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("Только чтение"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("Запись"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("Встроенный"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage(
      "Скрипт навыка",
    ),
    "totalTokens": MessageLookupByLibrary.simpleMessage("Всего токенов"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Измените условия поиска или создайте новый элемент.",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("Печатает..."),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage(
      "Unable to load bots",
    ),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage(
      "Unable to load chats",
    ),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage(
      "Unable to load messages",
    ),
    "unavailableBot": MessageLookupByLibrary.simpleMessage("Бот недоступен"),
    "uninstall": MessageLookupByLibrary.simpleMessage("Удалить"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage("Удалить навык"),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("Открепить"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "Формат изображения не поддерживается. Выберите изображение JPEG, PNG, GIF, BMP или WebP.",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("Загрузить файл"),
    "uploadImage": MessageLookupByLibrary.simpleMessage(
      "Загрузить изображение",
    ),
    "userAgreement": MessageLookupByLibrary.simpleMessage(
      "Пользовательское соглашение",
    ),
    "version": MessageLookupByLibrary.simpleMessage("Версия 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Не удалось загрузить видео",
    ),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("Открыть сводку"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
