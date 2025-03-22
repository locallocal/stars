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

  static String m1(botName) => "Bot ${botName} a été mis à jour";

  static String m2(botName) => "Discussion avec ${botName} supprimée";

  static String m3(botName) =>
      "La suppression du bot supprimera également toutes les discussions associées. Êtes-vous sûr de vouloir supprimer ${botName}?";

  static String m4(botName) =>
      "La suppression de la discussion effacera tout l\'historique des conversations. Êtes-vous sûr de vouloir supprimer la discussion avec ${botName}?";

  static String m5(language) => "Langue définie sur ${language}";

  static String m6(minutes) => "il y a ${minutes} minutes";

  static String m7(error) => "Échec de récupération de la réponse: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("À propos"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("À propos de Bubble"),
    "addBot": MessageLookupByLibrary.simpleMessage("Ajouter un Bot"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajuster la taille de police de l\'application",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajuster la Taille de Police",
    ),
    "apiAddress": MessageLookupByLibrary.simpleMessage("Adresse API:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("Clé API"),
    "apiType": MessageLookupByLibrary.simpleMessage("Type d\'API:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "Une application de chat IA simple mais puissante qui vous permet de discuter avec l\'IA n\'importe quand, n\'importe où.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Bubble"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Bubble - Assistant de Chat IA",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Avatar du Bot"),
    "botName": MessageLookupByLibrary.simpleMessage("Nom du Bot"),
    "botUpdated": m1,
    "cancel": MessageLookupByLibrary.simpleMessage("Annuler"),
    "chatDeleted": m2,
    "chats": MessageLookupByLibrary.simpleMessage("Discussions"),
    "clearChat": MessageLookupByLibrary.simpleMessage("Effacer la Discussion"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Effacer l\'historique de discussion",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Cliquez sur + en haut à droite pour ajouter un bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Cliquez sur + en haut à droite pour commencer une discussion",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirmer"),
    "confirmDeleteBot": m3,
    "confirmDeleteChat": m4,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Informations de contact (facultatif)",
    ),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 Équipe Bubble"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Fournisseur personnalisé...",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Mode Sombre"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Vous êtes un assistant IA utile. Veuillez répondre en français.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Supprimer"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Supprimer le bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage(
      "Supprimer la Discussion",
    ),
    "editBot": MessageLookupByLibrary.simpleMessage("Modifier le Bot"),
    "editName": MessageLookupByLibrary.simpleMessage("Modifier le Nom"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Échec de récupération de la réponse: le serveur a renvoyé une réponse vide",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "Entrez l\'adresse API...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("Entrez la clé API..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage(
      "Entrez le nom du bot...",
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
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Veuillez saisir le contenu des commentaires",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Veuillez nous faire part de vos réflexions, problèmes ou suggestions pour nous aider à améliorer l\'application",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Entrez vos commentaires ici...",
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
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage(
      "Aide et Commentaires",
    ),
    "home": MessageLookupByLibrary.simpleMessage("Accueil"),
    "justNow": MessageLookupByLibrary.simpleMessage("À l\'instant"),
    "languageChanged": m5,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Paramètres de Langue",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Mode Clair"),
    "messageHint": MessageLookupByLibrary.simpleMessage("Tapez un message..."),
    "minutesAgo": m6,
    "model": MessageLookupByLibrary.simpleMessage("Modèle"),
    "name": MessageLookupByLibrary.simpleMessage("Nom"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Nom mis à jour"),
    "newChat": MessageLookupByLibrary.simpleMessage("Nouvelle Discussion"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "Aucun bot disponible",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage(
      "Pas encore de discussions",
    ),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Veuillez d\'abord saisir la clé API",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage(
      "Aperçu de l\'effet du texte",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Politique de Confidentialité",
    ),
    "profile": MessageLookupByLibrary.simpleMessage("Profil"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Fournissez vos suggestions et commentaires",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Fournisseur"),
    "responseError": m7,
    "save": MessageLookupByLibrary.simpleMessage("Enregistrer"),
    "saveChanges": MessageLookupByLibrary.simpleMessage(
      "Enregistrer les modifications",
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
    "startChatting": MessageLookupByLibrary.simpleMessage(
      "Commencez à discuter",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage(
      "Soumettre les Commentaires",
    ),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("Invite Système"),
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
    "typing": MessageLookupByLibrary.simpleMessage("En train d\'écrire..."),
    "userAgreement": MessageLookupByLibrary.simpleMessage("Accord Utilisateur"),
    "version": MessageLookupByLibrary.simpleMessage("Version 1.0.0"),
  };
}
