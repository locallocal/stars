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
      final rootPath = path.normalize(rootDirectory.absolute.path);
      final normalizedRelativePath = _normalizeRelativePath(relativePath);
      final currentPath = path.normalize(
        path.join(rootPath, normalizedRelativePath),
      );
      if (currentPath != rootPath && !path.isWithin(rootPath, currentPath)) {
        throw const AppFailure.validation(
          'conversation_directory_path_invalid',
        );
      }
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

  String _normalizeRelativePath(String value) {
    if (value.isEmpty) return '';
    if (path.isAbsolute(value)) {
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
