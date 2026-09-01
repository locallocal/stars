import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/app/views/desktop_layout.dart';
import 'package:stars/ui/features/bots/view_models/bot_skill_view_model.dart';
import 'package:stars/ui/features/bots/views/add_bot.dart';
import 'package:stars/ui/features/chats/views/new_chat_dialog.dart';
import 'package:stars/utils/theme.dart';

Future<void> withDesktopPlatform(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<void> withMobilePlatform(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Widget newChatDialogHarness({
  required Brightness brightness,
  required Future<List<Bot>> botsFuture,
}) {
  return shadHarness(
    brightness: brightness,
    homeBuilder:
        (context) => Scaffold(
          body: NewChatDialog(botsFuture: botsFuture, onChatCreated: (_, _) {}),
        ),
  );
}

Widget addBotDialogHarness({
  required Brightness brightness,
  required Future<void> Function(Bot, List<BotSkillBinding>) onBotAdded,
  TextScaler textScaler = TextScaler.noScaling,
  String? botId,
  BotSkillViewModel? skillViewModel,
  Future<List<AiModelInfo>> Function(Bot)? modelLoader,
}) {
  return shadHarness(
    brightness: brightness,
    homeBuilder:
        (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: Scaffold(
            body: AddBotDialog(
              botId: botId,
              skillViewModel: skillViewModel,
              modelLoader: modelLoader,
              onBotAdded: onBotAdded,
            ),
          ),
        ),
  );
}

Widget desktopHarness({
  int currentIndex = 0,
  Bot? bot,
  Bot? selectedChatBot,
  String? selectedChatId,
  Widget? chatListPage,
  Widget? profilePage,
  VoidCallback? onCreateChat,
  VoidCallback? onSearchRequested,
}) {
  return shadHarness(
    brightness: Brightness.light,
    homeBuilder:
        (context) => Scaffold(
          body: DesktopLayout(
            currentIndex: currentIndex,
            onPageChanged: (_) {},
            pages: [
              chatListPage ?? const Center(child: Text('chat list')),
              const Center(child: Text('bot list')),
              const Center(child: Text('skills')),
              const Center(child: Text('mcp servers')),
              profilePage ?? const Center(child: Text('profile')),
            ],
            selectedChatId: selectedChatId,
            selectedChatBot: selectedChatBot,
            selectedBot: bot,
            onCreateChat: onCreateChat,
            onSearchRequested: onSearchRequested,
            onBotUpdated: (_) async {},
            onBotDeleted: () async {},
          ),
        ),
  );
}

Widget shadHarness({
  required Brightness brightness,
  required WidgetBuilder homeBuilder,
}) {
  final shadTheme = buildStarsShadTheme(
    brightness: brightness,
    fontSize: 16,
  ).copyWith(
    tooltipTheme: const ShadTooltipTheme(
      waitDuration: Duration.zero,
      showDuration: Duration.zero,
      duration: Duration.zero,
      reverseDuration: Duration.zero,
      effects: [],
    ),
  );
  return ShadApp.custom(
    themeMode: ThemeMode.light,
    theme: shadTheme,
    appBuilder:
        (shadContext) => MaterialApp(
          theme: buildShadMaterialBridgeTheme(
            context: shadContext,
            fontSize: 16,
          ),
          locale: const Locale('zh', 'CN'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: Builder(builder: homeBuilder),
        ),
  );
}

class BotCardTestBotRepository implements BotRepository {
  BotCardTestBotRepository(this.bots);

  final List<Bot> bots;
  Bot? addedBot;
  String? deletedBotId;

  @override
  Stream<List<Bot>> get changes => const Stream<List<Bot>>.empty();

  @override
  Future<void> addBot(Bot bot) async {
    addedBot = bot;
  }

  @override
  Future<void> deleteBot(String id) async {
    deletedBotId = id;
  }

  @override
  Future<Bot?> getBot(String id) async => null;

  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async => bots;

  @override
  Future<void> updateBot(Bot bot) async {}
}

class BotCardTestBindingRepository implements BotSkillBindingRepository {
  final List<BotSkillBinding> savedBindings = [];

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<BotSkillBinding>> getForBot(String botId) async =>
      List<BotSkillBinding>.unmodifiable(
        savedBindings.where((binding) => binding.botId == botId),
      );

  @override
  Future<void> remove(String botId, String skillId) async {
    savedBindings.removeWhere(
      (binding) => binding.botId == botId && binding.skillId == skillId,
    );
  }

  @override
  Future<void> save(BotSkillBinding binding) async {
    savedBindings
      ..removeWhere(
        (item) =>
            item.botId == binding.botId && item.skillId == binding.skillId,
      )
      ..add(binding);
  }
}

class BotCardTestMessageRepository implements MessageRepository {
  const BotCardTestMessageRepository(this.usageByBot);

  final Map<String, ModelTokenUsage> usageByBot;

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<ModelTokenUsage> getTokenUsageForBot(String botId) async =>
      usageByBot[botId] ?? ModelTokenUsage.empty;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Message operation is not used by this test.');
}

class BotCardTestMcpRepository implements McpServerRepository {
  const BotCardTestMcpRepository(this.servers);

  final List<McpServer> servers;

  @override
  Stream<List<McpServer>> get changes => const Stream<List<McpServer>>.empty();

  @override
  Future<List<McpServer>> getServers() async =>
      List<McpServer>.unmodifiable(servers);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('MCP operation is not used by this test.');
}

McpServer botCardMcpServer(String id, String name) => McpServer(
  id: id,
  name: name,
  transport: McpStreamableHttpServerTransport(
    endpoint: Uri.parse('https://mcp.example.test/$id'),
  ),
  status: McpConnectionStatus.connected,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class BotCardTestChatRepository implements ChatRepository {
  @override
  Stream<List<Chat>> get changes => const Stream<List<Chat>>.empty();

  @override
  Future<void> addChat(Chat chat) async {}

  @override
  Future<void> clearHistory(String id) async {}

  @override
  Future<void> deleteChat(String id) async {}

  @override
  Future<void> deleteChatsForBot(String botId) async {}

  @override
  Future<Chat?> getChat(String id) async => null;

  @override
  Future<List<Chat>> getChats({bool forceRefresh = false}) async => const [];

  @override
  void invalidate() {}

  @override
  Future<void> updateLastMessage(String id, String content) async {}
}

class UnusedAiProviderRepository implements AiProviderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('AI provider is not used by this test.');
}

class UnusedAttachmentRepository implements AttachmentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Attachment picker is not used by this test.');
}

SkillDescriptor addBotSkill(String name) {
  final timestamp = DateTime(2026);
  return SkillDescriptor(
    id: 'user:$name',
    name: name,
    description: '$name description',
    version: '1.0.0',
    scope: SkillScope.user,
    sourceUri: 'file:///skills/$name',
    rootPath: '/skills/$name',
    contentDigest: 'digest-$name',
    trustState: SkillTrustState.userReviewed,
    validationStatus: SkillValidationStatus.valid,
    compatibility: 'all',
    installedAt: timestamp,
    updatedAt: timestamp,
  );
}

final class AddBotSkillRepository implements SkillRepository {
  const AddBotSkillRepository(this.skills);

  final List<SkillDescriptor> skills;

  @override
  Stream<List<SkillDescriptor>> get changes =>
      const Stream<List<SkillDescriptor>>.empty();

  @override
  Future<List<SkillDescriptor>> getInstalled({
    bool forceRefresh = false,
  }) async => List<SkillDescriptor>.unmodifiable(skills);

  @override
  Future<SkillDescriptor?> getById(String id) async =>
      skills.where((skill) => skill.id == id).firstOrNull;

  @override
  Future<SkillDescriptor> install(SkillImportSource source) =>
      throw UnsupportedError('Skill installation is not used by this test.');

  @override
  Future<SkillContent> load(String skillId, {String? contentDigest}) =>
      throw UnsupportedError('Skill loading is not used by this test.');

  @override
  Future<SkillResourceContent> readResource(
    String skillId,
    String relativePath, {
    String? contentDigest,
  }) => throw UnsupportedError('Skill resources are not used by this test.');

  @override
  Future<void> uninstall(String skillId) =>
      throw UnsupportedError('Skill removal is not used by this test.');
}
