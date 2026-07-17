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

  static String m6(botName) =>
      "Tem certeza de que deseja limpar todo o histórico de conversa com \"${botName}\"? Esta ação não pode ser desfeita.";

  static String m7(botName) =>
      "Excluir o bot também removerá todas as conversas associadas. Tem certeza de que deseja excluir ${botName}?";

  static String m8(botName) =>
      "Excluir a conversa apagará todo o histórico de conversas. Tem certeza de que deseja excluir a conversa com ${botName}?";

  static String m9(language) => "Idioma alterado para ${language}";

  static String m10(minutes) => "há ${minutes} minutos";

  static String m11(count) => "${count} modelos recuperados com sucesso";

  static String m12(error) => "Falha ao obter resposta: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("Sobre"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Sobre o Stars"),
    "addBot": MessageLookupByLibrary.simpleMessage("Adicionar bot"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajustar tamanho da fonte do aplicativo",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "Ajustar tamanho da fonte",
    ),
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
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Avatar do bot"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botIsTyping": m3,
    "botName": MessageLookupByLibrary.simpleMessage("Nome do bot"),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
    "chatDeleted": m5,
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Histórico de conversa limpo",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Conversas"),
    "clear": MessageLookupByLibrary.simpleMessage("Limpar"),
    "clearChat": MessageLookupByLibrary.simpleMessage("Limpar conversa"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Limpar histórico de conversa",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Clique em + no canto superior direito para adicionar um bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Clique em Nova conversa para criar uma conversa",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
    "confirmClearChat": m6,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirmar exclusão"),
    "confirmDeleteBot": m7,
    "confirmDeleteChat": m8,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Informações de contato (opcional)",
    ),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 Equipe Stars"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Provedor personalizado...",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Modo escuro"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Você é um assistente de IA útil. Por favor, responda em português.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Excluir"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Excluir bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Excluir conversa"),
    "editBot": MessageLookupByLibrary.simpleMessage("Editar bot"),
    "editName": MessageLookupByLibrary.simpleMessage("Editar nome"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Falha ao obter resposta: o servidor retornou uma resposta vazia",
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
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Por favor, digite o conteúdo do feedback",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Por favor, conte-nos seus pensamentos, problemas ou sugestões para nos ajudar a melhorar o aplicativo",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Digite seu feedback aqui...",
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
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("Ajuda e Feedback"),
    "home": MessageLookupByLibrary.simpleMessage("Início"),
    "justNow": MessageLookupByLibrary.simpleMessage("Agora mesmo"),
    "languageChanged": m9,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Configurações de idioma",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Modo claro"),
    "messageHint": MessageLookupByLibrary.simpleMessage(
      "Digite uma mensagem...",
    ),
    "minutesAgo": m10,
    "model": MessageLookupByLibrary.simpleMessage("Modelo"),
    "modelsRetrievedSuccess": m11,
    "name": MessageLookupByLibrary.simpleMessage("Nome"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Nome atualizado"),
    "newChat": MessageLookupByLibrary.simpleMessage("Nova conversa"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "Nenhum bot disponível",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("Ainda não há conversas"),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "Nenhum modelo recuperado",
    ),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("Pausar geração"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Por favor, insira a chave API primeiro",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage(
      "Visualização do texto",
    ),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage(
      "Política de privacidade",
    ),
    "profile": MessageLookupByLibrary.simpleMessage("Perfil"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Forneça suas sugestões e feedback",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Provedor"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage(
      "Resposta cancelada",
    ),
    "responseError": m12,
    "save": MessageLookupByLibrary.simpleMessage("Salvar"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Salvar alterações"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Selecionar bot"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Selecionar idioma"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Selecionar modelo:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage(
      "Selecionar provedor:",
    ),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Selecionar tema"),
    "send": MessageLookupByLibrary.simpleMessage("Enviar"),
    "settings": MessageLookupByLibrary.simpleMessage("Configurações"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Envie uma mensagem no campo de texto abaixo para começar a conversar",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Comece a conversar"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("Enviar Feedback"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("Prompt do sistema"),
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
    "typing": MessageLookupByLibrary.simpleMessage("Digitando..."),
    "userAgreement": MessageLookupByLibrary.simpleMessage("Acordo do usuário"),
    "version": MessageLookupByLibrary.simpleMessage("Versão 1.0.0"),
  };
}
