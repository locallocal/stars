// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_CN locale. All the
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
  String get localeName => 'zh_CN';

  static String m0(name) => "智能体 \"${name}\" 已添加";

  static String m1(botName) => "\"${botName}\" 已被删除";

  static String m2(botName) => "你好！我是${botName}，一个AI助手。请随时向我提问，我会尽力帮助你。";

  static String m3(botName) => "${botName}正在输入...";

  static String m4(botName) => "智能体 ${botName} 已更新";

  static String m5(botName) => "已删除与 ${botName} 的聊天";

  static String m6(botName) => "确定要清空与 \"${botName}\" 的所有聊天记录吗？此操作不可恢复。";

  static String m7(botName) => "删除机器人会删除对应的聊天记录，确定要删除 ${botName} 吗？";

  static String m8(botName) => "删除聊天会清空所有的聊天记录，确定要删除与 ${botName} 的聊天吗？";

  static String m9(language) => "语言已设置为${language}";

  static String m10(minutes) => "${minutes}分钟前";

  static String m11(error) => "获取回复失败: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("智能体"),
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("关于泡泡"),
    "addBot": MessageLookupByLibrary.simpleMessage("添加智能体"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage("调整应用内文字大小"),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("调整文字大小"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API地址:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API密钥"),
    "apiType": MessageLookupByLibrary.simpleMessage("API类型:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "一个简单而强大的AI聊天应用，让您随时随地与AI进行对话。",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("泡泡"),
    "appTitle": MessageLookupByLibrary.simpleMessage("泡泡 - AI聊天助手"),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("智能体头像"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botIsTyping": m3,
    "botName": MessageLookupByLibrary.simpleMessage("智能体名称"),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "chatDeleted": m5,
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage("聊天记录已清空"),
    "chats": MessageLookupByLibrary.simpleMessage("聊天"),
    "clear": MessageLookupByLibrary.simpleMessage("清理"),
    "clearChat": MessageLookupByLibrary.simpleMessage("清空聊天"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage("清空聊天记录"),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage("点击右上角 + 添加智能体"),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage("点击右上角 + 开始聊天"),
    "confirm": MessageLookupByLibrary.simpleMessage("确定"),
    "confirmClearChat": m6,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("确认删除"),
    "confirmDeleteBot": m7,
    "confirmDeleteChat": m8,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage("联系方式（可选）"),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 泡泡团队"),
    "customProvider": MessageLookupByLibrary.simpleMessage("自定义供应商..."),
    "darkMode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "你是一个有用的AI助手，请用中文回答问题。",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("删除智能体"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("删除聊天"),
    "editBot": MessageLookupByLibrary.simpleMessage("编辑智能体"),
    "editName": MessageLookupByLibrary.simpleMessage("修改名称"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "获取回复失败: 服务器返回空响应",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage("输入API地址..."),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("输入API密钥..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("请输入名称..."),
    "enterNewName": MessageLookupByLibrary.simpleMessage("请输入新名称"),
    "enterProviderName": MessageLookupByLibrary.simpleMessage("输入供应商名称..."),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage("输入系统提示词..."),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "加载内容时出错，请稍后再试。",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage("请输入反馈内容"),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "请告诉我们您的想法、问题或建议，帮助我们改进应用",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage("请在此输入您的反馈内容..."),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage("提交失败，请稍后重试"),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage("感谢您的反馈！"),
    "fetchModelList": MessageLookupByLibrary.simpleMessage("获取模型列表"),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage("请先获取模型列表"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "请填写智能体名称、API地址和API密钥",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("文字大小"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage("文字大小已更新"),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("帮助与反馈"),
    "home": MessageLookupByLibrary.simpleMessage("首页"),
    "justNow": MessageLookupByLibrary.simpleMessage("刚刚"),
    "languageChanged": m9,
    "languageSettings": MessageLookupByLibrary.simpleMessage("语言设置"),
    "lightMode": MessageLookupByLibrary.simpleMessage("浅色模式"),
    "messageHint": MessageLookupByLibrary.simpleMessage("输入消息..."),
    "minutesAgo": m10,
    "model": MessageLookupByLibrary.simpleMessage("模型"),
    "name": MessageLookupByLibrary.simpleMessage("名称"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("名称已更新"),
    "newChat": MessageLookupByLibrary.simpleMessage("新建聊天"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage("没有可用的智能体"),
    "noChats": MessageLookupByLibrary.simpleMessage("还没有聊天记录"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("暂停生成"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage("请先输入API密钥"),
    "previewText": MessageLookupByLibrary.simpleMessage("预览文字效果"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("隐私政策"),
    "profile": MessageLookupByLibrary.simpleMessage("我的"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage("提供您的意见和建议"),
    "provider": MessageLookupByLibrary.simpleMessage("供应商"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("已取消回复"),
    "responseError": m11,
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("保存修改"),
    "selectBot": MessageLookupByLibrary.simpleMessage("选择智能体"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("选择语言"),
    "selectModel": MessageLookupByLibrary.simpleMessage("选择模型:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("选择提供商:"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("选择主题"),
    "send": MessageLookupByLibrary.simpleMessage("发送"),
    "settings": MessageLookupByLibrary.simpleMessage("设置"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage("在下方输入框发送消息开始聊天"),
    "startChatting": MessageLookupByLibrary.simpleMessage("开始聊天吧"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("提交反馈"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("系统提示词:"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage("已设置为深色模式"),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage("已设置为浅色模式"),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage("已设置为跟随系统主题"),
    "themeSettings": MessageLookupByLibrary.simpleMessage("主题设置"),
    "typing": MessageLookupByLibrary.simpleMessage("正在输入..."),
    "userAgreement": MessageLookupByLibrary.simpleMessage("用户协议"),
    "version": MessageLookupByLibrary.simpleMessage("版本 1.0.0"),
  };
}
