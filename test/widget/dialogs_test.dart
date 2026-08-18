import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/bots/view_models/bot_skill_view_model.dart';
import 'package:stars/utils/theme.dart';

import '../support/widget_test_support.dart';

void main() {
  testWidgets('new chat uses the desktop dialog and interactive list style', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);
    await withDesktopPlatform(() async {
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
        newChatDialogHarness(
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

    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        newChatDialogHarness(
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
    List<BotSkillBinding> submittedBindings = const [];
    final skillViewModel = BotSkillViewModel(
      botId: 'bot-new',
      skillRepository: AddBotSkillRepository([
        addBotSkill('Release Notes'),
        addBotSkill('Code Review'),
      ]),
      bindingRepository: DraftBotSkillBindingRepository(),
      supportsAutoActivation: true,
    );
    addTearDown(skillViewModel.dispose);

    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        addBotDialogHarness(
          brightness: Brightness.light,
          botId: 'bot-new',
          skillViewModel: skillViewModel,
          modelLoader:
              (_) async => [
                AiModelInfo(
                  modelId: 'gpt-test',
                  providerId: 'openai',
                  inputModalities: const [InputModality.text],
                  outputModalities: const [OutputModality.text],
                  supportsWebSearch: true,
                  supportsDeepThinking: true,
                  supportsMcp: false,
                  supportsAutomaticSkillActivation: true,
                ),
              ],
          onBotAdded: (bot, skillBindings) async {
            submittedBot = bot;
            submittedBindings = skillBindings;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.byType(ShadForm), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) => widget is StarsDesktopMenu<Object?>),
        findsNWidgets(2),
      );
      final addBotClose = find.byKey(const ValueKey<String>('add-bot-close'));
      final addBotDialog = find.byKey(
        const ValueKey<String>('add-bot-dialog-content'),
      );
      expect(addBotClose, findsOneWidget);
      expect(
        find.descendant(of: addBotClose, matching: find.byIcon(LucideIcons.x)),
        findsOneWidget,
      );
      expect(tester.getSize(addBotClose), const Size.square(44));
      expect(
        tester.getRect(addBotDialog).right - tester.getRect(addBotClose).right,
        closeTo(8, 0.01),
      );
      expect(
        tester.getRect(addBotClose).top - tester.getRect(addBotDialog).top,
        closeTo(12, 0.01),
      );
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(tester.getSize(addBotDialog), const Size(840, 720));
      expect(find.text('基本信息'), findsOneWidget);
      expect(find.text('提供商信息'), findsOneWidget);
      expect(find.text('模型配置'), findsOneWidget);
      expect(find.text('技能'), findsNothing);
      expect(find.byType(ShadCard), findsNWidgets(3));

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey<String>('add-bot-api-key')),
          matching: find.byType(EditableText),
        ),
        'secret-key',
      );
      final fetchModels = find.byIcon(LucideIcons.refreshCw);
      await tester.ensureVisible(fetchModels);
      await tester.pumpAndSettle();
      await tester.tap(fetchModels);
      await tester.pumpAndSettle();

      expect(find.text('技能'), findsOneWidget);
      expect(find.byType(ShadCard), findsNWidgets(4));

      final modelMenu = find.byKey(
        const ValueKey<String>('add-bot-model-menu'),
      );
      final modelMenuButton = find.descendant(
        of: modelMenu,
        matching: find.byType(StarsDesktopIconAction),
      );
      expect(modelMenu, findsOneWidget);
      expect(modelMenuButton, findsOneWidget);
      expect(
        tester.getRect(modelMenu).right,
        closeTo(tester.getRect(modelMenuButton).right, 0.1),
      );

      await tester.tap(modelMenuButton);
      await tester.pumpAndSettle();

      final modelOption = find.widgetWithText(ShadButton, 'gpt-test');
      expect(modelOption, findsOneWidget);
      expect(
        tester.getRect(modelOption).right,
        closeTo(tester.getRect(modelMenuButton).right - 6, 1),
      );
      expect(find.textContaining('联网搜索'), findsNothing);
      expect(find.textContaining('深度思考'), findsNothing);
      expect(find.textContaining('MCP —'), findsNothing);

      await tester.tap(modelOption);
      await tester.pumpAndSettle();

      final basicSection = find.byKey(
        const ValueKey<String>('add-bot-basic-section'),
      );
      final providerSection = find.byKey(
        const ValueKey<String>('add-bot-provider-section'),
      );
      final modelSection = find.byKey(
        const ValueKey<String>('add-bot-model-section'),
      );
      final skillSection = find.byKey(
        const ValueKey<String>('add-bot-skills-section'),
      );
      for (final (section, title) in [
        (basicSection, '基本信息'),
        (providerSection, '提供商信息'),
        (modelSection, '模型配置'),
        (skillSection, '技能'),
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
      expect(
        tester.getRect(modelSection).bottom,
        lessThan(tester.getRect(skillSection).top),
      );
      expect(
        tester.widget<ShadCard>(skillSection).backgroundColor,
        tester.widget<ShadCard>(modelSection).backgroundColor,
      );

      final addSkill = find.byKey(const ValueKey<String>('add-bot-skill'));
      await tester.ensureVisible(addSkill);
      await tester.tap(addSkill);
      await tester.pumpAndSettle();
      final skillSearchField = find.byKey(
        const ValueKey<String>('add-bot-skill-search-field'),
      );
      expect(skillSearchField, findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: skillSearchField,
          matching: find.byType(EditableText),
        ),
        'release',
      );
      await tester.pump();
      expect(find.text('Release Notes'), findsOneWidget);
      expect(find.text('Code Review'), findsNothing);
      await tester.tap(
        find.byKey(
          const ValueKey<String>('select-add-bot-skill-user:Release Notes'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('add-bot-selected-skill-user:Release Notes'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('add-bot-skill-auto-user:Release Notes'),
        ),
        findsNothing,
      );
      final selectedSkill = find.byKey(
        const ValueKey<String>('add-bot-selected-skill-user:Release Notes'),
      );
      expect(
        find.descendant(of: selectedSkill, matching: find.text('自动激活')),
        findsNothing,
      );
      expect(find.text('已开启'), findsNothing);
      expect(find.text('已关闭'), findsNothing);
      expect(find.bySemanticsLabel('自动激活'), findsOneWidget);
      expect(find.text('按消息启用'), findsNothing);
      expect(find.text('始终启用'), findsNothing);
      final testSkill = find.byKey(
        const ValueKey<String>(
          'test-add-bot-skill-description-user:Release Notes',
        ),
      );
      final skillToggle = find.byKey(
        const ValueKey<String>('add-bot-skill-toggle-user:Release Notes'),
      );
      expect(
        find.descendant(of: selectedSkill, matching: find.text('测试')),
        findsOneWidget,
      );
      expect(
        tester.getRect(testSkill).right,
        lessThan(tester.getRect(skillToggle).left),
      );
      await tester.tap(testSkill);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('skill-description-test-dialog')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('cancel-skill-description-test')),
      );
      await tester.pumpAndSettle();
      final providerField = find.byKey(
        const ValueKey<String>('add-bot-provider'),
      );
      await tester.ensureVisible(providerField);
      await tester.pumpAndSettle();

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
      expect(singleLineInputSizes.map((size) => size.width).toSet(), {
        StarsDesktopThemeSpec.addBotFormFieldWidth,
      });
      expect(singleLineInputSizes.map((size) => size.height).toSet(), {
        StarsDesktopThemeSpec.botFormFieldHeight,
      });

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
      expect(
        systemPromptSize,
        const Size(StarsDesktopThemeSpec.addBotFormFieldWidth, 114),
      );

      final providerMenuAnchor = find.descendant(
        of: providerField,
        matching: find.byWidgetPredicate(
          (widget) => widget is StarsDesktopMenu<Object?>,
        ),
      );
      expect(providerMenuAnchor, findsOneWidget);

      final providerDropdownIcon = find.descendant(
        of: providerMenuAnchor,
        matching: find.byIcon(LucideIcons.chevronDown),
      );
      final providerDropdownIconRect = tester.getRect(providerDropdownIcon);
      final providerMenuButton = find.descendant(
        of: providerMenuAnchor,
        matching: find.byType(StarsDesktopIconAction),
      );
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

      await tester.tap(providerDropdownIcon);
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.byType(ShadButton), findsWidgets);
      expect(find.text('OpenAI'), findsWidgets);
      final openAIOption = find.ancestor(
        of: find.text('OpenAI'),
        matching: find.byType(ShadButton),
      );
      final openAIOptionRect = tester.getRect(openAIOption);
      expect(
        openAIOptionRect.top,
        greaterThan(providerDropdownIconRect.bottom),
      );
      expect(
        openAIOptionRect.right,
        closeTo(tester.getRect(providerMenuButton).right - 6, 1),
      );
      final anthropicOption = find.ancestor(
        of: find.text('Anthropic'),
        matching: find.byType(ShadButton),
      );
      expect(
        find.descendant(
          of: anthropicOption,
          matching: find.byIcon(LucideIcons.check),
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
      expect(
        find.byWidgetPredicate((widget) => widget is StarsDesktopMenu<Object?>),
        findsNWidgets(3),
      );
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
      await tester.tap(find.byIcon(LucideIcons.plus));
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
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();

      expect(submittedBot?.provider, 'HuggingFace');
      expect(submittedBot?.id, 'bot-new');
      expect(submittedBot?.baseURL, customHuggingFaceUrl);
      expect(submittedBot?.apiType, Bot.apiTypeHuggingface);
      expect(submittedBot?.configuredSupportsAutomaticSkillActivation, isFalse);
      expect(submittedBindings, isEmpty);
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

    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        addBotDialogHarness(
          brightness: Brightness.dark,
          textScaler: const TextScaler.linear(2),
          onBotAdded: (_, _) {
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
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('add-bot-close')),
          matching: find.byIcon(LucideIcons.x),
        ),
        findsOneWidget,
      );
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
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pump();

      expect(submitCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('添加智能体').last, warnIfMissed: false);
      await tester.pump();
      expect(submitCount, 1);

      submission.complete();
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('add bot failures use the dismissible chat error alert', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.reset);

    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        addBotDialogHarness(
          brightness: Brightness.light,
          modelLoader: (_) async => throw StateError('模型服务不可用'),
          onBotAdded: (_, _) async => throw StateError('保存失败'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey<String>('add-bot-api-key')),
          matching: find.byType(EditableText),
        ),
        'secret-key',
      );
      final submit = find.byKey(const ValueKey<String>('add-bot-submit'));
      final actions = find.byKey(
        const ValueKey<String>('add-bot-footer-actions'),
      );
      final footerSurface = find.byKey(
        const ValueKey<String>('add-bot-footer-surface'),
      );
      final submitRectBeforeError = tester.getRect(submit);
      final actionsRectBeforeError = tester.getRect(actions);
      final footerRectBeforeError = tester.getRect(footerSurface);
      final fetchModels = find.byIcon(LucideIcons.refreshCw);
      await tester.ensureVisible(fetchModels);
      await tester.tap(fetchModels);
      await tester.pumpAndSettle();

      final alert = find.byKey(const ValueKey<String>('add-bot-error-alert'));
      final errorRegion = find.byKey(
        const ValueKey<String>('add-bot-error-region'),
      );
      final message = find.byKey(
        const ValueKey<String>('add-bot-error-message'),
      );
      final dismiss = find.byKey(
        const ValueKey<String>('dismiss-add-bot-error'),
      );
      expect(alert, findsOneWidget);
      expect(errorRegion, findsOneWidget);
      expect(find.text('加载内容时出错，请稍后再试。'), findsOneWidget);
      expect(find.textContaining('模型服务不可用'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.ancestor(of: alert, matching: find.byType(StarsInlineErrorAlert)),
        findsOneWidget,
      );
      expect(tester.getSize(alert).height, lessThanOrEqualTo(58));
      expect(
        tester.getCenter(message).dy,
        closeTo(tester.getCenter(alert).dy, 1),
      );
      expect(
        tester.getCenter(message).dx,
        closeTo(tester.getCenter(alert).dx, 1),
      );
      expect(
        tester.widget<ShadAlert>(alert).crossAxisAlignment,
        CrossAxisAlignment.center,
      );
      expect(
        tester.getRect(alert).bottom,
        lessThan(tester.getRect(submit).top),
      );
      final expectedErrorWidth =
          StarsDesktopThemeSpec.addBotFormFieldWidth +
          (StarsDesktopThemeSpec.botFormSectionPadding +
                  StarsDesktopThemeSpec.botFormSectionBorderWidth) *
              2;
      expect(tester.getSize(errorRegion).width, expectedErrorWidth);
      expect(tester.getSize(alert).width, expectedErrorWidth);
      expect(tester.getRect(actions), actionsRectBeforeError);
      expect(tester.getRect(submit), submitRectBeforeError);
      expect(tester.getRect(footerSurface), footerRectBeforeError);
      expect(tester.getSize(actions).width, expectedErrorWidth);
      expect(find.descendant(of: footerSurface, matching: alert), findsNothing);
      expect(
        tester.getRect(errorRegion).bottom,
        lessThan(tester.getRect(footerSurface).top),
      );

      await tester.tap(dismiss);
      await tester.pump();
      expect(alert, findsNothing);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey<String>('add-bot-name')),
          matching: find.byType(EditableText),
        ),
        'Researcher',
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(alert, findsOneWidget);
      expect(find.text('加载内容时出错，请稍后再试。'), findsOneWidget);
      expect(find.textContaining('保存失败'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
