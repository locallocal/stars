import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/ui/features/chat/views/typing_indicator.dart';
import 'package:stars/utils/theme.dart';

void main() {
  testWidgets('desktop typing icon rotates while the bot is responding', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(disableAnimations: true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_harness());
    await tester.pump();

    final spinner = find.byKey(
      const ValueKey<String>('desktop-typing-spinner'),
    );
    expect(spinner, findsOneWidget);
    final initialTurns = tester.widget<RotationTransition>(spinner).turns.value;

    await tester.pump(const Duration(milliseconds: 225));

    final rotatedTurns = tester.widget<RotationTransition>(spinner).turns.value;
    expect(rotatedTurns, isNot(closeTo(initialTurns, 0.01)));
    expect(rotatedTurns, closeTo(0.25, 0.05));
  });

  testWidgets('desktop typing icon respects disabled animations', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(disableAnimations: true));
    await tester.pumpAndSettle();

    final spinner = find.byKey(
      const ValueKey<String>('desktop-typing-spinner'),
    );
    final initialTurns = tester.widget<RotationTransition>(spinner).turns.value;

    await tester.pump(const Duration(milliseconds: 225));

    expect(
      tester.widget<RotationTransition>(spinner).turns.value,
      initialTurns,
    );
  });

  testWidgets('assistant typing follows the complete response lifecycle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        body: const AssistantTypingIndicator(
          botName: 'Stars',
          isResponding: true,
          isDesktop: true,
        ),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TypingIndicator), findsOneWidget);
    expect(find.text('Stars正在输入...'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        body: const Column(
          children: [
            Text('answer'),
            AssistantTypingIndicator(
              botName: 'Stars',
              isResponding: true,
              isDesktop: true,
            ),
          ],
        ),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('answer'), findsOneWidget);
    expect(find.byType(TypingIndicator), findsOneWidget);
    expect(find.text('Stars正在输入...'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        body: const Column(
          children: [
            Text('thinking'),
            AssistantTypingIndicator(
              botName: 'Stars',
              isResponding: true,
              isDesktop: true,
            ),
          ],
        ),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('thinking'), findsOneWidget);
    expect(find.byType(TypingIndicator), findsOneWidget);
    expect(find.text('Stars正在输入...'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        body: const AssistantTypingIndicator(
          botName: 'Stars',
          isResponding: false,
          isDesktop: true,
        ),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TypingIndicator), findsNothing);
    expect(find.text('Stars正在输入...'), findsNothing);
  });

  testWidgets(
    'structured Tool and Skill activity coexists with assistant typing',
    (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _harness(
          body: Column(
            children: [
              MessageList(
                messages: [
                  Message(
                    messageId: 'message-1',
                    turnId: 'turn-1',
                    runId: 'run-1',
                    chatId: 'chat-1',
                    botId: 'bot-1',
                    senderId: 'me',
                    content: 'Use the Skill',
                    timestamp: DateTime(2026),
                  ),
                ],
                scrollController: scrollController,
                isStreaming: true,
                streamingResponse: '',
                streamingProcessInfo: const MessageProcessInfo(
                  toolCalls: [
                    MessageToolCall(
                      callId: 'tool-1',
                      name: 'mcp.notes.save_note',
                      status: 'awaitingApproval',
                    ),
                  ],
                  skillActivations: [
                    MessageSkillActivation(
                      name: 'notes',
                      contentDigest: 'digest',
                      trigger: 'model',
                    ),
                  ],
                ),
                currentUserId: 'me',
                isDesktop: true,
              ),
              const AssistantTypingIndicator(
                botName: 'Stars',
                isResponding: true,
                isDesktop: true,
              ),
            ],
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('desktop-execution-status')),
        findsOneWidget,
      );
      expect(find.byType(TypingIndicator), findsOneWidget);
      expect(find.text('Stars正在输入...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _harness({bool disableAnimations = false, Widget? body}) {
  final shadTheme = buildStarsShadTheme(
    brightness: Brightness.light,
    fontSize: 16,
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
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: disableAnimations),
                child: ShadAppBuilder(child: child!),
              ),
          home: Scaffold(
            body:
                body ??
                const TypingIndicator(botName: 'Stars', isDesktop: true),
          ),
        ),
  );
}
