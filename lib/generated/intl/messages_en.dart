// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(name) => "Bot \"${name}\" has been added";

  static String m1(botName) => "\"${botName}\" has been deleted";

  static String m2(botName) =>
      "Hello! I\'m ${botName}, an AI assistant. Feel free to ask me anything, and I\'ll do my best to help you.";

  static String m3(botName) => "${botName} is typing...";

  static String m4(botName) => "Bot ${botName} has been updated";

  static String m5(botName) => "Chat with ${botName} deleted";

  static String m6(botName) =>
      "Are you sure you want to clear all chat history with \"${botName}\"? This action cannot be undone.";

  static String m7(botName) =>
      "Deleting this bot will also delete all associated chat history. Are you sure you want to delete ${botName}?";

  static String m8(botName) =>
      "Deleting this chat will clear all chat history. Are you sure you want to delete the chat with ${botName}?";

  static String m9(language) => "Language set to ${language}";

  static String m10(minutes) => "${minutes} minutes ago";

  static String m11(count) => "Successfully retrieved ${count} models";

  static String m12(error) => "Failed to get response: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("About Bubble"),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("Add Bot"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Adjust app font size",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("Adjust Font Size"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API Address:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API Key"),
    "apiType": MessageLookupByLibrary.simpleMessage("API Type:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "A simple yet powerful AI chat application that lets you chat with AI anytime, anywhere.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Bubble"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Bubble - AI Chat Assistant",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Bot Avatar"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botIsTyping": m3,
    "botName": MessageLookupByLibrary.simpleMessage("Bot Name"),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "chatDeleted": m5,
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Chat history cleared",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Chats"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "clearChat": MessageLookupByLibrary.simpleMessage("Clear Chat"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Clear chat history",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Click + in the top right to create a new bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Click + in the top right to start a chat",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirmClearChat": m6,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirm Delete"),
    "confirmDeleteBot": m7,
    "confirmDeleteChat": m8,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Contact information (optional)",
    ),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 Bubble Team"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Custom Provider...",
    ),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dark Mode"),
    "deepThinking": MessageLookupByLibrary.simpleMessage("Deep Thinking"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "You are a helpful AI assistant.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Delete Bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Delete Chat"),
    "editBot": MessageLookupByLibrary.simpleMessage("Edit Bot"),
    "editName": MessageLookupByLibrary.simpleMessage("Edit Name"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Failed to get response: Server returned empty response",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "Enter API address...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("Enter API key..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("Enter bot name..."),
    "enterNewName": MessageLookupByLibrary.simpleMessage(
      "Please enter new name",
    ),
    "enterProviderName": MessageLookupByLibrary.simpleMessage(
      "Enter provider name...",
    ),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "Enter system prompt...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "Error loading content, please try again later.",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "Please enter feedback content",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "Please tell us your thoughts, issues, or suggestions to help us improve the app",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "Enter your feedback here...",
    ),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "Submission failed, please try again later",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "Thank you for your feedback!",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage("Fetch Model List"),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "Please fetch model list first",
    ),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "Please fill in bot name, API address and API key",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Follow System"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("Font Size"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "Font size updated",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("Help & Feedback"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "justNow": MessageLookupByLibrary.simpleMessage("Just now"),
    "languageChanged": m9,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Language Settings",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Light Mode"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage("Type a message..."),
    "minutesAgo": m10,
    "model": MessageLookupByLibrary.simpleMessage("Model"),
    "modelsRetrievedSuccess": m11,
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Name updated"),
    "newChat": MessageLookupByLibrary.simpleMessage("New Chat"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "No bots available",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("No chats yet"),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "No models retrieved",
    ),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("Pause generation"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Please enter API key first",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage("Preview text effect"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Provide your suggestions and feedback",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Provider"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("Reply cancelled"),
    "responseError": m12,
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Save Changes"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Select Bot"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Select Language"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Select Model:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("Select Provider:"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Select Theme"),
    "send": MessageLookupByLibrary.simpleMessage("Send"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Type a message in the input box below to start chatting",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Start chatting"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("Submit Feedback"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("System Prompt"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "Theme set to dark mode",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "Theme set to light mode",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "Theme set to follow system",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage("Theme Settings"),
    "typing": MessageLookupByLibrary.simpleMessage("Typing..."),
    "uploadFile": MessageLookupByLibrary.simpleMessage("File"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("Image"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("User Agreement"),
    "version": MessageLookupByLibrary.simpleMessage("Version 1.0.0"),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
