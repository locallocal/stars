import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/conversation_directory_repository.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';

void main() {
  test('opens a directory, searches its files, and navigates up', () async {
    final repository = _DirectoryRepository({
      '': ConversationDirectorySnapshot(
        path: '/data/chats/chat-1',
        relativePath: '',
        entries: [
          ConversationDirectoryEntry(
            name: 'Notes',
            relativePath: 'Notes',
            isDirectory: true,
            modifiedAt: _timestamp,
          ),
          ConversationDirectoryEntry(
            name: 'image.png',
            relativePath: 'image.png',
            isDirectory: false,
            modifiedAt: _timestamp,
            sizeBytes: 128,
          ),
        ],
      ),
      'Notes': ConversationDirectorySnapshot(
        path: '/data/chats/chat-1/Notes',
        relativePath: 'Notes',
        entries: [
          ConversationDirectoryEntry(
            name: 'summary.md',
            relativePath: 'Notes/summary.md',
            isDirectory: false,
            modifiedAt: _timestamp,
            sizeBytes: 42,
          ),
        ],
      ),
    });
    final viewModel = ConversationDirectoryViewModel(
      chatId: 'chat-1',
      repository: repository,
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();
    expect(viewModel.canNavigateUp, isFalse);
    expect(
      viewModel.filePathFor(viewModel.visibleEntries.last),
      path.join('/data/chats/chat-1', 'image.png'),
    );
    expect(viewModel.filePathFor(viewModel.visibleEntries.first), isNull);

    await viewModel.openDirectory(viewModel.visibleEntries.first);
    viewModel.search('SUMMARY');

    expect(viewModel.directoryPath, '/data/chats/chat-1/Notes');
    expect(viewModel.canNavigateUp, isTrue);
    expect(viewModel.visibleEntries.single.name, 'summary.md');
    expect(viewModel.error, isNull);
    expect(viewModel.loading, isFalse);

    await viewModel.navigateUp();

    expect(viewModel.directoryPath, '/data/chats/chat-1');
    expect(viewModel.query, isEmpty);
    expect(viewModel.canNavigateUp, isFalse);
    expect(viewModel.visibleEntries, hasLength(2));
    expect(repository.requestedPaths, ['', 'Notes', '']);
  });

  test('exposes a safe failure when loading fails', () async {
    final viewModel = ConversationDirectoryViewModel(
      chatId: 'chat-1',
      repository: _DirectoryRepository.error(StateError('private path')),
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();

    expect(viewModel.error?.code, 'conversation_directory_load_failed');
    expect(viewModel.snapshot, isNull);
    expect(viewModel.loading, isFalse);
  });
}

final _timestamp = DateTime.utc(2026, 8, 27, 12);

final class _DirectoryRepository implements ConversationDirectoryRepository {
  _DirectoryRepository(this.snapshots) : error = null;

  _DirectoryRepository.error(this.error)
    : snapshots = const <String, ConversationDirectorySnapshot>{};

  final Map<String, ConversationDirectorySnapshot> snapshots;
  final Object? error;
  final List<String> requestedPaths = [];

  @override
  Future<ConversationDirectorySnapshot> read(
    String chatId, {
    String relativePath = '',
  }) async {
    requestedPaths.add(relativePath);
    if (error case final error?) throw error;
    return snapshots[relativePath]!;
  }
}
