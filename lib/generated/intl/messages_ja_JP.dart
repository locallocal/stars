// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja_JP locale. All the
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
  String get localeName => 'ja_JP';

  static String m0(status, reason) => "${status}。${reason}";

  static String m1(name) => "ボット \"${name}\" が追加されました";

  static String m2(botName) => "\"${botName}\"が削除されました";

  static String m3(botName) =>
      "こんにちは！私は${botName}というAIアシスタントです。どんな質問でもお気軽にどうぞ、できる限りお手伝いします。";

  static String m4(botName) => "${botName}が入力中...";

  static String m5(botName) => "ボット${botName}が更新されました";

  static String m6(botName) => "${botName}とのチャットが削除されました";

  static String m7(error) => "Could not clear chat history: ${error}";

  static String m8(botName) =>
      "\"${botName}\"とのすべてのチャット履歴を消去してもよろしいですか？この操作は元に戻せません。";

  static String m9(botName) =>
      "ボットを削除すると、関連するすべてのチャットも削除されます。${botName}を本当に削除しますか？";

  static String m10(botName) =>
      "チャットを削除するとすべてのチャット履歴が消去されます。${botName}とのチャットを本当に削除しますか？";

  static String m11(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m12(name) => "${name} をアンインストールしますか？ボットとの関連付けも削除されます。";

  static String m13(year) => "© ${year} Starsチーム";

  static String m14(error) => "Could not create the chat: ${error}";

  static String m15(error) => "Could not delete the chat: ${error}";

  static String m16(milliseconds) => "${milliseconds} ミリ秒";

  static String m17(seconds) => "${seconds} 秒";

  static String m18(name) =>
      "${name} が宣言済みスクリプトをツールとして登録することを許可します。各呼び出しにも承認が必要です。";

  static String m19(count) => "${count} files";

  static String m20(error) => "Generate image failed: ${error}";

  static String m21(error) => "Could not generate music: ${error}";

  static String m22(error) => "Could not generate speech: ${error}";

  static String m23(error) => "Could not generate video: ${error}";

  static String m24(count) => "${count} items";

  static String m25(language) => "言語が${language}に設定されました";

  static String m26(error) => "MCP connection failed: ${error}";

  static String m27(count) => "${count} configured (values hidden)";

  static String m28(minutes) => "${minutes}分前";

  static String m29(count) => "${count}個のモデルが正常に取得されました";

  static String m30(count) => "コマンド実行 ${count} 件";

  static String m31(duration) => "所要時間 ${duration}";

  static String m32(count) => "ファイル更新 ${count} 件";

  static String m33(count) => "ツール呼び出し ${count} 件";

  static String m34(error) => "応答の取得に失敗しました：${error}";

  static String m35(error) => "Could not save image: ${error}";

  static String m36(error) => "Could not share image: ${error}";

  static String m37(error) => "スキルをインポートできませんでした：${error}";

  static String m38(duration) => "思考完了 · ${duration}";

  static String m39(error) => "動画の再生エラー: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("ボット"),
    "about": MessageLookupByLibrary.simpleMessage("アプリについて"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Starsについて"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("ボットを追加"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("スキルを追加"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "アプリのフォントサイズを調整する",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("フォントサイズを調整"),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "インストール済みのスキルはすべて追加されています。",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("常に有効"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "各テキストリクエストにこのスキルを挿入します。",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("常に有効"),
    "answerTrustClaimHidden": MessageLookupByLibrary.simpleMessage(
      "厳格モードにより未検証の事実主張を非表示にしました。",
    ),
    "answerTrustDetails": MessageLookupByLibrary.simpleMessage("証拠の詳細を表示"),
    "answerTrustEvidence": MessageLookupByLibrary.simpleMessage("証拠"),
    "answerTrustEvidenceUnavailable": MessageLookupByLibrary.simpleMessage(
      "証拠の詳細を利用できません。",
    ),
    "answerTrustExportReason": MessageLookupByLibrary.simpleMessage("信頼理由"),
    "answerTrustExportStatus": MessageLookupByLibrary.simpleMessage("信頼状態"),
    "answerTrustFailed": MessageLookupByLibrary.simpleMessage("失敗"),
    "answerTrustFailureReason": MessageLookupByLibrary.simpleMessage("失敗理由"),
    "answerTrustNotFactChecked": MessageLookupByLibrary.simpleMessage(
      "ファクトチェック未実施",
    ),
    "answerTrustObservedAt": MessageLookupByLibrary.simpleMessage("観測日時"),
    "answerTrustPartiallyVerified": MessageLookupByLibrary.simpleMessage(
      "一部検証済み",
    ),
    "answerTrustReasonEvidenceExpired": MessageLookupByLibrary.simpleMessage(
      "裏付けとなる観測は期限切れです。",
    ),
    "answerTrustReasonGateFailed": MessageLookupByLibrary.simpleMessage(
      "この回答はアプリの信頼性ゲートを通過しませんでした。",
    ),
    "answerTrustReasonNoTool": MessageLookupByLibrary.simpleMessage(
      "この回答に利用可能なツール証拠がありません。",
    ),
    "answerTrustReasonNotFactChecked": MessageLookupByLibrary.simpleMessage(
      "この内容は創作、または検証済みの事実として提示されていません。",
    ),
    "answerTrustReasonPartiallyVerified": MessageLookupByLibrary.simpleMessage(
      "一部の事実主張のみ保存済みの証拠で裏付けられています。",
    ),
    "answerTrustReasonProviderFailed": MessageLookupByLibrary.simpleMessage(
      "この回答を検証する前にプロバイダーへのリクエストが失敗しました。",
    ),
    "answerTrustReasonProviderUnsupported":
        MessageLookupByLibrary.simpleMessage("このプロバイダーは検証ツールをサポートしていません。"),
    "answerTrustReasonToolRejected": MessageLookupByLibrary.simpleMessage(
      "検証ツールのリクエストが拒否されました。",
    ),
    "answerTrustReasonUnavailable": MessageLookupByLibrary.simpleMessage(
      "この回答の検証は完了していません。",
    ),
    "answerTrustReasonVerified": MessageLookupByLibrary.simpleMessage(
      "すべての事実主張は保存済みの証拠で裏付けられています。",
    ),
    "answerTrustSemanticLabel": m0,
    "answerTrustSource": MessageLookupByLibrary.simpleMessage("出典"),
    "answerTrustTool": MessageLookupByLibrary.simpleMessage("ツール"),
    "answerTrustUnverified": MessageLookupByLibrary.simpleMessage("未検証"),
    "answerTrustVerified": MessageLookupByLibrary.simpleMessage("検証済み"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("APIアドレス:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("APIキー"),
    "apiType": MessageLookupByLibrary.simpleMessage("APIタイプ:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "いつでもどこでもAIとチャットできるシンプルで強力なAIチャットアプリケーション。",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Stars - AIチャットアシスタント"),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "システムプロンプト",
    ),
    "applicationInjectedPromptDescription": MessageLookupByLibrary.simpleMessage(
      "Stars が管理します。有効にすると以下の内容を会話のモデルリクエストに注入し、無効にすると注入しません。必要な実行時の会話コンテキストには影響しません。内容は編集できません。",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("自動"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "対応モデルが説明に基づいてこのスキルを有効化します。",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "このプロバイダーは手動スキルのみ対応しています。",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage("自動メモリ"),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "自動要約は不正確な場合があります。現在のメッセージが常に優先されます。",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage("日別使用量に戻る"),
    "basicInformation": MessageLookupByLibrary.simpleMessage("基本情報"),
    "botAddedSuccess": m1,
    "botAvatar": MessageLookupByLibrary.simpleMessage("ボットのアバター"),
    "botDeleted": m2,
    "botGreeting": m3,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m4,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "このエージェントで MCP ツールを有効にします。ツール呼び出しには既定で確認が必要です。",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("ボット名"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage("ボット名でリストを絞り込みます。"),
    "botSkills": MessageLookupByLibrary.simpleMessage("スキル"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "このボットで使用できる再利用可能な指示を選択します。",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m5,
    "browseConversationDirectory": MessageLookupByLibrary.simpleMessage(
      "Browse conversation data",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("アバターを変更"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("保存済み"),
    "chatDeleted": m6,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage("チャットの実行状況"),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage(
      "チャット履歴が消去されました",
    ),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("チャット"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("クリア"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage("自動メモリを消去"),
    "clearChat": MessageLookupByLibrary.simpleMessage("チャットをクリア"),
    "clearChatFailed": m7,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage("チャット履歴をクリア"),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage("会話の固定を解除"),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "時間別使用量を表示する日を選択",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "右上の+をクリックしてボットを追加",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "新しいチャットをクリックして会話を作成",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage("コマンド実行"),
    "compactNow": MessageLookupByLibrary.simpleMessage("今すぐ圧縮"),
    "compactingContext": MessageLookupByLibrary.simpleMessage("コンテキストを整理中…"),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("失敗"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage("圧縮状態"),
    "confirm": MessageLookupByLibrary.simpleMessage("確認"),
    "confirmClearChat": m8,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("削除の確認"),
    "confirmDeleteBot": m9,
    "confirmDeleteChat": m10,
    "confirmDeleteMcpServer": m11,
    "confirmUninstallSkill": m12,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage("連絡先情報（任意）"),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage("コンテキストとメモリ"),
    "contextCompacted": MessageLookupByLibrary.simpleMessage("コンテキストを圧縮しました"),
    "contextWindow": MessageLookupByLibrary.simpleMessage("コンテキストウィンドウ"),
    "conversationDirectory": MessageLookupByLibrary.simpleMessage(
      "Conversation data directory",
    ),
    "conversationDirectoryDescription": MessageLookupByLibrary.simpleMessage(
      "Browse files and folders stored for this conversation.",
    ),
    "conversationDirectoryEmpty": MessageLookupByLibrary.simpleMessage(
      "This conversation directory is empty.",
    ),
    "conversationSummary": MessageLookupByLibrary.simpleMessage("会話の要約"),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage("会話別トークン比率"),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("API キーをコピー"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m13,
    "createChatFailed": m14,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("作成日時"),
    "customProvider": MessageLookupByLibrary.simpleMessage("カスタムプロバイダー..."),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage("日別使用量"),
    "darkMode": MessageLookupByLibrary.simpleMessage("ダークモード"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "このデータベースは新しいバージョンの Stars で作成されています。アプリを更新してから開いてください。",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "データベースの整合性チェックに失敗し、このバージョンのバックアップからも復元できませんでした。",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage("深い思考"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "あなたは役立つAIアシスタントです。日本語で回答してください。",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("削除"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("ボットを削除"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("チャットを削除"),
    "deleteChatFailed": m15,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "このアプリについて・法的情報",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "外観と言語",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "アバターと表示名を変更します。",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("一般"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage("ヘルプとサポート"),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage("個人情報"),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "変更はすぐに反映され、ローカルに保存されます。",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "プロフィール、外観、言語、アプリのサポートを管理します。",
    ),
    "details": MessageLookupByLibrary.simpleMessage("詳細"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "すべての確認不要を解除",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage("すべてのツールを無効化"),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage("スクリプトを無効化"),
    "durationMilliseconds": m16,
    "durationSeconds": m17,
    "edit": MessageLookupByLibrary.simpleMessage("編集"),
    "editBot": MessageLookupByLibrary.simpleMessage("ボットを編集"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("メモリを編集"),
    "editName": MessageLookupByLibrary.simpleMessage("名前を編集"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "応答の取得に失敗しました：サーバーが空の応答を返しました",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "すべて確認不要にする",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage("すべてのツールを有効化"),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage("スクリプトを有効化"),
    "enableSkillScriptsDescription": m18,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "隔離されたスキルスクリプトを有効にしますか？",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage("APIアドレスを入力..."),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("APIキーを入力..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("ボット名を入力..."),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage("表示名を入力してください"),
    "enterNewName": MessageLookupByLibrary.simpleMessage("新しい名前を入力してください"),
    "enterProviderName": MessageLookupByLibrary.simpleMessage("プロバイダー名を入力..."),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "システムプロンプトを入力...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "コンテンツの読み込み中にエラーが発生しました。後でもう一度お試しください。",
    ),
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage("推定使用量"),
    "executionStatus": MessageLookupByLibrary.simpleMessage("実行状態"),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "フィードバック内容を入力してください",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "アプリの改善に役立てるたければ、あなたの考え、問題点、または提案を教えてください",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "ここにフィードバックを入力してください...",
    ),
    "feedbackInformation": MessageLookupByLibrary.simpleMessage("フィードバック情報"),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "送信に失敗しました。後でもう一度お試しください",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "フィードバックをありがとうございます！",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage("モデルリストを取得"),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "まずモデルリストを取得してください",
    ),
    "fileAttachment": MessageLookupByLibrary.simpleMessage("File attachment"),
    "fileCount": m19,
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
    "fileStatus": MessageLookupByLibrary.simpleMessage("ファイル状態"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("音楽"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("音声"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("動画"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "ボット名、APIアドレス、APIキーを入力してください",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("システムに従う"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("フォントサイズ"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage("フォントサイズが更新されました"),
    "forgetMemory": MessageLookupByLibrary.simpleMessage("忘れる"),
    "generateImageFailed": m20,
    "generateMusicFailed": m21,
    "generateSpeechFailed": m22,
    "generateVideoFailed": m23,
    "generatedImage": MessageLookupByLibrary.simpleMessage("Image generated"),
    "generating": MessageLookupByLibrary.simpleMessage("Generating…"),
    "generatingImage": MessageLookupByLibrary.simpleMessage(
      "Generating image, please wait...",
    ),
    "generationFailed": MessageLookupByLibrary.simpleMessage("生成に失敗"),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "生成に失敗 · 部分回答を保持",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("ヘルプとフィードバック"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("API キーを非表示"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("ホーム"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage("時間別使用量"),
    "htmlPreview": MessageLookupByLibrary.simpleMessage("HTML プレビュー"),
    "idle": MessageLookupByLibrary.simpleMessage("待機中"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage("スキルフォルダーをインポート"),
    "importSkillZip": MessageLookupByLibrary.simpleMessage("スキル ZIP をインポート"),
    "importingSkill": MessageLookupByLibrary.simpleMessage("スキルをインポート中…"),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("入力トークン"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage("更新をインストール"),
    "invalidSummary": MessageLookupByLibrary.simpleMessage("生成された要約は検証に失敗しました"),
    "itemCount": m24,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("たった今"),
    "languageChanged": m25,
    "languageSettings": MessageLookupByLibrary.simpleMessage("言語設定"),
    "lightMode": MessageLookupByLibrary.simpleMessage("ライトモード"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("メモリを管理"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("メッセージごと"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "必要なときにメッセージ入力欄からスキルを選択します。",
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
    "mcpConnectionFailed": m26,
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
    "mcpHiddenEnvironmentVariableCount": m27,
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
    "mcpNoApprovalRequired": MessageLookupByLibrary.simpleMessage("確認不要"),
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
    "mcpServers": MessageLookupByLibrary.simpleMessage("MCP サーバー"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "MCP サーバーに接続してツールカタログを検出します。ツールはエージェント作成後に設定します。",
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
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("成果物"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "メモリが変更されました。再試行してください",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("訂正"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("決定"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("事実"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("設定"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("未解決の質問"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("タスク"),
    "memoryUserAssertion": MessageLookupByLibrary.simpleMessage("ユーザーの申告"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage("メッセージを入力..."),
    "messageSkills": MessageLookupByLibrary.simpleMessage("スキル"),
    "minutesAgo": m28,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("音声"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("ファイル"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("画像"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("マルチモーダル"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("音楽"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("リアルタイム"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("発話"),
    "modalityText": MessageLookupByLibrary.simpleMessage("テキスト"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("動画"),
    "model": MessageLookupByLibrary.simpleMessage("モデル"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage("モデル設定"),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage("モデルのコンテキストサイズ"),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("入力"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("出力"),
    "modelsRetrievedSuccess": m29,
    "modificationTime": MessageLookupByLibrary.simpleMessage("更新日時"),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("名前"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("名前が更新されました"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("新しいチャット"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "接続済みの利用可能な MCP ツールはありません。",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage("スキルが追加されていません"),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "このボットに必要なインストール済みスキルを追加します。",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage("利用可能なボットがありません"),
    "noChats": MessageLookupByLibrary.simpleMessage("まだチャットがありません"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage(
      "コンテンツが返されませんでした",
    ),
    "noConversationFilesFound": MessageLookupByLibrary.simpleMessage(
      "No matching files or folders.",
    ),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "利用できる会話の要約はまだありません。",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage("一致するボットが見つかりません"),
    "noMatchingChats": MessageLookupByLibrary.simpleMessage(
      "No matching chats found",
    ),
    "noMatchingMcpServers": MessageLookupByLibrary.simpleMessage(
      "No matching MCP servers found",
    ),
    "noMatchingMcpTools": MessageLookupByLibrary.simpleMessage(
      "No matching tools found",
    ),
    "noMatchingSkills": MessageLookupByLibrary.simpleMessage("一致するスキルが見つかりません"),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage("モデルが取得されませんでした"),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage(
      "スキルがインストールされていません",
    ),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md を含む Agent Skills フォルダーまたは ZIP をインポートしてください。",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "トークン使用履歴はありません",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("非対応"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "圧縮できる古いコンテキストが不足しています",
    ),
    "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
    "openLink": MessageLookupByLibrary.simpleMessage("リンクを開く"),
    "openWithSystem": MessageLookupByLibrary.simpleMessage(
      "Open with system app",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("出力トークン"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("部分回答"),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("音声を一時停止"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("生成を一時停止"),
    "pinMemory": MessageLookupByLibrary.simpleMessage("固定"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "選択したスキルをこの会話に固定",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("固定済み"),
    "playAudio": MessageLookupByLibrary.simpleMessage("音声を再生"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "APIキーを先に入力してください",
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
    "preview": MessageLookupByLibrary.simpleMessage("プレビュー"),
    "previewText": MessageLookupByLibrary.simpleMessage("テキスト効果のプレビュー"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("プライバシーポリシー"),
    "processCommandCount": m30,
    "processDuration": m31,
    "processFileCount": m32,
    "processInformation": MessageLookupByLibrary.simpleMessage("処理情報"),
    "processToolCount": m33,
    "profile": MessageLookupByLibrary.simpleMessage("プロフィール"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage("ご意見やご提案をお寄せください"),
    "provider": MessageLookupByLibrary.simpleMessage("プロバイダー"),
    "providerInformation": MessageLookupByLibrary.simpleMessage("プロバイダー情報"),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage("推論完了"),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage("推論中"),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage("推論中断"),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("再構築"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("更新"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage("カタログを更新"),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "カタログを更新中…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("スキルを削除"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("応答がキャンセルされました"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "停止済み · 部分回答を保持",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("デフォルトに戻す"),
    "responseError": m34,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("復元"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage("保持された最近のターン"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage("テストを実行"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("変更を保存"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m35,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("保存中..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("ボットを検索"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchConversationFiles": MessageLookupByLibrary.simpleMessage(
      "Search files and folders",
    ),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage("メモリを検索"),
    "searchSkills": MessageLookupByLibrary.simpleMessage("スキルを検索"),
    "selectBot": MessageLookupByLibrary.simpleMessage("ボットを選択"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("言語を選択"),
    "selectModel": MessageLookupByLibrary.simpleMessage("モデルを選択:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("プロバイダーを選択:"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("テーマを選択"),
    "send": MessageLookupByLibrary.simpleMessage("送信"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m36,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("API キーを表示"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "会話メッセージに実行の詳細を表示します。",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage("アセットあり"),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage("互換性"),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "この例ではスキルを有効化する",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "ユーザー依頼の例",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage("有効化結果"),
    "skillDetails": MessageLookupByLibrary.simpleMessage("スキルの詳細"),
    "skillDigest": MessageLookupByLibrary.simpleMessage("コンテンツダイジェスト"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("無効"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("有効"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("ファイル"),
    "skillImportFailed": m37,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage(
      "スキルをインポートしました",
    ),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("スキル"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "再利用可能な指示をインストールしてボットに関連付けます。",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "このバージョンでは、スキル内のスクリプトやコマンドは実行されません。",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("発行者"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "参照ファイルあり",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md は管理されたプロンプト指示としてのみ読み込まれます。スクリプト、コマンド、外部ツールは無効のままです。",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "デスクトップスクリプトサンドボックスが利用可能",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "承認するまでスクリプトはスキルごとに無効です。各呼び出しにも引き続き承認が必要です。",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "スキルスクリプトは利用不可",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "このプラットフォームには必要な隔離環境がありません。指示とリソースは引き続き利用できます。",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "スキルスクリプト設定を更新しました。",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "スクリプトはインストールされていますが、実行は無効です。",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage("スクリプト有効"),
    "skillSignature": MessageLookupByLibrary.simpleMessage("署名"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage("無効な署名"),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "不明な発行者",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage("未署名"),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage("署名検証済み"),
    "skillSource": MessageLookupByLibrary.simpleMessage("ソース"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("自動"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage("更新あり"),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("手動"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("通知"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("固定"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage("更新ポリシー"),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("ユーザー"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage("検証メモ"),
    "skillVersion": MessageLookupByLibrary.simpleMessage("バージョン"),
    "sourceCode": MessageLookupByLibrary.simpleMessage("ソースコード"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "下の入力欄にメッセージを送信してチャットを開始してください",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("チャットを始めましょう"),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "起動に失敗しました。もう一度お試しください。",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage("起動しています…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("有効化済み"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("添付済み"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage("承認待ち"),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("キャンセル済み"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("完了"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("拒否済み"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage("重複呼び出し"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("失敗"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("生成済み"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("進行中"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("記録済み"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("リクエスト済み"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("実行中"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("スキップ済み"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("タイムアウト"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("不明"),
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
    "strictGroundingMode": MessageLookupByLibrary.simpleMessage("厳格な検証モード"),
    "strictGroundingModeDescription": MessageLookupByLibrary.simpleMessage(
      "未検証の事実回答を隠し、検証とツール失敗の詳細は保持します。",
    ),
    "strictGroundingUnableToVerify": MessageLookupByLibrary.simpleMessage(
      "Stars はこの事実回答を検証できませんでした。証拠の詳細を確認するか、再検証してください。",
    ),
    "structuredProcessInfo": MessageLookupByLibrary.simpleMessage("構造化された処理情報"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("フィードバックを送信"),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage("要約済みメッセージ"),
    "supported": MessageLookupByLibrary.simpleMessage("対応"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("MCP 対応"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage("Skills 対応"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("システムプロンプト"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("テスト"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage("説明をテスト"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "テーマがダークモードに設定されました",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "テーマがライトモードに設定されました",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "テーマがシステムに従うように設定されました",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage("テーマ設定"),
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage("思考完了"),
    "thinkingCompletedWithDuration": m38,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("思考中…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("トークン使用量"),
    "tokens": MessageLookupByLibrary.simpleMessage("トークン"),
    "toolActionAccepted": MessageLookupByLibrary.simpleMessage("操作を受理"),
    "toolActionCompleted": MessageLookupByLibrary.simpleMessage("操作が完了"),
    "toolActionNotAccepted": MessageLookupByLibrary.simpleMessage("操作は未受理"),
    "toolActionNotCompleted": MessageLookupByLibrary.simpleMessage("操作は未完了"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage("1回のみ許可"),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("拒否"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("ツール呼び出し"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("破壊的"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("読み取り専用"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("書き込み"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("組み込み"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage("スキルスクリプト"),
    "toolStateNotReadBackVerified": MessageLookupByLibrary.simpleMessage(
      "状態は再読込検証されていません",
    ),
    "toolStateReadBackVerified": MessageLookupByLibrary.simpleMessage(
      "状態を再読込して検証済み",
    ),
    "totalTokens": MessageLookupByLibrary.simpleMessage("合計トークン"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "別の条件で検索するか、新しい項目を作成してください。",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("入力中..."),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage(
      "Unable to load bots",
    ),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage(
      "Unable to load chats",
    ),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage(
      "Unable to load messages",
    ),
    "unavailableBot": MessageLookupByLibrary.simpleMessage("利用できないボット"),
    "uninstall": MessageLookupByLibrary.simpleMessage("アンインストール"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage("スキルをアンインストール"),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("固定解除"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "この画像形式には対応していません。JPEG、PNG、GIF、BMP、または WebP 画像を選択してください。",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("ファイルをアップロード"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("画像をアップロード"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("ユーザー同意"),
    "version": MessageLookupByLibrary.simpleMessage("バージョン 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage("動画を読み込めません"),
    "videoPlaybackError": m39,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("要約を表示"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
