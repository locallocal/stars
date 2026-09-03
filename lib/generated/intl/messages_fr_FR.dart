// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr_FR locale. All the
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
  String get localeName => 'fr_FR';

  static String m0(name) => "Bot \"${name}\" a été ajouté";

  static String m1(botName) => "\"${botName}\" a été supprimé";

  static String m2(botName) =>
      "Bonjour ! Je suis ${botName}, un assistant IA. N\'hésitez pas à me poser des questions, je ferai de mon mieux pour vous aider.";

  static String m3(botName) => "${botName} est en train d\'écrire...";

  static String m4(botName) => "Bot ${botName} a été mis à jour";

  static String m5(botName) => "Discussion avec ${botName} supprimée";

  static String m6(error) => "Could not clear chat history: ${error}";

  static String m7(botName) =>
      "Êtes-vous sûr de vouloir effacer tout l\'historique de discussion avec \"${botName}\"? Cette action ne peut pas être annulée.";

  static String m8(botName) =>
      "La suppression du bot supprimera également toutes les discussions associées. Êtes-vous sûr de vouloir supprimer ${botName}?";

  static String m9(botName) =>
      "La suppression de la discussion effacera tout l\'historique des conversations. Êtes-vous sûr de vouloir supprimer la discussion avec ${botName}?";

  static String m10(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m11(name) =>
      "Désinstaller ${name} ? Les associations aux Bots seront également supprimées.";

  static String m12(year) => "© ${year} Équipe Stars";

  static String m13(error) => "Could not create the chat: ${error}";

  static String m14(error) => "Could not delete the chat: ${error}";

  static String m15(milliseconds) => "${milliseconds} ms";

  static String m16(seconds) => "${seconds} s";

  static String m17(name) =>
      "Autoriser ${name} à enregistrer ses scripts déclarés comme outils. Chaque appel nécessitera toujours une approbation.";

  static String m18(count) => "${count} files";

  static String m19(error) => "Generate image failed: ${error}";

  static String m20(error) => "Could not generate music: ${error}";

  static String m21(error) => "Could not generate speech: ${error}";

  static String m22(error) => "Could not generate video: ${error}";

  static String m23(count) => "${count} items";

  static String m24(language) => "Langue définie sur ${language}";

  static String m25(error) => "MCP connection failed: ${error}";

  static String m26(count) => "${count} configured (values hidden)";

  static String m27(minutes) => "il y a ${minutes} minutes";

  static String m28(count) => "${count} modèles récupérés avec succès";

  static String m29(count) => "${count} exécutions de commandes";

  static String m30(duration) => "Durée ${duration}";

  static String m31(count) => "${count} modifications de fichiers";

  static String m32(count) => "${count} appels d’outil";

  static String m33(error) => "Échec de récupération de la réponse: ${error}";

  static String m34(error) => "Could not save image: ${error}";

  static String m35(error) => "Could not share image: ${error}";

  static String m36(error) => "Impossible d’importer la compétence : ${error}";

  static String m37(duration) => "Réflexion terminée · ${duration}";

  static String m38(error) => "Erreur de lecture vidéo : ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("À propos"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("À propos de Stars"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("Ajouter un Bot"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("Ajouter une compétence"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajuster la taille de police de l\'application",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajuster la Taille de Police",
    ),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Toutes les compétences installées ont été ajoutées.",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("Toujours active"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Insère cette compétence dans chaque requête textuelle.",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("Toujours active"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("Adresse API:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("Clé API"),
    "apiType": MessageLookupByLibrary.simpleMessage("Type d\'API:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "Une application de chat IA simple mais puissante qui vous permet de discuter avec l\'IA n\'importe quand, n\'importe où.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Stars - Assistant de Chat IA",
    ),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "Prompt système",
    ),
    "applicationInjectedPromptDescription":
        MessageLookupByLibrary.simpleMessage(
          "Géré par Stars. Lorsqu’il est activé, le contenu ci-dessous est ajouté aux requêtes du modèle de la conversation ; lorsqu’il est désactivé, il est omis. Le contexte d’exécution requis reste inchangé. Le contenu n’est pas modifiable.",
        ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("Automatique"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Permet aux modèles compatibles d’activer cette compétence à partir de sa description.",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "Ce fournisseur ne prend en charge que les compétences manuelles.",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage(
      "Mémoire automatique",
    ),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "Les résumés automatiques peuvent être inexacts. Le message actuel est toujours prioritaire.",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage(
      "Retour à l’utilisation quotidienne",
    ),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Informations générales",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Avatar du Bot"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "Activez les outils MCP pour cet agent. Les appels nécessitent une confirmation par défaut.",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("Nom du Bot"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "La recherche filtre la liste par nom de bot.",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("Compétences"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "Choisissez les instructions réutilisables disponibles pour ce Bot.",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "browseConversationDirectory": MessageLookupByLibrary.simpleMessage(
      "Browse conversation data",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("Modifier l’avatar"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("Enregistré"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage(
      "État d’exécution du chat",
    ),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Historique de discussion effacé",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Discussions"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("Effacer"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage(
      "Effacer la mémoire automatique",
    ),
    "clearChat": MessageLookupByLibrary.simpleMessage("Effacer la Discussion"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Effacer l\'historique de discussion",
    ),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage(
      "Effacer les compétences épinglées",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "Sélectionnez un jour pour afficher l’utilisation horaire",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Cliquez sur + en haut à droite pour ajouter un bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Cliquez sur Nouvelle discussion pour créer une conversation",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage(
      "Exécutions de commandes",
    ),
    "compactNow": MessageLookupByLibrary.simpleMessage("Compresser maintenant"),
    "compactingContext": MessageLookupByLibrary.simpleMessage(
      "Organisation du contexte…",
    ),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("Échec"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage(
      "État de compression",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirmer"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage(
      "Confirmer la suppression",
    ),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Informations de contact (facultatif)",
    ),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage(
      "Contexte et mémoire",
    ),
    "contextCompacted": MessageLookupByLibrary.simpleMessage(
      "Contexte compressé",
    ),
    "contextWindow": MessageLookupByLibrary.simpleMessage(
      "Fenêtre de contexte",
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
      "Résumé de la conversation",
    ),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage(
      "Répartition des jetons par conversation",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("Copier la clé API"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m12,
    "createChatFailed": m13,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Date de création"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Fournisseur personnalisé...",
    ),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage(
      "Utilisation quotidienne",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Mode Sombre"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "Cette base de données a été créée par une version plus récente de Stars. Mettez l’application à jour avant de l’ouvrir.",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "Le contrôle d’intégrité de la base de données a échoué et la restauration depuis la sauvegarde de cette version n’a pas abouti.",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage(
      "Réflexion approfondie",
    ),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Vous êtes un assistant IA utile. Veuillez répondre en français.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Supprimer"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Supprimer le bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage(
      "Supprimer la Discussion",
    ),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "À propos et mentions légales",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "Apparence et langue",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Modifiez votre avatar et votre nom d’affichage.",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("Général"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage(
      "Aide et assistance",
    ),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage(
      "Informations personnelles",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "Les modifications prennent effet immédiatement et sont enregistrées localement.",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Gérez votre profil, l’apparence, la langue et l’assistance de l’application.",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Détails"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Désactiver sans confirmation pour tous",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Désactiver tous les outils",
    ),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Désactiver les scripts",
    ),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("Modifier"),
    "editBot": MessageLookupByLibrary.simpleMessage("Modifier le Bot"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("Modifier la mémoire"),
    "editName": MessageLookupByLibrary.simpleMessage("Modifier le Nom"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Échec de récupération de la réponse: le serveur a renvoyé une réponse vide",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Activer sans confirmation pour tous",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Activer tous les outils",
    ),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Activer les scripts",
    ),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "Activer les scripts isolés ?",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "Entrez l\'adresse API...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("Entrez la clé API..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage(
      "Entrez le nom du bot...",
    ),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage(
      "Saisissez un nom d’affichage",
    ),
    "enterNewName": MessageLookupByLibrary.simpleMessage(
      "Veuillez entrer un nouveau nom",
    ),
    "enterProviderName": MessageLookupByLibrary.simpleMessage(
      "Entrez le nom du fournisseur...",
    ),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Entrez l\'invite système...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "Erreur lors du chargement du contenu, veuillez réessayer plus tard.",
    ),
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage(
      "Utilisation estimée",
    ),
    "executionStatus": MessageLookupByLibrary.simpleMessage("État d’exécution"),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Veuillez saisir le contenu des commentaires",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Veuillez nous faire part de vos réflexions, problèmes ou suggestions pour nous aider à améliorer l\'application",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Entrez vos commentaires ici...",
    ),
    "feedbackInformation": MessageLookupByLibrary.simpleMessage(
      "Informations sur les commentaires",
    ),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "Échec de l\'envoi, veuillez réessayer plus tard",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "Merci pour vos commentaires !",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage(
      "Récupérer la liste des modèles",
    ),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "Veuillez d\'abord récupérer la liste des modèles",
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
    "fileStatus": MessageLookupByLibrary.simpleMessage("État des fichiers"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("Musique"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("Voix"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("Vidéo"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "Veuillez remplir le nom du bot, l\'adresse API et la clé API",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Suivre le Système"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage(
      "Taille de Police",
    ),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "Taille de police mise à jour",
    ),
    "forgetMemory": MessageLookupByLibrary.simpleMessage("Oublier"),
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
      "Échec de la génération",
    ),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "Échec de la génération · Réponse partielle conservée",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage(
      "Aide et Commentaires",
    ),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("Masquer la clé API"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("Accueil"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage(
      "Utilisation horaire",
    ),
    "htmlPreview": MessageLookupByLibrary.simpleMessage("Aperçu HTML"),
    "idle": MessageLookupByLibrary.simpleMessage("Inactif"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage(
      "Importer un dossier de compétences",
    ),
    "importSkillZip": MessageLookupByLibrary.simpleMessage(
      "Importer un ZIP de compétences",
    ),
    "importingSkill": MessageLookupByLibrary.simpleMessage(
      "Importation de la compétence…",
    ),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("Jetons d’entrée"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage(
      "Installer la mise à jour",
    ),
    "invalidSummary": MessageLookupByLibrary.simpleMessage(
      "Le résumé généré n’a pas passé la validation",
    ),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("À l\'instant"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Paramètres de Langue",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Mode Clair"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("Gérer la mémoire"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("Par message"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Si nécessaire, sélectionnez la compétence dans la zone de message.",
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
      "Sans confirmation",
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
    "mcpServers": MessageLookupByLibrary.simpleMessage("Serveurs MCP"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Connectez des serveurs MCP et découvrez leurs catalogues d’outils. Configurez les outils après avoir créé un agent.",
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
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("Artefact"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "La mémoire a changé ; réessayez",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("Correction"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("Décision"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("Fait"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("Préférence"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("Question ouverte"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("Tâche"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage("Tapez un message..."),
    "messageSkills": MessageLookupByLibrary.simpleMessage("Compétences"),
    "minutesAgo": m27,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("Audio"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("Fichier"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("Image"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("Multimodal"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("Musique"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("Temps réel"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("Parole"),
    "modalityText": MessageLookupByLibrary.simpleMessage("Texte"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("Vidéo"),
    "model": MessageLookupByLibrary.simpleMessage("Modèle"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "Configuration du modèle",
    ),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage(
      "Taille du contexte du modèle",
    ),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("Entrée"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("Sortie"),
    "modelsRetrievedSuccess": m28,
    "modificationTime": MessageLookupByLibrary.simpleMessage(
      "Date de modification",
    ),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("Nom"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Nom mis à jour"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("Nouvelle Discussion"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "Aucun outil MCP connecté n’est disponible.",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Aucune compétence ajoutée",
    ),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "Ajoutez les compétences installées dont ce Bot a besoin.",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "Aucun bot disponible",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage(
      "Pas encore de discussions",
    ),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "Aucun contenu renvoyé",
    ),
    "noConversationFilesFound": MessageLookupByLibrary.simpleMessage(
      "No matching files or folders.",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "Aucun résumé de la conversation n’est encore disponible.",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "Aucun bot correspondant trouvé",
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
      "Aucune compétence correspondante trouvée",
    ),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "Aucun modèle récupéré",
    ),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage(
      "Aucune compétence installée",
    ),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "Importez un dossier Agent Skills ou un fichier ZIP contenant SKILL.md.",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "Aucune utilisation de jetons enregistrée",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("Non pris en charge"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "Pas assez d’ancien contexte à compresser",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openLink": MessageLookupByLibrary.simpleMessage("Ouvrir le lien"),
    "openWithSystem": MessageLookupByLibrary.simpleMessage(
      "Open with system app",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("Jetons de sortie"),
    "partialResponse": MessageLookupByLibrary.simpleMessage(
      "Réponse partielle",
    ),
    "pauseAudio": MessageLookupByLibrary.simpleMessage(
      "Mettre l’audio en pause",
    ),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage(
      "Mettre en pause la génération",
    ),
    "pinMemory": MessageLookupByLibrary.simpleMessage("Épingler"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "Épingler la sélection pour cette conversation",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("Épinglée"),
    "playAudio": MessageLookupByLibrary.simpleMessage("Lire l’audio"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Veuillez d\'abord saisir la clé API",
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
    "preview": MessageLookupByLibrary.simpleMessage("Aperçu"),
    "previewText": MessageLookupByLibrary.simpleMessage(
      "Aperçu de l\'effet du texte",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Politique de Confidentialité",
    ),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "Informations sur le processus",
    ),
    "processToolCount": m32,
    "profile": MessageLookupByLibrary.simpleMessage("Profil"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Fournissez vos suggestions et commentaires",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Fournisseur"),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "Informations du fournisseur",
    ),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage(
      "Raisonnement terminé",
    ),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage(
      "Raisonnement en cours",
    ),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage(
      "Raisonnement interrompu",
    ),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("Reconstruire"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("Actualiser"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Actualiser les catalogues",
    ),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Actualisation des catalogues…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage(
      "Retirer la compétence",
    ),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("Réponse annulée"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "Arrêté · Réponse partielle conservée",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage(
      "Rétablir les paramètres par défaut",
    ),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("Restaurer"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage(
      "Tours récents conservés",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage(
      "Lancer le test",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Enregistrer"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage(
      "Enregistrer les modifications",
    ),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("Enregistrement..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("Rechercher des bots"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchConversationFiles": MessageLookupByLibrary.simpleMessage(
      "Search files and folders",
    ),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage(
      "Rechercher dans la mémoire",
    ),
    "searchSkills": MessageLookupByLibrary.simpleMessage(
      "Rechercher des compétences",
    ),
    "selectBot": MessageLookupByLibrary.simpleMessage("Sélectionner un Bot"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage(
      "Sélectionner la Langue",
    ),
    "selectModel": MessageLookupByLibrary.simpleMessage(
      "Sélectionner le modèle:",
    ),
    "selectProvider": MessageLookupByLibrary.simpleMessage(
      "Sélectionner le fournisseur:",
    ),
    "selectTheme": MessageLookupByLibrary.simpleMessage(
      "Sélectionner le Thème",
    ),
    "send": MessageLookupByLibrary.simpleMessage("Envoyer"),
    "settings": MessageLookupByLibrary.simpleMessage("Paramètres"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("Afficher la clé API"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Afficher les détails d’exécution dans les messages de conversation.",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage(
      "Ressources disponibles",
    ),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage("Compatibilité"),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "Cet exemple doit activer la compétence",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "Exemple de demande utilisateur",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage(
      "Résultat d’activation",
    ),
    "skillDetails": MessageLookupByLibrary.simpleMessage(
      "Détails de la compétence",
    ),
    "skillDigest": MessageLookupByLibrary.simpleMessage("Empreinte du contenu"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("Désactivée"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("Activée"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("Fichiers"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "Compétence importée",
    ),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("Compétences"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "Installez des instructions réutilisables et associez-les à vos Bots.",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "Cette version n’exécute aucun script ni aucune commande provenant des compétences.",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("Éditeur"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "Fichiers de référence disponibles",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md est chargé uniquement comme instruction contrôlée ; les scripts, commandes et outils externes restent désactivés.",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "Bac à sable de scripts disponible",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "Les scripts restent désactivés jusqu’à votre autorisation. Chaque exécution nécessite toujours une approbation.",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "Scripts de compétences indisponibles",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "Cette plateforme ne fournit pas l’isolation requise. Les instructions et ressources restent disponibles.",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "Paramètre des scripts mis à jour.",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "Les scripts sont installés, mais leur exécution est désactivée.",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage(
      "Scripts activés",
    ),
    "skillSignature": MessageLookupByLibrary.simpleMessage("Signature"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage(
      "Signature non valide",
    ),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "Éditeur inconnu",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage("Non signé"),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "Signature vérifiée",
    ),
    "skillSource": MessageLookupByLibrary.simpleMessage("Source"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("Automatique"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Mise à jour disponible",
    ),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("Manuelle"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("Notifier"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("Épinglée"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage(
      "Politique de mise à jour",
    ),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("Utilisateur"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage(
      "Notes de validation",
    ),
    "skillVersion": MessageLookupByLibrary.simpleMessage("Version"),
    "sourceCode": MessageLookupByLibrary.simpleMessage("Code source"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Envoyez un message dans le champ de texte ci-dessous pour commencer à discuter",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage(
      "Commencez à discuter",
    ),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "Échec du démarrage. Veuillez réessayer.",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage("Démarrage…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("Activé"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("Joint"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage(
      "En attente d’approbation",
    ),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Annulé"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Terminé"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("Refusé"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage("Appel en double"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("Échec"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("Généré"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("En cours"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("Enregistré"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("Demandé"),
    "statusRunning": MessageLookupByLibrary.simpleMessage(
      "En cours d’exécution",
    ),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("Ignoré"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("Délai dépassé"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("Inconnu"),
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
      "Informations structurées sur le processus",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage(
      "Soumettre les Commentaires",
    ),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage("Messages résumés"),
    "supported": MessageLookupByLibrary.simpleMessage("Pris en charge"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("Prend en charge MCP"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage(
      "Prend en charge les Skills",
    ),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("Invite Système"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("Tester"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage(
      "Tester la description",
    ),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "Thème défini sur mode sombre",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "Thème défini sur mode clair",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "Thème défini pour suivre le système",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage(
      "Paramètres du Thème",
    ),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage(
      "Réflexion terminée",
    ),
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage(
      "Réflexion en cours…",
    ),
    "tokenUsage": MessageLookupByLibrary.simpleMessage(
      "Utilisation des jetons",
    ),
    "tokens": MessageLookupByLibrary.simpleMessage("jetons"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage(
      "Autorisé une fois",
    ),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("Refusé"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("Appels d’outils"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("Destructif"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("Lecture seule"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("Écriture"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("Intégré"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage(
      "Script de compétence",
    ),
    "totalTokens": MessageLookupByLibrary.simpleMessage("Total des jetons"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Essayez une autre recherche ou créez un nouvel élément.",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("En train d\'écrire..."),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage(
      "Unable to load bots",
    ),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage(
      "Unable to load chats",
    ),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage(
      "Unable to load messages",
    ),
    "unavailableBot": MessageLookupByLibrary.simpleMessage("Bot indisponible"),
    "uninstall": MessageLookupByLibrary.simpleMessage("Désinstaller"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage(
      "Désinstaller la compétence",
    ),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("Désépingler"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "Format d’image non pris en charge. Choisissez une image JPEG, PNG, GIF, BMP ou WebP.",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("Importer un fichier"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("Importer une image"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("Accord Utilisateur"),
    "version": MessageLookupByLibrary.simpleMessage("Version 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Impossible de charger la vidéo",
    ),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("Voir le résumé"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
