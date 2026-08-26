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
    );

    expect(prompt, startsWith('<stars_conversation_context>'));
    expect(
      prompt,
      contains('Application-provided runtime identity for the current turn.'),
    );
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

String _testStarsSystemPrompt() => buildStarsSystemPrompt(
  operatingSystem: 'TestOS',
  operatingSystemVersion: '1.2.3',
);
