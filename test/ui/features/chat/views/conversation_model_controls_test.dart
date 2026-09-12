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
    tester.view.physicalSize = const Size(420, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = _CapabilityProvider();
    var savedMaxModelTurns = 15;
    var showReasoning = true;
    var showVerificationStatus = true;
    var showExecutionStatus = true;
    var strictGroundingMode = false;

    await tester.pumpWidget(
      _harness(
        provider,
        showReasoning: showReasoning,
        showVerificationStatus: showVerificationStatus,
        showExecutionStatus: showExecutionStatus,
        strictGroundingMode: strictGroundingMode,
        onShowReasoningChanged: (value) async {
          showReasoning = value;
        },
        onShowVerificationStatusChanged: (value) async {
          showVerificationStatus = value;
        },
        onShowExecutionStatusChanged: (value) async {
          showExecutionStatus = value;
        },
        onStrictGroundingModeChanged: (value) async {
          strictGroundingMode = value;
        },
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
    final reasoningRow = find.byKey(
      const ValueKey<String>('conversation-reasoning-row'),
    );
    final reasoningSwitch = find.byKey(
      const ValueKey<String>('conversation-reasoning-toggle'),
    );
    final verificationStatusRow = find.byKey(
      const ValueKey<String>('conversation-verification-status-row'),
    );
    final verificationStatusSwitch = find.byKey(
      const ValueKey<String>('conversation-verification-status-toggle'),
    );
    final executionStatusRow = find.byKey(
      const ValueKey<String>('conversation-execution-status-row'),
    );
    final executionStatusSwitch = find.byKey(
      const ValueKey<String>('conversation-execution-status-toggle'),
    );
    final strictGroundingRow = find.byKey(
      const ValueKey<String>('conversation-strict-grounding-row'),
    );
    final strictGroundingSwitch = find.byKey(
      const ValueKey<String>('conversation-strict-grounding-toggle'),
    );
    final maxModelTurnsRow = find.byKey(
      const ValueKey<String>('max-model-turns-row'),
    );
    final maxModelTurnsButton = find.byKey(
      const ValueKey<String>('max-model-turns-edit'),
    );
    expect(webRow, findsOneWidget);
    expect(thinkingRow, findsOneWidget);
    expect(reasoningRow, findsOneWidget);
    expect(verificationStatusRow, findsOneWidget);
    expect(executionStatusRow, findsOneWidget);
    expect(strictGroundingRow, findsOneWidget);
    expect(maxModelTurnsRow, findsOneWidget);
    expect(find.byType(StarsInspectorInfoRow), findsNWidgets(7));
    expect(find.byType(ShadSwitch), findsNWidgets(6));
    expect(find.byType(ShadButton), findsOneWidget);
    expect(find.text('联网搜索'), findsOneWidget);
    expect(find.text('允许模型搜索互联网以获取最新信息。'), findsOneWidget);
    expect(find.text('深度思考'), findsOneWidget);
    expect(find.text('允许模型在回复前进行更深入的推理。'), findsOneWidget);
    expect(find.text('思考过程'), findsOneWidget);
    expect(find.text('在智能体会话消息中显示思考过程。'), findsOneWidget);
    expect(find.text('核验检查'), findsOneWidget);
    expect(find.text('在智能体会话消息中显示核验状态和详情。'), findsOneWidget);
    expect(find.text('会话执行状态'), findsOneWidget);
    expect(find.text('严格验证模式'), findsOneWidget);
    expect(find.text('在会话内容中显示执行状态。'), findsOneWidget);
    expect(find.text('隐藏未验证的事实回答，同时保留验证详情和工具失败原因。'), findsOneWidget);
    expect(find.text('工具请求回合上限'), findsOneWidget);
    expect(find.text('单次回复中允许模型请求工具的最大回合数。此设置仅应用于当前会话。'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    final inspectorRows = find.byType(StarsInspectorInfoRow);
    for (var index = 0; index < 7; index++) {
      final row = tester.widget<StarsInspectorInfoRow>(inspectorRows.at(index));
      expect(row.layout, StarsInspectorInfoRowLayout.settings);
      expect(row.description, isNotEmpty);
    }
    expect(
      tester.getRect(find.text('联网搜索')).left,
      closeTo(tester.getRect(find.text('深度思考')).left, 0.01),
    );
    expect(
      tester.getRect(find.text('深度思考')).left,
      closeTo(tester.getRect(find.text('思考过程')).left, 0.01),
    );
    expect(
      tester.getRect(find.text('思考过程')).left,
      closeTo(tester.getRect(find.text('核验检查')).left, 0.01),
    );
    expect(
      tester.getRect(find.text('核验检查')).left,
      closeTo(tester.getRect(find.text('会话执行状态')).left, 0.01),
    );
    expect(
      tester.getRect(find.text('深度思考')).left,
      closeTo(tester.getRect(find.text('严格验证模式')).left, 0.01),
    );
    expect(
      tester.getRect(webRow).right - tester.getRect(webSwitch).right,
      StarsDesktopThemeSpec.settingsRowPadding.right,
    );
    expect(
      tester.getRect(thinkingRow).right - tester.getRect(thinkingSwitch).right,
      StarsDesktopThemeSpec.settingsRowPadding.right,
    );
    expect(
      tester.getRect(reasoningRow).right -
          tester.getRect(reasoningSwitch).right,
      StarsDesktopThemeSpec.settingsRowPadding.right,
    );
    expect(
      tester.getRect(verificationStatusRow).right -
          tester.getRect(verificationStatusSwitch).right,
      StarsDesktopThemeSpec.settingsRowPadding.right,
    );
    expect(
      tester.getRect(executionStatusRow).right -
          tester.getRect(executionStatusSwitch).right,
      StarsDesktopThemeSpec.settingsRowPadding.right,
    );
    expect(
      tester.getRect(strictGroundingRow).right -
          tester.getRect(strictGroundingSwitch).right,
      StarsDesktopThemeSpec.settingsRowPadding.right,
    );
    expect(
      tester.getTopLeft(reasoningRow).dy,
      greaterThan(tester.getTopLeft(thinkingRow).dy),
    );
    expect(
      tester.getTopLeft(verificationStatusRow).dy,
      greaterThan(tester.getTopLeft(reasoningRow).dy),
    );
    expect(
      tester.getTopLeft(executionStatusRow).dy,
      greaterThan(tester.getTopLeft(verificationStatusRow).dy),
    );
    expect(
      tester.getTopLeft(strictGroundingRow).dy,
      greaterThan(tester.getTopLeft(executionStatusRow).dy),
    );
    expect(
      tester.getTopLeft(maxModelTurnsRow).dy,
      greaterThan(tester.getTopLeft(strictGroundingRow).dy),
    );
    expect(
      tester.getRect(maxModelTurnsRow).right -
          tester.getRect(maxModelTurnsButton).right,
      StarsDesktopThemeSpec.settingsRowPadding.right,
    );
    final separators = find.byType(ShadSeparator);
    expect(separators, findsNWidgets(6));
    for (final separator in separators.evaluate()) {
      expect(
        (separator.widget as ShadSeparator).margin,
        StarsDesktopThemeSpec.settingsRowSeparatorMargin,
      );
    }
    expect(tester.getSize(webSwitch).width, 44);
    expect(tester.getSize(thinkingSwitch).width, 44);
    expect(tester.getSize(reasoningSwitch).width, 44);
    expect(tester.getSize(verificationStatusSwitch).width, 44);
    expect(tester.getSize(executionStatusSwitch).width, 44);
    expect(tester.getSize(strictGroundingSwitch).width, 44);
    expect(tester.getSize(maxModelTurnsButton).width, 72);
    expect(tester.widget<ShadSwitch>(webSwitch).value, isFalse);
    expect(tester.widget<ShadSwitch>(thinkingSwitch).value, isFalse);
    expect(tester.widget<ShadSwitch>(reasoningSwitch).value, isTrue);
    expect(tester.widget<ShadSwitch>(verificationStatusSwitch).value, isTrue);
    expect(tester.widget<ShadSwitch>(executionStatusSwitch).value, isTrue);
    expect(tester.widget<ShadSwitch>(strictGroundingSwitch).value, isFalse);

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

    await tester.tap(reasoningSwitch);
    await tester.pumpAndSettle();
    expect(showReasoning, isFalse);

    await tester.tap(verificationStatusSwitch);
    await tester.pumpAndSettle();
    expect(showVerificationStatus, isFalse);

    await tester.tap(executionStatusSwitch);
    await tester.pumpAndSettle();
    expect(showExecutionStatus, isFalse);

    await tester.pumpWidget(
      _harness(
        provider,
        showReasoning: showReasoning,
        showVerificationStatus: showVerificationStatus,
        showExecutionStatus: showExecutionStatus,
        strictGroundingMode: strictGroundingMode,
        onShowReasoningChanged: (value) async {
          showReasoning = value;
        },
        onShowVerificationStatusChanged: (value) async {
          showVerificationStatus = value;
        },
        onShowExecutionStatusChanged: (value) async {
          showExecutionStatus = value;
        },
        onStrictGroundingModeChanged: (value) async {
          strictGroundingMode = value;
        },
        onMaxModelTurnsChanged: (value) async {
          savedMaxModelTurns = value;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ShadSwitch>(reasoningSwitch).value, isFalse);
    expect(tester.widget<ShadSwitch>(verificationStatusSwitch).value, isFalse);
    expect(tester.widget<ShadSwitch>(executionStatusSwitch).value, isFalse);

    await tester.tap(strictGroundingSwitch);
    await tester.pumpAndSettle();
    expect(strictGroundingMode, isTrue);

    await tester.pumpWidget(
      _harness(
        provider,
        showReasoning: showReasoning,
        showVerificationStatus: showVerificationStatus,
        showExecutionStatus: showExecutionStatus,
        strictGroundingMode: strictGroundingMode,
        onShowReasoningChanged: (value) async {
          showReasoning = value;
        },
        onShowVerificationStatusChanged: (value) async {
          showVerificationStatus = value;
        },
        onShowExecutionStatusChanged: (value) async {
          showExecutionStatus = value;
        },
        onStrictGroundingModeChanged: (value) async {
          strictGroundingMode = value;
        },
        onMaxModelTurnsChanged: (value) async {
          savedMaxModelTurns = value;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ShadSwitch>(strictGroundingSwitch).value, isTrue);

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
  bool showReasoning = true,
  bool showVerificationStatus = true,
  bool showExecutionStatus = true,
  bool strictGroundingMode = false,
  ConversationPreferenceChanged? onShowReasoningChanged,
  ConversationPreferenceChanged? onShowVerificationStatusChanged,
  ConversationPreferenceChanged? onShowExecutionStatusChanged,
  ConversationPreferenceChanged? onStrictGroundingModeChanged,
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
                  showReasoning: showReasoning,
                  showVerificationStatus: showVerificationStatus,
                  showExecutionStatus: showExecutionStatus,
                  strictGroundingMode: strictGroundingMode,
                  onShowReasoningChanged: onShowReasoningChanged,
                  onShowVerificationStatusChanged:
                      onShowVerificationStatusChanged,
                  onShowExecutionStatusChanged: onShowExecutionStatusChanged,
                  onStrictGroundingModeChanged: onStrictGroundingModeChanged,
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
