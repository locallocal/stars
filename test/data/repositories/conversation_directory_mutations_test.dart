import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stars/data/repositories/local_conversation_directory_repository.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  late Directory workspace;
  late Directory root;
  late LocalConversationDirectoryRepository repository;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('stars-entry-mutations-');
    root = await Directory(path.join(workspace.path, 'chat')).create();
    repository = LocalConversationDirectoryRepository(
      directoryProvider: (_) async => root.path,
    );
  });
  tearDown(() async => workspace.delete(recursive: true));

  test(
    'renames files and populated folders in their existing parent',
    () async {
      final folder = await Directory(path.join(root.path, 'notes')).create();
      await File(
        path.join(folder.path, 'report.md'),
      ).writeAsString('report body');
      await repository.rename(
        'chat',
        relativePath: path.join('notes', 'report.md'),
        newName: '报告.md',
      );
      expect(await File(path.join(folder.path, 'report.md')).exists(), isFalse);
      expect(
        await File(path.join(folder.path, '报告.md')).readAsString(),
        'report body',
      );

      await repository.rename(
        'chat',
        relativePath: 'notes',
        newName: 'archive',
      );
      expect(await folder.exists(), isFalse);
      expect(
        await File(path.join(root.path, 'archive', '报告.md')).readAsString(),
        'report body',
      );
      final entries = (await repository.read('chat')).entries;
      expect(entries.single.name, 'archive');
    },
  );

  test(
    'does not overwrite existing files, folders, or dangling links',
    () async {
      final source = await File(
        path.join(root.path, 'source.txt'),
      ).writeAsString('source');
      final target = await File(
        path.join(root.path, 'target.txt'),
      ).writeAsString('target');
      await Directory(path.join(root.path, 'folder')).create();
      for (final name in ['target.txt', 'folder']) {
        await expectLater(
          repository.rename('chat', relativePath: 'source.txt', newName: name),
          _failure('conversation_entry_exists'),
        );
      }
      if (!Platform.isWindows) {
        await Link(
          path.join(root.path, 'dangling'),
        ).create(path.join(workspace.path, 'missing'));
        await expectLater(
          repository.rename(
            'chat',
            relativePath: 'source.txt',
            newName: 'dangling',
          ),
          _failure('conversation_entry_exists'),
        );
      }
      expect(await source.readAsString(), 'source');
      expect(await target.readAsString(), 'target');
    },
  );

  test(
    'deletes a file and a non-empty directory while preserving siblings',
    () async {
      final folder = await Directory(
        path.join(root.path, 'notes', 'nested'),
      ).create(recursive: true);
      await File(path.join(folder.path, 'report.md')).writeAsString('nested');
      final sibling = await File(
        path.join(root.path, 'keep.txt'),
      ).writeAsString('keep');
      await File(path.join(root.path, 'delete.txt')).writeAsString('delete');
      await repository.delete('chat', relativePath: 'delete.txt');
      await repository.delete('chat', relativePath: 'notes');
      expect(await sibling.readAsString(), 'keep');
      expect(
        (await repository.read('chat')).entries.map((entry) => entry.name),
        ['keep.txt'],
      );
    },
  );

  test(
    'rejects root, absolute and escaping paths for both operations',
    () async {
      final outside = await File(
        path.join(workspace.path, 'outside.txt'),
      ).writeAsString('outside');
      for (final value in [
        '',
        '.',
        '..',
        path.join('..', 'outside.txt'),
        outside.path,
      ]) {
        await expectLater(
          repository.delete('chat', relativePath: value),
          _failure('conversation_directory_path_invalid'),
        );
        await expectLater(
          repository.rename('chat', relativePath: value, newName: 'renamed'),
          _failure('conversation_directory_path_invalid'),
        );
      }
      expect(await root.exists(), isTrue);
      expect(await outside.readAsString(), 'outside');
    },
  );

  test('rejects invalid names before touching the source', () async {
    final source = await File(
      path.join(root.path, 'source.txt'),
    ).writeAsString('source');
    for (final name in [
      '',
      '.',
      '..',
      ' ',
      '../escape',
      'sub/file',
      r'sub\file',
      'bad\u0000name',
      'bad\nname',
      'CON',
      'nul.txt',
      'bad:name',
      'name.',
      'name ',
    ]) {
      await expectLater(
        repository.rename('chat', relativePath: 'source.txt', newName: name),
        _failure('conversation_entry_name_invalid'),
      );
    }
    expect(await source.readAsString(), 'source');
  });

  test('missing source returns an actionable failure', () async {
    await expectLater(
      repository.rename('chat', relativePath: 'gone.txt', newName: 'new.txt'),
      _failure('conversation_entry_missing'),
    );
    await expectLater(
      repository.delete('chat', relativePath: 'gone.txt'),
      _failure('conversation_entry_missing'),
    );
  });

  test('unchanged name leaves file content intact', () async {
    final source = await File(
      path.join(root.path, 'same.txt'),
    ).writeAsString('same');
    await repository.rename(
      'chat',
      relativePath: 'same.txt',
      newName: 'same.txt',
    );
    expect(await source.readAsString(), 'same');
  });

  test(
    'does not follow links through stale directory paths',
    () async {
      final outside =
          await Directory(path.join(workspace.path, 'outside')).create();
      final valuable = await File(
        path.join(outside.path, 'keep.txt'),
      ).writeAsString('keep');
      await Link(path.join(root.path, 'shortcut')).create(outside.path);
      for (final relativePath in [
        'shortcut',
        path.join('shortcut', 'keep.txt'),
      ]) {
        await expectLater(
          repository.delete('chat', relativePath: relativePath),
          _failure('conversation_directory_path_invalid'),
        );
        await expectLater(
          repository.rename('chat', relativePath: relativePath, newName: 'new'),
          _failure('conversation_directory_path_invalid'),
        );
      }
      await expectLater(
        repository.read('chat', relativePath: 'shortcut'),
        _failure('conversation_directory_path_invalid'),
      );
      expect(await valuable.readAsString(), 'keep');
    },
    skip: Platform.isWindows,
  );

  test(
    'recursive delete removes child links without deleting their targets',
    () async {
      final outside = await File(
        path.join(workspace.path, 'outside.txt'),
      ).writeAsString('keep');
      final folder = await Directory(path.join(root.path, 'folder')).create();
      await Link(path.join(folder.path, 'shortcut')).create(outside.path);
      await repository.delete('chat', relativePath: 'folder');
      expect(await folder.exists(), isFalse);
      expect(await outside.readAsString(), 'keep');
    },
    skip: Platform.isWindows,
  );
}

Matcher _failure(String code) =>
    throwsA(isA<AppFailure>().having((failure) => failure.code, 'code', code));
