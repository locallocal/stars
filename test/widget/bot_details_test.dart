import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/features/bots/views/edit_bot.dart';
import 'package:stars/utils/theme.dart';

import '../support/widget_test_support.dart';

void main() {
  testWidgets('desktop bot detail displays information without form inputs', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    const systemPrompt =
        'Be helpful, concise, and include the reasoning needed to support the answer.';
    final bot = Bot(
      id: 'bot-1',
      name: 'Researcher',
      avatar: '',
      provider: 'OpenAI',
      baseURL: 'https://example.invalid',
      apiKey: 'secret',
      apiType: Bot.apiTypeOpenAI,
      model: 'gpt-test',
      systemPrompt: systemPrompt,
      parameters: const {
        Bot.parameterContextWindowTokens: 128000,
        Bot.parameterInputModalities: ['text', 'image', 'audio'],
        Bot.parameterOutputModalities: ['text'],
        Bot.parameterSupportsSkills: true,
        Bot.parameterSupportsMcp: false,
      },
      createTimestamp: DateTime(2025, 1, 2, 9, 30),
      modifyTimestamp: DateTime(2026, 2, 3, 14, 45),
    );

    await tester.pumpWidget(desktopHarness(currentIndex: 1, bot: bot));
    await tester.pumpAndSettle();

    final detailScaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey<String>('desktop-bot-detail-scaffold')),
    );
    final detailContext = tester.element(
      find.byKey(const ValueKey<String>('desktop-bot-detail-scaffold')),
    );
    final workspaceColor = StarsDesktopThemeSpec.workspaceSurface(
      detailContext,
    );
    final raisedSurface = StarsDesktopTokens.of(detailContext).raisedSurface;
    final detailContent = find.byKey(
      const ValueKey<String>('desktop-bot-detail-content'),
    );
    expect(detailScaffold.backgroundColor, workspaceColor);
    expect(
      find.byKey(const ValueKey<String>('desktop-bot-save-bar-background')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('desktop-bot-save')),
      findsNothing,
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(
      tester.getSize(detailContent).width,
      StarsDesktopThemeSpec.formContentMaxWidth +
          StarsDesktopThemeSpec.formPagePadding.horizontal,
    );
    final basicSection = find.byKey(
      const ValueKey<String>('desktop-bot-basic-section'),
    );
    final providerSection = find.byKey(
      const ValueKey<String>('desktop-bot-provider-section'),
    );
    final modelSection = find.byKey(
      const ValueKey<String>('desktop-bot-model-section'),
    );
    final tokenUsageSection = find.byKey(
      const ValueKey<String>('desktop-bot-token-usage-section'),
    );
    expect(find.byType(ShadCard), findsNWidgets(6));
    for (final section in [
      basicSection,
      providerSection,
      modelSection,
      tokenUsageSection,
    ]) {
      expect(section, findsOneWidget);
      expect(
        tester.getSize(section).width,
        StarsDesktopThemeSpec.formContentMaxWidth,
      );
      expect(tester.widget<ShadCard>(section).backgroundColor, raisedSurface);
    }
    for (final seriesSection in [
      find.byKey(const ValueKey<String>('token-usage-input-section')),
      find.byKey(const ValueKey<String>('token-usage-output-section')),
    ]) {
      expect(seriesSection, findsOneWidget);
      expect(
        find.descendant(of: seriesSection, matching: find.byType(ShadCard)),
        findsOneWidget,
      );
    }
    for (final (section, title) in [
      (basicSection, '基本信息'),
      (providerSection, '提供商信息'),
      (modelSection, '模型配置'),
      (tokenUsageSection, 'Token 用量'),
    ]) {
      final titleText = tester.widget<Text>(
        find.descendant(of: section, matching: find.text(title)),
      );
      expect(
        titleText.style?.fontSize,
        StarsDesktopThemeSpec.botFormSectionTitleFontSize,
      );
    }
    expect(
      find.descendant(
        of: tokenUsageSection,
        matching: find.byIcon(Icons.data_usage_rounded),
      ),
      findsOneWidget,
    );
    final tokenSummary = find.byKey(
      const ValueKey<String>('bot-token-usage-summary'),
    );
    final tokenShare = find.byKey(
      const ValueKey<String>('bot-conversation-token-share'),
    );
    expect(
      find.byKey(const ValueKey<String>('bot-token-usage-two-columns')),
      findsOneWidget,
    );
    expect(tokenSummary, findsOneWidget);
    expect(tokenShare, findsOneWidget);
    expect(
      tester.getTopLeft(tokenSummary).dx,
      lessThan(tester.getTopLeft(tokenShare).dx),
    );
    expect(find.text('会话 Token 占比'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('bot-conversation-token-pie-empty')),
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
    expect(
      tester.getRect(modelSection).bottom,
      lessThan(tester.getRect(tokenUsageSection).top),
    );
    expect(
      find.descendant(of: detailContent, matching: find.byType(ShadInput)),
      findsNothing,
    );
    expect(
      find.descendant(of: detailContent, matching: find.byType(ShadTextarea)),
      findsNothing,
    );
    expect(
      find.descendant(of: detailContent, matching: find.byType(TextField)),
      findsNothing,
    );
    for (final key in [
      'bot-detail-name',
      'bot-detail-creation-time',
      'bot-detail-modification-time',
      'bot-detail-provider',
      'bot-detail-api-type',
      'bot-detail-base-url',
      'bot-detail-api-key',
      'bot-detail-model',
      'bot-detail-model-context-window',
      'bot-detail-model-modalities-input',
      'bot-detail-model-modalities-output',
      'bot-detail-supports-skills',
      'bot-detail-supports-mcp',
      'bot-detail-system-prompt',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
    }
    final creationTimeDetail = find.byKey(
      const ValueKey<String>('bot-detail-creation-time'),
    );
    expect(
      find.descendant(of: creationTimeDetail, matching: find.text('创建时间')),
      findsOneWidget,
    );
    final creationTimeValue = tester.widget<SelectableText>(
      find.descendant(
        of: creationTimeDetail,
        matching: find.byType(SelectableText),
      ),
    );
    expect(creationTimeValue.data, contains('2025'));
    final modificationTimeDetail = find.byKey(
      const ValueKey<String>('bot-detail-modification-time'),
    );
    expect(
      find.descendant(of: modificationTimeDetail, matching: find.text('修改时间')),
      findsOneWidget,
    );
    final modificationTimeValue = tester.widget<SelectableText>(
      find.descendant(
        of: modificationTimeDetail,
        matching: find.byType(SelectableText),
      ),
    );
    expect(modificationTimeValue.data, contains('2026'));
    final contextWindowDetail = find.byKey(
      const ValueKey<String>('bot-detail-model-context-window'),
    );
    expect(
      find.descendant(of: contextWindowDetail, matching: find.text('模型上下文大小')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SelectableText>(
            find.descendant(
              of: contextWindowDetail,
              matching: find.byType(SelectableText),
            ),
          )
          .data,
      contains('128'),
    );
    final inputModalities = find.byKey(
      const ValueKey<String>('bot-detail-model-modalities-input'),
    );
    final outputModalities = find.byKey(
      const ValueKey<String>('bot-detail-model-modalities-output'),
    );
    expect(
      find.descendant(of: inputModalities, matching: find.text('输入')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: inputModalities,
        matching: find.byIcon(Icons.text_fields_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: inputModalities,
        matching: find.byIcon(Icons.image_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: inputModalities,
        matching: find.byIcon(Icons.audio_file_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: outputModalities, matching: find.text('输出')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: outputModalities,
        matching: find.byIcon(Icons.text_fields_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: inputModalities, matching: find.text('文本')),
      findsNothing,
    );
    expect(
      find.descendant(of: inputModalities, matching: find.byTooltip('图片')),
      findsOneWidget,
    );
    expect(
      tester.getRect(inputModalities).left,
      closeTo(tester.getRect(contextWindowDetail).left, 0.01),
    );
    expect(
      tester.getRect(outputModalities).left,
      closeTo(tester.getRect(contextWindowDetail).left, 0.01),
    );
    expect(
      tester.getRect(inputModalities).right,
      closeTo(tester.getRect(contextWindowDetail).right, 0.01),
    );
    expect(
      tester.getRect(outputModalities).right,
      closeTo(tester.getRect(contextWindowDetail).right, 0.01),
    );
    final supportsSkillsDetail = find.byKey(
      const ValueKey<String>('bot-detail-supports-skills'),
    );
    expect(
      find.descendant(of: supportsSkillsDetail, matching: find.text('支持')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: supportsSkillsDetail,
        matching: find.byIcon(LucideIcons.wrench),
      ),
      findsOneWidget,
    );
    final supportsMcpDetail = find.byKey(
      const ValueKey<String>('bot-detail-supports-mcp'),
    );
    expect(
      find.descendant(of: supportsMcpDetail, matching: find.text('不支持')),
      findsOneWidget,
    );
    expect(find.text('https://example.invalid'), findsOneWidget);
    expect(find.text(systemPrompt), findsOneWidget);

    final providerDetail = find.byKey(
      const ValueKey<String>('bot-detail-provider'),
    );
    final providerLabel = find.descendant(
      of: providerDetail,
      matching: find.text('供应商'),
    );
    final providerValue = find.descendant(
      of: providerDetail,
      matching: find.text('OpenAI'),
    );
    expect(
      tester.getTopLeft(providerLabel).dx,
      lessThan(tester.getTopLeft(providerValue).dx),
    );
    final providerIcon = find.descendant(
      of: providerDetail,
      matching: find.byIcon(Icons.business_outlined),
    );
    expect(
      tester.widget<Icon>(providerIcon).size,
      StarsDesktopThemeSpec.settingsRowIconSize,
    );
    expect(
      tester.getSize(providerDetail).height,
      StarsDesktopThemeSpec.settingsRowMinHeight +
          StarsDesktopThemeSpec.settingsRowPadding.vertical,
    );
    final providerSeparators = find.descendant(
      of: providerSection,
      matching: find.byType(ShadSeparator),
    );
    expect(providerSeparators, findsNWidgets(3));
    expect(
      tester.widget<ShadSeparator>(providerSeparators.first).margin,
      StarsDesktopThemeSpec.settingsRowSeparatorMargin,
    );

    final systemPromptDetail = find.byKey(
      const ValueKey<String>('bot-detail-system-prompt'),
    );
    final systemPromptLabel = find.descendant(
      of: systemPromptDetail,
      matching: find.text('系统提示词'),
    );
    final systemPromptValue = find.descendant(
      of: systemPromptDetail,
      matching: find.text(systemPrompt),
    );
    expect(
      tester.getSize(systemPromptValue).width,
      greaterThan(StarsDesktopThemeSpec.settingsRowValueMaxWidth),
    );
    expect(
      tester.getTopLeft(systemPromptValue).dy,
      greaterThan(tester.getBottomLeft(systemPromptLabel).dy),
    );
    expect(
      tester.getTopLeft(systemPromptValue).dx,
      tester.getTopLeft(systemPromptLabel).dx,
    );

    final apiKeyDetail = find.byKey(
      const ValueKey<String>('bot-detail-api-key'),
    );
    expect(
      find.descendant(of: apiKeyDetail, matching: find.text('••••••••••••')),
      findsOneWidget,
    );
    expect(find.text('secret'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('bot-detail-toggle-api-key')),
    );
    await tester.pump();
    expect(
      find.descendant(of: apiKeyDetail, matching: find.text('secret')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('desktop-toolbar-inspector')),
      findsNothing,
    );
    expect(find.byIcon(Icons.vertical_split_outlined), findsNothing);
  });

  testWidgets('desktop bot provider settings are read-only and preserved', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    final bot = Bot(
      id: 'bot-1',
      name: 'Researcher',
      avatar: '',
      provider: 'OpenAI',
      baseURL: 'https://example.invalid',
      apiKey: 'secret',
      apiType: Bot.apiTypeOpenAI,
      model: 'gpt-test',
      systemPrompt: 'Be helpful',
      parameters: const {
        Bot.parameterInputModalities: ['text', 'image'],
        Bot.parameterOutputModalities: ['text'],
      },
      createTimestamp: DateTime(2026),
      modifyTimestamp: DateTime(2026),
    );
    Bot? updatedBot;

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: EditBotPage(
                bot: bot,
                embedded: true,
                onBotUpdated: (updated) async => updatedBot = updated,
                onBotDeleted: () async {},
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    final expectedFieldWidth =
        StarsDesktopThemeSpec.formContentMaxWidth -
        (StarsDesktopThemeSpec.botFormSectionPadding +
                StarsDesktopThemeSpec.botFormSectionBorderWidth) *
            2;
    expect(
      find.byKey(const ValueKey<String>('desktop-bot-token-usage-section')),
      findsNothing,
    );
    const readOnlyFieldKeys = [
      'desktop-bot-provider',
      'desktop-bot-api-type',
      'desktop-bot-base-url',
      'desktop-bot-api-key',
      'desktop-bot-model',
    ];
    for (final key in readOnlyFieldKeys) {
      final inputFinder = find.byKey(ValueKey<String>(key));
      final input = tester.widget<ShadInput>(inputFinder);
      expect(input.readOnly, isTrue, reason: '$key should be read-only');
      expect(tester.getSize(inputFinder).width, expectedFieldWidth);
      expect(
        tester.getSize(inputFinder).height,
        StarsDesktopThemeSpec.botFormFieldHeight,
      );
      final editableText = find.descendant(
        of: inputFinder,
        matching: find.byType(EditableText),
      );
      expect(
        tester.getRect(editableText).center.dy,
        closeTo(tester.getRect(inputFinder).center.dy, 0.5),
      );
      input.controller!.text = 'changed';
    }
    final nameInput = find.byKey(const ValueKey<String>('desktop-bot-name'));
    expect(tester.widget<ShadInput>(nameInput).readOnly, isFalse);
    expect(tester.getSize(nameInput).width, expectedFieldWidth);
    expect(
      tester.getSize(nameInput).height,
      StarsDesktopThemeSpec.botFormFieldHeight,
    );
    final nameEditableText = find.descendant(
      of: nameInput,
      matching: find.byType(EditableText),
    );
    expect(
      tester.getRect(nameEditableText).center.dy,
      closeTo(tester.getRect(nameInput).center.dy, 0.5),
    );
    final systemPrompt = find.byType(ShadTextarea);
    final systemPromptWidget = tester.widget<ShadTextarea>(systemPrompt);
    expect(systemPromptWidget.readOnly, false);
    expect(systemPromptWidget.alignment, isNull);
    expect(tester.getSize(systemPrompt).width, expectedFieldWidth);

    await tester.tap(find.byKey(const ValueKey<String>('desktop-bot-save')));
    await tester.pumpAndSettle();

    expect(updatedBot?.provider, bot.provider);
    expect(updatedBot?.apiType, bot.apiType);
    expect(updatedBot?.baseURL, bot.baseURL);
    expect(updatedBot?.apiKey, bot.apiKey);
    expect(updatedBot?.model, bot.model);
    expect(updatedBot?.configuredInputModalities, [
      InputModality.text,
      InputModality.image,
    ]);
    expect(updatedBot?.configuredOutputModalities, [OutputModality.text]);
  });

  testWidgets('desktop bot save button shows saving and saved states', (
    tester,
  ) async {
    final saveCompleter = Completer<void>();
    final bot = Bot(
      id: 'bot-save-status',
      name: 'Researcher',
      avatar: '',
      provider: 'OpenAI',
      baseURL: 'https://example.invalid',
      apiKey: 'secret',
      apiType: Bot.apiTypeOpenAI,
      model: 'gpt-test',
      systemPrompt: 'Be helpful',
      createTimestamp: DateTime(2026),
      modifyTimestamp: DateTime(2026),
    );

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: EditBotPage(
                bot: bot,
                embedded: true,
                onBotUpdated: (_) => saveCompleter.future,
                onBotDeleted: () async {},
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButtonFinder = find.byKey(
      const ValueKey<String>('desktop-bot-save'),
    );
    await tester.tap(saveButtonFinder);
    await tester.pump();

    expect(find.text('保存中...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<ShadButton>(saveButtonFinder).enabled, isFalse);

    saveCompleter.complete();
    await tester.pumpAndSettle();

    expect(find.text('已保存'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(tester.widget<ShadButton>(saveButtonFinder).enabled, isFalse);

    final nameField = find.descendant(
      of: find.byKey(const ValueKey<String>('desktop-bot-name')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(nameField, 'Updated Researcher');
    await tester.pump();

    expect(find.text('保存修改'), findsOneWidget);
    expect(tester.widget<ShadButton>(saveButtonFinder).enabled, isTrue);
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
      desktopHarness(
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
