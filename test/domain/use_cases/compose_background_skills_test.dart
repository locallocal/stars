import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';

import '../../support/compose_chat_fixtures.dart';

void main() {
  final fileSkill = fixtureSkill(
    'user:files',
    'file-operations',
    'Use structured file tools to write and verify files.',
    requestedToolNames: {'read_local_file', 'write_local_file'},
  );

  Future<PreparedChatTurn> compose(
    AiProvider provider, {
    String objective = '保存第八章到 chapter8.md，并读取确认内容',
  }) => ComposeChatTurn(
    skillRepository: FixtureFakeSkillRepository({'user:files': fileSkill}),
    bindingRepository: FixtureFakeBindingRepository([
      fixtureBinding('user:files'),
    ]),
    conversationArtifactsDirectoryProvider:
        fixtureTestConversationArtifactsDirectory,
  )(
    bot: fixtureBot(),
    history: [
      fixtureMessage(
        messageId: 'old-user',
        senderId: 'user-1',
        content: '编写第八章',
      ),
      fixtureMessage(
        messageId: 'old-assistant',
        senderId: 'assistant',
        content: '历史错误：没有写入工具。第八章正文需要保留',
        terminalOutcome: MessageTerminalOutcome.completed,
      ),
    ],
    userMessage: fixtureMessage(
      messageId: 'current-user',
      senderId: 'user-1',
      content: objective,
    ),
    currentUserId: 'user-1',
    skillToolProvider: provider,
    backgroundTaskObjective: objective,
  );

  test('selects file writes afresh without old capability claims', () async {
    final provider = FixtureFakeSkillProvider([
      _activate(),
      _finish(['file-operations']),
    ]);
    final prepared = await compose(provider);

    expect(prepared.requestedToolNames, {
      'read_local_file',
      'write_local_file',
    });
    expect(prepared.activatedSkills.single.name, 'file-operations');
    final request = provider.session.request!;
    expect(request.requireExplicitCompletion, isTrue);
    expect(request.messages.map((m) => m.role), ['system', 'user', 'user']);
    final prompt = request.messages.map((m) => m.content).join('\n');
    expect(prompt, contains('chapter8.md'));
    expect(prompt, contains('finish_skill_selection'));
    expect(prompt, isNot(contains('历史错误')));
    expect(prompt, isNot(contains('第八章正文需要保留')));
    expect(
      prepared.messages.map((m) => m.content).join('\n'),
      contains('第八章正文需要保留'),
    );
    expect(provider.session.closed, isTrue);
  });

  for (final entry
      in <String, List<SkillToolTurn>>{
        'plain acknowledgement': [SkillToolTurn(isComplete: true)],
        'unfinished activation': [_activate(), SkillToolTurn(isComplete: true)],
        'unactivated selection': [
          _finish(['file-operations']),
        ],
        'duplicate selection': [
          _activate(),
          _finish(['file-operations', 'file-operations']),
        ],
        'missing selected Skill': [_activate(), _finish([])],
        'failed activation': [_activate('unknown'), _finish([])],
        'repeated invalid calls': [_activate('unknown'), _activate('unknown')],
        'malformed completion': [
          SkillToolTurn(
            calls: [
              SkillToolCall(
                callId: 'finish',
                name: finishSkillSelectionToolName,
                arguments: {'selectedSkills': [], 'reason': ''},
              ),
            ],
          ),
        ],
      }.entries) {
    test('does not accept ${entry.key} as completed discovery', () async {
      final provider = FixtureFakeSkillProvider(entry.value);
      await expectLater(
        compose(provider),
        throwsA(isA<SkillSelectionIncompleteException>()),
      );
      expect(provider.session.closed, isTrue);
    });
  }

  test('permits an explicit decision that no Skill is relevant', () async {
    final provider = FixtureFakeSkillProvider([_finish([])]);
    final prepared = await compose(provider, objective: '使用已连接的 MCP 查询天气');
    expect(prepared.activatedSkills, isEmpty);
    expect(prepared.requestedToolNames, isEmpty);
  });

  test(
    'activation errors propagate instead of producing a read-only scope',
    () async {
      for (final error in [
        TimeoutException('provider timeout'),
        StateError('provider error'),
      ]) {
        await expectLater(
          compose(FixtureFailingSkillProvider(error)),
          throwsA(same(error)),
        );
      }
    },
  );
}

SkillToolTurn _activate([String name = 'file-operations']) => SkillToolTurn(
  calls: [
    SkillToolCall(
      callId: 'activate',
      name: 'activate_skill',
      arguments: {'name': name},
    ),
  ],
);

SkillToolTurn _finish(List<String> names) => SkillToolTurn(
  calls: [
    SkillToolCall(
      callId: 'finish',
      name: finishSkillSelectionToolName,
      arguments: {
        'selectedSkills': names,
        'reason':
            names.isEmpty
                ? 'No relevant Skill.'
                : 'File write and verification.',
      },
    ),
  ],
);
