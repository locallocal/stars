import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/conversation_directory_repository.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';

void main() {
  late _Repository repository;
  late ConversationDirectoryViewModel model;

  setUp(() async {
    repository = _Repository();
    model = ConversationDirectoryViewModel(
      chatId: 'chat',
      repository: repository,
    );
    await model.load();
  });
  tearDown(() => model.dispose());

  test(
    'rename refreshes the current directory and preserves the search query',
    () async {
      model.search('report');
      repository.onMutation = () async {
        repository.entries = [_entry('z-report.md'), _entry('a-report.md')];
      };
      expect(
        await model.renameEntry(model.snapshot!.entries.first, 'z-report.md'),
        isTrue,
      );
      expect(repository.operations, ['rename:notes/report.md:z-report.md']);
      expect(repository.reads, ['', 'notes']);
      expect(model.query, 'report');
      expect(model.visibleEntries.map((entry) => entry.name), [
        'a-report.md',
        'z-report.md',
      ]);
      expect(model.busy, isFalse);
    },
  );

  test(
    'deletion refreshes only after completion and blocks competing actions',
    () async {
      final pending = Completer<void>();
      repository.onMutation = () => pending.future;
      final entry = model.snapshot!.entries.single;
      final deletion = model.deleteEntry(entry);
      expect(model.mutating, isTrue);
      expect(model.snapshot!.entries, [entry]);
      expect(await model.deleteEntry(entry), isFalse);
      expect(await model.renameEntry(entry, 'other.md'), isFalse);
      await model.navigateUp();
      await model.load();
      expect(repository.reads, ['']);
      expect(repository.operations, ['delete:notes/report.md']);
      repository.entries = [];
      pending.complete();
      expect(await deletion, isTrue);
      expect(model.visibleEntries, isEmpty);
      expect(model.busy, isFalse);
    },
  );

  test(
    'failed mutation preserves the listing and exposes a separate retryable error',
    () async {
      final entry = model.snapshot!.entries.single;
      repository.onMutation =
          () async =>
              throw const AppFailure.validation('conversation_entry_exists');
      expect(await model.renameEntry(entry, 'duplicate.md'), isFalse);
      expect(model.mutationError?.code, 'conversation_entry_exists');
      expect(model.error, isNull);
      expect(model.visibleEntries, [entry]);
      expect(model.busy, isFalse);
      repository.onMutation = () async {};
      expect(await model.renameEntry(entry, 'available.md'), isTrue);
      expect(model.mutationError, isNull);
    },
  );

  test('invalid names never reach storage', () async {
    expect(
      await model.renameEntry(model.snapshot!.entries.single, '../escape'),
      isFalse,
    );
    expect(repository.operations, isEmpty);
    expect(model.mutationError?.code, 'conversation_entry_name_invalid');
  });

  test('stale entries are rejected without changing storage', () async {
    expect(await model.deleteEntry(_entry('unknown.md')), isFalse);
    expect(repository.operations, isEmpty);
    expect(model.mutationError?.code, 'conversation_entry_missing');
  });

  test(
    'successful mutation remains successful if the subsequent refresh fails',
    () async {
      repository.onMutation = () async {
        repository.readError = StateError('refresh failed');
      };
      expect(await model.deleteEntry(model.snapshot!.entries.single), isTrue);
      expect(model.mutationError, isNull);
      expect(model.error?.code, 'conversation_directory_load_failed');
      expect(model.busy, isFalse);
    },
  );

  test('completion after disposal neither refreshes nor notifies', () async {
    final pending = Completer<void>();
    repository.onMutation = () => pending.future;
    var notifications = 0;
    model.addListener(() => notifications++);
    final deletion = model.deleteEntry(model.snapshot!.entries.single);
    expect(notifications, 1);
    model.dispose();
    pending.complete();
    expect(await deletion, isFalse);
    expect(notifications, 1);
    expect(repository.reads, ['']);
  });
}

ConversationDirectoryEntry _entry(String name) => ConversationDirectoryEntry(
  name: name,
  relativePath: 'notes/$name',
  isDirectory: false,
  modifiedAt: DateTime(2026),
);

class _Repository implements ConversationDirectoryRepository {
  List<ConversationDirectoryEntry> entries = [_entry('report.md')];
  final reads = <String>[];
  final operations = <String>[];
  Future<void> Function() onMutation = () async {};
  Object? readError;

  @override
  Future<ConversationDirectorySnapshot> read(
    String chatId, {
    String relativePath = '',
  }) async {
    reads.add(relativePath);
    if (readError case final error?) throw error;
    return ConversationDirectorySnapshot(
      path: '/chat/notes',
      relativePath: 'notes',
      entries: entries,
    );
  }

  @override
  Future<void> copy(
    String chatId, {
    required String relativePath,
    required String destinationDirectory,
  }) async {}

  @override
  Future<void> rename(
    String chatId, {
    required String relativePath,
    required String newName,
  }) async {
    operations.add('rename:$relativePath:$newName');
    await onMutation();
  }

  @override
  Future<void> delete(String chatId, {required String relativePath}) async {
    operations.add('delete:$relativePath');
    await onMutation();
  }
}
