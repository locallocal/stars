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

  static String m6(botName) =>
      "Möchten Sie wirklich alle Chat-Verläufe mit \"${botName}\" löschen? Diese Aktion kann nicht rückgängig gemacht werden.";

  static String m7(botName) =>
      "Durch das Löschen des Bots werden alle zugehörigen Chats gelöscht. Möchten Sie ${botName} wirklich löschen?";

  static String m8(botName) =>
      "Durch das Löschen des Chats wird der gesamte Chat-Verlauf gelöscht. Möchten Sie den Chat mit ${botName} wirklich löschen?";

  static String m9(language) => "Sprache auf ${language} eingestellt";

  static String m10(minutes) => "vor ${minutes} Minuten";

  static String m11(error) =>
      "Antwort konnte nicht abgerufen werden: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("Über"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Über Bubble"),
    "addBot": MessageLookupByLibrary.simpleMessage("Bot hinzufügen"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "App-Schriftgröße anpassen",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Schriftgröße anpassen",
    ),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API-Adresse:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API-Schlüssel"),
    "apiType": MessageLookupByLibrary.simpleMessage("API-Typ:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "Eine einfache, aber leistungsstarke KI-Chat-Anwendung, mit der Sie jederzeit und überall mit KI chatten können.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Bubble"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Bubble - KI-Chat-Assistent",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Bot-Avatar"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botIsTyping": m3,
    "botName": MessageLookupByLibrary.simpleMessage("Bot-Name"),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("Abbrechen"),
    "chatDeleted": m5,
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Chat-Verlauf wurde gelöscht",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Chats"),
    "clear": MessageLookupByLibrary.simpleMessage("Löschen"),
    "clearChat": MessageLookupByLibrary.simpleMessage("Chat löschen"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Chat-Verlauf löschen",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Klicken Sie auf + in der oberen rechten Ecke, um einen Bot hinzuzufügen",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Klicken Sie auf + in der oberen rechten Ecke, um einen Chat zu starten",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Bestätigen"),
    "confirmClearChat": m6,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Löschen bestätigen"),
    "confirmDeleteBot": m7,
    "confirmDeleteChat": m8,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Kontaktinformationen (optional)",
    ),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 Bubble-Team"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Benutzerdefinierter Anbieter...",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dunkles Design"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Du bist ein hilfreicher KI-Assistent. Bitte antworte auf Deutsch.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Löschen"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Bot löschen"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Chat löschen"),
    "editBot": MessageLookupByLibrary.simpleMessage("Bot bearbeiten"),
    "editName": MessageLookupByLibrary.simpleMessage("Name bearbeiten"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Antwort konnte nicht abgerufen werden: Server hat eine leere Antwort zurückgegeben",
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
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie Feedback-Inhalt ein",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Bitte teilen Sie uns Ihre Gedanken, Probleme oder Vorschläge mit, um uns bei der Verbesserung der App zu helfen",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Geben Sie hier Ihr Feedback ein...",
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
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "Bitte Bot-Namen, API-Adresse und API-Schlüssel eingeben",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Systemeinstellung"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("Schriftgröße"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "Schriftgröße aktualisiert",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("Hilfe & Feedback"),
    "home": MessageLookupByLibrary.simpleMessage("Startseite"),
    "justNow": MessageLookupByLibrary.simpleMessage("Gerade eben"),
    "languageChanged": m9,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Spracheinstellungen",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Helles Design"),
    "messageHint": MessageLookupByLibrary.simpleMessage(
      "Nachricht eingeben...",
    ),
    "minutesAgo": m10,
    "model": MessageLookupByLibrary.simpleMessage("Modell"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Name aktualisiert"),
    "newChat": MessageLookupByLibrary.simpleMessage("Neuer Chat"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "Keine Bots verfügbar",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("Noch keine Chats"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage(
      "Generierung pausieren",
    ),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Bitte geben Sie zuerst den API-Schlüssel ein",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage("Texteffekt-Vorschau"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Datenschutzrichtlinie",
    ),
    "profile": MessageLookupByLibrary.simpleMessage("Profil"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Teilen Sie uns Ihre Vorschläge und Feedback mit",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Anbieter"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage(
      "Antwort abgebrochen",
    ),
    "responseError": m11,
    "save": MessageLookupByLibrary.simpleMessage("Speichern"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Änderungen speichern"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Bot auswählen"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Sprache auswählen"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Modell auswählen:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage(
      "Anbieter auswählen:",
    ),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Thema auswählen"),
    "send": MessageLookupByLibrary.simpleMessage("Senden"),
    "settings": MessageLookupByLibrary.simpleMessage("Einstellungen"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Senden Sie eine Nachricht im Eingabefeld unten, um den Chat zu beginnen",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage(
      "Beginnen Sie zu chatten",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("Feedback senden"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("System-Prompt"),
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
    "typing": MessageLookupByLibrary.simpleMessage("Schreibt..."),
    "userAgreement": MessageLookupByLibrary.simpleMessage(
      "Benutzervereinbarung",
    ),
    "version": MessageLookupByLibrary.simpleMessage("Version 1.0.0"),
  };
}
