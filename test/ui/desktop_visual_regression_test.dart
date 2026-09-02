import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/use_cases/create_chat.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/app/views/desktop_layout.dart';
import 'package:stars/ui/features/bots/view_models/bot_list_view_model.dart';
import 'package:stars/ui/features/bots/views/add_bot.dart';
import 'package:stars/ui/features/bots/views/bots.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/ui/features/chats/views/chat_item.dart';
import 'package:stars/ui/features/profile/views/profile.dart';
import 'package:stars/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const widths = [1024.0, 1280.0, 1600.0];
  const locales = [Locale('zh', 'CN'), Locale('en')];
  const appearances = [
    _Appearance('light', Brightness.light),
    _Appearance('dark', Brightness.dark),
    _Appearance('high_contrast', Brightness.light, highContrast: true),
  ];

  for (final width in widths) {
    for (final locale in locales) {
      for (final appearance in appearances) {
        final localeName = locale.languageCode == 'zh' ? 'zh_CN' : 'en';
        final widthName = width.toInt();
        testWidgets(
          'desktop visual matrix ${appearance.name} $localeName $widthName',
          (tester) async {
            debugDefaultTargetPlatformOverride = TargetPlatform.linux;
            try {
              tester.view.devicePixelRatio = 1;
              tester.view.physicalSize = const Size(1440, 1500);
              addTearDown(tester.view.reset);

              final botRepository = _VisualBotRepository(_visualBots(locale));
              final botViewModel = BotListViewModel(
                botRepository: botRepository,
                createChat: CreateChat(chatRepository: _VisualChatRepository()),
                aiProviderRepository: _UnusedAiProviderRepository(),
                attachmentRepository: _UnusedAttachmentRepository(),
              );
              addTearDown(botViewModel.dispose);
              await botViewModel.load();

              await tester.pumpWidget(
                _VisualHarness(
                  appearance: appearance,
                  locale: locale,
                  child: _DesktopVisualGallery(
                    logicalWidth: width,
                    locale: locale,
                    botViewModel: botViewModel,
                  ),
                ),
              );
              await tester.pumpAndSettle();

              await expectLater(
                find.byKey(const ValueKey<String>('desktop-visual-matrix')),
                matchesGoldenFile(
                  'goldens/desktop_visual_matrix/'
                  '${appearance.name}_${localeName}_$widthName.png',
                ),
              );
              expect(tester.takeException(), isNull);
            } finally {
              debugDefaultTargetPlatformOverride = null;
            }
          },
        );
      }
    }
  }
}

class _Appearance {
  const _Appearance(this.name, this.brightness, {this.highContrast = false});

  final String name;
  final Brightness brightness;
  final bool highContrast;
}

class _VisualHarness extends StatelessWidget {
  const _VisualHarness({
    required this.appearance,
    required this.locale,
    required this.child,
  });

  final _Appearance appearance;
  final Locale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shadTheme = buildStarsShadTheme(
      brightness: appearance.brightness,
      fontSize: 16,
      highContrast: appearance.highContrast,
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
            debugShowCheckedModeBanner: false,
            theme: buildShadMaterialBridgeTheme(
              context: shadContext,
              fontSize: 16,
              highContrast: appearance.highContrast,
            ),
            locale: locale,
            supportedLocales: supportedLocales,
            localizationsDelegates: const [
              GlobalShadLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              S.delegate,
            ],
            builder:
                (context, appChild) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(highContrast: appearance.highContrast),
                  child: ShadAppBuilder(child: appChild!),
                ),
            home: Scaffold(body: child),
          ),
    );
  }
}

class _DesktopVisualGallery extends StatefulWidget {
  const _DesktopVisualGallery({
    required this.logicalWidth,
    required this.locale,
    required this.botViewModel,
  });

  final double logicalWidth;
  final Locale locale;
  final BotListViewModel botViewModel;

  @override
  State<_DesktopVisualGallery> createState() => _DesktopVisualGalleryState();
}

class _DesktopVisualGalleryState extends State<_DesktopVisualGallery> {
  late final ScrollController _messageScrollController;

