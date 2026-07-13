import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/desktop_layout.dart';
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
    expect(tokens.windowBackground, const Color(0xFFF5F5F7));
    expect(tokens.contentBackground, const Color(0xFFFFFFFF));
    expect(tokens.sidebarOpaque, const Color(0xFFF0F0F2));
    expect(tokens.raisedSurface, const Color(0xFFFFFFFF));
    expect(tokens.controlFill, const Color(0x1F787880));
    expect(tokens.hoverFill, const Color(0x0D000000));
    expect(tokens.pressedFill, const Color(0x17000000));
    expect(tokens.selectedFill, const Color(0x1F007AFF));
    expect(tokens.separator, const Color(0x2E3C3C43));
    expect(tokens.primaryText, const Color(0xFF1D1D1F));
    expect(tokens.secondaryText, const Color(0xFF6E6E73));
    expect(tokens.tertiaryText, const Color(0xFF8E8E93));
    expect(tokens.accent, const Color(0xFF007AFF));
    expect(tokens.success, const Color(0xFF248A3D));
    expect(tokens.warning, const Color(0xFFC93400));
    expect(tokens.danger, const Color(0xFFD70015));
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
    expect(tokens.windowBackground, const Color(0xFF1C1C1E));
    expect(tokens.contentBackground, const Color(0xFF18181A));
    expect(tokens.sidebarOpaque, const Color(0xFF242426));
    expect(tokens.raisedSurface, const Color(0xFF2C2C2E));
    expect(tokens.controlFill, const Color(0x14FFFFFF));
    expect(tokens.hoverFill, const Color(0x12FFFFFF));
    expect(tokens.pressedFill, const Color(0x1CFFFFFF));
    expect(tokens.selectedFill, const Color(0x380A84FF));
    expect(tokens.separator, const Color(0x24FFFFFF));
    expect(tokens.primaryText, const Color(0xFFF5F5F7));
    expect(tokens.secondaryText, const Color(0xFFAEAEB2));
    expect(tokens.tertiaryText, const Color(0xFF8E8E93));
    expect(tokens.accent, const Color(0xFF0A84FF));
    expect(tokens.success, const Color(0xFF30D158));
    expect(tokens.warning, const Color(0xFFFF9F0A));
    expect(tokens.danger, const Color(0xFFFF453A));
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
    expect(tokens.separator, const Color(0x6B3C3C43));
    expect(tokens.selectedFill, const Color(0x3D007AFF));
    expect(tokens.focusRing, tokens.accent);
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
    expect(tokens.separator, const Color(0x6BFFFFFF));
    expect(tokens.selectedFill, const Color(0x610A84FF));
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

    await tester.tap(find.byIcon(Icons.view_sidebar_outlined));
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
}

Widget _desktopHarness({
  int currentIndex = 0,
  Bot? bot,
  VoidCallback? onCreateChat,
  VoidCallback? onSearchRequested,
}) {
  return MaterialApp(
    theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
    locale: const Locale('zh', 'CN'),
    supportedLocales: supportedLocales,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      S.delegate,
    ],
    home: Scaffold(
      body: DesktopLayout(
        currentIndex: currentIndex,
        onPageChanged: (_) {},
        pages: const [
          Center(child: Text('chat list')),
          Center(child: Text('bot list')),
          Center(child: Text('profile')),
        ],
        selectedBot: bot,
        onCreateChat: onCreateChat,
        onSearchRequested: onSearchRequested,
        onBotUpdated: (_) async {},
        onBotDeleted: () async {},
      ),
    ),
  );
}
