import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/create_chat.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/bots/view_models/bot_list_view_model.dart';
import 'package:stars/ui/features/bots/views/bots.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/views/clear_chat_dialog.dart';
import 'package:stars/ui/features/chats/view_models/chat_list_view_model.dart';
import 'package:stars/ui/features/chats/views/chats.dart';
import 'package:stars/ui/features/chats/views/chat_item.dart';
import 'package:stars/ui/features/chats/views/chat_list_builder.dart';
import 'package:stars/ui/features/profile/views/profile.dart';
import 'package:stars/utils/theme.dart';

import '../support/widget_test_support.dart';

void main() {
  testWidgets('desktop empty state renders without a card shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light, fontSize: 16),
        home: const Scaffold(
          body: DesktopEmptyStateCard(
            icon: Icons.forum_outlined,
            title: '尚未选择会话',
            description: '从侧边栏选择会话。',
          ),
        ),
      ),
    );

    expect(find.text('尚未选择会话'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('desktop bot and chat empty states match Skill styling', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.reset);

    final botRepository = BotCardTestBotRepository(const []);
    final botViewModel = BotListViewModel(
      botRepository: botRepository,
      createChat: CreateChat(chatRepository: BotCardTestChatRepository()),
      aiProviderRepository: UnusedAiProviderRepository(),
      attachmentRepository: UnusedAttachmentRepository(),
    );
    final chatViewModel = ChatListViewModel(
      chatRepository: BotCardTestChatRepository(),
      botRepository: botRepository,
    );
    addTearDown(botViewModel.dispose);
    addTearDown(chatViewModel.dispose);
    await botViewModel.load();
    await chatViewModel.load();

    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: ContactsPage(
                  viewModel: botViewModel,
                  onBotSelected: (_) {},
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('没有可用的智能体'), findsOneWidget);
      final botEmptyStateFinder = find.byType(DesktopEmptyStateCard);
      final botEmptyState = tester.widget<DesktopEmptyStateCard>(
        botEmptyStateFinder,
      );
      expect(botEmptyState.icon, desktopBotIcon);
      expect(botEmptyState.imageAsset, isNull);
      expect(botEmptyState.supportingText, isNull);
      expect(
        find.descendant(
          of: botEmptyStateFinder,
          matching: find.byIcon(desktopBotIcon),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: botEmptyStateFinder, matching: find.byType(Image)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: ChatListPage(
                  viewModel: chatViewModel,
                  onChatSelected: (_, _) {},
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('还没有会话记录'), findsOneWidget);
      final chatEmptyStateFinder = find.byType(DesktopEmptyStateCard);
      final chatEmptyState = tester.widget<DesktopEmptyStateCard>(
        chatEmptyStateFinder,
      );
      expect(chatEmptyState.icon, desktopStartConversationIcon);
      expect(chatEmptyState.imageAsset, isNull);
      expect(chatEmptyState.supportingText, isNull);
      expect(
        find.descendant(
          of: chatEmptyStateFinder,
          matching: find.byIcon(desktopStartConversationIcon),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chatEmptyStateFinder, matching: find.byType(Image)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('desktop home empty state has no duplicate new chat action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await withDesktopPlatform(() async {
      await tester.pumpWidget(desktopHarness(onCreateChat: () {}));
      await tester.pumpAndSettle();

      final emptyState = find.byType(DesktopEmptyStateCard);
      expect(emptyState, findsOneWidget);
      final emptyStateImage = find.descendant(
        of: emptyState,
        matching: find.byType(Image),
      );
      final emptyStateImageClip = find.ancestor(
        of: emptyStateImage,
        matching: find.byType(ClipRRect),
      );
      expect(emptyStateImage, findsOneWidget);
      expect(emptyStateImageClip, findsOneWidget);
      expect(
        tester.widget<ClipRRect>(emptyStateImageClip).borderRadius,
        desktopAppIconBorderRadius(DesktopEmptyStateCard.imageSize),
      );
      expect(
        find.descendant(of: emptyState, matching: find.text('点击新建会话创建会话')),
        findsOneWidget,
      );
      expect(find.textContaining('聊天'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('desktop-toolbar-clear-chat')),
        findsNothing,
      );
      expect(
        find.descendant(of: emptyState, matching: find.byType(ShadButton)),
        findsNothing,
      );
    });
  });

  testWidgets('desktop selected chat places clear before conversation data', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await withDesktopPlatform(() async {
      await tester.pumpWidget(desktopHarness(selectedChatId: 'chat-1'));
      await tester.pumpAndSettle();

      final clearAction = find.byKey(
        const ValueKey<String>('desktop-toolbar-clear-chat'),
      );
      final directoryAction = find.byKey(
        const ValueKey<String>('desktop-toolbar-conversation-directory'),
      );
      expect(clearAction, findsOneWidget);
      expect(directoryAction, findsOneWidget);
      expect(
        tester.getCenter(clearAction).dx,
        lessThan(tester.getCenter(directoryAction).dx),
      );
      expect(find.bySemanticsLabel('清空会话记录'), findsOneWidget);
      expect(find.bySemanticsLabel('查看会话数据'), findsOneWidget);
    });
  });

  testWidgets('desktop conversation info replaces chat at message width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);
    final bot = Bot(
      id: 'bot-1',
      name: 'Researcher',
      avatar: '',
      provider: 'OpenAI',
      baseURL: 'https://example.invalid',
      apiKey: '',
      apiType: Bot.apiTypeOpenAI,
      model: 'gpt-test',
      systemPrompt: '',
      parameters: const {
        Bot.parameterInputModalities: ['text', 'image', 'audio'],
        Bot.parameterOutputModalities: ['text'],
      },
      createTimestamp: DateTime(2026),
      modifyTimestamp: DateTime(2026),
    );

    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        desktopHarness(selectedChatBot: bot, selectedChatName: '季度规划'),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('显示会话信息'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('desktop-toolbar-conversation-info')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShadSheet), findsNothing);
      expect(find.bySemanticsLabel('隐藏会话信息'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey<String>('desktop-conversation-information-close'),
        ),
        findsNothing,
      );
      final content = tester.widget<ConstrainedBox>(
        find.byKey(
          const ValueKey<String>('desktop-conversation-information-content'),
        ),
      );
      expect(
        content.constraints.maxWidth,
        StarsDesktopThemeSpec.contentMaxWidth,
      );
      final conversationInfo = find.byKey(
        const PageStorageKey<String>('desktop-conversation-information-list'),
      );
      final infoList = tester.widget<ListView>(conversationInfo);
      expect(infoList.padding, StarsDesktopThemeSpec.profilePagePadding);
      expect(find.text('会话信息'), findsOneWidget);
      final pageTitle = find.byKey(
        const ValueKey<String>('desktop-conversation-information-title'),
      );
      expect(
        tester.widget<Text>(pageTitle).style,
        StarsDesktopThemeSpec.pageTitleStyle(tester.element(pageTitle)),
      );
      expect(
        find.byKey(
          const ValueKey<String>('desktop-conversation-information-avatar'),
        ),
        findsOneWidget,
      );
      final providerBadge = tester.widget<ShadBadge>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('desktop-conversation-provider-badge'),
          ),
          matching: find.byType(ShadBadge),
        ),
      );
      final modelBadge = tester.widget<ShadBadge>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('desktop-conversation-model-badge'),
          ),
          matching: find.byType(ShadBadge),
        ),
      );
      expect(providerBadge.variant, ShadBadgeVariant.outline);
      expect(modelBadge.variant, ShadBadgeVariant.secondary);
      final basicSection = find.byKey(
        const ValueKey<String>('desktop-conversation-basic-section'),
      );
      expect(basicSection, findsOneWidget);
      expect(
        find.descendant(of: basicSection, matching: find.byType(ShadCard)),
        findsOneWidget,
      );
      expect(find.text('基本信息'), findsOneWidget);
      expect(
        find.descendant(
          of: basicSection,
          matching: find.byIcon(LucideIcons.info),
        ),
        findsOneWidget,
      );
      final infoRows = find.byType(StarsInspectorInfoRow);
      expect(infoRows, findsNWidgets(6));
      expect(find.text('季度规划'), findsOneWidget);
      expect(find.text('用于识别当前会话的自定义名称。'), findsOneWidget);
      expect(find.text('当前会话使用的智能体。'), findsOneWidget);
      expect(find.text('为当前会话提供模型服务的供应商。'), findsOneWidget);
      expect(find.text('当前会话用于生成回复的模型。'), findsOneWidget);
      expect(find.text('此模型可以处理的内容类型。'), findsOneWidget);
      expect(find.text('此模型可以生成的内容类型。'), findsOneWidget);
      final labelLefts = <double>[];
      for (var index = 0; index < 3; index += 1) {
        final row = infoRows.at(index);
        expect(
          tester.widget<StarsInspectorInfoRow>(row).layout,
          StarsInspectorInfoRowLayout.settings,
        );
        final rowWidget = tester.widget<StarsInspectorInfoRow>(row);
        final label = find.descendant(
          of: row,
          matching: find.text(rowWidget.label),
        );
        final value = find.descendant(
          of: row,
          matching: find.text(rowWidget.value!),
        );
        final valueText = tester.widget<Text>(value);
        expect(valueText.textAlign, TextAlign.right);
        expect(valueText.maxLines, 1);
        expect(valueText.overflow, TextOverflow.ellipsis);
        labelLefts.add(tester.getRect(label).left);
        expect(
          tester.getRect(row).right - tester.getRect(value).right,
          closeTo(
            StarsDesktopThemeSpec.settingsRowPadding.right +
                StarsDesktopThemeSpec.settingsRowDisclosureInset,
            0.01,
          ),
        );
        expect(
          tester.getRect(label).left - tester.getRect(row).left,
          closeTo(
            StarsDesktopThemeSpec.settingsRowPadding.left +
                StarsDesktopThemeSpec.settingsRowIconSlotWidth +
                StarsDesktopThemeSpec.settingsRowIconGap,
            0.01,
          ),
        );
        expect(
          tester.getSize(row).height,
          greaterThanOrEqualTo(
            StarsDesktopThemeSpec.settingsRowPadding.vertical +
                StarsDesktopThemeSpec.settingsRowMinHeight,
          ),
        );
        expect(
          tester.getRect(conversationInfo).right - tester.getRect(row).right,
          greaterThanOrEqualTo(16),
        );
      }
      expect(labelLefts[1], closeTo(labelLefts[0], 0.01));
      expect(labelLefts[2], closeTo(labelLefts[0], 0.01));
      for (var index = 0; index < 6; index += 1) {
        final row = infoRows.at(index);
        final rowWidget = tester.widget<StarsInspectorInfoRow>(row);
        expect(rowWidget.description, isNotEmpty);
        final label = find.descendant(
          of: row,
          matching: find.text(rowWidget.label),
        );
        final description = find.descendant(
          of: row,
          matching: find.text(rowWidget.description!),
        );
        final leadingIcon = find.descendant(
          of: row,
          matching: find.byIcon(rowWidget.icon),
        );
        final trailing =
            rowWidget.value == null
                ? find.byWidget(rowWidget.trailing!)
                : find.descendant(
                  of: row,
                  matching: find.text(rowWidget.value!),
                );
        final rowCenterY = tester.getCenter(row).dy;

        expect(
          tester.getTopLeft(description).dy,
          greaterThan(tester.getBottomLeft(label).dy),
        );
        expect(
          tester.getCenter(leadingIcon.first).dy,
          closeTo(rowCenterY, 0.01),
        );
        expect(tester.getCenter(trailing).dy, closeTo(rowCenterY, 0.01));
      }
      final inputModalities = find.byKey(
        const ValueKey<String>('conversation-model-modalities-input'),
      );
      final outputModalities = find.byKey(
        const ValueKey<String>('conversation-model-modalities-output'),
      );
      expect(inputModalities, findsOneWidget);
      expect(outputModalities, findsOneWidget);
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
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('desktop chat row menu follows conversation action order', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);
    final registry = ChatGenerationRegistry(
      messagePersister: (message) async => message,
      lastMessageUpdater: (_, _) async {},
      providerFactory: (_) => throw StateError('Provider is not expected'),
    );
    addTearDown(registry.clear);
    final timestamp = DateTime(2026);
    final bot = Bot(
      id: 'bot-details-menu',
      name: '菜单智能体',
      avatar: '',
      provider: 'OpenAI',
      baseURL: '',
      apiKey: '',
      apiType: Bot.apiTypeOpenAI,
      model: 'gpt-test',
      systemPrompt: '',
      createTimestamp: timestamp,
      modifyTimestamp: timestamp,
    );
    final chat = Chat(
      id: 'chat-details-menu',
      botId: bot.id,
      lastMessage: '查看详情',
      lastMessageTimestamp: timestamp,
      createTimestamp: timestamp,
      modifyTimestamp: timestamp,
    );
    var selectedChatId = '';
    var directoryRequests = 0;
    var clearRequests = 0;

    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        desktopHarness(
          selectedChatBot: bot,
          chatListPage: ChatListBuilder(
            chatList: [chat],
            bots: [bot],
            selectedChatId: chat.id,
            generationRegistry: registry,
            onChatDeleted: (_) {},
            onDeleteChat: (_) async {},
            onChatSelected: (chatId, _) => selectedChatId = chatId,
            onChatDirectoryRequested: () => directoryRequests += 1,
            onChatClearRequested: () => clearRequests += 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final contextMenu = tester.widget<StarsContextMenu>(
        find.byKey(const ValueKey<String>('chat-menu-chat-details-menu')),
      );
      expect(
        contextMenu.items.where(
          (item) =>
              item.key ==
              const ValueKey<String>('chat-context-details-chat-details-menu'),
        ),
        hasLength(1),
      );
      final contextActionKeys = contextMenu.items
          .map((item) => item.key)
          .whereType<ValueKey<String>>()
          .map((key) => key.value)
          .toList(growable: false);
      expect(contextActionKeys, [
        'chat-context-directory-chat-details-menu',
        'chat-context-details-chat-details-menu',
        'chat-context-clear-chat-details-menu',
        'chat-context-delete-chat-details-menu',
      ]);
      expect(
        contextMenu.items.where(
          (item) =>
              item.key ==
              const ValueKey<String>(
                'chat-context-directory-chat-details-menu',
              ),
        ),
        hasLength(1),
      );

      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();

      final detailsAction = find.byKey(
        const ValueKey<String>('chat-details-chat-details-menu'),
      );
      final dataAction = find.byKey(
        const ValueKey<String>('chat-directory-chat-details-menu'),
      );
      final clearAction = find.byKey(
        const ValueKey<String>('chat-clear-chat-details-menu'),
      );
      final deleteAction = find.byKey(
        const ValueKey<String>('chat-delete-chat-details-menu'),
      );
      expect(dataAction, findsOneWidget);
      expect(detailsAction, findsOneWidget);
      expect(clearAction, findsOneWidget);
      expect(deleteAction, findsOneWidget);
      expect(find.text('开始聊天'), findsNothing);
      expect(find.text('数据'), findsOneWidget);
      expect(find.text('清空'), findsOneWidget);
      expect(
        [
          dataAction,
          detailsAction,
          clearAction,
          deleteAction,
        ].map((finder) => tester.getTopLeft(finder).dy).toList(growable: false),
        orderedEquals(
          [dataAction, detailsAction, clearAction, deleteAction]
            .map((finder) => tester.getTopLeft(finder).dy)
            .toList(growable: false)..sort(),
        ),
      );
      expect(
        find.descendant(
          of: detailsAction,
          matching: find.byIcon(LucideIcons.info),
        ),
        findsOneWidget,
      );
      expect(find.text('详情'), findsOneWidget);

      await tester.tap(detailsAction);
      await tester.pumpAndSettle();

      expect(selectedChatId, chat.id);
      expect(
        find.byKey(const ValueKey<String>('desktop-conversation-information')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('desktop-conversation-information-close'),
        ),
        findsNothing,
      );
      expect(find.bySemanticsLabel('隐藏会话信息'), findsWidgets);

      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();

      final directoryAction = find.byKey(
        const ValueKey<String>('chat-directory-chat-details-menu'),
      );
      expect(directoryAction, findsOneWidget);
      expect(
        find.descendant(
          of: directoryAction,
          matching: find.byIcon(LucideIcons.folderOpen),
        ),
        findsOneWidget,
      );
      expect(find.text('数据'), findsOneWidget);

      await tester.tap(directoryAction);
      await tester.pumpAndSettle();

      expect(selectedChatId, chat.id);
      expect(directoryRequests, 1);

      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('chat-clear-chat-details-menu')),
      );
      await tester.pumpAndSettle();

      expect(selectedChatId, chat.id);
      expect(clearRequests, 1);
    });
  });

  testWidgets('desktop clear chat cancel matches delete bot styling', (
    tester,
  ) async {
    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: ShadButton(
                  onPressed:
                      () => unawaited(showClearChatDialog(context, '测试智能体')),
                  child: const Text('打开清空会话弹窗'),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开清空会话弹窗'));
      await tester.pumpAndSettle();

      final cancelButtonFinder =
          find
              .ancestor(of: find.text('取消'), matching: find.byType(ShadButton))
              .first;
      final cancelButton = tester.widget<ShadButton>(cancelButtonFinder);
      expect(cancelButton.variant, ShadButtonVariant.outline);
      expect(cancelButton.autofocus, isFalse);

      await tester.tap(cancelButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('取消'), findsNothing);
    });
  });

  testWidgets('desktop stop generation dialog matches clear chat styling', (
    tester,
  ) async {
    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: ShadButton(
                  onPressed:
                      () => unawaited(
                        showStopGenerationBeforeLeavingDialog(context),
                      ),
                  child: const Text('打开停止生成弹窗'),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('打开停止生成弹窗'));
      await tester.pumpAndSettle();

      expect(find.text('离开前停止生成？'), findsOneWidget);
      expect(find.text('已生成的部分回复会被保留。'), findsOneWidget);

      final cancelButtonFinder =
          find
              .ancestor(of: find.text('取消'), matching: find.byType(ShadButton))
              .first;
      final stopButtonFinder =
          find
              .ancestor(
                of: find.text('停止并继续'),
                matching: find.byType(ShadButton),
              )
              .first;
      final cancelButton = tester.widget<ShadButton>(cancelButtonFinder);
      final stopButton = tester.widget<ShadButton>(stopButtonFinder);

      expect(cancelButton.variant, ShadButtonVariant.outline);
      expect(cancelButton.autofocus, isFalse);
      expect(stopButton.variant, ShadButtonVariant.destructive);
      expect(stopButton.leading, isNull);

      await tester.tap(cancelButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('离开前停止生成？'), findsNothing);
    });
  });

  testWidgets('desktop sidebar keeps Skill and MCP entries under My', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    for (final selectedPage in [1, 2, 3, 4]) {
      await tester.pumpWidget(desktopHarness(currentIndex: selectedPage));
      await tester.pumpAndSettle();

      final label = selectedPage == 1 ? '智能体' : '我的';
      final selectedButtonFinder =
          find
              .ancestor(of: find.text(label), matching: find.byType(ShadButton))
              .first;
      final selectedButton = tester.widget<ShadButton>(selectedButtonFinder);
      final selectedButtonContext = tester.element(selectedButtonFinder);

      expect(selectedButton.variant, ShadButtonVariant.primary);
      expect(
        selectedButton.backgroundColor,
        StarsDesktopThemeSpec.inactivePrimaryActionColor(selectedButtonContext),
      );
      expect(
        selectedButton.hoverBackgroundColor,
        selectedButton.backgroundColor,
      );
      expect(
        selectedButton.pressedBackgroundColor,
        selectedButton.backgroundColor,
      );
      final selectedForeground =
          ShadTheme.of(selectedButtonContext).colorScheme.primaryForeground;
      expect(selectedButton.foregroundColor, selectedForeground);
      expect(selectedButton.hoverForegroundColor, selectedForeground);
      expect(selectedButton.pressedForegroundColor, selectedForeground);

      final textFinder = find.text(label).first;
      final text = tester.widget<Text>(textFinder);
      final inheritedTextStyle =
          DefaultTextStyle.of(tester.element(textFinder)).style;
      expect(inheritedTextStyle.merge(text.style).color, selectedForeground);
      expect(
        tester.getSize(selectedButtonFinder).height,
        StarsDesktopThemeSpec.botFormFieldHeight,
      );
      expect(selectedButton.mainAxisAlignment, MainAxisAlignment.start);

      if (selectedPage == 1) {
        final newChatButtonFinder =
            find
                .ancestor(
                  of: find.byIcon(desktopStartConversationIcon),
                  matching: find.byType(ShadButton),
                )
                .first;
        final newChatButton = tester.widget<ShadButton>(newChatButtonFinder);
        final agentIcon = tester.widget<Icon>(
          find
              .descendant(
                of: selectedButtonFinder,
                matching: find.byIcon(LucideIcons.bot),
              )
              .first,
        );
        final newChatIcon = tester.widget<Icon>(
          find
              .descendant(
                of: newChatButtonFinder,
                matching: find.byIcon(desktopStartConversationIcon),
              )
              .first,
        );

        expect(
          tester.getSize(newChatButtonFinder).height,
          StarsDesktopThemeSpec.botFormFieldHeight,
        );
        expect(selectedButton.size, newChatButton.size);
        expect(selectedButton.expands, newChatButton.expands);
        expect(
          selectedButton.mainAxisAlignment,
          newChatButton.mainAxisAlignment,
        );
        expect(selectedButton.padding, newChatButton.padding);
        expect(selectedButton.gap, newChatButton.gap);
        expect(selectedButton.leading, isNull);
        expect(newChatButton.leading, isNull);
        expect(selectedButton.expands, isTrue);
        expect(agentIcon.size, newChatIcon.size);
      }

      final primaryNavigation = find.byKey(
        const ValueKey<String>('desktop-primary-navigation'),
      );
      expect(
        find.descendant(of: primaryNavigation, matching: find.text('技能')),
        findsNothing,
      );
      expect(
        find.descendant(of: primaryNavigation, matching: find.text('MCP 服务器')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: primaryNavigation,
          matching: find.byIcon(LucideIcons.wrench),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: primaryNavigation,
          matching: find.byIcon(LucideIcons.server),
        ),
        findsNothing,
      );
    }
  });

  testWidgets('desktop profile footer aligns with the My navigation button', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await withDesktopPlatform(() async {
      final profilePage = ProfilePage(
        initialProfile: Profile(
          name: 'Test User',
          avatar: '',
          fontSize: 16,
          themeMode: 1,
          language: 'zh_CN',
          showExecutionStatus: true,
          createTimestamp: DateTime(2026),
          modifyTimestamp: DateTime(2026),
        ),
        onProfileSaved: (_) async {},
        onOpenSkillLibrary: () {},
        onOpenMcpServers: () {},
      );

      await tester.pumpWidget(
        desktopHarness(currentIndex: 4, profilePage: profilePage),
      );
      await tester.pumpAndSettle();

      final aboutAndLegalTitle = find.text('关于与法律信息');
      final scrollPosition =
          Scrollable.of(tester.element(aboutAndLegalTitle)).position;
      scrollPosition.jumpTo(scrollPosition.maxScrollExtent);
      await tester.pump();

      final myButton =
          find
              .ancestor(of: find.text('我的'), matching: find.byType(ShadButton))
              .first;
      final aboutAndLegalSection = find.ancestor(
        of: aboutAndLegalTitle,
        matching: find.byType(ShadCard),
      );
      final viewportBottom =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final myButtonBottomInset =
          viewportBottom - tester.getRect(myButton).bottom;
      final sectionBottomInset =
          viewportBottom - tester.getRect(aboutAndLegalSection).bottom;

      expect(
        myButtonBottomInset,
        closeTo(StarsDesktopThemeSpec.sidebarFooterBottomInset, 0.01),
      );
      expect(sectionBottomInset, closeTo(myButtonBottomInset, 0.01));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'desktop primary navigation icons align with conversation avatars',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      final timestamp = DateTime(2026);
      final bot = Bot(
        id: 'sidebar-alignment-bot',
        name: '对齐测试',
        avatar: '',
        provider: 'OpenAI',
        baseURL: '',
        apiKey: '',
        apiType: Bot.apiTypeOpenAI,
        model: 'gpt-test',
        systemPrompt: '',
        createTimestamp: timestamp,
        modifyTimestamp: timestamp,
      );

      await tester.pumpWidget(
        desktopHarness(
          onCreateChat: () {},
          chatListPage: DesktopListPanel(
            title: '',
            description: '',
            searchHintText: '搜索会话',
            onSearchChanged: (_) {},
            action: const SizedBox.shrink(),
            showHeader: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ChatListItem(
                bot: bot,
                lastMessage: '测试消息',
                timestamp: '刚刚',
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final conversationIconLeft =
          tester.getTopLeft(find.byType(ShadAvatar)).dx;
      for (final icon in [desktopStartConversationIcon, LucideIcons.bot]) {
        final iconFinder = find.byIcon(icon).first;
        final buttonFinder =
            find
                .ancestor(of: iconFinder, matching: find.byType(ShadButton))
                .first;
        final labelFinder =
            find
                .descendant(of: buttonFinder, matching: find.byType(Text))
                .first;
        expect(
          tester.getTopLeft(iconFinder).dx,
          closeTo(conversationIconLeft, 0.01),
        );
        expect(
          tester.getCenter(labelFinder).dx,
          closeTo(tester.getCenter(buttonFinder).dx, 0.01),
        );
      }
    },
  );

  testWidgets('desktop sidebar divider remains visible after resizing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(desktopHarness(currentIndex: 4));
    await tester.pumpAndSettle();

    final handle = find.byKey(
      const ValueKey<String>('desktop-sidebar-resize-handle'),
    );
    expect(handle, findsOneWidget);
    final initialCenter = tester.getCenter(handle);

    await tester.drag(handle, const Offset(32, 0));
    await tester.pumpAndSettle();
    expect(tester.getCenter(handle).dx, greaterThan(initialCenter.dx));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final divider = find.descendant(
      of: handle,
      matching: find.byType(ColoredBox),
    );
    expect(divider, findsOneWidget);
    expect(
      tester.widget<ColoredBox>(divider).color,
      ShadTheme.of(tester.element(handle)).colorScheme.border,
    );
  });

  testWidgets('desktop shell uses one toolbar and overlays sidebar at 800px', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(desktopHarness());
    await tester.pumpAndSettle();

    expect(find.text('文件'), findsNothing);
    expect(find.text('编辑'), findsNothing);
    expect(find.text('视图'), findsNothing);
    expect(find.text('帮助'), findsNothing);
    expect(find.text('Stars'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('desktop-toolbar-sidebar')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stars'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Stars'), findsNothing);
  });

  testWidgets('desktop chat and bot list share toolbar geometry and divider', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    const toolbarKey = ValueKey<String>('desktop-unified-toolbar');

    await tester.pumpWidget(desktopHarness());
    await tester.pumpAndSettle();

    final chatToolbarFinder = find.byKey(toolbarKey);
    final chatToolbar = tester.widget<Container>(chatToolbarFinder);
    final chatDecoration = chatToolbar.decoration! as BoxDecoration;
    final chatBorder = chatDecoration.border! as Border;
    final chatSize = tester.getSize(chatToolbarFinder);

    await tester.pumpWidget(desktopHarness(currentIndex: 1));
    await tester.pumpAndSettle();

    final botToolbarFinder = find.byKey(toolbarKey);
    final botToolbar = tester.widget<Container>(botToolbarFinder);
    final botDecoration = botToolbar.decoration! as BoxDecoration;
    final botBorder = botDecoration.border! as Border;
    final botSize = tester.getSize(botToolbarFinder);

    expect(chatSize.height, StarsDesktopThemeSpec.toolbarHeight);
    expect(chatSize, botSize);
    expect(chatDecoration.color, botDecoration.color);
    expect(chatBorder.bottom, botBorder.bottom);
    expect(chatBorder.bottom.width, 0);
    expect(chatBorder.bottom.style, BorderStyle.solid);
  });
}
