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

  static String m1(botName) => "\"${botName}\" 已被刪除";

  static String m2(botName) => "你好！我是 ${botName}，一個AI助手。你可以問我任何問題，我會盡力幫助你。";

  static String m3(botName) => "${botName} 正在輸入...";

  static String m4(botName) => "智能體 ${botName} 已更新";

  static String m5(botName) => "已刪除與 ${botName} 的聊天";

  static String m6(error) => "Could not clear chat history: ${error}";

  static String m7(botName) => "確定要清空與 \"${botName}\" 的所有聊天記錄嗎？此操作無法撤銷。";

  static String m8(botName) => "刪除機器人會刪除對應的聊天記錄，確定要刪除 ${botName} 嗎？";

  static String m9(botName) => "刪除聊天會清空所有的聊天記錄，確定要刪除與 ${botName} 的聊天嗎？";

  static String m10(name) => "確定刪除「${name}」？快取的工具目錄與安全憑證也會移除。";

  static String m11(name) => "確定解除安裝技能「${name}」？相關智慧體綁定也會被移除。";

  static String m12(year) => "© ${year} Stars 團隊";

  static String m13(error) => "Could not create the chat: ${error}";

  static String m14(error) => "Could not delete the chat: ${error}";

  static String m15(milliseconds) => "${milliseconds} 毫秒";

  static String m16(seconds) => "${seconds} 秒";

  static String m17(name) => "允許「${name}」將已宣告的指令碼註冊為工具。每次呼叫仍須核准，並在桌面沙箱中執行。";

  static String m18(count) => "${count} files";

  static String m19(error) => "Generate image failed: ${error}";

  static String m20(error) => "Could not generate music: ${error}";

  static String m21(error) => "Could not generate speech: ${error}";

  static String m22(error) => "Could not generate video: ${error}";

  static String m23(count) => "${count} items";

  static String m24(language) => "語言已設置為${language}";

  static String m25(error) => "MCP 連線失敗：${error}";

  static String m26(count) => "${count} configured (values hidden)";

  static String m27(minutes) => "${minutes}分鐘前";

  static String m28(count) => "成功獲取 ${count} 個模型";

  static String m29(count) => "${count} 次命令執行";

  static String m30(duration) => "耗時 ${duration}";

  static String m31(count) => "${count} 筆檔案狀態";

  static String m32(count) => "${count} 次工具呼叫";

  static String m33(error) => "獲取回覆失敗: ${error}";

  static String m34(error) => "Could not save image: ${error}";

  static String m35(error) => "Could not share image: ${error}";

  static String m36(error) => "技能匯入失敗：${error}";

  static String m37(duration) => "思考完成 · ${duration}";

  static String m38(error) => "影片播放錯誤：${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("智能體"),
    "about": MessageLookupByLibrary.simpleMessage("關於"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("關於 Stars"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("添加機器人"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("新增 MCP 伺服器"),
    "addSkill": MessageLookupByLibrary.simpleMessage("加入技能"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage("調整應用內文字大小"),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("調整文字大小"),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage("所有已安裝技能均已加入。"),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("始終啟用"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "每次文字請求都會注入此技能。",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("始終啟用"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API地址:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API密鑰"),
    "apiType": MessageLookupByLibrary.simpleMessage("API類型:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "一個簡單而強大的AI聊天應用，讓您隨時隨地與AI進行對話。",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Stars - AI 聊天助手"),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage("系統提示詞"),
    "applicationInjectedPromptDescription":
        MessageLookupByLibrary.simpleMessage(
          "由 Stars 管理並注入至每次模型請求。目前智慧代理與對話識別碼會在執行階段補充，無法編輯。",
        ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("自動啟用"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "讓支援的模型依技能描述按需啟用。",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "目前模型服務僅支援手動使用技能。",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage("自動記憶"),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "自動摘要可能不準確，目前訊息始終優先。",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage(
      "Back to daily usage",
    ),
    "basicInformation": MessageLookupByLibrary.simpleMessage(
      "Basic Information",
    ),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("機器人頭像"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "按工具啟用目前智慧代理可使用的 MCP 能力；預設每次呼叫都需要確認。",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("機器人名稱"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search filters the list by bot name.",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("技能"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "選擇這個智慧體可以使用的可重複指令。",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("更換頭像"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("已儲存"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage("對話執行狀態"),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage("聊天記錄已清空"),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("聊天"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("清空"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage("清除自動記憶"),
    "clearChat": MessageLookupByLibrary.simpleMessage("清空聊天"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage("清空聊天記錄"),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage("清除會話固定技能"),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "Select a day to view hourly usage",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage("點擊右上角 + 添加智能體"),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage("點擊新建聊天建立會話"),
    "commandExecutions": MessageLookupByLibrary.simpleMessage("命令執行"),
    "compactNow": MessageLookupByLibrary.simpleMessage("立即壓縮"),
    "compactingContext": MessageLookupByLibrary.simpleMessage("正在整理上下文…"),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("失敗"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage("壓縮狀態"),
    "confirm": MessageLookupByLibrary.simpleMessage("確定"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("確認刪除"),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage("聯絡方式（可選）"),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage("上下文與記憶"),
    "contextCompacted": MessageLookupByLibrary.simpleMessage("上下文已壓縮"),
    "contextWindow": MessageLookupByLibrary.simpleMessage("上下文視窗"),
    "conversationSummary": MessageLookupByLibrary.simpleMessage("會話摘要"),
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
    "customProvider": MessageLookupByLibrary.simpleMessage("自定義供應商..."),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage("Daily usage"),
    "darkMode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "資料庫由較新版本的 Stars 建立，請升級應用程式後再開啟。",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "資料庫完整性檢查失敗，且無法從目前版本的備份還原。",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage("深度思考"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "你是一個有用的AI助手，請用繁體中文回答問題。",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("刪除"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("刪除智能體"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("刪除聊天"),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage("刪除 MCP 伺服器"),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage("關於與法律資訊"),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "外觀與語言",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "修改頭像與顯示名稱。",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("一般"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage("幫助與支援"),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage("個人資訊"),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "修改會立即生效並儲存於本機。",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "管理個人資訊、外觀、語言與應用程式支援。",
    ),
    "details": MessageLookupByLibrary.simpleMessage("詳情"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "全部關閉免確認",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage("全部關閉工具"),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage("停用指令碼"),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("編輯"),
    "editBot": MessageLookupByLibrary.simpleMessage("編輯機器人"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("編輯 MCP 伺服器"),
    "editMemory": MessageLookupByLibrary.simpleMessage("編輯記憶"),
    "editName": MessageLookupByLibrary.simpleMessage("修改名稱"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "獲取回覆失敗: 伺服器返回空響應",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "全部開啟免確認",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage("全部開啟工具"),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage("啟用指令碼"),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "啟用隔離的技能指令碼？",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage("輸入API地址..."),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("輸入API密鑰..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("請輸入名稱..."),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage("請輸入顯示名稱"),
    "enterNewName": MessageLookupByLibrary.simpleMessage("請輸入新名稱"),
    "enterProviderName": MessageLookupByLibrary.simpleMessage("輸入供應商名稱..."),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage("輸入系統提示詞..."),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "載入內容時出錯，請稍後再試。",
    ),
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage("預計本輪占用"),
    "executionStatus": MessageLookupByLibrary.simpleMessage("執行狀態"),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage("請輸入反饋內容"),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "請告訴我們您的想法、問題或建議，幫助我們改進應用",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage("請在此輸入您的反饋內容..."),
    "feedbackInformation": MessageLookupByLibrary.simpleMessage("反饋資訊"),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage("提交失敗，請稍後重試"),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage("感謝您的反饋！"),
    "fetchModelList": MessageLookupByLibrary.simpleMessage("獲取模型列表"),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage("請先獲取模型列表"),
    "fileAttachment": MessageLookupByLibrary.simpleMessage("File attachment"),
    "fileCount": m18,
    "fileResult": MessageLookupByLibrary.simpleMessage("File result"),
    "fileStatus": MessageLookupByLibrary.simpleMessage("檔案狀態"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("音樂"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("語音"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("影片"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "請填寫智能體名稱、API地址和API密鑰",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("文字大小"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage("文字大小已更新"),
    "forgetMemory": MessageLookupByLibrary.simpleMessage("遺忘"),
    "generateImageFailed": m19,
    "generateMusicFailed": m20,
    "generateSpeechFailed": m21,
    "generateVideoFailed": m22,
    "generatedImage": MessageLookupByLibrary.simpleMessage("Image generated"),
    "generating": MessageLookupByLibrary.simpleMessage("Generating…"),
    "generatingImage": MessageLookupByLibrary.simpleMessage(
      "Generating image, please wait...",
    ),
    "generationFailed": MessageLookupByLibrary.simpleMessage("生成失敗"),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "生成失敗 · 保留部分回覆",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("幫助與反饋"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("Hide API Key"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("首頁"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage("Hourly usage"),
    "idle": MessageLookupByLibrary.simpleMessage("閒置"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage("匯入技能資料夾"),
    "importSkillZip": MessageLookupByLibrary.simpleMessage("匯入技能 ZIP"),
    "importingSkill": MessageLookupByLibrary.simpleMessage("正在匯入技能…"),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("輸入 Token"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage("安裝更新"),
    "invalidSummary": MessageLookupByLibrary.simpleMessage("生成的摘要未通過驗證"),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("剛剛"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage("語言設定"),
    "lightMode": MessageLookupByLibrary.simpleMessage("淺色模式"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "本機程序型 MCP 伺服器仍停用，完成各平台安全審查後才會開放。",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("管理記憶"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("按訊息啟用"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "需要時從訊息輸入框選擇技能。",
    ),
    "mcpAccessToken": MessageLookupByLibrary.simpleMessage(
      "OAuth / Bearer 存取權杖",
    ),
    "mcpArguments": MessageLookupByLibrary.simpleMessage("參數"),
    "mcpArgumentsDescription": MessageLookupByLibrary.simpleMessage(
      "每行填寫一個參數。",
    ),
    "mcpAuthentication": MessageLookupByLibrary.simpleMessage("驗證"),
    "mcpAuthorizationRequired": MessageLookupByLibrary.simpleMessage("需要授權"),
    "mcpCommand": MessageLookupByLibrary.simpleMessage("命令"),
    "mcpCommandDescription": MessageLookupByLibrary.simpleMessage(
      "填寫可執行檔名稱或絕對路徑；命令會直接執行，不經過 Shell。",
    ),
    "mcpCommunicationChannel": MessageLookupByLibrary.simpleMessage(
      "Communication channel",
    ),
    "mcpConnected": MessageLookupByLibrary.simpleMessage("已連線"),
    "mcpConnecting": MessageLookupByLibrary.simpleMessage("連線中"),
    "mcpConnectionError": MessageLookupByLibrary.simpleMessage("連線錯誤"),
    "mcpConnectionFailed": m25,
    "mcpConnectionSettings": MessageLookupByLibrary.simpleMessage("連線設定"),
    "mcpDisconnected": MessageLookupByLibrary.simpleMessage("未連線"),
    "mcpEndpoint": MessageLookupByLibrary.simpleMessage("Streamable HTTP 端點"),
    "mcpEnvironment": MessageLookupByLibrary.simpleMessage("環境變數"),
    "mcpEnvironmentDescription": MessageLookupByLibrary.simpleMessage(
      "每行填寫一個 KEY=VALUE。內容會儲存在作業系統安全憑證儲存區；編輯時留空可保留現有值。",
    ),
    "mcpHiddenEnvironmentVariableCount": m26,
    "mcpHttpsRequired": MessageLookupByLibrary.simpleMessage(
      "遠端 MCP 端點必須使用 HTTPS。",
    ),
    "mcpInvalidStdioEnvironment": MessageLookupByLibrary.simpleMessage(
      "環境變數必須以每行一個 KEY=VALUE 的格式填寫。",
    ),
    "mcpLocalProcessSecurityDescription": MessageLookupByLibrary.simpleMessage(
      "stdio 伺服器會在本機執行命令，請只加入你信任的伺服器和環境變數。",
    ),
    "mcpLocalProcessSecurityTitle": MessageLookupByLibrary.simpleMessage(
      "本機程序安全",
    ),
    "mcpNoApprovalRequired": MessageLookupByLibrary.simpleMessage("免確認"),
    "mcpNoAuthentication": MessageLookupByLibrary.simpleMessage("無"),
    "mcpPrivateEndpointBlocked": MessageLookupByLibrary.simpleMessage(
      "已封鎖私有、本機及鏈路本地 MCP 端點。",
    ),
    "mcpProcessId": MessageLookupByLibrary.simpleMessage("Process ID (PID)"),
    "mcpProcessNotRunning": MessageLookupByLibrary.simpleMessage("Not running"),
    "mcpProcessRunning": MessageLookupByLibrary.simpleMessage("Running"),
    "mcpProcessStartedAt": MessageLookupByLibrary.simpleMessage("Started at"),
    "mcpProcessStatus": MessageLookupByLibrary.simpleMessage("Process status"),
    "mcpProgressiveDiscoveryDescription": MessageLookupByLibrary.simpleMessage(
      "Stars 會儲存已探索的工具目錄。請在編輯智慧代理時逐一啟用工具，只有該智慧代理會將其提供給模型。",
    ),
    "mcpRequestTimedOut": MessageLookupByLibrary.simpleMessage("MCP 請求逾時。"),
    "mcpSecureEnvironmentVariables": MessageLookupByLibrary.simpleMessage(
      "Secure environment variables",
    ),
    "mcpServerDetails": MessageLookupByLibrary.simpleMessage("伺服器詳情"),
    "mcpServerName": MessageLookupByLibrary.simpleMessage("伺服器名稱"),
    "mcpServers": MessageLookupByLibrary.simpleMessage("MCP 伺服器"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "連接 MCP 伺服器並探索工具目錄；建立智慧代理後再按工具設定。",
    ),
    "mcpStdioPipeChannel": MessageLookupByLibrary.simpleMessage(
      "stdin / stdout / stderr (operating system pipes)",
    ),
    "mcpStdioProcessAndChannel": MessageLookupByLibrary.simpleMessage(
      "Local process and communication",
    ),
    "mcpStdioStartFailed": MessageLookupByLibrary.simpleMessage(
      "無法啟動 stdio MCP 命令。",
    ),
    "mcpTokenLeaveBlank": MessageLookupByLibrary.simpleMessage("留空可保留現有安全憑證。"),
    "mcpTokenStoredSecurely": MessageLookupByLibrary.simpleMessage(
      "權杖會儲存在作業系統的安全憑證儲存區。",
    ),
    "mcpToolSchemaUnsupported": MessageLookupByLibrary.simpleMessage(
      "此工具的輸入 Schema 不受支援，無法選取。",
    ),
    "mcpTools": MessageLookupByLibrary.simpleMessage("工具"),
    "mcpTransport": MessageLookupByLibrary.simpleMessage("傳輸方式"),
    "mcpTransportStdio": MessageLookupByLibrary.simpleMessage("stdio（本機程序）"),
    "mcpTransportStreamableHttp": MessageLookupByLibrary.simpleMessage(
      "Streamable HTTP",
    ),
    "mcpUnsupportedProtocol": MessageLookupByLibrary.simpleMessage(
      "MCP 伺服器使用不支援的協定版本。",
    ),
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("重要引用"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage("記憶已發生變化，請重試"),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("修正"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("決策"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("事實"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("偏好"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("未決問題"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("待辦"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage("輸入消息..."),
    "messageSkills": MessageLookupByLibrary.simpleMessage("技能"),
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
    "model": MessageLookupByLibrary.simpleMessage("模型"),
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
    "name": MessageLookupByLibrary.simpleMessage("名稱"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("名稱已更新"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("新建聊天"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "目前沒有已連線且可用的 MCP 工具。",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage("尚未加入技能"),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "依需求加入這個智慧體要使用的已安裝技能。",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage("沒有可用的智能體"),
    "noChats": MessageLookupByLibrary.simpleMessage("還沒有聊天記錄"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage("未傳回內容"),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "目前還沒有可用的會話摘要。",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage(
      "No matching bots found",
    ),
    "noMatchingChats": MessageLookupByLibrary.simpleMessage(
      "No matching chats found",
    ),
    "noMatchingMcpServers": MessageLookupByLibrary.simpleMessage(
      "找不到符合的 MCP 伺服器",
    ),
    "noMatchingMcpTools": MessageLookupByLibrary.simpleMessage(
      "No matching tools found",
    ),
    "noMatchingSkills": MessageLookupByLibrary.simpleMessage("找不到符合的技能"),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("尚無 MCP 伺服器"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "新增 Streamable HTTP 或桌面端 stdio 伺服器以探索其工具目錄。",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "尚未發現工具，請檢查連線後重新整理。",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage("未獲取到任何模型"),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage("尚未安裝技能"),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "匯入包含 SKILL.md 的智慧體技能資料夾或 ZIP。",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "No token usage recorded",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("Not supported"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage("沒有足夠的舊上下文可壓縮"),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("輸出 Token"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("部分回覆"),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("暫停播放"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("暫停生成"),
    "pinMemory": MessageLookupByLibrary.simpleMessage("固定"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage("在目前會話固定已選技能"),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("已固定"),
    "playAudio": MessageLookupByLibrary.simpleMessage("播放音訊"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage("請先輸入API密鑰"),
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
    "previewText": MessageLookupByLibrary.simpleMessage("預覽文字效果"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("隱私政策"),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage("過程資訊"),
    "processToolCount": m32,
    "profile": MessageLookupByLibrary.simpleMessage("我的"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage("提供您的意見和建議"),
    "provider": MessageLookupByLibrary.simpleMessage("供應商"),
    "providerInformation": MessageLookupByLibrary.simpleMessage(
      "Provider Information",
    ),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage("思考完成"),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage("思考中"),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage("思考中斷"),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("重新建構"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("重新整理"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("重新整理工具"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage("重新整理目錄"),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "正在重新整理目錄…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("僅支援遠端 MCP"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("移除技能"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("回覆已取消"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage("已停止 · 保留部分回覆"),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("恢復預設值"),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("恢復"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage("保留的最近輪次"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage("執行測試"),
    "save": MessageLookupByLibrary.simpleMessage("儲存"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("儲存並連線"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("儲存修改"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("儲存中..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("Search bots"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage("搜尋 MCP 伺服器"),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage("搜尋記憶"),
    "searchSkills": MessageLookupByLibrary.simpleMessage("搜尋技能"),
    "selectBot": MessageLookupByLibrary.simpleMessage("選擇智能體"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("選擇語言"),
    "selectModel": MessageLookupByLibrary.simpleMessage("選擇模型:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("選擇提供商:"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("選擇主題"),
    "send": MessageLookupByLibrary.simpleMessage("發送"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("Show API Key"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "在對話內容中顯示執行狀態。",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage("包含靜態資源"),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage("相容性"),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "這個範例應啟用技能",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "範例使用者請求",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage("啟用結果"),
    "skillDetails": MessageLookupByLibrary.simpleMessage("技能詳情"),
    "skillDigest": MessageLookupByLibrary.simpleMessage("內容摘要"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("已關閉"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("已開啟"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("檔案"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage("技能已匯入"),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("技能"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "安裝可重複使用的指令，並將其綁定至智慧體。",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "目前版本不會執行技能中的腳本或命令。",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("發佈者"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage("包含參考資料"),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md 僅作為受控提示詞載入；腳本、命令與外部工具維持停用。",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage("桌面指令碼沙箱可用"),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "每個技能的指令碼預設停用，須明確授權後啟用；每次呼叫仍須核准，並在無網路、無主目錄且不繼承環境變數的隔離環境中執行。",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage("技能指令碼不可用"),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "目前平台不具備所需的隔離 helper。技能指令與資源仍可使用，但指令碼不會執行。",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "技能指令碼設定已更新。",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "技能腳本已安裝，但目前版本禁止執行。",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage("指令碼已啟用"),
    "skillSignature": MessageLookupByLibrary.simpleMessage("簽章"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage("簽章無效"),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "未知發佈者",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage("未簽章"),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage("簽章已驗證"),
    "skillSource": MessageLookupByLibrary.simpleMessage("來源"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("自動"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage("有可用更新"),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("手動"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("通知"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("固定版本"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage("更新策略"),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("使用者"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage("驗證說明"),
    "skillVersion": MessageLookupByLibrary.simpleMessage("版本"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage("在下方輸入框中發送訊息開始聊天"),
    "startChatting": MessageLookupByLibrary.simpleMessage("開始聊天吧"),
    "startupFailed": MessageLookupByLibrary.simpleMessage("啟動失敗，請再試一次。"),
    "startupStarting": MessageLookupByLibrary.simpleMessage("正在啟動…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("已啟用"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("已附加"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage("等待確認"),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("已取消"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("已完成"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("已拒絕"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage("重複呼叫"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("失敗"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("已生成"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("進行中"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("已記錄"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("已請求"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("執行中"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("已略過"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("已逾時"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("未知"),
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
    "structuredProcessInfo": MessageLookupByLibrary.simpleMessage("結構化過程資訊"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("提交反饋"),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage("已摘要訊息數"),
    "supported": MessageLookupByLibrary.simpleMessage("Supported"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("Supports MCP"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage("Supports Skills"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("系統提示詞"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("測試"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage("測試技能描述"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage("已設置為深色模式"),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage("已設置為淺色模式"),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage("已設置為跟隨系統主題"),
    "themeSettings": MessageLookupByLibrary.simpleMessage("主題設定"),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage("思考完成"),
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("正在思考…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("Token usage"),
    "tokens": MessageLookupByLibrary.simpleMessage("tokens"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage("已允許一次"),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("已拒絕"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("工具呼叫"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("破壞性"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("唯讀"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("寫入"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("內建"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage("技能指令碼"),
    "totalTokens": MessageLookupByLibrary.simpleMessage("Total tokens"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "Try a different search, or create a new item.",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("正在輸入..."),
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
    "uninstall": MessageLookupByLibrary.simpleMessage("解除安裝"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage("解除安裝技能"),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("解除固定"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "不支援此圖片格式。請選擇 JPEG、PNG、GIF、BMP 或 WebP 圖片。",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("上傳檔案"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("上傳圖片"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("用戶協議"),
    "version": MessageLookupByLibrary.simpleMessage("版本 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage("無法載入影片"),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("查看摘要"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
