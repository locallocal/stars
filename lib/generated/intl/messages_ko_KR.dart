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

  static String m6(error) => "Could not clear chat history: ${error}";

  static String m7(botName) =>
      "\"${botName}\"와(과)의 모든 채팅 기록을 지우시겠습니까? 이 작업은 취소할 수 없습니다.";

  static String m8(botName) =>
      "봇을 삭제하면 관련된 모든 채팅도 삭제됩니다. ${botName}을(를) 정말로 삭제하시겠습니까?";

  static String m9(botName) =>
      "채팅을 삭제하면 모든 채팅 기록이 삭제됩니다. ${botName}와(과)의 채팅을 정말로 삭제하시겠습니까?";

  static String m10(name) =>
      "Delete ${name}? Its cached Tool catalog and secure credential will also be removed.";

  static String m11(name) => "${name} 스킬을 제거할까요? 봇 연결도 함께 삭제됩니다.";

  static String m12(year) => "© ${year} Stars 팀";

  static String m13(error) => "Could not create the chat: ${error}";

  static String m14(error) => "Could not delete the chat: ${error}";

  static String m15(milliseconds) => "${milliseconds}밀리초";

  static String m16(seconds) => "${seconds}초";

  static String m17(name) =>
      "${name}에서 선언된 스크립트를 도구로 등록하도록 허용합니다. 각 호출에는 계속 승인이 필요합니다.";

  static String m18(count) => "${count} files";

  static String m19(error) => "Generate image failed: ${error}";

  static String m20(error) => "Could not generate music: ${error}";

  static String m21(error) => "Could not generate speech: ${error}";

  static String m22(error) => "Could not generate video: ${error}";

  static String m23(count) => "${count} items";

  static String m24(language) => "언어가 ${language}(으)로 설정되었습니다";

  static String m25(error) => "MCP connection failed: ${error}";

  static String m26(count) => "${count} configured (values hidden)";

  static String m27(minutes) => "${minutes}분 전";

  static String m28(count) => "${count}개의 모델을 성공적으로 검색했습니다";

  static String m29(count) => "명령 실행 ${count}회";

  static String m30(duration) => "소요 시간 ${duration}";

  static String m31(count) => "파일 변경 ${count}건";

  static String m32(count) => "도구 호출 ${count}회";

  static String m33(error) => "응답을 가져오지 못했습니다: ${error}";

  static String m34(error) => "Could not save image: ${error}";

  static String m35(error) => "Could not share image: ${error}";

  static String m36(error) => "스킬을 가져올 수 없습니다: ${error}";

  static String m37(duration) => "생각 완료 · ${duration}";

  static String m38(error) => "동영상 재생 오류: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Bots": MessageLookupByLibrary.simpleMessage("봇"),
    "about": MessageLookupByLibrary.simpleMessage("정보"),
    "aboutApp": MessageLookupByLibrary.simpleMessage("Stars 정보"),
    "activeRequestCannotCancel": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be cancelled. Wait for it to finish.",
    ),
    "activeRequestCannotStop": MessageLookupByLibrary.simpleMessage(
      "The active request cannot be stopped",
    ),
    "addAttachment": MessageLookupByLibrary.simpleMessage("Attachment"),
    "addBot": MessageLookupByLibrary.simpleMessage("봇 추가"),
    "addMcpServer": MessageLookupByLibrary.simpleMessage("Add MCP Server"),
    "addSkill": MessageLookupByLibrary.simpleMessage("스킬 추가"),
    "adjustAppFontSize": MessageLookupByLibrary.simpleMessage("앱 글꼴 크기 조정"),
    "adjustFontSize": MessageLookupByLibrary.simpleMessage("글꼴 크기 조정"),
    "allSkillsAdded": MessageLookupByLibrary.simpleMessage(
      "설치된 모든 스킬이 추가되었습니다.",
    ),
    "alwaysActivation": MessageLookupByLibrary.simpleMessage("항상 사용"),
    "alwaysActivationDescription": MessageLookupByLibrary.simpleMessage(
      "모든 텍스트 요청에 이 스킬을 삽입합니다.",
    ),
    "alwaysOn": MessageLookupByLibrary.simpleMessage("항상 사용"),
    "apiAddress": MessageLookupByLibrary.simpleMessage("API 주소:"),
    "apiKey": MessageLookupByLibrary.simpleMessage("API 키"),
    "apiType": MessageLookupByLibrary.simpleMessage("API 유형:"),
    "appDescription": MessageLookupByLibrary.simpleMessage(
      "언제 어디서나 AI와 채팅할 수 있는 간단하면서도 강력한 AI 채팅 애플리케이션입니다.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Stars"),
    "appTitle": MessageLookupByLibrary.simpleMessage("Stars - AI 채팅 어시스턴트"),
    "applicationInjectedPrompt": MessageLookupByLibrary.simpleMessage(
      "시스템 프롬프트",
    ),
    "applicationInjectedPromptDescription": MessageLookupByLibrary.simpleMessage(
      "Stars에서 관리하며 모든 모델 요청에 주입됩니다. 현재 에이전트와 대화 식별자는 런타임에 추가되며 편집할 수 없습니다.",
    ),
    "attachedFiles": MessageLookupByLibrary.simpleMessage("Attached Files"),
    "attachedImages": MessageLookupByLibrary.simpleMessage("Attached Images"),
    "attachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "autoActivation": MessageLookupByLibrary.simpleMessage("자동"),
    "autoActivationDescription": MessageLookupByLibrary.simpleMessage(
      "지원되는 모델이 설명을 바탕으로 이 스킬을 활성화합니다.",
    ),
    "autoActivationUnavailable": MessageLookupByLibrary.simpleMessage(
      "이 제공자는 수동 스킬만 지원합니다.",
    ),
    "automaticMemory": MessageLookupByLibrary.simpleMessage("자동 메모리"),
    "automaticSummaryWarning": MessageLookupByLibrary.simpleMessage(
      "자동 요약은 부정확할 수 있습니다. 현재 메시지가 항상 우선합니다.",
    ),
    "backToDailyUsage": MessageLookupByLibrary.simpleMessage("일일 사용량으로 돌아가기"),
    "basicInformation": MessageLookupByLibrary.simpleMessage("기본 정보"),
    "botAddedSuccess": m0,
    "botAvatar": MessageLookupByLibrary.simpleMessage("봇 아바타"),
    "botDeleted": m1,
    "botGreeting": m2,
    "botInformation": MessageLookupByLibrary.simpleMessage("Bot Information"),
    "botIsTyping": m3,
    "botMcpToolsDescription": MessageLookupByLibrary.simpleMessage(
      "이 에이전트에서 MCP 도구를 활성화합니다. 도구 호출에는 기본적으로 확인이 필요합니다.",
    ),
    "botName": MessageLookupByLibrary.simpleMessage("봇 이름"),
    "botSearchScope": MessageLookupByLibrary.simpleMessage(
      "봇 이름으로 목록을 필터링합니다.",
    ),
    "botSkills": MessageLookupByLibrary.simpleMessage("스킬"),
    "botSkillsDescription": MessageLookupByLibrary.simpleMessage(
      "이 봇에서 사용할 재사용 가능한 지침을 선택하세요.",
    ),
    "botUnavailableTitle": MessageLookupByLibrary.simpleMessage(
      "This bot is unavailable",
    ),
    "botUpdated": m4,
    "cancel": MessageLookupByLibrary.simpleMessage("취소"),
    "changeAvatar": MessageLookupByLibrary.simpleMessage("아바타 변경"),
    "changesSaved": MessageLookupByLibrary.simpleMessage("저장됨"),
    "chatDeleted": m5,
    "chatExecutionStatus": MessageLookupByLibrary.simpleMessage("채팅 실행 상태"),
    "chatHistoryCleared": MessageLookupByLibrary.simpleMessage("채팅 기록이 지워졌습니다"),
    "chatSearchScope": MessageLookupByLibrary.simpleMessage(
      "Search matches bot names and the latest message.",
    ),
    "chats": MessageLookupByLibrary.simpleMessage("채팅"),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "clear": MessageLookupByLibrary.simpleMessage("지우기"),
    "clearAttachments": MessageLookupByLibrary.simpleMessage(
      "Clear attachments",
    ),
    "clearAutomaticMemory": MessageLookupByLibrary.simpleMessage("자동 메모리 지우기"),
    "clearChat": MessageLookupByLibrary.simpleMessage("채팅 지우기"),
    "clearChatFailed": m6,
    "clearChatHistory": MessageLookupByLibrary.simpleMessage("채팅 기록 지우기"),
    "clearPinnedSkills": MessageLookupByLibrary.simpleMessage("대화 고정 해제"),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clickDayForHourlyUsage": MessageLookupByLibrary.simpleMessage(
      "시간별 사용량을 볼 날짜를 선택하세요",
    ),
    "clickToCreateBot": MessageLookupByLibrary.simpleMessage(
      "오른쪽 상단의 +를 클릭하여 봇 추가",
    ),
    "clickToStartChat": MessageLookupByLibrary.simpleMessage(
      "새 채팅을 클릭하여 대화를 만드세요",
    ),
    "commandExecutions": MessageLookupByLibrary.simpleMessage("명령 실행"),
    "compactNow": MessageLookupByLibrary.simpleMessage("지금 압축"),
    "compactingContext": MessageLookupByLibrary.simpleMessage("컨텍스트 정리 중…"),
    "compactionFailed": MessageLookupByLibrary.simpleMessage("실패"),
    "compactionStatus": MessageLookupByLibrary.simpleMessage("압축 상태"),
    "confirm": MessageLookupByLibrary.simpleMessage("확인"),
    "confirmClearChat": m7,
    "confirmDelete": MessageLookupByLibrary.simpleMessage("삭제 확인"),
    "confirmDeleteBot": m8,
    "confirmDeleteChat": m9,
    "confirmDeleteMcpServer": m10,
    "confirmUninstallSkill": m11,
    "contactInfoHint": MessageLookupByLibrary.simpleMessage("연락처 정보(선택 사항)"),
    "contextAndMemory": MessageLookupByLibrary.simpleMessage("컨텍스트와 메모리"),
    "contextCompacted": MessageLookupByLibrary.simpleMessage("컨텍스트가 압축되었습니다"),
    "contextWindow": MessageLookupByLibrary.simpleMessage("컨텍스트 창"),
    "conversationSummary": MessageLookupByLibrary.simpleMessage("대화 요약"),
    "conversationTokenShare": MessageLookupByLibrary.simpleMessage("대화별 토큰 비율"),
    "copyApiKey": MessageLookupByLibrary.simpleMessage("API 키 복사"),
    "copySkillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Copy installation location",
    ),
    "copyright": m12,
    "createChatFailed": m13,
    "creatingChat": MessageLookupByLibrary.simpleMessage("Creating…"),
    "creationTime": MessageLookupByLibrary.simpleMessage("생성 시간"),
    "customProvider": MessageLookupByLibrary.simpleMessage("사용자 정의 제공업체..."),
    "dailyTokenUsage": MessageLookupByLibrary.simpleMessage("일일 사용량"),
    "darkMode": MessageLookupByLibrary.simpleMessage("다크 모드"),
    "databaseDowngradeNotSupported": MessageLookupByLibrary.simpleMessage(
      "이 데이터베이스는 더 최신 버전의 Stars에서 생성되었습니다. 앱을 업데이트한 후 열어 주세요.",
    ),
    "databaseRecoveryFailed": MessageLookupByLibrary.simpleMessage(
      "데이터베이스 무결성 검사에 실패했으며 현재 버전의 백업에서도 복구하지 못했습니다.",
    ),
    "deepThinking": MessageLookupByLibrary.simpleMessage("심층 사고"),
    "defaultSystemPrompt": MessageLookupByLibrary.simpleMessage(
      "당신은 도움이 되는 AI 어시스턴트입니다. 한국어로 대답해 주세요.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("삭제"),
    "deleteBot": MessageLookupByLibrary.simpleMessage("봇 삭제"),
    "deleteChat": MessageLookupByLibrary.simpleMessage("채팅 삭제"),
    "deleteChatFailed": m14,
    "deleteMcpServer": MessageLookupByLibrary.simpleMessage(
      "Delete MCP Server",
    ),
    "desktopAboutAndLegal": MessageLookupByLibrary.simpleMessage(
      "앱 정보 및 법적 고지",
    ),
    "desktopAppearanceAndLanguage": MessageLookupByLibrary.simpleMessage(
      "모양 및 언어",
    ),
    "desktopEditProfileDescription": MessageLookupByLibrary.simpleMessage(
      "아바타와 표시 이름을 변경합니다.",
    ),
    "desktopGeneral": MessageLookupByLibrary.simpleMessage("일반"),
    "desktopHelpAndSupport": MessageLookupByLibrary.simpleMessage("도움말 및 지원"),
    "desktopPersonalInformation": MessageLookupByLibrary.simpleMessage("개인 정보"),
    "desktopSavedImmediatelyDescription": MessageLookupByLibrary.simpleMessage(
      "변경 사항은 즉시 적용되며 로컬에 저장됩니다.",
    ),
    "desktopSettingsDescription": MessageLookupByLibrary.simpleMessage(
      "프로필, 모양, 언어 및 앱 지원을 관리합니다.",
    ),
    "details": MessageLookupByLibrary.simpleMessage("세부 정보"),
    "directPlayback": MessageLookupByLibrary.simpleMessage("Ready to play"),
    "directPreview": MessageLookupByLibrary.simpleMessage("Ready to preview"),
    "disableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "모두 확인 없이 실행 해제",
    ),
    "disableAllMcpTools": MessageLookupByLibrary.simpleMessage("모든 도구 끄기"),
    "disableSkillScripts": MessageLookupByLibrary.simpleMessage("스크립트 비활성화"),
    "durationMilliseconds": m15,
    "durationSeconds": m16,
    "edit": MessageLookupByLibrary.simpleMessage("편집"),
    "editBot": MessageLookupByLibrary.simpleMessage("봇 편집"),
    "editMcpServer": MessageLookupByLibrary.simpleMessage("Edit MCP Server"),
    "editMemory": MessageLookupByLibrary.simpleMessage("메모리 편집"),
    "editName": MessageLookupByLibrary.simpleMessage("이름 수정"),
    "emptyResponseError": MessageLookupByLibrary.simpleMessage(
      "응답을 가져오지 못했습니다: 서버가 빈 응답을 반환했습니다",
    ),
    "enableAllMcpToolNoApproval": MessageLookupByLibrary.simpleMessage(
      "모두 확인 없이 실행",
    ),
    "enableAllMcpTools": MessageLookupByLibrary.simpleMessage("모든 도구 켜기"),
    "enableSkillScripts": MessageLookupByLibrary.simpleMessage("스크립트 활성화"),
    "enableSkillScriptsDescription": m17,
    "enableSkillScriptsTitle": MessageLookupByLibrary.simpleMessage(
      "격리된 스킬 스크립트를 활성화할까요?",
    ),
    "enterApiAddress": MessageLookupByLibrary.simpleMessage("API 주소 입력..."),
    "enterApiKey": MessageLookupByLibrary.simpleMessage("API 키 입력..."),
    "enterBotName": MessageLookupByLibrary.simpleMessage("봇 이름 입력..."),
    "enterDisplayName": MessageLookupByLibrary.simpleMessage("표시 이름을 입력하세요"),
    "enterNewName": MessageLookupByLibrary.simpleMessage("새 이름을 입력하세요"),
    "enterProviderName": MessageLookupByLibrary.simpleMessage("제공업체 이름 입력..."),
    "enterSystemPrompt": MessageLookupByLibrary.simpleMessage("시스템 프롬프트 입력..."),
    "errorLoadingContent": MessageLookupByLibrary.simpleMessage(
      "콘텐츠를 로드하는 중 오류가 발생했습니다. 나중에 다시 시도해 주세요.",
    ),
    "estimatedContextUsage": MessageLookupByLibrary.simpleMessage("예상 사용량"),
    "executionStatus": MessageLookupByLibrary.simpleMessage("실행 상태"),
    "feedbackContentRequired": MessageLookupByLibrary.simpleMessage(
      "피드백 내용을 입력해 주세요",
    ),
    "feedbackDescription": MessageLookupByLibrary.simpleMessage(
      "앱 개선에 도움이 될 수 있도록 생각, 문제 또는 제안을 알려주세요",
    ),
    "feedbackHint": MessageLookupByLibrary.simpleMessage("여기에 피드백을 입력하세요..."),
    "feedbackInformation": MessageLookupByLibrary.simpleMessage("피드백 정보"),
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
    "fileAttachment": MessageLookupByLibrary.simpleMessage("File attachment"),
    "fileCount": m18,
    "fileResult": MessageLookupByLibrary.simpleMessage("File result"),
    "fileStatus": MessageLookupByLibrary.simpleMessage("파일 상태"),
    "fileTypeMusic": MessageLookupByLibrary.simpleMessage("음악"),
    "fileTypeSpeech": MessageLookupByLibrary.simpleMessage("음성"),
    "fileTypeVideo": MessageLookupByLibrary.simpleMessage("동영상"),
    "fillRequiredFields": MessageLookupByLibrary.simpleMessage(
      "봇 이름, API 주소 및 API 키를 입력하세요",
    ),
    "followSystem": MessageLookupByLibrary.simpleMessage("시스템 설정 따르기"),
    "fontSizeSettings": MessageLookupByLibrary.simpleMessage("글꼴 크기"),
    "fontSizeUpdated": MessageLookupByLibrary.simpleMessage("글꼴 크기가 업데이트되었습니다"),
    "forgetMemory": MessageLookupByLibrary.simpleMessage("잊기"),
    "generateImageFailed": m19,
    "generateMusicFailed": m20,
    "generateSpeechFailed": m21,
    "generateVideoFailed": m22,
    "generatedImage": MessageLookupByLibrary.simpleMessage("Image generated"),
    "generating": MessageLookupByLibrary.simpleMessage("Generating…"),
    "generatingImage": MessageLookupByLibrary.simpleMessage(
      "Generating image, please wait...",
    ),
    "generationFailed": MessageLookupByLibrary.simpleMessage("생성 실패"),
    "generationFailedPartial": MessageLookupByLibrary.simpleMessage(
      "생성 실패 · 부분 응답 유지",
    ),
    "helpAndFeedback": MessageLookupByLibrary.simpleMessage("도움말 및 피드백"),
    "hideApiKey": MessageLookupByLibrary.simpleMessage("API 키 숨기기"),
    "hideInspector": MessageLookupByLibrary.simpleMessage("Hide Bot Info"),
    "hideSidebar": MessageLookupByLibrary.simpleMessage("Hide Sidebar"),
    "home": MessageLookupByLibrary.simpleMessage("홈"),
    "hourlyTokenUsage": MessageLookupByLibrary.simpleMessage("시간별 사용량"),
    "idle": MessageLookupByLibrary.simpleMessage("유휴"),
    "imageAttachment": MessageLookupByLibrary.simpleMessage("Image attachment"),
    "imageResult": MessageLookupByLibrary.simpleMessage("Image result"),
    "imageSavedToGallery": MessageLookupByLibrary.simpleMessage(
      "Image saved to gallery",
    ),
    "imageSize": MessageLookupByLibrary.simpleMessage("Image Size"),
    "imageStyle": MessageLookupByLibrary.simpleMessage("Image Style"),
    "importSkillFolder": MessageLookupByLibrary.simpleMessage("스킬 폴더 가져오기"),
    "importSkillZip": MessageLookupByLibrary.simpleMessage("스킬 ZIP 가져오기"),
    "importingSkill": MessageLookupByLibrary.simpleMessage("스킬 가져오는 중…"),
    "includesDuration": MessageLookupByLibrary.simpleMessage(
      "Includes duration",
    ),
    "inputTokens": MessageLookupByLibrary.simpleMessage("입력 토큰"),
    "installSkillUpdate": MessageLookupByLibrary.simpleMessage("업데이트 설치"),
    "invalidSummary": MessageLookupByLibrary.simpleMessage(
      "생성된 요약이 검증을 통과하지 못했습니다",
    ),
    "itemCount": m23,
    "jumpToLatest": MessageLookupByLibrary.simpleMessage("Jump to Latest"),
    "justNow": MessageLookupByLibrary.simpleMessage("방금"),
    "languageChanged": m24,
    "languageSettings": MessageLookupByLibrary.simpleMessage("언어 설정"),
    "lightMode": MessageLookupByLibrary.simpleMessage("라이트 모드"),
    "linkOpenFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to open this link.",
    ),
    "localMcpDisabledDescription": MessageLookupByLibrary.simpleMessage(
      "Local process-based MCP servers remain disabled pending a platform security review.",
    ),
    "manageMemory": MessageLookupByLibrary.simpleMessage("메모리 관리"),
    "manualActivation": MessageLookupByLibrary.simpleMessage("메시지별"),
    "manualActivationDescription": MessageLookupByLibrary.simpleMessage(
      "필요할 때 메시지 입력창에서 스킬을 선택하세요.",
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
    "mcpNoApprovalRequired": MessageLookupByLibrary.simpleMessage("확인 없이 실행"),
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
    "mcpServers": MessageLookupByLibrary.simpleMessage("MCP 서버"),
    "mcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "MCP 서버를 연결하고 도구 카탈로그를 검색합니다. 에이전트를 만든 후 도구를 구성하세요.",
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
    "memoryArtifact": MessageLookupByLibrary.simpleMessage("결과물"),
    "memoryChangedRetry": MessageLookupByLibrary.simpleMessage(
      "메모리가 변경되었습니다. 다시 시도하세요",
    ),
    "memoryCorrection": MessageLookupByLibrary.simpleMessage("수정"),
    "memoryDecision": MessageLookupByLibrary.simpleMessage("결정"),
    "memoryFact": MessageLookupByLibrary.simpleMessage("사실"),
    "memoryPreference": MessageLookupByLibrary.simpleMessage("환경 설정"),
    "memoryQuestion": MessageLookupByLibrary.simpleMessage("열린 질문"),
    "memoryTask": MessageLookupByLibrary.simpleMessage("작업"),
    "messageCopied": MessageLookupByLibrary.simpleMessage(
      "Message copied to clipboard",
    ),
    "messageHint": MessageLookupByLibrary.simpleMessage("메시지 입력..."),
    "messageSkills": MessageLookupByLibrary.simpleMessage("스킬"),
    "minutesAgo": m27,
    "modalityAudio": MessageLookupByLibrary.simpleMessage("오디오"),
    "modalityFile": MessageLookupByLibrary.simpleMessage("파일"),
    "modalityImage": MessageLookupByLibrary.simpleMessage("이미지"),
    "modalityMulti": MessageLookupByLibrary.simpleMessage("멀티모달"),
    "modalityMusic": MessageLookupByLibrary.simpleMessage("음악"),
    "modalityRealtime": MessageLookupByLibrary.simpleMessage("실시간"),
    "modalitySpeech": MessageLookupByLibrary.simpleMessage("음성"),
    "modalityText": MessageLookupByLibrary.simpleMessage("텍스트"),
    "modalityVideo": MessageLookupByLibrary.simpleMessage("비디오"),
    "model": MessageLookupByLibrary.simpleMessage("모델"),
    "modelConfiguration": MessageLookupByLibrary.simpleMessage("모델 구성"),
    "modelContextWindow": MessageLookupByLibrary.simpleMessage("모델 컨텍스트 크기"),
    "modelInputModalities": MessageLookupByLibrary.simpleMessage("입력"),
    "modelOutputModalities": MessageLookupByLibrary.simpleMessage("출력"),
    "modelsRetrievedSuccess": m28,
    "modificationTime": MessageLookupByLibrary.simpleMessage("수정 시간"),
    "musicGenerated": MessageLookupByLibrary.simpleMessage("Music generated"),
    "musicResult": MessageLookupByLibrary.simpleMessage("Music result"),
    "name": MessageLookupByLibrary.simpleMessage("이름"),
    "nameUpdated": MessageLookupByLibrary.simpleMessage("이름이 업데이트되었습니다"),
    "newBotWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "New bots remain in the workspace for editing.",
    ),
    "newChat": MessageLookupByLibrary.simpleMessage("새 채팅"),
    "newChatWorkspaceHint": MessageLookupByLibrary.simpleMessage(
      "A new chat opens directly in the workspace.",
    ),
    "noBotMcpToolsAvailable": MessageLookupByLibrary.simpleMessage(
      "연결되어 사용 가능한 MCP 도구가 없습니다.",
    ),
    "noBotSkillsAdded": MessageLookupByLibrary.simpleMessage("추가된 스킬 없음"),
    "noBotSkillsAddedDescription": MessageLookupByLibrary.simpleMessage(
      "이 봇에 필요한 설치된 스킬을 추가하세요.",
    ),
    "noBotsAvailable": MessageLookupByLibrary.simpleMessage("사용 가능한 봇이 없습니다"),
    "noChats": MessageLookupByLibrary.simpleMessage("아직 채팅이 없습니다"),
    "noContentReturned": MessageLookupByLibrary.simpleMessage("콘텐츠가 반환되지 않음"),
    "noConversationSummary": MessageLookupByLibrary.simpleMessage(
      "아직 사용할 수 있는 대화 요약이 없습니다.",
    ),
    "noMatchingBots": MessageLookupByLibrary.simpleMessage("일치하는 봇을 찾을 수 없습니다"),
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
      "일치하는 스킬을 찾을 수 없음",
    ),
    "noMcpServers": MessageLookupByLibrary.simpleMessage("No MCP Servers"),
    "noMcpServersDescription": MessageLookupByLibrary.simpleMessage(
      "Add a Streamable HTTP or desktop stdio server to discover its Tool catalog.",
    ),
    "noMcpToolsDiscovered": MessageLookupByLibrary.simpleMessage(
      "No Tools discovered. Check the connection and refresh.",
    ),
    "noModelsRetrieved": MessageLookupByLibrary.simpleMessage("검색된 모델이 없습니다"),
    "noSkillsInstalled": MessageLookupByLibrary.simpleMessage("설치된 스킬 없음"),
    "noSkillsInstalledDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md가 포함된 Agent Skills 폴더 또는 ZIP을 가져오세요.",
    ),
    "noTokenUsageRecorded": MessageLookupByLibrary.simpleMessage(
      "기록된 토큰 사용량 없음",
    ),
    "notSupported": MessageLookupByLibrary.simpleMessage("지원되지 않음"),
    "nothingToCompact": MessageLookupByLibrary.simpleMessage(
      "압축할 이전 컨텍스트가 충분하지 않습니다",
    ),
    "orphanedChatGuidance": MessageLookupByLibrary.simpleMessage(
      "Delete this orphaned chat or recreate the missing bot.",
    ),
    "outputTokens": MessageLookupByLibrary.simpleMessage("출력 토큰"),
    "partialResponse": MessageLookupByLibrary.simpleMessage("부분 응답"),
    "pauseAudio": MessageLookupByLibrary.simpleMessage("오디오 일시정지"),
    "pauseGeneration": MessageLookupByLibrary.simpleMessage("생성 일시 중지"),
    "pinMemory": MessageLookupByLibrary.simpleMessage("고정"),
    "pinSelectedSkills": MessageLookupByLibrary.simpleMessage(
      "선택한 스킬을 이 대화에 고정",
    ),
    "pinnedSkill": MessageLookupByLibrary.simpleMessage("고정됨"),
    "playAudio": MessageLookupByLibrary.simpleMessage("오디오 재생"),
    "pleaseEnterApiKey": MessageLookupByLibrary.simpleMessage(
      "API 키를 먼저 입력하세요",
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
    "previewText": MessageLookupByLibrary.simpleMessage("텍스트 효과 미리보기"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("개인정보 처리방침"),
    "processCommandCount": m29,
    "processDuration": m30,
    "processFileCount": m31,
    "processInformation": MessageLookupByLibrary.simpleMessage("프로세스 정보"),
    "processToolCount": m32,
    "profile": MessageLookupByLibrary.simpleMessage("프로필"),
    "provideFeedback": MessageLookupByLibrary.simpleMessage("의견과 제안을 제공해 주세요"),
    "provider": MessageLookupByLibrary.simpleMessage("제공자"),
    "providerInformation": MessageLookupByLibrary.simpleMessage("제공업체 정보"),
    "reasoningCompleted": MessageLookupByLibrary.simpleMessage("추론 완료"),
    "reasoningInProgress": MessageLookupByLibrary.simpleMessage("추론 진행 중"),
    "reasoningInterrupted": MessageLookupByLibrary.simpleMessage("추론 중단"),
    "rebuildMemory": MessageLookupByLibrary.simpleMessage("다시 구축"),
    "referenceAudio": MessageLookupByLibrary.simpleMessage("Reference audio"),
    "refresh": MessageLookupByLibrary.simpleMessage("새로 고침"),
    "refreshMcpTools": MessageLookupByLibrary.simpleMessage("Refresh Tools"),
    "refreshSkillCatalogs": MessageLookupByLibrary.simpleMessage("카탈로그 새로 고침"),
    "refreshingSkillCatalogs": MessageLookupByLibrary.simpleMessage(
      "카탈로그 새로 고치는 중…",
    ),
    "remoteMcpOnly": MessageLookupByLibrary.simpleMessage("Remote MCP only"),
    "removeFileAttachment": MessageLookupByLibrary.simpleMessage("Remove file"),
    "removeImageAttachment": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "removeMcpServer": MessageLookupByLibrary.simpleMessage(
      "Remove MCP Server",
    ),
    "removeSkill": MessageLookupByLibrary.simpleMessage("스킬 제거"),
    "replyCancelled": MessageLookupByLibrary.simpleMessage("응답이 취소되었습니다"),
    "replyStoppedPartial": MessageLookupByLibrary.simpleMessage(
      "중지됨 · 부분 응답 유지",
    ),
    "resetToDefault": MessageLookupByLibrary.simpleMessage("기본값으로 재설정"),
    "responseError": m33,
    "restoreMemory": MessageLookupByLibrary.simpleMessage("복원"),
    "retainedRecentTurns": MessageLookupByLibrary.simpleMessage("유지된 최근 턴"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "runSkillDescriptionTest": MessageLookupByLibrary.simpleMessage("테스트 실행"),
    "save": MessageLookupByLibrary.simpleMessage("저장"),
    "saveAndConnect": MessageLookupByLibrary.simpleMessage("Save and connect"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("변경사항 저장"),
    "saveImage": MessageLookupByLibrary.simpleMessage("Save image"),
    "saveImageFailed": m34,
    "saveToGalleryFailed": MessageLookupByLibrary.simpleMessage(
      "Could not save to gallery",
    ),
    "savingChanges": MessageLookupByLibrary.simpleMessage("저장 중..."),
    "searchBots": MessageLookupByLibrary.simpleMessage("봇 검색"),
    "searchChats": MessageLookupByLibrary.simpleMessage("Search conversations"),
    "searchMcpServers": MessageLookupByLibrary.simpleMessage(
      "Search MCP servers",
    ),
    "searchMcpTools": MessageLookupByLibrary.simpleMessage("Search tools"),
    "searchMemory": MessageLookupByLibrary.simpleMessage("메모리 검색"),
    "searchSkills": MessageLookupByLibrary.simpleMessage("스킬 검색"),
    "selectBot": MessageLookupByLibrary.simpleMessage("봇 선택"),
    "selectLanguage": MessageLookupByLibrary.simpleMessage("언어 선택"),
    "selectModel": MessageLookupByLibrary.simpleMessage("모델 선택:"),
    "selectProvider": MessageLookupByLibrary.simpleMessage("제공업체 선택:"),
    "selectTheme": MessageLookupByLibrary.simpleMessage("테마 선택"),
    "send": MessageLookupByLibrary.simpleMessage("보내기"),
    "settings": MessageLookupByLibrary.simpleMessage("설정"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shareImageFailed": m35,
    "sharedImageFromStars": MessageLookupByLibrary.simpleMessage(
      "Image from Stars",
    ),
    "showApiKey": MessageLookupByLibrary.simpleMessage("API 키 표시"),
    "showExecutionStatusDescription": MessageLookupByLibrary.simpleMessage(
      "대화 메시지에 실행 세부 정보를 표시합니다.",
    ),
    "showInspector": MessageLookupByLibrary.simpleMessage("Show Bot Info"),
    "showSidebar": MessageLookupByLibrary.simpleMessage("Show Sidebar"),
    "skillAssetsAvailable": MessageLookupByLibrary.simpleMessage("에셋 사용 가능"),
    "skillCompatibility": MessageLookupByLibrary.simpleMessage("호환성"),
    "skillDescriptionShouldActivate": MessageLookupByLibrary.simpleMessage(
      "이 예시는 스킬을 활성화해야 함",
    ),
    "skillDescriptionTestInput": MessageLookupByLibrary.simpleMessage(
      "사용자 요청 예시",
    ),
    "skillDescriptionTestResult": MessageLookupByLibrary.simpleMessage(
      "활성화 결과",
    ),
    "skillDetails": MessageLookupByLibrary.simpleMessage("스킬 세부 정보"),
    "skillDigest": MessageLookupByLibrary.simpleMessage("콘텐츠 다이제스트"),
    "skillDisabled": MessageLookupByLibrary.simpleMessage("꺼짐"),
    "skillEnabled": MessageLookupByLibrary.simpleMessage("켜짐"),
    "skillFiles": MessageLookupByLibrary.simpleMessage("파일"),
    "skillImportFailed": m36,
    "skillImportSucceeded": MessageLookupByLibrary.simpleMessage("스킬을 가져왔습니다"),
    "skillLibrary": MessageLookupByLibrary.simpleMessage("스킬"),
    "skillLibraryDescription": MessageLookupByLibrary.simpleMessage(
      "재사용 가능한 지침을 설치하고 봇에 연결합니다.",
    ),
    "skillNotExecutable": MessageLookupByLibrary.simpleMessage(
      "이 버전에서는 스킬의 스크립트나 명령을 실행하지 않습니다.",
    ),
    "skillPublisher": MessageLookupByLibrary.simpleMessage("게시자"),
    "skillReferencesAvailable": MessageLookupByLibrary.simpleMessage(
      "참조 파일 사용 가능",
    ),
    "skillSafetyDescription": MessageLookupByLibrary.simpleMessage(
      "SKILL.md는 제어된 프롬프트 지침으로만 불러옵니다. 스크립트, 명령 및 외부 도구는 계속 비활성화됩니다.",
    ),
    "skillSandboxAvailable": MessageLookupByLibrary.simpleMessage(
      "데스크톱 스크립트 샌드박스 사용 가능",
    ),
    "skillSandboxAvailableDescription": MessageLookupByLibrary.simpleMessage(
      "승인하기 전까지 스크립트는 스킬별로 비활성화됩니다. 각 호출에도 계속 승인이 필요합니다.",
    ),
    "skillSandboxUnavailable": MessageLookupByLibrary.simpleMessage(
      "스킬 스크립트 사용 불가",
    ),
    "skillSandboxUnavailableDescription": MessageLookupByLibrary.simpleMessage(
      "이 플랫폼은 필요한 격리 환경을 제공하지 않습니다. 지침과 리소스는 계속 사용할 수 있습니다.",
    ),
    "skillScriptSettingUpdated": MessageLookupByLibrary.simpleMessage(
      "스킬 스크립트 설정이 업데이트되었습니다.",
    ),
    "skillScriptsDisabled": MessageLookupByLibrary.simpleMessage(
      "스크립트가 설치되었지만 실행은 비활성화되어 있습니다.",
    ),
    "skillScriptsEnabled": MessageLookupByLibrary.simpleMessage("스크립트 활성화됨"),
    "skillSignature": MessageLookupByLibrary.simpleMessage("서명"),
    "skillSignatureInvalid": MessageLookupByLibrary.simpleMessage("잘못된 서명"),
    "skillSignatureUnknownPublisher": MessageLookupByLibrary.simpleMessage(
      "알 수 없는 게시자",
    ),
    "skillSignatureUnsigned": MessageLookupByLibrary.simpleMessage("서명되지 않음"),
    "skillSignatureVerified": MessageLookupByLibrary.simpleMessage("서명 확인됨"),
    "skillSource": MessageLookupByLibrary.simpleMessage("원본"),
    "skillStorageLocation": MessageLookupByLibrary.simpleMessage(
      "Installation location",
    ),
    "skillStorageLocationCopied": MessageLookupByLibrary.simpleMessage(
      "Installation location copied to clipboard",
    ),
    "skillUpdateAutomatic": MessageLookupByLibrary.simpleMessage("자동"),
    "skillUpdateAvailable": MessageLookupByLibrary.simpleMessage("업데이트 있음"),
    "skillUpdateManual": MessageLookupByLibrary.simpleMessage("수동"),
    "skillUpdateNotify": MessageLookupByLibrary.simpleMessage("알림"),
    "skillUpdatePinned": MessageLookupByLibrary.simpleMessage("고정"),
    "skillUpdatePolicy": MessageLookupByLibrary.simpleMessage("업데이트 정책"),
    "skillUserScope": MessageLookupByLibrary.simpleMessage("사용자"),
    "skillValidationWarnings": MessageLookupByLibrary.simpleMessage(
      "유효성 검사 참고",
    ),
    "skillVersion": MessageLookupByLibrary.simpleMessage("버전"),
    "speechGenerated": MessageLookupByLibrary.simpleMessage("Speech generated"),
    "speechResult": MessageLookupByLibrary.simpleMessage("Speech result"),
    "startChatPrompt": MessageLookupByLibrary.simpleMessage(
      "채팅을 시작하려면 아래 입력 필드에 메시지를 보내세요",
    ),
    "startChatting": MessageLookupByLibrary.simpleMessage("채팅 시작하기"),
    "startupFailed": MessageLookupByLibrary.simpleMessage(
      "시작하지 못했습니다. 다시 시도해 주세요.",
    ),
    "startupStarting": MessageLookupByLibrary.simpleMessage("시작하는 중…"),
    "statusActivated": MessageLookupByLibrary.simpleMessage("활성화됨"),
    "statusAttached": MessageLookupByLibrary.simpleMessage("첨부됨"),
    "statusAwaitingApproval": MessageLookupByLibrary.simpleMessage("승인 대기 중"),
    "statusCancelled": MessageLookupByLibrary.simpleMessage("취소됨"),
    "statusCompleted": MessageLookupByLibrary.simpleMessage("완료"),
    "statusDenied": MessageLookupByLibrary.simpleMessage("거부됨"),
    "statusDuplicate": MessageLookupByLibrary.simpleMessage("중복 호출"),
    "statusFailed": MessageLookupByLibrary.simpleMessage("실패"),
    "statusGenerated": MessageLookupByLibrary.simpleMessage("생성됨"),
    "statusInProgress": MessageLookupByLibrary.simpleMessage("진행 중"),
    "statusRecorded": MessageLookupByLibrary.simpleMessage("기록됨"),
    "statusRequested": MessageLookupByLibrary.simpleMessage("요청됨"),
    "statusRunning": MessageLookupByLibrary.simpleMessage("실행 중"),
    "statusSkipped": MessageLookupByLibrary.simpleMessage("건너뜀"),
    "statusTimedOut": MessageLookupByLibrary.simpleMessage("시간 초과"),
    "statusUnknown": MessageLookupByLibrary.simpleMessage("알 수 없음"),
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
      "구조화된 프로세스 정보",
    ),
    "submitFeedback": MessageLookupByLibrary.simpleMessage("피드백 제출"),
    "summarizedTurns": MessageLookupByLibrary.simpleMessage("요약된 메시지"),
    "supported": MessageLookupByLibrary.simpleMessage("지원됨"),
    "supportsMcp": MessageLookupByLibrary.simpleMessage("MCP 지원"),
    "supportsSkills": MessageLookupByLibrary.simpleMessage("Skills 지원"),
    "systemPrompt": MessageLookupByLibrary.simpleMessage("시스템 프롬프트"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Camera"),
    "testSkill": MessageLookupByLibrary.simpleMessage("테스트"),
    "testSkillDescription": MessageLookupByLibrary.simpleMessage("설명 테스트"),
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
    "thinkingCompleted": MessageLookupByLibrary.simpleMessage("생각 완료"),
    "thinkingCompletedWithDuration": m37,
    "thinkingInProgress": MessageLookupByLibrary.simpleMessage("생각 중…"),
    "tokenUsage": MessageLookupByLibrary.simpleMessage("토큰 사용량"),
    "tokens": MessageLookupByLibrary.simpleMessage("토큰"),
    "toolApprovalAllowOnce": MessageLookupByLibrary.simpleMessage("한 번 허용"),
    "toolApprovalDenied": MessageLookupByLibrary.simpleMessage("거부됨"),
    "toolCalls": MessageLookupByLibrary.simpleMessage("도구 호출"),
    "toolRiskDestructive": MessageLookupByLibrary.simpleMessage("파괴적"),
    "toolRiskReadOnly": MessageLookupByLibrary.simpleMessage("읽기 전용"),
    "toolRiskWrite": MessageLookupByLibrary.simpleMessage("쓰기"),
    "toolSourceBuiltIn": MessageLookupByLibrary.simpleMessage("내장"),
    "toolSourceMcp": MessageLookupByLibrary.simpleMessage("MCP"),
    "toolSourceSkillScript": MessageLookupByLibrary.simpleMessage("스킬 스크립트"),
    "totalTokens": MessageLookupByLibrary.simpleMessage("총 토큰"),
    "tryDifferentSearch": MessageLookupByLibrary.simpleMessage(
      "다른 조건으로 검색하거나 새 항목을 만드세요.",
    ),
    "typing": MessageLookupByLibrary.simpleMessage("입력 중..."),
    "unableToLoadBots": MessageLookupByLibrary.simpleMessage(
      "Unable to load bots",
    ),
    "unableToLoadChats": MessageLookupByLibrary.simpleMessage(
      "Unable to load chats",
    ),
    "unableToLoadMessages": MessageLookupByLibrary.simpleMessage(
      "Unable to load messages",
    ),
    "unavailableBot": MessageLookupByLibrary.simpleMessage("사용할 수 없는 봇"),
    "uninstall": MessageLookupByLibrary.simpleMessage("제거"),
    "uninstallSkill": MessageLookupByLibrary.simpleMessage("스킬 제거"),
    "unpinMemory": MessageLookupByLibrary.simpleMessage("고정 해제"),
    "unsupportedImageFormat": MessageLookupByLibrary.simpleMessage(
      "지원하지 않는 이미지 형식입니다. JPEG, PNG, GIF, BMP 또는 WebP 이미지를 선택하세요.",
    ),
    "uploadFile": MessageLookupByLibrary.simpleMessage("파일 업로드"),
    "uploadImage": MessageLookupByLibrary.simpleMessage("이미지 업로드"),
    "userAgreement": MessageLookupByLibrary.simpleMessage("사용자 동의"),
    "version": MessageLookupByLibrary.simpleMessage("버전 1.0.0"),
    "videoGenerated": MessageLookupByLibrary.simpleMessage("Video generated"),
    "videoLoadFailed": MessageLookupByLibrary.simpleMessage("동영상을 불러올 수 없습니다"),
    "videoPlaybackError": m38,
    "videoResult": MessageLookupByLibrary.simpleMessage("Video result"),
    "viewSummary": MessageLookupByLibrary.simpleMessage("요약 보기"),
    "waitForGenerationBeforeLeaving": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish before leaving this chat.",
    ),
    "waitForGenerationToFinish": MessageLookupByLibrary.simpleMessage(
      "Wait for generation to finish.",
    ),
    "webSearch": MessageLookupByLibrary.simpleMessage("Web Search"),
  };
}
