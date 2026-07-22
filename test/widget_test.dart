import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/model/model.dart';
import 'package:stars/ui/features/app/views/desktop_layout.dart';
import 'package:stars/ui/features/bots/views/add_bot.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/ui/features/chats/views/chat_list_builder.dart';
import 'package:stars/ui/features/chats/views/new_chat_dialog.dart';
import 'package:stars/utils/theme.dart';

void main() {
  testWidgets('desktop theme exposes the documented light fallback tokens', (
    tester,
  ) async {
    late BuildContext testContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
        home: Builder(
          builder: (context) {
            testContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final tokens = StarsDesktopTokens.of(testContext);
    expect(tokens.windowBackground, const Color(0xFFFFFFFF));
    expect(tokens.contentBackground, const Color(0xFFFFFFFF));
    expect(tokens.sidebarOpaque, const Color(0xFFFAFAFA));
    expect(tokens.raisedSurface, const Color(0xFFFFFFFF));
    expect(tokens.controlFill, const Color(0xFFF4F4F5));
    expect(tokens.hoverFill, const Color(0xFFF4F4F5));
    expect(tokens.pressedFill, const Color(0xFFE4E4E7));
    expect(tokens.selectedFill, const Color(0xFFF4F4F5));
    expect(tokens.separator, const Color(0xFFE4E4E7));
    expect(tokens.primaryText, const Color(0xFF09090B));
    expect(tokens.secondaryText, const Color(0xFF71717A));
    expect(tokens.tertiaryText, const Color(0xFFA1A1AA));
    expect(tokens.accent, const Color(0xFF18181B));
    expect(tokens.success, const Color(0xFF16A34A));
    expect(tokens.warning, const Color(0xFFD97706));
    expect(tokens.danger, const Color(0xFFEF4444));
    expect(tokens.highContrast, isFalse);
    expect(tokens.reduceTransparency, isFalse);

    expect(
      DesktopThemeTokens.shellBackground(testContext),
      tokens.windowBackground,
    );
    expect(DesktopThemeTokens.sidebarWidth, 300);
    expect(DesktopThemeTokens.inspectorWidth, 320);
    expect(DesktopThemeTokens.toolbarHeight, 50);
    expect(DesktopThemeTokens.menuBarHeight, 50);
    expect(DesktopThemeTokens.sidebarDecoration(testContext).border, isNull);
    expect(DesktopThemeTokens.formContentMaxWidth, 920);
    expect(
      StarsDesktopTheme.contentMaxWidth,
      DesktopThemeTokens.formContentMaxWidth,
    );
    expect(
      StarsDesktopTheme.inputMaxWidth,
      DesktopThemeTokens.formContentMaxWidth,
    );
    expect(
      DesktopThemeTokens.formPagePadding,
      const EdgeInsets.fromLTRB(32, 28, 32, 48),
    );
  });

  testWidgets('desktop theme exposes the documented dark fallback tokens', (
    tester,
  ) async {
    late BuildContext testContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.dark, fontSize: 16),
        home: Builder(
          builder: (context) {
            testContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final tokens = StarsDesktopTokens.of(testContext);
    expect(tokens.windowBackground, const Color(0xFF09090B));
    expect(tokens.contentBackground, const Color(0xFF09090B));
    expect(tokens.sidebarOpaque, const Color(0xFF18181B));
    expect(tokens.raisedSurface, const Color(0xFF18181B));
    expect(tokens.controlFill, const Color(0xFF27272A));
    expect(tokens.hoverFill, const Color(0xFF27272A));
    expect(tokens.pressedFill, const Color(0xFF3F3F46));
    expect(tokens.selectedFill, const Color(0xFF27272A));
    expect(tokens.separator, const Color(0xFF27272A));
    expect(tokens.primaryText, const Color(0xFFFAFAFA));
    expect(tokens.secondaryText, const Color(0xFFA1A1AA));
    expect(tokens.tertiaryText, const Color(0xFF71717A));
    expect(tokens.accent, const Color(0xFFFAFAFA));
    expect(tokens.success, const Color(0xFF22C55E));
    expect(tokens.warning, const Color(0xFFF59E0B));
    expect(tokens.danger, const Color(0xFFEF4444));
  });

  testWidgets('Shad dark theme keeps the sidebar lighter than the workspace', (
    tester,
  ) async {
    late BuildContext testContext;

    await tester.pumpWidget(
      _shadHarness(
        brightness: Brightness.dark,
        homeBuilder: (context) {
          testContext = context;
          return const SizedBox.shrink();
        },
      ),
    );
    await tester.pumpAndSettle();

    final tokens = StarsDesktopTokens.of(testContext);
    expect(tokens.contentBackground, const Color(0xFF09090B));
    expect(tokens.sidebarOpaque, const Color(0xFF18181B));
    expect(tokens.sidebarOpaque, isNot(tokens.contentBackground));
  });

  testWidgets('high contrast strengthens semantic boundaries and selection', (
    tester,
  ) async {
    late BuildContext testContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(
          brightness: Brightness.light,
          fontSize: 16,
          highContrast: true,
          reduceTransparency: true,
        ),
        home: Builder(
          builder: (context) {
            testContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final tokens = StarsDesktopTokens.of(testContext);
    expect(tokens.highContrast, isTrue);
    expect(tokens.reduceTransparency, isTrue);
    expect(tokens.separator, const Color(0xFFA1A1AA));
    expect(tokens.selectedFill, const Color(0xFFE4E4E7));
    expect(tokens.focusRing, const Color(0xFF09090B));
    expect(DesktopThemeTokens.panelShadow(testContext), isEmpty);
  });

  testWidgets('MediaQuery high contrast is honored by semantic token access', (
    tester,
  ) async {
    late BuildContext testContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.dark, fontSize: 16),
        home: MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final tokens = StarsDesktopTokens.of(testContext);
    expect(tokens.highContrast, isTrue);
    expect(tokens.separator, const Color(0xFF71717A));
    expect(tokens.selectedFill, const Color(0xFF3F3F46));
  });

  test('Shad high contrast strengthens direct component boundaries', () {
    final regular = buildStarsShadTheme(
      brightness: Brightness.light,
      fontSize: 16,
    );
    final highContrast = buildStarsShadTheme(
      brightness: Brightness.light,
      fontSize: 16,
      highContrast: true,
    );

    expect(regular.colorScheme.border, const Color(0xFFE4E4E7));
    expect(highContrast.colorScheme.border, const Color(0xFFA1A1AA));
    expect(highContrast.colorScheme.input, const Color(0xFFA1A1AA));
    expect(highContrast.colorScheme.ring, const Color(0xFF09090B));
  });

  test('mobile keeps the pre-migration Material palette', () {
    final mobile = buildLegacyMobileTheme(
      brightness: Brightness.light,
      fontSize: 16,
    );

    expect(mobile.colorScheme.primary, const Color(0xFF007AFF));
    expect(mobile.scaffoldBackgroundColor, const Color(0xFFF5F5F7));
    expect(mobile.dividerTheme.thickness, 0);
    expect(mobile.inputDecorationTheme.fillColor, const Color(0x1F787880));
  });

  test('content typography preserves the full 12 to 24 preference range', () {
    final small = buildAppTheme(brightness: Brightness.light, fontSize: 12);
    final large = buildAppTheme(brightness: Brightness.light, fontSize: 24);

    expect(small.textTheme.bodyLarge?.fontSize, 12);
    expect(large.textTheme.bodyLarge?.fontSize, 24);
  });

  testWidgets('glass roles use a solid semantic fallback without blur', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
        home: const Scaffold(
          body: StarsGlassSurface(
            role: StarsGlassRole.popover,
            child: Text('Popover content'),
          ),
        ),
      ),
    );

    expect(find.text('Popover content'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('desktop toolbar button keeps a 44px hit target and activates', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
        home: Scaffold(
          body: StarsToolbarButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: '搜索',
            onPressed: () => presses += 1,
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(StarsToolbarButton)), const Size(44, 44));
    await tester.tap(find.byIcon(Icons.search_rounded));
    expect(presses, 1);
  });

  testWidgets('desktop search and list primitives remain functional and flat', (
    tester,
  ) async {
    var query = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
        home: Scaffold(
          body: SizedBox(
            width: DesktopThemeTokens.sidebarWidth,
            height: 700,
            child: DesktopListPanel(
              title: '聊天',
              description: '最近会话',
              searchHintText: '搜索聊天记录',
              onSearchChanged: (value) => query = value,
              action: const Icon(Icons.add_rounded),
              child: const Text('会话内容'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('聊天'), findsOneWidget);
    expect(find.text('最近会话'), findsOneWidget);
    expect(find.text('会话内容'), findsOneWidget);
    expect(find.byType(StarsSearchField), findsOneWidget);
    expect(find.byType(Card), findsNothing);

    await tester.enterText(find.byType(TextField), '模型');
    expect(query, '模型');
  });

  testWidgets('desktop list panel can match the settings content width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 700);
    addTearDown(tester.view.reset);

    late Color workspaceColor;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
        home: Builder(
          builder: (context) {
            workspaceColor = DesktopThemeTokens.workspaceSurface(context);
            return Scaffold(
              body: SizedBox(
                width: 1000,
                height: 700,
                child: DesktopListPanel(
                  title: '',
                  description: '',
                  searchHintText: '搜索智能体',
                  onSearchChanged: (_) {},
                  action: const Text('添加智能体'),
                  contentMaxWidth: DesktopThemeTokens.formContentMaxWidth,
                  padding: DesktopThemeTokens.formPagePadding,
                  backgroundColor: workspaceColor,
                  child: const Text('智能体内容'),
                ),
              ),
            );
          },
        ),
      ),
    );

    final panelBackground = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(DesktopListPanel),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(panelBackground.color, workspaceColor);
    expect(
      tester.getSize(find.byType(StarsSearchField)).width,
      DesktopThemeTokens.formContentMaxWidth,
    );
    expect(find.text('添加智能体'), findsOneWidget);
    expect(find.text('智能体内容'), findsOneWidget);
  });

  testWidgets('desktop list panel can place search directly below padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
        home: Scaffold(
          body: SizedBox(
            width: DesktopThemeTokens.sidebarWidth,
            height: 700,
            child: DesktopListPanel(
              title: '',
              description: '',
              searchHintText: '搜索会话',
              onSearchChanged: (_) {},
              showHeader: false,
              action: const SizedBox.shrink(),
              child: const Text('会话内容'),
            ),
          ),
        ),
      ),
    );

    final panelTop = tester.getTopLeft(find.byType(DesktopListPanel)).dy;
    final searchTop = tester.getTopLeft(find.byType(StarsSearchField)).dy;
    expect(searchTop - panelTop, DesktopThemeTokens.panelPadding.top);
  });

  testWidgets('desktop message content uses its full available page width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: SizedBox(
                width: 736,
                height: 500,
                child: Column(
                  children: [
                    MessageList(
                      messages: [
                        Message(
                          messageId: 'message-1',
                          chatId: 'chat-1',
                          botId: 'bot-1',
                          senderId: 'bot-1',
                          content: '桌面会话内容',
                          timestamp: DateTime(2026),
                        ),
                      ],
                      scrollController: scrollController,
                      isStreaming: false,
                      streamingResponse: '',
                      currentUserId: 'me',
                      isDesktop: true,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('desktop-message-viewport')),
          )
          .width,
      736,
    );
  });

  testWidgets('chat row menu does not show a row focus ring on pointer use', (
    tester,
  ) async {
    await _withDesktopPlatform(() async {
      var openCount = 0;
      final registry = ChatGenerationRegistry(
        messagePersister: (message) async => message,
        lastMessageUpdater: (_, _) async {},
        providerFactory: (_) => throw StateError('Provider is not expected'),
      );
      addTearDown(registry.clear);
      final timestamp = DateTime(2026);
      final bot = Bot(
        id: 'bot-1',
        name: '测试智能体',
        avatar: '',
        provider: 'OpenAI',
        baseURL: '',
        apiKey: '',
        apiType: Bot.apiTypeOpenAI,
        model: 'gpt-test',
        systemPrompt: '',
        createTimestamp: timestamp,
        modifyTimestamp: timestamp,
      );
      final chat = Chat(
        id: 'chat-1',
        botId: bot.id,
        lastMessage: '测试会话',
        lastMessageTimestamp: timestamp,
        createTimestamp: timestamp,
        modifyTimestamp: timestamp,
      );

      await tester.pumpWidget(
        _shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 240,
                  child: ChatListBuilder(
                    chatList: [chat],
                    bots: [bot],
                    selectedChatId: chat.id,
                    generationRegistry: registry,
                    onChatDeleted: (_) {},
                    onDeleteChat: (_) async {},
                    onChatSelected: (_, _) => openCount += 1,
                  ),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();

      final row = find.byType(DesktopInteractiveListItem);
      final rowButton = tester.widget<ShadButton>(
        find.descendant(of: row, matching: find.byType(ShadButton)).first,
      );
      final rowContext = tester.element(row);
      final rowContainer = tester.widget<AnimatedContainer>(
        find.descendant(of: row, matching: find.byType(AnimatedContainer)),
      );
      final rowDecoration = rowContainer.decoration! as BoxDecoration;
      final rowBorder = rowDecoration.border! as Border;
      expect(rowButton.decoration?.disableSecondaryBorder, isTrue);
      expect(rowBorder.top.width, 0);
      expect(rowButton.variant, ShadButtonVariant.primary);
      expect(
        rowButton.backgroundColor,
        DesktopThemeTokens.inactivePrimaryActionColor(rowContext),
      );
      expect(rowButton.hoverBackgroundColor, rowButton.backgroundColor);
      expect(rowButton.pressedBackgroundColor, rowButton.backgroundColor);
      expect(rowButton.foregroundColor, Colors.white);
      expect(rowButton.hoverForegroundColor, Colors.white);
      expect(rowButton.pressedForegroundColor, Colors.white);
      expect(
        tester.widget<Text>(find.text(bot.name)).style?.color,
        Colors.white,
      );
      expect(
        tester
            .widget<Text>(find.textContaining(chat.lastMessage).first)
            .style
            ?.color,
        Colors.white,
      );

      await tester.tap(find.byIcon(LucideIcons.messageCircle));
      await tester.pumpAndSettle();

      expect(openCount, 1);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('chat-row-actions'),
      );
    });
  });

  testWidgets('desktop empty state renders without a card shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
        home: const Scaffold(
          body: DesktopEmptyStateCard(
            icon: Icons.forum_outlined,
            title: '尚未选择会话',
            description: '从侧边栏选择会话。',
          ),
        ),
      ),
    );

    expect(find.text('尚未选择会话'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('desktop home empty state has no duplicate new chat action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await _withDesktopPlatform(() async {
      await tester.pumpWidget(_desktopHarness(onCreateChat: () {}));
      await tester.pumpAndSettle();

      final emptyState = find.byType(DesktopEmptyStateCard);
      expect(emptyState, findsOneWidget);
      expect(
        find.descendant(of: emptyState, matching: find.text('点击新建会话创建会话')),
        findsOneWidget,
      );
      expect(find.textContaining('聊天'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('desktop-toolbar-clear-chat')),
        findsNothing,
      );
      expect(
        find.descendant(of: emptyState, matching: find.byType(ShadButton)),
        findsNothing,
      );
    });
  });

  testWidgets('desktop selected chat exposes clear action in the toolbar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await _withDesktopPlatform(() async {
      await tester.pumpWidget(_desktopHarness(selectedChatId: 'chat-1'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('desktop-toolbar-clear-chat')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('清空会话记录'), findsOneWidget);
    });
  });

  testWidgets('desktop sidebar selections match the empty composer action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    for (final selectedPage in [1, 2]) {
      await tester.pumpWidget(_desktopHarness(currentIndex: selectedPage));
      await tester.pumpAndSettle();

      final label = selectedPage == 1 ? '智能体' : '我的';
      final selectedButtonFinder =
          find
              .ancestor(of: find.text(label), matching: find.byType(ShadButton))
              .first;
      final selectedButton = tester.widget<ShadButton>(selectedButtonFinder);
      final selectedButtonContext = tester.element(selectedButtonFinder);

      expect(selectedButton.variant, ShadButtonVariant.primary);
      expect(
        selectedButton.backgroundColor,
        DesktopThemeTokens.inactivePrimaryActionColor(selectedButtonContext),
      );
      expect(
        selectedButton.hoverBackgroundColor,
        selectedButton.backgroundColor,
      );
      expect(
        selectedButton.pressedBackgroundColor,
        selectedButton.backgroundColor,
      );
      expect(selectedButton.foregroundColor, Colors.white);
      expect(selectedButton.hoverForegroundColor, Colors.white);
      expect(selectedButton.pressedForegroundColor, Colors.white);

      final textFinder = find.text(label).first;
      final text = tester.widget<Text>(textFinder);
      final inheritedTextStyle =
          DefaultTextStyle.of(tester.element(textFinder)).style;
      expect(inheritedTextStyle.merge(text.style).color, Colors.white);

      if (selectedPage == 1) {
        final newChatButton = tester.widget<ShadButton>(
          find
              .ancestor(
                of: find.byIcon(LucideIcons.squarePen),
                matching: find.byType(ShadButton),
              )
              .first,
        );
        final agentIcon = selectedButton.leading! as Icon;
        final newChatIcon = newChatButton.leading! as Icon;

        expect(selectedButton.size, newChatButton.size);
        expect(selectedButton.expands, newChatButton.expands);
        expect(
          selectedButton.mainAxisAlignment,
          newChatButton.mainAxisAlignment,
        );
        expect(selectedButton.padding, newChatButton.padding);
        expect(selectedButton.gap, newChatButton.gap);
        expect(agentIcon.size, newChatIcon.size);
      }
    }
  });

  testWidgets('desktop shell uses one toolbar and overlays sidebar at 800px', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_desktopHarness());
    await tester.pumpAndSettle();

    expect(find.text('文件'), findsNothing);
    expect(find.text('编辑'), findsNothing);
    expect(find.text('视图'), findsNothing);
    expect(find.text('帮助'), findsNothing);
    expect(find.text('Stars'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('desktop-toolbar-sidebar')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stars'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Stars'), findsNothing);
  });

  testWidgets('inspector only exposes real selected bot context', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    final bot = Bot(
      id: 'bot-1',
      name: 'Researcher',
      avatar: '',
      provider: 'OpenAI',
      baseURL: 'https://example.invalid',
      apiKey: '',
      apiType: Bot.apiTypeOpenAI,
      model: 'gpt-test',
      systemPrompt: '',
      createTimestamp: DateTime(2026),
      modifyTimestamp: DateTime(2026),
    );

    await tester.pumpWidget(_desktopHarness(currentIndex: 1, bot: bot));
    await tester.pumpAndSettle();

    final detailScaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey<String>('desktop-bot-detail-scaffold')),
    );
    final saveBarBackground = tester.widget<ColoredBox>(
      find.byKey(const ValueKey<String>('desktop-bot-save-bar-background')),
    );
    final detailContext = tester.element(
      find.byKey(const ValueKey<String>('desktop-bot-detail-scaffold')),
    );
    final workspaceColor = DesktopThemeTokens.workspaceSurface(detailContext);
    expect(detailScaffold.backgroundColor, workspaceColor);
    expect(saveBarBackground.color, workspaceColor);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('desktop-bot-detail-content')),
          )
          .width,
      DesktopThemeTokens.formContentMaxWidth +
          DesktopThemeTokens.formPagePadding.horizontal,
    );
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byKey(
                    const ValueKey<String>('desktop-bot-detail-content'),
                  ),
                  matching: find.byType(ShadInput),
                )
                .first,
          )
          .width,
      DesktopThemeTokens.formContentMaxWidth,
    );

    await tester.tap(find.byIcon(Icons.vertical_split_outlined));
    await tester.pumpAndSettle();

    expect(find.text('本地桌面'), findsNothing);
    expect(find.text('就绪'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Researcher'), findsWidgets);
    expect(find.text('OpenAI'), findsWidgets);
    expect(find.text('gpt-test'), findsWidgets);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('desktop command shortcuts share the shell actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);
    var createCount = 0;
    var searchCount = 0;

    await tester.pumpWidget(
      _desktopHarness(
        onCreateChat: () => createCount += 1,
        onSearchRequested: () => searchCount += 1,
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(createCount, 1);
    expect(searchCount, 1);
    expect(find.text('Stars'), findsNothing);
  });

  testWidgets('new chat uses the desktop dialog and interactive list style', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);
    await _withDesktopPlatform(() async {
      final bots = <Bot>[
        Bot(
          id: 'bot-1',
          name: 'Researcher with a deliberately long display name',
          avatar: '',
          provider: 'OpenAI',
          baseURL: 'https://example.invalid',
          apiKey: '',
          apiType: Bot.apiTypeOpenAI,
          model: 'gpt-test',
          systemPrompt: '',
          createTimestamp: DateTime(2026),
          modifyTimestamp: DateTime(2026),
        ),
        Bot(
          id: 'bot-2',
          name: 'Writer',
          avatar: '',
          provider: 'Anthropic',
          baseURL: 'https://example.invalid',
          apiKey: '',
          apiType: Bot.apiTypeAnthropic,
          model: 'claude-test',
          systemPrompt: '',
          createTimestamp: DateTime(2026),
          modifyTimestamp: DateTime(2026),
        ),
      ];

      await tester.pumpWidget(
        _newChatDialogHarness(
          brightness: Brightness.light,
          botsFuture: Future<List<Bot>>.value(bots),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('新建会话'), findsOneWidget);
      expect(find.text('选择智能体'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.byType(DesktopInteractiveListItem), findsNWidgets(2));
      expect(find.byType(ListTile), findsNothing);
      expect(find.text('OpenAI · gpt-test'), findsOneWidget);
      expect(find.text('Anthropic · claude-test'), findsOneWidget);
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey<String>('new-chat-dialog-content')),
            )
            .width,
        480,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('new chat empty state uses the dark semantic dialog surface', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    await _withDesktopPlatform(() async {
      await tester.pumpWidget(
        _newChatDialogHarness(
          brightness: Brightness.dark,
          botsFuture: Future<List<Bot>>.value(const <Bot>[]),
        ),
      );
      await tester.pumpAndSettle();

      final shadTheme = ShadTheme.of(tester.element(find.byType(ShadDialog)));
      expect(shadTheme.colorScheme.background, const Color(0xFF09090B));
      expect(shadTheme.colorScheme.border, const Color(0xFF27272A));
      expect(find.text('没有可用的智能体'), findsOneWidget);
      expect(find.byIcon(LucideIcons.bot), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('add bot uses the desktop form dialog and anchored menus', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.reset);
    Bot? submittedBot;

    await _withDesktopPlatform(() async {
      await tester.pumpWidget(
        _addBotDialogHarness(
          brightness: Brightness.light,
          onBotAdded: (bot) async => submittedBot = bot,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.byType(ShadForm), findsOneWidget);
      expect(find.byType(MenuAnchor), findsNWidgets(3));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(
        tester.getSize(
          find.byKey(const ValueKey<String>('add-bot-dialog-content')),
        ),
        const Size(840, 720),
      );
      expect(find.text('基本信息'), findsOneWidget);
      expect(find.text('提供商信息'), findsOneWidget);
      expect(find.text('模型配置'), findsOneWidget);
      expect(find.byType(ShadCard), findsNWidgets(3));

      final basicSection = find.byKey(
        const ValueKey<String>('add-bot-basic-section'),
      );
      final providerSection = find.byKey(
        const ValueKey<String>('add-bot-provider-section'),
      );
      final modelSection = find.byKey(
        const ValueKey<String>('add-bot-model-section'),
      );
      expect(
        find.descendant(
          of: basicSection,
          matching: find.byKey(const ValueKey<String>('add-bot-name')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: providerSection,
          matching: find.byKey(const ValueKey<String>('add-bot-provider')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: modelSection,
          matching: find.byKey(const ValueKey<String>('add-bot-model')),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(basicSection).bottom,
        lessThan(tester.getRect(providerSection).top),
      );
      expect(
        tester.getRect(providerSection).bottom,
        lessThan(tester.getRect(modelSection).top),
      );

      Size inputSize(String key) {
        return tester.getSize(
          find.descendant(
            of: find.byKey(ValueKey<String>(key)),
            matching: find.byType(ShadInput),
          ),
        );
      }

      final singleLineInputSizes = [
        inputSize('add-bot-name'),
        inputSize('add-bot-provider'),
        inputSize('add-bot-api-type'),
        inputSize('add-bot-base-url'),
        inputSize('add-bot-api-key'),
        inputSize('add-bot-model'),
      ];
      expect(singleLineInputSizes.map((size) => size.width).toSet(), {640.0});
      expect(singleLineInputSizes.map((size) => size.height).toSet(), {48.0});

      final nameField = find.byKey(const ValueKey<String>('add-bot-name'));
      await tester.enterText(
        find.descendant(of: nameField, matching: find.byType(EditableText)),
        'Researcher',
      );
      await tester.pump();
      final nameInputRect = tester.getRect(
        find.descendant(of: nameField, matching: find.byType(ShadInput)),
      );
      final nameTextRect = tester.getRect(
        find.descendant(of: nameField, matching: find.byType(EditableText)),
      );
      expect(nameTextRect.center.dy, closeTo(nameInputRect.center.dy, 0.5));

      final systemPromptSize = tester.getSize(
        find.descendant(
          of: find.byKey(const ValueKey<String>('add-bot-system-prompt')),
          matching: find.byType(ShadTextarea),
        ),
      );
      expect(systemPromptSize, const Size(640, 114));

      final providerField = find.byKey(
        const ValueKey<String>('add-bot-provider'),
      );
      final providerMenuAnchor = find.descendant(
        of: providerField,
        matching: find.byType(MenuAnchor),
      );
      expect(providerMenuAnchor, findsOneWidget);

      final providerDropdownIcon = find.descendant(
        of: providerMenuAnchor,
        matching: find.byIcon(Icons.expand_more_rounded),
      );
      final providerDropdownIconRect = tester.getRect(providerDropdownIcon);
      await tester.enterText(
        find.descendant(of: providerField, matching: find.byType(EditableText)),
        'Anthropic',
      );
      await tester.pumpAndSettle();

      TextEditingController controllerFor(String key) {
        return tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(ValueKey<String>(key)),
                matching: find.byType(EditableText),
              ),
            )
            .controller;
      }

      expect(
        controllerFor('add-bot-base-url').text,
        'https://api.anthropic.com/v1/',
      );
      expect(controllerFor('add-bot-api-type').text, Bot.apiTypeAnthropic);

      await tester.tap(find.byIcon(Icons.expand_more_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.byType(MenuItemButton), findsWidgets);
      expect(find.text('OpenAI'), findsWidgets);
      final openAIOption = find.ancestor(
        of: find.text('OpenAI'),
        matching: find.byType(MenuItemButton),
      );
      final openAIOptionRect = tester.getRect(openAIOption);
      expect(
        openAIOptionRect.top,
        greaterThan(providerDropdownIconRect.bottom),
      );
      expect(
        openAIOptionRect.right,
        closeTo(providerDropdownIconRect.right, 1),
      );
      final anthropicOption = find.ancestor(
        of: find.text('Anthropic'),
        matching: find.byType(MenuItemButton),
      );
      expect(
        find.descendant(
          of: anthropicOption,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: anthropicOption,
          matching: find.byIcon(Icons.circle),
        ),
        findsNothing,
      );

      await tester.ensureVisible(find.text('HuggingFace').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('HuggingFace').last);
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.byType(MenuAnchor), findsNWidgets(4));
      expect(controllerFor('add-bot-sub-provider').text, 'HF-Inference');
      expect(
        controllerFor('add-bot-base-url').text,
        'https://router.huggingface.co/hf-inference/',
      );
      expect(controllerFor('add-bot-api-type').text, Bot.apiTypeHuggingface);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey<String>('add-bot-name')),
          matching: find.byType(EditableText),
        ),
        'HF Researcher',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey<String>('add-bot-api-key')),
          matching: find.byType(EditableText),
        ),
        'secret-key',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey<String>('add-bot-base-url')),
          matching: find.byType(EditableText),
        ),
        '',
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(submittedBot, isNull);

      const customHuggingFaceUrl = 'https://example.invalid/hf/';
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey<String>('add-bot-base-url')),
          matching: find.byType(EditableText),
        ),
        customHuggingFaceUrl,
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(submittedBot?.provider, 'HuggingFace');
      expect(submittedBot?.baseURL, customHuggingFaceUrl);
      expect(submittedBot?.apiType, Bot.apiTypeHuggingface);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('add bot stays responsive and prevents duplicate submission', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);
    final submission = Completer<void>();
    var submitCount = 0;

    await _withDesktopPlatform(() async {
      await tester.pumpWidget(
        _addBotDialogHarness(
          brightness: Brightness.dark,
          textScaler: const TextScaler.linear(2),
          onBotAdded: (_) {
            submitCount += 1;
            return submission.future;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(
          find.byKey(const ValueKey<String>('add-bot-dialog-content')),
        ),
        const Size(768, 568),
      );
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final fields = find.byType(ShadInputFormField);
      expect(fields, findsNWidgets(6));
      await tester.enterText(
        find.descendant(of: fields.at(0), matching: find.byType(EditableText)),
        'Researcher',
      );
      await tester.enterText(
        find.descendant(of: fields.at(4), matching: find.byType(EditableText)),
        'secret-key',
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(submitCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('添加智能体').last, warnIfMissed: false);
      await tester.pump();
      expect(submitCount, 1);

      submission.complete();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _withDesktopPlatform(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Widget _newChatDialogHarness({
  required Brightness brightness,
  required Future<List<Bot>> botsFuture,
}) {
  return _shadHarness(
    brightness: brightness,
    homeBuilder:
        (context) => Scaffold(
          body: NewChatDialog(botsFuture: botsFuture, onChatCreated: (_, _) {}),
        ),
  );
}

Widget _addBotDialogHarness({
  required Brightness brightness,
  required Future<void> Function(Bot) onBotAdded,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return _shadHarness(
    brightness: brightness,
    homeBuilder:
        (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: Scaffold(body: AddBotDialog(onBotAdded: onBotAdded)),
        ),
  );
}

Widget _desktopHarness({
  int currentIndex = 0,
  Bot? bot,
  String? selectedChatId,
  VoidCallback? onCreateChat,
  VoidCallback? onSearchRequested,
}) {
  return _shadHarness(
    brightness: Brightness.light,
    homeBuilder:
        (context) => Scaffold(
          body: DesktopLayout(
            currentIndex: currentIndex,
            onPageChanged: (_) {},
            pages: const [
              Center(child: Text('chat list')),
              Center(child: Text('bot list')),
              Center(child: Text('profile')),
            ],
            selectedChatId: selectedChatId,
            selectedBot: bot,
            onCreateChat: onCreateChat,
            onSearchRequested: onSearchRequested,
            onBotUpdated: (_) async {},
            onBotDeleted: () async {},
          ),
        ),
  );
}

Widget _shadHarness({
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
