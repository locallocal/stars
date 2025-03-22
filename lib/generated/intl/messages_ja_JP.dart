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

  static String m0(name) => "ボット \"${name}\" が追加されました";

  static String m1(botName) => "ボット${botName}が更新されました";

  static String m2(botName) => "${botName}とのチャットが削除されました";

  static String m3(botName) =>
      "ボットを削除すると、関連するすべてのチャットも削除されます。${botName}を本当に削除しますか？";

  static String m4(botName) =>
      "チャットを削除するとすべてのチャット履歴が消去されます。${botName}とのチャットを本当に削除しますか？";

  static String m5(language) => "言語が${language}に設定されました";

  static String m6(minutes) => "${minutes}分前";

  static String m7(error) => "応答の取得に失敗しました：\$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("ボット"),
    "about": MessageLookupByLibrary.simpleMessage("アプリについて"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("バブルについて"),
    "addBot": MessageLookupByLibrary.simpleMessage("ボットを追加"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage(
      "アプリのフォントサイズを調整する",
    ),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("フォントサイズを調整"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("APIアドレス:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("APIキー"),
    "apiType": MessageLookupByLibrary.simpleMessage("APIタイプ:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "いつでもどこでもAIとチャットできるシンプルで強力なAIチャットアプリケーション。",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("バブル"),
    "appTitle": MessageLookupByLibrary.simpleMessage("バブル - AIチャットアシスタント"),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("ボットのアバター"),
    "botName": MessageLookupByLibrary.simpleMessage("ボット名"),
    "botUpdated": m1,
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "chatDeleted": m2,
    "chats": MessageLookupByLibrary.simpleMessage("チャット"),
    "clearChat": MessageLookupByLibrary.simpleMessage("チャットをクリア"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage("チャット履歴をクリア"),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "右上の+をクリックしてボットを追加",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "右上の+をクリックしてチャットを開始",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("確認"),
    "confirmDeleteBot": m3,
    "confirmDeleteChat": m4,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage("連絡先情報（任意）"),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 バブルチーム"),
    "customProvider": MessageLookupByLibrary.simpleMessage("カスタムプロバイダー..."),
    "darkMode": MessageLookupByLibrary.simpleMessage("ダークモード"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "あなたは役立つAIアシスタントです。日本語で回答してください。",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("削除"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("ボットを削除"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("チャットを削除"),
    "editBot": MessageLookupByLibrary.simpleMessage("ボットを編集"),
    "editName": MessageLookupByLibrary.simpleMessage("名前を編集"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "応答の取得に失敗しました：サーバーが空の応答を返しました",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage("APIアドレスを入力..."),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("APIキーを入力..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("ボット名を入力..."),
    "enterNewName": MessageLookupByLibrary.simpleMessage("新しい名前を入力してください"),
    "enterProviderName": MessageLookupByLibrary.simpleMessage("プロバイダー名を入力..."),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "システムプロンプトを入力...",
    ),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "コンテンツの読み込み中にエラーが発生しました。後でもう一度お試しください。",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "フィードバック内容を入力してください",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "アプリの改善に役立てるため、あなたの考え、問題点、または提案を教えてください",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage(
      "ここにフィードバックを入力してください...",
    ),
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
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "ボット名、APIアドレス、APIキーを入力してください",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("システムに従う"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("フォントサイズ"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage("フォントサイズが更新されました"),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("ヘルプとフィードバック"),
    "home": MessageLookupByLibrary.simpleMessage("ホーム"),
    "justNow": MessageLookupByLibrary.simpleMessage("たった今"),
    "languageChanged": m5,
    "languageSettings": MessageLookupByLibrary.simpleMessage("言語設定"),
    "lightMode": MessageLookupByLibrary.simpleMessage("ライトモード"),
    "messageHint": MessageLookupByLibrary.simpleMessage("メッセージを入力..."),
    "minutesAgo": m6,
    "model": MessageLookupByLibrary.simpleMessage("モデル"),
    "name": MessageLookupByLibrary.simpleMessage("名前"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("名前が更新されました"),
    "newChat": MessageLookupByLibrary.simpleMessage("新しいチャット"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage("利用可能なボットがありません"),
    "noChats": MessageLookupByLibrary.simpleMessage("まだチャットがありません"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "APIキーを先に入力してください",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage("テキスト効果のプレビュー"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("プライバシーポリシー"),
    "profile": MessageLookupByLibrary.simpleMessage("プロフィール"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage("ご意見やご提案をお寄せください"),
    "provider": MessageLookupByLibrary.simpleMessage("プロバイダー"),
    "responseError": m7,
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("変更を保存"),
    "selectBot": MessageLookupByLibrary.simpleMessage("ボットを選択"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("言語を選択"),
    "selectModel": MessageLookupByLibrary.simpleMessage("モデルを選択:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("プロバイダーを選択:"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("テーマを選択"),
    "send": MessageLookupByLibrary.simpleMessage("送信"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "startChatting": MessageLookupByLibrary.simpleMessage("チャットを始めましょう"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("フィードバックを送信"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("システムプロンプト"),
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
    "typing": MessageLookupByLibrary.simpleMessage("入力中..."),
    "userAgreement": MessageLookupByLibrary.simpleMessage("ユーザー同意"),
    "version": MessageLookupByLibrary.simpleMessage("バージョン 1.0.0"),
  };
}
