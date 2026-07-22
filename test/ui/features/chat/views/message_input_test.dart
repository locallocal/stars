import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/model/model.dart';
import 'package:stars/ui/features/chat/views/message_input.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/utils/theme.dart';

void main() {
  group('desktop MessageInput', () {
    testWidgets('does not show provider or model metadata', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpMessageInput(tester, controller: controller);

      expect(find.text('test · test-model'), findsNothing);
      expect(find.text('test-model'), findsNothing);
    });

    testWidgets('empty input keeps send disabled', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var sendCalls = 0;

      await _pumpMessageInput(
        tester,
        controller: controller,
        onSend: () => sendCalls += 1,
      );

      final sendButton = find.widgetWithText(ShadButton, '发送');
      expect(sendButton, findsOneWidget);
      final button = tester.widget<ShadButton>(sendButton);
      final sendButtonContext = tester.element(sendButton);
      expect(
        button.backgroundColor,
        DesktopThemeTokens.primaryActionColor(sendButtonContext),
      );
      expect(
        DesktopThemeTokens.inactivePrimaryActionColor(sendButtonContext),
        button.backgroundColor?.withValues(alpha: 0.5),
      );
      expect(
        tester
            .widgetList<Opacity>(
              find.descendant(of: sendButton, matching: find.byType(Opacity)),
            )
            .any((widget) => widget.opacity == 0.5),
        isTrue,
      );
      expect(button.enabled, isFalse);
      expect(button.onPressed, isNull);

      await tester.tap(sendButton, warnIfMissed: false);
      await tester.pump();
      expect(sendCalls, 0);
    });

    testWidgets('plain Enter sends the current message', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var sendCalls = 0;

      await _pumpMessageInput(
        tester,
        controller: controller,
        onSend: () => sendCalls += 1,
      );
      await _focusAndEnterText(tester, 'Hello');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sendCalls, 1);
    });

    testWidgets('Shift+Enter does not send', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var sendCalls = 0;

      await _pumpMessageInput(
        tester,
        controller: controller,
        onSend: () => sendCalls += 1,
      );
      await _focusAndEnterText(tester, 'First line');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(sendCalls, 0);
      expect(controller.text, startsWith('First line'));
    });

    testWidgets('Enter cannot submit again while a request is in progress', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Already submitted');
      addTearDown(controller.dispose);
      var sendCalls = 0;
      var cancelCalls = 0;

      await _pumpMessageInput(
        tester,
        controller: controller,
        requestInProgress: true,
        canCancel: true,
        onSend: () => sendCalls += 1,
        onCancel: () => cancelCalls += 1,
      );
      await tester.tap(find.byType(ShadTextarea));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(sendCalls, 0);
      expect(cancelCalls, 0);
      expect(find.widgetWithText(ShadButton, '停止'), findsOneWidget);
    });

    testWidgets('cancellable request swaps send for a same-size stop action', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Ready');
      addTearDown(controller.dispose);
      var sendCalls = 0;
      var cancelCalls = 0;

      await _pumpMessageInput(
        tester,
        controller: controller,
        onSend: () => sendCalls += 1,
        onCancel: () => cancelCalls += 1,
      );
      final sendButton = find.widgetWithText(ShadButton, '发送');
      final sendSize = tester.getSize(sendButton);
      final sendCenter = tester.getCenter(sendButton);

      await _pumpMessageInput(
        tester,
        controller: controller,
        requestInProgress: true,
        canCancel: true,
        onSend: () => sendCalls += 1,
        onCancel: () => cancelCalls += 1,
      );

      final stopButton = find.widgetWithText(ShadButton, '停止');
      expect(stopButton, findsOneWidget);
      expect(tester.getSize(stopButton), sendSize);
      expect(tester.getCenter(stopButton), sendCenter);
      expect(tester.getSize(stopButton), const Size(96, 36));

      await tester.tap(stopButton);
      await tester.pump();

      expect(cancelCalls, 1);
      expect(sendCalls, 0);
    });
  });
}

Future<void> _pumpMessageInput(
  WidgetTester tester, {
  required TextEditingController controller,
  bool requestInProgress = false,
  bool canCancel = false,
  VoidCallback? onSend,
  VoidCallback? onCancel,
}) async {
  final shadTheme = buildStarsShadTheme(
    brightness: Brightness.light,
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

  await tester.pumpWidget(
    ShadApp.custom(
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
            home: Builder(
              builder:
                  (context) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: const Size(1000, 800),
                      disableAnimations: true,
                    ),
                    child: Scaffold(
                      body: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 700,
                          child: MessageInput(
                            provider: _FakeProvider(_bot),
                            controller: controller,
                            requestInProgress: requestInProgress,
                            canCancel: canCancel,
                            desktopMode: true,
                            onCameraPressed: _noop,
                            onGalleryPressed: _noop,
                            onFilePressed: _noop,
                            onImageSizeSelected: _ignoreString,
                            onImageStyleSelected: _ignoreString,
                            onVideoRatioSelected: _ignoreString,
                            onSend: onSend ?? _noop,
                            onCancelRequest: onCancel ?? _noop,
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _focusAndEnterText(WidgetTester tester, String text) async {
  final textarea = find.byType(ShadTextarea);
  expect(textarea, findsOneWidget);
  await tester.tap(textarea);
  await tester.enterText(textarea, text);
  await tester.pump();
}

void _noop() {}

void _ignoreString(String _) {}

class _FakeProvider extends AiProvider {
  _FakeProvider(super.bot);

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final _bot = Bot(
  id: 'bot-1',
  name: 'Test bot',
  avatar: '',
  provider: 'test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: DateTime.fromMillisecondsSinceEpoch(1),
  modifyTimestamp: DateTime.fromMillisecondsSinceEpoch(1),
);
