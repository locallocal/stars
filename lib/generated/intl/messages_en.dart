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

  static String m13(error) => "Generate image failed: ${error}";

  static String m14(count) => "${count} items";

  static String m15(count) => "${count} files";

  static String m16(error) => "Could not save image: ${error}";

  static String m17(error) => "Could not share image: ${error}";

  static String m18(duration) => "Duration ${duration}";

  static String m19(count) => "${count} tool calls";

  static String m20(count) => "${count} command runs";

  static String m21(count) => "${count} file updates";

  static String m22(duration) => "Thinking complete · ${duration}";

  static String m23(error) => "Could not generate speech: ${error}";

  static String m24(error) => "Could not generate music: ${error}";

  static String m25(error) => "Could not generate video: ${error}";

  static String m26(error) => "Could not create the chat: ${error}";

  static String m27(error) => "Could not clear chat history: ${error}";

  static String m28(error) => "Could not delete the chat: ${error}";

  static String m9(language) => "Language set to ${language}";

  static String m10(minutes) => "${minutes} minutes ago";

  static String m11(count) => "Successfully retrieved ${count} models";

  static String m12(error) => "Failed to get response: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("About Stars"),
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
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Stars - AI Chat Assistant",
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
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 Stars Team"),
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
    "generateImageFailed": m13,
    "generatedImage": MessageLookupByLibrary.simpleMessage("Image generated"),
    "generatingImage": MessageLookupByLibrary.simpleMessage(
      "Generating image, please wait...",
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
    "pleaseEnterImageDescription": MessageLookupByLibrary.simpleMessage(
      "Please enter a description for image generation",
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
    "searchChats": MessageLookupByLibrary.simpleMessage("Search chats"),
    "searchBots": MessageLookupByLibrary.simpleMessage("Search bots"),
    "noMatchingChats": MessageLookupByLibrary.simpleMessage(
      "No matching chats found",
    ),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage(
      "Personal Information",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "Appearance & Language",
    ),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage(
      "Help & Support",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "About & Legal",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Manage your profile, appearance, language, and app support.",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Change your avatar and display name.",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "Changes take effect immediately and are saved locally.",
    ),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("Change avatar"),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("Reset to Default"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "generating": MessageLookupByLibrary.simpleMessage("Generating…"),
    "stopping": MessageLookupByLibrary.simpleMessage("Stopping…"),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Basic Information",
    ),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "Provider Information",
    ),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "Model Configuration",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("Copy API Key"),
    "showApiKey": MessageLookupByLibrary.simpleMessage("Show API Key"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("Hide API Key"),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "No matching bots found",
    ),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Try a different search, or create a new item.",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search filters the list by bot name.",
    ),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage(
      "Unable to load chats",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "unavailableBot": MessageLookupByLibrary.simpleMessage("Unavailable bot"),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "itemCount": m14,
    "fileCount": m15,
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "fileAttachment": MessageLookupByLibrary.simpleMessage("File attachment"),
    "fileResult": MessageLookupByLibrary.simpleMessage("File result"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "Stopped · Partial response kept",
    ),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "Generation failed · Partial response kept",
    ),
    "generationFailed": MessageLookupByLibrary.simpleMessage(
      "Generation failed",
    ),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "No content returned",
    ),
    "partialResponse": MessageLookupByLibrary.simpleMessage("Partial response"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Completed"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "saveImageFailed": m16,
    "shareImageFailed": m17,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "processDuration": m18,
    "processToolCount": m19,
    "processCommandCount": m20,
    "processFileCount": m21,
    "executionStatus": MessageLookupByLibrary.simpleMessage("Execution status"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("Tool calls"),
    "commandExecutions": MessageLookupByLibrary.simpleMessage(
      "Command execution",
    ),
    "fileStatus": MessageLookupByLibrary.simpleMessage("File status"),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "structuredProcessInfo": MessageLookupByLibrary.simpleMessage(
      "Structured process information",
    ),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("Generated"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("Attached"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("In progress"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("Running"),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("Failed"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("Recorded"),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage(
      "Reasoning complete",
    ),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage(
      "Reasoning interrupted",
    ),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage(
      "Reasoning in progress",
    ),
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "Process information",
    ),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("Speech"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("Music"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("Video"),
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("Thinking…"),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage(
      "Thinking complete",
    ),
    "thinkingCompletedWithDuration": m22,
    "pleaseEnterSpeechDescription": MessageLookupByLibrary.simpleMessage(
      "Enter a description for speech generation",
    ),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "generateSpeechFailed": m23,
    "pleaseEnterMusicDescription": MessageLookupByLibrary.simpleMessage(
      "Enter a description for music generation",
    ),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "generateMusicFailed": m24,
    "pleaseEnterVideoDescription": MessageLookupByLibrary.simpleMessage(
      "Enter a description for video generation",
    ),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "generateVideoFailed": m25,
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage(
      "Unable to load bots",
    ),
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "createChatFailed": m26,
    "stopGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Stop generation before leaving?",
    ),
    "stopGenerationBeforeLeavingDescription":
        MessageLookupByLibrary.simpleMessage(
          "The partial response will be kept.",
        ),
    "stopAndContinue": MessageLookupByLibrary.simpleMessage(
      "Stop and continue",
    ),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage(
      "Unable to load messages",
    ),
    "clearChatFailed": m27,
    "deleteChatFailed": m28,
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
