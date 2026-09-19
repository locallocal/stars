import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';

import '../../support/compose_chat_fixtures.dart';

void main() {
  test('continues discovery after each corrected activation error', () async {
    final skills = [
      for (var index = 0; index < 6; index++)
        fixtureSkill(
          'user:skill-$index',
          'skill-$index',
          'Instructions $index',
          requestedToolNames: {'tool-$index'},
        ),
    ];
    final provider = FixtureFakeSkillProvider([
      for (var index = 0; index < skills.length; index++) ...[
        _activate('missing-$index'),
        _activate('skill-$index'),
      ],
      SkillToolTurn(isComplete: true),
    ]);

    final result = await _compose(skills, provider);

    expect(result.activatedSkills.map((skill) => skill.id), [
      for (var index = 0; index < 6; index++) 'user:skill-$index',
    ]);
    expect(result.requestedToolNames, {
      for (var index = 0; index < 6; index++) 'tool-$index',
    });
    expect(
      provider.session.results
          .expand((batch) => batch)
          .where((result) => result.isError),
      hasLength(6),
    );
    expect(provider.session.closed, isTrue);
  });

  for (final valid in [true, false]) {
    test('stops repeated activations without progress: valid=$valid', () async {
      final skill = fixtureSkill('user:file', 'file', 'File instructions.');
      final repository = FixtureFakeSkillRepository({'user:file': skill});
      final provider = FixtureFakeSkillProvider([
        for (var index = 0; index < 10; index++)
          _activate(valid ? 'file' : 'missing', callId: 'call-$index'),
      ]);

      final result = await _compose([skill], provider, repository: repository);

      expect(provider.session.fixtureIndex, valid ? 3 : 2);
      expect(repository.loadedIds, valid ? ['user:file'] : isEmpty);
      expect(result.activatedSkills, hasLength(valid ? 1 : 0));
      expect(
        result.skillToolCalls.where(
          (call) => call.errorCode == 'skill_provider_error',
        ),
        isEmpty,
      );
      expect(provider.session.closed, isTrue);
    });
  }

  test('loads new references beyond fixed turn and call counts', () async {
    final paths = [
      for (var index = 0; index < 10; index++) 'references/guide-$index.md',
    ];
    final skill = fixtureSkill(
      'user:reference',
      'reference',
      'Read relevant references.',
      files: ['SKILL.md', ...paths],
    );
    final repository = FixtureFakeSkillRepository(
      {'user:reference': skill},
      resources: {
        for (var index = 0; index < paths.length; index++)
          'user:reference:${paths[index]}': 'Reference content $index.',
      },
    );
    final provider = FixtureFakeSkillProvider([
      _activate('reference'),
      for (final path in paths) _read(path),
      SkillToolTurn(isComplete: true),
    ]);

    final result = await _compose([skill], provider, repository: repository);

    expect(repository.readResourcePaths, paths);
    for (var index = 0; index < paths.length; index++) {
      expect(
        result.messages.first.content,
        contains('Reference content $index.'),
      );
    }
    expect(result.skillToolCalls, hasLength(11));
    expect(provider.session.closed, isTrue);
  });

  test(
    'cached references do not keep discovery running indefinitely',
    () async {
      const path = 'references/guide.md';
      final skill = fixtureSkill(
        'user:reference',
        'reference',
        'Read relevant references.',
        files: const ['SKILL.md', path],
      );
      final repository = FixtureFakeSkillRepository(
        {'user:reference': skill},
        resources: const {'user:reference:$path': 'Reference content.'},
      );
      final provider = FixtureFakeSkillProvider([
        _activate('reference'),
        for (var index = 0; index < 10; index++) _read(path),
      ]);

      final result = await _compose([skill], provider, repository: repository);

      expect(repository.readResourcePaths, [path]);
      expect(provider.session.fixtureIndex, 4);
      expect(result.messages.first.content, contains('Reference content.'));
      expect(
        result.skillToolCalls.where(
          (call) => call.errorCode == 'skill_provider_error',
        ),
        isEmpty,
      );
      expect(provider.session.closed, isTrue);
    },
  );

  test(
    'retains the context budget while allowing later fitting Skills',
    () async {
      final skills = [
        fixtureSkill('user:first', 'first', '12345678'),
        fixtureSkill('user:large', 'large', '1234567890123456'),
        fixtureSkill('user:last', 'last', 'abcdefgh'),
      ];
      final provider = FixtureFakeSkillProvider([
        _activate('first'),
        _activate('large'),
        _activate('last'),
        SkillToolTurn(isComplete: true),
      ]);

      final result = await _compose(
        skills,
        provider,
        budget: const SkillContextBudget(maxSkillContextTokens: 4),
      );

      expect(result.activatedSkills.map((skill) => skill.id), [
        'user:first',
        'user:last',
      ]);
      expect(result.estimatedSkillContextTokens, 4);
      expect(
        result.activationAttempts
            .singleWhere((attempt) => attempt.skillId == 'user:large')
            .errorCode,
        'skill_context_token_limit',
      );
      expect(provider.session.closed, isTrue);
    },
  );
}

SkillToolTurn _activate(String name, {String callId = 'activate'}) =>
    SkillToolTurn(
      calls: [
        SkillToolCall(
          callId: callId,
          name: 'activate_skill',
          arguments: {'name': name},
        ),
      ],
    );

SkillToolTurn _read(String path) => SkillToolTurn(
  calls: [
    SkillToolCall(
      callId: 'read',
      name: 'read_skill_resource',
      arguments: {'name': 'reference', 'path': path},
    ),
  ],
);

Future<PreparedChatTurn> _compose(
  List<SkillContent> skills,
  FixtureFakeSkillProvider provider, {
  FixtureFakeSkillRepository? repository,
  SkillContextBudget budget = const SkillContextBudget(),
}) => ComposeChatTurn(
  skillRepository:
      repository ??
      FixtureFakeSkillRepository({
        for (final skill in skills) skill.descriptor.id: skill,
      }),
  bindingRepository: FixtureFakeBindingRepository([
    for (final skill in skills) fixtureBinding(skill.descriptor.id),
  ]),
  budget: budget,
  conversationArtifactsDirectoryProvider:
      fixtureTestConversationArtifactsDirectory,
)(
  bot: fixtureBot(),
  history: const [],
  userMessage: fixtureMessage(senderId: 'user-1', content: '继续处理'),
  currentUserId: 'user-1',
  skillToolProvider: provider,
);
