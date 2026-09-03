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

  static String m6(error) => "Could not clear chat history: ${error}";

  static String m7(botName) =>
      "¿Estás seguro de que quieres borrar todo el historial de chat con \"${botName}\"? Esta acción no se puede deshacer.";

  static String m8(botName) =>
      "Eliminar el bot también eliminará todos los chats asociados. ¿Estás seguro de que quieres eliminar ${botName}?";

  static String m9(botName) =>
      "Eliminar el chat borrará todo el historial de conversación. ¿Estás seguro de que quieres eliminar el chat con ${botName}?";

  static String m10(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m11(name) =>
      "¿Desinstalar ${name}? También se eliminarán las vinculaciones con bots.";

  static String m12(year) => "© ${year} Equipo Stars";

  static String m13(error) => "Could not create the chat: ${error}";

  static String m14(error) => "Could not delete the chat: ${error}";

  static String m15(milliseconds) => "${milliseconds} ms";

  static String m16(seconds) => "${seconds} s";

  static String m17(name) =>
      "Permitir que ${name} registre sus scripts declarados como herramientas. Cada llamada seguirá requiriendo aprobación.";

  static String m18(count) => "${count} files";

  static String m19(error) => "Generate image failed: ${error}";

  static String m20(error) => "Could not generate music: ${error}";

  static String m21(error) => "Could not generate speech: ${error}";

  static String m22(error) => "Could not generate video: ${error}";

  static String m23(count) => "${count} items";

  static String m24(language) => "Idioma cambiado a ${language}";

  static String m25(error) => "MCP connection failed: ${error}";

  static String m26(count) => "${count} configured (values hidden)";

  static String m27(minutes) => "hace ${minutes} minutos";

  static String m28(count) => "Se han recuperado ${count} modelos con éxito";

  static String m29(count) => "${count} ejecuciones de comandos";

  static String m30(duration) => "Duración ${duration}";

  static String m31(count) => "${count} cambios de archivos";

  static String m32(count) => "${count} llamadas a herramientas";

  static String m33(error) => "Error al obtener respuesta: ${error}";

  static String m34(error) => "Could not save image: ${error}";

  static String m35(error) => "Could not share image: ${error}";

  static String m36(error) => "No se pudo importar la habilidad: ${error}";

  static String m37(duration) => "Pensamiento completado · ${duration}";

  static String m38(error) => "Error de reproducción de vídeo: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("Acerca de"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Acerca de Stars"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("Añadir bot"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("Añadir habilidad"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajustar tamaño de fuente de la aplicación",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajustar tamaño de fuente",
    ),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Se añadieron todas las habilidades instaladas.",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("Siempre activa"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Inserta esta habilidad en cada solicitud de texto.",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("Siempre activa"),
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
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "Prompt del sistema",
    ),
    "applicationInjectedPromptDescription":
        MessageLookupByLibrary.simpleMessage(
          "Stars lo administra. Al activarlo, el contenido siguiente se añade a las solicitudes del modelo de la conversación; al desactivarlo, se omite. El contexto de ejecución necesario no se ve afectado. El contenido no se puede editar.",
        ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("Automática"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Permite que los modelos compatibles activen esta habilidad según su descripción.",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "Este proveedor solo admite habilidades manuales.",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage(
      "Memoria automática",
    ),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "Los resúmenes automáticos pueden ser inexactos. El mensaje actual siempre tiene prioridad.",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage(
      "Volver al uso diario",
    ),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Información básica",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Avatar del bot"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "Activa herramientas MCP para este agente. Las llamadas requieren confirmación de forma predeterminada.",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("Nombre del bot"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "La búsqueda filtra la lista por nombre del bot.",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("Habilidades"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "Elige las instrucciones reutilizables disponibles para este bot.",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "browseConversationDirectory": MessageLookupByLibrary.simpleMessage(
      "Browse conversation data",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("Cambiar avatar"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("Guardado"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage(
      "Estado de ejecución del chat",
    ),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Historial de chat borrado",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Chats"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("Borrar"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage(
      "Borrar memoria automática",
    ),
    "clearChat": MessageLookupByLibrary.simpleMessage("Limpiar chat"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Borrar historial de chat",
    ),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage(
      "Borrar habilidades fijadas",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "Selecciona un día para ver el uso por hora",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Haz clic en + en la esquina superior derecha para añadir un bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Haz clic en Nuevo chat para crear una conversación",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage(
      "Ejecuciones de comandos",
    ),
    "compactNow": MessageLookupByLibrary.simpleMessage("Compactar ahora"),
    "compactingContext": MessageLookupByLibrary.simpleMessage(
      "Organizando el contexto…",
    ),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("Error"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage(
      "Estado de compactación",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage(
      "Confirmar eliminación",
    ),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Información de contacto (opcional)",
    ),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage(
      "Contexto y memoria",
    ),
    "contextCompacted": MessageLookupByLibrary.simpleMessage(
      "Contexto compactado",
    ),
    "contextWindow": MessageLookupByLibrary.simpleMessage(
      "Ventana de contexto",
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
      "Resumen de la conversación",
    ),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage(
      "Distribución de tokens por conversación",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("Copiar clave de API"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m12,
    "createChatFailed": m13,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Fecha de creación"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Proveedor personalizado...",
    ),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage("Uso diario"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Modo oscuro"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "Esta base de datos se creó con una versión más reciente de Stars. Actualiza la aplicación antes de abrirla.",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "La comprobación de integridad de la base de datos falló y no se pudo recuperar desde la copia de seguridad de esta versión.",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage(
      "Razonamiento profundo",
    ),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Eres un asistente de IA útil. Por favor, responde en español.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Eliminar bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Eliminar chat"),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "Acerca de e información legal",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "Apariencia e idioma",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Cambia tu avatar y nombre para mostrar.",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("General"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage(
      "Ayuda y soporte",
    ),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage(
      "Información personal",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "Los cambios se aplican de inmediato y se guardan localmente.",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Gestiona tu perfil, apariencia, idioma y soporte de la aplicación.",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Detalles"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Desactivar sin confirmación para todas",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Desactivar todas las herramientas",
    ),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Desactivar scripts",
    ),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("Editar"),
    "editBot": MessageLookupByLibrary.simpleMessage("Editar bot"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("Editar memoria"),
    "editName": MessageLookupByLibrary.simpleMessage("Editar nombre"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Error al obtener respuesta: el servidor devolvió una respuesta vacía",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Activar sin confirmación para todas",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Activar todas las herramientas",
    ),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Activar scripts",
    ),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "¿Activar scripts aislados?",
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
    "enterDisplayName": MessageLookupByLibrary.simpleMessage(
      "Introduce un nombre para mostrar",
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
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage(
      "Uso estimado",
    ),
    "executionStatus": MessageLookupByLibrary.simpleMessage(
      "Estado de ejecución",
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
    "feedbackInformation": MessageLookupByLibrary.simpleMessage(
      "Información sobre comentarios",
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
    "fileStatus": MessageLookupByLibrary.simpleMessage("Estado de archivos"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("Música"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("Voz"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("Vídeo"),
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
    "forgetMemory": MessageLookupByLibrary.simpleMessage("Olvidar"),
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
      "Error de generación",
    ),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "Error de generación · Se conserva la respuesta parcial",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage(
      "Ayuda y Comentarios",
    ),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("Ocultar clave de API"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("Inicio"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage("Uso por hora"),
    "htmlPreview": MessageLookupByLibrary.simpleMessage("Vista previa HTML"),
    "idle": MessageLookupByLibrary.simpleMessage("Inactivo"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage(
      "Importar carpeta de habilidades",
    ),
    "importSkillZip": MessageLookupByLibrary.simpleMessage(
      "Importar ZIP de habilidades",
    ),
    "importingSkill": MessageLookupByLibrary.simpleMessage(
      "Importando habilidad…",
    ),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("Tokens de entrada"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage(
      "Instalar actualización",
    ),
    "invalidSummary": MessageLookupByLibrary.simpleMessage(
      "El resumen generado no superó la validación",
    ),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("Ahora mismo"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Ajustes de idioma",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Modo claro"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("Administrar memoria"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("Por mensaje"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Selecciona la habilidad en el campo de mensaje cuando la necesites.",
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
      "Sin confirmación",
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
    "mcpServers": MessageLookupByLibrary.simpleMessage("Servidores MCP"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Conecta servidores MCP y descubre sus catálogos de herramientas. Configura las herramientas después de crear un agente.",
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
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("Artefacto"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "La memoria cambió; inténtalo de nuevo",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("Corrección"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("Decisión"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("Hecho"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("Preferencia"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("Pregunta abierta"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("Tarea"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage(
      "Escribe un mensaje...",
    ),
    "messageSkills": MessageLookupByLibrary.simpleMessage("Habilidades"),
    "minutesAgo": m27,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("Audio"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("Archivo"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("Imagen"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("Multimodal"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("Música"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("Tiempo real"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("Voz"),
    "modalityText": MessageLookupByLibrary.simpleMessage("Texto"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("Vídeo"),
    "model": MessageLookupByLibrary.simpleMessage("Modelo"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "Configuración del modelo",
    ),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage(
      "Tamaño del contexto del modelo",
    ),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("Entrada"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("Salida"),
    "modelsRetrievedSuccess": m28,
    "modificationTime": MessageLookupByLibrary.simpleMessage(
      "Fecha de modificación",
    ),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("Nombre"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Nombre actualizado"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("Nuevo chat"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "No hay herramientas MCP conectadas disponibles.",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "No se añadieron habilidades",
    ),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "Añade las habilidades instaladas que necesite este bot.",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "No hay bots disponibles",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("Aún no hay chats"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "No se devolvió contenido",
    ),
    "noConversationFilesFound": MessageLookupByLibrary.simpleMessage(
      "No matching files or folders.",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "Todavía no hay un resumen de la conversación disponible.",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "No se encontraron bots coincidentes",
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
      "No se encontraron habilidades coincidentes",
    ),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "No se han recuperado modelos",
    ),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage(
      "No hay habilidades instaladas",
    ),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "Importa una carpeta de Agent Skills o un ZIP que contenga SKILL.md.",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "No hay uso de tokens registrado",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("No compatible"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "No hay suficiente contexto anterior para compactar",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openLink": MessageLookupByLibrary.simpleMessage("Abrir enlace"),
    "openWithSystem": MessageLookupByLibrary.simpleMessage(
      "Open with system app",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("Tokens de salida"),
    "partialResponse": MessageLookupByLibrary.simpleMessage(
      "Respuesta parcial",
    ),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("Pausar audio"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage(
      "Pausar generación",
    ),
    "pinMemory": MessageLookupByLibrary.simpleMessage("Fijar"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "Fijar selección en esta conversación",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("Fijada"),
    "playAudio": MessageLookupByLibrary.simpleMessage("Reproducir audio"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Por favor, introduzca primero la clave API",
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
    "preview": MessageLookupByLibrary.simpleMessage("Vista previa"),
    "previewText": MessageLookupByLibrary.simpleMessage(
      "Vista previa del texto",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Política de privacidad",
    ),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "Información del proceso",
    ),
    "processToolCount": m32,
    "profile": MessageLookupByLibrary.simpleMessage("Perfil"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Proporcione sus sugerencias y comentarios",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Proveedor"),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "Información del proveedor",
    ),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage(
      "Razonamiento completado",
    ),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage(
      "Razonamiento en curso",
    ),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage(
      "Razonamiento interrumpido",
    ),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("Reconstruir"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("Actualizar"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Actualizar catálogos",
    ),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Actualizando catálogos…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("Quitar habilidad"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage(
      "Respuesta cancelada",
    ),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "Detenido · Se conserva la respuesta parcial",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage(
      "Restablecer valores predeterminados",
    ),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("Restaurar"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage(
      "Turnos recientes conservados",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage(
      "Ejecutar prueba",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Guardar"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Guardar cambios"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("Guardando..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("Buscar bots"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchConversationFiles": MessageLookupByLibrary.simpleMessage(
      "Search files and folders",
    ),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage(
      "Buscar en la memoria",
    ),
    "searchSkills": MessageLookupByLibrary.simpleMessage("Buscar habilidades"),
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
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("Mostrar clave de API"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Mostrar detalles de ejecución en los mensajes de la conversación.",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage(
      "Recursos disponibles",
    ),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage(
      "Compatibilidad",
    ),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "Este ejemplo debe activar la habilidad",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "Solicitud de usuario de ejemplo",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage(
      "Resultado de activación",
    ),
    "skillDetails": MessageLookupByLibrary.simpleMessage(
      "Detalles de la habilidad",
    ),
    "skillDigest": MessageLookupByLibrary.simpleMessage("Huella del contenido"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("Desactivada"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("Activada"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("Archivos"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "Habilidad importada",
    ),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("Habilidades"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "Instala instrucciones reutilizables y vincúlalas a tus bots.",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "Esta versión no ejecuta scripts ni comandos de las habilidades.",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("Editor"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "Archivos de referencia disponibles",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md se carga únicamente como una instrucción controlada; los scripts, comandos y herramientas externas permanecen desactivados.",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "Entorno aislado de scripts disponible",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "Los scripts permanecen desactivados hasta que los apruebes. Cada ejecución sigue requiriendo aprobación.",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "Scripts de habilidades no disponibles",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "Esta plataforma no ofrece el aislamiento necesario. Las instrucciones y recursos siguen disponibles.",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "Configuración de scripts actualizada.",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "Los scripts están instalados, pero su ejecución está desactivada.",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage(
      "Scripts activados",
    ),
    "skillSignature": MessageLookupByLibrary.simpleMessage("Firma"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage(
      "Firma no válida",
    ),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "Editor desconocido",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage("Sin firma"),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "Firma verificada",
    ),
    "skillSource": MessageLookupByLibrary.simpleMessage("Origen"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("Automática"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Actualización disponible",
    ),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("Manual"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("Notificar"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("Fijada"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage(
      "Política de actualización",
    ),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("Usuario"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage(
      "Notas de validación",
    ),
    "skillVersion": MessageLookupByLibrary.simpleMessage("Versión"),
    "sourceCode": MessageLookupByLibrary.simpleMessage("Código fuente"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Envía un mensaje en el campo de texto de abajo para comenzar a chatear",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Empieza a chatear"),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo iniciar. Inténtalo de nuevo.",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage("Iniciando…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("Activado"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("Adjuntado"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage(
      "Esperando aprobación",
    ),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Cancelado"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Completado"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("Denegado"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage(
      "Llamada duplicada",
    ),
    "statusFailed": MessageLookupByLibrary.simpleMessage("Fallido"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("Generado"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("En curso"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("Registrado"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("Solicitado"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("Ejecutándose"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("Omitido"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("Tiempo agotado"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("Desconocido"),
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
      "Información estructurada del proceso",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage(
      "Enviar Comentarios",
    ),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage(
      "Mensajes resumidos",
    ),
    "supported": MessageLookupByLibrary.simpleMessage("Compatible"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("Admite MCP"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage("Admite Skills"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("Prompt del sistema"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("Probar"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage(
      "Probar descripción",
    ),
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
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage(
      "Pensamiento completado",
    ),
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("Pensando…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("Uso de tokens"),
    "tokens": MessageLookupByLibrary.simpleMessage("tokens"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage(
      "Permitido una vez",
    ),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("Denegado"),
    "toolCalls": MessageLookupByLibrary.simpleMessage(
      "Llamadas a herramientas",
    ),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("Destructivo"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("Solo lectura"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("Escritura"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("Integrado"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage(
      "Script de habilidad",
    ),
    "totalTokens": MessageLookupByLibrary.simpleMessage("Tokens totales"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Prueba otra búsqueda o crea un elemento nuevo.",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("Escribiendo..."),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage(
      "Unable to load bots",
    ),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage(
      "Unable to load chats",
    ),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage(
      "Unable to load messages",
    ),
    "unavailableBot": MessageLookupByLibrary.simpleMessage("Bot no disponible"),
    "uninstall": MessageLookupByLibrary.simpleMessage("Desinstalar"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage(
      "Desinstalar habilidad",
    ),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("Desfijar"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "Formato de imagen no compatible. Elige una imagen JPEG, PNG, GIF, BMP o WebP.",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("Subir archivo"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("Subir imagen"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("Acuerdo de usuario"),
    "version": MessageLookupByLibrary.simpleMessage("Versión 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo cargar el vídeo",
    ),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("Ver resumen"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
