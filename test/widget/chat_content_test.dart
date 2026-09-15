import '../support/idle_chat_generation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/strict_grounding_policy.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/app/view_models/main_shell_view_model.dart';
import 'package:stars/ui/features/app/views/desktop_layout.dart';
import 'package:stars/ui/features/chats/view_models/chat_list_view_model.dart';
import 'package:stars/ui/features/chats/views/chats.dart';
import 'package:stars/ui/features/chats/views/chat_item.dart';
import 'package:stars/ui/features/chats/views/chat_list_builder.dart';
import 'package:stars/utils/theme.dart';

import '../support/widget_test_support.dart';

void main() {
  testWidgets('mobile chat app bar exposes a named 48px new chat action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final botRepository = BotCardTestBotRepository(const []);
    final viewModel = ChatListViewModel(
      chatRepository: BotCardTestChatRepository(),
      botRepository: botRepository,
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    try {
      await withMobilePlatform(() async {
        await tester.pumpWidget(
          shadHarness(
            brightness: Brightness.light,
            homeBuilder:
                (context) => ChatListPage(
                  viewModel: viewModel,
                  onChatSelected: (_, _) {},
                ),
          ),
        );
        await tester.pumpAndSettle();

        final newChatButton = find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == '新建聊天',
        );
        final newChatAction = find.descendant(
          of: newChatButton,
          matching: find.bySemanticsLabel('新建聊天'),
        );
        expect(newChatButton, findsOneWidget);
        expect(newChatAction, findsOneWidget);
        expect(tester.getSize(newChatButton), const Size.square(48));
        expect(
          tester.getSemantics(newChatAction),
          matchesSemantics(
            label: '新建聊天',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasFocusAction: true,
            hasTapAction: true,
          ),
        );
      });
    } finally {
      semantics.dispose();
    }
  });

  test('main shell distinguishes bot details from bot editing', () {
    final bot = Bot(
      id: 'bot-shell-mode',
      name: 'Mode test',
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
    final viewModel = MainShellViewModel(
      botRepository: BotCardTestBotRepository([bot]),
    );
    addTearDown(viewModel.dispose);

    viewModel.selectBot(bot);
    expect(viewModel.selectedBot, same(bot));
    expect(viewModel.isEditingSelectedBot, isFalse);

    viewModel.editBot(bot);
    expect(viewModel.selectedBot, same(bot));
    expect(viewModel.isEditingSelectedBot, isTrue);

    viewModel.clearSelectedBot();
    expect(viewModel.selectedBot, isNull);
    expect(viewModel.isEditingSelectedBot, isFalse);
  });

  test('main shell keeps the selected conversation name in sync', () {
    final bot = Bot(
      id: 'bot-chat-name',
      name: 'Assistant',
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
    final viewModel = MainShellViewModel(
      botRepository: BotCardTestBotRepository([bot]),
    );
    addTearDown(viewModel.dispose);

    viewModel.selectChat('chat-1', bot, chatName: ' Planning ');
    expect(viewModel.selectedChatName, 'Planning');

    viewModel.applyChatNameUpdate('another-chat', 'Ignored');
    expect(viewModel.selectedChatName, 'Planning');

    viewModel.applyChatNameUpdate('chat-1', 'Release');
    expect(viewModel.selectedChatName, 'Release');

    viewModel.clearSelectedChat();
    expect(viewModel.selectedChatName, isNull);
  });

  testWidgets('strict grounding preview marker is localized without raw text', (
    tester,
  ) async {
    await withDesktopPlatform(() async {
      final registry = idleChatGenerationRegistry(
        providerFactory: (_) => throw StateError('Provider is not expected'),
      );
      addTearDown(registry.clear);
      final timestamp = DateTime(2026);
      final bot = Bot(
        id: 'bot-strict-preview',
        name: '可信助手',
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
        id: 'chat-strict-preview',
        botId: bot.id,
        lastMessage: strictGroundingPreviewMarker,
        lastMessageTimestamp: timestamp,
        createTimestamp: timestamp,
        modifyTimestamp: timestamp,
      );

      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 240,
                  child: ChatListBuilder(
                    chatList: [chat],
                    bots: [bot],
                    strictGroundingMode: true,
                    generationRegistry: registry,
                    onChatDeleted: (_) {},
                    onDeleteChat: (_) async {},
                    onChatSelected: (_, _) {},
                  ),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('我暂时没有获得足够可靠的证据'), findsOneWidget);
      expect(find.textContaining(strictGroundingPreviewMarker), findsNothing);
    });
  });

  testWidgets('chat row shows its name and renames it with a Shad dialog', (
    tester,
  ) async {
    await withDesktopPlatform(() async {
      final registry = idleChatGenerationRegistry(
        providerFactory: (_) => throw StateError('Provider is not expected'),
      );
      addTearDown(registry.clear);
      final timestamp = DateTime(2026, 9, 12);
      final bot = Bot(
        id: 'bot-rename',
        name: '规划智能体',
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
        id: 'chat-rename',
        botId: bot.id,
        name: '需求梳理',
        lastMessage: '整理发布计划',
        lastMessageTimestamp: timestamp,
        createTimestamp: timestamp,
        modifyTimestamp: timestamp,
      );
      String? savedName;
      String? notifiedName;

      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 240,
                  child: ChatListBuilder(
                    chatList: [chat],
                    bots: [bot],
                    generationRegistry: registry,
                    onChatDeleted: (_) {},
                    onDeleteChat: (_) async {},
                    onChatSelected: (_, _) {},
                    onRenameChat: (_, name) async => savedName = name,
                    onChatRenamed: (_, name) => notifiedName = name,
                  ),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('需求梳理'), findsOneWidget);
      expect(find.textContaining('规划智能体 · OpenAI'), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();
      tester
          .widget<ShadButton>(
            find.byKey(const ValueKey<String>('chat-rename-chat-rename')),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      final input = find.byKey(
        const ValueKey<String>('rename-chat-name-input'),
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: input, matching: find.byType(EditableText)),
            )
            .controller
            .text,
        '需求梳理',
      );

      await tester.enterText(input, '   ');
      await tester.tap(find.byKey(const ValueKey<String>('rename-chat-save')));
      await tester.pump();
      expect(find.text('请输入会话名称。'), findsOneWidget);
      expect(savedName, isNull);

      await tester.enterText(input, ' 发布计划 ');
      await tester.tap(find.byKey(const ValueKey<String>('rename-chat-save')));
      await tester.pumpAndSettle();

      expect(savedName, '发布计划');
      expect(notifiedName, '发布计划');
      expect(
        find.byKey(const ValueKey<String>('rename-chat-dialog')),
        findsNothing,
      );
    });
  });

  testWidgets('chat row menu does not show a row focus ring on pointer use', (
    tester,
  ) async {
    await withDesktopPlatform(() async {
      var openCount = 0;
      final registry = idleChatGenerationRegistry(
        providerFactory: (_) => throw StateError('Provider is not expected'),
      );
      addTearDown(registry.clear);
      final timestamp = DateTime(2026);
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
        createTimestamp: timestamp,
        modifyTimestamp: timestamp,
      );
      final chat = Chat(
        id: 'chat-1',
        botId: bot.id,
        lastMessage: '测试会话',
        lastMessageTimestamp: timestamp,
        createTimestamp: timestamp,
        modifyTimestamp: timestamp,
      );

      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 240,
                  child: ChatListBuilder(
                    chatList: [chat],
                    bots: [bot],
                    selectedChatId: chat.id,
                    generationRegistry: registry,
                    onChatDeleted: (_) {},
                    onDeleteChat: (_) async {},
                    onChatSelected: (_, _) => openCount += 1,
                    onChatDirectoryRequested: () {},
                  ),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      final menuAction = tester.widget<StarsDesktopIconAction>(
        find.byType(StarsDesktopIconAction),
      );
      await tester.tap(
        find.byIcon(LucideIcons.ellipsis),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      final row = find.byType(DesktopInteractiveListItem);
      final rowButton = tester.widget<ShadButton>(
        find.descendant(of: row, matching: find.byType(ShadButton)).first,
      );
      final rowContext = tester.element(row);
      final rowContainer = tester.widget<AnimatedContainer>(
        find.descendant(of: row, matching: find.byType(AnimatedContainer)),
      );
      final rowDecoration = rowContainer.decoration! as BoxDecoration;
      final rowBorder = rowDecoration.border! as Border;
      final menuButton = tester.widget<ShadIconButton>(
        find
            .ancestor(
              of: find.byIcon(LucideIcons.ellipsis),
              matching: find.byType(ShadIconButton),
            )
            .first,
      );
      expect(rowButton.decoration?.disableSecondaryBorder, isTrue);
      expect(rowBorder.top.width, 0);
      expect(menuButton.hoverBackgroundColor, Colors.transparent);
      expect(rowButton.variant, ShadButtonVariant.primary);
      expect(
        rowButton.backgroundColor,
        StarsDesktopThemeSpec.inactivePrimaryActionColor(rowContext),
      );
      expect(rowButton.hoverBackgroundColor, rowButton.backgroundColor);
      expect(rowButton.pressedBackgroundColor, rowButton.backgroundColor);
      final selectedForeground =
          ShadTheme.of(rowContext).colorScheme.primaryForeground;
      expect(rowButton.foregroundColor, selectedForeground);
      expect(rowButton.hoverForegroundColor, selectedForeground);
      expect(rowButton.pressedForegroundColor, selectedForeground);
      expect(
        tester.widget<Text>(find.text(bot.name)).style?.color,
        selectedForeground,
      );
      expect(
        tester
            .widget<Text>(find.textContaining(chat.lastMessage).first)
            .style
            ?.color,
        selectedForeground,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('chat-directory-chat-1')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(openCount, 1);
      expect(menuAction.focusNode!.hasFocus, isFalse);
    });
  });

  testWidgets(
    'desktop Agent and My navigation restores the selected chat background',
    (tester) async {
      await withDesktopPlatform(() async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1440, 900);
        addTearDown(tester.view.reset);

        final registry = idleChatGenerationRegistry(
          providerFactory: (_) => throw StateError('Provider is not expected'),
        );
        addTearDown(registry.clear);
        final timestamp = DateTime(2026);
        final bot = Bot(
          id: 'bot-navigation',
          name: '测试智能体',
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
          id: 'chat-navigation',
          botId: bot.id,
          lastMessage: '测试会话',
          lastMessageTimestamp: timestamp,
          createTimestamp: timestamp,
          modifyTimestamp: timestamp,
        );
        final shell = MainShellViewModel(
          botRepository: BotCardTestBotRepository([bot]),
        )..selectChat(chat.id, bot);
        addTearDown(shell.dispose);

        await tester.pumpWidget(
          shadHarness(
            brightness: Brightness.light,
            homeBuilder:
                (context) => ListenableBuilder(
                  listenable: shell,
                  builder:
                      (context, _) => Scaffold(
                        body: DesktopLayout(
                          currentIndex: shell.currentIndex,
                          onPageChanged: shell.selectPage,
                          pages: [
                            ChatListBuilder(
                              chatList: [chat],
                              bots: [bot],
                              selectedChatId: shell.selectedChatId,
                              selectionVisible: shell.isChatSelectionVisible,
                              generationRegistry: registry,
                              onChatDeleted: (_) {},
                              onDeleteChat: (_) async {},
                              onChatSelected: shell.selectChat,
                            ),
                            const Center(child: Text('bot list')),
                            const Center(child: Text('skills')),
                            const Center(child: Text('mcp servers')),
                            const Center(child: Text('profile')),
                          ],
                          onBotUpdated: (_) async {},
                          onBotDeleted: () async {},
                        ),
                      ),
                ),
          ),
        );
        await tester.pumpAndSettle();

        ShadButton rowButton() => tester.widget<ShadButton>(
          find
              .descendant(
                of: find.byType(DesktopInteractiveListItem),
                matching: find.byType(ShadButton),
              )
              .first,
        );

        expect(rowButton().variant, ShadButtonVariant.primary);

        await tester.tap(find.text('智能体').first);
        await tester.pumpAndSettle();

        expect(shell.currentIndex, 1);
        expect(shell.selectedChatId, chat.id);
        expect(rowButton().variant, ShadButtonVariant.ghost);

        await tester.tap(find.text('我的').first);
        await tester.pumpAndSettle();

        expect(shell.currentIndex, 4);
        expect(shell.selectedChatId, chat.id);
        expect(rowButton().variant, ShadButtonVariant.ghost);

        await tester.tap(
          find.byType(DesktopInteractiveListItem).hitTestable().first,
        );
        await tester.pumpAndSettle();

        expect(shell.currentIndex, 0);
        expect(rowButton().variant, ShadButtonVariant.primary);
      });
    },
  );

  testWidgets('desktop delete chat cancel matches delete bot styling', (
    tester,
  ) async {
    await withDesktopPlatform(() async {
      var deleteCount = 0;
      final registry = idleChatGenerationRegistry(
        providerFactory: (_) => throw StateError('Provider is not expected'),
      );
      addTearDown(registry.clear);
      final timestamp = DateTime(2026);
      final bot = Bot(
        id: 'bot-delete',
        name: '待删除智能体',
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
        id: 'chat-delete',
        botId: bot.id,
        lastMessage: '待删除会话',
        lastMessageTimestamp: timestamp,
        createTimestamp: timestamp,
        modifyTimestamp: timestamp,
      );

      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 240,
                  child: ChatListBuilder(
                    chatList: [chat],
                    bots: [bot],
                    generationRegistry: registry,
                    onChatDeleted: (_) {},
                    onDeleteChat: (_) async => deleteCount += 1,
                    onChatSelected: (_, _) {},
                  ),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.trash2));
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
      expect(deleteCount, 0);
    });
  });

  testWidgets('chat row menu hover keeps the row background unchanged', (
    tester,
  ) async {
    final timestamp = DateTime(2026);
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
      createTimestamp: timestamp,
      modifyTimestamp: timestamp,
    );

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: SizedBox(
                width: 320,
                child: ChatListItem(
                  bot: bot,
                  lastMessage: '测试会话',
                  timestamp: '刚刚',
                  onTap: () {},
                  trailing: const SizedBox.square(
                    key: ValueKey<String>('chat-row-menu-target'),
                    dimension: 44,
                  ),
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.text(bot.name)).textAlign, TextAlign.left);

    ShadButton rowButton() => tester.widget<ShadButton>(
      find.descendant(
        of: find.byType(DesktopInteractiveListItem),
        matching: find.byType(ShadButton),
      ),
    );

    expect(rowButton().hoverBackgroundColor, isNull);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(
        find.byKey(const ValueKey<String>('chat-row-menu-target')),
      ),
    );
    await tester.pump();

    expect(rowButton().hoverBackgroundColor, Colors.transparent);

    await mouse.moveTo(tester.getCenter(find.text(bot.name)));
    await tester.pump();

    expect(rowButton().hoverBackgroundColor, isNull);
  });
}
