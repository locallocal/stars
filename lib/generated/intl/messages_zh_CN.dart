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

  static String m6(error) => "清空聊天记录失败：${error}";

  static String m7(botName) => "确定要清空与 \"${botName}\" 的所有聊天记录吗？此操作不可恢复。";

  static String m8(botName) => "删除机器人会删除对应的聊天记录，确定要删除 ${botName} 吗？";

  static String m9(botName) => "删除聊天会清空所有的聊天记录，确定要删除与 ${botName} 的聊天吗？";

  static String m10(name) => "确定删除“${name}”？缓存的工具目录和安全凭据也会一并移除。";

  static String m11(name) => "确定卸载技能“${name}”？相关智能体绑定也会被移除。";

  static String m12(year) => "© ${year} Stars 团队";

  static String m13(error) => "创建聊天失败：${error}";

  static String m14(error) => "删除会话失败：${error}";

  static String m15(milliseconds) => "${milliseconds} 毫秒";

  static String m16(seconds) => "${seconds} 秒";

  static String m17(name) => "允许“${name}”将已声明的脚本注册为工具。每次调用仍需审批，并在桌面沙箱中运行。";

  static String m18(count) => "${count} 个文件";

  static String m19(error) => "生成图片失败: ${error}";

  static String m20(error) => "生成音乐失败：${error}";

  static String m21(error) => "生成语音失败：${error}";

  static String m22(error) => "生成视频失败：${error}";

  static String m23(count) => "${count} 项";

  static String m24(language) => "语言已设置为${language}";

  static String m25(error) => "MCP 连接失败：${error}";

  static String m26(count) => "${count} 个（值已隐藏）";

  static String m27(minutes) => "${minutes}分钟前";

  static String m28(count) => "成功获取${count}个模型";

  static String m29(count) => "${count} 次命令执行";

  static String m30(duration) => "耗时 ${duration}";

  static String m31(count) => "${count} 条文件状态";

  static String m32(count) => "${count} 次工具调用";

  static String m33(error) => "获取回复失败: ${error}";

  static String m34(error) => "保存图片失败：${error}";

  static String m35(error) => "分享图片失败：${error}";

  static String m36(error) => "技能导入失败：${error}";

  static String m37(duration) => "思考完成 · ${duration}";

  static String m38(error) => "视频播放错误：${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("智能体"),
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("关于 Stars"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "当前请求无法取消，请等待生成完成。",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage("当前请求无法停止"),
    "addAttachment": MessageLookupByLibrary.simpleMessage("上传附件"),
    "addBot": MessageLookupByLibrary.simpleMessage("添加智能体"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("添加 MCP 服务器"),
    "addSkill": MessageLookupByLibrary.simpleMessage("添加技能"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage("调整应用内文字大小"),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("调整文字大小"),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage("所有已安装技能均已添加。"),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("始终启用"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "每次文本请求都会注入此技能。",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("始终启用"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API地址"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API密钥"),
    "apiType": MessageLookupByLibrary.simpleMessage("API类型"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "一个简单而强大的AI聊天应用，让您随时随地与AI进行对话。",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Stars - AI 聊天助手"),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage("系统提示词"),
    "applicationInjectedPromptDescription":
        MessageLookupByLibrary.simpleMessage(
          "由 Stars 管理并注入到每次模型请求中。当前智能体与会话标识会在运行时补充，不可编辑。",
        ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("附加文件"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("附加图片"),
    "attachments": MessageLookupByLibrary.simpleMessage("附件"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("自动激活"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "让支持的模型根据技能描述按需激活。",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "当前模型服务仅支持手动使用技能。",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage("自动记忆"),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "自动摘要可能不准确，当前消息始终优先。",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage("返回每日用量"),
    "basicInformation": MessageLookupByLibrary.simpleMessage("基本信息"),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("智能体头像"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("智能体信息"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "按工具开启当前智能体可使用的 MCP 能力；默认每次调用都需要确认。",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("智能体名称"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage("搜索会按智能体名称过滤列表。"),
    "botSkills": MessageLookupByLibrary.simpleMessage("技能"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "选择这个智能体可以使用的可复用指令。",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage("此智能体已不可用"),
    "botUpdated": m4,
    "browseConversationDirectory": MessageLookupByLibrary.simpleMessage(
      "查看会话数据",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("更换头像"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("已保存"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage("会话执行状态"),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage("聊天记录已清空"),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "搜索会匹配智能体名称和最后一条消息。",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("聊天"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("相册"),
    "clear": MessageLookupByLibrary.simpleMessage("清理"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage("清空附件"),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage("清除自动记忆"),
    "clearChat": MessageLookupByLibrary.simpleMessage("清空聊天"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage("清空聊天记录"),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage("清除会话固定技能"),
    "clearSearch": MessageLookupByLibrary.simpleMessage("清除搜索"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "选择一天查看小时用量",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage("点击右上角 + 添加智能体"),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage("点击新建聊天创建会话"),
    "commandExecutions": MessageLookupByLibrary.simpleMessage("命令执行"),
    "compactNow": MessageLookupByLibrary.simpleMessage("立即压缩"),
    "compactingContext": MessageLookupByLibrary.simpleMessage("正在整理上下文…"),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("失败"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage("压缩状态"),
    "confirm": MessageLookupByLibrary.simpleMessage("确定"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("确认删除"),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage("联系方式（可选）"),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage("上下文与记忆"),
    "contextCompacted": MessageLookupByLibrary.simpleMessage("上下文已压缩"),
    "contextWindow": MessageLookupByLibrary.simpleMessage("上下文窗口"),
    "conversationDirectory": MessageLookupByLibrary.simpleMessage("会话数据目录"),
    "conversationDirectoryDescription": MessageLookupByLibrary.simpleMessage(
      "查看此会话存储的文件和文件夹。",
    ),
    "conversationDirectoryEmpty": MessageLookupByLibrary.simpleMessage(
      "此会话数据目录为空。",
    ),
    "conversationSummary": MessageLookupByLibrary.simpleMessage("会话摘要"),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage(
      "会话 Token 占比",
    ),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("复制 API 密钥"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage("复制安装位置"),
    "copyright": m12,
    "createChatFailed": m13,
    "creatingChat": MessageLookupByLibrary.simpleMessage("正在创建…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("创建时间"),
    "customProvider": MessageLookupByLibrary.simpleMessage("自定义供应商..."),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage("每日用量"),
    "darkMode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "数据库由更高版本的 Stars 创建，请升级应用后再打开。",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "数据库完整性检查失败，且无法从当前版本备份恢复。",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage("深度思考"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "你是一个有用的AI助手，请用中文回答问题。",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("删除智能体"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("删除聊天"),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage("删除 MCP 服务器"),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage("关于与法律信息"),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "外观与语言",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "修改头像与展示名称。",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("通用"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage("帮助与支持"),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage("个人信息"),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "修改后会立即生效并保存到本地。",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "管理个人信息、外观、语言与应用支持。",
    ),
    "details": MessageLookupByLibrary.simpleMessage("详情"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("可直接播放"),
    "directPreview": MessageLookupByLibrary.simpleMessage("可直接预览"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "全部关闭免确认",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage("全部关闭工具"),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage("停用脚本"),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("编辑"),
    "editBot": MessageLookupByLibrary.simpleMessage("编辑智能体"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("编辑 MCP 服务器"),
    "editMemory": MessageLookupByLibrary.simpleMessage("编辑记忆"),
    "editName": MessageLookupByLibrary.simpleMessage("修改名称"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "获取回复失败: 服务器返回空响应",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "全部开启免确认",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage("全部开启工具"),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage("启用脚本"),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "启用隔离的技能脚本？",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage("输入API地址..."),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("输入API密钥..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("请输入名称..."),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage("请输入展示名称"),
    "enterNewName": MessageLookupByLibrary.simpleMessage("请输入新名称"),
    "enterProviderName": MessageLookupByLibrary.simpleMessage("输入供应商名称..."),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage("输入系统提示词..."),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "加载内容时出错，请稍后再试。",
    ),
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage("预计本轮占用"),
    "executionStatus": MessageLookupByLibrary.simpleMessage("执行状态"),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage("请输入反馈内容"),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "请告诉我们您的想法、问题或建议，帮助我们改进应用",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage("请在此输入您的反馈内容..."),
    "feedbackInformation": MessageLookupByLibrary.simpleMessage("反馈信息"),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage("提交失败，请稍后重试"),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage("感谢您的反馈！"),
    "fetchModelList": MessageLookupByLibrary.simpleMessage("获取模型列表"),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage("请先获取模型列表"),
    "fileAttachment": MessageLookupByLibrary.simpleMessage("文件附件"),
    "fileCount": m18,
    "fileMissing": MessageLookupByLibrary.simpleMessage("此文件已不存在。"),
    "fileOpenFailed": MessageLookupByLibrary.simpleMessage("无法打开此文件。"),
    "filePreviewUnavailable": MessageLookupByLibrary.simpleMessage(
      "此文件类型无法在应用内预览，请使用系统应用打开。",
    ),
    "fileResult": MessageLookupByLibrary.simpleMessage("文件结果"),
    "fileStatus": MessageLookupByLibrary.simpleMessage("文件状态"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("音乐"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("语音"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("视频"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "请填写智能体名称、API地址和API密钥",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("文字大小"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage("文字大小已更新"),
    "forgetMemory": MessageLookupByLibrary.simpleMessage("遗忘"),
    "generateImageFailed": m19,
    "generateMusicFailed": m20,
    "generateSpeechFailed": m21,
    "generateVideoFailed": m22,
    "generatedImage": MessageLookupByLibrary.simpleMessage("图片已生成"),
    "generating": MessageLookupByLibrary.simpleMessage("正在生成…"),
    "generatingImage": MessageLookupByLibrary.simpleMessage("正在生成图片，请稍候..."),
    "generationFailed": MessageLookupByLibrary.simpleMessage("生成失败"),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "生成失败 · 保留部分回复",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("帮助与反馈"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("隐藏 API 密钥"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("隐藏智能体信息"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("隐藏侧栏"),
    "home": MessageLookupByLibrary.simpleMessage("首页"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage("小时用量"),
    "htmlPreview": MessageLookupByLibrary.simpleMessage("HTML 预览"),
    "idle": MessageLookupByLibrary.simpleMessage("空闲"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("图片附件"),
    "imageResult": MessageLookupByLibrary.simpleMessage("图片结果"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage("图片已保存到相册"),
    "imageSize": MessageLookupByLibrary.simpleMessage("图像尺寸"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("图像风格"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage("导入技能文件夹"),
    "importSkillZip": MessageLookupByLibrary.simpleMessage("导入技能 ZIP"),
    "importingSkill": MessageLookupByLibrary.simpleMessage("正在导入技能…"),
    "includesDuration": MessageLookupByLibrary.simpleMessage("包含耗时"),
    "inputTokens": MessageLookupByLibrary.simpleMessage("输入 Token"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage("安装更新"),
    "invalidSummary": MessageLookupByLibrary.simpleMessage("生成的摘要未通过校验"),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("回到最新"),
    "justNow": MessageLookupByLibrary.simpleMessage("刚刚"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage("语言设置"),
    "lightMode": MessageLookupByLibrary.simpleMessage("浅色模式"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage("无法打开此链接。"),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "基于本地进程的 MCP 服务器仍处于禁用状态，待完成各平台安全评审后再开放。",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("管理记忆"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("按消息启用"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "需要时从消息输入框选择技能。",
    ),
    "mcpAccessToken": MessageLookupByLibrary.simpleMessage(
      "OAuth / Bearer 访问令牌",
    ),
    "mcpArguments": MessageLookupByLibrary.simpleMessage("参数"),
    "mcpArgumentsDescription": MessageLookupByLibrary.simpleMessage(
      "每行填写一个参数。",
    ),
    "mcpAuthentication": MessageLookupByLibrary.simpleMessage("身份验证"),
    "mcpAuthorizationRequired": MessageLookupByLibrary.simpleMessage("需要授权"),
    "mcpCommand": MessageLookupByLibrary.simpleMessage("命令"),
    "mcpCommandDescription": MessageLookupByLibrary.simpleMessage(
      "填写可执行文件名称或绝对路径；命令将直接运行，不经过 Shell。",
    ),
    "mcpCommunicationChannel": MessageLookupByLibrary.simpleMessage("通信通道"),
    "mcpConnected": MessageLookupByLibrary.simpleMessage("已连接"),
    "mcpConnecting": MessageLookupByLibrary.simpleMessage("连接中"),
    "mcpConnectionError": MessageLookupByLibrary.simpleMessage("连接错误"),
    "mcpConnectionFailed": m25,
    "mcpConnectionSettings": MessageLookupByLibrary.simpleMessage("连接配置"),
    "mcpDisconnected": MessageLookupByLibrary.simpleMessage("未连接"),
    "mcpEndpoint": MessageLookupByLibrary.simpleMessage("Streamable HTTP 端点"),
    "mcpEnvironment": MessageLookupByLibrary.simpleMessage("环境变量"),
    "mcpEnvironmentDescription": MessageLookupByLibrary.simpleMessage(
      "每行填写一个 KEY=VALUE。内容保存在操作系统安全凭据存储中；编辑时留空可保留现有值。",
    ),
    "mcpHiddenEnvironmentVariableCount": m26,
    "mcpHttpsRequired": MessageLookupByLibrary.simpleMessage(
      "远程 MCP 端点必须使用 HTTPS。",
    ),
    "mcpInvalidStdioEnvironment": MessageLookupByLibrary.simpleMessage(
      "环境变量必须按每行一个 KEY=VALUE 的格式填写。",
    ),
    "mcpLocalProcessSecurityDescription": MessageLookupByLibrary.simpleMessage(
      "stdio 服务器会在本机运行命令，请仅添加你信任的服务器和环境变量。",
    ),
    "mcpLocalProcessSecurityTitle": MessageLookupByLibrary.simpleMessage(
      "本地进程安全",
    ),
    "mcpNoApprovalRequired": MessageLookupByLibrary.simpleMessage("免确认"),
    "mcpNoAuthentication": MessageLookupByLibrary.simpleMessage("无"),
    "mcpPrivateEndpointBlocked": MessageLookupByLibrary.simpleMessage(
      "已阻止私网、本机和链路本地 MCP 端点。",
    ),
    "mcpProcessId": MessageLookupByLibrary.simpleMessage("进程 ID (PID)"),
    "mcpProcessNotRunning": MessageLookupByLibrary.simpleMessage("未运行"),
    "mcpProcessRunning": MessageLookupByLibrary.simpleMessage("运行中"),
    "mcpProcessStartedAt": MessageLookupByLibrary.simpleMessage("启动时间"),
    "mcpProcessStatus": MessageLookupByLibrary.simpleMessage("进程状态"),
    "mcpProgressiveDiscoveryDescription": MessageLookupByLibrary.simpleMessage(
      "Stars 会保存已发现的工具目录。请在编辑智能体时逐个开启工具，只有该智能体会将其提供给模型。",
    ),
    "mcpRequestTimedOut": MessageLookupByLibrary.simpleMessage("MCP 请求超时。"),
    "mcpSecureEnvironmentVariables": MessageLookupByLibrary.simpleMessage(
      "安全环境变量",
    ),
    "mcpServerDetails": MessageLookupByLibrary.simpleMessage("服务器详情"),
    "mcpServerInUseByBot": MessageLookupByLibrary.simpleMessage(
      "此 MCP 服务器正被智能体使用，请先从智能体中移除后再删除。",
    ),
    "mcpServerName": MessageLookupByLibrary.simpleMessage("服务器名称"),
    "mcpServers": MessageLookupByLibrary.simpleMessage("MCP 服务器"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "连接 MCP 服务器并发现工具目录；创建智能体后再按工具配置。",
    ),
    "mcpStdioPipeChannel": MessageLookupByLibrary.simpleMessage(
      "stdin / stdout / stderr（操作系统管道）",
    ),
    "mcpStdioProcessAndChannel": MessageLookupByLibrary.simpleMessage(
      "本地进程与通信",
    ),
    "mcpStdioStartFailed": MessageLookupByLibrary.simpleMessage(
      "无法启动 stdio MCP 命令。",
    ),
    "mcpTokenLeaveBlank": MessageLookupByLibrary.simpleMessage("留空可保留现有安全凭据。"),
    "mcpTokenStoredSecurely": MessageLookupByLibrary.simpleMessage(
      "令牌保存在操作系统的安全凭据存储中。",
    ),
    "mcpToolSchemaUnsupported": MessageLookupByLibrary.simpleMessage(
      "此工具的输入 Schema 不受支持，无法选择。",
    ),
    "mcpTools": MessageLookupByLibrary.simpleMessage("工具"),
    "mcpTransport": MessageLookupByLibrary.simpleMessage("传输方式"),
    "mcpTransportStdio": MessageLookupByLibrary.simpleMessage("stdio（本地进程）"),
    "mcpTransportStreamableHttp": MessageLookupByLibrary.simpleMessage(
      "Streamable HTTP",
    ),
    "mcpUnsupportedProtocol": MessageLookupByLibrary.simpleMessage(
      "MCP 服务器使用了不受支持的协议版本。",
    ),
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("重要引用"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage("记忆已发生变化，请重试"),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("纠正"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("决策"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("事实"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("偏好"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("未决问题"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("待办"),
    "messageCopied": MessageLookupByLibrary.simpleMessage("消息已复制到剪贴板"),
    "messageHint": MessageLookupByLibrary.simpleMessage("输入消息..."),
    "messageSkills": MessageLookupByLibrary.simpleMessage("技能"),
    "minutesAgo": m27,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("音频"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("文件"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("图片"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("多模态"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("音乐"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("实时"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("语音"),
    "modalityText": MessageLookupByLibrary.simpleMessage("文本"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("视频"),
    "model": MessageLookupByLibrary.simpleMessage("模型"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage("模型配置"),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage("模型上下文大小"),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("输入"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("输出"),
    "modelsRetrievedSuccess": m28,
    "modificationTime": MessageLookupByLibrary.simpleMessage("修改时间"),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("音乐已生成"),
    "musicResult": MessageLookupByLibrary.simpleMessage("音乐结果"),
    "name": MessageLookupByLibrary.simpleMessage("名称"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("名称已更新"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "新建智能体会留在工作区中继续编辑。",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("新建聊天"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "新建聊天后会直接在工作区打开会话。",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "暂无已连接且可用的 MCP 工具。",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage("尚未添加技能"),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "按需添加这个智能体要使用的已安装技能。",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage("没有可用的智能体"),
    "noChats": MessageLookupByLibrary.simpleMessage("还没有聊天记录"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage("未返回内容"),
    "noConversationFilesFound": MessageLookupByLibrary.simpleMessage(
      "未找到匹配的文件或文件夹。",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "当前还没有可用的会话摘要。",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage("没有找到匹配的智能体"),
    "noMatchingChats": MessageLookupByLibrary.simpleMessage("没有找到匹配的聊天"),
    "noMatchingMcpServers": MessageLookupByLibrary.simpleMessage(
      "未找到匹配的 MCP 服务器",
    ),
    "noMatchingMcpTools": MessageLookupByLibrary.simpleMessage("未找到匹配的工具"),
    "noMatchingSkills": MessageLookupByLibrary.simpleMessage("未找到匹配的技能"),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("尚无 MCP 服务器"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "添加 Streamable HTTP 或桌面端 stdio 服务器以发现其工具目录。",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "尚未发现工具，请检查连接后刷新。",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage("未获取到模型列表"),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage("尚未安装技能"),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "导入包含 SKILL.md 的智能体技能文件夹或 ZIP。",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "暂无 Token 用量记录",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("不支持"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage("没有足够的旧上下文可压缩"),
    "openFile": MessageLookupByLibrary.simpleMessage("打开文件"),
    "openLink": MessageLookupByLibrary.simpleMessage("打开链接"),
    "openWithSystem": MessageLookupByLibrary.simpleMessage("使用系统应用打开"),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "删除这条孤立会话，或重新创建缺失的智能体。",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("输出 Token"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("部分回复"),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("暂停播放"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("暂停生成"),
    "pinMemory": MessageLookupByLibrary.simpleMessage("固定"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage("在当前会话中固定已选技能"),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("已固定"),
    "playAudio": MessageLookupByLibrary.simpleMessage("播放音频"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage("请先输入API密钥"),
    "pleaseEnterImageDescription": MessageLookupByLibrary.simpleMessage(
      "请输入生成图片的描述",
    ),
    "pleaseEnterMusicDescription": MessageLookupByLibrary.simpleMessage(
      "请输入音乐描述",
    ),
    "pleaseEnterSpeechDescription": MessageLookupByLibrary.simpleMessage(
      "请输入语音描述",
    ),
    "pleaseEnterVideoDescription": MessageLookupByLibrary.simpleMessage(
      "请输入视频描述",
    ),
    "preview": MessageLookupByLibrary.simpleMessage("预览"),
    "previewText": MessageLookupByLibrary.simpleMessage("预览文字效果"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("隐私政策"),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage("过程信息"),
    "processToolCount": m32,
    "profile": MessageLookupByLibrary.simpleMessage("我的"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage("提供您的意见和建议"),
    "provider": MessageLookupByLibrary.simpleMessage("供应商"),
    "providerInformation": MessageLookupByLibrary.simpleMessage("提供商信息"),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage("思考完成"),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage("思考中"),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage("思考中断"),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("重新构建"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("参考音频"),
    "refresh": MessageLookupByLibrary.simpleMessage("刷新"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("刷新工具"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage("刷新目录"),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage("正在刷新目录…"),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("仅支持远程 MCP"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("移除文件"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage("移除图片"),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage("移除 MCP 服务器"),
    "removeSkill": MessageLookupByLibrary.simpleMessage("移除技能"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("已取消回复"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage("已停止 · 保留部分回复"),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("恢复默认"),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("恢复"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage("保留的最近轮次"),
    "retry": MessageLookupByLibrary.simpleMessage("重试"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage("运行测试"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("保存并连接"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("保存修改"),
    "saveImage": MessageLookupByLibrary.simpleMessage("保存图片"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage("保存到相册失败"),
    "savingChanges": MessageLookupByLibrary.simpleMessage("保存中..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("搜索智能体"),
    "searchChats": MessageLookupByLibrary.simpleMessage("搜索会话"),
    "searchConversationFiles": MessageLookupByLibrary.simpleMessage("搜索文件和文件夹"),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage("搜索 MCP 服务器"),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("搜索工具"),
    "searchMemory": MessageLookupByLibrary.simpleMessage("搜索记忆"),
    "searchSkills": MessageLookupByLibrary.simpleMessage("搜索技能"),
    "selectBot": MessageLookupByLibrary.simpleMessage("选择智能体"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("选择语言"),
    "selectModel": MessageLookupByLibrary.simpleMessage("选择模型:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("选择提供商"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("选择主题"),
    "send": MessageLookupByLibrary.simpleMessage("发送"),
    "settings": MessageLookupByLibrary.simpleMessage("设置"),
    "shareImage": MessageLookupByLibrary.simpleMessage("分享图片"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "来自 Stars 的图片",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("显示 API 密钥"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "在会话内容中显示执行状态。",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("显示智能体信息"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("显示侧栏"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage("包含静态资源"),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage("兼容性"),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "这个示例应当激活技能",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage("示例用户请求"),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage("激活结果"),
    "skillDetails": MessageLookupByLibrary.simpleMessage("技能详情"),
    "skillDigest": MessageLookupByLibrary.simpleMessage("内容摘要"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("已关闭"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("已开启"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("文件"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage("技能已导入"),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("技能"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "安装可复用指令，并将其绑定到智能体。",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "当前版本不会执行技能中的脚本或命令。",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("发布者"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage("包含参考资料"),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md 仅作为受控提示词加载；脚本、命令和外部工具保持禁用。",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage("桌面脚本沙箱可用"),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "每个技能的脚本默认关闭，需明确授权后启用；每次调用仍需审批，并在无网络、无主目录和不继承环境变量的隔离环境中运行。",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage("技能脚本不可用"),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "当前平台不具备所需的隔离 helper。技能指令和资源仍可使用，但脚本不会运行。",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "技能脚本设置已更新。",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "技能脚本已安装，但当前版本禁止执行。",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage("脚本已启用"),
    "skillSignature": MessageLookupByLibrary.simpleMessage("签名"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage("签名无效"),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "未知发布者",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage("未签名"),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage("签名已验证"),
    "skillSource": MessageLookupByLibrary.simpleMessage("来源"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage("安装位置"),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "安装位置已复制到剪贴板",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("自动"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage("有可用更新"),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("手动"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("通知"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("固定版本"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage("更新策略"),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("用户"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage("校验说明"),
    "skillVersion": MessageLookupByLibrary.simpleMessage("版本"),
    "sourceCode": MessageLookupByLibrary.simpleMessage("源代码"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("语音已生成"),
    "speechResult": MessageLookupByLibrary.simpleMessage("语音结果"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage("在下方输入框发送消息开始聊天"),
    "startChatting": MessageLookupByLibrary.simpleMessage("开始聊天吧"),
    "startupFailed": MessageLookupByLibrary.simpleMessage("启动失败，请重试。"),
    "startupStarting": MessageLookupByLibrary.simpleMessage("正在启动…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("已激活"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("已附加"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage("等待确认"),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("已取消"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("已完成"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("已拒绝"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage("重复调用"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("失败"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("已生成"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("进行中"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("已记录"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("已请求"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("执行中"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("已跳过"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("已超时"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("未知"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "stopAndContinue": MessageLookupByLibrary.simpleMessage("停止并继续"),
    "stopGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "离开前停止生成？",
    ),
    "stopGenerationBeforeLeavingDescription":
        MessageLookupByLibrary.simpleMessage("已生成的部分回复会被保留。"),
    "stopping": MessageLookupByLibrary.simpleMessage("正在停止…"),
    "structuredProcessInfo": MessageLookupByLibrary.simpleMessage("结构化过程信息"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("提交反馈"),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage("已摘要消息数"),
    "supported": MessageLookupByLibrary.simpleMessage("支持"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("支持 MCP"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage("支持技能"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("系统提示词:"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("拍照"),
    "testSkill": MessageLookupByLibrary.simpleMessage("测试"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage("测试技能描述"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage("已设置为深色模式"),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage("已设置为浅色模式"),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage("已设置为跟随系统主题"),
    "themeSettings": MessageLookupByLibrary.simpleMessage("主题设置"),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage("思考完成"),
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("正在思考…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("Token 用量"),
    "tokens": MessageLookupByLibrary.simpleMessage("Token"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage("已允许一次"),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("已拒绝"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("工具调用"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("破坏性"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("只读"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("写入"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("内置"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage("技能脚本"),
    "totalTokens": MessageLookupByLibrary.simpleMessage("Token 总量"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "试试其他关键词，或直接新建。",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("正在输入..."),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage("无法加载智能体"),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage("无法加载聊天列表"),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage("无法加载消息"),
    "unavailableBot": MessageLookupByLibrary.simpleMessage("智能体不可用"),
    "uninstall": MessageLookupByLibrary.simpleMessage("卸载"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage("卸载技能"),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("解除固定"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "不支持此图片格式。请选择 JPEG、PNG、GIF、BMP 或 WebP 图片。",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("文件"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("图片"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("用户协议"),
    "version": MessageLookupByLibrary.simpleMessage("版本 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("视频已生成"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage("无法加载视频"),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("视频结果"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("查看摘要"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "请等待生成完成后再离开当前会话。",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "请等待生成完成。",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("联网搜索"),
  };
}
