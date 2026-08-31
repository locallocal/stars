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

  static String m6(error) => "Could not clear chat history: ${error}";

  static String m7(botName) =>
      "Are you sure you want to clear all chat history with \"${botName}\"? This action cannot be undone.";

  static String m8(botName) =>
      "Deleting this bot will also delete all associated chat history. Are you sure you want to delete ${botName}?";

  static String m9(botName) =>
      "Deleting this chat will clear all chat history. Are you sure you want to delete the chat with ${botName}?";

  static String m10(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m11(name) =>
      "Uninstall ${name}? Bot bindings will also be removed.";

  static String m12(year) => "© ${year} Stars Team";

  static String m13(error) => "Could not create the chat: ${error}";

  static String m14(error) => "Could not delete the chat: ${error}";

  static String m15(milliseconds) => "${milliseconds} ms";

  static String m16(seconds) => "${seconds} s";

  static String m17(name) =>
      "Allow ${name} to register its declared scripts as tools. Each call still requires approval and runs inside the desktop sandbox.";

  static String m18(count) => "${count} files";

  static String m19(error) => "Generate image failed: ${error}";

  static String m20(error) => "Could not generate music: ${error}";

  static String m21(error) => "Could not generate speech: ${error}";

  static String m22(error) => "Could not generate video: ${error}";

  static String m23(count) => "${count} items";

  static String m24(language) => "Language set to ${language}";

  static String m25(error) => "MCP connection failed: ${error}";

  static String m26(count) => "${count} configured (values hidden)";

  static String m27(minutes) => "${minutes} minutes ago";

  static String m28(count) => "Successfully retrieved ${count} models";

  static String m29(count) => "${count} command runs";

  static String m30(duration) => "Duration ${duration}";

  static String m31(count) => "${count} file updates";

  static String m32(count) => "${count} tool calls";

  static String m33(error) => "Failed to get response: ${error}";

  static String m34(error) => "Could not save image: ${error}";

  static String m35(error) => "Could not share image: ${error}";

  static String m36(error) => "Could not import Skill: ${error}";

  static String m37(duration) => "Thinking complete · ${duration}";

  static String m38(error) => "Video playback error: ${error}";

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
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("Add Skill"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "Adjust app font size",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("Adjust Font Size"),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "All installed Skills have been added.",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("Always on"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Inject this Skill into every text request.",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("Always on"),
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
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "System prompt",
    ),
    "applicationInjectedPromptDescription": MessageLookupByLibrary.simpleMessage(
      "Managed by Stars and added to every model-facing system prompt. Current agent and conversation identifiers are added at runtime and cannot be edited.",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("Automatic"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Let supported models activate this Skill from its description.",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "This provider supports manual Skills only.",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage("Automatic memory"),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "Automatic summaries can be inaccurate. The current message always takes precedence.",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage(
      "Back to daily usage",
    ),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Basic Information",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("Bot Avatar"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "Enable MCP Tools for this agent. Tool calls require confirmation by default.",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("Bot Name"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search filters the list by bot name.",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("Skills"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "Choose reusable instructions available to this bot.",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "browseConversationDirectory": MessageLookupByLibrary.simpleMessage(
      "Browse conversation data",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("Change avatar"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("Saved"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage(
      "Chat execution status",
    ),
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
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage(
      "Clear automatic memory",
    ),
    "clearChat": MessageLookupByLibrary.simpleMessage("Clear Chat"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "Clear chat history",
    ),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage(
      "Clear conversation pins",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "Select a day to view hourly usage",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "Click + in the top right to create a new bot",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "Click New Chat to create a conversation",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage(
      "Command execution",
    ),
    "compactNow": MessageLookupByLibrary.simpleMessage("Compact now"),
    "compactingContext": MessageLookupByLibrary.simpleMessage(
      "Organizing context…",
    ),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("Failed"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage(
      "Compaction status",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirm Delete"),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "Contact information (optional)",
    ),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage(
      "Context and memory",
    ),
    "contextCompacted": MessageLookupByLibrary.simpleMessage(
      "Context compacted",
    ),
    "contextWindow": MessageLookupByLibrary.simpleMessage("Context window"),
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
      "Conversation summary",
    ),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage(
      "Token share by conversation",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("Copy API Key"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m12,
    "createChatFailed": m13,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Creation Time"),
    "customProvider": MessageLookupByLibrary.simpleMessage(
      "Custom Provider...",
    ),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage("Daily usage"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dark Mode"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "This database was created by a newer version of Stars. Update the app before opening it.",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "The database integrity check failed, and recovery from this version\'s backup was unsuccessful.",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage("Deep Thinking"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "You are a helpful AI assistant.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("Delete Bot"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("Delete Chat"),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "About & Legal",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "Appearance & Language",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "Change your avatar and display name.",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("General"),
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
    "details": MessageLookupByLibrary.simpleMessage("Details"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Disable no confirmation for all",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Disable all Tools",
    ),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Disable scripts",
    ),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editBot": MessageLookupByLibrary.simpleMessage("Edit Bot"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("Edit memory"),
    "editName": MessageLookupByLibrary.simpleMessage("Edit Name"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "Failed to get response: Server returned empty response",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "Enable no confirmation for all",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "Enable all Tools",
    ),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "Enable scripts",
    ),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "Enable isolated Skill scripts?",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "Enter API address...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("Enter API key..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("Enter bot name..."),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage(
      "Enter a display name",
    ),
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
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage(
      "Estimated usage",
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
    "feedbackInformation": MessageLookupByLibrary.simpleMessage(
      "Feedback Information",
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
    "forgetMemory": MessageLookupByLibrary.simpleMessage("Forget"),
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
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage("Hourly usage"),
    "htmlPreview": MessageLookupByLibrary.simpleMessage("HTML preview"),
    "idle": MessageLookupByLibrary.simpleMessage("Idle"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage("Import folder"),
    "importSkillZip": MessageLookupByLibrary.simpleMessage("Import ZIP"),
    "importingSkill": MessageLookupByLibrary.simpleMessage("Importing…"),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("Input tokens"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage(
      "Install update",
    ),
    "invalidSummary": MessageLookupByLibrary.simpleMessage(
      "The generated summary did not pass validation",
    ),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("Just now"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage(
      "Language Settings",
    ),
    "lightMode": MessageLookupByLibrary.simpleMessage("Light Mode"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("Manage memory"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("Per message"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "Select the Skill from the message composer when needed.",
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
      "No confirmation",
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
    "mcpServers": MessageLookupByLibrary.simpleMessage("MCP Servers"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Connect MCP Servers and discover their Tool catalogs. Configure Tools after creating an agent.",
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
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("Artifact"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "Memory changed; please retry",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("Correction"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("Decision"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("Fact"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("Preference"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("Open question"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("Task"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage("Type a message..."),
    "messageSkills": MessageLookupByLibrary.simpleMessage("Skills"),
    "minutesAgo": m27,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("Audio"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("File"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("Image"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("Multimodal"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("Music"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("Realtime"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("Speech"),
    "modalityText": MessageLookupByLibrary.simpleMessage("Text"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("Video"),
    "model": MessageLookupByLibrary.simpleMessage("Model"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "Model Configuration",
    ),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage(
      "Model Context Size",
    ),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("Input"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("Output"),
    "modelsRetrievedSuccess": m28,
    "modificationTime": MessageLookupByLibrary.simpleMessage(
      "Modification Time",
    ),
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
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "No connected MCP Tools are available.",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage("No Skills added"),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "Add the installed Skills this bot needs.",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "No bots available",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("No chats yet"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "No content returned",
    ),
    "noConversationFilesFound": MessageLookupByLibrary.simpleMessage(
      "No matching files or folders.",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "No conversation summary is available yet.",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "No matching bots found",
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
      "No matching skills found",
    ),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "No models retrieved",
    ),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage(
      "No Skills installed",
    ),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "Import an Agent Skills folder or ZIP containing SKILL.md.",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "No token usage recorded",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("Not supported"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "There is not enough older context to compact",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openLink": MessageLookupByLibrary.simpleMessage("Open link"),
    "openWithSystem": MessageLookupByLibrary.simpleMessage(
      "Open with system app",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("Output tokens"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("Partial response"),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("Pause audio"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("Pause generation"),
    "pinMemory": MessageLookupByLibrary.simpleMessage("Pin"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "Pin selected for this conversation",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("Pinned"),
    "playAudio": MessageLookupByLibrary.simpleMessage("Play audio"),
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
    "preview": MessageLookupByLibrary.simpleMessage("Preview"),
    "previewText": MessageLookupByLibrary.simpleMessage("Preview text effect"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "Process information",
    ),
    "processToolCount": m32,
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
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("Rebuild"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Refresh catalogs",
    ),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "Refreshing catalogs…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("Remove Skill"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("Reply cancelled"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "Stopped · Partial response kept",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("Reset to Default"),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("Restore"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage(
      "Recent turns retained",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage("Run test"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Save Changes"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("Saving..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("Search bots"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchConversationFiles": MessageLookupByLibrary.simpleMessage(
      "Search files and folders",
    ),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage("Search memory"),
    "searchSkills": MessageLookupByLibrary.simpleMessage("Search skills"),
    "selectBot": MessageLookupByLibrary.simpleMessage("Select Bot"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("Select Language"),
    "selectModel": MessageLookupByLibrary.simpleMessage("Select Model:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("Select Provider"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("Select Theme"),
    "send": MessageLookupByLibrary.simpleMessage("Send"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("Show API Key"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "Show execution details in conversation messages.",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage(
      "Assets available",
    ),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage("Compatibility"),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "This example should activate the Skill",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "Example user request",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage(
      "Activation result",
    ),
    "skillDetails": MessageLookupByLibrary.simpleMessage("Skill details"),
    "skillDigest": MessageLookupByLibrary.simpleMessage("Content digest"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("Disabled"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("Enabled"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("Files"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "Skill imported",
    ),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("Skills"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "Install reusable instructions and bind them to your bots.",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "This release does not execute Skill scripts or commands.",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("Publisher"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "Reference files available",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md is loaded only as controlled prompt guidance; scripts, commands, and external tools remain disabled.",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "Desktop script sandbox available",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "Scripts remain disabled per Skill until you approve them. Every invocation still requires approval and runs without network, home-directory, or inherited environment access.",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "Skill scripts unavailable",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "This platform does not provide the required isolated helper. Skill instructions and resources remain available, but scripts cannot run.",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "Skill script setting updated.",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "Scripts are installed but execution is disabled.",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage(
      "Scripts enabled",
    ),
    "skillSignature": MessageLookupByLibrary.simpleMessage("Signature"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage(
      "Invalid signature",
    ),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "Unknown publisher",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage("Unsigned"),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "Verified signature",
    ),
    "skillSource": MessageLookupByLibrary.simpleMessage("Source"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("Automatic"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "Update available",
    ),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("Manual"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("Notify"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("Pinned"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage("Update policy"),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("User"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage(
      "Validation notes",
    ),
    "skillVersion": MessageLookupByLibrary.simpleMessage("Version"),
    "sourceCode": MessageLookupByLibrary.simpleMessage("Source code"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "Type a message in the input box below to start chatting",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("Start chatting"),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "Startup failed. Please try again.",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage("Starting…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("Activated"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("Attached"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage(
      "Awaiting approval",
    ),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("Completed"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("Denied"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage("Duplicate call"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("Failed"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("Generated"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("In progress"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("Recorded"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("Requested"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("Running"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("Skipped"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("Timed out"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
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
    "summarizedTurns": MessageLookupByLibrary.simpleMessage(
      "Messages summarized",
    ),
    "supported": MessageLookupByLibrary.simpleMessage("Supported"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("Supports MCP"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage("Supports Skills"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("System Prompt"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("Test"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage(
      "Test description",
    ),
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
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("Thinking…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("Token usage"),
    "tokens": MessageLookupByLibrary.simpleMessage("tokens"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage(
      "Allowed once",
    ),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("Denied"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("Tool calls"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("Destructive"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("Read only"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("Write"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("Built-in"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage(
      "Skill script",
    ),
    "totalTokens": MessageLookupByLibrary.simpleMessage("Total tokens"),
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
    "uninstall": MessageLookupByLibrary.simpleMessage("Uninstall"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage("Uninstall Skill"),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("Unpin"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "Unsupported image format. Choose a JPEG, PNG, GIF, BMP, or WebP image.",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("File"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("Image"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("User Agreement"),
    "version": MessageLookupByLibrary.simpleMessage("Version 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to load video",
    ),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("View summary"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
