import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/context_summarizer.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/compact_conversation.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/conversation_memory_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_memory_panel.dart';
import 'package:stars/utils/theme.dart';

void main() {
  test('publishes immutable memory item snapshots', () async {
    final repository = _MemoryRepository();
    final viewModel = ConversationMemoryViewModel(
      chatId: 'chat_1',
      bot: _bot,
      repository: repository,
      compactConversation: CompactConversation(
        messageRepository: _MessageRepository(),
        memoryRepository: repository,
        summarizerFactory: (_) => const _Summarizer(),
      ),
      conversationArtifactsDirectoryProvider: _conversationArtifactsDirectory,
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();
    final itemsSnapshot = viewModel.items;

    expect(viewModel.artifactsDirectoryPath, '/data/Stars/chats/chat_1');
    expect(() => itemsSnapshot.clear(), throwsUnsupportedError);

    repository.items.add(
      ConversationMemoryItem(
        id: 'memory_2',
        chatId: 'chat_1',
        memoryKey: 'storage.backup',
        kind: ConversationMemoryKind.fact,
        content: 'Keep a backup',
        createdAt: DateTime(2026, 8, 9),
        updatedAt: DateTime(2026, 8, 9),
      ),
    );

    expect(itemsSnapshot, hasLength(1));
    await viewModel.load();
    expect(viewModel.items, hasLength(2));
    expect(itemsSnapshot, hasLength(1));
  });

  testWidgets('shows summary, memory controls, and opens the manager', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemoryRepository();
    final viewModel = ConversationMemoryViewModel(
      chatId: 'chat_1',
      bot: _bot,
      repository: repository,
      compactConversation: CompactConversation(
        messageRepository: _MessageRepository(),
        memoryRepository: repository,
        summarizerFactory: (_) => const _Summarizer(),
      ),
      conversationArtifactsDirectoryProvider: _conversationArtifactsDirectory,
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(_harness(viewModel));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('conversation-memory-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('conversation-memory-section-title')),
      findsOneWidget,
    );
    expect(find.text('上下文与记忆'), findsOneWidget);
    expect(find.text('查看摘要'), findsOneWidget);
    expect(find.text('管理记忆'), findsOneWidget);
    expect(find.text('自动记忆'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('automatic-memory-switch')),
      findsOneWidget,
    );
    expect(find.byType(ShadSwitch), findsOneWidget);
    final summarizedTurnsValue = find.descendant(
      of: find.byKey(const ValueKey<String>('memory-summarized-turns')),
      matching: find.byType(SelectableText),
    );
    final compactionStatusValue = find.descendant(
      of: find.byKey(const ValueKey<String>('memory-compaction-status')),
      matching: find.byType(SelectableText),
    );
    final automaticMemorySwitch = find.byKey(
      const ValueKey<String>('automatic-memory-switch'),
    );
    final summarizedTurnsRow = find.byKey(
      const ValueKey<String>('memory-summarized-turns'),
    );
    final compactionStatusRow = find.byKey(
      const ValueKey<String>('memory-compaction-status'),
    );
    final automaticMemoryRow = find.byKey(
      const ValueKey<String>('automatic-memory-row'),
    );
    expect(
      tester.widget<SelectableText>(summarizedTurnsValue).textAlign,
      TextAlign.right,
    );
    expect(
      tester.widget<SelectableText>(compactionStatusValue).textAlign,
      TextAlign.right,
    );
    expect(
      tester.getRect(compactionStatusValue).center.dx,
      closeTo(tester.getRect(automaticMemorySwitch).center.dx, 0.01),
    );
    expect(
      tester.getRect(summarizedTurnsValue).center.dx,
      closeTo(tester.getRect(automaticMemorySwitch).center.dx, 0.01),
    );
    expect(
      tester.getRect(summarizedTurnsValue).right,
      closeTo(tester.getRect(summarizedTurnsRow).right, 0.01),
    );
    expect(
      tester.getRect(compactionStatusValue).right,
      closeTo(tester.getRect(compactionStatusRow).right, 0.01),
    );
    expect(
      tester.getRect(automaticMemorySwitch).right,
      closeTo(tester.getRect(automaticMemoryRow).right, 0.01),
    );
    final memoryLabelLefts = [
      tester.getRect(find.text('已摘要消息数')).left,
      tester.getRect(find.text('压缩状态')).left,
      tester.getRect(find.text('自动记忆')).left,
    ];
    expect(memoryLabelLefts[1], closeTo(memoryLabelLefts[0], 0.01));
    expect(memoryLabelLefts[2], closeTo(memoryLabelLefts[0], 0.01));

    final actionsRect = tester.getRect(
      find.byKey(const ValueKey<String>('conversation-memory-actions')),
    );
    final summaryRect = tester.getRect(
      find.byKey(const ValueKey<String>('memory-view-summary')),
    );
    final compactRect = tester.getRect(
      find.byKey(const ValueKey<String>('memory-compact-now')),
    );
    final manageRect = tester.getRect(
      find.byKey(const ValueKey<String>('memory-manage')),
    );
    expect(summaryRect.left, closeTo(actionsRect.left, 0.01));
    expect(compactRect.right, closeTo(actionsRect.right, 0.01));
    expect(summaryRect.center.dy, closeTo(manageRect.center.dy, 0.01));
    expect(summaryRect.center.dy, closeTo(compactRect.center.dy, 0.01));
    final automaticMemoryGap =
        tester
            .getSize(
              find.byKey(const ValueKey<String>('automatic-memory-icon-gap')),
            )
            .width;
    for (final key in const [
      'memory-view-summary',
      'memory-compact-now',
      'memory-manage',
    ]) {
      expect(
        tester.widget<ShadButton>(find.byKey(ValueKey<String>(key))).gap,
        automaticMemoryGap,
      );
    }
    final summaryButton = find.byKey(
      const ValueKey<String>('memory-view-summary'),
    );
    final summaryIconRect = tester.getRect(
      find.descendant(
        of: summaryButton,
        matching: find.byIcon(LucideIcons.fileText),
      ),
    );
    final summaryTextRect = tester.getRect(
      find.descendant(of: summaryButton, matching: find.text('查看摘要')),
    );
    expect(
      summaryTextRect.left - summaryIconRect.right,
      closeTo(automaticMemoryGap, 0.01),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('memory-view-summary')),
        matching: find.byIcon(LucideIcons.fileText),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('memory-compact-now')),
        matching: find.byIcon(LucideIcons.minimize2),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('memory-manage')),
        matching: find.byIcon(LucideIcons.brain),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('memory-compact-now')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('没有足够的旧上下文可压缩'), findsOneWidget);
    expect(find.byType(ShadToast), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('memory-view-summary')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('conversation-summary-dialog')),
      findsOneWidget,
    );
    _expectDesktopDialogCloseAligned(
      tester,
      dialogKey: 'conversation-summary-dialog',
      closeKey: 'conversation-summary-header-close',
    );
    expect(
      find.byKey(const ValueKey<String>('conversation-summary-surface')),
      findsOneWidget,
    );
    expect(find.text('会话摘要'), findsOneWidget);
    expect(find.textContaining('Summary'), findsOneWidget);
    final summaryMarkdown = tester.widget<Markdown>(
      find.byKey(const ValueKey<String>('conversation-summary-markdown')),
    );
    expect(summaryMarkdown.styleSheet?.h1?.fontSize, 17);
    expect(summaryMarkdown.styleSheet?.h2?.fontSize, 15);
    expect(summaryMarkdown.styleSheet?.h3?.fontSize, 14);
    expect(summaryMarkdown.styleSheet?.p?.fontSize, 14);
    expect(summaryMarkdown.styleSheet?.code?.fontSize, 12);

    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-summary-header-close')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('memory-manage')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('conversation-memory-manager-dialog')),
      findsOneWidget,
    );
    _expectDesktopDialogCloseAligned(
      tester,
      dialogKey: 'conversation-memory-manager-dialog',
      closeKey: 'conversation-memory-manager-header-close',
    );
    expect(
      find.byKey(const ValueKey<String>('memory-search-input')),
      findsOneWidget,
    );
    final memorySearchField = find.byKey(
      const ValueKey<String>('memory-search-input'),
    );
    final memorySearchInput = find.descendant(
      of: memorySearchField,
      matching: find.byType(ShadInput),
    );
    expect(tester.widget(memorySearchField), isA<StarsSearchField>());
    expect(
      tester.getSize(memorySearchField).height,
      StarsDesktopThemeSpec.botFormFieldHeight,
    );
    expect(
      tester.widget<ShadInput>(memorySearchInput).alignment,
      Alignment.centerLeft,
    );
    expect(
      tester.widget<ShadInput>(memorySearchInput).placeholderAlignment,
      Alignment.centerLeft,
    );
    expect(
      tester
          .getRect(
            find.descendant(of: memorySearchField, matching: find.byType(Text)),
          )
          .center
          .dy,
      closeTo(tester.getRect(memorySearchInput).center.dy, 0.5),
    );
    expect(
      tester
          .getRect(
            find.descendant(
              of: memorySearchField,
              matching: find.byType(EditableText),
            ),
          )
          .center
          .dy,
      closeTo(tester.getRect(memorySearchInput).center.dy, 0.5),
    );
    expect(
      find.byKey(const ValueKey<String>('memory-summary-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_1')),
      findsOneWidget,
    );
    expect(find.text('自动摘要可能不准确，当前消息始终优先。'), findsOneWidget);
    expect(find.text('Use SQLite metadata'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('memory-pin-memory_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memory-edit-memory_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memory-forget-memory_1')),
      findsOneWidget,
    );

    await tester.enterText(memorySearchInput, 'missing memory');
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('memory-summary-card')),
      findsOneWidget,
    );

    await tester.tap(find.text('清除自动记忆'));
    await tester.pumpAndSettle();

    expect(repository.hasSummary, isFalse);
    expect(repository.items, isEmpty);
    expect(
      find.byKey(const ValueKey<String>('memory-summary-card')),
      findsNothing,
    );
  });

  testWidgets('manager applies pin, edit, forget, and restore actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemoryRepository();
    final viewModel = ConversationMemoryViewModel(
      chatId: 'chat_1',
      bot: _bot,
      repository: repository,
      compactConversation: CompactConversation(
        messageRepository: _MessageRepository(),
        memoryRepository: repository,
        summarizerFactory: (_) => const _Summarizer(),
      ),
      conversationArtifactsDirectoryProvider: _conversationArtifactsDirectory,
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(_harness(viewModel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('memory-manage')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('memory-pin-memory_1')));
    await tester.pumpAndSettle();
    expect(repository.items.single.state, ConversationMemoryItemState.pinned);
    expect(repository.items.single.origin, ConversationMemoryOrigin.user);

    await tester.tap(
      find.byKey(const ValueKey<String>('memory-edit-memory_1')),
    );
    await tester.pumpAndSettle();
    final editInput = find.byKey(
      const ValueKey<String>('memory-edit-input-memory_1'),
    );
    expect(editInput, findsOneWidget);
    await tester.enterText(editInput, 'Use encrypted SQLite metadata');
    await tester.tap(
      find.byKey(const ValueKey<String>('memory-edit-save-memory_1')),
    );
    await tester.pumpAndSettle();
    expect(repository.items.single.content, 'Use encrypted SQLite metadata');

    await tester.tap(
      find.byKey(const ValueKey<String>('memory-forget-memory_1')),
    );
    await tester.pumpAndSettle();
    expect(
      repository.items.single.state,
      ConversationMemoryItemState.forgotten,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('memory-forget-memory_1')),
    );
    await tester.pumpAndSettle();
    expect(repository.items.single.state, ConversationMemoryItemState.active);
    expect(
      find.byKey(const ValueKey<String>('memory-action-error')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager paginates memory items and keeps pages valid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemoryRepository(itemCount: 12);
    final viewModel = ConversationMemoryViewModel(
      chatId: 'chat_1',
      bot: _bot,
      repository: repository,
      compactConversation: CompactConversation(
        messageRepository: _MessageRepository(),
        memoryRepository: repository,
        summarizerFactory: (_) => const _Summarizer(),
      ),
      conversationArtifactsDirectoryProvider: _conversationArtifactsDirectory,
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(_harness(viewModel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('memory-manage')));
    await tester.pumpAndSettle();

    final previousPage = find.byKey(
      const ValueKey<String>('memory-previous-page'),
    );
    final nextPage = find.byKey(const ValueKey<String>('memory-next-page'));
    final pageIndicator = find.byKey(
      const ValueKey<String>('memory-page-indicator'),
    );
    final searchInput = find.descendant(
      of: find.byKey(const ValueKey<String>('memory-search-input')),
      matching: find.byType(ShadInput),
    );
    final memoryList = find.byKey(const ValueKey<String>('memory-list'));

    expect(find.text('1 / 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_1')),
      findsOneWidget,
    );
    await tester.drag(memoryList, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_11')),
      findsNothing,
    );
    expect(
      tester.widget<StarsDesktopIconAction>(previousPage).enabled,
      isFalse,
    );
    expect(tester.widget<StarsDesktopIconAction>(nextPage).enabled, isTrue);

    await tester.tap(nextPage);
    await tester.pump();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_11')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_12')),
      findsOneWidget,
    );
    expect(tester.widget<StarsDesktopIconAction>(previousPage).enabled, isTrue);
    expect(tester.widget<StarsDesktopIconAction>(nextPage).enabled, isFalse);

    await tester.tap(previousPage);
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_1')),
      findsOneWidget,
    );

    await tester.tap(nextPage);
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.enterText(searchInput, 'Memory item 2');
    await tester.pump();

    expect(pageIndicator, findsNothing);
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_12')),
      findsNothing,
    );

    await tester.enterText(searchInput, '');
    await tester.pump();

    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(nextPage);
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);

    repository.items.removeWhere(
      (item) => item.id == 'memory_11' || item.id == 'memory_12',
    );
    await viewModel.load();
    await tester.pump();

    expect(pageIndicator, findsNothing);
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_1')),
      findsOneWidget,
    );
    await tester.drag(memoryList, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('memory-item-memory_10')),
      findsOneWidget,
    );
    expect(previousPage, findsNothing);
    expect(nextPage, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the conversation system prompt read only below memory', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final bot = Bot(
        id: 'bot<1>',
        name: 'Research & Review',
        avatar: '',
        provider: 'Test',
        baseURL: '',
        apiKey: '',
        apiType: Bot.apiTypeOpenAI,
        model: 'model',
        systemPrompt: 'Editable agent instructions.',
        createTimestamp: DateTime(2026),
        modifyTimestamp: DateTime(2026),
      );
      final repository = _MemoryRepository();
      final viewModel = ConversationMemoryViewModel(
        chatId: 'chat>2',
        bot: bot,
        repository: repository,
        compactConversation: CompactConversation(
          messageRepository: _MessageRepository(),
          memoryRepository: repository,
          summarizerFactory: (_) => const _Summarizer(),
        ),
        conversationArtifactsDirectoryProvider: _conversationArtifactsDirectory,
      );
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final memoryActions = find.byKey(
        const ValueKey<String>('conversation-memory-actions'),
      );
      final promptBlock = find.byKey(
        const ValueKey<String>('conversation-system-prompt-block'),
      );
      final promptTitle = find.byKey(
        const ValueKey<String>('conversation-system-prompt-title'),
      );
      final promptValue = find.byKey(
        const ValueKey<String>('conversation-system-prompt-value'),
      );
      final promptText = find.descendant(
        of: promptBlock,
        matching: find.byType(SelectableText),
      );
      final prompt = tester.widget<SelectableText>(promptText).data!;

      expect(promptBlock, findsOneWidget);
      expect(find.text('系统提示词'), findsOneWidget);
      expect(promptText, findsOneWidget);
      expect(find.byType(ShadTextarea), findsNothing);
      expect(
        tester.getTopLeft(promptTitle).dy,
        greaterThan(tester.getBottomLeft(memoryActions).dy),
      );
      expect(
        tester.getSemantics(promptValue),
        matchesSemantics(
          label: '系统提示词',
          value: prompt,
          isTextField: true,
          isReadOnly: true,
        ),
      );
      expect(prompt, contains('Agent ID: bot&lt;1&gt;'));
      expect(prompt, contains('Agent name: Research &amp; Review'));
      expect(prompt, contains('Current conversation ID: chat&gt;2'));
      expect(
        prompt,
        matches(
          RegExp(
            r'Current time: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
            r'(?:Z|[+-]\d{2}:\d{2})',
          ),
        ),
      );
      expect(
        prompt,
        contains(
          'Conversation artifacts directory: '
          '/data/Stars/chats/chat&gt;2',
        ),
      );
      expect(prompt, contains('Use this directory to store and access files'));
      expect(prompt, isNot(contains(bot.systemPrompt)));
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reports manager mutation failures without leaking exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemoryRepository(failMutations: true);
    final viewModel = ConversationMemoryViewModel(
      chatId: 'chat_1',
      bot: _bot,
      repository: repository,
      compactConversation: CompactConversation(
        messageRepository: _MessageRepository(),
        memoryRepository: repository,
        summarizerFactory: (_) => const _Summarizer(),
      ),
      conversationArtifactsDirectoryProvider: _conversationArtifactsDirectory,
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(_harness(viewModel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('memory-manage')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('memory-pin-memory_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
    expect(find.text('加载内容时出错，请稍后再试。'), findsOneWidget);
  });

  testWidgets('explains when a conversation summary is not available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemoryRepository(hasSummary: false);
    final viewModel = ConversationMemoryViewModel(
      chatId: 'chat_without_summary',
      bot: _bot,
      repository: repository,
      compactConversation: CompactConversation(
        messageRepository: _MessageRepository(),
        memoryRepository: repository,
        summarizerFactory: (_) => const _Summarizer(),
      ),
      conversationArtifactsDirectoryProvider: _conversationArtifactsDirectory,
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(_harness(viewModel));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('memory-view-summary')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('当前还没有可用的会话摘要。'), findsOneWidget);
    expect(find.byType(ShadToast), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('conversation-summary-dialog')),
      findsNothing,
    );
  });
}