  bool get _isChinese => widget.locale.languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    _messageScrollController = ScrollController();
  }

  @override
  void dispose() {
    _messageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bot = widget.botViewModel.bots.first;
    final scenes = <(String, Widget)>[
      ('Desktop shell', _buildShell()),
      ('Conversation list', _buildConversationList(bot)),
      ('Bot grid', _buildBotGrid()),
      ('Bot add / edit', _buildBotForm()),
      ('Long message + tools', _buildMessageList(bot)),
      ('Settings', _buildProfile()),
    ];

    return RepaintBoundary(
      key: const ValueKey<String>('desktop-visual-matrix'),
      child: ColoredBox(
        color: StarsDesktopTokens.of(context).windowBackground,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (var row = 0; row < 3; row += 1)
                Expanded(
                  child: Row(
                    children: [
                      for (var column = 0; column < 2; column += 1) ...[
                        Expanded(
                          child: _SceneFrame(
                            title: scenes[row * 2 + column].$1,
                            logicalWidth: widget.logicalWidth,
                            child: scenes[row * 2 + column].$2,
                          ),
                        ),
                        if (column == 0) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShell() {
    return DesktopLayout(
      currentIndex: 0,
      onPageChanged: (_) {},
      pages: [
        Center(child: Text(_isChinese ? '会话列表' : 'Conversations')),
        Center(child: Text(_isChinese ? '智能体列表' : 'Bots')),
        const Center(child: Text('Skills')),
        const Center(child: Text('MCP')),
        Center(child: Text(_isChinese ? '设置' : 'Settings')),
      ],
      onCreateChat: () {},
      onSearchRequested: () {},
      onBotUpdated: (_) async {},
      onBotDeleted: () async {},
    );
  }

  Widget _buildConversationList(Bot bot) {
    return DesktopListPanel(
      title: _isChinese ? '会话' : 'Conversations',
      description: _isChinese ? '最近的对话' : 'Recent conversations',
      searchHintText: _isChinese ? '搜索会话' : 'Search conversations',
      onSearchChanged: (_) {},
      action: StarsDesktopIconAction(
        icon: LucideIcons.plus,
        label: _isChinese ? '新建会话' : 'New conversation',
        onPressed: () {},
      ),
      child: ListView(
        children: [
          ChatListItem(
            bot: bot,
            lastMessage:
                _isChinese ? '整理桌面组件矩阵与视觉基线' : 'Review the desktop UI matrix',
            timestamp: '09:42',
            isSelected: true,
            onTap: () {},
          ),
          ChatListItem(
            bot: widget.botViewModel.bots.last,
            lastMessage:
                _isChinese ? '分析最新的工具执行结果' : 'Analyze the latest tool run',
            timestamp: _isChinese ? '昨天' : 'Yesterday',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBotGrid() {
    return ContactsPage(
      viewModel: widget.botViewModel,
      onBotSelected: (_) {},
      onBotEditSelected: (_) {},
    );
  }

  Widget _buildBotForm() {
    return AddBotPage(
      embedded: true,
      botId: 'golden-bot',
      onBotAdded: (_, _) async {},
      modelLoader: (_) async => const [],
    );
  }

  Widget _buildMessageList(Bot bot) {
    final assistantText =
        _isChinese
            ? '这是一个用于验证桌面长消息排版的回复。它包含多段说明、工具执行状态和足够长的正文，'
                '用于观察在不同窗口宽度下的换行、留白、操作按钮与执行摘要是否保持一致。\n\n'
                '第二段继续补充内容，确保消息气泡不会挤压侧边栏，也不会让工具状态超出可见区域。'
            : 'This response validates long desktop message layout. It includes multiple '
                'paragraphs, tool execution state, and enough text to exercise wrapping, spacing, '
                'message actions, and execution summaries at every supported window width.\n\n'
                'A second paragraph keeps the message representative without crowding the sidebar.';
    return Column(
      children: [
        MessageList(
          messages: [
            Message(
              messageId: 'user-message',
              chatId: 'chat-1',
              botId: bot.id,
              senderId: 'me',
              content:
                  _isChinese
                      ? '请检查桌面视觉回归矩阵。'
                      : 'Check the desktop visual matrix.',
              timestamp: DateTime(2026, 8, 12, 9, 40),
            ),
          ],
          scrollController: _messageScrollController,
          isStreaming: true,
          streamingResponse: assistantText,
          streamingProcessInfo: const MessageProcessInfo(
            durationMs: 1480,
            reasoningStatus: 'completed',
            toolCalls: [
              MessageToolCall(
                callId: 'tool-1',
                name: 'search_docs',
                title: 'Search documentation',
                source: 'mcp',
                status: 'succeeded',
                resultSummary: '6 references',
                durationMs: 320,
              ),
            ],
            commandExecutions: [
              MessageCommandExecution(
                callId: 'command-1',
                command: 'flutter test',
                status: 'succeeded',
                durationMs: 910,
              ),
            ],
          ),
          streamingTokenUsage: const ModelTokenUsage(
            inputTokens: 820,
            outputTokens: 1460,
          ),
          currentUserId: 'me',
          isDesktop: true,
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return ProfilePage(
      initialProfile: Profile(
        name: _isChinese ? '星辰用户' : 'Stars User',
        avatar: '',
        fontSize: 16,
        themeMode: 0,
        language: _isChinese ? 'zh_CN' : 'en',
        createTimestamp: DateTime(2026, 8, 12),
        modifyTimestamp: DateTime(2026, 8, 12),
      ),
      onProfileSaved: (_) async {},
      applicationPromptProvider:
          (languageCode) => 'Stable visual regression prompt.',
      onOpenSkillLibrary: () {},
      onOpenMcpServers: () {},
    );
  }
}

class _SceneFrame extends StatelessWidget {
  const _SceneFrame({
    required this.title,
    required this.logicalWidth,
    required this.child,
  });

  final String title;
  final double logicalWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.contentBackground,
          border: Border.all(color: tokens.separator),
          borderRadius: StarsDesktopThemeSpec.containerRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '$title · ${logicalWidth.toInt()}px',
                style: StarsDesktopThemeSpec.sectionTitleStyle(context),
              ),
            ),
            const ShadSeparator.horizontal(),
            Expanded(
              child: ClipRect(
                child: FittedBox(
                  alignment: Alignment.topLeft,
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: logicalWidth,
                    height: 720,
                    child: Builder(
                      builder:
                          (context) => MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(size: Size(logicalWidth, 720)),
                            child: Scaffold(body: child),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Bot> _visualBots(Locale locale) {
  final isChinese = locale.languageCode == 'zh';
  return [
    _visualBot('researcher', isChinese ? '研究助手' : 'Research Assistant'),
    _visualBot('reviewer', isChinese ? '代码审查' : 'Code Reviewer'),
    _visualBot('writer', isChinese ? '写作伙伴' : 'Writing Partner'),
  ];
}

Bot _visualBot(String id, String name) => Bot(
  id: id,
  name: name,
  avatar: '',
  provider: 'OpenAI',
  baseURL: 'https://api.openai.com/v1/',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'gpt-5.2',
  systemPrompt: 'Be helpful.',
  parameters: const {
    Bot.parameterContextWindowTokens: 128000,
    Bot.parameterInputModalities: ['text', 'image'],
    Bot.parameterOutputModalities: ['text'],
  },
  createTimestamp: DateTime(2026, 8, 12),
  modifyTimestamp: DateTime(2026, 8, 12),
);

class _VisualBotRepository implements BotRepository {
  _VisualBotRepository(this.bots);

  final List<Bot> bots;

  @override
  Stream<List<Bot>> get changes => const Stream<List<Bot>>.empty();

  @override
  Future<void> addBot(Bot bot) async => bots.add(bot);

  @override
  Future<void> deleteBot(String id) async =>
      bots.removeWhere((bot) => bot.id == id);

  @override
  Future<Bot?> getBot(String id) async =>
      bots.where((bot) => bot.id == id).firstOrNull;

  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async =>
      List<Bot>.unmodifiable(bots);

  @override
  Future<void> updateBot(Bot bot) async {}
}

class _VisualChatRepository implements ChatRepository {
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

class _UnusedAiProviderRepository implements AiProviderRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('AI calls are not used by visual tests.');
}

class _UnusedAttachmentRepository implements AttachmentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(
        'Attachment actions are not used by visual tests.',
      );
}
