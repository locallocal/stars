import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/services/stars_system_prompt.dart';
import 'package:stars/ui/core/widgets/prompt_markdown.dart';
import 'package:stars/utils/theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('prompt wraps with large text on narrow $brightness screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prompt = buildStarsConversationContext(
        agentId: 'agent-1',
        agentName: 'Research *draft* [notes]',
        conversationId: 'conversation-with-a-long-identifier',
        artifactsDirectoryPath:
            r'C:\Users\research_team\Documents\Stars\conversations\long_directory_name',
        currentTime: DateTime.utc(2026),
      );
      final theme = buildStarsShadTheme(brightness: brightness, fontSize: 14);
      await tester.pumpWidget(
        ShadApp.custom(
          theme: theme,
          darkTheme: theme,
          themeMode:
              brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          appBuilder:
              (shadContext) => MaterialApp(
                theme: buildShadMaterialBridgeTheme(
                  context: shadContext,
                  fontSize: 14,
                ),
                localizationsDelegates: const [
                  GlobalShadLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) => ShadAppBuilder(child: child!),
                home: Scaffold(
                  body: MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(2),
                    ),
                    child: SingleChildScrollView(
                      child: PromptMarkdown(
                        data: prompt,
                        semanticLabel: 'System prompt',
                      ),
                    ),
                  ),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Conversation context', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('Agent name: Research *draft* [notes]', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
      expect(find.byType(Scrollable), findsOneWidget);
      final promptContext = tester.element(find.byType(PromptMarkdown));
      final surface = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PromptMarkdown),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(surface.padding, const EdgeInsets.all(14));
      expect(
        surface.decoration,
        StarsDesktopThemeSpec.statusDecoration(promptContext),
      );
      final markdown = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      expect(
        markdown.styleSheet!.p!.color,
        StarsDesktopThemeSpec.text(promptContext),
      );
      expect(markdown.styleSheet!.p!.fontFamily, 'monospace');
      expect(markdown.styleSheet!.p!.fontSize, 12);
      expect(markdown.styleSheet!.p!.height, 1.5);
      expect(markdown.styleSheet!.h2, markdown.styleSheet!.p);
      expect(tester.takeException(), isNull);
    });
  }
}
