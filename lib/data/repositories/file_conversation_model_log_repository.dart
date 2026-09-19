import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:stars/data/repositories/file_model_log_repository.dart';
import 'package:stars/domain/repositories/model_log_repository.dart';

/// Owns one writer per conversation, shared by foreground and background work.
final class FileConversationModelLogRepository
    implements ConversationModelLogRepository {
  FileConversationModelLogRepository({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? _defaultDirectory;

  final Future<Directory> Function() _directoryProvider;
  final _conversations = <String, FileModelLogRepository>{};

  @override
  FileModelLogRepository forConversation(String chatId) {
    if (chatId.trim().isEmpty) throw ArgumentError.value(chatId, 'chatId');
    return _conversations.putIfAbsent(
      chatId,
      () => FileModelLogRepository(
        chatId: chatId,
        directoryProvider:
            () async => Directory(
              p.join(
                (await _directoryProvider()).path,
                // A fixed-size component keeps arbitrary IDs inside the log root.
                sha256.convert(utf8.encode(chatId)).toString(),
              ),
            ),
      ),
    );
  }

  Future<void> flush() async {
    await Future.wait(
      _conversations.values.map((repository) => repository.flush()),
    );
  }

  Future<void> dispose() async {
    await Future.wait(
      _conversations.values.map((repository) => repository.dispose()),
    );
  }
}

Future<Directory> _defaultDirectory() async => Directory(
  p.join(
    (await getApplicationDocumentsDirectory()).path,
    'Stars',
    'logs',
    'models',
    'conversations',
  ),
);
