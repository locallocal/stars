// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ko_KR locale. All the
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
  String get localeName => 'ko_KR';

  static String m0(name) => "봇 \"${name}\"이(가) 추가되었습니다";

  static String m1(botName) => "\"${botName}\"이(가) 삭제되었습니다";

  static String m2(botName) =>
      "안녕하세요! 저는 ${botName}이라는 AI 어시스턴트입니다. 어떤 질문이든 편하게 물어보세요, 최선을 다해 도와드리겠습니다.";

  static String m3(botName) => "${botName}이(가) 입력 중...";

  static String m4(botName) => "봇 ${botName}이(가) 업데이트되었습니다";

  static String m5(botName) => "${botName}와(과)의 채팅이 삭제되었습니다";

  static String m6(botName) =>
      "\"${botName}\"와(과)의 모든 채팅 기록을 지우시겠습니까? 이 작업은 취소할 수 없습니다.";

  static String m7(botName) =>
      "봇을 삭제하면 관련된 모든 채팅도 삭제됩니다. ${botName}을(를) 정말로 삭제하시겠습니까?";

  static String m8(botName) =>
      "채팅을 삭제하면 모든 채팅 기록이 삭제됩니다. ${botName}와(과)의 채팅을 정말로 삭제하시겠습니까?";

  static String m9(language) => "언어가 ${language}(으)로 설정되었습니다";

  static String m10(minutes) => "${minutes}분 전";

  static String m11(error) => "응답을 가져오지 못했습니다: \$${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("봇"),
    "about": MessageLookupByLibrary.simpleMessage("정보"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("버블 정보"),
    "addBot": MessageLookupByLibrary.simpleMessage("봇 추가"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage("앱 글꼴 크기 조정"),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("글꼴 크기 조정"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API 주소:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API 키"),
    "apiType": MessageLookupByLibrary.simpleMessage("API 유형:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "언제 어디서나 AI와 채팅할 수 있는 간단하면서도 강력한 AI 채팅 애플리케이션입니다.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("버블"),
    "appTitle": MessageLookupByLibrary.simpleMessage("버블 - AI 채팅 어시스턴트"),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("봇 아바타"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botIsTyping": m3,
    "botName": MessageLookupByLibrary.simpleMessage("봇 이름"),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("취소"),
    "chatDeleted": m5,
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage("채팅 기록이 지워졌습니다"),
    "chats": MessageLookupByLibrary.simpleMessage("채팅"),
    "clear": MessageLookupByLibrary.simpleMessage("지우기"),
    "clearChat": MessageLookupByLibrary.simpleMessage("채팅 지우기"),
    "clearChatHistory": MessageLookupByLibrary.simpleMessage("채팅 기록 지우기"),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "오른쪽 상단의 +를 클릭하여 봇 추가",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "오른쪽 상단의 +를 클릭하여 채팅 시작",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("확인"),
    "confirmClearChat": m6,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("삭제 확인"),
    "confirmDeleteBot": m7,
    "confirmDeleteChat": m8,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage("연락처 정보(선택 사항)"),
    "copyright": MessageLookupByLibrary.simpleMessage("© 2025 버블 팀"),
    "customProvider": MessageLookupByLibrary.simpleMessage("사용자 정의 제공업체..."),
    "darkMode": MessageLookupByLibrary.simpleMessage("다크 모드"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "당신은 도움이 되는 AI 어시스턴트입니다. 한국어로 대답해 주세요.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("삭제"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("봇 삭제"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("채팅 삭제"),
    "editBot": MessageLookupByLibrary.simpleMessage("봇 편집"),
    "editName": MessageLookupByLibrary.simpleMessage("이름 수정"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "응답을 가져오지 못했습니다: 서버가 빈 응답을 반환했습니다",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage("API 주소 입력..."),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("API 키 입력..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("봇 이름 입력..."),
    "enterNewName": MessageLookupByLibrary.simpleMessage("새 이름을 입력하세요"),
    "enterProviderName": MessageLookupByLibrary.simpleMessage("제공업체 이름 입력..."),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage("시스템 프롬프트 입력..."),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "콘텐츠를 로드하는 중 오류가 발생했습니다. 나중에 다시 시도해 주세요.",
    ),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "피드백 내용을 입력해 주세요",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "앱 개선에 도움이 될 수 있도록 생각, 문제 또는 제안을 알려주세요",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage("여기에 피드백을 입력하세요..."),
    "feedbackSubmitError": MessageLookupByLibrary.simpleMessage(
      "제출 실패, 나중에 다시 시도해 주세요",
    ),
    "feedbackSubmitted": MessageLookupByLibrary.simpleMessage(
      "피드백을 보내주셔서 감사합니다!",
    ),
    "fetchModelList": MessageLookupByLibrary.simpleMessage("모델 목록 가져오기"),
    "fetchModelListFirst": MessageLookupByLibrary.simpleMessage(
      "먼저 모델 목록을 가져오세요",
    ),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "봇 이름, API 주소 및 API 키를 입력하세요",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("시스템 설정 따르기"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("글꼴 크기"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage("글꼴 크기가 업데이트되었습니다"),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("도움말 및 피드백"),
    "home": MessageLookupByLibrary.simpleMessage("홈"),
    "justNow": MessageLookupByLibrary.simpleMessage("방금"),
    "languageChanged": m9,
    "languageSettings": MessageLookupByLibrary.simpleMessage("언어 설정"),
    "lightMode": MessageLookupByLibrary.simpleMessage("라이트 모드"),
    "messageHint": MessageLookupByLibrary.simpleMessage("메시지 입력..."),
    "minutesAgo": m10,
    "model": MessageLookupByLibrary.simpleMessage("모델"),
    "name": MessageLookupByLibrary.simpleMessage("이름"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("이름이 업데이트되었습니다"),
    "newChat": MessageLookupByLibrary.simpleMessage("새 채팅"),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage("사용 가능한 봇이 없습니다"),
    "noChats": MessageLookupByLibrary.simpleMessage("아직 채팅이 없습니다"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("생성 일시 중지"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "API 키를 먼저 입력하세요",
    ),
    "previewText": MessageLookupByLibrary.simpleMessage("텍스트 효과 미리보기"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("개인정보 처리방침"),
    "profile": MessageLookupByLibrary.simpleMessage("프로필"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage("의견과 제안을 제공해 주세요"),
    "provider": MessageLookupByLibrary.simpleMessage("제공자"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("응답이 취소되었습니다"),
    "responseError": m11,
    "save": MessageLookupByLibrary.simpleMessage("저장"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("변경사항 저장"),
    "selectBot": MessageLookupByLibrary.simpleMessage("봇 선택"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("언어 선택"),
    "selectModel": MessageLookupByLibrary.simpleMessage("모델 선택:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("제공업체 선택:"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("테마 선택"),
    "send": MessageLookupByLibrary.simpleMessage("보내기"),
    "settings": MessageLookupByLibrary.simpleMessage("설정"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "채팅을 시작하려면 아래 입력 필드에 메시지를 보내세요",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("채팅 시작하기"),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("피드백 제출"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("시스템 프롬프트"),
    "themeSetToDark": MessageLookupByLibrary.simpleMessage(
      "테마가 다크 모드로 설정되었습니다",
    ),
    "themeSetToLight": MessageLookupByLibrary.simpleMessage(
      "테마가 라이트 모드로 설정되었습니다",
    ),
    "themeSetToSystem": MessageLookupByLibrary.simpleMessage(
      "테마가 시스템 설정을 따르도록 설정되었습니다",
    ),
    "themeSettings": MessageLookupByLibrary.simpleMessage("테마 설정"),
    "typing": MessageLookupByLibrary.simpleMessage("입력 중..."),
    "userAgreement": MessageLookupByLibrary.simpleMessage("사용자 동의"),
    "version": MessageLookupByLibrary.simpleMessage("버전 1.0.0"),
  };
}
