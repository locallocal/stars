// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a it_IT locale. All the
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
  String get localeName => 'it_IT';

  static String m0(name) => "Bot \"${name}\" aggiunto";

  static String m1(botName) => "\"${botName}\" è stato eliminato";

  static String m2(botName) =>
      "Ciao! Sono ${botName}, un assistente AI. Puoi farmi qualsiasi domanda e farò del mio meglio per aiutarti.";

  static String m3(botName) => "${botName} sta scrivendo...";

  static String m4(botName) => "Bot ${botName} aggiornato";

  static String m5(botName) => "Chat con ${botName} eliminata";

  static String m6(botName) =>
      "Sei sicuro di voler cancellare tutta la cronologia chat con \"${botName}\"? Questa azione non può essere annullata.";

  static String m7(botName) =>
      "Eliminare il bot rimuoverà anche tutte le chat associate. Sei sicuro di voler eliminare ${botName}?";

  static String m8(botName) =>
      "Eliminare la chat cancellerà tutta la cronologia delle conversazioni. Sei sicuro di voler eliminare la chat con ${botName}?";

  static String m9(language) => "Lingua impostata a ${language}";

  static String m10(minutes) => "${minutes} minuti fa";

  static String m11(count) => "${count} modelli recuperati con successo";

  static String m12(error) => "Impossibile ottenere risposta: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bot"),
    "about": MessageLookupByLibrary.simpleMessage("Informazioni"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Informazioni su Bubble"),
    "addBot": MessageLookupByLibrary.simpleMessage("Aggiungi bot"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Regola dimensione testo nell\'app",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Regola dimensione testo",
    ),
    "apiAddress": MessageLookupByLibrary.simpleMessage("Indirizzo API:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("Chiave API"),
    "apiType": MessageLookupByLibrary.simpleMessage("Tipo API:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "Un\'app di chat AI semplice ma potente che ti permette di conversare con l\'AI ovunque tu sia.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Bubble"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Bubble - Assistente chat AI",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Avatar bot"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botIsTyping": m3,
    "botName": MessageLookupByLibrary.simpleMessage("Nome bot"),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("Annulla"),
    "chatDeleted": m5,
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Cronologia chat cancellata",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Chat"),
    "clear": MessageLookupByLibrary.simpleMessage("Cancella"),
    "clearChat": MessageLookupByLibrary.simpleMessage("Cancella chat"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Cancella cronologia chat",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Clicca + nell\'angolo in alto a destra per aggiungere un bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Clicca + nell\'angolo in alto a destra per iniziare una chat",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Conferma"),
    "confirmClearChat": m6,
    "confirmDelete": MessageLookupByLibrary.simpleMessage(
      "Conferma eliminazione",
    ),
    "confirmDeleteBot": m7,
    "confirmDeleteChat": m8,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Informazioni di contatto (opzionale)",
    ),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 Team Bubble"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Fornitore personalizzato...",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Modalità scura"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Sei un assistente AI utile. Per favore, rispondi in italiano.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Elimina"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Elimina bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Elimina chat"),
    "editBot": MessageLookupByLibrary.simpleMessage("Modifica bot"),
    "editName": MessageLookupByLibrary.simpleMessage("Modifica nome"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Impossibile ottenere risposta: il server ha restituito una risposta vuota",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "Inserisci indirizzo API...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage(
      "Inserisci chiave API...",
    ),
    "enterBotName": MessageLookupByLibrary.simpleMessage(
      "Inserisci nome bot...",
    ),
    "enterNewName": MessageLookupByLibrary.simpleMessage(
      "Inserisci nuovo nome",
    ),
    "enterProviderName": MessageLookupByLibrary.simpleMessage(
      "Inserisci nome fornitore...",
    ),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Inserisci prompt di sistema...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "Errore durante il caricamento del contenuto, riprova più tardi.",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Inserisci il contenuto del feedback",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Raccontaci i tuoi pensieri, problemi o suggerimenti per aiutarci a migliorare l\'app",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Inserisci il tuo feedback qui...",
    ),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "Invio fallito, riprova più tardi",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "Grazie per il tuo feedback!",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage(
      "Ottieni lista modelli",
    ),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "Ottieni prima la lista dei modelli",
    ),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "Compila nome bot, indirizzo API e chiave API",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Segui sistema"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage(
      "Dimensione testo",
    ),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "Dimensione testo aggiornata",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("Aiuto e feedback"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "justNow": MessageLookupByLibrary.simpleMessage("Proprio ora"),
    "languageChanged": m9,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Impostazioni lingua",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Modalità chiara"),
    "messageHint": MessageLookupByLibrary.simpleMessage(
      "Inserisci messaggio...",
    ),
    "minutesAgo": m10,
    "model": MessageLookupByLibrary.simpleMessage("Modello"),
    "modelsRetrievedSuccess": m11,
    "name": MessageLookupByLibrary.simpleMessage("Nome"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Nome aggiornato"),
    "newChat": MessageLookupByLibrary.simpleMessage("Nuova chat"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "Nessun bot disponibile",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("Nessuna chat ancora"),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "Nessun modello recuperato",
    ),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage(
      "Pausa generazione",
    ),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Inserisci prima la chiave API",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage("Anteprima testo"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Politica sulla privacy",
    ),
    "profile": MessageLookupByLibrary.simpleMessage("Profilo"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Fornisci i tuoi suggerimenti e feedback",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Fornitore"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage(
      "Risposta annullata",
    ),
    "responseError": m12,
    "save": MessageLookupByLibrary.simpleMessage("Salva"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Salva modifiche"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Seleziona bot"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Seleziona lingua"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Seleziona modello:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage(
      "Seleziona fornitore:",
    ),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Seleziona tema"),
    "send": MessageLookupByLibrary.simpleMessage("Invia"),
    "settings": MessageLookupByLibrary.simpleMessage("Impostazioni"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Invia un messaggio nel campo di testo sotto per iniziare a chattare",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Inizia a chattare"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("Invia feedback"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("Prompt di sistema:"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "Tema impostato su scuro",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "Tema impostato su chiaro",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "Tema impostato su sistema",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage("Impostazioni tema"),
    "typing": MessageLookupByLibrary.simpleMessage("Digitando..."),
    "userAgreement": MessageLookupByLibrary.simpleMessage("Accordo utente"),
    "version": MessageLookupByLibrary.simpleMessage("Versione 1.0.0"),
  };
}
