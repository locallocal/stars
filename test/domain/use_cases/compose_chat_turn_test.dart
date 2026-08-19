import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/domain/services/stars_system_prompt.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';

void main() {
  test('offers every enabled Skill for automatic model activation', () async {
    final skills = <String, SkillContent>{
      'user:always': _skill('user:always', 'always', 'Always instructions.'),
      'user:selected': _skill(
        'user:selected',
        'selected',
        'Selected instructions.',
        requestedToolNames: const {'calculate'},
      ),
      'user:ignored': _skill('user:ignored', 'ignored', 'Ignored secret.'),
    };
    final skillRepository = _FakeSkillRepository(skills);
    final bindingRepository = _FakeBindingRepository([
      _binding('user:always', priority: 10),
      _binding('user:selected', priority: 5),
      _binding('user:ignored'),
    ]);
    final provider = _FakeSkillProvider([
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
    final compose = ComposeChatTurn(
      skillRepository: skillRepository,
      bindingRepository: bindingRepository,
      starsSystemPromptProvider: _testStarsSystemPrompt,
    );

    final result = await compose(
      bot: _bot(systemPrompt: 'You are a helpful assistant.'),
      history: [
        _message(senderId: 'user-1', content: 'Earlier question'),
        _message(senderId: 'bot-1', content: 'Earlier answer'),
      ],
      userMessage: _message(senderId: 'user-1', content: 'Current question'),
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
    expect(systemPrompt, contains('Agent ID: bot-1'));
    expect(systemPrompt, contains('Agent name: Assistant'));
    expect(systemPrompt, contains('Current conversation ID: chat-1'));
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
    expect(systemPrompt, contains('Scripts and commands'));
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
    expect(result.requestedToolNames, {'calculate'});
  });

  test('does not send empty assistant history entries to providers', () async {
    final compose = ComposeChatTurn(
      skillRepository: _FakeSkillRepository(const {}),
      bindingRepository: _FakeBindingRepository(const []),
      starsSystemPromptProvider: _testStarsSystemPrompt,
    );

    final result = await compose(
      bot: _bot(),
      history: [
        _message(senderId: 'user-1', content: 'Failed question'),
        _message(senderId: 'bot-1', content: ''),
      ],
      userMessage: _message(senderId: 'user-1', content: 'Retry question'),
      currentUserId: 'user-1',
    );

    expect(result.messages.map((message) => message.role), ['system', 'user']);
    expect(result.messages.last.content, 'Failed question\nRetry question');
    expect(
      result.messages.every(
        (message) =>
            message.content.trim().isNotEmpty ||
            message.images.isNotEmpty ||
            message.files.isNotEmpty,
      ),
      isTrue,
    );
  });

  test(
    'auto activation uses structured tools and injects requested references',
    () async {
      final auto = _skill(
        'user:release-notes',
        'release-notes',
        'Prepare concise release notes.',
        files: const ['SKILL.md', 'references/style.md'],
      );
      final repository = _FakeSkillRepository(
        {'user:release-notes': auto},
        resources: {
          'user:release-notes:references/style.md': 'Use short headings.',
        },
      );
      final provider = _FakeSkillProvider([
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
        bindingRepository: _FakeBindingRepository([
          _binding('user:release-notes'),
        ]),
      );

      final result = await compose(
        bot: _bot(),
        history: const [],
        userMessage: _message(
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

  test('legacy provider does not receive or activate auto Skills', () async {
    final auto = _skill(
      'user:auto',
      'auto',
      'Auto instructions must remain undisclosed.',
    );
    final compose = ComposeChatTurn(
      skillRepository: _FakeSkillRepository({'user:auto': auto}),
      bindingRepository: _FakeBindingRepository([_binding('user:auto')]),
    );

    final result = await compose(
      bot: _bot(),
      history: const [],
      userMessage: _message(senderId: 'user-1', content: 'Use auto'),
      currentUserId: 'user-1',
      skillToolProvider: _LegacySkillProvider(),
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
    'desktop shell system Skill exposes its tool to Agent providers',
    () async {
      final shellSkill = _systemShellSkill();
      final compose = ComposeChatTurn(
        skillRepository: _FakeSkillRepository(const {}),
        bindingRepository: _FakeBindingRepository([
          _binding(shellCommandSkillId),
        ]),
        bundledSkillLoader: () async => [shellSkill],
      );

      final result = await compose(
        bot: _bot(),
        history: const [],
        userMessage: _message(senderId: 'user-1', content: 'List local files'),
        currentUserId: 'user-1',
        skillToolProvider: _FakeSkillProvider(const []),
      );

      expect(result.requestedToolNames, shellCommandToolNames);
      expect(result.approvalExemptToolNames, isEmpty);
      expect(result.activatedSkills.single.id, shellCommandSkillId);
      expect(result.messages.first.role, 'system');
      expect(result.messages.first.content, contains('every command requires'));
      expect(result.messages.first.content, contains(shellSkill.instructions));
    },
  );

  test('unbound or disabled shell system Skill exposes no tool', () async {
    final shellSkill = _systemShellSkill();
    for (final bindings in <List<BotSkillBinding>>[
      const [],
      [_binding(shellCommandSkillId, enabled: false)],
    ]) {
      final compose = ComposeChatTurn(
        skillRepository: _FakeSkillRepository(const {}),
        bindingRepository: _FakeBindingRepository(bindings),
        bundledSkillLoader: () async => [shellSkill],
      );

      final result = await compose(
        bot: _bot(),
        history: const [],
        userMessage: _message(senderId: 'user-1', content: 'List local files'),
        currentUserId: 'user-1',
        skillToolProvider: _FakeSkillProvider(const []),
      );

      expect(result.requestedToolNames, isEmpty);
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
  });

  test(
    'bound Skill installer exposes install and SQLite inventory tools',
    () async {
      final installerSkill = _systemSkillInstallerSkill();
      final compose = ComposeChatTurn(
        skillRepository: _FakeSkillRepository(const {}),
        bindingRepository: _FakeBindingRepository([
          _binding(skillInstallerSkillId),
        ]),
        bundledSkillLoader: () async => [installerSkill],
      );

      final result = await compose(
        bot: _bot(),
        history: const [],
        userMessage: _message(
          senderId: 'user-1',
          content: 'Install this Skill from GitHub',
        ),
        currentUserId: 'user-1',
        skillToolProvider: _FakeSkillProvider(const []),
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
    final mcpInstallerSkill = _systemMcpInstallerSkill();
    final compose = ComposeChatTurn(
      skillRepository: _FakeSkillRepository(const {}),
      bindingRepository: _FakeBindingRepository([
        _binding(mcpInstallerSkillId),
      ]),
      bundledSkillLoader: () async => [mcpInstallerSkill],
    );

    final result = await compose(
      bot: _bot(),
      history: const [],
      userMessage: _message(
        senderId: 'user-1',
        content: 'Add this Streamable HTTP MCP server',
      ),
      currentUserId: 'user-1',
      skillToolProvider: _FakeSkillProvider(const []),
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
      final auto = _skill(
        'user:reference-reader',
        'reference-reader',
        'Read relevant reference material.',
        files: const ['SKILL.md', 'references/guide.md'],
      );
      final repository = _FakeSkillRepository(
        {'user:reference-reader': auto},
        resources: {
          'user:reference-reader:references/guide.md': '1234567890123456',
        },
      );
      final provider = _FakeSkillProvider([
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
        bindingRepository: _FakeBindingRepository([
          _binding('user:reference-reader'),
        ]),
        budget: const SkillContextBudget(maxResourceTokens: 3),
      );

      final result = await compose(
        bot: _bot(),
        history: const [],
        userMessage: _message(
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
    final skill = _skill('user:auto', 'auto', 'Auto instructions.');
    final compose = ComposeChatTurn(
      skillRepository: _FakeSkillRepository({'user:auto': skill}),
      bindingRepository: _FakeBindingRepository([_binding('user:auto')]),
    );

    final result = await compose(
      bot: _bot(
        parameters: const {
          Bot.parameterSupportsAutomaticSkillActivation: false,
        },
      ),
      history: const [],
      userMessage: _message(senderId: 'user-1', content: 'Question'),
      currentUserId: 'user-1',
      skillToolProvider: _FakeSkillProvider([SkillToolTurn(isComplete: true)]),
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
    final skill = _skill('user:auto', 'auto', 'Auto instructions.');
    final compose = ComposeChatTurn(
      skillRepository: _FakeSkillRepository({'user:auto': skill}),
      bindingRepository: _FakeBindingRepository([_binding('user:auto')]),
    );

    final result = await compose(
      bot: _bot(),
      history: const [],
      userMessage: _message(senderId: 'user-1', content: 'Use auto'),
      currentUserId: 'user-1',
      skillToolProvider: _FailingSkillProvider(
        TimeoutException('Skill request timed out.'),
      ),
    );

    expect(result.activatedSkills, isEmpty);
    expect(result.skillToolCalls.single.detail, 'provider_timeout');
    expect(result.skillToolCalls.single.errorCode, 'skill_provider_timeout');
  });

  test('limits activation to three usable Skills', () async {
    final skills = <String, SkillContent>{
      for (var index = 0; index < 5; index++)
        'user:skill-$index': _skill(
          'user:skill-$index',
          'skill-$index',
          'Instructions $index',
        ),
    };
    final compose = ComposeChatTurn(
      skillRepository: _FakeSkillRepository(skills),
      bindingRepository: _FakeBindingRepository([
        for (var index = 0; index < 5; index++)
          _binding('user:skill-$index', priority: index),
      ]),
    );
    final provider = _FakeSkillProvider([
      SkillToolTurn(
        calls: [
          for (var index = 4; index >= 0; index--)
            SkillToolCall(
              callId: 'activate-$index',
              name: 'activate_skill',
              arguments: {'name': 'skill-$index'},
            ),
        ],
      ),
      SkillToolTurn(isComplete: true),
    ]);

    final result = await compose(
      bot: _bot(),
      history: const [],
      userMessage: _message(senderId: 'user-1', content: 'Question'),
      currentUserId: 'user-1',
      skillToolProvider: provider,
    );

    expect(result.activatedSkills, hasLength(3));
    expect(result.activatedSkills.map((skill) => skill.id), [
      'user:skill-4',
      'user:skill-3',
      'user:skill-2',
    ]);
  });

  test('records Skills skipped by the context Token budget', () async {
    final oversized = _skill(
      'user:oversized',
      'oversized',
      'This instruction is intentionally longer than a four-token budget.',
    );
    final compose = ComposeChatTurn(
      skillRepository: _FakeSkillRepository({'user:oversized': oversized}),
      bindingRepository: _FakeBindingRepository([_binding('user:oversized')]),
      budget: const SkillContextBudget(maxTokensPerSkill: 4),
    );

    final result = await compose(
      bot: _bot(),
      history: const [],
      userMessage: _message(senderId: 'user-1', content: 'Question'),
      currentUserId: 'user-1',
      skillToolProvider: _FakeSkillProvider([
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
    'skips unusable candidates before applying the activation limit',
    () async {
      final blocked = _skill(
        'user:blocked',
        'blocked',
        'Blocked instructions.',
      );
      final usable = _skill('user:usable', 'usable', 'Usable instructions.');
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
        skillRepository: _FakeSkillRepository({
          'user:blocked': SkillContent(
            descriptor: blockedDescriptor,
            instructions: blocked.instructions,
          ),
          'user:usable': usable,
        }),
        bindingRepository: _FakeBindingRepository([
          _binding('user:blocked', priority: 100),
          _binding('user:usable', priority: 1),
        ]),
      );

      final result = await compose(
        bot: _bot(),
        history: const [],
        userMessage: _message(senderId: 'user-1', content: 'Question'),
        currentUserId: 'user-1',
        skillToolProvider: _FakeSkillProvider([
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
      skillRepository: _FakeSkillRepository(const {}),
      bindingRepository: _FakeBindingRepository(const []),
      mcpServerRepository: _FakeMcpServerRepository(server, [tool]),
    );

    final result = await compose(
      bot: _bot(
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
      userMessage: _message(senderId: 'user-1', content: 'Search the docs'),
      currentUserId: 'user-1',
      skillToolProvider: _McpProvider(),
    );

    expect(result.requestedToolNames, {'mcp.server-1.search'});
    expect(result.approvalExemptToolNames, {'mcp.server-1.search'});

    final unconfiguredResult = await compose(
      bot: _bot(parameters: const {Bot.parameterSupportsMcp: true}),
      history: const [],
      userMessage: _message(senderId: 'user-1', content: 'Search the docs'),
      currentUserId: 'user-1',
      skillToolProvider: _McpProvider(),
    );

    expect(unconfiguredResult.requestedToolNames, isEmpty);
    expect(unconfiguredResult.approvalExemptToolNames, isEmpty);
  });
}

SkillContent _skill(
  String id,
  String name,
  String instructions, {
  List<String> files = const [],
  Set<String> requestedToolNames = const {},
}) {
  final now = DateTime(2026, 7, 26);
  return SkillContent(
    descriptor: SkillDescriptor(
      id: id,
      name: name,
      description: '$name description',
      version: '1.0.0',
      scope: SkillScope.user,
      sourceUri: 'file:///$name',
      rootPath: '/skills/$name',
      contentDigest: 'digest-$name',
      trustState: SkillTrustState.userReviewed,
      validationStatus: SkillValidationStatus.valid,
      compatibility: '',
      requestedToolNames: requestedToolNames,
      installedAt: now,
      updatedAt: now,
    ),
    instructions: instructions,
    files: files,
  );
}

SkillContent _systemShellSkill() {
  final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return SkillContent(
    descriptor: SkillDescriptor(
      id: shellCommandSkillId,
      name: 'shell-command',
      description: 'Execute an approved native shell command.',
      version: '2',
      scope: SkillScope.bundled,
      sourceUri: 'asset:///shell-command/SKILL.md',
      rootPath: 'assets/skills/system/shell-command',
      contentDigest: shellCommandSkillContentDigest,
      trustState: SkillTrustState.bundledTrusted,
      validationStatus: SkillValidationStatus.valid,
      compatibility: 'Stars desktop',
      requestedToolNames: shellCommandToolNames,
      installedAt: timestamp,
      updatedAt: timestamp,
    ),
    instructions:
        'Every command requires approval. Use the native platform shell.',
    files: const ['SKILL.md'],
  );
}

SkillContent _systemSkillInstallerSkill() {
  final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return SkillContent(
    descriptor: SkillDescriptor(
      id: skillInstallerSkillId,
      name: 'skill-installer',
      description: 'Install a validated Stars Skill package.',
      version: '$skillInstallerSkillPromptVersion',
      scope: SkillScope.bundled,
      sourceUri: 'asset:///skill-installer/SKILL.md',
      rootPath: 'assets/skills/system/skill-installer',
      contentDigest: skillInstallerSkillContentDigest,
      trustState: SkillTrustState.bundledTrusted,
      validationStatus: SkillValidationStatus.valid,
      compatibility: 'Stars desktop',
      requestedToolNames: skillInstallerToolNames,
      installedAt: timestamp,
      updatedAt: timestamp,
    ),
    instructions:
        'Use install_skill only after explicit approval. Pass source_type and source.',
    files: const ['SKILL.md'],
  );
}

SkillContent _systemMcpInstallerSkill() {
  final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return SkillContent(
    descriptor: SkillDescriptor(
      id: mcpInstallerSkillId,
      name: 'mcp-installer',
      description: 'Install a configured Stars MCP server.',
      version: '1',
      scope: SkillScope.bundled,
      sourceUri: 'asset:///mcp-installer/SKILL.md',
      rootPath: 'assets/skills/system/mcp-installer',
      contentDigest: mcpInstallerSkillContentDigest,
      trustState: SkillTrustState.bundledTrusted,
      validationStatus: SkillValidationStatus.valid,
      compatibility: 'Stars desktop',
      requestedToolNames: mcpInstallerToolNames,
      installedAt: timestamp,
      updatedAt: timestamp,
    ),
    instructions:
        'Use add_mcp_server only with user-provided connection details.',
    files: const ['SKILL.md'],
  );
}

BotSkillBinding _binding(
  String skillId, {
  int priority = 0,
  bool enabled = true,
}) {
  final now = DateTime(2026, 7, 26);
  return BotSkillBinding(
    botId: 'bot-1',
    skillId: skillId,
    enabled: enabled,
    priority: priority,
    createdAt: now,
    updatedAt: now,
  );
}

Bot _bot({String systemPrompt = '', Map<String, dynamic>? parameters}) => Bot(
  id: 'bot-1',
  name: 'Assistant',
  avatar: '',
  provider: 'OpenAI',
  baseURL: 'https://example.test',
  apiKey: 'secret',
  apiType: Bot.apiTypeOpenAI,
  model: 'model',
  systemPrompt: systemPrompt,
  parameters: parameters ?? const {},
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

Message _message({required String senderId, required String content}) =>
    Message(
      chatId: 'chat-1',
      botId: 'bot-1',
      senderId: senderId,
      content: content,
      timestamp: DateTime(2026, 7, 26),
    );

final class _FakeSkillRepository implements SkillRepository {
  _FakeSkillRepository(this.contents, {this.resources = const {}});

  final Map<String, SkillContent> contents;
  final Map<String, String> resources;
  final List<String> loadedIds = [];
  final List<String> readResourcePaths = [];

  @override
  Stream<List<SkillDescriptor>> get changes => const Stream.empty();

  @override
  Future<SkillDescriptor?> getById(String id) async => contents[id]?.descriptor;

  @override
  Future<List<SkillDescriptor>> getInstalled({
    bool forceRefresh = false,
  }) async => contents.values.map((content) => content.descriptor).toList();

  @override
  Future<SkillDescriptor> install(SkillImportSource source) =>
      throw UnimplementedError();

  @override
  Future<SkillContent> load(String skillId, {String? contentDigest}) async {
    loadedIds.add(skillId);
    return contents[skillId]!;
  }

  @override
  Future<SkillResourceContent> readResource(
    String skillId,
    String relativePath, {
    String? contentDigest,
  }) async {
    readResourcePaths.add(relativePath);
    return SkillResourceContent(
      skillId: skillId,
      path: relativePath,
      content: resources['$skillId:$relativePath']!,
    );
  }

  @override
  Future<void> uninstall(String skillId) => throw UnimplementedError();
}

final class _FakeSkillProvider extends AiProvider {
  _FakeSkillProvider(List<SkillToolTurn> turns)
    : session = _FakeSkillSession(turns),
      super(_bot());

  final _FakeSkillSession session;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  SkillToolSession openSkillToolSession(SkillToolSessionRequest request) {
    session.request = request;
    return session;
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _LegacySkillProvider extends AiProvider {
  _LegacySkillProvider() : super(_bot());

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _FailingSkillProvider extends AiProvider {
  _FailingSkillProvider(Object error)
    : session = _FailingSkillSession(error),
      super(_bot());

  final _FailingSkillSession session;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  SkillToolSession openSkillToolSession(SkillToolSessionRequest request) =>
      session;

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _McpProvider extends AiProvider {
  _McpProvider() : super(_bot());

  @override
  bool supportMcp() => true;

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _FakeMcpServerRepository implements McpServerRepository {
  const _FakeMcpServerRepository(this.server, this.tools);

  final McpServer server;
  final List<McpToolDescriptor> tools;

  @override
  Stream<List<McpServer>> get changes => const Stream.empty();

  @override
  Future<void> deleteServer(String id) => throw UnimplementedError();

  @override
  Future<McpServer?> getServer(String id) async =>
      id == server.id ? server : null;

  @override
  Future<List<McpServer>> getServers() async => [server];

  @override
  Future<List<McpToolDescriptor>> getTools(String serverId) async =>
      serverId == server.id ? tools : const [];

  @override
  Future<void> replaceCatalog(
    McpServer server,
    List<McpToolDescriptor> tools,
  ) => throw UnimplementedError();

  @override
  Future<void> saveServer(McpServer server) => throw UnimplementedError();
}

final class _FakeSkillSession implements SkillToolSession {
  _FakeSkillSession(this.turns);

  final List<SkillToolTurn> turns;
  final List<List<SkillToolResult>> results = [];
  SkillToolSessionRequest? request;
  var _index = 0;
  var closed = false;

  @override
  Future<SkillToolTurn> start() async => turns[_index++];

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> toolResults) async {
    results.add(toolResults);
    return turns[_index++];
  }

  @override
  void close() => closed = true;
}

final class _FailingSkillSession implements SkillToolSession {
  const _FailingSkillSession(this.error);

  final Object error;

  @override
  Future<SkillToolTurn> start() => Future.error(error);

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> results) =>
      Future.error(error);

  @override
  void close() {}
}

final class _FakeBindingRepository implements BotSkillBindingRepository {
  _FakeBindingRepository(this.bindings);

  final List<BotSkillBinding> bindings;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<BotSkillBinding>> getForBot(String botId) async => bindings;

  @override
  Future<void> remove(String botId, String skillId) =>
      throw UnimplementedError();

  @override
  Future<void> save(BotSkillBinding binding) => throw UnimplementedError();
}

String _testStarsSystemPrompt() => buildStarsSystemPrompt(
  operatingSystem: 'TestOS',
  operatingSystemVersion: '1.2.3',
);
