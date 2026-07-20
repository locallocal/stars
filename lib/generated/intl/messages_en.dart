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

  static String m13(error) => "Could not clear chat history: ${error}";

  static String m6(botName) =>
      "Are you sure you want to clear all chat history with \"${botName}\"? This action cannot be undone.";

  static String m7(botName) =>
      "Deleting this bot will also delete all associated chat history. Are you sure you want to delete ${botName}?";

  static String m8(botName) =>
      "Deleting this chat will clear all chat history. Are you sure you want to delete the chat with ${botName}?";

  static String m14(error) => "Could not create the chat: ${error}";

  static String m15(error) => "Could not delete the chat: ${error}";

  static String m16(count) => "${count} files";

  static String m17(error) => "Generate image failed: ${error}";

  static String m18(error) => "Could not generate music: ${error}";

  static String m19(error) => "Could not generate speech: ${error}";

  static String m20(error) => "Could not generate video: ${error}";

  static String m21(count) => "${count} items";

  static String m9(language) => "Language set to ${language}";

  static String m10(minutes) => "${minutes} minutes ago";

  static String m11(count) => "Successfully retrieved ${count} models";

  static String m22(count) => "${count} command runs";

  static String m23(duration) => "Duration ${duration}";

  static String m24(count) => "${count} file updates";

  static String m25(count) => "${count} tool calls";

  static String m12(error) => "Failed to get response: ${error}";

  static String m26(error) => "Could not save image: ${error}";

  static String m27(error) => "Could not share image: ${error}";

  static String m28(duration) => "Thinking complete · ${duration}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("Bots"),
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("About Stars"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("Add Bot"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Adjust app font size",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("Adjust Font Size"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API Address"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API Key"),
    "apiType": MessageLookupByLibrary.simpleMessage("API Type"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "A simple yet powerful AI chat application that lets you chat with AI anytime, anywhere.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage(
      "Stars - AI Chat Assistant",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Basic Information",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Bot Avatar"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botName": MessageLookupByLibrary.simpleMessage("Bot Name"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search filters the list by bot name.",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("Change avatar"),
    "chatDeleted": m5,
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "Chat history cleared",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("Chats"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearChat": MessageLookupByLibrary.simpleMessage("Clear Chat"),
    "clearChatFailed": m13,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Clear chat history",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Click + in the top right to create a new bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Click New Chat to create a conversation",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage(
      "Command execution",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirmClearChat": m6,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirm Delete"),
    "confirmDeleteBot": m7,
    "confirmDeleteChat": m8,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Contact information (optional)",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("Copy API Key"),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 Stars Team"),
    "createChatFailed": m14,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
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
    "deleteChatFailed": m15,
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "About & Legal",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "Appearance & Language",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Change your avatar and display name.",
    ),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage(
      "Help & Support",
    ),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage(
      "Personal Information",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "Changes take effect immediately and are saved locally.",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "Manage your profile, appearance, language, and app support.",
    ),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
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
    "executionStatus": MessageLookupByLibrary.simpleMessage("Execution status"),
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
    "fileAttachment": MessageLookupByLibrary.simpleMessage("File attachment"),
    "fileCount": m16,
    "fileResult": MessageLookupByLibrary.simpleMessage("File result"),
    "fileStatus": MessageLookupByLibrary.simpleMessage("File status"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("Music"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("Speech"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("Video"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "Please fill in bot name, API address and API key",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("Follow System"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("Font Size"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "Font size updated",
    ),
    "generateImageFailed": m17,
    "generateMusicFailed": m18,
    "generateSpeechFailed": m19,
    "generateVideoFailed": m20,
    "generatedImage": MessageLookupByLibrary.simpleMessage("Image generated"),
    "generating": MessageLookupByLibrary.simpleMessage("Generating…"),
    "generatingImage": MessageLookupByLibrary.simpleMessage(
      "Generating image, please wait...",
    ),
    "generationFailed": MessageLookupByLibrary.simpleMessage(
      "Generation failed",
    ),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "Generation failed · Partial response kept",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("Help & Feedback"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("Hide API Key"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "itemCount": m21,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("Just now"),
    "languageChanged": m9,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Language Settings",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Light Mode"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage("Type a message..."),
    "minutesAgo": m10,
    "model": MessageLookupByLibrary.simpleMessage("Model"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "Model Configuration",
    ),
    "modelsRetrievedSuccess": m11,
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("Name updated"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("New Chat"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "No bots available",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("No chats yet"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "No content returned",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "No matching bots found",
    ),
    "noMatchingChats": MessageLookupByLibrary.simpleMessage(
      "No matching chats found",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "No models retrieved",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "partialResponse": MessageLookupByLibrary.simpleMessage("Partial response"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("Pause generation"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "Please enter API key first",
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
    "previewText": MessageLookupByLibrary.simpleMessage("Preview text effect"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "processCommandCount": m22,
    "processDuration": m23,
    "processFileCount": m24,
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "Process information",
    ),
    "processToolCount": m25,
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "Provide your suggestions and feedback",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("Provider"),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "Provider Information",
    ),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage(
      "Reasoning complete",
    ),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage(
      "Reasoning in progress",
    ),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage(
      "Reasoning interrupted",
    ),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("Reply cancelled"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "Stopped · Partial response kept",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("Reset to Default"),
    "responseError": m12,
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Save Changes"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m26,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "searchBots": MessageLookupByLibrary.simpleMessage("Search bots"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Select Bot"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Select Language"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Select Model:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("Select Provider"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Select Theme"),
    "send": MessageLookupByLibrary.simpleMessage("Send"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m27,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("Show API Key"),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Type a message in the input box below to start chatting",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Start chatting"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("Attached"),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Completed"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("Failed"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("Generated"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("In progress"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("Recorded"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("Running"),
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
      "Structured process information",
    ),
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
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage(
      "Thinking complete",
    ),
    "thinkingCompletedWithDuration": m28,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("Thinking…"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("Tool calls"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Try a different search, or create a new item.",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("Typing..."),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage(
      "Unable to load bots",
    ),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage(
      "Unable to load chats",
    ),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage(
      "Unable to load messages",
    ),
    "unavailableBot": MessageLookupByLibrary.simpleMessage("Unavailable bot"),
    "uploadFile": MessageLookupByLibrary.simpleMessage("File"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("Image"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("User Agreement"),
    "version": MessageLookupByLibrary.simpleMessage("Version 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
