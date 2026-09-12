import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/use_cases/create_chat.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/bots/views/add_bot.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/views/message_input.dart';
import 'package:stars/ui/features/chats/view_models/new_chat_view_model.dart';
import 'package:stars/ui/features/chats/views/chat_list_builder.dart';
import 'package:stars/ui/features/chats/views/new_chat_dialog.dart';
import 'package:stars/utils/theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'desktop creates a bot and chat, sends, cancels, then deletes the chat',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1280, 900);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const _DesktopWorkflowApp());
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('workflow-add-bot')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AddBotDialog), findsOneWidget);

        await tester.enterText(_editableInside('add-bot-name'), 'Workflow Bot');
        await tester.enterText(
          _editableInside('add-bot-api-key'),
          'integration-secret',
        );
        final refreshModels = find.byIcon(LucideIcons.refreshCw);
        await tester.ensureVisible(refreshModels);
        await tester.pumpAndSettle();
        await tester.tap(refreshModels);
        await tester.pumpAndSettle();
        final modelMenu = find.byKey(
          const ValueKey<String>('add-bot-model-menu'),
        );
        await tester.ensureVisible(modelMenu);
        await tester.pumpAndSettle();
        await tester.tap(modelMenu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('integration-model').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('add-bot-submit')));
        await tester.pumpAndSettle();

        expect(find.byType(AddBotDialog), findsNothing);
        expect(find.text('Workflow Bot'), findsWidgets);

        await tester.tap(
          find.byKey(const ValueKey<String>('workflow-new-chat')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(NewChatDialog), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey<String>('workflow-bot')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('workflow-composer')),
          findsOneWidget,
        );
        final composer = find.descendant(
          of: find.byKey(const ValueKey<String>('workflow-composer')),
          matching: find.byType(ShadTextarea),
        );
        await tester.tap(composer);
        await tester.enterText(composer, 'Run the desktop workflow');
        await tester.pump();
        await tester.tap(find.widgetWithText(ShadButton, '发送'));
        await tester.pumpAndSettle();
        expect(find.text('停止'), findsOneWidget);
        expect(find.text('Run the desktop workflow'), findsOneWidget);

        await tester.tap(find.text('停止'));
        await tester.pumpAndSettle();
        expect(find.text('已取消生成'), findsOneWidget);

        await tester.tap(find.byIcon(LucideIcons.ellipsis));
        await tester.pumpAndSettle();
        await tester.tap(find.text('删除').last);
        await tester.pumpAndSettle();
        expect(find.text('删除会话'), findsOneWidget);
        await tester.tap(find.text('删除').last);
        await tester.pumpAndSettle();

        expect(find.text('会话已删除'), findsOneWidget);
        expect(find.byIcon(LucideIcons.ellipsis), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}

Finder _editableInside(String key) => find.descendant(
  of: find.byKey(ValueKey<String>(key)),
  matching: find.byType(EditableText),
);

class _DesktopWorkflowApp extends StatelessWidget {
  const _DesktopWorkflowApp();

  @override
  Widget build(BuildContext context) {
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
    return ShadApp.custom(
      themeMode: ThemeMode.light,
      theme: shadTheme,
      appBuilder:
          (shadContext) => MaterialApp(
            debugShowCheckedModeBanner: false,
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
            home: const Scaffold(body: _DesktopWorkflowHarness()),
          ),
    );
  }
}

class _DesktopWorkflowHarness extends StatefulWidget {
  const _DesktopWorkflowHarness();

  @override
  State<_DesktopWorkflowHarness> createState() =>
      _DesktopWorkflowHarnessState();
}

class _DesktopWorkflowHarnessState extends State<_DesktopWorkflowHarness> {
  late final _MemoryBotRepository _bots;
  late final _MemoryChatRepository _chats;
  late final CreateChat _createChat;
  late final ChatGenerationRegistry _generationRegistry;
  late final TextEditingController _composer;
  Bot? _selectedBot;
  Chat? _selectedChat;
  bool _requestInProgress = false;
  bool _cancelled = false;
  String _sentMessage = '';
  bool _deleted = false;

  @override
  void initState() {
    super.initState();
    _bots = _MemoryBotRepository();
    _chats = _MemoryChatRepository();
    _createChat = CreateChat(
      chatRepository: _chats,
      clock: () => DateTime(2026, 8, 12, 9, 42),
    );
    _composer = TextEditingController();
    _generationRegistry = ChatGenerationRegistry(
      messagePersister: (message) async => message,
      lastMessageUpdater: (_, _) async {},
      providerFactory: _WorkflowProvider.new,
    );
  }

  @override
  void dispose() {
    _generationRegistry.clear();
    _composer.dispose();
    _bots.dispose();
    _chats.dispose();
    super.dispose();
  }

