import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/views/conversation_model_controls.dart';
import 'package:stars/utils/theme.dart';

void main() {
  testWidgets('shows settings-aligned switches and toggles provider options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = _CapabilityProvider();
    var savedMaxModelTurns = 15;

    await tester.pumpWidget(
      _harness(
        provider,
        onMaxModelTurnsChanged: (value) async {
          savedMaxModelTurns = value;
        },
      ),
    );
    await tester.pumpAndSettle();

    final webRow = find.byKey(
      const ValueKey<String>('conversation-web-search-row'),
    );
    final thinkingRow = find.byKey(
      const ValueKey<String>('conversation-deep-thinking-row'),
    );
    final webSwitch = find.byKey(
      const ValueKey<String>('conversation-web-search-toggle'),
    );
    final thinkingSwitch = find.byKey(
      const ValueKey<String>('conversation-deep-thinking-toggle'),
    );
    final maxModelTurnsRow = find.byKey(
      const ValueKey<String>('max-model-turns-row'),
    );
    final maxModelTurnsButton = find.byKey(
      const ValueKey<String>('max-model-turns-edit'),
    );
    expect(webRow, findsOneWidget);
    expect(thinkingRow, findsOneWidget);
    expect(maxModelTurnsRow, findsOneWidget);
    expect(find.byType(StarsInspectorInfoRow), findsNWidgets(3));
    expect(find.byType(ShadSwitch), findsNWidgets(2));
    expect(find.byType(ShadButton), findsOneWidget);
    expect(find.text('联网搜索'), findsOneWidget);
    expect(find.text('深度思考'), findsOneWidget);
    expect(find.text('工具请求回合上限'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    final inspectorRows = find.byType(StarsInspectorInfoRow);
    for (var index = 0; index < 3; index++) {
      expect(
        tester.widget<StarsInspectorInfoRow>(inspectorRows.at(index)).layout,
        StarsInspectorInfoRowLayout.settings,
      );
    }
    for (final row in [webRow, thinkingRow, maxModelTurnsRow]) {
      expect(
        tester.getSize(row).height,
        StarsDesktopThemeSpec.settingsRowMinHeight +
            StarsDesktopThemeSpec.settingsRowPadding.vertical,
      );
    }
    expect(
      tester.getRect(find.text('联网搜索')).left,
      closeTo(tester.getRect(find.text('深度思考')).left, 0.01),
    );
    expect(
      tester.getRect(webRow).right - tester.getRect(webSwitch).right,
      StarsDesktopThemeSpec.settingsRowPadding.right +
          StarsDesktopThemeSpec.settingsRowDisclosureInset,
    );
    expect(
      tester.getRect(thinkingRow).right - tester.getRect(thinkingSwitch).right,
      StarsDesktopThemeSpec.settingsRowPadding.right +
          StarsDesktopThemeSpec.settingsRowDisclosureInset,
    );
    expect(
      tester.getTopLeft(maxModelTurnsRow).dy,
      greaterThan(tester.getTopLeft(thinkingRow).dy),
    );
    expect(
      tester.getRect(maxModelTurnsRow).right -
          tester.getRect(maxModelTurnsButton).right,
      StarsDesktopThemeSpec.settingsRowPadding.right +
          StarsDesktopThemeSpec.settingsRowDisclosureInset,
    );
    final separators = find.byType(ShadSeparator);
    expect(separators, findsNWidgets(2));
    for (final separator in separators.evaluate()) {
      expect(
        (separator.widget as ShadSeparator).margin,
        StarsDesktopThemeSpec.settingsRowSeparatorMargin,
      );
    }
    expect(tester.getSize(webSwitch).width, 44);
    expect(tester.getSize(thinkingSwitch).width, 44);
    expect(tester.getSize(maxModelTurnsButton).width, 72);
    expect(tester.widget<ShadSwitch>(webSwitch).value, isFalse);
    expect(tester.widget<ShadSwitch>(thinkingSwitch).value, isFalse);

    await tester.tap(webSwitch);
    await tester.pump();

    expect(provider.getWebSearch(), isTrue);
    expect(provider.getDeepThinking(), isFalse);
    expect(tester.widget<ShadSwitch>(webSwitch).value, isTrue);
    expect(tester.widget<ShadSwitch>(thinkingSwitch).value, isFalse);

    await tester.tap(thinkingSwitch);
    await tester.pump();

    expect(provider.getDeepThinking(), isTrue);
    expect(tester.widget<ShadSwitch>(thinkingSwitch).value, isTrue);

    await tester.tap(maxModelTurnsButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('max-model-turns-dialog')),
      findsOneWidget,
    );
    expect(find.byType(ShadInputFormField), findsOneWidget);
    final input = find.descendant(
      of: find.byKey(const ValueKey<String>('max-model-turns-input')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(input, '0');
    await tester.tap(
      find.byKey(const ValueKey<String>('max-model-turns-save')),
    );
    await tester.pumpAndSettle();

    expect(find.text('请输入 1 至 50 之间的整数。'), findsOneWidget);
    expect(savedMaxModelTurns, 15);

    await tester.enterText(input, '27');
    await tester.tap(
      find.byKey(const ValueKey<String>('max-model-turns-save')),
    );
    await tester.pumpAndSettle();

    expect(savedMaxModelTurns, 27);
    expect(
      find.byKey(const ValueKey<String>('max-model-turns-dialog')),
      findsNothing,
    );
    expect(find.text('工具请求回合上限已更新。'), findsOneWidget);
  });
}

Widget _harness(
  AiProvider provider, {
  MaxModelTurnsChanged? onMaxModelTurnsChanged,
}) {
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
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 320,
                child: ConversationModelControls(
                  provider: provider,
                  onMaxModelTurnsChanged: onMaxModelTurnsChanged,
                ),
              ),
            ),
          ),
        ),
  );
}

final class _CapabilityProvider extends AiProvider {
  _CapabilityProvider() : super(_bot);

  @override
  bool supportWebSearch() => true;

  @override
  bool supportDeepThinking() => true;

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final _bot = Bot(
  id: 'bot-1',
  name: 'Bot',
  avatar: '',
  provider: 'test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);
