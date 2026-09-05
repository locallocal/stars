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

  static String m0(status, reason) => "${status}. ${reason}";

  static String m1(name) => "Bot \"${name}\" aggiunto";

  static String m2(botName) => "\"${botName}\" è stato eliminato";

  static String m3(botName) =>
      "Ciao! Sono ${botName}, un assistente AI. Puoi farmi qualsiasi domanda e farò del mio meglio per aiutarti.";

  static String m4(botName) => "${botName} sta scrivendo...";

  static String m5(botName) => "Bot ${botName} aggiornato";

  static String m6(botName) => "Chat con ${botName} eliminata";

  static String m7(error) => "Could not clear chat history: ${error}";

  static String m8(botName) =>
      "Sei sicuro di voler cancellare tutta la cronologia chat con \"${botName}\"? Questa azione non può essere annullata.";

  static String m9(botName) =>
      "Eliminare il bot rimuoverà anche tutte le chat associate. Sei sicuro di voler eliminare ${botName}?";

  static String m10(botName) =>
      "Eliminare la chat cancellerà tutta la cronologia delle conversazioni. Sei sicuro di voler eliminare la chat con ${botName}?";

  static String m11(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m12(name) =>
      "Disinstallare ${name}? Verranno rimossi anche i collegamenti ai bot.";

  static String m13(year) => "© ${year} Team Stars";

  static String m14(error) => "Could not create the chat: ${error}";

  static String m15(error) => "Could not delete the chat: ${error}";

  static String m16(milliseconds) => "${milliseconds} ms";

  static String m17(seconds) => "${seconds} s";

  static String m18(name) =>
      "Consenti a ${name} di registrare gli script dichiarati come strumenti. Ogni chiamata richiederà comunque l’approvazione.";

  static String m19(count) => "${count} files";

  static String m20(error) => "Generate image failed: ${error}";

  static String m21(error) => "Could not generate music: ${error}";

  static String m22(error) => "Could not generate speech: ${error}";

  static String m23(error) => "Could not generate video: ${error}";

  static String m24(count) => "${count} items";

  static String m25(language) => "Lingua impostata a ${language}";

  static String m26(error) => "MCP connection failed: ${error}";

  static String m27(count) => "${count} configured (values hidden)";

  static String m28(minutes) => "${minutes} minuti fa";

  static String m29(count) => "${count} modelli recuperati con successo";

  static String m30(count) => "${count} esecuzioni di comandi";

  static String m31(duration) => "Durata ${duration}";

  static String m32(count) => "${count} modifiche ai file";

  static String m33(count) => "${count} chiamate agli strumenti";

  static String m34(error) => "Impossibile ottenere risposta: ${error}";

  static String m35(error) => "Could not save image: ${error}";

  static String m36(error) => "Could not share image: ${error}";

  static String m37(error) => "Impossibile importare la competenza: ${error}";

  static String m38(duration) => "Elaborazione completata · ${duration}";

  static String m39(error) => "Errore di riproduzione video: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bot"),
    "about": MessageLookupByLibrary.simpleMessage("Informazioni"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Informazioni su Stars"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("Aggiungi bot"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("Aggiungi competenza"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Regola dimensione testo nell\'app",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Regola dimensione testo",
    ),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Tutte le competenze installate sono state aggiunte.",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("Sempre attiva"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Inserisce questa competenza in ogni richiesta di testo.",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("Sempre attiva"),
    "answerTrustFailed": MessageLookupByLibrary.simpleMessage("Non riuscito"),
    "answerTrustReasonGateFailed": MessageLookupByLibrary.simpleMessage(
      "Questa risposta non ha superato il controllo di attendibilità dell\'applicazione.",
    ),
    "answerTrustReasonNoTool": MessageLookupByLibrary.simpleMessage(
      "Non sono disponibili prove utilizzabili dagli strumenti per questa risposta.",
    ),
    "answerTrustReasonProviderFailed": MessageLookupByLibrary.simpleMessage(
      "La richiesta al provider non è riuscita prima che questa risposta potesse essere verificata.",
    ),
    "answerTrustReasonProviderUnsupported":
        MessageLookupByLibrary.simpleMessage(
          "Questo provider non supporta gli strumenti di verifica.",
        ),
    "answerTrustReasonToolRejected": MessageLookupByLibrary.simpleMessage(
      "La richiesta dello strumento di verifica è stata rifiutata.",
    ),
    "answerTrustReasonUnavailable": MessageLookupByLibrary.simpleMessage(
      "La verifica di questa risposta non è stata completata.",
    ),
    "answerTrustSemanticLabel": m0,
    "answerTrustUnverified": MessageLookupByLibrary.simpleMessage(
      "Non verificato",
    ),
    "apiAddress": MessageLookupByLibrary.simpleMessage("Indirizzo API:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("Chiave API"),
    "apiType": MessageLookupByLibrary.simpleMessage("Tipo API:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "Un\'app di chat AI semplice ma potente che ti permette di conversare con l\'AI ovunque tu sia.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Stars - Assistente chat AI",
    ),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "Prompt di sistema",
    ),
    "applicationInjectedPromptDescription": MessageLookupByLibrary.simpleMessage(
      "Gestito da Stars. Quando è attivo, il contenuto seguente viene aggiunto alle richieste del modello della conversazione; quando è disattivato, viene omesso. Il contesto di esecuzione necessario non è interessato. Il contenuto non è modificabile.",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("Automatica"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Consente ai modelli supportati di attivare questa competenza dalla sua descrizione.",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "Questo provider supporta solo competenze manuali.",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage(
      "Memoria automatica",
    ),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "I riepiloghi automatici possono essere imprecisi. Il messaggio corrente ha sempre la precedenza.",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage(
      "Torna all’utilizzo giornaliero",
    ),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Informazioni di base",
    ),
    "botAddedSuccess": m1,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Avatar bot"),
    "botDeleted": m2,
    "botGreeting": m3,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m4,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "Abilita gli strumenti MCP per questo agente. Le chiamate richiedono conferma per impostazione predefinita.",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("Nome bot"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "La ricerca filtra l’elenco per nome del bot.",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("Competenze"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "Scegli le istruzioni riutilizzabili disponibili per questo bot.",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m5,
    "browseConversationDirectory": MessageLookupByLibrary.simpleMessage(
      "Browse conversation data",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Annulla"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("Cambia avatar"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("Salvato"),
    "chatDeleted": m6,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage(
      "Stato di esecuzione della chat",
    ),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Cronologia chat cancellata",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Chat"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("Cancella"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage(
      "Cancella memoria automatica",
    ),
    "clearChat": MessageLookupByLibrary.simpleMessage("Cancella chat"),
    "clearChatFailed": m7,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Cancella cronologia chat",
    ),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage(
      "Rimuovi competenze fissate",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "Seleziona un giorno per visualizzare l’utilizzo orario",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Clicca + nell\'angolo in alto a destra per aggiungere un bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Fai clic su Nuova chat per creare una conversazione",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage(
      "Esecuzioni dei comandi",
    ),
    "compactNow": MessageLookupByLibrary.simpleMessage("Comprimi ora"),
    "compactingContext": MessageLookupByLibrary.simpleMessage(
      "Organizzazione del contesto…",
    ),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("Non riuscito"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage(
      "Stato compressione",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Conferma"),
    "confirmClearChat": m8,
    "confirmDelete": MessageLookupByLibrary.simpleMessage(
      "Conferma eliminazione",
    ),
    "confirmDeleteBot": m9,
    "confirmDeleteChat": m10,
    "confirmDeleteMcpServer": m11,
    "confirmUninstallSkill": m12,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Informazioni di contatto (opzionale)",
    ),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage(
      "Contesto e memoria",
    ),
    "contextCompacted": MessageLookupByLibrary.simpleMessage(
      "Contesto compresso",
    ),
    "contextWindow": MessageLookupByLibrary.simpleMessage(
      "Finestra di contesto",
    ),
    "conversationDirectory": MessageLookupByLibrary.simpleMessage(
      "Conversation data directory",
    ),
    "conversationDirectoryDescription": MessageLookupByLibrary.simpleMessage(
      "Browse files and folders stored for this conversation.",
    ),
    "conversationDirectoryEmpty": MessageLookupByLibrary.simpleMessage(
      "This conversation directory is empty.",
    ),
    "conversationSummary": MessageLookupByLibrary.simpleMessage(
      "Riepilogo conversazione",
    ),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage(
      "Distribuzione dei token per conversazione",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("Copia chiave API"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m13,
    "createChatFailed": m14,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Data di creazione"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Fornitore personalizzato...",
    ),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage(
      "Utilizzo giornaliero",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Modalità scura"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "Questo database è stato creato da una versione più recente di Stars. Aggiorna l’app prima di aprirlo.",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "Il controllo di integrità del database non è riuscito e non è stato possibile ripristinarlo dal backup di questa versione.",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage(
      "Ragionamento approfondito",
    ),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Sei un assistente AI utile. Per favore, rispondi in italiano.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Elimina"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Elimina bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Elimina chat"),
    "deleteChatFailed": m15,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "Informazioni e note legali",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "Aspetto e lingua",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Modifica il tuo avatar e il nome visualizzato.",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("Generali"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage(
      "Aiuto e supporto",
    ),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage(
      "Informazioni personali",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "Le modifiche hanno effetto immediato e vengono salvate localmente.",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Gestisci il profilo, l’aspetto, la lingua e il supporto dell’app.",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Dettagli"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Disabilita senza conferma per tutti",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Disabilita tutti gli strumenti",
    ),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Disattiva script",
    ),
    "durationMilliseconds": m16,
    "durationSeconds": m17,
    "edit": MessageLookupByLibrary.simpleMessage("Modifica"),
    "editBot": MessageLookupByLibrary.simpleMessage("Modifica bot"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("Modifica memoria"),
    "editName": MessageLookupByLibrary.simpleMessage("Modifica nome"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Impossibile ottenere risposta: il server ha restituito una risposta vuota",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Abilita senza conferma per tutti",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Abilita tutti gli strumenti",
    ),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage("Attiva script"),
    "enableSkillScriptsDescription": m18,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "Attivare gli script isolati?",
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
    "enterDisplayName": MessageLookupByLibrary.simpleMessage(
      "Inserisci un nome visualizzato",
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
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage(
      "Utilizzo stimato",
    ),
    "executionStatus": MessageLookupByLibrary.simpleMessage(
      "Stato di esecuzione",
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
    "feedbackInformation": MessageLookupByLibrary.simpleMessage(
      "Informazioni sul feedback",
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
    "fileAttachment": MessageLookupByLibrary.simpleMessage("File attachment"),
    "fileCount": m19,
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
    "fileStatus": MessageLookupByLibrary.simpleMessage("Stato dei file"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("Musica"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("Voce"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("Video"),
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
    "forgetMemory": MessageLookupByLibrary.simpleMessage("Dimentica"),
    "generateImageFailed": m20,
    "generateMusicFailed": m21,
    "generateSpeechFailed": m22,
    "generateVideoFailed": m23,
    "generatedImage": MessageLookupByLibrary.simpleMessage("Image generated"),
    "generating": MessageLookupByLibrary.simpleMessage("Generating…"),
    "generatingImage": MessageLookupByLibrary.simpleMessage(
      "Generating image, please wait...",
    ),
    "generationFailed": MessageLookupByLibrary.simpleMessage(
      "Generazione non riuscita",
    ),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "Generazione non riuscita · Risposta parziale conservata",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("Aiuto e feedback"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("Nascondi chiave API"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage("Utilizzo orario"),
    "htmlPreview": MessageLookupByLibrary.simpleMessage("Anteprima HTML"),
    "idle": MessageLookupByLibrary.simpleMessage("Inattivo"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage(
      "Importa cartella delle competenze",
    ),
    "importSkillZip": MessageLookupByLibrary.simpleMessage(
      "Importa ZIP delle competenze",
    ),
    "importingSkill": MessageLookupByLibrary.simpleMessage(
      "Importazione della competenza…",
    ),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("Token di input"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage(
      "Installa aggiornamento",
    ),
    "invalidSummary": MessageLookupByLibrary.simpleMessage(
      "Il riepilogo non ha superato la convalida",
    ),
    "itemCount": m24,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("Proprio ora"),
    "languageChanged": m25,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Impostazioni lingua",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Modalità chiara"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("Gestisci memoria"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("Per messaggio"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Se necessario, seleziona la competenza nel campo del messaggio.",
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
    "mcpConnectionFailed": m26,
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
    "mcpHiddenEnvironmentVariableCount": m27,
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
      "Senza conferma",
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
    "mcpServers": MessageLookupByLibrary.simpleMessage("Server MCP"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Collega server MCP e scopri i relativi cataloghi di strumenti. Configura gli strumenti dopo aver creato un agente.",
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
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("Artefatto"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "La memoria è cambiata; riprova",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("Correzione"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("Decisione"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("Fatto"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("Preferenza"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("Domanda aperta"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("Attività"),
    "memoryUserAssertion": MessageLookupByLibrary.simpleMessage(
      "Affermazione dell\'utente",
    ),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage(
      "Inserisci messaggio...",
    ),
    "messageSkills": MessageLookupByLibrary.simpleMessage("Competenze"),
    "minutesAgo": m28,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("Audio"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("File"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("Immagine"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("Multimodale"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("Musica"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("Tempo reale"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("Voce"),
    "modalityText": MessageLookupByLibrary.simpleMessage("Testo"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("Video"),
    "model": MessageLookupByLibrary.simpleMessage("Modello"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "Configurazione del modello",
    ),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage(
      "Dimensione del contesto del modello",
    ),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("Ingresso"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("Uscita"),
    "modelsRetrievedSuccess": m29,
    "modificationTime": MessageLookupByLibrary.simpleMessage(
      "Data di modifica",
    ),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("Nome"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Nome aggiornato"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("Nuova chat"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "Non sono disponibili strumenti MCP connessi.",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Nessuna competenza aggiunta",
    ),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "Aggiungi le competenze installate necessarie a questo bot.",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "Nessun bot disponibile",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("Nessuna chat ancora"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "Nessun contenuto restituito",
    ),
    "noConversationFilesFound": MessageLookupByLibrary.simpleMessage(
      "No matching files or folders.",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "Non è ancora disponibile un riepilogo della conversazione.",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "Nessun bot corrispondente trovato",
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
      "Nessuna competenza corrispondente trovata",
    ),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "Nessun modello recuperato",
    ),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage(
      "Nessuna competenza installata",
    ),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "Importa una cartella Agent Skills o un file ZIP contenente SKILL.md.",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "Nessun utilizzo dei token registrato",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("Non supportato"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "Contesto precedente insufficiente da comprimere",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openLink": MessageLookupByLibrary.simpleMessage("Apri link"),
    "openWithSystem": MessageLookupByLibrary.simpleMessage(
      "Open with system app",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("Token di output"),
    "partialResponse": MessageLookupByLibrary.simpleMessage(
      "Risposta parziale",
    ),
    "pauseAudio": MessageLookupByLibrary.simpleMessage(
      "Metti in pausa l’audio",
    ),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage(
      "Pausa generazione",
    ),
    "pinMemory": MessageLookupByLibrary.simpleMessage("Fissa"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "Fissa la selezione per questa conversazione",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("Fissata"),
    "playAudio": MessageLookupByLibrary.simpleMessage("Riproduci audio"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Inserisci prima la chiave API",
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
    "preview": MessageLookupByLibrary.simpleMessage("Anteprima"),
    "previewText": MessageLookupByLibrary.simpleMessage("Anteprima testo"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Politica sulla privacy",
    ),
    "processCommandCount": m30,
    "processDuration": m31,
    "processFileCount": m32,
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "Informazioni sul processo",
    ),
    "processToolCount": m33,
    "profile": MessageLookupByLibrary.simpleMessage("Profilo"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Fornisci i tuoi suggerimenti e feedback",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Fornitore"),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "Informazioni sul provider",
    ),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage(
      "Ragionamento completato",
    ),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage(
      "Ragionamento in corso",
    ),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage(
      "Ragionamento interrotto",
    ),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("Ricostruisci"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("Aggiorna"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Aggiorna cataloghi",
    ),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Aggiornamento cataloghi…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("Rimuovi competenza"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage(
      "Risposta annullata",
    ),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "Interrotto · Risposta parziale conservata",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage(
      "Ripristina impostazioni predefinite",
    ),
    "responseError": m34,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("Ripristina"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage(
      "Turni recenti mantenuti",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage(
      "Esegui verifica",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Salva"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Salva modifiche"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m35,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("Salvataggio..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("Cerca bot"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchConversationFiles": MessageLookupByLibrary.simpleMessage(
      "Search files and folders",
    ),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage("Cerca nella memoria"),
    "searchSkills": MessageLookupByLibrary.simpleMessage("Cerca competenze"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Seleziona bot"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Seleziona lingua"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Seleziona modello:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage(
      "Seleziona fornitore:",
    ),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Seleziona tema"),
    "send": MessageLookupByLibrary.simpleMessage("Invia"),
    "settings": MessageLookupByLibrary.simpleMessage("Impostazioni"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m36,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("Mostra chiave API"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Mostra i dettagli di esecuzione nei messaggi della conversazione.",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage(
      "Risorse disponibili",
    ),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage("Compatibilità"),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "Questo esempio deve attivare la competenza",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "Esempio di richiesta utente",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage(
      "Risultato attivazione",
    ),
    "skillDetails": MessageLookupByLibrary.simpleMessage(
      "Dettagli della competenza",
    ),
    "skillDigest": MessageLookupByLibrary.simpleMessage("Digest del contenuto"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("Disattivata"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("Attivata"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("File"),
    "skillImportFailed": m37,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "Competenza importata",
    ),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("Competenze"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "Installa istruzioni riutilizzabili e associale ai bot.",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "Questa versione non esegue script o comandi delle competenze.",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("Editore"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "File di riferimento disponibili",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md viene caricato solo come istruzione controllata per il prompt; script, comandi e strumenti esterni restano disabilitati.",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "Sandbox per script desktop disponibile",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "Gli script restano disattivati finché non li approvi. Ogni chiamata richiede comunque l’approvazione.",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "Script delle abilità non disponibili",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "Questa piattaforma non offre l’isolamento richiesto. Istruzioni e risorse restano disponibili.",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "Impostazione degli script aggiornata.",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "Gli script sono installati, ma la loro esecuzione è disabilitata.",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage(
      "Script attivati",
    ),
    "skillSignature": MessageLookupByLibrary.simpleMessage("Firma"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage(
      "Firma non valida",
    ),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "Editore sconosciuto",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage(
      "Non firmato",
    ),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "Firma verificata",
    ),
    "skillSource": MessageLookupByLibrary.simpleMessage("Origine"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("Automatico"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Aggiornamento disponibile",
    ),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("Manuale"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("Notifica"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("Bloccato"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage(
      "Criterio di aggiornamento",
    ),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("Utente"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage(
      "Note di convalida",
    ),
    "skillVersion": MessageLookupByLibrary.simpleMessage("Versione"),
    "sourceCode": MessageLookupByLibrary.simpleMessage("Codice sorgente"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Invia un messaggio nel campo di testo sotto per iniziare a chattare",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Inizia a chattare"),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "Avvio non riuscito. Riprova.",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage("Avvio…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("Attivato"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("Allegato"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage(
      "In attesa di approvazione",
    ),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Annullato"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Completato"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("Negato"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage(
      "Chiamata duplicata",
    ),
    "statusFailed": MessageLookupByLibrary.simpleMessage("Non riuscito"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("Generato"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("In corso"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("Registrato"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("Richiesto"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("In esecuzione"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("Ignorato"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("Tempo scaduto"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("Sconosciuto"),
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
      "Informazioni strutturate sul processo",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("Invia feedback"),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage(
      "Messaggi riassunti",
    ),
    "supported": MessageLookupByLibrary.simpleMessage("Supportato"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("Supporta MCP"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage("Supporta Skills"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("Prompt di sistema:"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("Verifica"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage(
      "Verifica descrizione",
    ),
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
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage(
      "Elaborazione completata",
    ),
    "thinkingCompletedWithDuration": m38,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("Elaborazione…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("Utilizzo dei token"),
    "tokens": MessageLookupByLibrary.simpleMessage("tokens"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage(
      "Consentito una volta",
    ),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("Negato"),
    "toolCalls": MessageLookupByLibrary.simpleMessage(
      "Chiamate agli strumenti",
    ),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("Distruttivo"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("Sola lettura"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("Scrittura"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("Integrato"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage(
      "Script Skill",
    ),
    "totalTokens": MessageLookupByLibrary.simpleMessage("Token totali"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Prova un’altra ricerca o crea un nuovo elemento.",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("Digitando..."),
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
      "Bot non disponibile",
    ),
    "uninstall": MessageLookupByLibrary.simpleMessage("Disinstalla"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage(
      "Disinstalla competenza",
    ),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("Rimuovi"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "Formato immagine non supportato. Scegli un’immagine JPEG, PNG, GIF, BMP o WebP.",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("Carica file"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("Carica immagine"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("Accordo utente"),
    "version": MessageLookupByLibrary.simpleMessage("Versione 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Impossibile caricare il video",
    ),
    "videoPlaybackError": m39,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("Vedi riepilogo"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
