import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:stars/data/services/application_data_directory.dart';
import 'package:stars/domain/models/conversation_memory.dart';

typedef SummaryDocumentsDirectoryProvider = Future<Directory> Function();

final class StoredConversationSummary {
  const StoredConversationSummary({
    required this.fileName,
    required this.contentDigest,
    required this.contentBytes,
  });

  final String fileName;
  final String contentDigest;
  final int contentBytes;
}

final class ConversationSummaryStorageException implements Exception {
  const ConversationSummaryStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class StagedConversationDeletion {
  StagedConversationDeletion({
    required Directory original,
    required Directory staged,
    required this.recreateOriginal,
  }) : _original = original,
       _staged = staged;

  final Directory _original;
  final Directory _staged;
  final bool recreateOriginal;

  Future<void> rollback() async {
    if (!await _staged.exists()) return;
    await _original.parent.create(recursive: true);
    if (await _original.exists()) await _original.delete(recursive: true);
    await _staged.rename(_original.path);
  }

  Future<void> commit() async {
    try {
      if (await _staged.exists()) await _staged.delete(recursive: true);
      if (recreateOriginal && !await _original.exists()) {
        await _original.create(recursive: true);
      }
    } on FileSystemException {
      // The staged path remains outside normal reads and startup recovery will
      // retry physical deletion.
    }
  }
}

/// Owns all path construction and integrity checking for conversation summaries.
final class ConversationSummaryStorage {
  ConversationSummaryStorage({
    SummaryDocumentsDirectoryProvider? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getStarsApplicationDocumentsDirectory;

  final SummaryDocumentsDirectoryProvider _documentsDirectoryProvider;

  Future<StoredConversationSummary> write({
    required String chatId,
    required String summaryId,
    required String markdown,
  }) async {
    _validateId(chatId, 'chatId');
    _validateId(summaryId, 'summaryId');
    final normalized = markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final bytes = utf8.encode(normalized);
    final directory = await _summaryDirectory(chatId);
    await directory.create(recursive: true);
    final fileName = '$summaryId.md';
    final destination = File(path.join(directory.path, fileName));
    if (await destination.exists()) {
      throw ConversationSummaryStorageException(
        'Summary $summaryId already exists and is immutable.',
      );
    }
    final temporary = File(
      path.join(
        directory.path,
        '.$summaryId.${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    try {
      final sink = temporary.openWrite(encoding: utf8);
      sink.write(normalized);
      await sink.flush();
      await sink.close();
      await temporary.rename(destination.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
    return StoredConversationSummary(
      fileName: fileName,
      contentDigest: sha256.convert(bytes).toString(),
      contentBytes: bytes.length,
    );
  }

  Future<String> read(ConversationSummaryMetadata metadata) async {
    _validateId(metadata.chatId, 'chatId');
    _validateId(metadata.id, 'summaryId');
    final expectedName = '${metadata.id}.md';
    if (metadata.fileName != expectedName) {
      throw const ConversationSummaryStorageException(
        'Summary metadata contains an invalid file name.',
      );
    }
    final directory = await _summaryDirectory(metadata.chatId);
    final file = File(path.join(directory.path, expectedName));
    if (!await file.exists()) {
      throw const ConversationSummaryStorageException(
        'Summary Markdown file is missing.',
      );
    }
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    if (digest != metadata.contentDigest ||
        bytes.length != metadata.contentBytes) {
      throw const ConversationSummaryStorageException(
        'Summary Markdown failed its integrity check.',
      );
    }
    return utf8.decode(bytes);
  }

  Future<void> deleteSummary(String chatId, String summaryId) async {
    _validateId(chatId, 'chatId');
    _validateId(summaryId, 'summaryId');
    final directory = await _summaryDirectory(chatId);
    final file = File(path.join(directory.path, '$summaryId.md'));
    if (await file.exists()) await file.delete();
  }

  Future<void> clearSummaries(String chatId) async {
    _validateId(chatId, 'chatId');
    final directory = await _summaryDirectory(chatId);
    if (await directory.exists()) await directory.delete(recursive: true);
    await directory.create(recursive: true);
  }

  Future<void> deleteChatDirectory(String chatId) async {
    _validateId(chatId, 'chatId');
    final root = await _documentsDirectoryProvider();
    final directory = Directory(path.join(root.path, 'chats', chatId));
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<StagedConversationDeletion?> stageForChatClear(String chatId) =>
      _stage(chatId: chatId, summariesOnly: true);

  Future<StagedConversationDeletion?> stageForChatDeletion(String chatId) =>
      _stage(chatId: chatId, summariesOnly: false);

  Future<void> recoverPendingDeletions() async {
    final root = await _documentsDirectoryProvider();
    final pending = Directory(path.join(root.path, '.pending_deletions'));
    if (!await pending.exists()) return;
    await for (final entity in pending.list(followLinks: false)) {
      try {
        await entity.delete(recursive: true);
      } on FileSystemException {
        // Keep it invisible and retry on the next startup.
      }
    }
  }

  Future<StagedConversationDeletion?> _stage({
    required String chatId,
    required bool summariesOnly,
  }) async {
    _validateId(chatId, 'chatId');
    final root = await _documentsDirectoryProvider();
    final original = Directory(
      summariesOnly
          ? path.join(root.path, 'chats', chatId, 'summaries')
          : path.join(root.path, 'chats', chatId),
    );
    if (!await original.exists()) return null;
    final pending = Directory(path.join(root.path, '.pending_deletions'));
    await pending.create(recursive: true);
    final staged = Directory(
      path.join(
        pending.path,
        '${summariesOnly ? 'clear' : 'delete'}_${chatId}_'
        '${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await original.rename(staged.path);
    if (summariesOnly) await original.create(recursive: true);
    return StagedConversationDeletion(
      original: original,
      staged: staged,
      recreateOriginal: summariesOnly,
    );
  }

  Future<Directory> _summaryDirectory(String chatId) async {
    final root = await _documentsDirectoryProvider();
    return Directory(path.join(root.path, 'chats', chatId, 'summaries'));
  }
}

void _validateId(String value, String field) {
  final safe = RegExp(r'^[A-Za-z0-9_-]+$');
  if (value.isEmpty || !safe.hasMatch(value) || value == '.' || value == '..') {
    throw ArgumentError.value(value, field, 'Unsafe application-generated ID.');
  }
}
