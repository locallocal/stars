import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/conversation_directory_repository.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_directory_dialog.dart';
import 'package:stars/ui/features/chat/views/conversation_directory_page.dart';
import 'package:stars/utils/theme.dart';

import '../../../../support/widget_test_support.dart';

void main() {
  testWidgets('opens folders, lists one level, and navigates up', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 800);
    addTearDown(tester.view.reset);
    final viewModel = ConversationDirectoryViewModel(
      chatId: 'chat-1',
      repository: _DirectoryRepository({
        '': ConversationDirectorySnapshot(
          path: '/data/chats/chat-1',
          relativePath: '',
          entries: [
            ConversationDirectoryEntry(
              name: 'image.png',
              relativePath: 'image.png',
              isDirectory: false,
              modifiedAt: DateTime.utc(2026, 8, 27, 12),
              sizeBytes: 2048,
            ),
            ConversationDirectoryEntry(
              name: 'notes',
              relativePath: 'notes',
              isDirectory: true,
              modifiedAt: DateTime.utc(2026, 8, 27, 12),
            ),
            for (var index = 0; index < 20; index += 1)
              ConversationDirectoryEntry(
                name: 'file-$index.txt',
                relativePath: 'file-$index.txt',
                isDirectory: false,
                modifiedAt: DateTime.utc(2026, 8, 27, 12),
                sizeBytes: index,
              ),
          ],
        ),
        'notes': ConversationDirectorySnapshot(
          path: '/data/chats/chat-1/notes',
          relativePath: 'notes',
          entries: [
            ConversationDirectoryEntry(
              name: 'summary.md',
              relativePath: 'notes/summary.md',
              isDirectory: false,
              modifiedAt: DateTime.utc(2026, 8, 27, 12),
              sizeBytes: 42,
            ),
          ],
        ),
      }),
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const ValueKey<String>('open-conversation-directory'),
                  onPressed:
                      () => unawaited(
                        showConversationDirectoryDialog(
                          context: context,
                          viewModel: viewModel,
                        ),
                      ),
                  child: const Text('Open directory'),
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('open-conversation-directory')),
    );
    await tester.pumpAndSettle();

    final headerClose = find.byKey(
      const ValueKey<String>('conversation-directory-header-close'),
    );
    expect(headerClose, findsOneWidget);
    expect(tester.getSize(headerClose), const Size.square(44));

    final pathField = find.byKey(
      const ValueKey<String>('conversation-directory-path'),
    );
    final pathFieldWidget = tester.widget<ShadInput>(pathField);
    final pathFolderIcon = find.descendant(
      of: pathField,
      matching: find.byIcon(LucideIcons.folderOpen),
    );
    final pathText = find.descendant(
      of: pathField,
      matching: find.byType(EditableText),
    );
    expect(pathFieldWidget.readOnly, isTrue);
    expect(pathFieldWidget.alignment, Alignment.centerLeft);
    expect(pathFieldWidget.crossAxisAlignment, CrossAxisAlignment.center);
    expect(
      tester.getSize(pathField).height,
      StarsDesktopThemeSpec.botFormFieldHeight,
    );
    expect(
      tester.getCenter(pathFolderIcon).dy,
      closeTo(tester.getCenter(pathText).dy, 0.1),
    );

    expect(find.text('/data/chats/chat-1'), findsOneWidget);
    expect(find.text('notes'), findsOneWidget);
    expect(find.text('file-0.txt'), findsOneWidget);
    expect(find.text('summary.md'), findsNothing);
    expect(
      tester.getTopLeft(find.text('notes')).dy,
      lessThan(tester.getTopLeft(find.text('file-0.txt')).dy),
    );
    final entriesPanel = find.byKey(
      const ValueKey<String>('conversation-directory-entries'),
    );
    expect(tester.widget(entriesPanel), isA<Column>());
    expect(
      find.descendant(of: entriesPanel, matching: find.byType(ShadSeparator)),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-directory-notes')),
    );
    await tester.pumpAndSettle();

    expect(find.text('/data/chats/chat-1/notes'), findsOneWidget);
    expect(find.text('notes'), findsNothing);
    expect(find.text('file-0.txt'), findsNothing);
    expect(find.text('summary.md'), findsOneWidget);

    final searchField = find.descendant(
      of: find.byKey(const ValueKey<String>('conversation-directory-search')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(searchField, 'SUMMARY');
    await tester.pump();

    expect(find.text('summary.md'), findsOneWidget);

    await tester.enterText(searchField, 'missing');
    await tester.pump();
    final searchEmptyState = find.byKey(
      const ValueKey<String>('conversation-directory-no-results'),
    );
    expect(searchEmptyState, findsOneWidget);
    final emptyState = tester.widget<DesktopEmptyStateCard>(searchEmptyState);
    expect(emptyState.icon, LucideIcons.searchX);
    expect(emptyState.title, '未找到匹配的文件或文件夹。');
    expect(emptyState.description, '试试其他文件或文件夹名称，或清除搜索。');
    expect(emptyState.supportingText, '搜索会匹配当前目录中的文件和文件夹名称。');

    await tester.tap(
      find.byKey(
        const ValueKey<String>('conversation-directory-empty-clear-search'),
      ),
    );
    await tester.pump();
    expect(find.text('summary.md'), findsOneWidget);
    expect(_searchText(tester), isEmpty);

    await tester.enterText(searchField, 'missing');
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-directory-clear-search')),
    );
    await tester.pump();
    expect(find.text('summary.md'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-directory-up')),
    );
    await tester.pumpAndSettle();

    expect(find.text('/data/chats/chat-1'), findsOneWidget);
    expect(find.text('notes'), findsOneWidget);
    expect(find.text('file-0.txt'), findsOneWidget);
    expect(find.text('summary.md'), findsNothing);
    final scrollbar = tester.widget<Scrollbar>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('conversation-directory-dialog')),
        matching: find.byType(Scrollbar),
      ),
    );
    final fileList = tester.widget<ListView>(
      find.byKey(const ValueKey<String>('conversation-directory-list')),
    );
    expect(scrollbar.controller, isNotNull);
    expect(scrollbar.controller, same(fileList.controller));

    await tester.drag(
      find.byKey(const ValueKey<String>('conversation-directory-list')),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();

    await tester.tap(headerClose);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'opens an in-app preview for a file and returns to the directory',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 800);
      addTearDown(tester.view.reset);
      final directory = Directory.systemTemp.createTempSync(
        'stars-conversation-directory-preview-',
      );
      addTearDown(() {
        if (directory.existsSync()) directory.deleteSync(recursive: true);
      });
      final file = File('${directory.path}/dashboard.html');
      file.writeAsStringSync('''
<!doctype html>
<html>
  <head><title>Conversation dashboard</title></head>
  <body><h1>Preview from the conversation directory</h1></body>
</html>
''');
      final viewModel = ConversationDirectoryViewModel(
        chatId: 'chat-1',
        repository: _DirectoryRepository({
          '': ConversationDirectorySnapshot(
            path: directory.path,
            relativePath: '',
            entries: [
              ConversationDirectoryEntry(
                name: 'dashboard.html',
                relativePath: 'dashboard.html',
                isDirectory: false,
                modifiedAt: DateTime.utc(2026, 9, 2, 12),
                sizeBytes: file.lengthSync(),
              ),
            ],
          ),
        }),
      );
      addTearDown(viewModel.dispose);

      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed:
                        () => unawaited(
                          showConversationDirectoryDialog(
                            context: context,
                            viewModel: viewModel,
                          ),
                        ),
                    child: const Text('Open directory'),
                  ),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open directory'));
      await tester.pumpAndSettle();

      final fileRow = find.byKey(
        const ValueKey<String>('conversation-directory-dashboard.html'),
      );
      expect(fileRow.hitTestable(), findsOneWidget);
      expect(find.byIcon(LucideIcons.eye), findsNothing);

      await tester.tap(fileRow);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        find.byKey(const ValueKey<String>('message-local-file-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('message-local-file-html-preview')),
        findsOneWidget,
      );
      expect(find.text('Conversation dashboard'), findsOneWidget);
      expect(
        find.textContaining('Preview from the conversation directory'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('message-local-file-maximize')),
      );
      await tester.pump();

      final maximizedPreview = tester.widget<ShadDialog>(
        find.byKey(const ValueKey<String>('message-local-file-dialog')),
      );
      expect(maximizedPreview.constraints!.biggest, const Size(900, 800));
      expect(find.byIcon(LucideIcons.minimize2), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('message-local-file-close')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const ValueKey<String>('conversation-directory-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('message-local-file-dialog')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('conversation-directory-close')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    },
  );

  testWidgets('renders as a full-width desktop workspace page', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);
    final viewModel = ConversationDirectoryViewModel(
      chatId: 'chat-page',
      repository: _DirectoryRepository({
        '': ConversationDirectorySnapshot(
          path: '/data/chats/chat-page',
          relativePath: '',
          entries: [
            ConversationDirectoryEntry(
              name: 'report.md',
              relativePath: 'report.md',
              isDirectory: false,
              modifiedAt: DateTime.utc(2026, 9, 11, 12),
              sizeBytes: 1024,
            ),
          ],
        ),
      }),
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) =>
                Scaffold(body: ConversationDirectoryPage(viewModel: viewModel)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('desktop-conversation-directory')),
      findsOneWidget,
    );
    expect(find.byType(ShadDialog), findsNothing);
    final contentFinder = find.byKey(
      const ValueKey<String>('desktop-conversation-directory-content'),
    );
    final content = tester.widget<ConstrainedBox>(contentFinder);
    expect(content.constraints.maxWidth, StarsDesktopThemeSpec.contentMaxWidth);
    expect(
      tester.getSize(contentFinder).width,
      StarsDesktopThemeSpec.contentMaxWidth,
    );
    final pageTitle = find.byKey(
      const ValueKey<String>('desktop-conversation-directory-title'),
    );
    expect(
      tester.widget<Text>(pageTitle).style,
      StarsDesktopThemeSpec.pageTitleStyle(tester.element(pageTitle)),
    );
    expect(find.text('/data/chats/chat-page'), findsOneWidget);
    expect(find.text('report.md'), findsOneWidget);

    final searchField = find.descendant(
      of: find.byKey(const ValueKey<String>('conversation-directory-search')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(searchField, 'missing');
    await tester.pump();

    final searchEmptyState = find.byKey(
      const ValueKey<String>('conversation-directory-no-results'),
    );
    expect(searchEmptyState, findsOneWidget);
    expect(tester.widget(searchEmptyState), isA<DesktopEmptyStateCard>());
    expect(
      find.descendant(
        of: searchEmptyState,
        matching: find.byIcon(LucideIcons.searchX),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: searchEmptyState, matching: find.byType(ShadButton)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stacks path and search controls on a narrow viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(520, 700);
    addTearDown(tester.view.reset);
    final viewModel = ConversationDirectoryViewModel(
      chatId: 'chat-narrow',
      repository: _DirectoryRepository({
        '': ConversationDirectorySnapshot(
          path: '/data/chats/chat-narrow',
          relativePath: '',
          entries: [
            ConversationDirectoryEntry(
              name: 'dashboard.html',
              relativePath: 'dashboard.html',
              isDirectory: false,
              modifiedAt: DateTime.utc(2026, 9, 6, 12),
              sizeBytes: 512,
            ),
          ],
        ),
      }),
    );

    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed:
                      () => unawaited(
                        showConversationDirectoryDialog(
                          context: context,
                          viewModel: viewModel,
                        ),
                      ),
                  child: const Text('Open narrow directory'),
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open narrow directory'));
    await tester.pumpAndSettle();

    final path = find.byKey(
      const ValueKey<String>('conversation-directory-path'),
    );
    final search = find.byKey(
      const ValueKey<String>('conversation-directory-search'),
    );
    expect(path, findsOneWidget);
    expect(search, findsOneWidget);
    expect(
      tester.getTopLeft(search).dy,
      greaterThan(tester.getTopLeft(path).dy),
    );
    expect(find.text('dashboard.html'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-directory-close')),
    );
    await tester.pumpAndSettle();
  });
}

String _searchText(WidgetTester tester) {
  final search = find.descendant(
    of: find.byKey(const ValueKey<String>('conversation-directory-search')),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(search).controller.text;
}

final class _DirectoryRepository implements ConversationDirectoryRepository {
  const _DirectoryRepository(this.snapshots);

  final Map<String, ConversationDirectorySnapshot> snapshots;

  @override
  Future<ConversationDirectorySnapshot> read(
    String chatId, {
    String relativePath = '',
  }) async => snapshots[relativePath]!;
}
