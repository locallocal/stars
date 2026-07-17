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

  static String m13(error) => "生成图片失败: ${error}";

  static String m14(count) => "${count} 项";

  static String m15(count) => "${count} 个文件";

  static String m16(error) => "保存图片失败：${error}";

  static String m17(error) => "分享图片失败：${error}";

  static String m18(duration) => "耗时 ${duration}";

  static String m19(count) => "${count} 次工具调用";

  static String m20(count) => "${count} 次命令执行";

  static String m21(count) => "${count} 条文件状态";

  static String m22(duration) => "思考完成 · ${duration}";

  static String m23(error) => "生成语音失败：${error}";

  static String m24(error) => "生成音乐失败：${error}";

  static String m25(error) => "生成视频失败：${error}";

  static String m26(error) => "创建聊天失败：${error}";

  static String m27(error) => "清空聊天记录失败：${error}";

  static String m28(error) => "删除会话失败：${error}";

  static String m9(language) => "语言已设置为${language}";

  static String m10(minutes) => "${minutes}分钟前";

  static String m11(count) => "成功获取${count}个模型";

  static String m12(error) => "获取回复失败: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("智能体"),
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("关于 Stars"),
    "addAttachment": MessageLookupByLibrary.simpleMessage("上传附件"),
    "addBot": MessageLookupByLibrary.simpleMessage("添加智能体"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage("调整应用内文字大小"),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("调整文字大小"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API地址:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API密钥"),
    "apiType": MessageLookupByLibrary.simpleMessage("API类型:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "一个简单而强大的AI聊天应用，让您随时随地与AI进行对话。",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Stars - AI 聊天助手"),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("附件文件"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("附加图片"),
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
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("相册"),
    "clear": MessageLookupByLibrary.simpleMessage("清理"),
    "clearChat": MessageLookupByLibrary.simpleMessage("清空聊天"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage("清空聊天记录"),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage("点击右上角 + 添加智能体"),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage("点击新建聊天创建会话"),
    "confirm": MessageLookupByLibrary.simpleMessage("确定"),
    "confirmClearChat": m6,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("确认删除"),
    "confirmDeleteBot": m7,
    "confirmDeleteChat": m8,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage("联系方式（可选）"),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 Stars 团队"),
    "customProvider": MessageLookupByLibrary.simpleMessage("自定义供应商..."),
    "darkMode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "deepThinking": MessageLookupByLibrary.simpleMessage("深度思考"),
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
    "generateImageFailed": m13,
    "generatedImage": MessageLookupByLibrary.simpleMessage("图片已生成"),
    "generatingImage": MessageLookupByLibrary.simpleMessage("正在生成图片，请稍候..."),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("帮助与反馈"),
    "home": MessageLookupByLibrary.simpleMessage("首页"),
    "justNow": MessageLookupByLibrary.simpleMessage("刚刚"),
    "languageChanged": m9,
    "languageSettings": MessageLookupByLibrary.simpleMessage("语言设置"),
    "lightMode": MessageLookupByLibrary.simpleMessage("浅色模式"),
    "messageCopied": MessageLookupByLibrary.simpleMessage("消息已复制到剪贴板"),
    "messageHint": MessageLookupByLibrary.simpleMessage("输入消息..."),
    "minutesAgo": m10,
    "model": MessageLookupByLibrary.simpleMessage("模型"),
    "modelsRetrievedSuccess": m11,
    "name": MessageLookupByLibrary.simpleMessage("名称"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("名称已更新"),
    "newChat": MessageLookupByLibrary.simpleMessage("新建聊天"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage("没有可用的智能体"),
    "noChats": MessageLookupByLibrary.simpleMessage("还没有聊天记录"),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage("未获取到模型列表"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("暂停生成"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage("请先输入API密钥"),
    "pleaseEnterImageDescription": MessageLookupByLibrary.simpleMessage(
      "请输入生成图片的描述",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage("预览文字效果"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("隐私政策"),
    "profile": MessageLookupByLibrary.simpleMessage("我的"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage("提供您的意见和建议"),
    "provider": MessageLookupByLibrary.simpleMessage("供应商"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("已取消回复"),
    "responseError": m12,
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
    "takePhoto": MessageLookupByLibrary.simpleMessage("拍照"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage("已设置为深色模式"),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage("已设置为浅色模式"),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage("已设置为跟随系统主题"),
    "themeSettings": MessageLookupByLibrary.simpleMessage("主题设置"),
    "typing": MessageLookupByLibrary.simpleMessage("正在输入..."),
    "uploadFile": MessageLookupByLibrary.simpleMessage("文件"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("图片"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("用户协议"),
    "version": MessageLookupByLibrary.simpleMessage("版本 1.0.0"),
    "searchChats": MessageLookupByLibrary.simpleMessage("搜索会话"),
    "searchBots": MessageLookupByLibrary.simpleMessage("搜索智能体"),
    "noMatchingChats": MessageLookupByLibrary.simpleMessage("没有找到匹配的聊天"),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage("个人信息"),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "外观与语言",
    ),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage("帮助与支持"),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage("关于与法律信息"),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "管理个人信息、外观、语言与应用支持。",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "修改头像与展示名称。",
    ),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "修改后会立即生效并保存到本地。",
    ),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("更换头像"),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("恢复默认"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("隐藏侧栏"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("显示侧栏"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("隐藏智能体信息"),
    "showInspector": MessageLookupByLibrary.simpleMessage("显示智能体信息"),
    "botInformation": MessageLookupByLibrary.simpleMessage("智能体信息"),
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("回到最新"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("图像风格"),
    "imageSize": MessageLookupByLibrary.simpleMessage("图像尺寸"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "generating": MessageLookupByLibrary.simpleMessage("正在生成…"),
    "stopping": MessageLookupByLibrary.simpleMessage("正在停止…"),
    "basicInformation": MessageLookupByLibrary.simpleMessage("基本信息"),
    "providerInformation": MessageLookupByLibrary.simpleMessage("提供商信息"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage("模型配置"),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("复制 API 密钥"),
    "showApiKey": MessageLookupByLibrary.simpleMessage("显示 API 密钥"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("隐藏 API 密钥"),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage("没有找到匹配的智能体"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "试试其他关键词，或直接新建。",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "搜索会匹配智能体名称和最后一条消息。",
    ),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "新建聊天后会直接在工作区打开会话。",
    ),
    "botSearchScope": MessageLookupByLibrary.simpleMessage("搜索会按智能体名称过滤列表。"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "新建智能体会留在工作区中继续编辑。",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("重试"),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage("无法加载聊天列表"),
    "clearSearch": MessageLookupByLibrary.simpleMessage("清除搜索"),
    "unavailableBot": MessageLookupByLibrary.simpleMessage("智能体不可用"),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage("此智能体已不可用"),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "删除这条孤立会话，或重新创建缺失的智能体。",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage("当前请求无法停止"),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "请等待生成完成。",
    ),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "请等待生成完成后再离开当前会话。",
    ),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "当前请求无法取消，请等待生成完成。",
    ),
    "attachments": MessageLookupByLibrary.simpleMessage("附件"),
    "itemCount": m14,
    "fileCount": m15,
    "clearAttachments": MessageLookupByLibrary.simpleMessage("清空附件"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage("移除图片"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("移除文件"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("图片附件"),
    "imageResult": MessageLookupByLibrary.simpleMessage("图片结果"),
    "fileAttachment": MessageLookupByLibrary.simpleMessage("文件附件"),
    "fileResult": MessageLookupByLibrary.simpleMessage("文件结果"),
    "speechResult": MessageLookupByLibrary.simpleMessage("语音结果"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("参考音频"),
    "musicResult": MessageLookupByLibrary.simpleMessage("音乐结果"),
    "videoResult": MessageLookupByLibrary.simpleMessage("视频结果"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("可直接播放"),
    "directPreview": MessageLookupByLibrary.simpleMessage("可直接预览"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage("已停止 · 保留部分回复"),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "生成失败 · 保留部分回复",
    ),
    "generationFailed": MessageLookupByLibrary.simpleMessage("生成失败"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage("未返回内容"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("部分回复"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("已完成"),
    "saveImage": MessageLookupByLibrary.simpleMessage("保存图片"),
    "shareImage": MessageLookupByLibrary.simpleMessage("分享图片"),
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage("保存到相册失败"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage("图片已保存到相册"),
    "saveImageFailed": m16,
    "shareImageFailed": m17,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "来自 Stars 的图片",
    ),
    "processDuration": m18,
    "processToolCount": m19,
    "processCommandCount": m20,
    "processFileCount": m21,
    "executionStatus": MessageLookupByLibrary.simpleMessage("执行状态"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("工具调用"),
    "commandExecutions": MessageLookupByLibrary.simpleMessage("命令执行"),
    "fileStatus": MessageLookupByLibrary.simpleMessage("文件状态"),
    "includesDuration": MessageLookupByLibrary.simpleMessage("包含耗时"),
    "structuredProcessInfo": MessageLookupByLibrary.simpleMessage("结构化过程信息"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("已生成"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("已附加"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("进行中"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("执行中"),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("已取消"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("失败"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("已记录"),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage("思考完成"),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage("思考中断"),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage("思考中"),
    "processInformation": MessageLookupByLibrary.simpleMessage("过程信息"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("语音"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("音乐"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("视频"),
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("正在思考…"),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage("思考完成"),
    "thinkingCompletedWithDuration": m22,
    "pleaseEnterSpeechDescription": MessageLookupByLibrary.simpleMessage(
      "请输入语音描述",
    ),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("语音已生成"),
    "generateSpeechFailed": m23,
    "pleaseEnterMusicDescription": MessageLookupByLibrary.simpleMessage(
      "请输入音乐描述",
    ),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("音乐已生成"),
    "generateMusicFailed": m24,
    "pleaseEnterVideoDescription": MessageLookupByLibrary.simpleMessage(
      "请输入视频描述",
    ),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("视频已生成"),
    "generateVideoFailed": m25,
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage("无法打开此链接。"),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage("无法加载智能体"),
    "creatingChat": MessageLookupByLibrary.simpleMessage("正在创建…"),
    "createChatFailed": m26,
    "stopGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "离开前停止生成？",
    ),
    "stopGenerationBeforeLeavingDescription":
        MessageLookupByLibrary.simpleMessage("已生成的部分回复会被保留。"),
    "stopAndContinue": MessageLookupByLibrary.simpleMessage("停止并继续"),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage("无法加载消息"),
    "clearChatFailed": m27,
    "deleteChatFailed": m28,
    "webSearch": MessageLookupByLibrary.simpleMessage("联网搜索"),
  };
}
