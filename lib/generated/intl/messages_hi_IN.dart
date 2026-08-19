// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a hi_IN locale. All the
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
  String get localeName => 'hi_IN';

  static String m0(name) => "बॉट \"${name}\" जोड़ा गया है";

  static String m1(botName) => "\"${botName}\" हटा दिया गया है";

  static String m2(botName) =>
      "नमस्ते! मैं ${botName} हूँ, एक AI सहायक। आप मुझसे कोई भी प्रश्न पूछ सकते हैं, मैं आपकी मदद करने की पूरी कोशिश करूंगा।";

  static String m3(botName) => "${botName} टाइप कर रहा है...";

  static String m4(botName) => "बॉट ${botName} अपडेट किया गया है";

  static String m5(botName) => "${botName} के साथ चैट हटा दी गई";

  static String m6(error) => "Could not clear chat history: ${error}";

  static String m7(botName) =>
      "क्या आप वाकई \"${botName}\" के साथ सभी चैट इतिहास मिटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती है।";

  static String m8(botName) =>
      "बॉट हटाने से संबंधित सभी चैट भी हट जाएंगी। क्या आप वाकई ${botName} को हटाना चाहते हैं?";

  static String m9(botName) =>
      "चैट हटाने से सभी चैट इतिहास मिट जाएगा। क्या आप वाकई ${botName} के साथ चैट हटाना चाहते हैं?";

  static String m10(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m11(name) =>
      "${name} को अनइंस्टॉल करें? बॉट से इसके संबंध भी हटा दिए जाएँगे।";

  static String m12(year) => "© ${year} Stars टीम";

  static String m13(error) => "Could not create the chat: ${error}";

  static String m14(error) => "Could not delete the chat: ${error}";

  static String m15(milliseconds) => "${milliseconds} मिलीसेकंड";

  static String m16(seconds) => "${seconds} सेकंड";

  static String m17(name) =>
      "${name} को घोषित स्क्रिप्ट टूल के रूप में पंजीकृत करने दें। हर कॉल को फिर भी स्वीकृति चाहिए।";

  static String m18(count) => "${count} files";

  static String m19(error) => "Generate image failed: ${error}";

  static String m20(error) => "Could not generate music: ${error}";

  static String m21(error) => "Could not generate speech: ${error}";

  static String m22(error) => "Could not generate video: ${error}";

  static String m23(count) => "${count} items";

  static String m24(language) => "भाषा ${language} में बदली गई";

  static String m25(error) => "MCP connection failed: ${error}";

  static String m26(count) => "${count} configured (values hidden)";

  static String m27(minutes) => "${minutes} मिनट पहले";

  static String m28(count) => "सफलतापूर्वक ${count} मॉडल प्राप्त किए गए";

  static String m29(count) => "${count} कमांड निष्पादन";

  static String m30(duration) => "अवधि ${duration}";

  static String m31(count) => "${count} फ़ाइल बदलाव";

  static String m32(count) => "${count} टूल कॉल";

  static String m33(error) => "उत्तर प्राप्त करने में विफल: ${error}";

  static String m34(error) => "Could not save image: ${error}";

  static String m35(error) => "Could not share image: ${error}";

  static String m36(error) => "कौशल आयात नहीं हो सका: ${error}";

  static String m37(duration) => "सोचना पूर्ण · ${duration}";

  static String m38(error) => "वीडियो चलाने में त्रुटि: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("बॉट्स"),
    "about": MessageLookupByLibrary.simpleMessage("के बारे में"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Stars के बारे में"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("बॉट जोड़ें"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("कौशल जोड़ें"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "एप्लिकेशन फॉन्ट साइज़ समायोजित करें",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage(
      "फॉन्ट साइज़ समायोजित करें",
    ),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "सभी इंस्टॉल किए गए कौशल जोड़ दिए गए हैं।",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("हमेशा चालू"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "हर टेक्स्ट अनुरोध में यह कौशल जोड़ें।",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("हमेशा चालू"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API पता:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API कुंजी"),
    "apiType": MessageLookupByLibrary.simpleMessage("API प्रकार:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "एक सरल लेकिन शक्तिशाली AI चैट एप्लयन जो आपको कहीं भी, कभी भी AI के साथ चैट करने की अनुमति देता है।",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Stars - AI चैट सहायक"),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "सिस्टम प्रॉम्प्ट",
    ),
    "applicationInjectedPromptDescription": MessageLookupByLibrary.simpleMessage(
      "Stars इसे प्रबंधित करता है और हर मॉडल अनुरोध में जोड़ता है। वर्तमान एजेंट और बातचीत के पहचानकर्ता रनटाइम पर जोड़े जाते हैं और संपादित नहीं किए जा सकते।",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("स्वचालित"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "समर्थित मॉडल इस कौशल को उसके विवरण के आधार पर सक्रिय कर सकते हैं।",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "यह प्रदाता केवल मैन्युअल कौशल का समर्थन करता है।",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage("स्वचालित स्मृति"),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "स्वचालित सारांश गलत हो सकते हैं। वर्तमान संदेश हमेशा प्राथमिक है।",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage(
      "दैनिक उपयोग पर वापस जाएँ",
    ),
    "basicInformation": MessageLookupByLibrary.simpleMessage("मूल जानकारी"),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("बॉट अवतार"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "इस एजेंट के लिए MCP टूल चालू करें। डिफ़ॉल्ट रूप से टूल कॉल की पुष्टि आवश्यक है।",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("बॉट का नाम"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "खोज बॉट के नाम के अनुसार सूची फ़िल्टर करती है।",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("कौशल"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "इस बॉट के लिए उपलब्ध दोबारा इस्तेमाल किए जा सकने वाले निर्देश चुनें।",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("रद्द करें"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("अवतार बदलें"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("सहेजा गया"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage(
      "चैट निष्पादन स्थिति",
    ),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "चैट इतिहास मिटा दिया गया",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("चैट्स"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("मिटाएं"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage(
      "स्वचालित स्मृति साफ़ करें",
    ),
    "clearChat": MessageLookupByLibrary.simpleMessage("चैट साफ़ करें"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage(
      "चैट इतिहास साफ़ करें",
    ),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage(
      "बातचीत के पिन हटाएँ",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "प्रति घंटे का उपयोग देखने के लिए कोई दिन चुनें",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "बॉट जोड़ने के लिए ऊपरी दाएं कोने में + पर क्लिक करें",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "बातचीत बनाने के लिए नई चैट पर क्लिक करें",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage("कमांड निष्पादन"),
    "compactNow": MessageLookupByLibrary.simpleMessage("अभी संपीड़ित करें"),
    "compactingContext": MessageLookupByLibrary.simpleMessage(
      "संदर्भ व्यवस्थित किया जा रहा है…",
    ),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("विफल"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage("संपीड़न स्थिति"),
    "confirm": MessageLookupByLibrary.simpleMessage("पुष्टि करें"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage(
      "हटाने की पुष्टि करें",
    ),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage(
      "संपर्क जानकारी (वैकल्पिक)",
    ),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage(
      "संदर्भ और स्मृति",
    ),
    "contextCompacted": MessageLookupByLibrary.simpleMessage(
      "संदर्भ संपीड़ित हुआ",
    ),
    "contextWindow": MessageLookupByLibrary.simpleMessage("संदर्भ विंडो"),
    "conversationSummary": MessageLookupByLibrary.simpleMessage(
      "वार्तालाप सारांश",
    ),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage(
      "वार्तालाप के अनुसार टोकन हिस्सेदारी",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("API कुंजी कॉपी करें"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m12,
    "createChatFailed": m13,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("बनाने का समय"),
    "customProvider": MessageLookupByLibrary.simpleMessage("कस्टम प्रदाता..."),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage("दैनिक उपयोग"),
    "darkMode": MessageLookupByLibrary.simpleMessage("डार्क मोड"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "यह डेटाबेस Stars के नए संस्करण से बनाया गया था। इसे खोलने से पहले ऐप अपडेट करें।",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "डेटाबेस अखंडता जाँच विफल रही और इस संस्करण के बैकअप से पुनर्प्राप्ति नहीं हो सकी।",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage("गहन चिंतन"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "आप एक सहायक AI हैं। कृपया हिंदी में उत्तर दें।",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("हटाएं"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("बॉट हटाएं"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("चैट हटाएं"),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "ऐप के बारे में और कानूनी जानकारी",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "दिखावट और भाषा",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "अपना अवतार और प्रदर्शन नाम बदलें।",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("सामान्य"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage(
      "सहायता और समर्थन",
    ),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage(
      "व्यक्तिगत जानकारी",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "बदलाव तुरंत लागू होते हैं और स्थानीय रूप से सहेजे जाते हैं।",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "अपनी प्रोफ़ाइल, दिखावट, भाषा और ऐप सहायता प्रबंधित करें।",
    ),
    "details": MessageLookupByLibrary.simpleMessage("विवरण"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "सभी के लिए बिना पुष्टि बंद करें",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "सभी टूल बंद करें",
    ),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "स्क्रिप्ट अक्षम करें",
    ),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("संपादित करें"),
    "editBot": MessageLookupByLibrary.simpleMessage("बॉट संपादित करें"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("स्मृति संपादित करें"),
    "editName": MessageLookupByLibrary.simpleMessage("नाम संपादित करें"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "उत्तर प्राप्त करने में विफल: सर्वर ने खाली प्रतिक्रिया लौटाई",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "सभी के लिए बिना पुष्टि चालू करें",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage(
      "सभी टूल चालू करें",
    ),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage(
      "स्क्रिप्ट सक्षम करें",
    ),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "अलग की गई कौशल स्क्रिप्ट सक्षम करें?",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage(
      "API पता दर्ज करें...",
    ),
    "enterApiKey": MessageLookupByLibrary.simpleMessage(
      "API कुंजी दर्ज करें...",
    ),
    "enterBotName": MessageLookupByLibrary.simpleMessage(
      "बॉट का नाम दर्ज करें...",
    ),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage(
      "प्रदर्शन नाम दर्ज करें",
    ),
    "enterNewName": MessageLookupByLibrary.simpleMessage(
      "कृपया नया नाम दर्ज करें",
    ),
    "enterProviderName": MessageLookupByLibrary.simpleMessage(
      "प्रदाता का नाम दर्ज करें...",
    ),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "सिस्टम प्रॉम्प्ट दर्ज करें...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "सामग्री लोड करने में त्रुटि, कृपया बाद में पुनः प्रयास करें।",
    ),
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage(
      "अनुमानित उपयोग",
    ),
    "executionStatus": MessageLookupByLibrary.simpleMessage("निष्पादन स्थिति"),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "कृपया प्रतिक्रिया सामग्री दर्ज करें",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "कृपया हमें अपने विचार, समस्याएं या सुझाव बताएं ताकि हम ऐप को बेहतर बना सकें",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "यहां अपनी प्रतिक्रिया दर्ज करें...",
    ),
    "feedbackInformation": MessageLookupByLibrary.simpleMessage(
      "प्रतिक्रिया जानकारी",
    ),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "भेजने में विफल, कृपया बाद में पुनः प्रयास करें",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "आपकी प्रतिक्रिया के लिए धन्यवाद!",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage(
      "मॉडल सूची प्राप्त करें",
    ),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "कृपया पहले मॉडल सूची प्राप्त करें",
    ),
    "fileAttachment": MessageLookupByLibrary.simpleMessage("File attachment"),
    "fileCount": m18,
    "fileResult": MessageLookupByLibrary.simpleMessage("File result"),
    "fileStatus": MessageLookupByLibrary.simpleMessage("फ़ाइल स्थिति"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("संगीत"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("वाणी"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("वीडियो"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "कृपया बॉट का नाम, API पता और API कुंजी भरें",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage(
      "सिस्टम का अनुसरण करें",
    ),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("फॉन्ट साइज़"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage(
      "फॉन्ट साइज़ अपडेट किया गया",
    ),
    "forgetMemory": MessageLookupByLibrary.simpleMessage("भूलें"),
    "generateImageFailed": m19,
    "generateMusicFailed": m20,
    "generateSpeechFailed": m21,
    "generateVideoFailed": m22,
    "generatedImage": MessageLookupByLibrary.simpleMessage("Image generated"),
    "generating": MessageLookupByLibrary.simpleMessage("Generating…"),
    "generatingImage": MessageLookupByLibrary.simpleMessage(
      "Generating image, please wait...",
    ),
    "generationFailed": MessageLookupByLibrary.simpleMessage("जनरेशन विफल"),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "जनरेशन विफल · आंशिक उत्तर रखा गया",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage(
      "सहायता और प्रतिक्रिया",
    ),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("API कुंजी छिपाएँ"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("होम"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage(
      "प्रति घंटे उपयोग",
    ),
    "idle": MessageLookupByLibrary.simpleMessage("निष्क्रिय"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage(
      "कौशल फ़ोल्डर आयात करें",
    ),
    "importSkillZip": MessageLookupByLibrary.simpleMessage(
      "कौशल ZIP आयात करें",
    ),
    "importingSkill": MessageLookupByLibrary.simpleMessage(
      "कौशल आयात हो रहा है…",
    ),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("इनपुट टोकन"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage(
      "अपडेट इंस्टॉल करें",
    ),
    "invalidSummary": MessageLookupByLibrary.simpleMessage(
      "सारांश सत्यापन में विफल रहा",
    ),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("अभी-अभी"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage("भाषा सेटिंग्स"),
    "lightMode": MessageLookupByLibrary.simpleMessage("लाइट मोड"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage(
      "स्मृति प्रबंधित करें",
    ),
    "manualActivation": MessageLookupByLibrary.simpleMessage("प्रति संदेश"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "ज़रूरत होने पर संदेश लिखने की जगह से कौशल चुनें।",
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
      "पुष्टि के बिना",
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
    "mcpServerName": MessageLookupByLibrary.simpleMessage("Server name"),
    "mcpServers": MessageLookupByLibrary.simpleMessage("MCP सर्वर"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "MCP सर्वर कनेक्ट करें और उनके टूल कैटलॉग खोजें। एजेंट बनाने के बाद टूल कॉन्फ़िगर करें।",
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
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("आर्टिफैक्ट"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "स्मृति बदल गई; फिर प्रयास करें",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("सुधार"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("निर्णय"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("तथ्य"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("पसंद"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("खुला प्रश्न"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("कार्य"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage("संदेश लिखें..."),
    "messageSkills": MessageLookupByLibrary.simpleMessage("कौशल"),
    "minutesAgo": m27,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("ऑडियो"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("फ़ाइल"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("इमेज"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("मल्टीमॉडल"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("संगीत"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("रीयल-टाइम"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("वाणी"),
    "modalityText": MessageLookupByLibrary.simpleMessage("टेक्स्ट"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("वीडियो"),
    "model": MessageLookupByLibrary.simpleMessage("मॉडल"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage(
      "मॉडल कॉन्फ़िगरेशन",
    ),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage(
      "मॉडल कॉन्टेक्स्ट आकार",
    ),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("इनपुट"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("आउटपुट"),
    "modelsRetrievedSuccess": m28,
    "modificationTime": MessageLookupByLibrary.simpleMessage("संशोधन का समय"),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("नाम"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("नाम अपडेट किया गया"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("नई चैट"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "कोई कनेक्टेड MCP टूल उपलब्ध नहीं है।",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "कोई कौशल नहीं जोड़ा गया",
    ),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "इस बॉट के लिए ज़रूरी इंस्टॉल किए गए कौशल जोड़ें।",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage(
      "कोई बॉट उपलब्ध नहीं है",
    ),
    "noChats": MessageLookupByLibrary.simpleMessage("अभी तक कोई चैट नहीं"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "कोई सामग्री नहीं मिली",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "अभी कोई वार्तालाप सारांश उपलब्ध नहीं है।",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "कोई मेल खाता बॉट नहीं मिला",
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
      "कोई मिलता-जुलता कौशल नहीं मिला",
    ),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage(
      "कोई मॉडल प्राप्त नहीं हुआ",
    ),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage(
      "कोई कौशल इंस्टॉल नहीं है",
    ),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md वाला Agent Skills फ़ोल्डर या ZIP आयात करें।",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "कोई टोकन उपयोग दर्ज नहीं है",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("समर्थित नहीं"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "संपीड़ित करने के लिए पर्याप्त पुराना संदर्भ नहीं है",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("आउटपुट टोकन"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("आंशिक उत्तर"),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("ऑडियो रोकें"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("उत्पादन रोकें"),
    "pinMemory": MessageLookupByLibrary.simpleMessage("पिन करें"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "इस बातचीत के लिए चयनित कौशल पिन करें",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("पिन किया गया"),
    "playAudio": MessageLookupByLibrary.simpleMessage("ऑडियो चलाएँ"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "कृपया पहले API कुंजी दर्ज करें",
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
    "previewText": MessageLookupByLibrary.simpleMessage("टेक्स्ट प्रीव्यू"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("गोपनीयता नीति"),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage(
      "प्रक्रिया जानकारी",
    ),
    "processToolCount": m32,
    "profile": MessageLookupByLibrary.simpleMessage("प्रोफाइल"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage(
      "अपने सुझाव और प्रतिक्रिया प्रदान करें",
    ),
    "provider": MessageLookupByLibrary.simpleMessage("प्रदाता"),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "प्रदाता की जानकारी",
    ),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage("तर्क पूर्ण"),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage("तर्क जारी"),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage("तर्क बाधित"),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("पुनर्निर्माण"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("ताज़ा करें"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "कैटलॉग रीफ़्रेश करें",
    ),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "कैटलॉग रीफ़्रेश हो रहे हैं…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("कौशल हटाएँ"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage(
      "उत्तर रद्द किया गया",
    ),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "रोक दिया गया · आंशिक उत्तर रखा गया",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage(
      "डिफ़ॉल्ट पर रीसेट करें",
    ),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("पुनर्स्थापित करें"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage(
      "हाल के रखे गए चरण",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage(
      "जाँच चलाएँ",
    ),
    "save": MessageLookupByLibrary.simpleMessage("सहेजें"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("परिवर्तन सहेजें"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("सहेजा जा रहा है..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("बॉट खोजें"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage("स्मृति खोजें"),
    "searchSkills": MessageLookupByLibrary.simpleMessage("कौशल खोजें"),
    "selectBot": MessageLookupByLibrary.simpleMessage("बॉट चुनें"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("भाषा चुनें"),
    "selectModel": MessageLookupByLibrary.simpleMessage("मॉडल चुनें:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("प्रदाता चुनें:"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("थीम चुनें"),
    "send": MessageLookupByLibrary.simpleMessage("भेजें"),
    "settings": MessageLookupByLibrary.simpleMessage("सेटिंग्स"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("API कुंजी दिखाएँ"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "बातचीत के संदेशों में निष्पादन विवरण दिखाएँ।",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage(
      "एसेट उपलब्ध हैं",
    ),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage("संगतता"),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "इस उदाहरण से कौशल सक्रिय होना चाहिए",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "उदाहरण उपयोगकर्ता अनुरोध",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage(
      "सक्रियण परिणाम",
    ),
    "skillDetails": MessageLookupByLibrary.simpleMessage("कौशल का विवरण"),
    "skillDigest": MessageLookupByLibrary.simpleMessage("सामग्री डाइजेस्ट"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("बंद"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("चालू"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("फ़ाइलें"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "कौशल आयात किया गया",
    ),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("कौशल"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "दोबारा इस्तेमाल किए जा सकने वाले निर्देश इंस्टॉल करें और उन्हें बॉट से जोड़ें।",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "यह संस्करण कौशल की स्क्रिप्ट या कमांड नहीं चलाता।",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("प्रकाशक"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "संदर्भ फ़ाइलें उपलब्ध हैं",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md को केवल नियंत्रित प्रॉम्प्ट निर्देश के रूप में लोड किया जाता है; स्क्रिप्ट, कमांड और बाहरी टूल अक्षम रहते हैं।",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "डेस्कटॉप स्क्रिप्ट सैंडबॉक्स उपलब्ध",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "आपकी अनुमति तक स्क्रिप्ट बंद रहती हैं। हर कॉल के लिए फिर भी स्वीकृति आवश्यक है।",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "कौशल स्क्रिप्ट उपलब्ध नहीं",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "यह प्लेटफ़ॉर्म आवश्यक अलगाव नहीं देता। निर्देश और संसाधन उपलब्ध रहेंगे।",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "कौशल स्क्रिप्ट सेटिंग अपडेट हुई।",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "स्क्रिप्ट इंस्टॉल हैं, लेकिन उनका निष्पादन अक्षम है।",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage(
      "स्क्रिप्ट सक्षम",
    ),
    "skillSignature": MessageLookupByLibrary.simpleMessage("हस्ताक्षर"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage(
      "अमान्य हस्ताक्षर",
    ),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "अज्ञात प्रकाशक",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage(
      "अहस्ताक्षरित",
    ),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage(
      "सत्यापित हस्ताक्षर",
    ),
    "skillSource": MessageLookupByLibrary.simpleMessage("स्रोत"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("स्वचालित"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage(
      "अपडेट उपलब्ध",
    ),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("मैन्युअल"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("सूचित करें"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("पिन किया गया"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage("अपडेट नीति"),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("उपयोगकर्ता"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage(
      "सत्यापन टिप्पणियाँ",
    ),
    "skillVersion": MessageLookupByLibrary.simpleMessage("संस्करण"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "चैट शुरू करने के लिए नीचे इनपुट फील्ड में संदेश भेजें",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("चैटिंग शुरू करें"),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "शुरू नहीं हो सका। फिर से कोशिश करें।",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage("शुरू हो रहा है…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("सक्रिय"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("संलग्न"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage(
      "स्वीकृति की प्रतीक्षा",
    ),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("रद्द"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("पूर्ण"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("अस्वीकृत"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage("डुप्लिकेट कॉल"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("विफल"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("जनरेट किया गया"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("प्रगति में"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("दर्ज"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("अनुरोधित"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("चल रहा है"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("छोड़ा गया"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("समय समाप्त"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("अज्ञात"),
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
      "संरचित प्रक्रिया जानकारी",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("प्रतिक्रिया भेजें"),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage("सारांशित संदेश"),
    "supported": MessageLookupByLibrary.simpleMessage("समर्थित"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("MCP समर्थित है"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage(
      "Skills समर्थित हैं",
    ),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("सिस्टम प्रॉम्प्ट"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("जाँचें"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage(
      "विवरण जाँचें",
    ),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "थीम डार्क मोड पर सेट की गई",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "थीम लाइट मोड पर सेट की गई",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "थीम सिस्टम के अनुसार सेट की गई",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage("थीम सेटिंग्स"),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage("सोचना पूर्ण"),
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("सोच रहा है…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("टोकन उपयोग"),
    "tokens": MessageLookupByLibrary.simpleMessage("टोकन"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage(
      "एक बार अनुमति",
    ),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("अस्वीकृत"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("टूल कॉल"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("विनाशकारी"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage(
      "केवल-पढ़ने योग्य",
    ),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("लिखना"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("अंतर्निहित"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage(
      "स्किल स्क्रिप्ट",
    ),
    "totalTokens": MessageLookupByLibrary.simpleMessage("कुल टोकन"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "किसी अन्य खोज का प्रयास करें या नया आइटम बनाएँ।",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("टाइप कर रहा है..."),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage(
      "Unable to load bots",
    ),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage(
      "Unable to load chats",
    ),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage(
      "Unable to load messages",
    ),
    "unavailableBot": MessageLookupByLibrary.simpleMessage(
      "बॉट उपलब्ध नहीं है",
    ),
    "uninstall": MessageLookupByLibrary.simpleMessage("अनइंस्टॉल करें"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage(
      "कौशल अनइंस्टॉल करें",
    ),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("अनपिन करें"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "यह इमेज फ़ॉर्मैट समर्थित नहीं है। JPEG, PNG, GIF, BMP या WebP इमेज चुनें।",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("फ़ाइल अपलोड करें"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("छवि अपलोड करें"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("उपयोगकर्ता समझौता"),
    "version": MessageLookupByLibrary.simpleMessage("संस्करण 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage(
      "वीडियो लोड नहीं हो सका",
    ),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("सारांश देखें"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
