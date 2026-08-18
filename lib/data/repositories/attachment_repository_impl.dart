import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:stars/data/services/application_data_directory.dart';
import 'package:stars/data/services/attachment_picker_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';

typedef AttachmentDocumentsDirectoryProvider = Future<Directory> Function();

class AttachmentRepositoryImpl implements ConversationAssetRepository {
  AttachmentRepositoryImpl({
    required AttachmentPickerService service,
    AttachmentDocumentsDirectoryProvider? documentsDirectoryProvider,
  }) : _service = service,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getStarsApplicationDocumentsDirectory;

  final AttachmentPickerService _service;
  final AttachmentDocumentsDirectoryProvider _documentsDirectoryProvider;

  @override
  Future<String?> captureImage() => _service.captureImage();

  @override
  Future<String?> selectImage() => _service.selectImage();

  @override
  Future<String?> selectFile() => _service.selectFile();

  @override
  Future<List<String>> persistAssets({
    required String chatId,
    required Iterable<String> sourcePaths,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(chatId)) {
      throw const AppFailure.validation('invalid_chat_id');
    }
    final sources = sourcePaths.toList(growable: false);
    if (sources.isEmpty) return const [];

    final root = await _documentsDirectoryProvider();
    final directory = Directory(path.join(root.path, 'chats', chatId));
    try {
      await directory.create(recursive: true);
    } on Object catch (error) {
      throw AppFailure.storage(
        'conversation_directory_create_failed',
        cause: error,
      );
    }

    final staged = <_StagedAsset>[];
    final results = <String>[];
    try {
      for (var index = 0; index < sources.length; index++) {
        final source = File(sources[index]);
        if (!await source.exists()) {
          throw AppFailure.storage(
            'attachment_source_missing',
            cause: sources[index],
          );
        }
        final digest = await sha256.bind(source.openRead()).first;
        final extension = path.extension(source.path).toLowerCase();
        final destination = File(
          path.join(directory.path, '${digest.toString()}$extension'),
        );
        results.add(destination.path);
        if (await destination.exists() ||
            staged.any((asset) => asset.destination.path == destination.path)) {
          continue;
        }
        final temporary = File(
          path.join(
            directory.path,
            '.asset_${digest.toString()}_${index}_'
            '${DateTime.now().microsecondsSinceEpoch}.tmp',
          ),
        );
        await source.copy(temporary.path);
        staged.add(
          _StagedAsset(temporary: temporary, destination: destination),
        );
      }

      for (final asset in staged) {
        await asset.temporary.rename(asset.destination.path);
        asset.committed = true;
      }
      return List<String>.unmodifiable(results);
    } on Object catch (error) {
      for (final asset in staged.reversed) {
        try {
          if (await asset.temporary.exists()) await asset.temporary.delete();
          if (asset.committed && await asset.destination.exists()) {
            await asset.destination.delete();
          }
        } on FileSystemException {
          // Cleanup is best effort; staged names are never returned to callers.
        }
      }
      throw AppFailure.from(error, code: 'attachment_persist_failed');
    }
  }

  @override
  Future<String> getOutputDirectory(String chatId) async {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(chatId)) {
      throw const AppFailure.validation('invalid_chat_id');
    }
    final root = await _documentsDirectoryProvider();
    final directory = Directory(path.join(root.path, 'chats', chatId));
    await directory.create(recursive: true);
    return directory.path;
  }
}

final class _StagedAsset {
  _StagedAsset({required this.temporary, required this.destination});

  final File temporary;
  final File destination;
  bool committed = false;
}