void _expectDesktopDialogCloseAligned(
  WidgetTester tester, {
  required String dialogKey,
  required String closeKey,
}) {
  final dialog = find.byKey(ValueKey<String>(dialogKey));
  final close = find.byKey(ValueKey<String>(closeKey));
  expect(dialog, findsOneWidget);
  expect(close, findsOneWidget);
  final dialogSurface =
      find.ancestor(of: close, matching: find.byType(Stack)).first;
  expect(tester.getSize(close), const Size.square(44));
  expect(
    find.descendant(of: close, matching: find.byIcon(LucideIcons.x)),
    findsOneWidget,
  );
  expect(
    tester.getRect(dialogSurface).right - tester.getRect(close).right,
    closeTo(8, 0.01),
  );
  expect(
    tester.getRect(close).top - tester.getRect(dialogSurface).top,
    closeTo(12, 0.01),
  );
}

Widget _harness(ConversationMemoryViewModel viewModel) {
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
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 248,
                child: ConversationMemoryPanel(
                  viewModel: viewModel,
                  generationViewModel: null,
                ),
              ),
            ),
          ),
        ),
  );
}

Future<String> _conversationArtifactsDirectory(String chatId) =>
    Future.value('/data/Stars/chats/$chatId');

final _bot = Bot(
  id: 'bot_1',
  name: 'Bot',
  avatar: '',
  provider: 'Test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

final class _MemoryRepository implements ConversationMemoryRepository {
  _MemoryRepository({
    bool hasSummary = true,
    this.failMutations = false,
    int itemCount = 1,
  }) : _hasSummary = hasSummary,
       items = [
         for (var index = 1; index <= itemCount; index += 1)
           ConversationMemoryItem(
             id: 'memory_$index',
             chatId: 'chat_1',
             memoryKey: index == 1 ? 'storage.choice' : 'memory.$index',
             kind: ConversationMemoryKind.decision,
             content: index == 1 ? 'Use SQLite metadata' : 'Memory item $index',
             createdAt: DateTime(2026, 8, 8),
             updatedAt: DateTime(2026, 8, 8),
           ),
       ];

  bool _hasSummary;
  final bool failMutations;
  final List<ConversationMemoryItem> items;
  final StreamController<String> controller = StreamController.broadcast();

  bool get hasSummary => _hasSummary;

  @override
  Stream<String> get changes => controller.stream;

  @override
  Future<ConversationSummaryDocument?> getActiveSummary(String chatId) async {
    if (!_hasSummary) return null;
    final now = DateTime(2026, 8, 8);
    return ConversationSummaryDocument(
      metadata: ConversationSummaryMetadata(
        id: 'summary_1',
        chatId: chatId,
        status: ConversationSummaryStatus.active,
        fileName: 'summary_1.md',
        contentDigest: 'digest',
        contentBytes: 10,
        sourceStartMessageId: 'message_1',
        sourceEndMessageId: 'message_2',
        sourceMessageIds: const ['message_1', 'message_2'],
        sourceDigest: 'sources',
        baseRevision: 0,
        createdAt: now,
        updatedAt: now,
      ),
      markdown: '# 会话摘要\n\n- Summary',
    );
  }

  @override
  Future<List<ConversationMemoryItem>> getItems(String chatId) async => items;

  @override
  Future<ConversationMemoryState> getState(String chatId) async =>
      ConversationMemoryState(chatId: chatId, updatedAt: DateTime(2026, 8, 8));

  @override
  Future<void> saveUserItem(ConversationMemoryItem item) async {
    _failMutation();
    final index = items.indexWhere((existing) => existing.id == item.id);
    final saved = item.copyWith(origin: ConversationMemoryOrigin.user);
    if (index < 0) {
      items.add(saved);
    } else {
      items[index] = saved;
    }
  }

  @override
  Future<void> forgetItem(String chatId, String itemId) async {
    _failMutation();
    _setItemState(itemId, ConversationMemoryItemState.forgotten);
  }

  @override
  Future<void> restoreItem(String chatId, String itemId) async {
    _failMutation();
    _setItemState(itemId, ConversationMemoryItemState.active);
  }

  @override
  Future<void> setAutoMemoryEnabled(String chatId, bool enabled) async {
    _failMutation();
  }

  @override
  Future<void> clearAutomaticMemory(String chatId) async {
    _failMutation();
    _hasSummary = false;
    items.removeWhere(
      (item) =>
          item.origin == ConversationMemoryOrigin.auto &&
          item.state != ConversationMemoryItemState.forgotten,
    );
  }

  @override
  Future<void> setCompactionStatus(
    String chatId,
    ConversationCompactionStatus status, {
    String lastError = '',
  }) async {}

  void _setItemState(String itemId, ConversationMemoryItemState state) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index >= 0) items[index] = items[index].copyWith(state: state);
  }

  void _failMutation() {
    if (failMutations) throw StateError('Injected memory mutation failure.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _MessageRepository implements MessageRepository {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<Message>> getMessages(String chatId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Summarizer implements ContextSummarizer {
  const _Summarizer();

  @override
  Future<ContextSummaryResult> summarize(ContextSummaryRequest request) {
    throw UnimplementedError();
  }
}
