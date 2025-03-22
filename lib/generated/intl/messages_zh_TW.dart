// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_TW locale. All the
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
  String get localeName => 'zh_TW';

  static String m0(name) => "智能體 \"${name}\" 已添加";

  static String m1(botName) => "智能體 ${botName} 已更新";

  static String m2(botName) => "已刪除與 ${botName} 的聊天";

  static String m3(botName) => "刪除機器人會刪除對應的聊天記錄，確定要刪除 ${botName} 嗎？";

  static String m4(botName) => "刪除聊天會清空所有的聊天記錄，確定要刪除與 ${botName} 的聊天嗎？";

  static String m5(language) => "語言已設置為${language}";

  static String m6(minutes) => "${minutes}分鐘前";

  static String m7(error) => "獲取回覆失敗: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("智能體"),
    "about": MessageLookupByLibrary.simpleMessage("關於"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("關於泡泡"),
    "addBot": MessageLookupByLibrary.simpleMessage("添加機器人"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage("調整應用內文字大小"),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("調整文字大小"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API地址:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API密鑰"),
    "apiType": MessageLookupByLibrary.simpleMessage("API類型:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "一個簡單而強大的AI聊天應用，讓您隨時隨地與AI進行對話。",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("泡泡"),
    "appTitle": MessageLookupByLibrary.simpleMessage("泡泡 - AI聊天助手"),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("機器人頭像"),
    "botName": MessageLookupByLibrary.simpleMessage("機器人名稱"),
    "botUpdated": m1,
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "chatDeleted": m2,
    "chats": MessageLookupByLibrary.simpleMessage("聊天"),
    "clearChat": MessageLookupByLibrary.simpleMessage("清空聊天"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage("清空聊天記錄"),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage("點擊右上角 + 添加智能體"),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage("點擊右上角 + 開始聊天"),
    "confirm": MessageLookupByLibrary.simpleMessage("確定"),
    "confirmDeleteBot": m3,
    "confirmDeleteChat": m4,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage("聯絡方式（可選）"),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 泡泡團隊"),
    "customProvider": MessageLookupByLibrary.simpleMessage("自定義供應商..."),
    "darkMode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "你是一個有用的AI助手，請用繁體中文回答問題。",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("刪除"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("刪除智能體"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("刪除聊天"),
    "editBot": MessageLookupByLibrary.simpleMessage("編輯機器人"),
    "editName": MessageLookupByLibrary.simpleMessage("修改名稱"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "獲取回覆失敗: 伺服器返回空響應",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage("輸入API地址..."),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("輸入API密鑰..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("請輸入名稱..."),
    "enterNewName": MessageLookupByLibrary.simpleMessage("請輸入新名稱"),
    "enterProviderName": MessageLookupByLibrary.simpleMessage("輸入供應商名稱..."),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage("輸入系統提示詞..."),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "載入內容時出錯，請稍後再試。",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage("請輸入反饋內容"),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "請告訴我們您的想法、問題或建議，幫助我們改進應用",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage("請在此輸入您的反饋內容..."),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage("提交失敗，請稍後重試"),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage("感謝您的反饋！"),
    "fetchModelList": MessageLookupByLibrary.simpleMessage("獲取模型列表"),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage("請先獲取模型列表"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "請填寫智能體名稱、API地址和API密鑰",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("文字大小"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage("文字大小已更新"),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("幫助與反饋"),
    "home": MessageLookupByLibrary.simpleMessage("首頁"),
    "justNow": MessageLookupByLibrary.simpleMessage("剛剛"),
    "languageChanged": m5,
    "languageSettings": MessageLookupByLibrary.simpleMessage("語言設定"),
    "lightMode": MessageLookupByLibrary.simpleMessage("淺色模式"),
    "messageHint": MessageLookupByLibrary.simpleMessage("輸入消息..."),
    "minutesAgo": m6,
    "model": MessageLookupByLibrary.simpleMessage("模型"),
    "name": MessageLookupByLibrary.simpleMessage("名稱"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("名稱已更新"),
    "newChat": MessageLookupByLibrary.simpleMessage("新建聊天"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage("沒有可用的智能體"),
    "noChats": MessageLookupByLibrary.simpleMessage("還沒有聊天記錄"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage("請先輸入API密鑰"),
    "previewText": MessageLookupByLibrary.simpleMessage("預覽文字效果"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("隱私政策"),
    "profile": MessageLookupByLibrary.simpleMessage("我的"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage("提供您的意見和建議"),
    "provider": MessageLookupByLibrary.simpleMessage("供應商"),
    "responseError": m7,
    "save": MessageLookupByLibrary.simpleMessage("儲存"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("儲存修改"),
    "selectBot": MessageLookupByLibrary.simpleMessage("選擇智能體"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("選擇語言"),
    "selectModel": MessageLookupByLibrary.simpleMessage("選擇模型:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("選擇提供商:"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("選擇主題"),
    "send": MessageLookupByLibrary.simpleMessage("發送"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "startChatting": MessageLookupByLibrary.simpleMessage("開始聊天吧"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("提交反饋"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("系統提示詞"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage("已設置為深色模式"),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage("已設置為淺色模式"),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage("已設置為跟隨系統主題"),
    "themeSettings": MessageLookupByLibrary.simpleMessage("主題設定"),
    "typing": MessageLookupByLibrary.simpleMessage("正在輸入..."),
    "userAgreement": MessageLookupByLibrary.simpleMessage("用戶協議"),
    "version": MessageLookupByLibrary.simpleMessage("版本 1.0.0"),
  };
}
