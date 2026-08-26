// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Stars`
  String get appName {
    return Intl.message(
      'Stars',
      name: 'appName',
      desc: 'Application name',
      args: [],
    );
  }

  /// `Profile`
  String get profile {
    return Intl.message(
      'Profile',
      name: 'profile',
      desc: 'User profile',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: 'Settings',
      args: [],
    );
  }

  /// `About`
  String get about {
    return Intl.message('About', name: 'about', desc: 'About', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: 'Cancel button',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: 'Save button', args: []);
  }

  /// `Confirm`
  String get confirm {
    return Intl.message(
      'Confirm',
      name: 'confirm',
      desc: 'Confirm button',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: 'Home page', args: []);
  }

  /// `Chats`
  String get chats {
    return Intl.message('Chats', name: 'chats', desc: 'Chat list', args: []);
  }

  /// `New Chat`
  String get newChat {
    return Intl.message(
      'New Chat',
      name: 'newChat',
      desc: 'New chat',
      args: [],
    );
  }

  /// `Theme Settings`
  String get themeSettings {
    return Intl.message(
      'Theme Settings',
      name: 'themeSettings',
      desc: 'Theme settings',
      args: [],
    );
  }

  /// `Follow System`
  String get followSystem {
    return Intl.message(
      'Follow System',
      name: 'followSystem',
      desc: 'Follow system theme',
      args: [],
    );
  }

  /// `Light Mode`
  String get lightMode {
    return Intl.message(
      'Light Mode',
      name: 'lightMode',
      desc: 'Light mode',
      args: [],
    );
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message(
      'Dark Mode',
      name: 'darkMode',
      desc: 'Dark mode',
      args: [],
    );
  }

  /// `Language Settings`
  String get languageSettings {
    return Intl.message(
      'Language Settings',
      name: 'languageSettings',
      desc: 'Language settings',
      args: [],
    );
  }

  /// `Font Size`
  String get fontSizeSettings {
    return Intl.message(
      'Font Size',
      name: 'fontSizeSettings',
      desc: 'Font size settings',
      args: [],
    );
  }

  /// `Adjust app font size`
  String get adjustAppFontSize {
    return Intl.message(
      'Adjust app font size',
      name: 'adjustAppFontSize',
      desc: 'Adjust application font size',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: 'Name', args: []);
  }

  /// `Edit Name`
  String get editName {
    return Intl.message(
      'Edit Name',
      name: 'editName',
      desc: 'Edit name',
      args: [],
    );
  }

  /// `Please enter new name`
  String get enterNewName {
    return Intl.message(
      'Please enter new name',
      name: 'enterNewName',
      desc: 'Please enter new name',
      args: [],
    );
  }

  /// `Name updated`
  String get nameUpdated {
    return Intl.message(
      'Name updated',
      name: 'nameUpdated',
      desc: 'Name has been updated',
      args: [],
    );
  }

  /// `Send`
  String get send {
    return Intl.message('Send', name: 'send', desc: 'Send button', args: []);
  }

  /// `Typing...`
  String get typing {
    return Intl.message(
      'Typing...',
      name: 'typing',
      desc: 'Typing indicator',
      args: [],
    );
  }

  /// `Clear Chat`
  String get clearChat {
    return Intl.message(
      'Clear Chat',
      name: 'clearChat',
      desc: 'Clear chat',
      args: [],
    );
  }

  /// `Add Bot`
  String get addBot {
    return Intl.message('Add Bot', name: 'addBot', desc: 'Add bot', args: []);
  }

  /// `Edit Bot`
  String get editBot {
    return Intl.message(
      'Edit Bot',
      name: 'editBot',
      desc: 'Edit bot',
      args: [],
    );
  }

  /// `Bot Name`
  String get botName {
    return Intl.message(
      'Bot Name',
      name: 'botName',
      desc: 'Bot name',
      args: [],
    );
  }

  /// `Bot Avatar`
  String get botAvatar {
    return Intl.message(
      'Bot Avatar',
      name: 'botAvatar',
      desc: 'Bot avatar',
      args: [],
    );
  }

  /// `Provider`
  String get provider {
    return Intl.message(
      'Provider',
      name: 'provider',
      desc: 'Provider',
      args: [],
    );
  }

  /// `API Key`
  String get apiKey {
    return Intl.message('API Key', name: 'apiKey', desc: 'API key', args: []);
  }

  /// `Model`
  String get model {
    return Intl.message('Model', name: 'model', desc: 'Model', args: []);
  }

  /// `System Prompt`
  String get systemPrompt {
    return Intl.message(
      'System Prompt',
      name: 'systemPrompt',
      desc: 'System prompt',
      args: [],
    );
  }

  /// `Language set to {language}`
  String languageChanged(String language) {
    return Intl.message(
      'Language set to $language',
      name: 'languageChanged',
      desc: 'Language changed notification',
      args: [language],
    );
  }

  /// `Select Language`
  String get selectLanguage {
    return Intl.message(
      'Select Language',
      name: 'selectLanguage',
      desc: 'Select language',
      args: [],
    );
  }

  /// `Select Theme`
  String get selectTheme {
    return Intl.message(
      'Select Theme',
      name: 'selectTheme',
      desc: 'Select theme',
      args: [],
    );
  }

  /// `Adjust Font Size`
  String get adjustFontSize {
    return Intl.message(
      'Adjust Font Size',
      name: 'adjustFontSize',
      desc: 'Adjust font size',
      args: [],
    );
  }

  /// `Preview text effect`
  String get previewText {
    return Intl.message(
      'Preview text effect',
      name: 'previewText',
      desc: 'Preview text effect',
      args: [],
    );
  }

  /// `Font size updated`
  String get fontSizeUpdated {
    return Intl.message(
      'Font size updated',
      name: 'fontSizeUpdated',
      desc: 'Font size has been updated',
      args: [],
    );
  }

  /// `Theme set to follow system`
  String get themeSetToSystem {
    return Intl.message(
      'Theme set to follow system',
      name: 'themeSetToSystem',
      desc: 'Theme set to follow system',
      args: [],
    );
  }

  /// `Theme set to light mode`
  String get themeSetToLight {
    return Intl.message(
      'Theme set to light mode',
      name: 'themeSetToLight',
      desc: 'Theme set to light mode',
      args: [],
    );
  }

  /// `Theme set to dark mode`
  String get themeSetToDark {
    return Intl.message(
      'Theme set to dark mode',
      name: 'themeSetToDark',
      desc: 'Theme set to dark mode',
      args: [],
    );
  }

  /// `About Stars`
  String get aboutApp {
    return Intl.message(
      'About Stars',
      name: 'aboutApp',
      desc: 'About the app',
      args: [],
    );
  }

  /// `A simple yet powerful AI chat application that lets you chat with AI anytime, anywhere.`
  String get appDescription {
    return Intl.message(
      'A simple yet powerful AI chat application that lets you chat with AI anytime, anywhere.',
      name: 'appDescription',
      desc: 'App description',
      args: [],
    );
  }

  /// `© {year} Stars Team`
  String copyright(int year) {
    return Intl.message(
      '© $year Stars Team',
      name: 'copyright',
      desc: 'Copyright information',
      args: [year],
    );
  }

  /// `User Agreement`
  String get userAgreement {
    return Intl.message(
      'User Agreement',
      name: 'userAgreement',
      desc: 'User agreement',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: 'Privacy policy',
      args: [],
    );
  }

  /// `Version 1.0.0`
  String get version {
    return Intl.message(
      'Version 1.0.0',
      name: 'version',
      desc: 'Version information',
      args: [],
    );
  }

  /// `Stars - AI Chat Assistant`
  String get appTitle {
    return Intl.message(
      'Stars - AI Chat Assistant',
      name: 'appTitle',
      desc: 'App title',
      args: [],
    );
  }

  /// `Bots`
  String get Bots {
    return Intl.message('Bots', name: 'Bots', desc: 'Bots', args: []);
  }

  /// `Select Bot`
  String get selectBot {
    return Intl.message(
      'Select Bot',
      name: 'selectBot',
      desc: 'Select bot',
      args: [],
    );
  }

  /// `No bots available`
  String get noBotsAvailable {
    return Intl.message(
      'No bots available',
      name: 'noBotsAvailable',
      desc: 'No bots available',
      args: [],
    );
  }

  /// `Click + in the top right to create a new bot`
  String get clickToCreateBot {
    return Intl.message(
      'Click + in the top right to create a new bot',
      name: 'clickToCreateBot',
      desc: 'Click to create bot prompt',
      args: [],
    );
  }

  /// `No chats yet`
  String get noChats {
    return Intl.message(
      'No chats yet',
      name: 'noChats',
      desc: 'No chats yet',
      args: [],
    );
  }

  /// `Click New Chat to create a conversation`
  String get clickToStartChat {
    return Intl.message(
      'Click New Chat to create a conversation',
      name: 'clickToStartChat',
      desc: 'Click to start chat prompt',
      args: [],
    );
  }

  /// `Delete Chat`
  String get deleteChat {
    return Intl.message(
      'Delete Chat',
      name: 'deleteChat',
      desc: 'Delete chat',
      args: [],
    );
  }

  /// `Type a message...`
  String get messageHint {
    return Intl.message(
      'Type a message...',
      name: 'messageHint',
      desc: 'Message input hint',
      args: [],
    );
  }

  /// `Error loading content, please try again later.`
  String get errorLoadingContent {
    return Intl.message(
      'Error loading content, please try again later.',
      name: 'errorLoadingContent',
      desc: 'Error message when content fails to load',
      args: [],
    );
  }

  /// `Please enter API key first`
  String get pleaseEnterApiKey {
    return Intl.message(
      'Please enter API key first',
      name: 'pleaseEnterApiKey',
      desc: 'Prompt user to enter API key',
      args: [],
    );
  }

  /// `Enter bot name...`
  String get enterBotName {
    return Intl.message(
      'Enter bot name...',
      name: 'enterBotName',
      desc: 'Prompt user to enter bot name',
      args: [],
    );
  }

  /// `Enter provider name...`
  String get enterProviderName {
    return Intl.message(
      'Enter provider name...',
      name: 'enterProviderName',
      desc: 'Prompt user to enter custom provider name',
      args: [],
    );
  }

  /// `Select Provider`
  String get selectProvider {
    return Intl.message(
      'Select Provider',
      name: 'selectProvider',
      desc: 'Label for selecting AI service provider',
      args: [],
    );
  }

  /// `Custom Provider...`
  String get customProvider {
    return Intl.message(
      'Custom Provider...',
      name: 'customProvider',
      desc: 'Option for custom AI service provider',
      args: [],
    );
  }

  /// `API Type`
  String get apiType {
    return Intl.message(
      'API Type',
      name: 'apiType',
      desc: 'Label for API type selection',
      args: [],
    );
  }

  /// `API Address`
  String get apiAddress {
    return Intl.message(
      'API Address',
      name: 'apiAddress',
      desc: 'Label for API address input',
      args: [],
    );
  }

  /// `Enter API address...`
  String get enterApiAddress {
    return Intl.message(
      'Enter API address...',
      name: 'enterApiAddress',
      desc: 'Prompt user to enter API address',
      args: [],
    );
  }

  /// `Enter API key...`
  String get enterApiKey {
    return Intl.message(
      'Enter API key...',
      name: 'enterApiKey',
      desc: 'Prompt user to enter API key',
      args: [],
    );
  }

  /// `Please fetch model list first`
  String get fetchModelListFirst {
    return Intl.message(
      'Please fetch model list first',
      name: 'fetchModelListFirst',
      desc: 'Prompt user to fetch model list first',
      args: [],
    );
  }

  /// `Fetch Model List`
  String get fetchModelList {
    return Intl.message(
      'Fetch Model List',
      name: 'fetchModelList',
      desc: 'Tooltip for fetch model list button',
      args: [],
    );
  }

  /// `Select Model:`
  String get selectModel {
    return Intl.message(
      'Select Model:',
      name: 'selectModel',
      desc: 'Label for model selection',
      args: [],
    );
  }

  /// `Enter system prompt...`
  String get enterSystemPrompt {
    return Intl.message(
      'Enter system prompt...',
      name: 'enterSystemPrompt',
      desc: 'Hint text for system prompt input field',
      args: [],
    );
  }

  /// `You are a helpful AI assistant.`
  String get defaultSystemPrompt {
    return Intl.message(
      'You are a helpful AI assistant.',
      name: 'defaultSystemPrompt',
      desc: 'Default system prompt',
      args: [],
    );
  }

  /// `Bot "{name}" has been added`
  String botAddedSuccess(String name) {
    return Intl.message(
      'Bot "$name" has been added',
      name: 'botAddedSuccess',
      desc: 'Success message when a bot is added',
      args: [name],
    );
  }

  /// `Please fill in bot name, API address and API key`
  String get fillRequiredFields {
    return Intl.message(
      'Please fill in bot name, API address and API key',
      name: 'fillRequiredFields',
      desc: 'Prompt user to fill in required fields',
      args: [],
    );
  }

  /// `Help & Feedback`
  String get helpAndFeedback {
    return Intl.message(
      'Help & Feedback',
      name: 'helpAndFeedback',
      desc: 'Help and feedback option',
      args: [],
    );
  }

  /// `Provide your suggestions and feedback`
  String get provideFeedback {
    return Intl.message(
      'Provide your suggestions and feedback',
      name: 'provideFeedback',
      desc: 'Description for providing feedback',
      args: [],
    );
  }

  /// `Feedback Information`
  String get feedbackInformation {
    return Intl.message(
      'Feedback Information',
      name: 'feedbackInformation',
      desc: 'Feedback form section title',
      args: [],
    );
  }

  /// `Please tell us your thoughts, issues, or suggestions to help us improve the app`
  String get feedbackDescription {
    return Intl.message(
      'Please tell us your thoughts, issues, or suggestions to help us improve the app',
      name: 'feedbackDescription',
      desc: 'Feedback page description',
      args: [],
    );
  }

  /// `Enter your feedback here...`
  String get feedbackHint {
    return Intl.message(
      'Enter your feedback here...',
      name: 'feedbackHint',
      desc: 'Feedback input hint',
      args: [],
    );
  }

  /// `Contact information (optional)`
  String get contactInfoHint {
    return Intl.message(
      'Contact information (optional)',
      name: 'contactInfoHint',
      desc: 'Contact information input hint',
      args: [],
    );
  }

  /// `Submit Feedback`
  String get submitFeedback {
    return Intl.message(
      'Submit Feedback',
      name: 'submitFeedback',
      desc: 'Submit feedback button',
      args: [],
    );
  }

  /// `Thank you for your feedback!`
  String get feedbackSubmitted {
    return Intl.message(
      'Thank you for your feedback!',
      name: 'feedbackSubmitted',
      desc: 'Feedback submission success message',
      args: [],
    );
  }

  /// `Submission failed, please try again later`
  String get feedbackSubmitError {
    return Intl.message(
      'Submission failed, please try again later',
      name: 'feedbackSubmitError',
      desc: 'Feedback submission error message',
      args: [],
    );
  }

  /// `Please enter feedback content`
  String get feedbackContentRequired {
    return Intl.message(
      'Please enter feedback content',
      name: 'feedbackContentRequired',
      desc: 'Feedback content required message',
      args: [],
    );
  }

  /// `Failed to get response: Server returned empty response`
  String get emptyResponseError {
    return Intl.message(
      'Failed to get response: Server returned empty response',
      name: 'emptyResponseError',
      desc: 'Failed to get response: Server returned empty response',
      args: [],
    );
  }

  /// `Failed to get response: {error}`
  String responseError(String error) {
    return Intl.message(
      'Failed to get response: $error',
      name: 'responseError',
      desc: 'Failed to get response',
      args: [error],
    );
  }

  /// `Clear chat history`
  String get clearChatHistory {
    return Intl.message(
      'Clear chat history',
      name: 'clearChatHistory',
      desc: 'Clear chat history',
      args: [],
    );
  }

  /// `{minutes} minutes ago`
  String minutesAgo(int minutes) {
    return Intl.message(
      '$minutes minutes ago',
      name: 'minutesAgo',
      desc: '',
      args: [minutes],
    );
  }

  /// `Just now`
  String get justNow {
    return Intl.message(
      'Just now',
      name: 'justNow',
      desc: 'Just now',
      args: [],
    );
  }

  /// `Chat with {botName} deleted`
  String chatDeleted(String botName) {
    return Intl.message(
      'Chat with $botName deleted',
      name: 'chatDeleted',
      desc: '',
      args: [botName],
    );
  }

  /// `Start chatting`
  String get startChatting {
    return Intl.message(
      'Start chatting',
      name: 'startChatting',
      desc: 'Start chatting',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: 'Delete', args: []);
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Deleting this chat will clear all chat history. Are you sure you want to delete the chat with {botName}?`
  String confirmDeleteChat(String botName) {
    return Intl.message(
      'Deleting this chat will clear all chat history. Are you sure you want to delete the chat with $botName?',
      name: 'confirmDeleteChat',
      desc: '',
      args: [botName],
    );
  }

  /// `Delete Bot`
  String get deleteBot {
    return Intl.message(
      'Delete Bot',
      name: 'deleteBot',
      desc: 'Delete bot',
      args: [],
    );
  }

  /// `Deleting this bot will also delete all associated chat history. Are you sure you want to delete {botName}?`
  String confirmDeleteBot(String botName) {
    return Intl.message(
      'Deleting this bot will also delete all associated chat history. Are you sure you want to delete $botName?',
      name: 'confirmDeleteBot',
      desc: '',
      args: [botName],
    );
  }

  /// `Save Changes`
  String get saveChanges {
    return Intl.message(
      'Save Changes',
      name: 'saveChanges',
      desc: 'Save changes button',
      args: [],
    );
  }

  /// `Saving...`
  String get savingChanges {
    return Intl.message(
      'Saving...',
      name: 'savingChanges',
      desc: 'Status shown while bot changes are being saved',
      args: [],
    );
  }

  /// `Saved`
  String get changesSaved {
    return Intl.message(
      'Saved',
      name: 'changesSaved',
      desc: 'Status shown after bot changes are saved',
      args: [],
    );
  }

  /// `Bot {botName} has been updated`
  String botUpdated(String botName) {
    return Intl.message(
      'Bot $botName has been updated',
      name: 'botUpdated',
      desc: '',
      args: [botName],
    );
  }

  /// `Hello! I'm {botName}, an AI assistant. Feel free to ask me anything, and I'll do my best to help you.`
  String botGreeting(String botName) {
    return Intl.message(
      'Hello! I\'m $botName, an AI assistant. Feel free to ask me anything, and I\'ll do my best to help you.',
      name: 'botGreeting',
      desc: 'Greeting message from the AI assistant',
      args: [botName],
    );
  }

  /// `Type a message in the input box below to start chatting`
  String get startChatPrompt {
    return Intl.message(
      'Type a message in the input box below to start chatting',
      name: 'startChatPrompt',
      desc: 'Text prompting user to start chatting in the input box',
      args: [],
    );
  }

  /// `{botName} is typing...`
  String botIsTyping(String botName) {
    return Intl.message(
      '$botName is typing...',
      name: 'botIsTyping',
      desc: 'Indicates that the AI assistant is typing a message',
      args: [botName],
    );
  }

  /// `Pause generation`
  String get pauseGeneration {
    return Intl.message(
      'Pause generation',
      name: 'pauseGeneration',
      desc: 'Tooltip for the button to pause AI response generation',
      args: [],
    );
  }

  /// `Are you sure you want to clear all chat history with "{botName}"? This action cannot be undone.`
  String confirmClearChat(String botName) {
    return Intl.message(
      'Are you sure you want to clear all chat history with "$botName"? This action cannot be undone.',
      name: 'confirmClearChat',
      desc: 'Confirmation text for clearing chat history',
      args: [botName],
    );
  }

  /// `Chat history cleared`
  String get chatHistoryCleared {
    return Intl.message(
      'Chat history cleared',
      name: 'chatHistoryCleared',
      desc: 'Notification shown after chat history is cleared',
      args: [],
    );
  }

  /// `Reply cancelled`
  String get replyCancelled {
    return Intl.message(
      'Reply cancelled',
      name: 'replyCancelled',
      desc: 'Notification shown after cancelling AI reply generation',
      args: [],
    );
  }

  /// `Clear`
  String get clear {
    return Intl.message(
      'Clear',
      name: 'clear',
      desc: 'Text for the button to clear chat history',
      args: [],
    );
  }

  /// `Confirm Delete`
  String get confirmDelete {
    return Intl.message(
      'Confirm Delete',
      name: 'confirmDelete',
      desc: 'Text for the confirmation dialog when deleting a chat or bot',
      args: [],
    );
  }

  /// `"{botName}" has been deleted`
  String botDeleted(String botName) {
    return Intl.message(
      '"$botName" has been deleted',
      name: 'botDeleted',
      desc: 'Notification shown after a bot is deleted',
      args: [botName],
    );
  }

  /// `Successfully retrieved {count} models`
  String modelsRetrievedSuccess(String count) {
    return Intl.message(
      'Successfully retrieved $count models',
      name: 'modelsRetrievedSuccess',
      desc: 'Success message when models are retrieved',
      args: [count],
    );
  }

  /// `No models retrieved`
  String get noModelsRetrieved {
    return Intl.message(
      'No models retrieved',
      name: 'noModelsRetrieved',
      desc: 'Message when no models are retrieved',
      args: [],
    );
  }

  /// `Message copied to clipboard`
  String get messageCopied {
    return Intl.message(
      'Message copied to clipboard',
      name: 'messageCopied',
      desc: 'Notification when message is copied',
      args: [],
    );
  }

  /// `Web Search`
  String get webSearch {
    return Intl.message(
      'Web Search',
      name: 'webSearch',
      desc: 'Button text for web search feature',
      args: [],
    );
  }

  /// `Deep Thinking`
  String get deepThinking {
    return Intl.message(
      'Deep Thinking',
      name: 'deepThinking',
      desc: 'Button text for deep thinking feature',
      args: [],
    );
  }

  /// `Image`
  String get uploadImage {
    return Intl.message(
      'Image',
      name: 'uploadImage',
      desc: 'Upload image button text',
      args: [],
    );
  }

  /// `File`
  String get uploadFile {
    return Intl.message(
      'File',
      name: 'uploadFile',
      desc: 'Upload file button text',
      args: [],
    );
  }

  /// `Play audio`
  String get playAudio {
    return Intl.message(
      'Play audio',
      name: 'playAudio',
      desc: 'Play audio button tooltip',
      args: [],
    );
  }

  /// `Pause audio`
  String get pauseAudio {
    return Intl.message(
      'Pause audio',
      name: 'pauseAudio',
      desc: 'Pause audio button tooltip',
      args: [],
    );
  }

  /// `Camera`
  String get takePhoto {
    return Intl.message(
      'Camera',
      name: 'takePhoto',
      desc: 'Take photo option text',
      args: [],
    );
  }

  /// `Gallery`
  String get chooseFromGallery {
    return Intl.message(
      'Gallery',
      name: 'chooseFromGallery',
      desc: 'Choose from gallery option text',
      args: [],
    );
  }

  /// `Attachment`
  String get addAttachment {
    return Intl.message(
      'Attachment',
      name: 'addAttachment',
      desc: 'Add attachment button text',
      args: [],
    );
  }

  /// `Attached Images`
  String get attachedImages {
    return Intl.message(
      'Attached Images',
      name: 'attachedImages',
      desc: 'Text for attached images',
      args: [],
    );
  }

  /// `Attached Files`
  String get attachedFiles {
    return Intl.message(
      'Attached Files',
      name: 'attachedFiles',
      desc: 'Label for attached files',
      args: [],
    );
  }

  /// `Please enter a description for image generation`
  String get pleaseEnterImageDescription {
    return Intl.message(
      'Please enter a description for image generation',
      name: 'pleaseEnterImageDescription',
      desc: 'Prompt for entering description for image generation',
      args: [],
    );
  }

  /// `Generate image failed: {error}`
  String generateImageFailed(String error) {
    return Intl.message(
      'Generate image failed: $error',
      name: 'generateImageFailed',
      desc: 'Error message when image generation fails',
      args: [error],
    );
  }

  /// `Generating image, please wait...`
  String get generatingImage {
    return Intl.message(
      'Generating image, please wait...',
      name: 'generatingImage',
      desc: 'Message while image is being generated',
      args: [],
    );
  }

  /// `Image generated`
  String get generatedImage {
    return Intl.message(
      'Image generated',
      name: 'generatedImage',
      desc: 'Message when image is generated',
      args: [],
    );
  }

  /// `No matching chats found`
  String get noMatchingChats {
    return Intl.message(
      'No matching chats found',
      name: 'noMatchingChats',
      desc: 'Message when no matching chats are found',
      args: [],
    );
  }

  /// `Search conversations`
  String get searchChats {
    return Intl.message(
      'Search conversations',
      name: 'searchChats',
      desc: 'Hint text for chat search field',
      args: [],
    );
  }

  /// `Search bots`
  String get searchBots {
    return Intl.message(
      'Search bots',
      name: 'searchBots',
      desc: 'Hint text for bot search field',
      args: [],
    );
  }

  /// `Personal Information`
  String get desktopPersonalInformation {
    return Intl.message(
      'Personal Information',
      name: 'desktopPersonalInformation',
      desc: '',
      args: [],
    );
  }

  /// `Appearance & Language`
  String get desktopAppearanceAndLanguage {
    return Intl.message(
      'Appearance & Language',
      name: 'desktopAppearanceAndLanguage',
      desc: '',
      args: [],
    );
  }

  /// `General`
  String get desktopGeneral {
    return Intl.message('General', name: 'desktopGeneral', desc: '', args: []);
  }

  /// `System prompt`
  String get applicationInjectedPrompt {
    return Intl.message(
      'System prompt',
      name: 'applicationInjectedPrompt',
      desc: '',
      args: [],
    );
  }

  /// `Managed by Stars and added to every model-facing system prompt. Current agent and conversation identifiers are added at runtime and cannot be edited.`
  String get applicationInjectedPromptDescription {
    return Intl.message(
      'Managed by Stars and added to every model-facing system prompt. Current agent and conversation identifiers are added at runtime and cannot be edited.',
      name: 'applicationInjectedPromptDescription',
      desc: '',
      args: [],
    );
  }

  /// `Help & Support`
  String get desktopHelpAndSupport {
    return Intl.message(
      'Help & Support',
      name: 'desktopHelpAndSupport',
      desc: '',
      args: [],
    );
  }

  /// `About & Legal`
  String get desktopAboutAndLegal {
    return Intl.message(
      'About & Legal',
      name: 'desktopAboutAndLegal',
      desc: '',
      args: [],
    );
  }

  /// `Manage your profile, appearance, language, and app support.`
  String get desktopSettingsDescription {
    return Intl.message(
      'Manage your profile, appearance, language, and app support.',
      name: 'desktopSettingsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Change your avatar and display name.`
  String get desktopEditProfileDescription {
    return Intl.message(
      'Change your avatar and display name.',
      name: 'desktopEditProfileDescription',
      desc: '',
      args: [],
    );
  }

  /// `Changes take effect immediately and are saved locally.`
  String get desktopSavedImmediatelyDescription {
    return Intl.message(
      'Changes take effect immediately and are saved locally.',
      name: 'desktopSavedImmediatelyDescription',
      desc: '',
      args: [],
    );
  }

  /// `Chat execution status`
  String get chatExecutionStatus {
    return Intl.message(
      'Chat execution status',
      name: 'chatExecutionStatus',
      desc: '',
      args: [],
    );
  }

  /// `Show execution details in conversation messages.`
  String get showExecutionStatusDescription {
    return Intl.message(
      'Show execution details in conversation messages.',
      name: 'showExecutionStatusDescription',
      desc: '',
      args: [],
    );
  }

  /// `Change avatar`
  String get changeAvatar {
    return Intl.message(
      'Change avatar',
      name: 'changeAvatar',
      desc: '',
      args: [],
    );
  }

  /// `Reset to Default`
  String get resetToDefault {
    return Intl.message(
      'Reset to Default',
      name: 'resetToDefault',
      desc: '',
      args: [],
    );
  }

  /// `Hide Sidebar`
  String get hideSidebar {
    return Intl.message(
      'Hide Sidebar',
      name: 'hideSidebar',
      desc: '',
      args: [],
    );
  }

  /// `Show Sidebar`
  String get showSidebar {
    return Intl.message(
      'Show Sidebar',
      name: 'showSidebar',
      desc: '',
      args: [],
    );
  }

  /// `Hide Bot Info`
  String get hideInspector {
    return Intl.message(
      'Hide Bot Info',
      name: 'hideInspector',
      desc: '',
      args: [],
    );
  }

  /// `Show Bot Info`
  String get showInspector {
    return Intl.message(
      'Show Bot Info',
      name: 'showInspector',
      desc: '',
      args: [],
    );
  }

  /// `Bot Information`
  String get botInformation {
    return Intl.message(
      'Bot Information',
      name: 'botInformation',
      desc: '',
      args: [],
    );
  }

  /// `Jump to Latest`
  String get jumpToLatest {
    return Intl.message(
      'Jump to Latest',
      name: 'jumpToLatest',
      desc: '',
      args: [],
    );
  }

  /// `Image Style`
  String get imageStyle {
    return Intl.message('Image Style', name: 'imageStyle', desc: '', args: []);
  }

  /// `Image Size`
  String get imageSize {
    return Intl.message('Image Size', name: 'imageSize', desc: '', args: []);
  }

  /// `Stop`
  String get stop {
    return Intl.message('Stop', name: 'stop', desc: '', args: []);
  }

  /// `Generating…`
  String get generating {
    return Intl.message(
      'Generating…',
      name: 'generating',
      desc:
          'Disabled primary action label while a request is running and cannot be cancelled',
      args: [],
    );
  }

  /// `Stopping…`
  String get stopping {
    return Intl.message(
      'Stopping…',
      name: 'stopping',
      desc:
          'Disabled primary action label while cancellation is being confirmed',
      args: [],
    );
  }

  /// `Basic Information`
  String get basicInformation {
    return Intl.message(
      'Basic Information',
      name: 'basicInformation',
      desc: '',
      args: [],
    );
  }

  /// `Creation Time`
  String get creationTime {
    return Intl.message(
      'Creation Time',
      name: 'creationTime',
      desc: '',
      args: [],
    );
  }

  /// `Modification Time`
  String get modificationTime {
    return Intl.message(
      'Modification Time',
      name: 'modificationTime',
      desc: '',
      args: [],
    );
  }

  /// `Provider Information`
  String get providerInformation {
    return Intl.message(
      'Provider Information',
      name: 'providerInformation',
      desc: '',
      args: [],
    );
  }

  /// `Model Configuration`
  String get modelConfiguration {
    return Intl.message(
      'Model Configuration',
      name: 'modelConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Model Context Size`
  String get modelContextWindow {
    return Intl.message(
      'Model Context Size',
      name: 'modelContextWindow',
      desc: '',
      args: [],
    );
  }

  /// `Input`
  String get modelInputModalities {
    return Intl.message(
      'Input',
      name: 'modelInputModalities',
      desc: '',
      args: [],
    );
  }

  /// `Output`
  String get modelOutputModalities {
    return Intl.message(
      'Output',
      name: 'modelOutputModalities',
      desc: '',
      args: [],
    );
  }

  /// `Text`
  String get modalityText {
    return Intl.message('Text', name: 'modalityText', desc: '', args: []);
  }

  /// `Image`
  String get modalityImage {
    return Intl.message('Image', name: 'modalityImage', desc: '', args: []);
  }

  /// `File`
  String get modalityFile {
    return Intl.message('File', name: 'modalityFile', desc: '', args: []);
  }

  /// `Audio`
  String get modalityAudio {
    return Intl.message('Audio', name: 'modalityAudio', desc: '', args: []);
  }

  /// `Video`
  String get modalityVideo {
    return Intl.message('Video', name: 'modalityVideo', desc: '', args: []);
  }

  /// `Realtime`
  String get modalityRealtime {
    return Intl.message(
      'Realtime',
      name: 'modalityRealtime',
      desc: '',
      args: [],
    );
  }

  /// `Speech`
  String get modalitySpeech {
    return Intl.message('Speech', name: 'modalitySpeech', desc: '', args: []);
  }

  /// `Music`
  String get modalityMusic {
    return Intl.message('Music', name: 'modalityMusic', desc: '', args: []);
  }

  /// `Multimodal`
  String get modalityMulti {
    return Intl.message(
      'Multimodal',
      name: 'modalityMulti',
      desc: '',
      args: [],
    );
  }

  /// `Supports Skills`
  String get supportsSkills {
    return Intl.message(
      'Supports Skills',
      name: 'supportsSkills',
      desc: '',
      args: [],
    );
  }

  /// `Supports MCP`
  String get supportsMcp {
    return Intl.message(
      'Supports MCP',
      name: 'supportsMcp',
      desc: '',
      args: [],
    );
  }

  /// `Supported`
  String get supported {
    return Intl.message('Supported', name: 'supported', desc: '', args: []);
  }

  /// `Not supported`
  String get notSupported {
    return Intl.message(
      'Not supported',
      name: 'notSupported',
      desc: '',
      args: [],
    );
  }

  /// `tokens`
  String get tokens {
    return Intl.message('tokens', name: 'tokens', desc: '', args: []);
  }

  /// `Copy API Key`
  String get copyApiKey {
    return Intl.message('Copy API Key', name: 'copyApiKey', desc: '', args: []);
  }

  /// `Show API Key`
  String get showApiKey {
    return Intl.message('Show API Key', name: 'showApiKey', desc: '', args: []);
  }

  /// `Hide API Key`
  String get hideApiKey {
    return Intl.message('Hide API Key', name: 'hideApiKey', desc: '', args: []);
  }

  /// `No matching bots found`
  String get noMatchingBots {
    return Intl.message(
      'No matching bots found',
      name: 'noMatchingBots',
      desc: '',
      args: [],
    );
  }

  /// `Try a different search, or create a new item.`
  String get tryDifferentSearch {
    return Intl.message(
      'Try a different search, or create a new item.',
      name: 'tryDifferentSearch',
      desc: '',
      args: [],
    );
  }

  /// `Search matches bot names and the latest message.`
  String get chatSearchScope {
    return Intl.message(
      'Search matches bot names and the latest message.',
      name: 'chatSearchScope',
      desc: '',
      args: [],
    );
  }

  /// `A new chat opens directly in the workspace.`
  String get newChatWorkspaceHint {
    return Intl.message(
      'A new chat opens directly in the workspace.',
      name: 'newChatWorkspaceHint',
      desc: '',
      args: [],
    );
  }

  /// `Search filters the list by bot name.`
  String get botSearchScope {
    return Intl.message(
      'Search filters the list by bot name.',
      name: 'botSearchScope',
      desc: '',
      args: [],
    );
  }

  /// `New bots remain in the workspace for editing.`
  String get newBotWorkspaceHint {
    return Intl.message(
      'New bots remain in the workspace for editing.',
      name: 'newBotWorkspaceHint',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retry {
    return Intl.message('Retry', name: 'retry', desc: '', args: []);
  }

  /// `Unable to load chats`
  String get unableToLoadChats {
    return Intl.message(
      'Unable to load chats',
      name: 'unableToLoadChats',
      desc: '',
      args: [],
    );
  }

  /// `Clear search`
  String get clearSearch {
    return Intl.message(
      'Clear search',
      name: 'clearSearch',
      desc: '',
      args: [],
    );
  }

  /// `Conversation data directory`
  String get conversationDirectory {
    return Intl.message(
      'Conversation data directory',
      name: 'conversationDirectory',
      desc: '',
      args: [],
    );
  }

  /// `Browse conversation data`
  String get browseConversationDirectory {
    return Intl.message(
      'Browse conversation data',
      name: 'browseConversationDirectory',
      desc: '',
      args: [],
    );
  }

  /// `Browse files and folders stored for this conversation.`
  String get conversationDirectoryDescription {
    return Intl.message(
      'Browse files and folders stored for this conversation.',
      name: 'conversationDirectoryDescription',
      desc: '',
      args: [],
    );
  }

  /// `Search files and folders`
  String get searchConversationFiles {
    return Intl.message(
      'Search files and folders',
      name: 'searchConversationFiles',
      desc: '',
      args: [],
    );
  }

  /// `This conversation directory is empty.`
  String get conversationDirectoryEmpty {
    return Intl.message(
      'This conversation directory is empty.',
      name: 'conversationDirectoryEmpty',
      desc: '',
      args: [],
    );
  }

  /// `No matching files or folders.`
  String get noConversationFilesFound {
    return Intl.message(
      'No matching files or folders.',
      name: 'noConversationFilesFound',
      desc: '',
      args: [],
    );
  }

  /// `Unavailable bot`
  String get unavailableBot {
    return Intl.message(
      'Unavailable bot',
      name: 'unavailableBot',
      desc: '',
      args: [],
    );
  }

  /// `This bot is unavailable`
  String get botUnavailableTitle {
    return Intl.message(
      'This bot is unavailable',
      name: 'botUnavailableTitle',
      desc: '',
      args: [],
    );
  }

  /// `Delete this orphaned chat or recreate the missing bot.`
  String get orphanedChatGuidance {
    return Intl.message(
      'Delete this orphaned chat or recreate the missing bot.',
      name: 'orphanedChatGuidance',
      desc: '',
      args: [],
    );
  }

  /// `The active request cannot be stopped`
  String get activeRequestCannotStop {
    return Intl.message(
      'The active request cannot be stopped',
      name: 'activeRequestCannotStop',
      desc: '',
      args: [],
    );
  }

  /// `Wait for generation to finish.`
  String get waitForGenerationToFinish {
    return Intl.message(
      'Wait for generation to finish.',
      name: 'waitForGenerationToFinish',
      desc: '',
      args: [],
    );
  }

  /// `Wait for generation to finish before leaving this chat.`
  String get waitForGenerationBeforeLeaving {
    return Intl.message(
      'Wait for generation to finish before leaving this chat.',
      name: 'waitForGenerationBeforeLeaving',
      desc: '',
      args: [],
    );
  }

  /// `The active request cannot be cancelled. Wait for it to finish.`
  String get activeRequestCannotCancel {
    return Intl.message(
      'The active request cannot be cancelled. Wait for it to finish.',
      name: 'activeRequestCannotCancel',
      desc: '',
      args: [],
    );
  }

  /// `Attachments`
  String get attachments {
    return Intl.message('Attachments', name: 'attachments', desc: '', args: []);
  }

  /// `{count} items`
  String itemCount(String count) {
    return Intl.message(
      '$count items',
      name: 'itemCount',
      desc: '',
      args: [count],
    );
  }

  /// `{count} files`
  String fileCount(String count) {
    return Intl.message(
      '$count files',
      name: 'fileCount',
      desc: '',
      args: [count],
    );
  }

  /// `Clear attachments`
  String get clearAttachments {
    return Intl.message(
      'Clear attachments',
      name: 'clearAttachments',
      desc: '',
      args: [],
    );
  }

  /// `Remove image`
  String get removeImageAttachment {
    return Intl.message(
      'Remove image',
      name: 'removeImageAttachment',
      desc: '',
      args: [],
    );
  }

  /// `Remove file`
  String get removeFileAttachment {
    return Intl.message(
      'Remove file',
      name: 'removeFileAttachment',
      desc: '',
      args: [],
    );
  }

  /// `Unsupported image format. Choose a JPEG, PNG, GIF, BMP, or WebP image.`
  String get unsupportedImageFormat {
    return Intl.message(
      'Unsupported image format. Choose a JPEG, PNG, GIF, BMP, or WebP image.',
      name: 'unsupportedImageFormat',
      desc: '',
      args: [],
    );
  }

  /// `Image attachment`
  String get imageAttachment {
    return Intl.message(
      'Image attachment',
      name: 'imageAttachment',
      desc: '',
      args: [],
    );
  }

  /// `Image result`
  String get imageResult {
    return Intl.message(
      'Image result',
      name: 'imageResult',
      desc: '',
      args: [],
    );
  }

  /// `File attachment`
  String get fileAttachment {
    return Intl.message(
      'File attachment',
      name: 'fileAttachment',
      desc: '',
      args: [],
    );
  }

  /// `File result`
  String get fileResult {
    return Intl.message('File result', name: 'fileResult', desc: '', args: []);
  }

  /// `Speech result`
  String get speechResult {
    return Intl.message(
      'Speech result',
      name: 'speechResult',
      desc: '',
      args: [],
    );
  }

  /// `Reference audio`
  String get referenceAudio {
    return Intl.message(
      'Reference audio',
      name: 'referenceAudio',
      desc: '',
      args: [],
    );
  }

  /// `Music result`
  String get musicResult {
    return Intl.message(
      'Music result',
      name: 'musicResult',
      desc: '',
      args: [],
    );
  }

  /// `Video result`
  String get videoResult {
    return Intl.message(
      'Video result',
      name: 'videoResult',
      desc: '',
      args: [],
    );
  }

  /// `Ready to play`
  String get directPlayback {
    return Intl.message(
      'Ready to play',
      name: 'directPlayback',
      desc: '',
      args: [],
    );
  }

  /// `Ready to preview`
  String get directPreview {
    return Intl.message(
      'Ready to preview',
      name: 'directPreview',
      desc: '',
      args: [],
    );
  }

  /// `Open file`
  String get openFile {
    return Intl.message('Open file', name: 'openFile', desc: '', args: []);
  }

  /// `Open with system app`
  String get openWithSystem {
    return Intl.message(
      'Open with system app',
      name: 'openWithSystem',
      desc: '',
      args: [],
    );
  }

  /// `Preview is not available for this file type. Open it with a system app.`
  String get filePreviewUnavailable {
    return Intl.message(
      'Preview is not available for this file type. Open it with a system app.',
      name: 'filePreviewUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Unable to open this file.`
  String get fileOpenFailed {
    return Intl.message(
      'Unable to open this file.',
      name: 'fileOpenFailed',
      desc: '',
      args: [],
    );
  }

  /// `This file no longer exists.`
  String get fileMissing {
    return Intl.message(
      'This file no longer exists.',
      name: 'fileMissing',
      desc: '',
      args: [],
    );
  }

  /// `Stopped · Partial response kept`
  String get replyStoppedPartial {
    return Intl.message(
      'Stopped · Partial response kept',
      name: 'replyStoppedPartial',
      desc: '',
      args: [],
    );
  }

  /// `Generation failed · Partial response kept`
  String get generationFailedPartial {
    return Intl.message(
      'Generation failed · Partial response kept',
      name: 'generationFailedPartial',
      desc: '',
      args: [],
    );
  }

  /// `Generation failed`
  String get generationFailed {
    return Intl.message(
      'Generation failed',
      name: 'generationFailed',
      desc: '',
      args: [],
    );
  }

  /// `No content returned`
  String get noContentReturned {
    return Intl.message(
      'No content returned',
      name: 'noContentReturned',
      desc: '',
      args: [],
    );
  }

  /// `Partial response`
  String get partialResponse {
    return Intl.message(
      'Partial response',
      name: 'partialResponse',
      desc: '',
      args: [],
    );
  }

  /// `Completed`
  String get statusCompleted {
    return Intl.message(
      'Completed',
      name: 'statusCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Save image`
  String get saveImage {
    return Intl.message('Save image', name: 'saveImage', desc: '', args: []);
  }

  /// `Share image`
  String get shareImage {
    return Intl.message('Share image', name: 'shareImage', desc: '', args: []);
  }

  /// `Could not save to gallery`
  String get saveToGalleryFailed {
    return Intl.message(
      'Could not save to gallery',
      name: 'saveToGalleryFailed',
      desc: '',
      args: [],
    );
  }

  /// `Image saved to gallery`
  String get imageSavedToGallery {
    return Intl.message(
      'Image saved to gallery',
      name: 'imageSavedToGallery',
      desc: '',
      args: [],
    );
  }

  /// `Could not save image: {error}`
  String saveImageFailed(String error) {
    return Intl.message(
      'Could not save image: $error',
      name: 'saveImageFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Could not share image: {error}`
  String shareImageFailed(String error) {
    return Intl.message(
      'Could not share image: $error',
      name: 'shareImageFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Image from Stars`
  String get sharedImageFromStars {
    return Intl.message(
      'Image from Stars',
      name: 'sharedImageFromStars',
      desc: '',
      args: [],
    );
  }

  /// `Duration {duration}`
  String processDuration(String duration) {
    return Intl.message(
      'Duration $duration',
      name: 'processDuration',
      desc: '',
      args: [duration],
    );
  }

  /// `{count} tool calls`
  String processToolCount(String count) {
    return Intl.message(
      '$count tool calls',
      name: 'processToolCount',
      desc: '',
      args: [count],
    );
  }

  /// `{count} command runs`
  String processCommandCount(String count) {
    return Intl.message(
      '$count command runs',
      name: 'processCommandCount',
      desc: '',
      args: [count],
    );
  }

  /// `{count} file updates`
  String processFileCount(String count) {
    return Intl.message(
      '$count file updates',
      name: 'processFileCount',
      desc: '',
      args: [count],
    );
  }

  /// `Execution status`
  String get executionStatus {
    return Intl.message(
      'Execution status',
      name: 'executionStatus',
      desc: '',
      args: [],
    );
  }

  /// `Tool calls`
  String get toolCalls {
    return Intl.message('Tool calls', name: 'toolCalls', desc: '', args: []);
  }

  /// `Command execution`
  String get commandExecutions {
    return Intl.message(
      'Command execution',
      name: 'commandExecutions',
      desc: '',
      args: [],
    );
  }

  /// `File status`
  String get fileStatus {
    return Intl.message('File status', name: 'fileStatus', desc: '', args: []);
  }

  /// `Includes duration`
  String get includesDuration {
    return Intl.message(
      'Includes duration',
      name: 'includesDuration',
      desc: '',
      args: [],
    );
  }

  /// `Structured process information`
  String get structuredProcessInfo {
    return Intl.message(
      'Structured process information',
      name: 'structuredProcessInfo',
      desc: '',
      args: [],
    );
  }

  /// `Generated`
  String get statusGenerated {
    return Intl.message(
      'Generated',
      name: 'statusGenerated',
      desc: '',
      args: [],
    );
  }

  /// `Attached`
  String get statusAttached {
    return Intl.message('Attached', name: 'statusAttached', desc: '', args: []);
  }

  /// `In progress`
  String get statusInProgress {
    return Intl.message(
      'In progress',
      name: 'statusInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Running`
  String get statusRunning {
    return Intl.message('Running', name: 'statusRunning', desc: '', args: []);
  }

  /// `Cancelled`
  String get statusCancelled {
    return Intl.message(
      'Cancelled',
      name: 'statusCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get statusFailed {
    return Intl.message('Failed', name: 'statusFailed', desc: '', args: []);
  }

  /// `Recorded`
  String get statusRecorded {
    return Intl.message('Recorded', name: 'statusRecorded', desc: '', args: []);
  }

  /// `Requested`
  String get statusRequested {
    return Intl.message(
      'Requested',
      name: 'statusRequested',
      desc: '',
      args: [],
    );
  }

  /// `Awaiting approval`
  String get statusAwaitingApproval {
    return Intl.message(
      'Awaiting approval',
      name: 'statusAwaitingApproval',
      desc: '',
      args: [],
    );
  }

  /// `Denied`
  String get statusDenied {
    return Intl.message('Denied', name: 'statusDenied', desc: '', args: []);
  }

  /// `Timed out`
  String get statusTimedOut {
    return Intl.message(
      'Timed out',
      name: 'statusTimedOut',
      desc: '',
      args: [],
    );
  }

  /// `Duplicate call`
  String get statusDuplicate {
    return Intl.message(
      'Duplicate call',
      name: 'statusDuplicate',
      desc: '',
      args: [],
    );
  }

  /// `Skipped`
  String get statusSkipped {
    return Intl.message('Skipped', name: 'statusSkipped', desc: '', args: []);
  }

  /// `Activated`
  String get statusActivated {
    return Intl.message(
      'Activated',
      name: 'statusActivated',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get statusUnknown {
    return Intl.message('Unknown', name: 'statusUnknown', desc: '', args: []);
  }

  /// `Built-in`
  String get toolSourceBuiltIn {
    return Intl.message(
      'Built-in',
      name: 'toolSourceBuiltIn',
      desc: '',
      args: [],
    );
  }

  /// `MCP`
  String get toolSourceMcp {
    return Intl.message('MCP', name: 'toolSourceMcp', desc: '', args: []);
  }

  /// `Skill script`
  String get toolSourceSkillScript {
    return Intl.message(
      'Skill script',
      name: 'toolSourceSkillScript',
      desc: '',
      args: [],
    );
  }

  /// `Read only`
  String get toolRiskReadOnly {
    return Intl.message(
      'Read only',
      name: 'toolRiskReadOnly',
      desc: '',
      args: [],
    );
  }

  /// `Write`
  String get toolRiskWrite {
    return Intl.message('Write', name: 'toolRiskWrite', desc: '', args: []);
  }

  /// `Destructive`
  String get toolRiskDestructive {
    return Intl.message(
      'Destructive',
      name: 'toolRiskDestructive',
      desc: '',
      args: [],
    );
  }

  /// `Allowed once`
  String get toolApprovalAllowOnce {
    return Intl.message(
      'Allowed once',
      name: 'toolApprovalAllowOnce',
      desc: '',
      args: [],
    );
  }

  /// `Denied`
  String get toolApprovalDenied {
    return Intl.message(
      'Denied',
      name: 'toolApprovalDenied',
      desc: '',
      args: [],
    );
  }

  /// `Reasoning complete`
  String get reasoningCompleted {
    return Intl.message(
      'Reasoning complete',
      name: 'reasoningCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Reasoning interrupted`
  String get reasoningInterrupted {
    return Intl.message(
      'Reasoning interrupted',
      name: 'reasoningInterrupted',
      desc: '',
      args: [],
    );
  }

  /// `Reasoning in progress`
  String get reasoningInProgress {
    return Intl.message(
      'Reasoning in progress',
      name: 'reasoningInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Process information`
  String get processInformation {
    return Intl.message(
      'Process information',
      name: 'processInformation',
      desc: '',
      args: [],
    );
  }

  /// `Speech`
  String get fileTypeSpeech {
    return Intl.message('Speech', name: 'fileTypeSpeech', desc: '', args: []);
  }

  /// `Music`
  String get fileTypeMusic {
    return Intl.message('Music', name: 'fileTypeMusic', desc: '', args: []);
  }

  /// `Video`
  String get fileTypeVideo {
    return Intl.message('Video', name: 'fileTypeVideo', desc: '', args: []);
  }

  /// `Thinking…`
  String get thinkingInProgress {
    return Intl.message(
      'Thinking…',
      name: 'thinkingInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Thinking complete`
  String get thinkingCompleted {
    return Intl.message(
      'Thinking complete',
      name: 'thinkingCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Thinking complete · {duration}`
  String thinkingCompletedWithDuration(String duration) {
    return Intl.message(
      'Thinking complete · $duration',
      name: 'thinkingCompletedWithDuration',
      desc: '',
      args: [duration],
    );
  }

  /// `Enter a description for speech generation`
  String get pleaseEnterSpeechDescription {
    return Intl.message(
      'Enter a description for speech generation',
      name: 'pleaseEnterSpeechDescription',
      desc: '',
      args: [],
    );
  }

  /// `Speech generated`
  String get speechGenerated {
    return Intl.message(
      'Speech generated',
      name: 'speechGenerated',
      desc: '',
      args: [],
    );
  }

  /// `Could not generate speech: {error}`
  String generateSpeechFailed(String error) {
    return Intl.message(
      'Could not generate speech: $error',
      name: 'generateSpeechFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Enter a description for music generation`
  String get pleaseEnterMusicDescription {
    return Intl.message(
      'Enter a description for music generation',
      name: 'pleaseEnterMusicDescription',
      desc: '',
      args: [],
    );
  }

  /// `Music generated`
  String get musicGenerated {
    return Intl.message(
      'Music generated',
      name: 'musicGenerated',
      desc: '',
      args: [],
    );
  }

  /// `Could not generate music: {error}`
  String generateMusicFailed(String error) {
    return Intl.message(
      'Could not generate music: $error',
      name: 'generateMusicFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Enter a description for video generation`
  String get pleaseEnterVideoDescription {
    return Intl.message(
      'Enter a description for video generation',
      name: 'pleaseEnterVideoDescription',
      desc: '',
      args: [],
    );
  }

  /// `Video generated`
  String get videoGenerated {
    return Intl.message(
      'Video generated',
      name: 'videoGenerated',
      desc: '',
      args: [],
    );
  }

  /// `Could not generate video: {error}`
  String generateVideoFailed(String error) {
    return Intl.message(
      'Could not generate video: $error',
      name: 'generateVideoFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Unable to open this link.`
  String get linkOpenFailed {
    return Intl.message(
      'Unable to open this link.',
      name: 'linkOpenFailed',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load bots`
  String get unableToLoadBots {
    return Intl.message(
      'Unable to load bots',
      name: 'unableToLoadBots',
      desc: '',
      args: [],
    );
  }

  /// `Creating…`
  String get creatingChat {
    return Intl.message('Creating…', name: 'creatingChat', desc: '', args: []);
  }

  /// `Could not create the chat: {error}`
  String createChatFailed(String error) {
    return Intl.message(
      'Could not create the chat: $error',
      name: 'createChatFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Stop generation before leaving?`
  String get stopGenerationBeforeLeaving {
    return Intl.message(
      'Stop generation before leaving?',
      name: 'stopGenerationBeforeLeaving',
      desc: '',
      args: [],
    );
  }

  /// `The partial response will be kept.`
  String get stopGenerationBeforeLeavingDescription {
    return Intl.message(
      'The partial response will be kept.',
      name: 'stopGenerationBeforeLeavingDescription',
      desc: '',
      args: [],
    );
  }

  /// `Stop and continue`
  String get stopAndContinue {
    return Intl.message(
      'Stop and continue',
      name: 'stopAndContinue',
      desc: '',
      args: [],
    );
  }

  /// `Unable to load messages`
  String get unableToLoadMessages {
    return Intl.message(
      'Unable to load messages',
      name: 'unableToLoadMessages',
      desc: '',
      args: [],
    );
  }

  /// `Could not clear chat history: {error}`
  String clearChatFailed(String error) {
    return Intl.message(
      'Could not clear chat history: $error',
      name: 'clearChatFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Could not delete the chat: {error}`
  String deleteChatFailed(String error) {
    return Intl.message(
      'Could not delete the chat: $error',
      name: 'deleteChatFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Token usage`
  String get tokenUsage {
    return Intl.message('Token usage', name: 'tokenUsage', desc: '', args: []);
  }

  /// `Token share by conversation`
  String get conversationTokenShare {
    return Intl.message(
      'Token share by conversation',
      name: 'conversationTokenShare',
      desc: '',
      args: [],
    );
  }

  /// `Input tokens`
  String get inputTokens {
    return Intl.message(
      'Input tokens',
      name: 'inputTokens',
      desc: '',
      args: [],
    );
  }

  /// `Output tokens`
  String get outputTokens {
    return Intl.message(
      'Output tokens',
      name: 'outputTokens',
      desc: '',
      args: [],
    );
  }

  /// `Total tokens`
  String get totalTokens {
    return Intl.message(
      'Total tokens',
      name: 'totalTokens',
      desc: '',
      args: [],
    );
  }

  /// `No token usage recorded`
  String get noTokenUsageRecorded {
    return Intl.message(
      'No token usage recorded',
      name: 'noTokenUsageRecorded',
      desc: '',
      args: [],
    );
  }

  /// `Daily usage`
  String get dailyTokenUsage {
    return Intl.message(
      'Daily usage',
      name: 'dailyTokenUsage',
      desc: '',
      args: [],
    );
  }

  /// `Hourly usage`
  String get hourlyTokenUsage {
    return Intl.message(
      'Hourly usage',
      name: 'hourlyTokenUsage',
      desc: '',
      args: [],
    );
  }

  /// `Back to daily usage`
  String get backToDailyUsage {
    return Intl.message(
      'Back to daily usage',
      name: 'backToDailyUsage',
      desc: '',
      args: [],
    );
  }

  /// `Select a day to view hourly usage`
  String get clickDayForHourlyUsage {
    return Intl.message(
      'Select a day to view hourly usage',
      name: 'clickDayForHourlyUsage',
      desc: '',
      args: [],
    );
  }

  /// `Enter a display name`
  String get enterDisplayName {
    return Intl.message(
      'Enter a display name',
      name: 'enterDisplayName',
      desc: '',
      args: [],
    );
  }

  /// `Skills`
  String get skillLibrary {
    return Intl.message('Skills', name: 'skillLibrary', desc: '', args: []);
  }

  /// `Install reusable instructions and bind them to your bots.`
  String get skillLibraryDescription {
    return Intl.message(
      'Install reusable instructions and bind them to your bots.',
      name: 'skillLibraryDescription',
      desc: '',
      args: [],
    );
  }

  /// `Search skills`
  String get searchSkills {
    return Intl.message(
      'Search skills',
      name: 'searchSkills',
      desc: '',
      args: [],
    );
  }

  /// `No matching skills found`
  String get noMatchingSkills {
    return Intl.message(
      'No matching skills found',
      name: 'noMatchingSkills',
      desc: '',
      args: [],
    );
  }

  /// `Import folder`
  String get importSkillFolder {
    return Intl.message(
      'Import folder',
      name: 'importSkillFolder',
      desc: '',
      args: [],
    );
  }

  /// `Import ZIP`
  String get importSkillZip {
    return Intl.message(
      'Import ZIP',
      name: 'importSkillZip',
      desc: '',
      args: [],
    );
  }

  /// `Importing…`
  String get importingSkill {
    return Intl.message(
      'Importing…',
      name: 'importingSkill',
      desc: '',
      args: [],
    );
  }

  /// `No Skills installed`
  String get noSkillsInstalled {
    return Intl.message(
      'No Skills installed',
      name: 'noSkillsInstalled',
      desc: '',
      args: [],
    );
  }

  /// `Import an Agent Skills folder or ZIP containing SKILL.md.`
  String get noSkillsInstalledDescription {
    return Intl.message(
      'Import an Agent Skills folder or ZIP containing SKILL.md.',
      name: 'noSkillsInstalledDescription',
      desc: '',
      args: [],
    );
  }

  /// `Skill imported`
  String get skillImportSucceeded {
    return Intl.message(
      'Skill imported',
      name: 'skillImportSucceeded',
      desc: '',
      args: [],
    );
  }

  /// `Could not import Skill: {error}`
  String skillImportFailed(String error) {
    return Intl.message(
      'Could not import Skill: $error',
      name: 'skillImportFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Details`
  String get details {
    return Intl.message('Details', name: 'details', desc: '', args: []);
  }

  /// `Refresh`
  String get refresh {
    return Intl.message('Refresh', name: 'refresh', desc: '', args: []);
  }

  /// `Skill details`
  String get skillDetails {
    return Intl.message(
      'Skill details',
      name: 'skillDetails',
      desc: '',
      args: [],
    );
  }

  /// `Uninstall`
  String get uninstall {
    return Intl.message('Uninstall', name: 'uninstall', desc: '', args: []);
  }

  /// `Uninstall Skill`
  String get uninstallSkill {
    return Intl.message(
      'Uninstall Skill',
      name: 'uninstallSkill',
      desc: '',
      args: [],
    );
  }

  /// `Uninstall {name}? Bot bindings will also be removed.`
  String confirmUninstallSkill(String name) {
    return Intl.message(
      'Uninstall $name? Bot bindings will also be removed.',
      name: 'confirmUninstallSkill',
      desc: '',
      args: [name],
    );
  }

  /// `Version`
  String get skillVersion {
    return Intl.message('Version', name: 'skillVersion', desc: '', args: []);
  }

  /// `Source`
  String get skillSource {
    return Intl.message('Source', name: 'skillSource', desc: '', args: []);
  }

  /// `Content digest`
  String get skillDigest {
    return Intl.message(
      'Content digest',
      name: 'skillDigest',
      desc: '',
      args: [],
    );
  }

  /// `Installation location`
  String get skillStorageLocation {
    return Intl.message(
      'Installation location',
      name: 'skillStorageLocation',
      desc: '',
      args: [],
    );
  }

  /// `Copy installation location`
  String get copySkillStorageLocation {
    return Intl.message(
      'Copy installation location',
      name: 'copySkillStorageLocation',
      desc: '',
      args: [],
    );
  }

  /// `Installation location copied to clipboard`
  String get skillStorageLocationCopied {
    return Intl.message(
      'Installation location copied to clipboard',
      name: 'skillStorageLocationCopied',
      desc: '',
      args: [],
    );
  }

  /// `Compatibility`
  String get skillCompatibility {
    return Intl.message(
      'Compatibility',
      name: 'skillCompatibility',
      desc: '',
      args: [],
    );
  }

  /// `Files`
  String get skillFiles {
    return Intl.message('Files', name: 'skillFiles', desc: '', args: []);
  }

  /// `Validation notes`
  String get skillValidationWarnings {
    return Intl.message(
      'Validation notes',
      name: 'skillValidationWarnings',
      desc: '',
      args: [],
    );
  }

  /// `Scripts are installed but execution is disabled.`
  String get skillScriptsDisabled {
    return Intl.message(
      'Scripts are installed but execution is disabled.',
      name: 'skillScriptsDisabled',
      desc: '',
      args: [],
    );
  }

  /// `Reference files available`
  String get skillReferencesAvailable {
    return Intl.message(
      'Reference files available',
      name: 'skillReferencesAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Assets available`
  String get skillAssetsAvailable {
    return Intl.message(
      'Assets available',
      name: 'skillAssetsAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Skills`
  String get botSkills {
    return Intl.message('Skills', name: 'botSkills', desc: '', args: []);
  }

  /// `Choose reusable instructions available to this bot.`
  String get botSkillsDescription {
    return Intl.message(
      'Choose reusable instructions available to this bot.',
      name: 'botSkillsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Add Skill`
  String get addSkill {
    return Intl.message('Add Skill', name: 'addSkill', desc: '', args: []);
  }

  /// `Remove Skill`
  String get removeSkill {
    return Intl.message(
      'Remove Skill',
      name: 'removeSkill',
      desc: '',
      args: [],
    );
  }

  /// `No Skills added`
  String get noBotSkillsAdded {
    return Intl.message(
      'No Skills added',
      name: 'noBotSkillsAdded',
      desc: '',
      args: [],
    );
  }

  /// `Add the installed Skills this bot needs.`
  String get noBotSkillsAddedDescription {
    return Intl.message(
      'Add the installed Skills this bot needs.',
      name: 'noBotSkillsAddedDescription',
      desc: '',
      args: [],
    );
  }

  /// `All installed Skills have been added.`
  String get allSkillsAdded {
    return Intl.message(
      'All installed Skills have been added.',
      name: 'allSkillsAdded',
      desc: '',
      args: [],
    );
  }

  /// `Enabled`
  String get skillEnabled {
    return Intl.message('Enabled', name: 'skillEnabled', desc: '', args: []);
  }

  /// `Disabled`
  String get skillDisabled {
    return Intl.message('Disabled', name: 'skillDisabled', desc: '', args: []);
  }

  /// `Per message`
  String get manualActivation {
    return Intl.message(
      'Per message',
      name: 'manualActivation',
      desc: '',
      args: [],
    );
  }

  /// `Always on`
  String get alwaysActivation {
    return Intl.message(
      'Always on',
      name: 'alwaysActivation',
      desc: '',
      args: [],
    );
  }

  /// `Select the Skill from the message composer when needed.`
  String get manualActivationDescription {
    return Intl.message(
      'Select the Skill from the message composer when needed.',
      name: 'manualActivationDescription',
      desc: '',
      args: [],
    );
  }

  /// `Inject this Skill into every text request.`
  String get alwaysActivationDescription {
    return Intl.message(
      'Inject this Skill into every text request.',
      name: 'alwaysActivationDescription',
      desc: '',
      args: [],
    );
  }

  /// `Automatic`
  String get autoActivation {
    return Intl.message(
      'Automatic',
      name: 'autoActivation',
      desc: '',
      args: [],
    );
  }

  /// `Let supported models activate this Skill from its description.`
  String get autoActivationDescription {
    return Intl.message(
      'Let supported models activate this Skill from its description.',
      name: 'autoActivationDescription',
      desc: '',
      args: [],
    );
  }

  /// `This provider supports manual Skills only.`
  String get autoActivationUnavailable {
    return Intl.message(
      'This provider supports manual Skills only.',
      name: 'autoActivationUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Test description`
  String get testSkillDescription {
    return Intl.message(
      'Test description',
      name: 'testSkillDescription',
      desc: '',
      args: [],
    );
  }

  /// `Test`
  String get testSkill {
    return Intl.message('Test', name: 'testSkill', desc: '', args: []);
  }

  /// `Example user request`
  String get skillDescriptionTestInput {
    return Intl.message(
      'Example user request',
      name: 'skillDescriptionTestInput',
      desc: '',
      args: [],
    );
  }

  /// `This example should activate the Skill`
  String get skillDescriptionShouldActivate {
    return Intl.message(
      'This example should activate the Skill',
      name: 'skillDescriptionShouldActivate',
      desc: '',
      args: [],
    );
  }

  /// `Run test`
  String get runSkillDescriptionTest {
    return Intl.message(
      'Run test',
      name: 'runSkillDescriptionTest',
      desc: '',
      args: [],
    );
  }

  /// `Activation result`
  String get skillDescriptionTestResult {
    return Intl.message(
      'Activation result',
      name: 'skillDescriptionTestResult',
      desc: '',
      args: [],
    );
  }

  /// `Pinned`
  String get pinnedSkill {
    return Intl.message('Pinned', name: 'pinnedSkill', desc: '', args: []);
  }

  /// `Pin selected for this conversation`
  String get pinSelectedSkills {
    return Intl.message(
      'Pin selected for this conversation',
      name: 'pinSelectedSkills',
      desc: '',
      args: [],
    );
  }

  /// `Clear conversation pins`
  String get clearPinnedSkills {
    return Intl.message(
      'Clear conversation pins',
      name: 'clearPinnedSkills',
      desc: '',
      args: [],
    );
  }

  /// `Skills`
  String get messageSkills {
    return Intl.message('Skills', name: 'messageSkills', desc: '', args: []);
  }

  /// `Always on`
  String get alwaysOn {
    return Intl.message('Always on', name: 'alwaysOn', desc: '', args: []);
  }

  /// `This release does not execute Skill scripts or commands.`
  String get skillNotExecutable {
    return Intl.message(
      'This release does not execute Skill scripts or commands.',
      name: 'skillNotExecutable',
      desc: '',
      args: [],
    );
  }

  /// `SKILL.md is loaded only as controlled prompt guidance; scripts, commands, and external tools remain disabled.`
  String get skillSafetyDescription {
    return Intl.message(
      'SKILL.md is loaded only as controlled prompt guidance; scripts, commands, and external tools remain disabled.',
      name: 'skillSafetyDescription',
      desc: '',
      args: [],
    );
  }

  /// `User`
  String get skillUserScope {
    return Intl.message('User', name: 'skillUserScope', desc: '', args: []);
  }

  /// `MCP Servers`
  String get mcpServers {
    return Intl.message('MCP Servers', name: 'mcpServers', desc: '', args: []);
  }

  /// `Connect MCP Servers and discover their Tool catalogs. Configure Tools after creating an agent.`
  String get mcpServersDescription {
    return Intl.message(
      'Connect MCP Servers and discover their Tool catalogs. Configure Tools after creating an agent.',
      name: 'mcpServersDescription',
      desc: '',
      args: [],
    );
  }

  /// `Enable MCP Tools for this agent. Tool calls require confirmation by default.`
  String get botMcpToolsDescription {
    return Intl.message(
      'Enable MCP Tools for this agent. Tool calls require confirmation by default.',
      name: 'botMcpToolsDescription',
      desc: '',
      args: [],
    );
  }

  /// `No connected MCP Tools are available.`
  String get noBotMcpToolsAvailable {
    return Intl.message(
      'No connected MCP Tools are available.',
      name: 'noBotMcpToolsAvailable',
      desc: '',
      args: [],
    );
  }

  /// `No confirmation`
  String get mcpNoApprovalRequired {
    return Intl.message(
      'No confirmation',
      name: 'mcpNoApprovalRequired',
      desc: '',
      args: [],
    );
  }

  /// `Enable all Tools`
  String get enableAllMcpTools {
    return Intl.message(
      'Enable all Tools',
      name: 'enableAllMcpTools',
      desc: '',
      args: [],
    );
  }

  /// `Disable all Tools`
  String get disableAllMcpTools {
    return Intl.message(
      'Disable all Tools',
      name: 'disableAllMcpTools',
      desc: '',
      args: [],
    );
  }

  /// `Enable no confirmation for all`
  String get enableAllMcpToolNoApproval {
    return Intl.message(
      'Enable no confirmation for all',
      name: 'enableAllMcpToolNoApproval',
      desc: '',
      args: [],
    );
  }

  /// `Disable no confirmation for all`
  String get disableAllMcpToolNoApproval {
    return Intl.message(
      'Disable no confirmation for all',
      name: 'disableAllMcpToolNoApproval',
      desc: '',
      args: [],
    );
  }

  /// `Search MCP servers`
  String get searchMcpServers {
    return Intl.message(
      'Search MCP servers',
      name: 'searchMcpServers',
      desc: '',
      args: [],
    );
  }

  /// `No matching MCP servers found`
  String get noMatchingMcpServers {
    return Intl.message(
      'No matching MCP servers found',
      name: 'noMatchingMcpServers',
      desc: '',
      args: [],
    );
  }

  /// `Search tools`
  String get searchMcpTools {
    return Intl.message(
      'Search tools',
      name: 'searchMcpTools',
      desc: '',
      args: [],
    );
  }

  /// `No matching tools found`
  String get noMatchingMcpTools {
    return Intl.message(
      'No matching tools found',
      name: 'noMatchingMcpTools',
      desc: '',
      args: [],
    );
  }

  /// `Add MCP Server`
  String get addMcpServer {
    return Intl.message(
      'Add MCP Server',
      name: 'addMcpServer',
      desc: '',
      args: [],
    );
  }

  /// `Remove MCP Server`
  String get removeMcpServer {
    return Intl.message(
      'Remove MCP Server',
      name: 'removeMcpServer',
      desc: '',
      args: [],
    );
  }

  /// `Remote MCP only`
  String get remoteMcpOnly {
    return Intl.message(
      'Remote MCP only',
      name: 'remoteMcpOnly',
      desc: '',
      args: [],
    );
  }

  /// `Local process-based MCP servers remain disabled pending a platform security review.`
  String get localMcpDisabledDescription {
    return Intl.message(
      'Local process-based MCP servers remain disabled pending a platform security review.',
      name: 'localMcpDisabledDescription',
      desc: '',
      args: [],
    );
  }

  /// `Local process security`
  String get mcpLocalProcessSecurityTitle {
    return Intl.message(
      'Local process security',
      name: 'mcpLocalProcessSecurityTitle',
      desc: '',
      args: [],
    );
  }

  /// `stdio servers run commands on this computer. Only add servers and environment variables you trust.`
  String get mcpLocalProcessSecurityDescription {
    return Intl.message(
      'stdio servers run commands on this computer. Only add servers and environment variables you trust.',
      name: 'mcpLocalProcessSecurityDescription',
      desc: '',
      args: [],
    );
  }

  /// `Stars stores discovered Tool catalogs. Enable individual Tools when editing an agent; only that agent can expose them to the model.`
  String get mcpProgressiveDiscoveryDescription {
    return Intl.message(
      'Stars stores discovered Tool catalogs. Enable individual Tools when editing an agent; only that agent can expose them to the model.',
      name: 'mcpProgressiveDiscoveryDescription',
      desc: '',
      args: [],
    );
  }

  /// `Remote MCP endpoints must use HTTPS.`
  String get mcpHttpsRequired {
    return Intl.message(
      'Remote MCP endpoints must use HTTPS.',
      name: 'mcpHttpsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Private, local, and link-local MCP endpoints are blocked.`
  String get mcpPrivateEndpointBlocked {
    return Intl.message(
      'Private, local, and link-local MCP endpoints are blocked.',
      name: 'mcpPrivateEndpointBlocked',
      desc: '',
      args: [],
    );
  }

  /// `Authorization required`
  String get mcpAuthorizationRequired {
    return Intl.message(
      'Authorization required',
      name: 'mcpAuthorizationRequired',
      desc: '',
      args: [],
    );
  }

  /// `The MCP request timed out.`
  String get mcpRequestTimedOut {
    return Intl.message(
      'The MCP request timed out.',
      name: 'mcpRequestTimedOut',
      desc: '',
      args: [],
    );
  }

  /// `The MCP server uses an unsupported protocol version.`
  String get mcpUnsupportedProtocol {
    return Intl.message(
      'The MCP server uses an unsupported protocol version.',
      name: 'mcpUnsupportedProtocol',
      desc: '',
      args: [],
    );
  }

  /// `The stdio MCP command could not be started.`
  String get mcpStdioStartFailed {
    return Intl.message(
      'The stdio MCP command could not be started.',
      name: 'mcpStdioStartFailed',
      desc: '',
      args: [],
    );
  }

  /// `Environment variables must use one KEY=VALUE entry per line.`
  String get mcpInvalidStdioEnvironment {
    return Intl.message(
      'Environment variables must use one KEY=VALUE entry per line.',
      name: 'mcpInvalidStdioEnvironment',
      desc: '',
      args: [],
    );
  }

  /// `This MCP server is used by an agent. Remove it from the agent before deleting it.`
  String get mcpServerInUseByBot {
    return Intl.message(
      'This MCP server is used by an agent. Remove it from the agent before deleting it.',
      name: 'mcpServerInUseByBot',
      desc: '',
      args: [],
    );
  }

  /// `MCP connection failed: {error}`
  String mcpConnectionFailed(String error) {
    return Intl.message(
      'MCP connection failed: $error',
      name: 'mcpConnectionFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Delete MCP Server`
  String get deleteMcpServer {
    return Intl.message(
      'Delete MCP Server',
      name: 'deleteMcpServer',
      desc: '',
      args: [],
    );
  }

  /// `Delete {name}? Its cached Tool catalog and secure credential will also be removed.`
  String confirmDeleteMcpServer(String name) {
    return Intl.message(
      'Delete $name? Its cached Tool catalog and secure credential will also be removed.',
      name: 'confirmDeleteMcpServer',
      desc: '',
      args: [name],
    );
  }

  /// `Tools`
  String get mcpTools {
    return Intl.message('Tools', name: 'mcpTools', desc: '', args: []);
  }

  /// `Refresh Tools`
  String get refreshMcpTools {
    return Intl.message(
      'Refresh Tools',
      name: 'refreshMcpTools',
      desc: '',
      args: [],
    );
  }

  /// `Server details`
  String get mcpServerDetails {
    return Intl.message(
      'Server details',
      name: 'mcpServerDetails',
      desc: '',
      args: [],
    );
  }

  /// `Edit MCP Server`
  String get editMcpServer {
    return Intl.message(
      'Edit MCP Server',
      name: 'editMcpServer',
      desc: '',
      args: [],
    );
  }

  /// `No Tools discovered. Check the connection and refresh.`
  String get noMcpToolsDiscovered {
    return Intl.message(
      'No Tools discovered. Check the connection and refresh.',
      name: 'noMcpToolsDiscovered',
      desc: '',
      args: [],
    );
  }

  /// `This Tool has an unsupported input schema and cannot be selected.`
  String get mcpToolSchemaUnsupported {
    return Intl.message(
      'This Tool has an unsupported input schema and cannot be selected.',
      name: 'mcpToolSchemaUnsupported',
      desc: '',
      args: [],
    );
  }

  /// `Connected`
  String get mcpConnected {
    return Intl.message('Connected', name: 'mcpConnected', desc: '', args: []);
  }

  /// `Connecting`
  String get mcpConnecting {
    return Intl.message(
      'Connecting',
      name: 'mcpConnecting',
      desc: '',
      args: [],
    );
  }

  /// `Connection error`
  String get mcpConnectionError {
    return Intl.message(
      'Connection error',
      name: 'mcpConnectionError',
      desc: '',
      args: [],
    );
  }

  /// `Disconnected`
  String get mcpDisconnected {
    return Intl.message(
      'Disconnected',
      name: 'mcpDisconnected',
      desc: '',
      args: [],
    );
  }

  /// `Server name`
  String get mcpServerName {
    return Intl.message(
      'Server name',
      name: 'mcpServerName',
      desc: '',
      args: [],
    );
  }

  /// `Connection`
  String get mcpConnectionSettings {
    return Intl.message(
      'Connection',
      name: 'mcpConnectionSettings',
      desc: '',
      args: [],
    );
  }

  /// `Transport`
  String get mcpTransport {
    return Intl.message('Transport', name: 'mcpTransport', desc: '', args: []);
  }

  /// `Streamable HTTP`
  String get mcpTransportStreamableHttp {
    return Intl.message(
      'Streamable HTTP',
      name: 'mcpTransportStreamableHttp',
      desc: '',
      args: [],
    );
  }

  /// `stdio (local process)`
  String get mcpTransportStdio {
    return Intl.message(
      'stdio (local process)',
      name: 'mcpTransportStdio',
      desc: '',
      args: [],
    );
  }

  /// `Streamable HTTP endpoint`
  String get mcpEndpoint {
    return Intl.message(
      'Streamable HTTP endpoint',
      name: 'mcpEndpoint',
      desc: '',
      args: [],
    );
  }

  /// `Command`
  String get mcpCommand {
    return Intl.message('Command', name: 'mcpCommand', desc: '', args: []);
  }

  /// `Executable name or absolute path. The command runs directly without a shell.`
  String get mcpCommandDescription {
    return Intl.message(
      'Executable name or absolute path. The command runs directly without a shell.',
      name: 'mcpCommandDescription',
      desc: '',
      args: [],
    );
  }

  /// `Arguments`
  String get mcpArguments {
    return Intl.message('Arguments', name: 'mcpArguments', desc: '', args: []);
  }

  /// `Enter one argument per line.`
  String get mcpArgumentsDescription {
    return Intl.message(
      'Enter one argument per line.',
      name: 'mcpArgumentsDescription',
      desc: '',
      args: [],
    );
  }

  /// `Local process and communication`
  String get mcpStdioProcessAndChannel {
    return Intl.message(
      'Local process and communication',
      name: 'mcpStdioProcessAndChannel',
      desc: '',
      args: [],
    );
  }

  /// `Process status`
  String get mcpProcessStatus {
    return Intl.message(
      'Process status',
      name: 'mcpProcessStatus',
      desc: '',
      args: [],
    );
  }

  /// `Running`
  String get mcpProcessRunning {
    return Intl.message(
      'Running',
      name: 'mcpProcessRunning',
      desc: '',
      args: [],
    );
  }

  /// `Not running`
  String get mcpProcessNotRunning {
    return Intl.message(
      'Not running',
      name: 'mcpProcessNotRunning',
      desc: '',
      args: [],
    );
  }

  /// `Process ID (PID)`
  String get mcpProcessId {
    return Intl.message(
      'Process ID (PID)',
      name: 'mcpProcessId',
      desc: '',
      args: [],
    );
  }

  /// `Started at`
  String get mcpProcessStartedAt {
    return Intl.message(
      'Started at',
      name: 'mcpProcessStartedAt',
      desc: '',
      args: [],
    );
  }

  /// `Secure environment variables`
  String get mcpSecureEnvironmentVariables {
    return Intl.message(
      'Secure environment variables',
      name: 'mcpSecureEnvironmentVariables',
      desc: '',
      args: [],
    );
  }

  /// `{count} configured (values hidden)`
  String mcpHiddenEnvironmentVariableCount(int count) {
    return Intl.message(
      '$count configured (values hidden)',
      name: 'mcpHiddenEnvironmentVariableCount',
      desc: '',
      args: [count],
    );
  }

  /// `Communication channel`
  String get mcpCommunicationChannel {
    return Intl.message(
      'Communication channel',
      name: 'mcpCommunicationChannel',
      desc: '',
      args: [],
    );
  }

  /// `stdin / stdout / stderr (operating system pipes)`
  String get mcpStdioPipeChannel {
    return Intl.message(
      'stdin / stdout / stderr (operating system pipes)',
      name: 'mcpStdioPipeChannel',
      desc: '',
      args: [],
    );
  }

  /// `Environment variables`
  String get mcpEnvironment {
    return Intl.message(
      'Environment variables',
      name: 'mcpEnvironment',
      desc: '',
      args: [],
    );
  }

  /// `Enter one KEY=VALUE per line. Values are stored in the operating system's secure credential store; leave blank while editing to keep existing values.`
  String get mcpEnvironmentDescription {
    return Intl.message(
      'Enter one KEY=VALUE per line. Values are stored in the operating system\'s secure credential store; leave blank while editing to keep existing values.',
      name: 'mcpEnvironmentDescription',
      desc: '',
      args: [],
    );
  }

  /// `Authentication`
  String get mcpAuthentication {
    return Intl.message(
      'Authentication',
      name: 'mcpAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `None`
  String get mcpNoAuthentication {
    return Intl.message(
      'None',
      name: 'mcpNoAuthentication',
      desc: '',
      args: [],
    );
  }

  /// `OAuth / bearer access token`
  String get mcpAccessToken {
    return Intl.message(
      'OAuth / bearer access token',
      name: 'mcpAccessToken',
      desc: '',
      args: [],
    );
  }

  /// `Stored in the operating system's secure credential store.`
  String get mcpTokenStoredSecurely {
    return Intl.message(
      'Stored in the operating system\'s secure credential store.',
      name: 'mcpTokenStoredSecurely',
      desc: '',
      args: [],
    );
  }

  /// `Leave blank to keep the existing secure credential.`
  String get mcpTokenLeaveBlank {
    return Intl.message(
      'Leave blank to keep the existing secure credential.',
      name: 'mcpTokenLeaveBlank',
      desc: '',
      args: [],
    );
  }

  /// `Save and connect`
  String get saveAndConnect {
    return Intl.message(
      'Save and connect',
      name: 'saveAndConnect',
      desc: '',
      args: [],
    );
  }

  /// `No MCP Servers`
  String get noMcpServers {
    return Intl.message(
      'No MCP Servers',
      name: 'noMcpServers',
      desc: '',
      args: [],
    );
  }

  /// `Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.`
  String get noMcpServersDescription {
    return Intl.message(
      'Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.',
      name: 'noMcpServersDescription',
      desc: '',
      args: [],
    );
  }

  /// `Refresh catalogs`
  String get refreshSkillCatalogs {
    return Intl.message(
      'Refresh catalogs',
      name: 'refreshSkillCatalogs',
      desc: '',
      args: [],
    );
  }

  /// `Refreshing catalogs…`
  String get refreshingSkillCatalogs {
    return Intl.message(
      'Refreshing catalogs…',
      name: 'refreshingSkillCatalogs',
      desc: '',
      args: [],
    );
  }

  /// `Desktop script sandbox available`
  String get skillSandboxAvailable {
    return Intl.message(
      'Desktop script sandbox available',
      name: 'skillSandboxAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Scripts remain disabled per Skill until you approve them. Every invocation still requires approval and runs without network, home-directory, or inherited environment access.`
  String get skillSandboxAvailableDescription {
    return Intl.message(
      'Scripts remain disabled per Skill until you approve them. Every invocation still requires approval and runs without network, home-directory, or inherited environment access.',
      name: 'skillSandboxAvailableDescription',
      desc: '',
      args: [],
    );
  }

  /// `Skill scripts unavailable`
  String get skillSandboxUnavailable {
    return Intl.message(
      'Skill scripts unavailable',
      name: 'skillSandboxUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `This platform does not provide the required isolated helper. Skill instructions and resources remain available, but scripts cannot run.`
  String get skillSandboxUnavailableDescription {
    return Intl.message(
      'This platform does not provide the required isolated helper. Skill instructions and resources remain available, but scripts cannot run.',
      name: 'skillSandboxUnavailableDescription',
      desc: '',
      args: [],
    );
  }

  /// `Scripts enabled`
  String get skillScriptsEnabled {
    return Intl.message(
      'Scripts enabled',
      name: 'skillScriptsEnabled',
      desc: '',
      args: [],
    );
  }

  /// `Enable scripts`
  String get enableSkillScripts {
    return Intl.message(
      'Enable scripts',
      name: 'enableSkillScripts',
      desc: '',
      args: [],
    );
  }

  /// `Disable scripts`
  String get disableSkillScripts {
    return Intl.message(
      'Disable scripts',
      name: 'disableSkillScripts',
      desc: '',
      args: [],
    );
  }

  /// `Enable isolated Skill scripts?`
  String get enableSkillScriptsTitle {
    return Intl.message(
      'Enable isolated Skill scripts?',
      name: 'enableSkillScriptsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Allow {name} to register its declared scripts as tools. Each call still requires approval and runs inside the desktop sandbox.`
  String enableSkillScriptsDescription(String name) {
    return Intl.message(
      'Allow $name to register its declared scripts as tools. Each call still requires approval and runs inside the desktop sandbox.',
      name: 'enableSkillScriptsDescription',
      desc: '',
      args: [name],
    );
  }

  /// `Skill script setting updated.`
  String get skillScriptSettingUpdated {
    return Intl.message(
      'Skill script setting updated.',
      name: 'skillScriptSettingUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Publisher`
  String get skillPublisher {
    return Intl.message(
      'Publisher',
      name: 'skillPublisher',
      desc: '',
      args: [],
    );
  }

  /// `Signature`
  String get skillSignature {
    return Intl.message(
      'Signature',
      name: 'skillSignature',
      desc: '',
      args: [],
    );
  }

  /// `Unsigned`
  String get skillSignatureUnsigned {
    return Intl.message(
      'Unsigned',
      name: 'skillSignatureUnsigned',
      desc: '',
      args: [],
    );
  }

  /// `Verified signature`
  String get skillSignatureVerified {
    return Intl.message(
      'Verified signature',
      name: 'skillSignatureVerified',
      desc: '',
      args: [],
    );
  }

  /// `Unknown publisher`
  String get skillSignatureUnknownPublisher {
    return Intl.message(
      'Unknown publisher',
      name: 'skillSignatureUnknownPublisher',
      desc: '',
      args: [],
    );
  }

  /// `Invalid signature`
  String get skillSignatureInvalid {
    return Intl.message(
      'Invalid signature',
      name: 'skillSignatureInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Update policy`
  String get skillUpdatePolicy {
    return Intl.message(
      'Update policy',
      name: 'skillUpdatePolicy',
      desc: '',
      args: [],
    );
  }

  /// `Manual`
  String get skillUpdateManual {
    return Intl.message(
      'Manual',
      name: 'skillUpdateManual',
      desc: '',
      args: [],
    );
  }

  /// `Notify`
  String get skillUpdateNotify {
    return Intl.message(
      'Notify',
      name: 'skillUpdateNotify',
      desc: '',
      args: [],
    );
  }

  /// `Automatic`
  String get skillUpdateAutomatic {
    return Intl.message(
      'Automatic',
      name: 'skillUpdateAutomatic',
      desc: '',
      args: [],
    );
  }

  /// `Pinned`
  String get skillUpdatePinned {
    return Intl.message(
      'Pinned',
      name: 'skillUpdatePinned',
      desc: '',
      args: [],
    );
  }

  /// `Update available`
  String get skillUpdateAvailable {
    return Intl.message(
      'Update available',
      name: 'skillUpdateAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Install update`
  String get installSkillUpdate {
    return Intl.message(
      'Install update',
      name: 'installSkillUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Context and memory`
  String get contextAndMemory {
    return Intl.message(
      'Context and memory',
      name: 'contextAndMemory',
      desc: '',
      args: [],
    );
  }

  /// `Context window`
  String get contextWindow {
    return Intl.message(
      'Context window',
      name: 'contextWindow',
      desc: '',
      args: [],
    );
  }

  /// `Estimated usage`
  String get estimatedContextUsage {
    return Intl.message(
      'Estimated usage',
      name: 'estimatedContextUsage',
      desc: '',
      args: [],
    );
  }

  /// `Recent turns retained`
  String get retainedRecentTurns {
    return Intl.message(
      'Recent turns retained',
      name: 'retainedRecentTurns',
      desc: '',
      args: [],
    );
  }

  /// `Messages summarized`
  String get summarizedTurns {
    return Intl.message(
      'Messages summarized',
      name: 'summarizedTurns',
      desc: '',
      args: [],
    );
  }

  /// `Compaction status`
  String get compactionStatus {
    return Intl.message(
      'Compaction status',
      name: 'compactionStatus',
      desc: '',
      args: [],
    );
  }

  /// `Organizing context…`
  String get compactingContext {
    return Intl.message(
      'Organizing context…',
      name: 'compactingContext',
      desc: '',
      args: [],
    );
  }

  /// `Automatic memory`
  String get automaticMemory {
    return Intl.message(
      'Automatic memory',
      name: 'automaticMemory',
      desc: '',
      args: [],
    );
  }

  /// `View summary`
  String get viewSummary {
    return Intl.message(
      'View summary',
      name: 'viewSummary',
      desc: '',
      args: [],
    );
  }

  /// `No conversation summary is available yet.`
  String get noConversationSummary {
    return Intl.message(
      'No conversation summary is available yet.',
      name: 'noConversationSummary',
      desc: '',
      args: [],
    );
  }

  /// `Manage memory`
  String get manageMemory {
    return Intl.message(
      'Manage memory',
      name: 'manageMemory',
      desc: '',
      args: [],
    );
  }

  /// `Compact now`
  String get compactNow {
    return Intl.message('Compact now', name: 'compactNow', desc: '', args: []);
  }

  /// `Context compacted`
  String get contextCompacted {
    return Intl.message(
      'Context compacted',
      name: 'contextCompacted',
      desc: '',
      args: [],
    );
  }

  /// `There is not enough older context to compact`
  String get nothingToCompact {
    return Intl.message(
      'There is not enough older context to compact',
      name: 'nothingToCompact',
      desc: '',
      args: [],
    );
  }

  /// `Memory changed; please retry`
  String get memoryChangedRetry {
    return Intl.message(
      'Memory changed; please retry',
      name: 'memoryChangedRetry',
      desc: '',
      args: [],
    );
  }

  /// `The generated summary did not pass validation`
  String get invalidSummary {
    return Intl.message(
      'The generated summary did not pass validation',
      name: 'invalidSummary',
      desc: '',
      args: [],
    );
  }

  /// `Conversation summary`
  String get conversationSummary {
    return Intl.message(
      'Conversation summary',
      name: 'conversationSummary',
      desc: '',
      args: [],
    );
  }

  /// `Search memory`
  String get searchMemory {
    return Intl.message(
      'Search memory',
      name: 'searchMemory',
      desc: '',
      args: [],
    );
  }

  /// `Automatic summaries can be inaccurate. The current message always takes precedence.`
  String get automaticSummaryWarning {
    return Intl.message(
      'Automatic summaries can be inaccurate. The current message always takes precedence.',
      name: 'automaticSummaryWarning',
      desc: '',
      args: [],
    );
  }

  /// `Rebuild`
  String get rebuildMemory {
    return Intl.message('Rebuild', name: 'rebuildMemory', desc: '', args: []);
  }

  /// `Clear automatic memory`
  String get clearAutomaticMemory {
    return Intl.message(
      'Clear automatic memory',
      name: 'clearAutomaticMemory',
      desc: '',
      args: [],
    );
  }

  /// `Pin`
  String get pinMemory {
    return Intl.message('Pin', name: 'pinMemory', desc: '', args: []);
  }

  /// `Unpin`
  String get unpinMemory {
    return Intl.message('Unpin', name: 'unpinMemory', desc: '', args: []);
  }

  /// `Edit memory`
  String get editMemory {
    return Intl.message('Edit memory', name: 'editMemory', desc: '', args: []);
  }

  /// `Restore`
  String get restoreMemory {
    return Intl.message('Restore', name: 'restoreMemory', desc: '', args: []);
  }

  /// `Forget`
  String get forgetMemory {
    return Intl.message('Forget', name: 'forgetMemory', desc: '', args: []);
  }

  /// `Failed`
  String get compactionFailed {
    return Intl.message('Failed', name: 'compactionFailed', desc: '', args: []);
  }

  /// `Idle`
  String get idle {
    return Intl.message('Idle', name: 'idle', desc: '', args: []);
  }

  /// `Fact`
  String get memoryFact {
    return Intl.message('Fact', name: 'memoryFact', desc: '', args: []);
  }

  /// `Preference`
  String get memoryPreference {
    return Intl.message(
      'Preference',
      name: 'memoryPreference',
      desc: '',
      args: [],
    );
  }

  /// `Decision`
  String get memoryDecision {
    return Intl.message('Decision', name: 'memoryDecision', desc: '', args: []);
  }

  /// `Task`
  String get memoryTask {
    return Intl.message('Task', name: 'memoryTask', desc: '', args: []);
  }

  /// `Open question`
  String get memoryQuestion {
    return Intl.message(
      'Open question',
      name: 'memoryQuestion',
      desc: '',
      args: [],
    );
  }

  /// `Artifact`
  String get memoryArtifact {
    return Intl.message('Artifact', name: 'memoryArtifact', desc: '', args: []);
  }

  /// `Correction`
  String get memoryCorrection {
    return Intl.message(
      'Correction',
      name: 'memoryCorrection',
      desc: '',
      args: [],
    );
  }

  /// `Starting…`
  String get startupStarting {
    return Intl.message(
      'Starting…',
      name: 'startupStarting',
      desc:
          'Status shown while Stars loads the profile before the main application starts',
      args: [],
    );
  }

  /// `Startup failed. Please try again.`
  String get startupFailed {
    return Intl.message(
      'Startup failed. Please try again.',
      name: 'startupFailed',
      desc: 'Status shown when Stars cannot finish loading the application',
      args: [],
    );
  }

  /// `Video playback error: {error}`
  String videoPlaybackError(String error) {
    return Intl.message(
      'Video playback error: $error',
      name: 'videoPlaybackError',
      desc: 'Error shown by the embedded video controls',
      args: [error],
    );
  }

  /// `Unable to load video`
  String get videoLoadFailed {
    return Intl.message(
      'Unable to load video',
      name: 'videoLoadFailed',
      desc: 'Error shown when a local generated video cannot be initialized',
      args: [],
    );
  }

  /// `This database was created by a newer version of Stars. Update the app before opening it.`
  String get databaseDowngradeNotSupported {
    return Intl.message(
      'This database was created by a newer version of Stars. Update the app before opening it.',
      name: 'databaseDowngradeNotSupported',
      desc:
          'Safe error shown when the local database is newer than the application',
      args: [],
    );
  }

  /// `The database integrity check failed, and recovery from this version's backup was unsuccessful.`
  String get databaseRecoveryFailed {
    return Intl.message(
      'The database integrity check failed, and recovery from this version\'s backup was unsuccessful.',
      name: 'databaseRecoveryFailed',
      desc:
          'Safe error shown when database validation and backup recovery both fail',
      args: [],
    );
  }

  /// `{milliseconds} ms`
  String durationMilliseconds(String milliseconds) {
    return Intl.message(
      '$milliseconds ms',
      name: 'durationMilliseconds',
      desc: 'Localized duration shorter than one second',
      args: [milliseconds],
    );
  }

  /// `{seconds} s`
  String durationSeconds(String seconds) {
    return Intl.message(
      '$seconds s',
      name: 'durationSeconds',
      desc: 'Localized duration measured in seconds',
      args: [seconds],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'de', countryCode: 'DE'),
      Locale.fromSubtags(languageCode: 'es', countryCode: 'ES'),
      Locale.fromSubtags(languageCode: 'fr', countryCode: 'FR'),
      Locale.fromSubtags(languageCode: 'hi', countryCode: 'IN'),
      Locale.fromSubtags(languageCode: 'it', countryCode: 'IT'),
      Locale.fromSubtags(languageCode: 'ja', countryCode: 'JP'),
      Locale.fromSubtags(languageCode: 'ko', countryCode: 'KR'),
      Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR'),
      Locale.fromSubtags(languageCode: 'ru', countryCode: 'RU'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
