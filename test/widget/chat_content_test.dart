import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/strict_grounding_policy.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/app/view_models/main_shell_view_model.dart';
import 'package:stars/ui/features/app/views/desktop_layout.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
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

  testWidgets('strict grounding preview marker is localized without raw text', (
    tester,
  ) async {
    await withDesktopPlatform(() async {
      final registry = ChatGenerationRegistry(
        messagePersister: (message) async => message,
        lastMessageUpdater: (_, _) async {},
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

      expect(find.textContaining('Stars 无法验证此事实回答'), findsOneWidget);
      expect(find.textContaining(strictGroundingPreviewMarker), findsNothing);
    });
  });

  testWidgets('desktop message content uses its full available page width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);

    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: SizedBox(
                width: 736,
                height: 500,
                child: Column(
                  children: [
                    MessageList(
                      messages: [
                        Message(
                          messageId: 'message-1',
                          chatId: 'chat-1',
                          botId: 'bot-1',
                          senderId: 'bot-1',
                          content: '桌面会话内容',
                          timestamp: DateTime(2026),
                        ),
                      ],
                      scrollController: scrollController,
                      isStreaming: false,
                      streamingResponse: '',
                      currentUserId: 'me',
                      isDesktop: true,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('desktop-message-viewport')),
          )
          .width,
      736,
    );
  });

  testWidgets('desktop message image opens a laid out preview dialog', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.reset);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    const imagePath = 'assets/images/profile/no_bots_v2.png';

    await withDesktopPlatform(() async {
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: Column(
                  children: [
                    MessageList(
                      messages: [
                        Message(
                          messageId: 'message-with-image',
                          chatId: 'chat-1',
                          botId: 'bot-1',
                          senderId: 'me',
                          content: '',
                          images: const [imagePath],
                          timestamp: DateTime(2026),
                        ),
                      ],
                      scrollController: scrollController,
                      isStreaming: false,
                      streamingResponse: '',
                      currentUserId: 'me',
                      isDesktop: true,
                    ),
                  ],
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('message-image-preview-$imagePath')),
      );
      await tester.pumpAndSettle();

      final dialog = find.byKey(const ValueKey<String>('message-image-dialog'));
      expect(dialog, findsOneWidget);
      final preview = find.byKey(
        const ValueKey<String>('message-image-dialog-preview'),
      );
      expect(preview, findsOneWidget);
      final previewSize = tester.getSize(preview);
      expect(previewSize.width, greaterThan(0));
      expect(previewSize.height, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('desktop message execution status is the final message block', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: Column(
                children: [
                  MessageList(
                    messages: [
                      Message(
                        messageId: 'message-1',
                        chatId: 'chat-1',
                        botId: 'bot-1',
                        senderId: 'bot-1',
                        content: '回复信息',
                        processInfo: const MessageProcessInfo(durationMs: 1200),
                        tokenUsage: const ModelTokenUsage(
                          inputTokens: 120,
                          outputTokens: 30,
                        ),
                        files: const ['/tmp/output.txt'],
                        terminalOutcome: MessageTerminalOutcome.failed,
                        hasPartialContent: true,
                        timestamp: DateTime(2026),
                      ),
                    ],
                    scrollController: scrollController,
                    isStreaming: false,
                    streamingResponse: '',
                    currentUserId: 'user',
                    isDesktop: true,
                  ),
                ],
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    final content = find.text('回复信息');
    final fileResult = find.text('文件结果');
    final terminalStatus = find.text('生成失败 · 保留部分回复');
    final executionStatus = find.text('执行状态');
    final duration = find.text('耗时 1.2 秒');
    final inputTokens = find.text('输入 Token 120');
    final outputTokens = find.text('输出 Token 30');
    expect(content, findsOneWidget);
    expect(fileResult, findsOneWidget);
    expect(terminalStatus, findsOneWidget);
    expect(executionStatus, findsOneWidget);
    expect(duration, findsOneWidget);
    expect(inputTokens, findsOneWidget);
    expect(outputTokens, findsOneWidget);
    expect(find.text('包含耗时'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('execution-header-metrics')),
      findsOneWidget,
    );
    final headerMetrics = find.byKey(
      const ValueKey<String>('execution-header-metrics'),
    );
    final durationIcon = find.descendant(
      of: headerMetrics,
      matching: find.byIcon(LucideIcons.clock3),
    );
    expect(durationIcon, findsOneWidget);
    expect(
      find.descendant(
        of: headerMetrics,
        matching: find.byIcon(Icons.login_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: headerMetrics,
        matching: find.byIcon(Icons.logout_rounded),
      ),
      findsOneWidget,
    );
    final executionTop = tester.getTopLeft(executionStatus).dy;
    expect(executionTop, greaterThan(tester.getBottomLeft(content).dy));
    expect(executionTop, greaterThan(tester.getBottomLeft(fileResult).dy));
    expect(executionTop, greaterThan(tester.getBottomLeft(terminalStatus).dy));
    final durationPosition = tester.getTopLeft(duration);
    final inputPosition = tester.getTopLeft(inputTokens);
    final outputPosition = tester.getTopLeft(outputTokens);
    final durationText = tester.widget<Text>(duration);
    final inputText = tester.widget<Text>(inputTokens);
    final outputText = tester.widget<Text>(outputTokens);
    expect(durationText.style?.fontSize, 12);
    expect(durationText.style?.height, 1.2);
    expect(durationText.style?.fontWeight, FontWeight.w400);
    expect(inputText.style, durationText.style);
    expect(outputText.style, durationText.style);
    expect(
      tester.getTopLeft(durationIcon).dx,
      tester.getTopLeft(executionStatus).dx,
    );
    expect(inputPosition.dy, durationPosition.dy);
    expect(outputPosition.dy, durationPosition.dy);
    expect(inputPosition.dx, greaterThan(durationPosition.dx));
    expect(outputPosition.dx, greaterThan(inputPosition.dx));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(content));
    await tester.pumpAndSettle();

    final copyAction = find.byKey(
      const ValueKey<String>('desktop-message-copy-action'),
    );
    final executionCard = find.ancestor(
      of: executionStatus,
      matching: find.byType(ShadCard),
    );
    expect(copyAction, findsOneWidget);
    expect(executionCard, findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.ancestor(
              of: copyAction,
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      1,
    );
    final copyRect = tester.getRect(copyAction);
    final executionRect = tester.getRect(executionCard);
    expect(copyRect.left, executionRect.left);
    expect(copyRect.top - executionRect.bottom, greaterThanOrEqualTo(4));
  });

  testWidgets('message execution status omits tokens without usage data', (
    tester,
  ) async {
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => const Scaffold(
              body: ProcessInfoSection(
                processInfo: MessageProcessInfo(durationMs: 800),
                isDesktop: true,
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('执行状态'), findsOneWidget);
    expect(find.text('耗时 800 毫秒'), findsOneWidget);
    expect(find.text('包含耗时'), findsNothing);
    expect(find.textContaining('输入 Token'), findsNothing);
    expect(find.textContaining('输出 Token'), findsNothing);
  });

  testWidgets('execution status shows the detailed shell command', (
    tester,
  ) async {
    const command = 'git status --short && dart analyze';
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => const Scaffold(
              body: ProcessInfoSection(
                processInfo: MessageProcessInfo(
                  commandExecutions: [
                    MessageCommandExecution(
                      callId: 'shell-1',
                      command: command,
                      status: 'succeeded',
                      durationMs: 240,
                    ),
                  ],
                ),
                isDesktop: true,
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(command).hitTestable(), findsNothing);
    await tester.tap(find.text('执行状态'));
    await tester.pumpAndSettle();

    expect(find.text('命令执行').hitTestable(), findsOneWidget);
    expect(find.text(command).hitTestable(), findsOneWidget);
    expect(find.text('已完成').hitTestable(), findsOneWidget);
    expect(find.text('耗时 240 毫秒').hitTestable(), findsOneWidget);
  });

  testWidgets(
    'desktop merges user Skill activations into the response execution status',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.reset);

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: Column(
                  children: [
                    MessageList(
                      messages: [
                        Message(
                          messageId: 'message-user',
                          turnId: 'turn-1',
                          runId: 'run-1',
                          chatId: 'chat-1',
                          botId: 'bot-1',
                          senderId: 'user',
                          content: '使用技能处理',
                          processInfo: const MessageProcessInfo(
                            toolCalls: [
                              MessageToolCall(
                                name: 'activate_skill',
                                status: 'completed',
                                detail: 'release-notes',
                              ),
                            ],
                            skillActivations: [
                              MessageSkillActivation(
                                name: 'release-notes',
                                contentDigest: 'abc123',
                                trigger: 'manual',
                              ),
                            ],
                          ),
                          timestamp: DateTime(2026),
                        ),
                        Message(
                          messageId: 'message-assistant',
                          turnId: 'turn-1',
                          runId: 'run-1',
                          chatId: 'chat-1',
                          botId: 'bot-1',
                          senderId: 'bot-1',
                          content: '处理完成',
                          processInfo: const MessageProcessInfo(
                            durationMs: 1000,
                            toolCalls: [
                              MessageToolCall(
                                name: 'mcp.docs.search',
                                title: '搜索文档',
                                mcpServerName: '文档服务',
                                status: 'completed',
                                source: 'mcp',
                                riskLevel: 'readOnly',
                              ),
                              MessageToolCall(
                                name: 'read_file',
                                status: 'awaitingApproval',
                                source: 'builtIn',
                                riskLevel: 'write',
                                detail: 'tool_execution_failed',
                                approvalStatus: 'allowOnce',
                              ),
                            ],
                          ),
                          timestamp: DateTime(2026),
                        ),
                      ],
                      scrollController: scrollController,
                      isStreaming: false,
                      streamingResponse: '',
                      currentUserId: 'user',
                      isDesktop: true,
                    ),
                  ],
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();

      final executionStatus = find.text('执行状态');
      expect(executionStatus, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('desktop-execution-status')),
        findsOneWidget,
      );
      expect(find.text('技能 1'), findsOneWidget);
      expect(find.text('MCP 1'), findsOneWidget);
      expect(find.text('release-notes').hitTestable(), findsNothing);
      expect(find.text('文档服务 · 搜索文档').hitTestable(), findsNothing);

      await tester.tap(executionStatus);
      await tester.pumpAndSettle();

      expect(find.text('release-notes'), findsNWidgets(2));
      expect(find.text('release-notes').hitTestable(), findsOneWidget);
      expect(find.text('activate_skill').hitTestable(), findsOneWidget);
      expect(find.text('文档服务 · 搜索文档').hitTestable(), findsOneWidget);
      expect(find.text('read_file').hitTestable(), findsOneWidget);
      expect(find.text('按消息启用 · abc123'), findsOneWidget);
      expect(find.text('MCP · 只读').hitTestable(), findsOneWidget);
      expect(find.text('内置 · 写入 · 失败 · 已允许一次').hitTestable(), findsOneWidget);
      expect(find.text('等待确认').hitTestable(), findsOneWidget);
      expect(find.textContaining('builtIn'), findsNothing);
      expect(find.textContaining('readOnly'), findsNothing);
      expect(find.textContaining('allowOnce'), findsNothing);
      expect(find.textContaining('tool_execution_failed'), findsNothing);

      await tester.tap(executionStatus);
      await tester.pumpAndSettle();

      expect(find.text('release-notes').hitTestable(), findsNothing);
      expect(find.text('read_file').hitTestable(), findsNothing);
    },
  );

  testWidgets('mobile hides execution status below user messages', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: Column(
                children: [
                  MessageList(
                    messages: [
                      Message(
                        messageId: 'message-user',
                        turnId: 'turn-1',
                        runId: 'run-1',
                        chatId: 'chat-1',
                        botId: 'bot-1',
                        senderId: 'user',
                        content: '使用技能处理',
                        processInfo: const MessageProcessInfo(
                          durationMs: 100,
                          toolCalls: [
                            MessageToolCall(
                              name: 'activate_skill',
                              status: 'completed',
                            ),
                          ],
                          skillActivations: [
                            MessageSkillActivation(
                              name: 'release-notes',
                              contentDigest: 'abc123',
                              trigger: 'model',
                            ),
                          ],
                        ),
                        timestamp: DateTime(2026),
                      ),
                    ],
                    scrollController: scrollController,
                    isStreaming: false,
                    streamingResponse: '',
                    currentUserId: 'user',
                  ),
                ],
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('执行状态'), findsNothing);
    expect(find.text('技能 1'), findsNothing);
    expect(find.text('release-notes'), findsNothing);
    expect(find.text('activate_skill'), findsNothing);
  });

  testWidgets('desktop execution details scroll after reaching max height', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 720,
                  child: ProcessInfoSection(
                    isDesktop: true,
                    isStreaming: true,
                    processInfo: MessageProcessInfo(
                      commandExecutions: [
                        for (var index = 0; index < 30; index++)
                          MessageCommandExecution(
                            command: 'command-$index',
                            status: 'completed',
                            detail: 'detail-$index',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('command-0').hitTestable(), findsNothing);

    await tester.tap(find.text('执行状态'));
    await tester.pumpAndSettle();

    expect(find.text('command-0').hitTestable(), findsOneWidget);
    final scrollable = find.byKey(
      const ValueKey<String>('execution-details-scroll'),
    );
    expect(scrollable, findsOneWidget);
    expect(
      tester.getSize(scrollable).height,
      lessThanOrEqualTo(ProcessInfoSection.desktopDetailsMaxHeight),
    );

    final scrollView = tester.widget<SingleChildScrollView>(scrollable);
    expect(scrollView.controller, isNotNull);
    expect(scrollView.controller!.position.maxScrollExtent, greaterThan(0));

    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scrollView.controller!.offset, greaterThan(0));
  });

  testWidgets('message execution status can be hidden by preference', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: Column(
                children: [
                  MessageList(
                    messages: const [],
                    scrollController: scrollController,
                    isStreaming: true,
                    streamingResponse: '回复信息',
                    streamingProcessInfo: const MessageProcessInfo(
                      durationMs: 1200,
                    ),
                    currentUserId: 'user',
                    isDesktop: true,
                    showExecutionStatus: false,
                  ),
                ],
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('回复信息'), findsOneWidget);
    expect(find.text('执行状态'), findsNothing);
    expect(find.textContaining('输入 Token'), findsNothing);
    expect(find.textContaining('输出 Token'), findsNothing);
  });

  testWidgets('chat row menu does not show a row focus ring on pointer use', (
    tester,
  ) async {
    await withDesktopPlatform(() async {
      var openCount = 0;
      final registry = ChatGenerationRegistry(
        messagePersister: (message) async => message,
        lastMessageUpdater: (_, _) async {},
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
        find.byIcon(LucideIcons.messageCircle),
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

        final registry = ChatGenerationRegistry(
          messagePersister: (message) async => message,
          lastMessageUpdater: (_, _) async {},
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
      final registry = ChatGenerationRegistry(
        messagePersister: (message) async => message,
        lastMessageUpdater: (_, _) async {},
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
