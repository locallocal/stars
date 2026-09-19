import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';

import '../../support/compose_chat_fixtures.dart';

void main() {
  test(
    'does not prefilter a large Skill catalog before model selection',
    () async {
      final skills = <String, SkillContent>{
        for (var index = 0; index < 20; index++)
          'user:filler-$index': fixtureSkill(
            'user:filler-$index',
            'filler-$index',
            'Unrelated instructions $index.',
          ),
        'user:file': fixtureSkill(
          'user:file',
          'file-operations',
          'Save research results to a local file.',
        ),
      };
      final provider = FixtureFakeSkillProvider(
        fixtureActivationTurns(['file-operations']),
      );
      final compose = ComposeChatTurn(
        skillRepository: FixtureFakeSkillRepository(skills),
        bindingRepository: FixtureFakeBindingRepository([
          for (var index = 0; index < 20; index++)
            fixtureBinding('user:filler-$index', priority: 100 - index),
          fixtureBinding('user:file'),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        starsSystemPromptProvider: fixtureTestStarsSystemPrompt,
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(senderId: 'user-1', content: '再调研一次'),
        currentUserId: 'user-1',
        skillToolProvider: provider,
      );

      expect(provider.session.request?.catalog, hasLength(21));
      expect(
        provider.session.request?.catalog.map((entry) => entry.id),
        contains('user:file'),
      );
      expect(result.activatedSkills.map((skill) => skill.id), ['user:file']);
    },
  );

  test('offers every enabled Skill for automatic model activation', () async {
    final skills = <String, SkillContent>{
      'user:always': fixtureSkill(
        'user:always',
        'always',
        'Always instructions.',
      ),
      'user:selected': fixtureSkill(
        'user:selected',
        'selected',
        'Selected instructions.',
        requestedToolNames: const {'calculate'},
      ),
      'user:ignored': fixtureSkill(
        'user:ignored',
        'ignored',
        'Ignored secret.',
      ),
    };
    final skillRepository = FixtureFakeSkillRepository(skills);
    final bindingRepository = FixtureFakeBindingRepository([
      fixtureBinding('user:always', priority: 10),
      fixtureBinding('user:selected', priority: 5),
      fixtureBinding('user:ignored'),
    ]);
    final provider = FixtureFakeSkillProvider([
      SkillToolTurn(
        calls: [
          SkillToolCall(
            callId: 'activate-selected',
            name: 'activate_skill',
            arguments: const {'name': 'selected'},
          ),
        ],
      ),
      SkillToolTurn(isComplete: true),
    ]);
    final requestedArtifactsDirectories = <String>[];
    final compose = ComposeChatTurn(
      skillRepository: skillRepository,
      bindingRepository: bindingRepository,
      conversationArtifactsDirectoryProvider: (conversationId) async {
        requestedArtifactsDirectories.add(conversationId);
        return '/data/Stars/chats/$conversationId';
      },
      starsSystemPromptProvider: fixtureTestStarsSystemPrompt,
    );

    final result = await compose(
      bot: fixtureBot(systemPrompt: 'You are a helpful assistant.'),
      history: [
        fixtureMessage(senderId: 'user-1', content: 'Earlier question'),
        fixtureMessage(
          senderId: 'bot-1',
          content: 'Earlier answer',
          reasoning: 'Earlier reasoning',
        ),
      ],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Current question',
      ),
      currentUserId: 'user-1',
      skillToolProvider: provider,
    );

    expect(skillRepository.loadedIds, ['user:selected']);
    expect(result.messages.map((message) => message.role), [
      'system',
      'user',
      'assistant',
      'user',
    ]);
    final systemPrompt = result.messages.first.content;
    expect(systemPrompt, startsWith('<stars_application_context>'));
    expect(systemPrompt, contains('Operating system type: TestOS'));
    expect(systemPrompt, contains('Operating system version: 1.2.3'));
    expect(systemPrompt, contains('<stars_conversation_context>'));
    expect(systemPrompt, contains('Current time:'));
    expect(systemPrompt, contains('Agent ID: bot-1'));
    expect(systemPrompt, contains('Agent name: Assistant'));
    expect(systemPrompt, contains('Current conversation ID: chat-1'));
    expect(
      systemPrompt,
      contains('Conversation artifacts directory: /data/Stars/chats/chat-1'),
    );
    expect(
      systemPrompt,
      contains('Use this directory to store and access files'),
    );
    expect(requestedArtifactsDirectories, ['chat-1']);
    expect(
      '<stars_conversation_context>'.allMatches(systemPrompt),
      hasLength(1),
    );
    expect(
      systemPrompt.indexOf('</stars_conversation_context>'),
      lessThan(systemPrompt.indexOf('You are a helpful assistant.')),
    );
    expect(systemPrompt, contains('You are a helpful assistant.'));
    expect(systemPrompt, contains('Selected instructions.'));
    expect(systemPrompt, isNot(contains('Always instructions.')));
    expect(systemPrompt, isNot(contains('Ignored secret.')));
    expect(
      systemPrompt,
      contains('A Skill is available only after model activation'),
    );
    expect(systemPrompt, contains('policy checks'));
    expect(result.activatedSkills.map((skill) => skill.id), ['user:selected']);
    expect(result.activatedSkills.single.trigger, SkillActivationTrigger.model);
    expect(provider.session.request?.catalog.map((skill) => skill.id), [
      'user:always',
      'user:selected',
      'user:ignored',
    ]);
    expect(
      provider.session.request?.messages.first.content,
      startsWith('<stars_application_context>'),
    );
    expect(
      provider.session.request?.messages.first.content,
      contains('Current conversation ID: chat-1'),
    );
    expect(
      provider.session.request?.messages.first.content,
      contains('Conversation artifacts directory: /data/Stars/chats/chat-1'),
    );
    expect(result.requestedToolNames, {'calculate'});
    expect(
      result.messages
          .singleWhere((message) => message.role == 'assistant')
          .reasoning,
      'Earlier reasoning',
    );
  });

  test(
    'omits the application prompt but localizes conversation context',
    () async {
      var preferenceReads = 0;
      var languageReads = 0;
      final compose = ComposeChatTurn(
        skillRepository: FixtureFakeSkillRepository(const {}),
        bindingRepository: FixtureFakeBindingRepository(const []),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        starsSystemPromptProvider: fixtureTestStarsSystemPrompt,
        starsSystemPromptEnabledProvider: () async {
          preferenceReads += 1;
          return false;
        },
        starsSystemPromptLanguageProvider: () async {
          languageReads += 1;
          return 'zh_CN';
        },
      );

      final result = await compose(
        bot: fixtureBot(systemPrompt: 'Bot-owned instructions.'),
        history: const [],
        userMessage: fixtureMessage(senderId: 'user-1', content: 'Hello'),
        currentUserId: 'user-1',
      );

      final systemPrompt = result.messages.first.content;
      expect(systemPrompt, isNot(contains('<stars_application_context>')));
      expect(systemPrompt, isNot(contains('<stars_reliability_policy>')));
      expect(systemPrompt, contains('<stars_conversation_context>'));
      expect(systemPrompt, contains('当前会话 ID：chat-1'));
      expect(systemPrompt, isNot(contains('Current conversation ID:')));
      expect(systemPrompt, contains('Bot-owned instructions.'));
      expect(result.reliabilityPolicyEnabled, isFalse);
      expect(preferenceReads, 1);
      expect(languageReads, 1);
    },
  );

  test('injects the Stars prompt using the selected language', () async {
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository(const {}),
      bindingRepository: FixtureFakeBindingRepository(const []),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
      starsSystemPromptProvider: fixtureTestStarsSystemPrompt,
      starsSystemPromptLanguageProvider: () async => 'zh_CN',
    );

    final result = await compose(
      bot: fixtureBot(),
      history: const [],
      userMessage: fixtureMessage(senderId: 'user-1', content: 'Hello'),
      currentUserId: 'user-1',
    );

    final systemPrompt = result.messages.first.content;
    expect(systemPrompt, contains('应用: Stars'));
    expect(systemPrompt, contains('已选择的界面语言: 简体中文'));
    expect(systemPrompt, contains('操作系统类型: TestOS'));
    expect(systemPrompt, contains('当前会话 ID：chat-1'));
    expect(systemPrompt, contains('会话产物目录：/data/Stars/chats/chat-1'));
    expect(systemPrompt, isNot(contains('Description:')));
    expect(systemPrompt, isNot(contains('Current conversation ID:')));
  });

  test(
    'auto activation uses structured tools and injects requested references',
    () async {
      final auto = fixtureSkill(
        'user:release-notes',
        'release-notes',
        'Prepare concise release notes.',
        files: const ['SKILL.md', 'references/style.md'],
      );
      final repository = FixtureFakeSkillRepository(
        {'user:release-notes': auto},
        resources: {
          'user:release-notes:references/style.md': 'Use short headings.',
        },
      );
      final provider = FixtureFakeSkillProvider([
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'activate-1',
              name: 'activate_skill',
              arguments: const {'name': 'release-notes'},
            ),
          ],
          tokenUsage: const ModelTokenUsage(
            model: 'test-model',
            inputTokens: 20,
            outputTokens: 2,
            totalTokens: 22,
          ),
        ),
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'read-1',
              name: 'read_skill_resource',
              arguments: const {
                'name': 'release-notes',
                'path': 'references/style.md',
              },
            ),
          ],
          tokenUsage: const ModelTokenUsage(
            model: 'test-model',
            inputTokens: 25,
            outputTokens: 3,
            totalTokens: 28,
          ),
        ),
        SkillToolTurn(isComplete: true),
      ]);
      final compose = ComposeChatTurn(
        skillRepository: repository,
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding('user:release-notes'),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(
          senderId: 'user-1',
          content: 'Draft release notes for this version.',
        ),
        currentUserId: 'user-1',
        skillToolProvider: provider,
      );

      expect(result.activatedSkills, hasLength(1));
      expect(
        result.activatedSkills.single.trigger,
        SkillActivationTrigger.model,
      );
      expect(result.messages.first.content, contains(auto.instructions));
      expect(result.messages.first.content, contains('Use short headings.'));
      expect(
        result.messages.first.content,
        isNot(contains('<available_skills>')),
      );
      expect(repository.readResourcePaths, ['references/style.md']);
      expect(
        provider.session.results.first.single.content,
        contains('<available_references count="1">'),
      );
      expect(
        provider.session.results.first.single.content,
        contains('- references/style.md'),
      );
      expect(result.skillToolCalls.map((call) => call.name), [
        'activate_skill',
        'read_skill_resource',
      ]);
      expect(
        result.activationAttempts.single.status,
        SkillActivationStatus.activated,
      );
      expect(result.preflightTokenUsage.inputTokens, 45);
      expect(result.preflightTokenUsage.outputTokens, 5);
      expect(provider.session.results, hasLength(2));
      expect(provider.session.closed, isTrue);
    },
  );

  test(
    'reference-free bundled Skill rejects resource reads with an explicit manifest',
    () async {
      final skill = fixtureSystemLocalFileSystemSkill(directory: false);
      final repository = FixtureFakeSkillRepository(const {});
      final provider = FixtureFakeSkillProvider([
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'activate-1',
              name: 'activate_skill',
              arguments: const {'name': 'file-operations'},
            ),
          ],
        ),
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'read-1',
              name: 'read_skill_resource',
              arguments: const {
                'name': 'file-operations',
                'path': 'references/tools.md',
              },
            ),
          ],
        ),
        SkillToolTurn(isComplete: true),
      ]);
      final compose = ComposeChatTurn(
        skillRepository: repository,
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding(fileOperationsSkillId),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        bundledSkillLoader: () async => [skill],
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(
          senderId: 'user-1',
          content: 'Save this HTML file locally',
        ),
        currentUserId: 'user-1',
        skillToolProvider: provider,
      );

      final activationResult = provider.session.results.first.single;
      expect(
        activationResult.content,
        contains('<available_references count="0">'),
      );
      expect(
        activationResult.content,
        contains('do not call read_skill_resource'),
      );
      expect(repository.readResourcePaths, isEmpty);
      expect(result.skillToolCalls.last.status, 'failed');
      expect(result.skillToolCalls.last.errorCode, 'skill_has_no_references');
      expect(
        provider.session.results.last.single.errorCode,
        'skill_has_no_references',
      );
    },
  );

  test(
    'bundled Skill reads an advertised reference from application assets',
    () async {
      final skill = fixtureSystemSkillWithReference();
      final repository = FixtureFakeSkillRepository(const {});
      final provider = FixtureFakeSkillProvider([
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'activate-1',
              name: 'activate_skill',
              arguments: const {'name': 'bundled-reference'},
            ),
          ],
        ),
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'read-1',
              name: 'read_skill_resource',
              arguments: const {
                'name': 'bundled-reference',
                'path': 'references/guide.md',
              },
            ),
          ],
        ),
        SkillToolTurn(isComplete: true),
      ]);
      final compose = ComposeChatTurn(
        skillRepository: repository,
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding(skill.descriptor.id),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        bundledSkillLoader: () async => [skill],
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(
          senderId: 'user-1',
          content: 'Use the bundled guide',
        ),
        currentUserId: 'user-1',
        skillToolProvider: provider,
      );

      expect(repository.readResourcePaths, isEmpty);
      expect(result.skillToolCalls.last.status, 'completed');
      expect(result.messages.first.content, contains('Bundled guide content.'));
      expect(
        provider.session.results.first.single.content,
        contains('- references/guide.md'),
      );
    },
  );

  test('rejects a resource path that was not advertised', () async {
    final skill = fixtureSkill(
      'user:reference-reader',
      'reference-reader',
      'Read an advertised reference.',
      files: const ['SKILL.md', 'references/guide.md'],
    );
    final repository = FixtureFakeSkillRepository({skill.descriptor.id: skill});
    final provider = FixtureFakeSkillProvider([
      SkillToolTurn(
        calls: [
          SkillToolCall(
            callId: 'activate-1',
            name: 'activate_skill',
            arguments: const {'name': 'reference-reader'},
          ),
        ],
      ),
      SkillToolTurn(
        calls: [
          SkillToolCall(
            callId: 'read-1',
            name: 'read_skill_resource',
            arguments: const {
              'name': 'reference-reader',
              'path': 'references/tools.md',
            },
          ),
        ],
      ),
      SkillToolTurn(isComplete: true),
    ]);
    final compose = ComposeChatTurn(
      skillRepository: repository,
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding(skill.descriptor.id),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
    );

    final result = await compose(
      bot: fixtureBot(),
      history: const [],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Read the guide',
      ),
      currentUserId: 'user-1',
      skillToolProvider: provider,
    );

    expect(repository.readResourcePaths, isEmpty);
    expect(
      result.skillToolCalls.last.errorCode,
      'skill_reference_not_advertised',
    );
    expect(
      provider.session.results.last.single.content,
      contains('skill_reference_not_advertised'),
    );
  });

  test('preserves a specific repository resource error code', () async {
    final skill = fixtureSkill(
      'user:reference-reader',
      'reference-reader',
      'Read an advertised reference.',
      files: const ['SKILL.md', 'references/guide.md'],
    );
    final repository = FixtureFakeSkillRepository(
      {skill.descriptor.id: skill},
      resourceReadError: const SkillInstallException(
        'Reference not found.',
        code: 'skill_reference_not_found',
      ),
    );
    final provider = FixtureFakeSkillProvider([
      SkillToolTurn(
        calls: [
          SkillToolCall(
            callId: 'activate-1',
            name: 'activate_skill',
            arguments: const {'name': 'reference-reader'},
          ),
        ],
      ),
      SkillToolTurn(
        calls: [
          SkillToolCall(
            callId: 'read-1',
            name: 'read_skill_resource',
            arguments: const {
              'name': 'reference-reader',
              'path': 'references/guide.md',
            },
          ),
        ],
      ),
      SkillToolTurn(isComplete: true),
    ]);
    final compose = ComposeChatTurn(
      skillRepository: repository,
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding(skill.descriptor.id),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
    );

    final result = await compose(
      bot: fixtureBot(),
      history: const [],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Read the guide',
      ),
      currentUserId: 'user-1',
      skillToolProvider: provider,
    );

    expect(repository.readResourcePaths, ['references/guide.md']);
    expect(result.skillToolCalls.last.errorCode, 'skill_reference_not_found');
    expect(
      provider.session.results.last.single.errorCode,
      'skill_reference_not_found',
    );
  });

  test('legacy provider does not receive or activate auto Skills', () async {
    final auto = fixtureSkill(
      'user:auto',
      'auto',
      'Auto instructions must remain undisclosed.',
    );
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository({'user:auto': auto}),
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding('user:auto'),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
    );

    final result = await compose(
      bot: fixtureBot(),
      history: const [],
      userMessage: fixtureMessage(senderId: 'user-1', content: 'Use auto'),
      currentUserId: 'user-1',
      skillToolProvider: FixtureLegacySkillProvider(),
    );

    expect(result.activatedSkills, isEmpty);
    expect(result.messages.map((message) => message.role), ['system', 'user']);
    expect(
      result.messages.first.content,
      startsWith('<stars_application_context>'),
    );
    expect(result.messages.last.content, 'Use auto');
  });

  test(
    'model-selected shell system Skill exposes its tool to Agent providers',
    () async {
      final shellSkill = fixtureSystemShellSkill();
      final compose = ComposeChatTurn(
        skillRepository: FixtureFakeSkillRepository(const {}),
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding(shellCommandSkillId),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        bundledSkillLoader: () async => [shellSkill],
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(
          senderId: 'user-1',
          content: 'Run flutter test for this project',
        ),
        currentUserId: 'user-1',
        skillToolProvider: FixtureFakeSkillProvider(
          fixtureActivationTurns(const ['shell-command']),
        ),
      );

      expect(result.requestedToolNames, shellCommandToolNames);
      expect(result.approvalExemptToolNames, isEmpty);
      expect(result.activatedSkills.single.id, shellCommandSkillId);
      expect(result.messages.first.role, 'system');
      expect(result.messages.first.content, contains('model activation'));
      expect(result.messages.first.content, contains(shellSkill.instructions));
    },
  );

  test(
    'active Skill configured for no confirmation exempts its requested tools',
    () async {
      final shellSkill = fixtureSystemShellSkill();
      final compose = ComposeChatTurn(
        skillRepository: FixtureFakeSkillRepository(const {}),
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding(shellCommandSkillId, requiresApproval: false),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        bundledSkillLoader: () async => [shellSkill],
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(
          senderId: 'user-1',
          content: 'Run flutter test for this project',
        ),
        currentUserId: 'user-1',
        skillToolProvider: FixtureFakeSkillProvider(
          fixtureActivationTurns(const ['shell-command']),
        ),
      );

      expect(result.requestedToolNames, shellCommandToolNames);
      expect(result.approvalExemptToolNames, shellCommandToolNames);
    },
  );

  test(
    'does not expose a bound system Skill without model activation',
    () async {
      final fileSkill = fixtureSystemLocalFileSystemSkill(directory: false);
      final provider = FixtureFakeSkillProvider([
        SkillToolTurn(isComplete: true),
      ]);
      final compose = ComposeChatTurn(
        skillRepository: FixtureFakeSkillRepository(const {}),
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding(fileOperationsSkillId),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        bundledSkillLoader: () async => [fileSkill],
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(
          senderId: 'user-1',
          content: 'Save this HTML file locally',
        ),
        currentUserId: 'user-1',
        skillToolProvider: provider,
      );

      expect(provider.session.request?.catalog.map((skill) => skill.id), [
        fileOperationsSkillId,
      ]);
      expect(result.activatedSkills, isEmpty);
      expect(result.requestedToolNames, isEmpty);
      expect(
        result.messages.first.content,
        isNot(contains(fileSkill.instructions)),
      );
    },
  );

  for (final enabled in [true, false]) {
    for (final requiresApproval in [true, false]) {
      test(
        'unselected file Skill keeps configured grants: enabled=$enabled, approval=$requiresApproval',
        () async {
          final skill = fixtureSystemLocalFileSystemSkill(directory: false);
          final compose = ComposeChatTurn(
            skillRepository: FixtureFakeSkillRepository(const {}),
            bindingRepository: FixtureFakeBindingRepository([
              fixtureBinding(
                fileOperationsSkillId,
                enabled: enabled,
                requiresApproval: requiresApproval,
              ),
            ]),
            conversationArtifactsDirectoryProvider:
                fixtureTestConversationArtifactsDirectory,
            bundledSkillLoader: () async => [skill],
          );
          final result = await compose(
            bot: fixtureBot(),
            history: const [],
            userMessage: fixtureMessage(
              senderId: 'user-1',
              content: 'Read the report',
            ),
            currentUserId: 'user-1',
            skillToolProvider: FixtureFakeSkillProvider([
              SkillToolTurn(isComplete: true),
            ]),
          );
          expect(result.activatedSkills, isEmpty);
          expect(result.requestedToolNames, isEmpty);
          expect(
            result.approvalExemptToolNames,
            enabled && !requiresApproval ? fileOperationsToolNames : isEmpty,
          );
        },
      );
    }
  }

  test(
    'unbound Skills leave the Skill tool channel empty for verification discovery',
    () async {
      final shellSkill = fixtureSystemShellSkill();
      for (final bindings in <List<BotSkillBinding>>[
        const [],
        [fixtureBinding(shellCommandSkillId, enabled: false)],
      ]) {
        final compose = ComposeChatTurn(
          skillRepository: FixtureFakeSkillRepository(const {}),
          bindingRepository: FixtureFakeBindingRepository(bindings),
          conversationArtifactsDirectoryProvider:
              fixtureTestConversationArtifactsDirectory,
          bundledSkillLoader: () async => [shellSkill],
        );

        final result = await compose(
          bot: fixtureBot(),
          history: const [],
          userMessage: fixtureMessage(
            senderId: 'user-1',
            content: 'List local files',
          ),
          currentUserId: 'user-1',
          skillToolProvider: FixtureFakeSkillProvider(const []),
        );

        expect(result.requestedToolNames, isEmpty);
        expect(result.approvalExemptToolNames, isEmpty);
        expect(result.activatedSkills, isEmpty);
        expect(result.messages.map((message) => message.role), [
          'system',
          'user',
        ]);
        expect(
          result.messages.first.content,
          startsWith('<stars_application_context>'),
        );
      }
    },
  );

  test('model-selected local file system Skills expose native tools', () async {
    final directorySkill = fixtureSystemLocalFileSystemSkill(directory: true);
    final fileSkill = fixtureSystemLocalFileSystemSkill(directory: false);
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository(const {}),
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding(directoryOperationsSkillId),
        fixtureBinding(fileOperationsSkillId),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
      bundledSkillLoader: () async => [directorySkill, fileSkill],
    );

    final result = await compose(
      bot: fixtureBot(),
      history: const [],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Read a file and list its parent directory',
      ),
      currentUserId: 'user-1',
      skillToolProvider: FixtureFakeSkillProvider(
        fixtureActivationTurns(const [
          'directory-operations',
          'file-operations',
        ]),
      ),
    );

    expect(result.requestedToolNames, {
      ...directoryOperationsToolNames,
      ...fileOperationsToolNames,
    });
    expect(result.approvalExemptToolNames, isEmpty);
    expect(result.activatedSkills.map((skill) => skill.id), {
      directoryOperationsSkillId,
      fileOperationsSkillId,
    });
    expect(
      result.messages.first.content,
      contains(directorySkill.instructions),
    );
    expect(result.messages.first.content, contains(fileSkill.instructions));
  });

  test(
    'model decides which enabled system Skills enter the final context',
    () async {
      final shellSkill = fixtureSystemShellSkill();
      final directorySkill = fixtureSystemLocalFileSystemSkill(directory: true);
      final fileSkill = fixtureSystemLocalFileSystemSkill(directory: false);
      final installerSkill = fixtureSystemSkillInstallerSkill();
      final mcpInstallerSkill = fixtureSystemMcpInstallerSkill();
      final historySkill = fixtureSystemConversationHistorySkill();
      final provider = FixtureFakeSkillProvider(
        fixtureActivationTurns(const ['file-operations']),
      );
      final compose = ComposeChatTurn(
        skillRepository: FixtureFakeSkillRepository(const {}),
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding(shellCommandSkillId),
          fixtureBinding(directoryOperationsSkillId),
          fixtureBinding(fileOperationsSkillId),
          fixtureBinding(skillInstallerSkillId),
          fixtureBinding(mcpInstallerSkillId),
          fixtureBinding(conversationHistorySkillId),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        bundledSkillLoader:
            () async => [
              shellSkill,
              directorySkill,
              fileSkill,
              installerSkill,
              mcpInstallerSkill,
              historySkill,
            ],
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(
          senderId: 'user-1',
          content: 'Save this HTML file locally',
        ),
        currentUserId: 'user-1',
        skillToolProvider: provider,
      );

      expect(result.requestedToolNames, fileOperationsToolNames);
      expect(result.activatedSkills.single.id, fileOperationsSkillId);
      expect(
        provider.session.request?.catalog.map((skill) => skill.id),
        unorderedEquals([
          shellCommandSkillId,
          directoryOperationsSkillId,
          fileOperationsSkillId,
          skillInstallerSkillId,
          mcpInstallerSkillId,
          conversationHistorySkillId,
        ]),
      );
      expect(result.messages.first.content, contains(fileSkill.instructions));
      expect(
        result.messages.first.content,
        isNot(contains(shellSkill.instructions)),
      );
      expect(
        result.messages.first.content,
        isNot(contains(directorySkill.instructions)),
      );
      expect(
        result.messages.first.content,
        isNot(contains(installerSkill.instructions)),
      );
      expect(
        result.messages.first.content,
        isNot(contains(mcpInstallerSkill.instructions)),
      );
      expect(
        result.messages.first.content,
        isNot(contains(historySkill.instructions)),
      );
    },
  );

  test('model can select a system Skill for an elliptical follow-up', () async {
    final fileSkill = fixtureSystemLocalFileSystemSkill(directory: false);
    final provider = FixtureFakeSkillProvider(
      fixtureActivationTurns(const ['file-operations']),
    );
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository(const {}),
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding(fileOperationsSkillId),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
      bundledSkillLoader: () async => [fileSkill],
    );

    final result = await compose(
      bot: fixtureBot(),
      history: [
        fixtureMessage(
          senderId: 'user-1',
          content: '详细调研 Transformer 架构，将结果写入本地',
        ),
        fixtureMessage(senderId: 'bot-1', content: '报告已写入本地。'),
      ],
      userMessage: fixtureMessage(senderId: 'user-1', content: '再调研一次'),
      currentUserId: 'user-1',
      skillToolProvider: provider,
    );

    expect(provider.session.request?.catalog.map((skill) => skill.id), [
      fileOperationsSkillId,
    ]);
    expect(
      provider.session.request?.messages.map((message) => message.content),
      contains('详细调研 Transformer 架构，将结果写入本地'),
    );
    expect(result.activatedSkills.single.id, fileOperationsSkillId);
    expect(result.requestedToolNames, fileOperationsToolNames);
  });

  test(
    'bound Skill installer exposes install and SQLite inventory tools',
    () async {
      final installerSkill = fixtureSystemSkillInstallerSkill();
      final compose = ComposeChatTurn(
        skillRepository: FixtureFakeSkillRepository(const {}),
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding(skillInstallerSkillId),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        bundledSkillLoader: () async => [installerSkill],
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(
          senderId: 'user-1',
          content: 'Install this Skill from GitHub',
        ),
        currentUserId: 'user-1',
        skillToolProvider: FixtureFakeSkillProvider(
          fixtureActivationTurns(const ['skill-installer']),
        ),
      );

      expect(result.requestedToolNames, skillInstallerToolNames);
      expect(result.approvalExemptToolNames, skillInventoryToolNames);
      expect(result.activatedSkills.single.id, skillInstallerSkillId);
      expect(
        result.messages.first.content,
        contains(installerSkill.instructions),
      );
    },
  );

  test('bound MCP installer Skill exposes write and inventory tools', () async {
    final mcpInstallerSkill = fixtureSystemMcpInstallerSkill();
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository(const {}),
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding(mcpInstallerSkillId),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
      bundledSkillLoader: () async => [mcpInstallerSkill],
    );

    final result = await compose(
      bot: fixtureBot(),
      history: const [],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Add this Streamable HTTP MCP server',
      ),
      currentUserId: 'user-1',
      skillToolProvider: FixtureFakeSkillProvider(
        fixtureActivationTurns(const ['mcp-installer']),
      ),
    );

    expect(result.requestedToolNames, mcpInstallerToolNames);
    expect(result.approvalExemptToolNames, mcpInventoryToolNames);
    expect(result.activatedSkills.single.id, mcpInstallerSkillId);
    expect(
      result.messages.first.content,
      contains(mcpInstallerSkill.instructions),
    );
  });

  test(
    'reuses an activated reference without spending its budget twice',
    () async {
      final auto = fixtureSkill(
        'user:reference-reader',
        'reference-reader',
        'Read relevant reference material.',
        files: const ['SKILL.md', 'references/guide.md'],
      );
      final repository = FixtureFakeSkillRepository(
        {'user:reference-reader': auto},
        resources: {
          'user:reference-reader:references/guide.md': '1234567890123456',
        },
      );
      final provider = FixtureFakeSkillProvider([
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'activate-1',
              name: 'activate_skill',
              arguments: const {'name': 'reference-reader'},
            ),
          ],
        ),
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'read-1',
              name: 'read_skill_resource',
              arguments: const {
                'name': 'reference-reader',
                'path': 'references/guide.md',
              },
            ),
          ],
        ),
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'read-2',
              name: 'read_skill_resource',
              arguments: const {
                'name': 'reference-reader',
                'path': 'references/guide.md',
              },
            ),
          ],
        ),
        SkillToolTurn(isComplete: true),
      ]);
      final compose = ComposeChatTurn(
        skillRepository: repository,
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding('user:reference-reader'),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
        budget: const SkillContextBudget(maxResourceTokens: 3),
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(
          senderId: 'user-1',
          content: 'Use the reference guide.',
        ),
        currentUserId: 'user-1',
        skillToolProvider: provider,
      );

      expect(repository.readResourcePaths, ['references/guide.md']);
      expect(result.estimatedSkillContextTokens, lessThanOrEqualTo(13));
      expect(
        provider.session.results
            .expand((results) => results)
            .where((result) => result.name == 'read_skill_resource')
            .map((result) => result.content),
        everyElement(contains('[truncated]')),
      );
    },
  );

  test('configured unsupported models do not expose Skills', () async {
    final skill = fixtureSkill('user:auto', 'auto', 'Auto instructions.');
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository({'user:auto': skill}),
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding('user:auto'),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
    );

    final result = await compose(
      bot: fixtureBot(
        parameters: const {
          Bot.parameterSupportsAutomaticSkillActivation: false,
        },
      ),
      history: const [],
      userMessage: fixtureMessage(senderId: 'user-1', content: 'Question'),
      currentUserId: 'user-1',
      skillToolProvider: FixtureFakeSkillProvider([
        SkillToolTurn(isComplete: true),
      ]),
    );

    expect(result.activatedSkills, isEmpty);
    expect(result.activationAttempts, isEmpty);
    expect(result.messages.map((message) => message.role), ['system', 'user']);
    expect(
      result.messages.first.content,
      startsWith('<stars_application_context>'),
    );
    expect(result.messages.last.content, 'Question');
  });

  test('records automatic Skill provider timeouts explicitly', () async {
    final skill = fixtureSkill('user:auto', 'auto', 'Auto instructions.');
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository({'user:auto': skill}),
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding('user:auto'),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
    );

    final result = await compose(
      bot: fixtureBot(),
      history: const [],
      userMessage: fixtureMessage(senderId: 'user-1', content: 'Use auto'),
      currentUserId: 'user-1',
      skillToolProvider: FixtureFailingSkillProvider(
        TimeoutException('Skill request timed out.'),
      ),
    );

    expect(result.activatedSkills, isEmpty);
    expect(result.skillToolCalls.single.detail, 'provider_timeout');
    expect(result.skillToolCalls.single.errorCode, 'skill_provider_timeout');
  });

  test('records a safe structured automatic Skill Provider failure', () async {
    final skill = fixtureSkill('user:auto', 'auto', 'Auto instructions.');
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository({'user:auto': skill}),
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding('user:auto'),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
    );
    final failure = ProviderFailure.fromHttp(
      statusCode: 404,
      endpointKind: ProviderEndpointKind.responses,
      responseBody: '{"error":{"message":"Bearer sk-secret"}}',
    );

    final result = await compose(
      bot: fixtureBot(),
      history: const [],
      userMessage: fixtureMessage(senderId: 'user-1', content: 'Use auto'),
      currentUserId: 'user-1',
      skillToolProvider: FixtureFailingSkillProvider(failure),
    );

    expect(result.activatedSkills, isEmpty);
    expect(result.skillToolCalls.single.detail, 'provider_endpoint_not_found');
    expect(
      result.skillToolCalls.single.errorCode,
      'skill_provider_endpoint_not_found',
    );
    expect(result.skillToolCalls.single.detail, isNot(contains('sk-secret')));
  });

  for (final batched in [true, false]) {
    test('activates every model-selected Skill: batched=$batched', () async {
      final skills = <String, SkillContent>{
        for (var index = 0; index < 10; index++)
          'user:skill-$index': fixtureSkill(
            'user:skill-$index',
            'skill-$index',
            'Instructions $index',
            requestedToolNames: {'tool-$index'},
          ),
      };
      final repository = FixtureFakeSkillRepository(skills);
      final compose = ComposeChatTurn(
        skillRepository: repository,
        bindingRepository: FixtureFakeBindingRepository([
          for (var index = 0; index < 10; index++)
            fixtureBinding('user:skill-$index', priority: index),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
      );
      final calls = [
        for (var index = 9; index >= 0; index--)
          SkillToolCall(
            callId: 'activate-$index',
            name: 'activate_skill',
            arguments: {'name': 'skill-$index'},
          ),
      ];
      final provider = FixtureFakeSkillProvider([
        if (batched)
          SkillToolTurn(calls: calls)
        else
          for (final call in calls) SkillToolTurn(calls: [call]),
        SkillToolTurn(isComplete: true),
      ]);

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(senderId: 'user-1', content: 'Question'),
        currentUserId: 'user-1',
        skillToolProvider: provider,
      );

      expect(result.activatedSkills.map((skill) => skill.id), [
        for (var index = 9; index >= 0; index--) 'user:skill-$index',
      ]);
      expect(repository.loadedIds, hasLength(10));
      expect(result.requestedToolNames, {
        for (var index = 0; index < 10; index++) 'tool-$index',
      });
      expect(
        result.activationAttempts.map((attempt) => attempt.status),
        everyElement(SkillActivationStatus.activated),
      );
      expect(provider.session.closed, isTrue);
    });
  }

  test('records Skills skipped by the context Token budget', () async {
    final oversized = fixtureSkill(
      'user:oversized',
      'oversized',
      'This instruction is intentionally longer than a four-token budget.',
    );
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository({
        'user:oversized': oversized,
      }),
      bindingRepository: FixtureFakeBindingRepository([
        fixtureBinding('user:oversized'),
      ]),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
      budget: const SkillContextBudget(maxTokensPerSkill: 4),
    );

    final result = await compose(
      bot: fixtureBot(),
      history: const [],
      userMessage: fixtureMessage(senderId: 'user-1', content: 'Question'),
      currentUserId: 'user-1',
      skillToolProvider: FixtureFakeSkillProvider([
        SkillToolTurn(
          calls: [
            SkillToolCall(
              callId: 'activate-oversized',
              name: 'activate_skill',
              arguments: const {'name': 'oversized'},
            ),
          ],
        ),
        SkillToolTurn(isComplete: true),
      ]),
    );

    expect(result.activatedSkills, isEmpty);
    expect(
      result.activationAttempts.single.status,
      SkillActivationStatus.skipped,
    );
    expect(result.activationAttempts.single.errorCode, 'per_skill_token_limit');
  });

  test(
    'excludes unusable Skill candidates before automatic model activation',
    () async {
      final blocked = fixtureSkill(
        'user:blocked',
        'blocked',
        'Blocked instructions.',
      );
      final usable = fixtureSkill(
        'user:usable',
        'usable',
        'Usable instructions.',
      );
      final blockedDescriptor = SkillDescriptor(
        id: blocked.descriptor.id,
        name: blocked.descriptor.name,
        description: blocked.descriptor.description,
        version: blocked.descriptor.version,
        scope: blocked.descriptor.scope,
        sourceUri: blocked.descriptor.sourceUri,
        rootPath: blocked.descriptor.rootPath,
        contentDigest: blocked.descriptor.contentDigest,
        trustState: SkillTrustState.blocked,
        validationStatus: blocked.descriptor.validationStatus,
        compatibility: blocked.descriptor.compatibility,
        installedAt: blocked.descriptor.installedAt,
        updatedAt: blocked.descriptor.updatedAt,
      );
      final compose = ComposeChatTurn(
        skillRepository: FixtureFakeSkillRepository({
          'user:blocked': SkillContent(
            descriptor: blockedDescriptor,
            instructions: blocked.instructions,
          ),
          'user:usable': usable,
        }),
        bindingRepository: FixtureFakeBindingRepository([
          fixtureBinding('user:blocked', priority: 100),
          fixtureBinding('user:usable', priority: 1),
        ]),
        conversationArtifactsDirectoryProvider:
            fixtureTestConversationArtifactsDirectory,
      );

      final result = await compose(
        bot: fixtureBot(),
        history: const [],
        userMessage: fixtureMessage(senderId: 'user-1', content: 'Question'),
        currentUserId: 'user-1',
        skillToolProvider: FixtureFakeSkillProvider([
          SkillToolTurn(
            calls: [
              SkillToolCall(
                callId: 'activate-usable',
                name: 'activate_skill',
                arguments: const {'name': 'usable'},
              ),
            ],
          ),
          SkillToolTurn(isComplete: true),
        ]),
      );

      expect(result.activatedSkills.map((skill) => skill.id), ['user:usable']);
      expect(result.messages.first.content, contains('Usable instructions.'));
      expect(
        result.messages.first.content,
        isNot(contains('Blocked instructions.')),
      );
    },
  );

  test('exposes only MCP Tools configured for the bot', () async {
    final now = DateTime(2026, 8, 2);
    final server = McpServer(
      id: 'server-1',
      name: 'Docs',
      transport: McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://mcp.example.test'),
      ),
      status: McpConnectionStatus.connected,
      createdAt: now,
      updatedAt: now,
    );
    final tool = McpToolDescriptor(
      serverId: server.id,
      remoteName: 'search',
      title: 'Search',
      description: 'Search documentation',
      inputSchema: const {'type': 'object', 'properties': <String, Object?>{}},
      updatedAt: now,
    );
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository(const {}),
      bindingRepository: FixtureFakeBindingRepository(const []),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
      mcpServerRepository: FixtureFakeMcpServerRepository(server, [tool]),
    );

    final result = await compose(
      bot: fixtureBot(
        parameters: const {
          Bot.parameterSupportsMcp: true,
          Bot.parameterMcpTools: [
            {
              'server_id': 'server-1',
              'remote_name': 'search',
              'requires_approval': false,
            },
          ],
        },
      ),
      history: const [],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Search the docs',
      ),
      currentUserId: 'user-1',
      skillToolProvider: FixtureMcpProvider(),
    );

    expect(result.requestedToolNames, {'mcp.server-1.search'});
    expect(result.approvalExemptToolNames, {'mcp.server-1.search'});

    final unconfiguredResult = await compose(
      bot: fixtureBot(parameters: const {Bot.parameterSupportsMcp: true}),
      history: const [],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Search the docs',
      ),
      currentUserId: 'user-1',
      skillToolProvider: FixtureMcpProvider(),
    );

    expect(unconfiguredResult.requestedToolNames, isEmpty);
    expect(unconfiguredResult.approvalExemptToolNames, isEmpty);
  });
}
