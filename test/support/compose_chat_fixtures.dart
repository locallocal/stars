import 'dart:async';

import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/domain/services/stars_system_prompt.dart';

SkillContent fixtureSkill(
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
      hasReferences: files.any((file) => file.startsWith('references/')),
      installedAt: now,
      updatedAt: now,
    ),
    instructions: instructions,
    files: files,
  );
}

List<SkillToolTurn> fixtureActivationTurns(List<String> skillNames) => [
  SkillToolTurn(
    calls: [
      for (final (index, name) in skillNames.indexed)
        SkillToolCall(
          callId: 'activate-$index',
          name: 'activate_skill',
          arguments: {'name': name},
        ),
    ],
  ),
  SkillToolTurn(isComplete: true),
];

SkillContent fixtureSystemShellSkill() {
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

SkillContent fixtureSystemLocalFileSystemSkill({required bool directory}) {
  final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final id = directory ? directoryOperationsSkillId : fileOperationsSkillId;
  final name = directory ? 'directory-operations' : 'file-operations';
  final requestedToolNames =
      directory ? directoryOperationsToolNames : fileOperationsToolNames;
  return SkillContent(
    descriptor: SkillDescriptor(
      id: id,
      name: name,
      description: 'Native local $name.',
      version: '1',
      scope: SkillScope.bundled,
      sourceUri: 'asset:///$name/SKILL.md',
      rootPath: 'assets/skills/system/$name',
      contentDigest:
          directory
              ? directoryOperationsSkillContentDigest
              : fileOperationsSkillContentDigest,
      trustState: SkillTrustState.bundledTrusted,
      validationStatus: SkillValidationStatus.valid,
      compatibility: 'Stars native platforms',
      requestedToolNames: requestedToolNames,
      installedAt: timestamp,
      updatedAt: timestamp,
    ),
    instructions: 'Use native $name tools only after user approval.',
    files: const ['SKILL.md'],
  );
}

SkillContent fixtureSystemSkillWithReference() {
  final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return SkillContent(
    descriptor: SkillDescriptor(
      id: 'system:bundled-reference',
      name: 'bundled-reference',
      description: 'Read a bundled reference.',
      version: '1',
      scope: SkillScope.bundled,
      sourceUri: 'asset:///bundled-reference/SKILL.md',
      rootPath: 'assets/skills/system/bundled-reference',
      contentDigest: 'digest-bundled-reference',
      trustState: SkillTrustState.bundledTrusted,
      validationStatus: SkillValidationStatus.valid,
      compatibility: 'Stars',
      hasReferences: true,
      installedAt: timestamp,
      updatedAt: timestamp,
    ),
    instructions: 'Read only advertised bundled references.',
    files: const ['SKILL.md', 'references/guide.md'],
    resources: const {'references/guide.md': 'Bundled guide content.'},
  );
}

SkillContent fixtureSystemSkillInstallerSkill() {
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

SkillContent fixtureSystemMcpInstallerSkill() {
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

SkillContent fixtureSystemConversationHistorySkill() {
  final timestamp = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return SkillContent(
    descriptor: SkillDescriptor(
      id: conversationHistorySkillId,
      name: 'conversation-history',
      description: 'Search and read exact persisted conversation messages.',
      version: '$conversationHistorySkillPromptVersion',
      scope: SkillScope.bundled,
      sourceUri: 'asset:///conversation-history/SKILL.md',
      rootPath: 'assets/skills/system/conversation-history',
      contentDigest: conversationHistorySkillContentDigest,
      trustState: SkillTrustState.bundledTrusted,
      validationStatus: SkillValidationStatus.valid,
      compatibility: 'Stars',
      requestedToolNames: conversationHistoryToolNames,
      installedAt: timestamp,
      updatedAt: timestamp,
    ),
    instructions: 'Use history tools only for exact persisted messages.',
    files: const ['SKILL.md'],
  );
}

BotSkillBinding fixtureBinding(
  String skillId, {
  int priority = 0,
  bool enabled = true,
  bool requiresApproval = true,
}) {
  final now = DateTime(2026, 7, 26);
  return BotSkillBinding(
    botId: 'bot-1',
    skillId: skillId,
    enabled: enabled,
    requiresApproval: requiresApproval,
    priority: priority,
    createdAt: now,
    updatedAt: now,
  );
}

Bot fixtureBot({String systemPrompt = '', Map<String, dynamic>? parameters}) =>
    Bot(
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

Message fixtureMessage({
  required String senderId,
  required String content,
  String messageId = '',
  String turnId = 'turn-history',
  String runId = '',
  String reasoning = '',
  MessageTerminalOutcome? terminalOutcome,
  bool hasPartialContent = false,
  MessageGrounding grounding = const MessageGrounding.unverified(),
  List<String> images = const [],
  List<String> files = const [],
}) => Message(
  messageId: messageId,
  turnId: turnId,
  runId: runId,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: senderId,
  content: content,
  reasoning: reasoning,
  terminalOutcome: terminalOutcome,
  hasPartialContent: hasPartialContent,
  grounding: grounding,
  images: images,
  files: files,
  timestamp: DateTime(2026, 7, 26),
);

final class FixtureFakeSkillRepository implements SkillRepository {
  FixtureFakeSkillRepository(
    this.contents, {
    this.resources = const {},
    this.resourceReadError,
  });

  final Map<String, SkillContent> contents;
  final Map<String, String> resources;
  final Object? resourceReadError;
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
    final error = resourceReadError;
    if (error != null) throw error;
    return SkillResourceContent(
      skillId: skillId,
      path: relativePath,
      content: resources['$skillId:$relativePath']!,
    );
  }

  @override
  Future<void> uninstall(String skillId) => throw UnimplementedError();
}

final class FixtureFakeSkillProvider extends AiProvider {
  FixtureFakeSkillProvider(List<SkillToolTurn> turns)
    : session = FixtureFakeSkillSession(turns),
      super(fixtureBot());

  final FixtureFakeSkillSession session;

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

final class FixtureLegacySkillProvider extends AiProvider {
  FixtureLegacySkillProvider() : super(fixtureBot());

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class FixtureFailingSkillProvider extends AiProvider {
  FixtureFailingSkillProvider(Object error)
    : session = FixtureFailingSkillSession(error),
      super(fixtureBot());

  final FixtureFailingSkillSession session;

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

final class FixtureMcpProvider extends AiProvider {
  FixtureMcpProvider() : super(fixtureBot());

  @override
  bool supportMcp() => true;

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class FixtureFakeMcpServerRepository implements McpServerRepository {
  const FixtureFakeMcpServerRepository(this.server, this.tools);

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

final class FixtureFakeSkillSession implements SkillToolSession {
  FixtureFakeSkillSession(this.turns);

  final List<SkillToolTurn> turns;
  final List<List<SkillToolResult>> results = [];
  SkillToolSessionRequest? request;
  var fixtureIndex = 0;
  var closed = false;

  @override
  Future<SkillToolTurn> start() async => turns[fixtureIndex++];

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> toolResults) async {
    results.add(toolResults);
    return turns[fixtureIndex++];
  }

  @override
  void close() => closed = true;
}

final class FixtureFailingSkillSession implements SkillToolSession {
  const FixtureFailingSkillSession(this.error);

  final Object error;

  @override
  Future<SkillToolTurn> start() => Future.error(error);

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> results) =>
      Future.error(error);

  @override
  void close() {}
}

final class FixtureFakeBindingRepository implements BotSkillBindingRepository {
  FixtureFakeBindingRepository(this.bindings);

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

Future<String> fixtureTestConversationArtifactsDirectory(
  String conversationId,
) => Future.value('/data/Stars/chats/$conversationId');

String fixtureTestStarsSystemPrompt(String languageCode) =>
    buildStarsSystemPrompt(
      operatingSystem: 'TestOS',
      operatingSystemVersion: '1.2.3',
      languageCode: languageCode,
    );
