import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/utils/theme.dart';

import 'support/widget_test_support.dart';

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
      StarsDesktopThemeSpec.shellBackground(testContext),
      tokens.windowBackground,
    );
    expect(StarsDesktopThemeSpec.sidebarWidth, 300);
    expect(StarsDesktopThemeSpec.toolbarHeight, 50);
    expect(StarsDesktopThemeSpec.menuBarHeight, 50);
    expect(StarsDesktopThemeSpec.sidebarDecoration(testContext).border, isNull);
    expect(StarsDesktopThemeSpec.formContentMaxWidth, 920);
    expect(StarsDesktopThemeSpec.addBotFormFieldWidth, 640);
    expect(StarsDesktopThemeSpec.botFormFieldHeight, 48);
    expect(StarsDesktopThemeSpec.botFormSectionPadding, 20);
    expect(StarsDesktopThemeSpec.botFormSectionBorderWidth, 1);
    expect(StarsDesktopThemeSpec.botFormSectionTitleFontSize, 16);
    expect(
      StarsDesktopThemeSpec.contentMaxWidth,
      StarsDesktopThemeSpec.formContentMaxWidth,
    );
    expect(
      StarsDesktopThemeSpec.contentMaxWidth,
      StarsDesktopThemeSpec.formContentMaxWidth,
    );
    expect(
      StarsDesktopThemeSpec.formPagePadding,
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
      shadHarness(
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
    expect(StarsDesktopThemeSpec.panelShadow(testContext), isEmpty);
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
            width: StarsDesktopThemeSpec.sidebarWidth,
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
    expect(
      tester.getSize(find.byType(StarsSearchField)).height,
      StarsDesktopThemeSpec.botFormFieldHeight,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).textAlignVertical,
      TextAlignVertical.center,
    );

    await tester.enterText(find.byType(TextField), '模型');
    expect(query, '模型');
  });

  testWidgets('desktop search fields match bot form height and center text', (
    tester,
  ) async {
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: SizedBox(
                width: StarsDesktopThemeSpec.sidebarWidth,
                child: Column(
                  children: [
                    StarsSearchField(
                      key: const ValueKey<String>('chat-search-field'),
                      hintText: '搜索会话',
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 12),
                    StarsSearchField(
                      key: const ValueKey<String>('bot-search-field'),
                      hintText: '搜索智能体',
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    for (final key in const ['chat-search-field', 'bot-search-field']) {
      final field = find.byKey(ValueKey<String>(key));
      final input = find.descendant(
        of: field,
        matching: find.byType(ShadInput),
      );
      final shadInput = tester.widget<ShadInput>(input);
      expect(
        tester.getSize(field).height,
        StarsDesktopThemeSpec.botFormFieldHeight,
      );
      expect(shadInput.alignment, Alignment.centerLeft);
      expect(shadInput.placeholderAlignment, Alignment.centerLeft);
      expect(
        tester
            .getRect(find.descendant(of: field, matching: find.byType(Text)))
            .center
            .dy,
        closeTo(tester.getRect(input).center.dy, 0.5),
      );
      expect(
        tester
            .getRect(
              find.descendant(of: field, matching: find.byType(EditableText)),
            )
            .center
            .dy,
        closeTo(tester.getRect(input).center.dy, 0.5),
      );
    }
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
            workspaceColor = StarsDesktopThemeSpec.workspaceSurface(context);
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
                  contentMaxWidth: StarsDesktopThemeSpec.formContentMaxWidth,
                  padding: StarsDesktopThemeSpec.formPagePadding,
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
      StarsDesktopThemeSpec.formContentMaxWidth,
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
            width: StarsDesktopThemeSpec.sidebarWidth,
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
    expect(searchTop - panelTop, StarsDesktopThemeSpec.panelPadding.top);
  });
}
