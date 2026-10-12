import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stars/domain/models/app_failure.dart';
import 'package:stars/domain/models/conversation_directory.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/conversation_directory_repository.dart';

final class LocalConversationDirectoryRepository
    implements ConversationDirectoryRepository {
  const LocalConversationDirectoryRepository({
    required ConversationArtifactsDirectoryProvider directoryProvider,
  }) : _directoryProvider = directoryProvider;

  final ConversationArtifactsDirectoryProvider _directoryProvider;

  @override
  Future<ConversationDirectorySnapshot> read(
    String chatId, {
    String relativePath = '',
  }) async {
    try {
      final directoryPath = await _directoryProvider(chatId);
      final rootDirectory = Directory(directoryPath);
      if (!await rootDirectory.exists()) {
        await rootDirectory.create(recursive: true);
      }
      final rootPath = await rootDirectory.resolveSymbolicLinks();
      final normalizedRelativePath = _normalizeRelativePath(relativePath);
      final currentPath = await _resolvePath(rootPath, normalizedRelativePath);
      final directory = Directory(currentPath);

      final entries = <ConversationDirectoryEntry>[];
      await for (final entity in directory.list(
        recursive: false,
        followLinks: false,
      )) {
        if (entity is! File && entity is! Directory) continue;
        final stat = await _statOrNull(entity);
        if (stat == null) continue;
        final entryRelativePath = path.relative(entity.path, from: rootPath);
        entries.add(
          ConversationDirectoryEntry(
            name: path.basename(entity.path),
            relativePath: entryRelativePath,
            isDirectory: entity is Directory,
            modifiedAt: stat.modified,
            sizeBytes: entity is File ? stat.size : null,
          ),
        );
      }

      entries.sort((left, right) {
        if (left.isDirectory != right.isDirectory) {
          return left.isDirectory ? -1 : 1;
        }
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
      return ConversationDirectorySnapshot(
        path: directory.path,
        relativePath: normalizedRelativePath,
        entries: entries,
      );
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw AppFailure.storage(
        'conversation_directory_read_failed',
        cause: error,
      );
    }
  }

  @override
  Future<void> rename(
    String chatId, {
    required String relativePath,
    required String newName,
  }) async {
    try {
      if (!isValidConversationEntryName(newName)) {
        throw const AppFailure.validation('conversation_entry_name_invalid');
      }
      final source = await _resolveEntry(chatId, relativePath);
      final destination = path.join(path.dirname(source.path), newName);
      if (source.path == destination) return;
      if (await FileSystemEntity.type(destination, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw const AppFailure.validation('conversation_entry_exists');
      }
      await source.rename(destination);
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw AppFailure.storage(
        'conversation_entry_rename_failed',
        cause: error,
      );
    }
  }

  @override
  Future<void> delete(String chatId, {required String relativePath}) async {
    try {
      final entry = await _resolveEntry(chatId, relativePath);
      await entry.delete(recursive: entry is Directory);
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw AppFailure.storage(
        'conversation_entry_delete_failed',
        cause: error,
      );
    }
  }

  Future<FileSystemEntity> _resolveEntry(
    String chatId,
    String relativePath,
  ) async {
    final normalized = _normalizeRelativePath(relativePath);
    if (normalized.isEmpty) {
      throw const AppFailure.validation('conversation_directory_path_invalid');
    }
    final root = Directory(await _directoryProvider(chatId));
    final rootPath = await root.resolveSymbolicLinks();
    final entryPath = await _resolvePath(rootPath, normalized);
    return switch (await FileSystemEntity.type(entryPath, followLinks: false)) {
      FileSystemEntityType.file => File(entryPath),
      FileSystemEntityType.directory => Directory(entryPath),
      FileSystemEntityType.notFound =>
        throw const AppFailure.validation('conversation_entry_missing'),
      _ =>
        throw const AppFailure.validation(
          'conversation_directory_path_invalid',
        ),
    };
  }

  Future<String> _resolvePath(String rootPath, String relativePath) async {
    final target = path.normalize(path.join(rootPath, relativePath));
    if (target != rootPath && !path.isWithin(rootPath, target)) {
      throw const AppFailure.validation('conversation_directory_path_invalid');
    }
    var current = rootPath;
    // Check each component so a stale listing cannot traverse a replaced
    // directory or target a link outside the conversation's data directory.
    for (final segment in path.split(relativePath)) {
      current = path.join(current, segment);
      if (await FileSystemEntity.type(current, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const AppFailure.validation(
          'conversation_directory_path_invalid',
        );
      }
    }
    return target;
  }

  String _normalizeRelativePath(String value) {
    if (value.isEmpty) return '';
    if (path.isAbsolute(value) || value.contains('\u0000')) {
      throw const AppFailure.validation('conversation_directory_path_invalid');
    }
    final normalized = path.normalize(value);
    if (normalized == '.') return '';
    if (normalized == '..' || normalized.startsWith('..${path.separator}')) {
      throw const AppFailure.validation('conversation_directory_path_invalid');
    }
    return normalized;
  }

  Future<FileStat?> _statOrNull(FileSystemEntity entity) async {
    try {
      return await entity.stat();
    } on FileSystemException {
      // Files may disappear while a long-running agent is still writing.
      return null;
    }
  }
}
