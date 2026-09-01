import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/models/skill_records.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  test('Skill activations survive process info serialization', () {
    const info = MessageProcessInfo(
      reasoningStatus: 'completed',
      skillActivations: [
        MessageSkillActivation(
          name: 'release-notes',
          contentDigest: 'abc123',
          trigger: 'manual',
        ),
      ],
    );

    final restored =
        MessageProcessInfoRecord.fromRaw(
          jsonEncode(MessageProcessInfoRecord.fromDomain(info).values),
        ).toDomain();

    expect(restored.hasData, isTrue);
    expect(restored.reasoningStatus, 'completed');
    expect(restored.skillActivations, hasLength(1));
    expect(restored.skillActivations.single.name, 'release-notes');
    expect(restored.skillActivations.single.contentDigest, 'abc123');
    expect(restored.skillActivations.single.trigger, 'manual');
    expect(restored.skillActivations.single.status, 'recorded');
  });

  test('rejects process info that does not use the current field set', () {
    expect(
      () => MessageProcessInfoRecord.fromRaw(
        jsonEncode(<String, Object?>{
          'reasoning_status': 'completed',
          'duration_ms': 42,
          'tool_calls': <Object?>[],
          'command_executions': <Object?>[],
          'file_edits': <Object?>[],
        }),
      ),
      throwsFormatException,
    );
  });

  test('structured tool invocation survives process info serialization', () {
    const info = MessageProcessInfo(
      toolCalls: [
        MessageToolCall(
          callId: 'call-1',
          name: 'mcp.server-1.save_note',
          title: 'Save note',
          mcpServerName: 'Notes',
          status: 'succeeded',
          source: 'mcp',
          riskLevel: 'write',
          argumentsSummary: '{"title":"Release"}',
          resultSummary: 'saved',
          approvalStatus: 'allowOnce',
          durationMs: 12,
        ),
      ],
    );

    final restored =
        MessageProcessInfoRecord.fromRaw(
          jsonEncode(MessageProcessInfoRecord.fromDomain(info).values),
        ).toDomain();
    final call = restored.toolCalls.single;

    expect(call.callId, 'call-1');
    expect(call.name, 'mcp.server-1.save_note');
    expect(call.title, 'Save note');
    expect(call.mcpServerName, 'Notes');
    expect(call.source, 'mcp');
    expect(call.riskLevel, 'write');
    expect(call.argumentsSummary, '{"title":"Release"}');
    expect(call.resultSummary, 'saved');
    expect(call.approvalStatus, 'allowOnce');
    expect(call.durationMs, 12);
  });

  test('shell command execution survives process info serialization', () {
    const info = MessageProcessInfo(
      commandExecutions: [
        MessageCommandExecution(
          callId: 'shell-1',
          command: 'git status --short && dart analyze',
          status: 'succeeded',
          detail: 'completed',
          durationMs: 240,
        ),
      ],
    );

    final restored =
        MessageProcessInfoRecord.fromRaw(
          jsonEncode(MessageProcessInfoRecord.fromDomain(info).values),
        ).toDomain();
    final execution = restored.commandExecutions.single;

    expect(execution.callId, 'shell-1');
    expect(execution.command, 'git status --short && dart analyze');
    expect(execution.status, 'succeeded');
    expect(execution.detail, 'completed');
    expect(execution.durationMs, 240);
  });

  test('local records preserve core domain model fields', () {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(1770000000123);
    final bot = Bot(
      id: 'bot-1',
      name: 'Assistant',
      avatar: '/avatar.png',
      provider: 'Provider',
      baseURL: 'https://example.test',
      apiKey: 'secret',
      apiType: Bot.apiTypeOpenAI,
      model: 'model-a',
      systemPrompt: 'Be helpful.',
      parameters: const {'temperature': 0.3},
      createTimestamp: timestamp,
      modifyTimestamp: timestamp,
    );
    final chat = Chat(
      id: 'chat-1',
      botId: bot.id,
      lastMessage: 'Hello',
      lastMessageTimestamp: timestamp,
      createTimestamp: timestamp,
      modifyTimestamp: timestamp,
    );
    final profile = Profile(
      name: 'Earthwind',
      avatar: '/profile.png',
      fontSize: 18,
      themeMode: 2,
      language: 'zh_CN',
      showExecutionStatus: false,
      injectApplicationPrompt: false,
      createTimestamp: timestamp,
      modifyTimestamp: timestamp,
    );

    final botRecord = BotRecord.fromDomain(
      bot,
      storedApiKey: 'encrypted-api-key',
    );
    final restoredBot = botRecord.toDomain(apiKey: bot.apiKey);
    final restoredChat = ChatRecord.fromDomain(chat).toDomain();
    final restoredProfile = ProfileRecord.fromDomain(profile).toDomain();

    expect(restoredBot.parameters, {'temperature': 0.3});
    expect(restoredBot.modifyTimestamp, timestamp);
    expect(botRecord.storedApiKey, 'encrypted-api-key');
    expect(restoredChat.lastMessage, 'Hello');
    expect(restoredChat.lastMessageTimestamp, timestamp);
    expect(restoredProfile.fontSize, 18);
    expect(restoredProfile.showExecutionStatus, isFalse);
    expect(restoredProfile.injectApplicationPrompt, isFalse);

    final legacyProfileValues = Map<String, Object?>.from(
      ProfileRecord.fromDomain(profile).values,
    )..remove('inject_application_prompt');
    expect(
      ProfileRecord(legacyProfileValues).toDomain().injectApplicationPrompt,
      isTrue,
    );
  });

  test('rejects corrupt current Bot parameters instead of erasing them', () {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(1);
    final record = BotRecord.fromDomain(
      Bot(
        id: 'bot-strict',
        name: 'Strict',
        avatar: '',
        provider: 'Provider',
        baseURL: '',
        apiKey: '',
        apiType: Bot.apiTypeOpenAI,
        model: 'model',
        systemPrompt: '',
        parameters: const <String, Object?>{},
        createTimestamp: timestamp,
        modifyTimestamp: timestamp,
      ),
      storedApiKey: '',
    );
    final corrupt = BotRecord(<String, Object?>{
      ...record.values,
      'parameters': '{not-json',
    });

    expect(() => corrupt.toDomain(apiKey: ''), throwsFormatException);
  });

  test('rejects corrupt message assets and timestamps', () {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(1);
    final record = MessageRecord.fromDomain(
      Message(
        messageId: 'message-strict',
        turnId: 'turn-strict',
        chatId: 'chat-strict',
        botId: 'bot-strict',
        senderId: 'me',
        content: 'content',
        timestamp: timestamp,
      ),
    );

    expect(
      () =>
          MessageRecord(<String, Object?>{
            ...record.values,
            'images': 'not-json',
          }).toDomain(),
      throwsFormatException,
    );
    expect(
      () =>
          MessageRecord(<String, Object?>{
            ...record.values,
            'timestamp': null,
          }).toDomain(),
      throwsFormatException,
    );
  });

  test('rejects corrupt current Skill JSON instead of using defaults', () {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(1);
    final record = SkillRecord.fromDomain(
      SkillDescriptor(
        id: 'user:strict',
        name: 'strict',
        description: 'Strict Skill',
        version: '1.0.0',
        scope: SkillScope.user,
        sourceUri: 'file:///strict',
        rootPath: '/skills/strict',
        contentDigest: 'digest',
        trustState: SkillTrustState.userReviewed,
        validationStatus: SkillValidationStatus.valid,
        compatibility: 'Stars',
        installedAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    expect(
      () =>
          SkillRecord(<String, Object?>{
            ...record.values,
            'requested_tools_json': '[1]',
          }).toDomain(),
      throwsFormatException,
    );
  });
}
