import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stars/data/repositories/local_conversation_directory_repository.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('stars-directory-browser-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'reads one directory level, sorts folders first, and skips links',
    () async {
      final conversationDirectory = await Directory(
        path.join(root.path, 'chat-1'),
      ).create(recursive: true);
      final nestedDirectory =
          await Directory(
            path.join(conversationDirectory.path, 'notes'),
          ).create();
      await File(
        path.join(nestedDirectory.path, 'summary.md'),
      ).writeAsString('summary');
      await File(
        path.join(conversationDirectory.path, 'image.png'),
      ).writeAsBytes(const [1, 2, 3]);
      try {
        await Link(
          path.join(conversationDirectory.path, 'outside-link'),
        ).create(root.path);
      } on FileSystemException {
        // Creating links can require elevated privileges on Windows.
      }
      final repository = LocalConversationDirectoryRepository(
        directoryProvider: (_) async => conversationDirectory.path,
      );

      final snapshot = await repository.read('chat-1');

      expect(snapshot.path, conversationDirectory.path);
      expect(snapshot.relativePath, isEmpty);
      expect(snapshot.entries.map((entry) => entry.relativePath), [
        'notes',
        'image.png',
      ]);
      expect(snapshot.entries.first.isDirectory, isTrue);
      expect(snapshot.entries[1].sizeBytes, 3);
      expect(
        snapshot.entries.any((entry) => entry.name == 'outside-link'),
        isFalse,
      );

      final nestedSnapshot = await repository.read(
        'chat-1',
        relativePath: 'notes',
      );

      expect(nestedSnapshot.path, nestedDirectory.path);
      expect(nestedSnapshot.relativePath, 'notes');
      expect(nestedSnapshot.entries.map((entry) => entry.relativePath), [
        path.join('notes', 'summary.md'),
      ]);
    },
  );

  test('rejects paths outside the conversation directory', () async {
    final conversationDirectory = await Directory(
      path.join(root.path, 'chat-1'),
    ).create(recursive: true);
    final repository = LocalConversationDirectoryRepository(
      directoryProvider: (_) async => conversationDirectory.path,
    );

    await expectLater(
      repository.read('chat-1', relativePath: path.join('..', 'outside')),
      throwsA(
        isA<AppFailure>()
            .having(
              (failure) => failure.code,
              'code',
              'conversation_directory_path_invalid',
            )
            .having(
              (failure) => failure.kind,
              'kind',
              AppFailureKind.validation,
            ),
      ),
    );
  });

  test('wraps directory failures in a safe storage failure', () async {
    final repository = LocalConversationDirectoryRepository(
      directoryProvider:
          (_) async => throw const FileSystemException('sensitive path'),
    );

    await expectLater(
      repository.read('chat-1'),
      throwsA(
        isA<AppFailure>()
            .having(
              (failure) => failure.code,
              'code',
              'conversation_directory_read_failed',
            )
            .having((failure) => failure.kind, 'kind', AppFailureKind.storage),
      ),
    );
  });
}
