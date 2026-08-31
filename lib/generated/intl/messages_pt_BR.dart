// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a pt_BR locale. All the
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
  String get localeName => 'pt_BR';

  static String m0(name) => "Bot \"${name}\" foi adicionado";

  static String m1(botName) => "\"${botName}\" foi excluído";

  static String m2(botName) =>
      "Olá! Eu sou ${botName}, um assistente de IA. Você pode me fazer qualquer pergunta e farei o meu melhor para ajudar.";

  static String m3(botName) => "${botName} está digitando...";

  static String m4(botName) => "Bot ${botName} foi atualizado";

  static String m5(botName) => "Conversa com ${botName} excluída";

  static String m6(error) => "Could not clear chat history: ${error}";

  static String m7(botName) =>
      "Tem certeza de que deseja limpar todo o histórico de conversa com \"${botName}\"? Esta ação não pode ser desfeita.";

  static String m8(botName) =>
      "Excluir o bot também removerá todas as conversas associadas. Tem certeza de que deseja excluir ${botName}?";

  static String m9(botName) =>
      "Excluir a conversa apagará todo o histórico de conversas. Tem certeza de que deseja excluir a conversa com ${botName}?";

  static String m10(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m11(name) =>
      "Desinstalar ${name}? Os vínculos com bots também serão removidos.";

  static String m12(year) => "© ${year} Equipe Stars";

  static String m13(error) => "Could not create the chat: ${error}";

  static String m14(error) => "Could not delete the chat: ${error}";

  static String m15(milliseconds) => "${milliseconds} ms";

  static String m16(seconds) => "${seconds} s";

  static String m17(name) =>
      "Permitir que ${name} registre os scripts declarados como ferramentas. Cada chamada ainda exigirá aprovação.";

  static String m18(count) => "${count} files";

  static String m19(error) => "Generate image failed: ${error}";

  static String m20(error) => "Could not generate music: ${error}";

  static String m21(error) => "Could not generate speech: ${error}";

  static String m22(error) => "Could not generate video: ${error}";

  static String m23(count) => "${count} items";

  static String m24(language) => "Idioma alterado para ${language}";

  static String m25(error) => "MCP connection failed: ${error}";

  static String m26(count) => "${count} configured (values hidden)";

  static String m27(minutes) => "há ${minutes} minutos";

  static String m28(count) => "${count} modelos recuperados com sucesso";

  static String m29(count) => "${count} execuções de comando";

  static String m30(duration) => "Duração ${duration}";

  static String m31(count) => "${count} alterações de arquivo";

  static String m32(count) => "${count} chamadas de ferramenta";

  static String m33(error) => "Falha ao obter resposta: ${error}";

  static String m34(error) => "Could not save image: ${error}";

  static String m35(error) => "Could not share image: ${error}";

  static String m36(error) =>
      "Não foi possível importar a habilidade: ${error}";

  static String m37(duration) => "Pensamento concluído · ${duration}";

  static String m38(error) => "Erro na reprodução do vídeo: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("Sobre"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Sobre o Stars"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("Adicionar bot"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("Adicionar habilidade"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajustar tamanho da fonte do aplicativo",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajustar tamanho da fonte",
    ),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Todas as habilidades instaladas foram adicionadas.",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("Sempre ativa"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Insere esta habilidade em cada solicitação de texto.",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("Sempre ativa"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("Endereço da API:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("Chave API"),
    "apiType": MessageLookupByLibrary.simpleMessage("Tipo de API:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "Um aplicativo de chat com IA simples, mas poderoso, que permite conversar com inteligência artificial a qualquer hora e em qualquer lugar.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Stars - Assistente de chat com IA",
    ),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "Prompt do sistema",
    ),
    "applicationInjectedPromptDescription": MessageLookupByLibrary.simpleMessage(
      "Gerenciado pelo Stars e adicionado a cada solicitação ao modelo. Os identificadores do agente e da conversa atuais são incluídos em tempo de execução e não podem ser editados.",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("Automática"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Permite que modelos compatíveis ativem esta habilidade pela descrição.",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "Este provedor aceita apenas habilidades manuais.",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage(
      "Memória automática",
    ),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "Resumos automáticos podem ser imprecisos. A mensagem atual sempre tem prioridade.",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage(
      "Voltar ao uso diário",
    ),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Informações básicas",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Avatar do bot"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "Ative ferramentas MCP para este agente. As chamadas exigem confirmação por padrão.",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("Nome do bot"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "A pesquisa filtra a lista pelo nome do bot.",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("Habilidades"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "Escolha as instruções reutilizáveis disponíveis para este bot.",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "browseConversationDirectory": MessageLookupByLibrary.simpleMessage(
      "Browse conversation data",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("Alterar avatar"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("Salvo"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage(
      "Status de execução do chat",
    ),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Histórico de conversa limpo",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Conversas"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("Limpar"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage(
      "Limpar memória automática",
    ),
    "clearChat": MessageLookupByLibrary.simpleMessage("Limpar conversa"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Limpar histórico de conversa",
    ),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage(
      "Limpar habilidades fixadas",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "Selecione um dia para ver o uso por hora",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Clique em + no canto superior direito para adicionar um bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Clique em Nova conversa para criar uma conversa",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage(
      "Execuções de comando",
    ),
    "compactNow": MessageLookupByLibrary.simpleMessage("Compactar agora"),
    "compactingContext": MessageLookupByLibrary.simpleMessage(
      "Organizando o contexto…",
    ),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("Falhou"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage(
      "Status da compactação",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirmar exclusão"),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Informações de contato (opcional)",
    ),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage(
      "Contexto e memória",
    ),
    "contextCompacted": MessageLookupByLibrary.simpleMessage(
      "Contexto compactado",
    ),
    "contextWindow": MessageLookupByLibrary.simpleMessage("Janela de contexto"),
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
      "Resumo da conversa",
    ),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage(
      "Distribuição de tokens por conversa",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("Copiar chave de API"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m12,
    "createChatFailed": m13,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Data de criação"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Provedor personalizado...",
    ),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage("Uso diário"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Modo escuro"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "Este banco de dados foi criado por uma versão mais recente do Stars. Atualize o aplicativo antes de abri-lo.",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "A verificação de integridade do banco de dados falhou e não foi possível recuperá-lo pelo backup desta versão.",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage("Raciocínio profundo"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Você é um assistente de IA útil. Por favor, responda em português.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Excluir"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Excluir bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Excluir conversa"),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "Sobre e informações legais",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "Aparência e idioma",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Altere seu avatar e nome de exibição.",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("Geral"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage(
      "Ajuda e suporte",
    ),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage(
      "Informações pessoais",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "As alterações entram em vigor imediatamente e são salvas localmente.",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Gerencie seu perfil, aparência, idioma e suporte do aplicativo.",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Detalhes"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Desativar sem confirmação para todas",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Desativar todas as ferramentas",
    ),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Desativar scripts",
    ),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("Editar"),
    "editBot": MessageLookupByLibrary.simpleMessage("Editar bot"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("Editar memória"),
    "editName": MessageLookupByLibrary.simpleMessage("Editar nome"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Falha ao obter resposta: o servidor retornou uma resposta vazia",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Ativar sem confirmação para todas",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Ativar todas as ferramentas",
    ),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Ativar scripts",
    ),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "Ativar scripts isolados?",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "Digite o endereço da API...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage(
      "Digite a chave API...",
    ),
    "enterBotName": MessageLookupByLibrary.simpleMessage(
      "Digite o nome do bot...",
    ),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage(
      "Digite um nome de exibição",
    ),
    "enterNewName": MessageLookupByLibrary.simpleMessage(
      "Por favor, digite um novo nome",
    ),
    "enterProviderName": MessageLookupByLibrary.simpleMessage(
      "Digite o nome do provedor...",
    ),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Digite o prompt do sistema...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "Erro ao carregar conteúdo, por favor tente novamente mais tarde.",
    ),
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage(
      "Uso estimado",
    ),
    "executionStatus": MessageLookupByLibrary.simpleMessage(
      "Status da execução",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Por favor, digite o conteúdo do feedback",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Por favor, conte-nos seus pensamentos, problemas ou sugestões para nos ajudar a melhorar o aplicativo",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Digite seu feedback aqui...",
    ),
    "feedbackInformation": MessageLookupByLibrary.simpleMessage(
      "Informações de feedback",
    ),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "Falha no envio, por favor tente novamente mais tarde",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "Obrigado pelo seu feedback!",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage(
      "Obter lista de modelos",
    ),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "Por favor, obtenha a lista de modelos primeiro",
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
    "fileStatus": MessageLookupByLibrary.simpleMessage("Status dos arquivos"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("Música"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("Fala"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("Vídeo"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "Por favor, preencha o nome do bot, endereço da API e chave API",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Sistema"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage(
      "Tamanho da fonte",
    ),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "Tamanho da fonte atualizado",
    ),
    "forgetMemory": MessageLookupByLibrary.simpleMessage("Esquecer"),
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
      "Falha na geração",
    ),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "Falha na geração · Resposta parcial mantida",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("Ajuda e Feedback"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("Ocultar chave de API"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("Início"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage("Uso por hora"),
    "htmlPreview": MessageLookupByLibrary.simpleMessage("Prévia de HTML"),
    "idle": MessageLookupByLibrary.simpleMessage("Ocioso"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage(
      "Importar pasta de habilidades",
    ),
    "importSkillZip": MessageLookupByLibrary.simpleMessage(
      "Importar ZIP de habilidades",
    ),
    "importingSkill": MessageLookupByLibrary.simpleMessage(
      "Importando habilidade…",
    ),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("Tokens de entrada"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage(
      "Instalar atualização",
    ),
    "invalidSummary": MessageLookupByLibrary.simpleMessage(
      "O resumo gerado não passou na validação",
    ),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("Agora mesmo"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Configurações de idioma",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Modo claro"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("Gerenciar memória"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("Por mensagem"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Selecione a habilidade no campo de mensagem quando precisar.",
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
      "Sem confirmação",
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
      "Conecte servidores MCP e descubra seus catálogos de ferramentas. Configure as ferramentas após criar um agente.",
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
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("Artefato"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "A memória mudou; tente novamente",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("Correção"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("Decisão"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("Fato"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("Preferência"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage(
      "Pergunta em aberto",
    ),
    "memoryTask": MessageLookupByLibrary.simpleMessage("Tarefa"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage(
      "Digite uma mensagem...",
    ),
    "messageSkills": MessageLookupByLibrary.simpleMessage("Habilidades"),
    "minutesAgo": m27,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("Audio"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("Arquivo"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("Imagem"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("Multimodal"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("Música"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("Tempo real"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("Fala"),
    "modalityText": MessageLookupByLibrary.simpleMessage("Texto"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("Vídeo"),
    "model": MessageLookupByLibrary.simpleMessage("Modelo"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "Configuração do modelo",
    ),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage(
      "Tamanho do contexto do modelo",
    ),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("Entrada"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("Saída"),
    "modelsRetrievedSuccess": m28,
    "modificationTime": MessageLookupByLibrary.simpleMessage(
      "Data de modificação",
    ),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("Nome"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Nome atualizado"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("Nova conversa"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "Não há ferramentas MCP conectadas disponíveis.",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "Nenhuma habilidade adicionada",
    ),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "Adicione as habilidades instaladas necessárias para este bot.",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "Nenhum bot disponível",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("Ainda não há conversas"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "Nenhum conteúdo retornado",
    ),
    "noConversationFilesFound": MessageLookupByLibrary.simpleMessage(
      "No matching files or folders.",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "Ainda não há um resumo da conversa disponível.",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "Nenhum bot correspondente encontrado",
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
      "Nenhuma habilidade correspondente encontrada",
    ),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "Nenhum modelo recuperado",
    ),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage(
      "Nenhuma habilidade instalada",
    ),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "Importe uma pasta do Agent Skills ou um ZIP contendo SKILL.md.",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "Nenhum uso de tokens registrado",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("Não compatível"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "Não há contexto antigo suficiente para compactar",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openLink": MessageLookupByLibrary.simpleMessage("Abrir link"),
    "openWithSystem": MessageLookupByLibrary.simpleMessage(
      "Open with system app",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("Tokens de saída"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("Resposta parcial"),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("Pausar áudio"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("Pausar geração"),
    "pinMemory": MessageLookupByLibrary.simpleMessage("Fixar"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "Fixar seleção nesta conversa",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("Fixada"),
    "playAudio": MessageLookupByLibrary.simpleMessage("Reproduzir áudio"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Por favor, insira a chave API primeiro",
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
    "preview": MessageLookupByLibrary.simpleMessage("Prévia"),
    "previewText": MessageLookupByLibrary.simpleMessage(
      "Visualização do texto",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Política de privacidade",
    ),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "Informações do processo",
    ),
    "processToolCount": m32,
    "profile": MessageLookupByLibrary.simpleMessage("Perfil"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Forneça suas sugestões e feedback",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Provedor"),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "Informações do provedor",
    ),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage(
      "Raciocínio concluído",
    ),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage(
      "Raciocínio em andamento",
    ),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage(
      "Raciocínio interrompido",
    ),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("Reconstruir"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("Atualizar"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Atualizar catálogos",
    ),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Atualizando catálogos…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("Remover habilidade"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage(
      "Resposta cancelada",
    ),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "Interrompido · Resposta parcial mantida",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("Restaurar padrão"),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("Restaurar"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage(
      "Turnos recentes mantidos",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage(
      "Executar teste",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Salvar"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Salvar alterações"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("Salvando..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("Pesquisar bots"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchConversationFiles": MessageLookupByLibrary.simpleMessage(
      "Search files and folders",
    ),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage("Pesquisar memória"),
    "searchSkills": MessageLookupByLibrary.simpleMessage("Buscar habilidades"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Selecionar bot"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Selecionar idioma"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Selecionar modelo:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage(
      "Selecionar provedor:",
    ),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Selecionar tema"),
    "send": MessageLookupByLibrary.simpleMessage("Enviar"),
    "settings": MessageLookupByLibrary.simpleMessage("Configurações"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("Mostrar chave de API"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Mostrar detalhes da execução nas mensagens da conversa.",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage(
      "Recursos disponíveis",
    ),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage(
      "Compatibilidade",
    ),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "Este exemplo deve ativar a habilidade",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "Exemplo de solicitação do usuário",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage(
      "Resultado da ativação",
    ),
    "skillDetails": MessageLookupByLibrary.simpleMessage(
      "Detalhes da habilidade",
    ),
    "skillDigest": MessageLookupByLibrary.simpleMessage("Hash do conteúdo"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("Desativada"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("Ativada"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("Arquivos"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "Habilidade importada",
    ),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("Habilidades"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "Instale instruções reutilizáveis e vincule-as aos bots.",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "Esta versão não executa scripts ou comandos das habilidades.",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("Publicador"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "Arquivos de referência disponíveis",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "O SKILL.md é carregado apenas como orientação controlada de prompt; scripts, comandos e ferramentas externas permanecem desativados.",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "Sandbox de scripts disponível",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "Os scripts permanecem desativados até sua aprovação. Cada chamada ainda exige aprovação.",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "Scripts de habilidades indisponíveis",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "Esta plataforma não oferece o isolamento necessário. Instruções e recursos continuam disponíveis.",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "Configuração dos scripts atualizada.",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "Os scripts estão instalados, mas a execução está desativada.",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage(
      "Scripts ativados",
    ),
    "skillSignature": MessageLookupByLibrary.simpleMessage("Assinatura"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage(
      "Assinatura inválida",
    ),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "Publicador desconhecido",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage(
      "Sem assinatura",
    ),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "Assinatura verificada",
    ),
    "skillSource": MessageLookupByLibrary.simpleMessage("Origem"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("Automática"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Atualização disponível",
    ),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("Manual"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("Notificar"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("Fixada"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage(
      "Política de atualização",
    ),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("Usuário"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage(
      "Notas de validação",
    ),
    "skillVersion": MessageLookupByLibrary.simpleMessage("Versão"),
    "sourceCode": MessageLookupByLibrary.simpleMessage("Código-fonte"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Envie uma mensagem no campo de texto abaixo para começar a conversar",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Comece a conversar"),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "Falha ao iniciar. Tente novamente.",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage("Iniciando…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("Ativado"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("Anexado"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage(
      "Aguardando aprovação",
    ),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Cancelado"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Concluído"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("Negado"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage(
      "Chamada duplicada",
    ),
    "statusFailed": MessageLookupByLibrary.simpleMessage("Falhou"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("Gerado"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("Em andamento"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("Registrado"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("Solicitado"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("Em execução"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("Ignorado"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("Tempo esgotado"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("Desconhecido"),
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
      "Informações estruturadas do processo",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("Enviar Feedback"),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage(
      "Mensagens resumidas",
    ),
    "supported": MessageLookupByLibrary.simpleMessage("Compatível"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("Compatível com MCP"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage(
      "Compatível com Skills",
    ),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("Prompt do sistema"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("Testar"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage(
      "Testar descrição",
    ),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "Tema configurado para modo escuro",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "Tema configurado para modo claro",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "Tema configurado para seguir o sistema",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage(
      "Configurações de tema",
    ),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage(
      "Pensamento concluído",
    ),
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("Pensando…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("Uso de tokens"),
    "tokens": MessageLookupByLibrary.simpleMessage("tokens"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage(
      "Permitido uma vez",
    ),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("Negado"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("Chamadas de ferramenta"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("Destrutivo"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("Somente leitura"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("Gravação"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("Integrado"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage(
      "Script de Skill",
    ),
    "totalTokens": MessageLookupByLibrary.simpleMessage("Total de tokens"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Tente outra pesquisa ou crie um novo item.",
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
    "unavailableBot": MessageLookupByLibrary.simpleMessage("Bot indisponível"),
    "uninstall": MessageLookupByLibrary.simpleMessage("Desinstalar"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage(
      "Desinstalar habilidade",
    ),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("Desafixar"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "Formato de imagem não compatível. Escolha uma imagem JPEG, PNG, GIF, BMP ou WebP.",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("Enviar arquivo"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("Enviar imagem"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("Acordo do usuário"),
    "version": MessageLookupByLibrary.simpleMessage("Versão 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Não foi possível carregar o vídeo",
    ),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("Ver resumo"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
