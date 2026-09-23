import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:stars/domain/services/stars_system_prompt.dart';

void main() {
  test('describes Stars and safely includes operating system details', () {
    final prompt = buildStarsSystemPrompt(
      operatingSystem: 'test<os>',
      operatingSystemVersion: '1.0 & newer',
    );

    expect(prompt, startsWith('## Application context'));
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
    expect(prompt, contains('## Reliability policy'));
    expect(prompt, contains('An error, empty result,'));
    expect(prompt, isNot(contains('<stars_evidence')));
    expect(prompt, isNot(contains(RegExp(r'</?stars_'))));
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
    expect(prompt, contains('不得编造事实、引用、工具结果或已完成的操作'));
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
      expect(prompt, isNot(contains(RegExp(r'</?stars_'))), reason: entry.key);
      expect(
        md.Document()
            .parseLines(prompt.split('\n'))
            .whereType<md.Element>()
            .map((element) => element.tag),
        ['h2', 'ul', 'p', 'h2', 'p'],
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

    expect(prompt, startsWith('## Application context'));
    expect(
      prompt.indexOf('## Reliability policy'),
      lessThan(prompt.indexOf('Existing assistant instructions.')),
    );
    expect(prompt, endsWith('Existing assistant instructions.'));
  });

  test('safely describes the current agent and conversation identity', () {
    final prompt = buildStarsConversationContext(
      agentId: 'agent<1>',
      agentName: 'Research & Review',
      conversationId: 'chat>2',
      conversationName: '  Research & Review  ',
      artifactsDirectoryPath: '/data/Stars/chats/chat&2',
      currentTime: DateTime.utc(2026, 8, 27, 6, 30, 45),
    );

    expect(prompt, startsWith('## Conversation context'));
    expect(
      prompt,
      contains('Application-provided runtime identity for the current turn.'),
    );
    expect(prompt, contains('Current time: 2026-08-27T06:30:45Z'));
    expect(prompt, contains('Agent ID: agent&lt;1&gt;'));
    expect(prompt, contains('Agent name: Research &amp; Review'));
    expect(prompt, contains('Current conversation ID: chat&gt;2'));
    expect(prompt, contains('Conversation name: Research &amp; Review'));
    expect(
      prompt,
      contains(
        'Conversation artifacts directory: /data/Stars/chats/chat&amp;2',
      ),
    );
    expect(prompt, contains('Use this directory to store and access files'));
    expect(prompt, isNot(contains(RegExp(r'</?stars_'))));
  });

  test('localizes conversation context for every selectable language', () {
    const localizedConversationLabels = <String, String>{
      'en_US': 'Current conversation ID: chat-1',
      'zh_CN': '当前会话 ID：chat-1',
      'zh_TW': '目前對話 ID：chat-1',
      'ja_JP': '現在の会話 ID：chat-1',
      'fr_FR': 'ID de la conversation actuelle : chat-1',
      'de_DE': 'ID der aktuellen Unterhaltung: chat-1',
      'ko_KR': '현재 대화 ID: chat-1',
      'ru_RU': 'ID текущего диалога: chat-1',
      'es_ES': 'ID de la conversación actual: chat-1',
      'hi_IN': 'वर्तमान बातचीत ID: chat-1',
      'pt_BR': 'ID da conversa atual: chat-1',
      'it_IT': 'ID della conversazione corrente: chat-1',
    };
    const localizedNameLabels = <String, String>{
      'en_US': 'Conversation name: Research',
      'zh_CN': '会话名称：Research',
      'zh_TW': '對話名稱：Research',
      'ja_JP': '会話名：Research',
      'fr_FR': 'Nom de la conversation : Research',
      'de_DE': 'Unterhaltungsname: Research',
      'ko_KR': '대화 이름: Research',
      'ru_RU': 'Название диалога: Research',
      'es_ES': 'Nombre de la conversación: Research',
      'hi_IN': 'बातचीत का नाम: Research',
      'pt_BR': 'Nome da conversa: Research',
      'it_IT': 'Nome della conversazione: Research',
    };

    for (final entry in localizedConversationLabels.entries) {
      final prompt = buildStarsConversationContext(
        agentId: '',
        agentName: 'Assistant',
        conversationId: 'chat-1',
        conversationName: 'Research',
        artifactsDirectoryPath: '/data/chat-1',
        currentTime: DateTime.utc(2026),
        languageCode: entry.key,
      );
      expect(prompt, contains(entry.value), reason: entry.key);
      expect(
        prompt,
        contains(localizedNameLabels[entry.key]),
        reason: entry.key,
      );
      expect(prompt, isNot(contains(RegExp(r'</?stars_'))), reason: entry.key);
      expect(
        md.Document()
            .parseLines(prompt.split('\n'))
            .whereType<md.Element>()
            .map((element) => element.tag),
        ['h2', 'p', 'ul', 'p'],
        reason: entry.key,
      );
    }

    final fallback = buildStarsConversationContext(
      agentId: 'agent-1',
      agentName: 'Assistant',
      conversationId: 'chat-1',
      currentTime: DateTime.utc(2026),
      languageCode: 'unsupported',
    );
    expect(fallback, contains(localizedConversationLabels['en_US']));
    expect(fallback, endsWith('- Conversation name: unknown'));
    expect(fallback, isNot(contains('Conversation artifacts directory:')));
  });

  test('runtime values stay literal inside Markdown metadata lists', () {
    const name = r'Research *draft* _v2_ [notes](https://example.com) `code`';
    const path = r'C:\data\team_[draft]\a`b';
    final prompt = buildStarsConversationContext(
      agentId: 'agent<1>',
      agentName: '$name\r\n## Extra heading\n- Extra item',
      conversationId: 'chat&2',
      conversationName: '$name\n## Renamed',
      artifactsDirectoryPath: path,
      currentTime: DateTime.utc(2026),
    );
    final nodes = md.Document(encodeHtml: false).parseLines(prompt.split('\n'));
    expect(nodes.whereType<md.Element>().map((node) => node.tag), [
      'h2',
      'p',
      'ul',
      'p',
    ]);
    final metadata = nodes[2] as md.Element;
    expect(metadata.children, hasLength(6));
    expect(metadata.textContent, contains('Agent ID: agent<1>'));
    expect(
      metadata.textContent,
      contains('$name ## Extra heading - Extra item'),
    );
    expect(metadata.textContent, contains('Current conversation ID: chat&2'));
    expect(
      metadata.textContent,
      contains('Conversation name: $name ## Renamed'),
    );
    expect(metadata.textContent, contains(path));
    final html = md.markdownToHtml(prompt);
    for (final tag in ['<a ', '<img ', '<em>', '<strong>', '<code>']) {
      expect(html, isNot(contains(tag)));
    }
  });
}

String _testStarsSystemPrompt(String languageCode) => buildStarsSystemPrompt(
  operatingSystem: 'TestOS',
  operatingSystemVersion: '1.2.3',
  languageCode: languageCode,
);
