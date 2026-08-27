
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/create_chat.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/bots/view_models/bot_list_view_model.dart';
import 'package:stars/ui/features/bots/views/bots.dart';
import 'package:stars/ui/features/bots/views/edit_bot.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

import '../support/widget_test_support.dart';

void main() {
  testWidgets('desktop bot cards show usage, model, and timestamp metrics', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.reset);

    final timestamp = DateTime(2025);
    final modifiedAt = DateTime(2026);
    final bot = Bot(
      id: 'bot-1',
      name: '测试智能体',
      avatar: '',
      provider: 'OpenAI',
      baseURL: '',
      apiKey: '',
      apiType: Bot.apiTypeOpenAI,
      model: 'gpt-test',
      systemPrompt: '',
      parameters: const {
        Bot.parameterContextWindowTokens: 128000,
        Bot.parameterInputModalities: ['text', 'image', 'audio'],
        Bot.parameterOutputModalities: ['text'],
        Bot.parameterMcpServers: ['mcp-search', 'mcp-docs'],
        Bot.parameterMcpTools: [
          {
            'server_id': 'mcp-search',
            'remote_name': 'search',
            'requires_approval': true,
          },
        ],
      },
      createTimestamp: timestamp,
      modifyTimestamp: modifiedAt,
    );
    final bindingRepository = BotCardTestBindingRepository();
    await bindingRepository.save(
      BotSkillBinding(
        botId: bot.id,
        skillId: 'user:writer',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await bindingRepository.save(
      BotSkillBinding(
        botId: bot.id,
        skillId: 'user:reviewer',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    final viewModel = BotListViewModel(
      botRepository: BotCardTestBotRepository([bot]),
      createChat: CreateChat(chatRepository: BotCardTestChatRepository()),
      aiProviderRepository: UnusedAiProviderRepository(),
      attachmentRepository: UnusedAttachmentRepository(),
      botSkillBindingRepository: bindingRepository,
      messageRepository: BotCardTestMessageRepository({
        bot.id: const ModelTokenUsage(totalTokens: 1500),
      }),
      mcpServerRepository: BotCardTestMcpRepository([
        botCardMcpServer('mcp-search', 'Search'),
        botCardMcpServer('mcp-docs', 'Docs'),
      ]),
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: ContactsPage(viewModel: viewModel, onBotSelected: (_) {}),
              ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(const ValueKey<String>('desktop-bot-card-bot-1'));
      final tokenMetric = find.byKey(
        const ValueKey<String>('bot-card-token-total-bot-1'),
      );
      final tokenMetricIcon = find.descendant(
        of: tokenMetric,
        matching: find.byIcon(Icons.data_usage_rounded),
      );
      final skillMetric = find.byKey(
        const ValueKey<String>('bot-card-skill-count-bot-1'),
      );
      final mcpMetric = find.byKey(
        const ValueKey<String>('bot-card-mcp-count-bot-1'),
      );
      final contextWindowMetric = find.byKey(
        const ValueKey<String>('bot-card-context-window-bot-1'),
      );
      final creationTimeMetric = find.byKey(
        const ValueKey<String>('bot-card-creation-time-bot-1'),
      );
      final modificationTimeMetric = find.byKey(
        const ValueKey<String>('bot-card-modification-time-bot-1'),
      );
      final avatar = find.descendant(
        of: card,
        matching: find.byType(ShadAvatar),
      );
      final botName = find.descendant(of: card, matching: find.text('测试智能体'));
      final identity = find.byKey(
        const ValueKey<String>('bot-card-identity-bot-1'),
      );
      final providerAndModel = find.descendant(
        of: card,
        matching: find.text('OpenAI · gpt-test'),
      );
      final menuButton = find.byKey(
        const ValueKey<String>('desktop-bot-menu-button-bot-1'),
      );
      final menuIcon = find.descendant(
        of: menuButton,
        matching: find.byIcon(LucideIcons.ellipsis),
      );
      final footer = find.byKey(
        const ValueKey<String>('desktop-bot-card-footer-bot-1'),
      );
      final modalities = find.byKey(
        const ValueKey<String>('bot-card-modalities-bot-1'),
      );
      final modelFeatures = find.byKey(
        const ValueKey<String>('bot-card-model-features-bot-1'),
      );
      final usageFeatures = find.byKey(
        const ValueKey<String>('bot-card-usage-features-bot-1'),
      );
      final informationPanel = find.byKey(
        const ValueKey<String>('bot-card-information-panel-bot-1'),
      );
      final informationDivider = find.byKey(
        const ValueKey<String>('bot-card-information-divider-bot-1'),
      );
      expect(card, findsOneWidget);
      expect(tester.getSize(card).height, 212);
      expect(tokenMetric, findsOneWidget);
      expect(tokenMetricIcon, findsOneWidget);
      expect(skillMetric, findsOneWidget);
      expect(mcpMetric, findsOneWidget);
      expect(contextWindowMetric, findsOneWidget);
      expect(creationTimeMetric, findsOneWidget);
      expect(modificationTimeMetric, findsOneWidget);
      expect(avatar, findsOneWidget);
      expect(botName, findsOneWidget);
      expect(identity, findsOneWidget);
      expect(providerAndModel, findsOneWidget);
      expect(menuButton, findsOneWidget);
      expect(menuIcon, findsOneWidget);
      expect(footer, findsOneWidget);
      expect(modelFeatures, findsOneWidget);
      expect(usageFeatures, findsOneWidget);
      expect(modalities, findsOneWidget);
      expect(informationPanel, findsOneWidget);
      expect(informationDivider, findsOneWidget);
      expect(
        tester.widget<Container>(informationPanel).decoration,
        BoxDecoration(
          color: StarsDesktopThemeSpec.controlFill(
            tester.element(informationPanel),
          ),
          borderRadius: StarsDesktopThemeSpec.controlRadius,
        ),
      );
      final inputModalities = find.byKey(
        const ValueKey<String>('bot-card-modalities-bot-1-input'),
      );
      final outputModalities = find.byKey(
        const ValueKey<String>('bot-card-modalities-bot-1-output'),
      );
      expect(inputModalities, findsOneWidget);
      expect(outputModalities, findsOneWidget);
      final inputDirectionIcon = find.descendant(
        of: modalities,
        matching: find.byIcon(Icons.input_rounded),
      );
      final outputDirectionIcon = find.descendant(
        of: modalities,
        matching: find.byIcon(Icons.output_rounded),
      );
      expect(inputDirectionIcon, findsOneWidget);
      expect(outputDirectionIcon, findsOneWidget);
      expect(
        find.descendant(
          of: modalities,
          matching: find.byIcon(Icons.text_fields_rounded),
        ),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: modalities,
          matching: find.byIcon(Icons.image_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: modalities,
          matching: find.byIcon(Icons.audio_file_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: modalities, matching: find.textContaining('文本')),
        findsNothing,
      );
      expect(
        tester.getCenter(inputModalities).dy,
        closeTo(tester.getCenter(outputModalities).dy, 0.01),
      );
      expect(
        tester.getTopLeft(contextWindowMetric).dy,
        closeTo(tester.getTopLeft(inputModalities).dy, 0.01),
      );
      for (final direction in ['output', 'input']) {
        final group =
            direction == 'output' ? outputModalities : inputModalities;
        final directionIcon = find.descendant(
          of: group,
          matching: find.byIcon(
            direction == 'output' ? Icons.output_rounded : Icons.input_rounded,
          ),
        );
        final separator = find.byKey(
          ValueKey<String>('bot-card-modalities-bot-1-$direction-separator'),
        );
        final textFeature = find.byKey(
          ValueKey<String>('bot-card-modalities-bot-1-$direction-value-text'),
        );
        expect(separator, findsOneWidget);
        expect(
          tester.getRect(directionIcon).right,
          lessThan(tester.getRect(separator).left),
        );
        expect(
          tester.getRect(separator).right,
          lessThan(tester.getRect(textFeature).left),
        );
      }
      final contextFeatureIcon = find.descendant(
        of: contextWindowMetric,
        matching: find.byIcon(LucideIcons.braces),
      );
      final contextWindowSeparator = find.byKey(
        const ValueKey<String>('bot-card-context-window-separator-bot-1'),
      );
      final contextWindowValue = find.descendant(
        of: contextWindowMetric,
        matching: find.byType(Text),
      );
      final inputAudioFeature = find.byKey(
        const ValueKey<String>('bot-card-modalities-bot-1-input-value-audio'),
      );
      expect(contextWindowSeparator, findsOneWidget);
      expect(
        tester.getRect(contextFeatureIcon).right,
        lessThan(tester.getRect(contextWindowSeparator).left),
      );
      expect(
        tester.getRect(contextWindowSeparator).right,
        lessThan(tester.getRect(contextWindowValue).left),
      );
      expect(
        tester.getRect(inputDirectionIcon).left -
            tester.getRect(contextWindowValue).right,
        greaterThanOrEqualTo(24),
      );
      expect(
        tester.getRect(outputDirectionIcon).left -
            tester.getRect(inputAudioFeature).right,
        greaterThanOrEqualTo(24),
      );
      final cardRect = tester.getRect(card);
      final avatarRect = tester.getRect(avatar);
      final footerRect = tester.getRect(footer);
      final iconTopInset = avatarRect.top - cardRect.top;
      final footerBottomInset = cardRect.bottom - footerRect.bottom;
      expect(iconTopInset, greaterThanOrEqualTo(18));
      expect(footerBottomInset, closeTo(19, 0.5));
      expect(
        cardRect.right - tester.getRect(menuIcon).right,
        closeTo(avatarRect.left - cardRect.left, 0.5),
      );
      expect(
        tester.getTopRight(avatar).dx,
        lessThan(tester.getTopLeft(botName).dx),
      );
      expect(
        tester.getCenter(avatar).dy,
        closeTo(tester.getCenter(identity).dy, 0.5),
      );
      expect(
        tester.getTopLeft(informationPanel).dy -
            tester.getBottomLeft(avatar).dy,
        greaterThanOrEqualTo(12),
      );
      expect(
        tester.getTopLeft(contextWindowMetric).dy -
            tester.getTopLeft(informationPanel).dy,
        closeTo(9, 0.5),
      );
      expect(
        tester.getTopLeft(contextWindowMetric).dx -
            tester.getTopLeft(avatar).dx,
        closeTo(10, 0.5),
      );
      expect(
        tester.getTopLeft(tokenMetric).dy -
            tester.getBottomLeft(contextWindowMetric).dy,
        closeTo(17, 0.5),
      );
      expect(
        tester.getTopLeft(tokenMetric).dx,
        closeTo(tester.getTopLeft(contextWindowMetric).dx, 0.5),
      );
      expect(
        tester.getTopLeft(skillMetric).dx,
        closeTo(tester.getTopLeft(inputModalities).dx, 0.5),
      );
      expect(
        tester.getTopLeft(mcpMetric).dx,
        closeTo(tester.getTopLeft(outputModalities).dx, 0.5),
      );
      expect(
        tester.getCenter(tokenMetric).dy,
        closeTo(tester.getCenter(skillMetric).dy, 0.5),
      );
      expect(
        tester.getCenter(skillMetric).dy,
        closeTo(tester.getCenter(mcpMetric).dy, 0.5),
      );
      expect(
        tester.getTopLeft(tokenMetric).dx,
        lessThan(tester.getTopLeft(skillMetric).dx),
      );
      expect(
        tester.getTopLeft(skillMetric).dx,
        lessThan(tester.getTopLeft(mcpMetric).dx),
      );
      expect(
        tester.getTopLeft(providerAndModel).dx,
        closeTo(tester.getTopLeft(botName).dx, 0.5),
      );
      expect(
        tester.getTopLeft(providerAndModel).dy,
        greaterThan(tester.getBottomLeft(botName).dy),
      );
      expect(
        tester.getCenter(menuButton).dy,
        closeTo(tester.getCenter(creationTimeMetric).dy, 0.5),
      );
      expect(
        tester.getTopLeft(creationTimeMetric).dx,
        closeTo(tester.getTopLeft(avatar).dx, 0.5),
      );
      expect(
        tester.getRect(creationTimeMetric).right,
        lessThan(tester.getRect(modificationTimeMetric).left),
      );
      expect(
        tester.getCenter(modificationTimeMetric).dy,
        closeTo(tester.getCenter(creationTimeMetric).dy, 0.5),
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(of: tokenMetric, matching: find.byType(Text)),
            )
            .data,
        isNot(contains('Token 总量')),
      );
      expect(
        find.descendant(of: skillMetric, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: mcpMetric, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: contextWindowMetric, matching: find.text('—')),
        findsNothing,
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: creationTimeMetric,
                matching: find.byType(Text),
              ),
            )
            .data,
        contains('2025'),
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: modificationTimeMetric,
                matching: find.byType(Text),
              ),
            )
            .data,
        contains('2026'),
      );
      expect(
        tester
            .widget<Tooltip>(
              find.descendant(of: tokenMetric, matching: find.byType(Tooltip)),
            )
            .message,
        'Token 总量',
      );
      expect(
        tester
            .widget<Tooltip>(
              find.descendant(of: skillMetric, matching: find.byType(Tooltip)),
            )
            .message,
        '技能',
      );
      expect(
        tester
            .widget<Tooltip>(
              find.descendant(of: mcpMetric, matching: find.byType(Tooltip)),
            )
            .message,
        'MCP 服务器',
      );
      expect(
        tester
            .widget<Tooltip>(
              find.descendant(
                of: contextWindowMetric,
                matching: find.byType(Tooltip),
              ),
            )
            .message,
        '模型上下文大小',
      );
      expect(
        tester
            .widget<Tooltip>(
              find.descendant(
                of: creationTimeMetric,
                matching: find.byType(Tooltip),
              ),
            )
            .message,
        '创建时间',
      );
      final tokenIcon = find.descendant(
        of: tokenMetric,
        matching: find.byIcon(Icons.data_usage_rounded),
      );
      final skillIcon = find.descendant(
        of: skillMetric,
        matching: find.byIcon(LucideIcons.wrench),
      );
      final mcpIcon = find.descendant(
        of: mcpMetric,
        matching: find.byIcon(Icons.hub_outlined),
      );
      final contextWindowIcon = find.descendant(
        of: contextWindowMetric,
        matching: find.byIcon(LucideIcons.braces),
      );
      final creationTimeIcon = find.descendant(
        of: creationTimeMetric,
        matching: find.byIcon(LucideIcons.clock3),
      );
      final modificationTimeIcon = find.descendant(
        of: modificationTimeMetric,
        matching: find.byIcon(LucideIcons.history),
      );
      final usageMetrics = [tokenMetric, skillMetric, mcpMetric];
      final usageIcons = [tokenIcon, skillIcon, mcpIcon];
      final usageSeparatorKeys = [
        'bot-card-token-total-separator-bot-1',
        'bot-card-skill-count-separator-bot-1',
        'bot-card-mcp-count-separator-bot-1',
      ];
      for (var index = 0; index < usageMetrics.length; index += 1) {
        final separator = find.byKey(
          ValueKey<String>(usageSeparatorKeys[index]),
        );
        final value = find.descendant(
          of: usageMetrics[index],
          matching: find.byType(Text),
        );
        expect(separator, findsOneWidget);
        expect(
          tester.getRect(usageIcons[index]).right,
          lessThan(tester.getRect(separator).left),
        );
        expect(
          tester.getRect(separator).right,
          lessThan(tester.getRect(value).left),
        );
      }
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);

      Future<void> expectTooltip(Finder icon, String name) async {
        await mouse.moveTo(tester.getCenter(icon));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(name), findsOneWidget);
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
      }

      await expectTooltip(tokenIcon, 'Token 总量');
      await expectTooltip(skillIcon, '技能');
      await expectTooltip(mcpIcon, 'MCP 服务器');
      await expectTooltip(contextWindowIcon, '模型上下文大小');
      await expectTooltip(creationTimeIcon, '创建时间');
      await expectTooltip(modificationTimeIcon, '修改时间');
      expect(find.byIcon(LucideIcons.arrowUpRight), findsNothing);
      expect(
        viewModel.metricsFor(bot.id).tokenUsage.effectiveTotalTokens,
        1500,
      );
      expect(viewModel.metricsFor(bot.id).skillCount, 2);
      expect(viewModel.metricsFor(bot.id).contextWindowTokens, 128000);
      expect(viewModel.metricsFor(bot.id).mcpServerNames, ['Docs', 'Search']);
      final addBotButton =
          find
              .ancestor(
                of: find.text('添加智能体'),
                matching: find.byType(ShadButton),
              )
              .first;
      final addBotButtonWidget = tester.widget<ShadButton>(addBotButton);
      expect(addBotButtonWidget.size, isNull);
      expect(addBotButtonWidget.height, isNull);
      expect(tester.getSize(addBotButton).height, 40);

      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(informationPanel).left,
        greaterThan(tester.getRect(card).left),
      );
      expect(
        tester.getRect(informationPanel).right,
        lessThan(tester.getRect(card).right),
      );
    });
  });

  test('bot list persists Skill bindings with a newly added Bot', () async {
    final botRepository = BotCardTestBotRepository(const []);
    final bindingRepository = BotCardTestBindingRepository();
    final viewModel = BotListViewModel(
      botRepository: botRepository,
      createChat: CreateChat(chatRepository: BotCardTestChatRepository()),
      aiProviderRepository: UnusedAiProviderRepository(),
      attachmentRepository: UnusedAttachmentRepository(),
      botSkillBindingRepository: bindingRepository,
    );
    addTearDown(viewModel.dispose);
    final timestamp = DateTime(2026);
    final bot = Bot(
      id: 'bot-new',
      name: 'Researcher',
      avatar: '',
      provider: 'OpenAI',
      baseURL: 'https://example.invalid',
      apiKey: 'secret-key',
      apiType: Bot.apiTypeOpenAI,
      model: 'gpt-test',
      systemPrompt: '',
      createTimestamp: timestamp,
      modifyTimestamp: timestamp,
    );
    final binding = BotSkillBinding(
      botId: bot.id,
      skillId: 'user:Release Notes',
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    await viewModel.addBot(bot, skillBindings: [binding]);

    expect(botRepository.addedBot, same(bot));
    expect(bindingRepository.savedBindings, [same(binding)]);
  });

  testWidgets('desktop bot card menu opens details and editing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.reset);

    final bot = Bot(
      id: 'bot-menu',
      name: '菜单智能体',
      avatar: '',
      provider: 'OpenAI',
      baseURL: '',
      apiKey: '',
      apiType: Bot.apiTypeOpenAI,
      model: 'gpt-test',
      systemPrompt: '',
      createTimestamp: DateTime(2026),
      modifyTimestamp: DateTime(2026),
    );
    final botRepository = BotCardTestBotRepository([bot]);
    final viewModel = BotListViewModel(
      botRepository: botRepository,
      createChat: CreateChat(chatRepository: BotCardTestChatRepository()),
      aiProviderRepository: UnusedAiProviderRepository(),
      attachmentRepository: UnusedAttachmentRepository(),
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    Bot? selectedDetailBot;
    Bot? selectedEditBot;
    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: ContactsPage(
                  viewModel: viewModel,
                  onBotSelected: (bot) => selectedDetailBot = bot,
                  onBotEditSelected: (bot) => selectedEditBot = bot,
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(
        const ValueKey<String>('desktop-bot-card-bot-menu'),
      );
      final menuButton = find.byKey(
        const ValueKey<String>('desktop-bot-menu-button-bot-menu'),
      );
      expect(card, findsOneWidget);
      expect(menuButton, findsOneWidget);
      expect(
        tester.getCenter(menuButton).dx,
        greaterThan(tester.getCenter(card).dx),
      );
      expect(
        tester.getCenter(menuButton).dy,
        greaterThan(tester.getCenter(card).dy),
      );

      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(selectedDetailBot?.id, bot.id);
      expect(selectedEditBot, isNull);
      selectedDetailBot = null;

      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      final actionMenu = find.byKey(
        const ValueKey<String>('desktop-bot-action-menu-bot-menu'),
      );
      final detailsAction = find.byKey(
        const ValueKey<String>('desktop-bot-details-bot-menu'),
      );
      final pageContext = tester.element(find.byType(ContactsPage));
      final startChatLabel = desktopConversationText(
        pageContext,
        S.of(pageContext).startChatting,
      );
      final startChatAction = find.ancestor(
        of: find.text(startChatLabel),
        matching: find.byType(ShadButton),
      );
      expect(actionMenu, findsOneWidget);
      expect(detailsAction, findsOneWidget);
      expect(startChatAction, findsOneWidget);
      expect(
        find.descendant(
          of: startChatAction,
          matching: find.byIcon(desktopStartConversationIcon),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(actionMenu).right,
        closeTo(tester.getRect(menuButton).right, 1),
      );
      expect(find.text(startChatLabel), findsOneWidget);
      expect(find.text('详情'), findsOneWidget);
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      expect(
        tester.getCenter(startChatAction).dy,
        lessThan(tester.getCenter(detailsAction).dy),
      );
      expect(
        find.descendant(of: actionMenu, matching: find.byType(ShadButton)),
        findsNWidgets(4),
      );

      await tester.tap(detailsAction);
      await tester.pumpAndSettle();
      expect(selectedDetailBot?.id, bot.id);
      expect(selectedEditBot, isNull);
      expect(actionMenu, findsNothing);

      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();
      expect(selectedEditBot?.id, bot.id);

      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(botRepository.deletedBotId, bot.id);
    });
  });

  testWidgets('mobile bot card opens a read-only detail page', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    final bot = Bot(
      id: 'bot-mobile-detail',
      name: '移动智能体',
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
    final viewModel = BotListViewModel(
      botRepository: BotCardTestBotRepository([bot]),
      createChat: CreateChat(chatRepository: BotCardTestChatRepository()),
      aiProviderRepository: UnusedAiProviderRepository(),
      attachmentRepository: UnusedAttachmentRepository(),
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    try {
      await withMobilePlatform(() async {
        await tester.pumpWidget(
          shadHarness(
            brightness: Brightness.light,
            homeBuilder:
                (context) => Scaffold(
                  body: ContactsPage(
                    viewModel: viewModel,
                    onBotSelected: (_) {},
                  ),
                ),
          ),
        );
        await tester.pumpAndSettle();

        final addBotButton = find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == '添加智能体',
        );
        final addBotAction = find.descendant(
          of: addBotButton,
          matching: find.bySemanticsLabel('添加智能体'),
        );
        expect(addBotButton, findsOneWidget);
        expect(addBotAction, findsOneWidget);
        expect(tester.getSize(addBotButton), const Size.square(48));
        expect(
          tester.getSemantics(addBotAction),
          matchesSemantics(
            label: '添加智能体',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasFocusAction: true,
            hasTapAction: true,
          ),
        );

        await tester.tap(find.text(bot.name));
        await tester.pumpAndSettle();

        final page = tester.widget<EditBotPage>(find.byType(EditBotPage));
        expect(page.readOnly, isTrue);
        expect(find.text('详情'), findsOneWidget);
        expect(find.text('保存修改'), findsNothing);
        expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
        expect(find.byType(TextField), findsNothing);
        expect(find.byType(ShadInput), findsNothing);
        expect(find.byType(ShadTextarea), findsNothing);
        final providerDetail = find.byKey(
          const ValueKey<String>('bot-detail-provider'),
        );
        await tester.ensureVisible(providerDetail);
        await tester.pumpAndSettle();
        final providerLabel = find.descendant(
          of: providerDetail,
          matching: find.text('供应商'),
        );
        final providerValue = find.descendant(
          of: providerDetail,
          matching: find.text('OpenAI'),
        );
        expect(providerDetail, findsOneWidget);
        expect(providerLabel, findsOneWidget);
        expect(providerValue, findsOneWidget);
        expect(
          tester.getTopLeft(providerLabel).dy,
          lessThan(tester.getTopLeft(providerValue).dy),
        );
      });
    } finally {
      semantics.dispose();
    }
  });

}
