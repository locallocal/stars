import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/conversation_directory_repository.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_directory_dialog.dart';

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
              name: 'notes',
              relativePath: 'notes',
              isDirectory: true,
              modifiedAt: DateTime.utc(2026, 8, 27, 12),
            ),
            ConversationDirectoryEntry(
              name: 'image.png',
              relativePath: 'image.png',
              isDirectory: false,
              modifiedAt: DateTime.utc(2026, 8, 27, 12),
              sizeBytes: 2048,
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

    expect(find.text('/data/chats/chat-1'), findsOneWidget);
    expect(find.text('notes'), findsOneWidget);
    expect(find.text('image.png'), findsOneWidget);
    expect(find.text('summary.md'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-directory-notes')),
    );
    await tester.pumpAndSettle();

    expect(find.text('/data/chats/chat-1/notes'), findsOneWidget);
    expect(find.text('notes'), findsNothing);
    expect(find.text('image.png'), findsNothing);
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
    expect(
      find.byKey(const ValueKey<String>('conversation-directory-no-results')),
      findsOneWidget,
    );

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
    expect(find.text('image.png'), findsOneWidget);
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

    await tester.tap(
      find.byKey(const ValueKey<String>('conversation-directory-close')),
    );
    await tester.pumpAndSettle();
  });
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
