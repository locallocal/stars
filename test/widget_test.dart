import 'package:bubble/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop theme exposes the documented light tokens', (
    WidgetTester tester,
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

    expect(
      DesktopThemeTokens.shellBackground(testContext),
      const Color(0xFFF2F5F9),
    );
    expect(
      DesktopThemeTokens.sidebarSurface(testContext),
      const Color(0xFFEFF3F8),
    );
    expect(DesktopThemeTokens.workspaceSurface(testContext), Colors.white);
    expect(DesktopThemeTokens.sidebarWidth, 340);
    expect(DesktopThemeTokens.inspectorWidth, 380);
    expect(DesktopThemeTokens.menuBarHeight, 42);
  });

  testWidgets('desktop list panel renders task controls and content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
        home: Scaffold(
          body: SizedBox(
            width: DesktopThemeTokens.sidebarWidth,
            height: 700,
            child: DesktopListPanel(
              title: '聊天',
              description: '最近任务',
              searchHintText: '搜索聊天记录',
              onSearchChanged: (_) {},
              action: const Icon(Icons.add_rounded),
              child: const Text('任务内容'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('聊天'), findsOneWidget);
    expect(find.text('最近任务'), findsOneWidget);
    expect(find.text('搜索聊天记录'), findsOneWidget);
    expect(find.text('任务内容'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });
}
