import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/services/stars_system_prompt.dart';

void main() {
  test('describes Stars and safely includes operating system details', () {
    final prompt = buildStarsSystemPrompt(
      operatingSystem: 'test<os>',
      operatingSystemVersion: '1.0 & newer',
    );

    expect(prompt, startsWith('<stars_application_context>'));
    expect(prompt, contains('Application: Stars'));
    expect(
      prompt,
      contains(
        'Stars is a cross-platform AI chat client for configurable '
        'assistants, Skills, MCP tools, and locally stored conversations.',
      ),
    );
    expect(prompt, contains('Operating system type: test&lt;os&gt;'));
    expect(prompt, contains('Operating system version: 1.0 &amp; newer'));
    expect(prompt, contains('<stars_reliability_policy>'));
    expect(prompt, contains('An error, empty result,'));
    expect(
      prompt,
      contains('<stars_evidence call_ids="call-id-1,call-id-2" />'),
    );
    expect(prompt, endsWith('</stars_reliability_policy>'));
  });

  test('localizes the displayed and injected prompt language', () {
    final prompt = buildStarsSystemPrompt(
      operatingSystem: '',
      operatingSystemVersion: '',
      languageCode: 'zh-CN',
    );

    expect(prompt, contains('应用: Stars'));
    expect(prompt, contains('已选择的界面语言: 简体中文'));
    expect(prompt, contains('面向用户的回答请使用简体中文'));
    expect(prompt, contains('操作系统类型: 未知'));
    expect(prompt, contains('只列出确实支持回答'));
    expect(prompt, isNot(contains('Description:')));
  });

  test('supports every selectable language and falls back to English', () {
    const localizedMarkers = <String, String>{
      'en_US': 'Selected interface language: English',
      'zh_CN': '已选择的界面语言: 简体中文',
      'zh_TW': '已選取的介面語言: 繁體中文',
      'ja_JP': '選択中の表示言語: 日本語',
      'fr_FR': 'Langue d’interface sélectionnée: Français',
      'de_DE': 'Ausgewählte Oberflächensprache: Deutsch',
      'ko_KR': '선택한 인터페이스 언어: 한국어',
      'ru_RU': 'Выбранный язык интерфейса: Русский',
      'es_ES': 'Idioma de interfaz seleccionado: Español',
      'hi_IN': 'चुनी गई इंटरफ़ेस भाषा: हिन्दी',
      'pt_BR': 'Idioma da interface selecionado: Português',
      'it_IT': 'Lingua dell’interfaccia selezionata: Italiano',
    };

    for (final entry in localizedMarkers.entries) {
      final prompt = buildStarsSystemPrompt(
        operatingSystem: 'TestOS',
        operatingSystemVersion: '1',
        languageCode: entry.key,
      );
      expect(prompt, contains(entry.value), reason: entry.key);
      expect(
        '<stars_evidence'.allMatches(prompt),
        hasLength(1),
        reason: entry.key,
      );
    }

    final fallback = buildStarsSystemPrompt(
      operatingSystem: 'TestOS',
      operatingSystemVersion: '1',
      languageCode: 'unsupported',
    );
    expect(fallback, contains(localizedMarkers['en_US']));
  });

  test('places Stars context before the existing system prompt', () {
    final prompt = prependStarsSystemPrompt(
      '  Existing assistant instructions.  ',
      starsSystemPromptProvider: _testStarsSystemPrompt,
    );

    expect(prompt, startsWith('<stars_application_context>'));
    expect(
      prompt.indexOf('</stars_application_context>'),
      lessThan(prompt.indexOf('Existing assistant instructions.')),
    );
    expect(prompt, endsWith('Existing assistant instructions.'));
  });

  test('safely describes the current agent and conversation identity', () {
    final prompt = buildStarsConversationContext(
      agentId: 'agent<1>',
      agentName: 'Research & Review',
      conversationId: 'chat>2',
      artifactsDirectoryPath: '/data/Stars/chats/chat&2',
      currentTime: DateTime.utc(2026, 8, 27, 6, 30, 45),
    );

    expect(prompt, startsWith('<stars_conversation_context>'));
    expect(
      prompt,
      contains('Application-provided runtime identity for the current turn.'),
    );
    expect(prompt, contains('Current time: 2026-08-27T06:30:45Z'));
    expect(prompt, contains('Agent ID: agent&lt;1&gt;'));
    expect(prompt, contains('Agent name: Research &amp; Review'));
    expect(prompt, contains('Current conversation ID: chat&gt;2'));
    expect(
      prompt,
      contains(
        'Conversation artifacts directory: /data/Stars/chats/chat&amp;2',
      ),
    );
    expect(prompt, contains('Use this directory to store and access files'));
    expect(prompt, endsWith('</stars_conversation_context>'));
  });
}

String _testStarsSystemPrompt(String languageCode) => buildStarsSystemPrompt(
  operatingSystem: 'TestOS',
  operatingSystemVersion: '1.2.3',
  languageCode: languageCode,
);
