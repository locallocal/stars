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
    final name =
        (locale.countryCode?.isEmpty ?? false)
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

  /// `Bubble`
  String get appName {
    return Intl.message(
      'Bubble',
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

  /// `About Bubble`
  String get aboutApp {
    return Intl.message(
      'About Bubble',
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

  /// `© 2025 Bubble Team`
  String get copyright {
    return Intl.message(
      '© 2025 Bubble Team',
      name: 'copyright',
      desc: 'Copyright information',
      args: [],
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

  /// `Bubble - AI Chat Assistant`
  String get appTitle {
    return Intl.message(
      'Bubble - AI Chat Assistant',
      name: 'appTitle',
      desc: 'App title',
      args: [],
    );
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

  /// `No chats yet`
  String get noChats {
    return Intl.message(
      'No chats yet',
      name: 'noChats',
      desc: 'No chats yet',
      args: [],
    );
  }

  /// `Click + in the top right to start a chat`
  String get clickToStartChat {
    return Intl.message(
      'Click + in the top right to start a chat',
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

  /// `Are you sure you want to delete this chat?`
  String get confirmDeleteChat {
    return Intl.message(
      'Are you sure you want to delete this chat?',
      name: 'confirmDeleteChat',
      desc: 'Confirm delete chat',
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

  /// `Select Provider:`
  String get selectProvider {
    return Intl.message(
      'Select Provider:',
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

  /// `API Type:`
  String get apiType {
    return Intl.message(
      'API Type:',
      name: 'apiType',
      desc: 'Label for API type selection',
      args: [],
    );
  }

  /// `API Address:`
  String get apiAddress {
    return Intl.message(
      'API Address:',
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
