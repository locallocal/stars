// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a de_DE locale. All the
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
  String get localeName => 'de_DE';

  static String m0(name) => "Bot \"${name}\" wurde hinzugefügt";

  static String m1(botName) => "\"${botName}\" wurde gelöscht";

  static String m2(botName) =>
      "Hallo! Ich bin ${botName}, ein KI-Assistent. Stellen Sie mir jederzeit Fragen, ich werde mein Bestes tun, um Ihnen zu helfen.";

  static String m3(botName) => "${botName} schreibt...";

  static String m4(botName) => "Bot ${botName} wurde aktualisiert";

  static String m5(botName) => "Chat mit ${botName} wurde gelöscht";

  static String m6(error) => "Could not clear chat history: ${error}";

  static String m7(botName) =>
      "Möchten Sie wirklich alle Chat-Verläufe mit \"${botName}\" löschen? Diese Aktion kann nicht rückgängig gemacht werden.";

  static String m8(botName) =>
      "Durch das Löschen des Bots werden alle zugehörigen Chats gelöscht. Möchten Sie ${botName} wirklich löschen?";

  static String m9(botName) =>
      "Durch das Löschen des Chats wird der gesamte Chat-Verlauf gelöscht. Möchten Sie den Chat mit ${botName} wirklich löschen?";

  static String m10(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m11(name) =>
      "${name} deinstallieren? Die Bot-Zuordnungen werden ebenfalls entfernt.";

  static String m12(year) => "© ${year} Stars-Team";

  static String m13(error) => "Could not create the chat: ${error}";

  static String m14(error) => "Could not delete the chat: ${error}";

  static String m15(milliseconds) => "${milliseconds} ms";

  static String m16(seconds) => "${seconds} s";

  static String m17(name) =>
      "${name} darf deklarierte Skripte als Tools registrieren. Jeder Aufruf erfordert weiterhin eine Genehmigung.";

  static String m18(count) => "${count} files";

  static String m19(error) => "Generate image failed: ${error}";

  static String m20(error) => "Could not generate music: ${error}";

  static String m21(error) => "Could not generate speech: ${error}";

  static String m22(error) => "Could not generate video: ${error}";

  static String m23(count) => "${count} items";

  static String m24(language) => "Sprache auf ${language} eingestellt";

  static String m25(error) => "MCP connection failed: ${error}";

  static String m26(count) => "${count} configured (values hidden)";

  static String m27(minutes) => "vor ${minutes} Minuten";

  static String m28(count) => "Erfolgreich ${count} Modelle abgerufen";

  static String m29(count) => "${count} Befehlsausführungen";

  static String m30(duration) => "Dauer ${duration}";

  static String m31(count) => "${count} Dateiänderungen";

  static String m32(count) => "${count} Tool-Aufrufe";

  static String m33(error) => "Antwort konnte nicht abgerufen werden: ${error}";

  static String m34(error) => "Could not save image: ${error}";

  static String m35(error) => "Could not share image: ${error}";

  static String m36(error) =>
      "Fähigkeit konnte nicht importiert werden: ${error}";

  static String m37(duration) => "Denken abgeschlossen · ${duration}";

  static String m38(error) => "Fehler bei der Videowiedergabe: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("Über"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Über Stars"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("Bot hinzufügen"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("Fähigkeit hinzufügen"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "App-Schriftgröße anpassen",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Schriftgröße anpassen",
    ),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Alle installierten Fähigkeiten wurden hinzugefügt.",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("Immer aktiv"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Diese Fähigkeit wird in jede Textanfrage eingefügt.",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("Immer aktiv"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API-Adresse:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API-Schlüssel"),
    "apiType": MessageLookupByLibrary.simpleMessage("API-Typ:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "Eine einfache, aber leistungsstarke KI-Chat-Anwendung, mit der Sie jederzeit und überall mit KI chatten können.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Stars - KI-Chat-Assistent",
    ),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "System-Prompt",
    ),
    "applicationInjectedPromptDescription": MessageLookupByLibrary.simpleMessage(
      "Wird von Stars verwaltet und jeder Modellanfrage hinzugefügt. Die Kennungen des aktuellen Agenten und der Unterhaltung werden zur Laufzeit ergänzt und können nicht bearbeitet werden.",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("Automatisch"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Unterstützte Modelle können diese Fähigkeit anhand ihrer Beschreibung aktivieren.",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "Dieser Anbieter unterstützt nur manuelle Fähigkeiten.",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage(
      "Automatische Erinnerung",
    ),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "Automatische Zusammenfassungen können ungenau sein. Die aktuelle Nachricht hat Vorrang.",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage(
      "Zurück zur täglichen Nutzung",
    ),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Grundlegende Informationen",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Bot-Avatar"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "MCP-Tools für diesen Agenten aktivieren. Tool-Aufrufe müssen standardmäßig bestätigt werden.",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("Bot-Name"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "Die Suche filtert die Liste nach Bot-Namen.",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("Fähigkeiten"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "Wählen Sie wiederverwendbare Anweisungen für diesen Bot aus.",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("Abbrechen"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("Avatar ändern"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("Gespeichert"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage(
      "Ausführungsstatus des Chats",
    ),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Chat-Verlauf wurde gelöscht",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Chats"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("Löschen"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage(
      "Automatische Erinnerung löschen",
    ),
    "clearChat": MessageLookupByLibrary.simpleMessage("Chat löschen"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Chat-Verlauf löschen",
    ),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage(
      "Anheftungen des Gesprächs löschen",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "Tag auswählen, um die stündliche Nutzung anzuzeigen",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Klicken Sie auf + in der oberen rechten Ecke, um einen Bot hinzuzufügen",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Klicken Sie auf Neuer Chat, um eine Unterhaltung zu erstellen",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage(
      "Befehlsausführungen",
    ),
    "compactNow": MessageLookupByLibrary.simpleMessage("Jetzt komprimieren"),
    "compactingContext": MessageLookupByLibrary.simpleMessage(
      "Kontext wird organisiert…",
    ),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("Fehlgeschlagen"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage(
      "Komprimierungsstatus",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Bestätigen"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Löschen bestätigen"),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Kontaktinformationen (optional)",
    ),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage(
      "Kontext und Erinnerung",
    ),
    "contextCompacted": MessageLookupByLibrary.simpleMessage(
      "Kontext komprimiert",
    ),
    "contextWindow": MessageLookupByLibrary.simpleMessage("Kontextfenster"),
    "conversationSummary": MessageLookupByLibrary.simpleMessage(
      "Gesprächszusammenfassung",
    ),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage(
      "Token-Anteil nach Unterhaltung",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage(
      "API-Schlüssel kopieren",
    ),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m12,
    "createChatFailed": m13,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Erstellungszeit"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Benutzerdefinierter Anbieter...",
    ),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage("Tägliche Nutzung"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dunkles Design"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "Diese Datenbank wurde mit einer neueren Version von Stars erstellt. Aktualisieren Sie die App, bevor Sie sie öffnen.",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "Die Integritätsprüfung der Datenbank ist fehlgeschlagen, und die Wiederherstellung aus der Sicherung dieser Version war nicht möglich.",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage("Tiefes Denken"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Du bist ein hilfreicher KI-Assistent. Bitte antworte auf Deutsch.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Löschen"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Bot löschen"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Chat löschen"),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "Info und Rechtliches",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "Erscheinungsbild und Sprache",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Ändere deinen Avatar und Anzeigenamen.",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("Allgemein"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage(
      "Hilfe und Support",
    ),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage(
      "Persönliche Informationen",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "Änderungen werden sofort wirksam und lokal gespeichert.",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Verwalte dein Profil, das Erscheinungsbild, die Sprache und den App-Support.",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Details"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Ohne Bestätigung für alle deaktivieren",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Alle Tools deaktivieren",
    ),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Skripte deaktivieren",
    ),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("Bearbeiten"),
    "editBot": MessageLookupByLibrary.simpleMessage("Bot bearbeiten"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("Erinnerung bearbeiten"),
    "editName": MessageLookupByLibrary.simpleMessage("Name bearbeiten"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Antwort konnte nicht abgerufen werden: Server hat eine leere Antwort zurückgegeben",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Ohne Bestätigung für alle aktivieren",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Alle Tools aktivieren",
    ),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Skripte aktivieren",
    ),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "Isolierte Skill-Skripte aktivieren?",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "API-Adresse eingeben...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage(
      "API-Schlüssel eingeben...",
    ),
    "enterBotName": MessageLookupByLibrary.simpleMessage(
      "Bot-Namen eingeben...",
    ),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage(
      "Anzeigenamen eingeben",
    ),
    "enterNewName": MessageLookupByLibrary.simpleMessage(
      "Bitte neuen Namen eingeben",
    ),
    "enterProviderName": MessageLookupByLibrary.simpleMessage(
      "Anbieternamen eingeben...",
    ),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "System-Prompt eingeben...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "Fehler beim Laden des Inhalts, bitte versuchen Sie es später erneut.",
    ),
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage(
      "Geschätzte Nutzung",
    ),
    "executionStatus": MessageLookupByLibrary.simpleMessage(
      "Ausführungsstatus",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie Feedback-Inhalt ein",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Bitte teilen Sie uns Ihre Gedanken, Probleme oder Vorschläge mit, um uns bei der Verbesserung der App zu helfen",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Geben Sie hier Ihr Feedback ein...",
    ),
    "feedbackInformation": MessageLookupByLibrary.simpleMessage(
      "Feedback-Informationen",
    ),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "Übermittlung fehlgeschlagen, bitte versuchen Sie es später erneut",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "Vielen Dank für Ihr Feedback!",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage(
      "Modellliste abrufen",
    ),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "Bitte zuerst Modellliste abrufen",
    ),
    "fileAttachment": MessageLookupByLibrary.simpleMessage("File attachment"),
    "fileCount": m18,
    "fileResult": MessageLookupByLibrary.simpleMessage("File result"),
    "fileStatus": MessageLookupByLibrary.simpleMessage("Dateistatus"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("Musik"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("Sprache"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("Video"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "Bitte Bot-Namen, API-Adresse und API-Schlüssel eingeben",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Systemeinstellung"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("Schriftgröße"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "Schriftgröße aktualisiert",
    ),
    "forgetMemory": MessageLookupByLibrary.simpleMessage("Vergessen"),
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
      "Generierung fehlgeschlagen",
    ),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "Generierung fehlgeschlagen · Teilantwort beibehalten",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("Hilfe & Feedback"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage(
      "API-Schlüssel ausblenden",
    ),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("Startseite"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage(
      "Stündliche Nutzung",
    ),
    "idle": MessageLookupByLibrary.simpleMessage("Leerlauf"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage(
      "Fähigkeitsordner importieren",
    ),
    "importSkillZip": MessageLookupByLibrary.simpleMessage(
      "Fähigkeits-ZIP importieren",
    ),
    "importingSkill": MessageLookupByLibrary.simpleMessage(
      "Fähigkeit wird importiert…",
    ),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("Eingabe-Token"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage(
      "Aktualisierung installieren",
    ),
    "invalidSummary": MessageLookupByLibrary.simpleMessage(
      "Die Zusammenfassung hat die Prüfung nicht bestanden",
    ),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("Gerade eben"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Spracheinstellungen",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Helles Design"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage(
      "Erinnerung verwalten",
    ),
    "manualActivation": MessageLookupByLibrary.simpleMessage("Pro Nachricht"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Wählen Sie die Fähigkeit bei Bedarf im Nachrichtenfeld aus.",
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
      "Ohne Bestätigung",
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
    "mcpServers": MessageLookupByLibrary.simpleMessage("MCP-Server"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "MCP-Server verbinden und ihre Tool-Kataloge entdecken. Tools werden nach dem Erstellen eines Agenten konfiguriert.",
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
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("Artefakt"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "Erinnerung geändert; bitte erneut versuchen",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("Korrektur"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("Entscheidung"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("Fakt"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("Präferenz"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("Offene Frage"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("Aufgabe"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage(
      "Nachricht eingeben...",
    ),
    "messageSkills": MessageLookupByLibrary.simpleMessage("Fähigkeiten"),
    "minutesAgo": m27,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("Audio"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("Datei"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("Bild"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("Multimodal"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("Musik"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("Echtzeit"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("Sprache"),
    "modalityText": MessageLookupByLibrary.simpleMessage("Text"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("Video"),
    "model": MessageLookupByLibrary.simpleMessage("Modell"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "Modellkonfiguration",
    ),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage(
      "Modellkontextgröße",
    ),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("Eingabe"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("Ausgabe"),
    "modelsRetrievedSuccess": m28,
    "modificationTime": MessageLookupByLibrary.simpleMessage("Änderungszeit"),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Name aktualisiert"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("Neuer Chat"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "Keine verbundenen MCP-Tools verfügbar.",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Keine Fähigkeiten hinzugefügt",
    ),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "Fügen Sie die installierten Fähigkeiten hinzu, die dieser Bot benötigt.",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "Keine Bots verfügbar",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("Noch keine Chats"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "Kein Inhalt zurückgegeben",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "Es ist noch keine Gesprächszusammenfassung verfügbar.",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "Keine passenden Bots gefunden",
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
      "Keine passenden Fähigkeiten gefunden",
    ),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "Keine Modelle abgerufen",
    ),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage(
      "Keine Fähigkeiten installiert",
    ),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "Importieren Sie einen Agent-Skills-Ordner oder eine ZIP-Datei mit SKILL.md.",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "Keine Token-Nutzung erfasst",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("Nicht unterstützt"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "Nicht genügend älterer Kontext zum Komprimieren",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("Ausgabe-Token"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("Teilantwort"),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("Audio pausieren"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage(
      "Generierung pausieren",
    ),
    "pinMemory": MessageLookupByLibrary.simpleMessage("Anheften"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "Auswahl für dieses Gespräch anheften",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("Angeheftet"),
    "playAudio": MessageLookupByLibrary.simpleMessage("Audio abspielen"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie zuerst den API-Schlüssel ein",
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
    "previewText": MessageLookupByLibrary.simpleMessage("Texteffekt-Vorschau"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Datenschutzrichtlinie",
    ),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "Prozessinformationen",
    ),
    "processToolCount": m32,
    "profile": MessageLookupByLibrary.simpleMessage("Profil"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Teilen Sie uns Ihre Vorschläge und Feedback mit",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Anbieter"),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "Anbieterinformationen",
    ),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage(
      "Denkvorgang abgeschlossen",
    ),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage(
      "Denkvorgang läuft",
    ),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage(
      "Denkvorgang unterbrochen",
    ),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("Neu erstellen"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("Aktualisieren"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Kataloge aktualisieren",
    ),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Kataloge werden aktualisiert…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("Fähigkeit entfernen"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage(
      "Antwort abgebrochen",
    ),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "Gestoppt · Teilantwort beibehalten",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage(
      "Auf Standard zurücksetzen",
    ),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("Wiederherstellen"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage(
      "Beibehaltene letzte Runden",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage(
      "Test ausführen",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Speichern"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Änderungen speichern"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage(
      "Wird gespeichert...",
    ),
    "searchBots": MessageLookupByLibrary.simpleMessage("Bots durchsuchen"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage(
      "Erinnerung durchsuchen",
    ),
    "searchSkills": MessageLookupByLibrary.simpleMessage(
      "Fähigkeiten durchsuchen",
    ),
    "selectBot": MessageLookupByLibrary.simpleMessage("Bot auswählen"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Sprache auswählen"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Modell auswählen:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage(
      "Anbieter auswählen:",
    ),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Thema auswählen"),
    "send": MessageLookupByLibrary.simpleMessage("Senden"),
    "settings": MessageLookupByLibrary.simpleMessage("Einstellungen"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage(
      "API-Schlüssel anzeigen",
    ),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Ausführungsdetails in Unterhaltungsnachrichten anzeigen.",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage(
      "Assets verfügbar",
    ),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage(
      "Kompatibilität",
    ),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "Dieses Beispiel soll die Fähigkeit aktivieren",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "Beispielanfrage",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage(
      "Aktivierungsergebnis",
    ),
    "skillDetails": MessageLookupByLibrary.simpleMessage("Fähigkeitsdetails"),
    "skillDigest": MessageLookupByLibrary.simpleMessage("Inhalts-Hash"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("Deaktiviert"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("Aktiviert"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("Dateien"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "Fähigkeit importiert",
    ),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("Fähigkeiten"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "Wiederverwendbare Anweisungen installieren und Bots zuordnen.",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "Diese Version führt keine Skripte oder Befehle aus Fähigkeiten aus.",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("Herausgeber"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "Referenzdateien verfügbar",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md wird nur als kontrollierte Prompt-Anweisung geladen; Skripte, Befehle und externe Tools bleiben deaktiviert.",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "Desktop-Skript-Sandbox verfügbar",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "Skripte bleiben pro Skill deaktiviert, bis Sie sie freigeben. Jeder Aufruf benötigt weiterhin eine Genehmigung.",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "Skill-Skripte nicht verfügbar",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "Diese Plattform bietet keine ausreichende isolierte Hilfsumgebung. Anweisungen und Ressourcen bleiben verfügbar.",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "Skill-Skripteinstellung aktualisiert.",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "Skripte sind installiert, ihre Ausführung ist jedoch deaktiviert.",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage(
      "Skripte aktiviert",
    ),
    "skillSignature": MessageLookupByLibrary.simpleMessage("Signatur"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage(
      "Ungültige Signatur",
    ),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "Unbekannter Herausgeber",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage(
      "Nicht signiert",
    ),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "Signatur verifiziert",
    ),
    "skillSource": MessageLookupByLibrary.simpleMessage("Quelle"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("Automatisch"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Aktualisierung verfügbar",
    ),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("Manuell"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage(
      "Benachrichtigen",
    ),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("Fixiert"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage(
      "Aktualisierungsrichtlinie",
    ),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("Benutzer"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage(
      "Validierungshinweise",
    ),
    "skillVersion": MessageLookupByLibrary.simpleMessage("Version"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Senden Sie eine Nachricht im Eingabefeld unten, um den Chat zu beginnen",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage(
      "Beginnen Sie zu chatten",
    ),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "Start fehlgeschlagen. Bitte erneut versuchen.",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage(
      "Stars wird gestartet…",
    ),
    "statusActivated": MessageLookupByLibrary.simpleMessage("Aktiviert"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("Angehängt"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage(
      "Wartet auf Bestätigung",
    ),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Abgebrochen"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Abgeschlossen"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("Abgelehnt"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage("Doppelter Aufruf"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("Fehlgeschlagen"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("Generiert"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("In Bearbeitung"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("Erfasst"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("Angefordert"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("Wird ausgeführt"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("Übersprungen"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage(
      "Zeitüberschreitung",
    ),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("Unbekannt"),
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
      "Strukturierte Prozessinformationen",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("Feedback senden"),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage(
      "Zusammengefasste Nachrichten",
    ),
    "supported": MessageLookupByLibrary.simpleMessage("Unterstützt"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("Unterstützt MCP"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage(
      "Unterstützt Skills",
    ),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("System-Prompt"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("Testen"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage(
      "Beschreibung testen",
    ),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "Thema auf dunkles Design gesetzt",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "Thema auf helles Design gesetzt",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "Thema auf Systemeinstellung gesetzt",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage(
      "Thema-Einstellungen",
    ),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage(
      "Denken abgeschlossen",
    ),
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("Denkt nach…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("Token-Nutzung"),
    "tokens": MessageLookupByLibrary.simpleMessage("Token"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage(
      "Einmal erlaubt",
    ),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("Abgelehnt"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("Tool-Aufrufe"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("Destruktiv"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage(
      "Schreibgeschützt",
    ),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("Schreiben"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("Integriert"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage(
      "Skill-Skript",
    ),
    "totalTokens": MessageLookupByLibrary.simpleMessage("Token insgesamt"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Versuchen Sie eine andere Suche oder erstellen Sie einen neuen Eintrag.",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("Schreibt..."),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage(
      "Unable to load bots",
    ),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage(
      "Unable to load chats",
    ),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage(
      "Unable to load messages",
    ),
    "unavailableBot": MessageLookupByLibrary.simpleMessage(
      "Bot nicht verfügbar",
    ),
    "uninstall": MessageLookupByLibrary.simpleMessage("Deinstallieren"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage(
      "Fähigkeit deinstallieren",
    ),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("Lösen"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "Nicht unterstütztes Bildformat. Wählen Sie ein JPEG-, PNG-, GIF-, BMP- oder WebP-Bild.",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("Datei hochladen"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("Bild hochladen"),
    "userAgreement": MessageLookupByLibrary.simpleMessage(
      "Benutzervereinbarung",
    ),
    "version": MessageLookupByLibrary.simpleMessage("Version 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Video konnte nicht geladen werden",
    ),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage(
      "Zusammenfassung anzeigen",
    ),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
