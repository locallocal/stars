// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es_ES locale. All the
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
  String get localeName => 'es_ES';

  static String m0(name) => "Bot \"${name}\" ha sido añadido";

  static String m1(botName) => "\"${botName}\" ha sido eliminado";

  static String m2(botName) =>
      "¡Hola! Soy ${botName}, un asistente de IA. Puedes hacerme cualquier pregunta y haré lo posible por ayudarte.";

  static String m3(botName) => "${botName} está escribiendo...";

  static String m4(botName) => "Bot ${botName} ha sido actualizado";

  static String m5(botName) => "Chat con ${botName} eliminado";

  static String m6(botName) =>
      "¿Estás seguro de que quieres borrar todo el historial de chat con \"${botName}\"? Esta acción no se puede deshacer.";

  static String m7(botName) =>
      "Eliminar el bot también eliminará todos los chats asociados. ¿Estás seguro de que quieres eliminar ${botName}?";

  static String m8(botName) =>
      "Eliminar el chat borrará todo el historial de conversación. ¿Estás seguro de que quieres eliminar el chat con ${botName}?";

  static String m9(language) => "Idioma cambiado a ${language}";

  static String m10(minutes) => "hace ${minutes} minutos";

  static String m11(count) => "Se han recuperado ${count} modelos con éxito";

  static String m12(error) => "Error al obtener respuesta: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("Acerca de"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Acerca de Stars"),
    "addBot": MessageLookupByLibrary.simpleMessage("Añadir bot"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajustar tamaño de fuente de la aplicación",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajustar tamaño de fuente",
    ),
    "apiAddress": MessageLookupByLibrary.simpleMessage("Dirección API:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("Clave API"),
    "apiType": MessageLookupByLibrary.simpleMessage("Tipo de API:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "Una aplicación de chat con IA simple pero potente que te permite chatear con inteligencia artificial en cualquier momento y lugar.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Stars - Asistente de chat IA",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Avatar del bot"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botIsTyping": m3,
    "botName": MessageLookupByLibrary.simpleMessage("Nombre del bot"),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
    "chatDeleted": m5,
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Historial de chat borrado",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Chats"),
    "clear": MessageLookupByLibrary.simpleMessage("Borrar"),
    "clearChat": MessageLookupByLibrary.simpleMessage("Limpiar chat"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Borrar historial de chat",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Haz clic en + en la esquina superior derecha para añadir un bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Haz clic en Nuevo chat para crear una conversación",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
    "confirmClearChat": m6,
    "confirmDelete": MessageLookupByLibrary.simpleMessage(
      "Confirmar eliminación",
    ),
    "confirmDeleteBot": m7,
    "confirmDeleteChat": m8,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Información de contacto (opcional)",
    ),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 Equipo Stars"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Proveedor personalizado...",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Modo oscuro"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Eres un asistente de IA útil. Por favor, responde en español.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Eliminar bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Eliminar chat"),
    "editBot": MessageLookupByLibrary.simpleMessage("Editar bot"),
    "editName": MessageLookupByLibrary.simpleMessage("Editar nombre"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Error al obtener respuesta: el servidor devolvió una respuesta vacía",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "Introducir dirección API...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage(
      "Introducir clave API...",
    ),
    "enterBotName": MessageLookupByLibrary.simpleMessage(
      "Introduzca el nombre del bot...",
    ),
    "enterNewName": MessageLookupByLibrary.simpleMessage(
      "Por favor, introduce un nuevo nombre",
    ),
    "enterProviderName": MessageLookupByLibrary.simpleMessage(
      "Introduzca el nombre del proveedor...",
    ),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Introducir prompt del sistema...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "Error al cargar el contenido, por favor intente más tarde.",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Por favor, ingrese el contenido de los comentarios",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Por favor, cuéntenos sus pensamientos, problemas o sugerencias para ayudarnos a mejorar la aplicación",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Ingrese sus comentarios aquí...",
    ),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "Error al enviar, por favor intente más tarde",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "¡Gracias por sus comentarios!",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage(
      "Obtener lista de modelos",
    ),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "Por favor, obtenga primero la lista de modelos",
    ),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "Por favor, complete el nombre del bot, dirección API y clave API",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Sistema"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage(
      "Tamaño de fuente",
    ),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "Tamaño de fuente actualizado",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage(
      "Ayuda y Comentarios",
    ),
    "home": MessageLookupByLibrary.simpleMessage("Inicio"),
    "justNow": MessageLookupByLibrary.simpleMessage("Ahora mismo"),
    "languageChanged": m9,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Ajustes de idioma",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Modo claro"),
    "messageHint": MessageLookupByLibrary.simpleMessage(
      "Escribe un mensaje...",
    ),
    "minutesAgo": m10,
    "model": MessageLookupByLibrary.simpleMessage("Modelo"),
    "modelsRetrievedSuccess": m11,
    "name": MessageLookupByLibrary.simpleMessage("Nombre"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Nombre actualizado"),
    "newChat": MessageLookupByLibrary.simpleMessage("Nuevo chat"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "No hay bots disponibles",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("Aún no hay chats"),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "No se han recuperado modelos",
    ),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage(
      "Pausar generación",
    ),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Por favor, introduzca primero la clave API",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage(
      "Vista previa del texto",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Política de privacidad",
    ),
    "profile": MessageLookupByLibrary.simpleMessage("Perfil"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Proporcione sus sugerencias y comentarios",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Proveedor"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage(
      "Respuesta cancelada",
    ),
    "responseError": m12,
    "save": MessageLookupByLibrary.simpleMessage("Guardar"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Guardar cambios"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Seleccionar bot"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage(
      "Seleccionar idioma",
    ),
    "selectModel": MessageLookupByLibrary.simpleMessage("Seleccionar modelo:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage(
      "Seleccionar proveedor:",
    ),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Seleccionar tema"),
    "send": MessageLookupByLibrary.simpleMessage("Enviar"),
    "settings": MessageLookupByLibrary.simpleMessage("Ajustes"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Envía un mensaje en el campo de texto de abajo para comenzar a chatear",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Empieza a chatear"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage(
      "Enviar Comentarios",
    ),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("Prompt del sistema"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "Tema configurado en modo oscuro",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "Tema configurado en modo claro",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "Tema configurado para seguir el sistema",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage("Ajustes de tema"),
    "typing": MessageLookupByLibrary.simpleMessage("Escribiendo..."),
    "userAgreement": MessageLookupByLibrary.simpleMessage("Acuerdo de usuario"),
    "version": MessageLookupByLibrary.simpleMessage("Versión 1.0.0"),
  };
}