  Future<void> _openAddBot() async {
    await showShadDialog<void>(
      context: context,
      builder:
          (context) => AddBotDialog(
            botId: 'workflow-bot',
            modelLoader:
                (_) async => [
                  AiModelInfo(
                    modelId: 'integration-model',
                    providerId: 'openai',
                    inputModalities: [InputModality.text],
                    outputModalities: [OutputModality.text],
                  ),
                ],
            onBotAdded: (bot, _) async {
              await _bots.addBot(bot);
              if (!mounted) return;
              setState(() => _selectedBot = bot);
              Navigator.of(this.context).pop();
            },
          ),
    );
  }

  Future<void> _openNewChat() async {
    await showShadDialog<void>(
      context: context,
      builder:
          (context) => NewChatDialog(
            viewModel: NewChatViewModel(
              botRepository: _bots,
              createChat: _createChat,
            ),
            onChatCreated: (chatId, bot) {
              setState(() {
                _selectedBot = bot;
                _selectedChat = _chats.items.singleWhere(
                  (chat) => chat.id == chatId,
                );
              });
            },
          ),
    );
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sentMessage = text;
      _composer.clear();
      _requestInProgress = true;
      _cancelled = false;
    });
  }

  void _cancel() {
    setState(() {
      _requestInProgress = false;
      _cancelled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bot = _selectedBot;
    final chat = _selectedChat;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ShadButton(
                key: const ValueKey<String>('workflow-add-bot'),
                onPressed: _openAddBot,
                leading: const Icon(LucideIcons.bot, size: 16),
                child: const Text('新增智能体'),
              ),
              ShadButton.outline(
                key: const ValueKey<String>('workflow-new-chat'),
                enabled: bot != null,
                onPressed: _openNewChat,
                leading: const Icon(LucideIcons.messageCircle, size: 16),
                child: const Text('新建会话'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (bot != null) Text(bot.name),
          if (chat != null && bot != null) ...[
            const SizedBox(height: 16),
            if (_sentMessage.isNotEmpty) Text(_sentMessage),
            if (_cancelled) const Text('已取消生成'),
            const SizedBox(height: 12),
            SizedBox(
              key: const ValueKey<String>('workflow-composer'),
              child: MessageInput(
                controller: _composer,
                provider: _WorkflowProvider(bot),
                requestInProgress: _requestInProgress,
                canCancel: _requestInProgress,
                desktopMode: true,
                onSend: _send,
                onCancelRequest: _cancel,
                onCameraPressed: () {},
                onGalleryPressed: () {},
                onFilePressed: () {},
                onImageSizeSelected: (_) {},
                onImageStyleSelected: (_) {},
                onVideoRatioSelected: (_) {},
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ChatListBuilder(
                chatList: _chats.items,
                bots: _bots.items,
                selectedChatId: chat.id,
                onChatDeleted:
                    (_) => setState(() {
                      _selectedChat = null;
                      _deleted = true;
                    }),
                onChatSelected: (_, _) {},
                onDeleteChat: _chats.deleteChat,
                generationRegistry: _generationRegistry,
              ),
            ),
          ] else
            const Spacer(),
          if (_deleted) const Text('会话已删除'),
        ],
      ),
    );
  }
}

class _WorkflowProvider extends AiProvider {
  _WorkflowProvider(super.bot);

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

class _MemoryBotRepository implements BotRepository {
  final List<Bot> items = [];
  final StreamController<List<Bot>> _changes =
      StreamController<List<Bot>>.broadcast();

  @override
  Stream<List<Bot>> get changes => _changes.stream;

  @override
  Future<void> addBot(Bot bot) async {
    items.add(bot);
    _changes.add(List<Bot>.unmodifiable(items));
  }

  @override
  Future<void> deleteBot(String id) async {
    items.removeWhere((bot) => bot.id == id);
    _changes.add(List<Bot>.unmodifiable(items));
  }

  @override
  Future<Bot?> getBot(String id) async =>
      items.where((bot) => bot.id == id).firstOrNull;

  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async =>
      List<Bot>.unmodifiable(items);

  @override
  Future<void> updateBot(Bot bot) async {}

  void dispose() => _changes.close();
}

class _MemoryChatRepository implements ChatRepository {
  final List<Chat> items = [];
  final StreamController<List<Chat>> _changes =
      StreamController<List<Chat>>.broadcast();

  @override
  Stream<List<Chat>> get changes => _changes.stream;

  @override
  Future<void> addChat(Chat chat) async {
    items.add(chat);
    _changes.add(List<Chat>.unmodifiable(items));
  }

  @override
  Future<void> clearHistory(String id) async {}

  @override
  Future<void> deleteChat(String id) async {
    items.removeWhere((chat) => chat.id == id);
    _changes.add(List<Chat>.unmodifiable(items));
  }

  @override
  Future<void> deleteChatsForBot(String botId) async {}

  @override
  Future<Chat?> getChat(String id) async =>
      items.where((chat) => chat.id == id).firstOrNull;

  @override
  Future<List<Chat>> getChats({bool forceRefresh = false}) async =>
      List<Chat>.unmodifiable(items);

  @override
  void invalidate() {}

  @override
  Future<void> updateLastMessage(String id, String content) async {}

  @override
  Future<void> updateChatName(String id, String name) async {}

  void dispose() => _changes.close();
}
