import 'package:stars/domain/models/app_failure.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';

final class MessageActionViewModel {
  const MessageActionViewModel({required MessageActionRepository repository})
    : _repository = repository;

  final MessageActionRepository _repository;

  Future<MediaExportResult> saveImage({
    required String sourcePath,
    required String dialogTitle,
  }) async {
    try {
      return await _repository.saveImage(
        sourcePath: sourcePath,
        dialogTitle: dialogTitle,
      );
    } on Object catch (error) {
      throw AppFailure.from(error, code: 'message_image_export_failed');
    }
  }

  Future<void> shareImage({
    required String sourcePath,
    required String text,
  }) async {
    try {
      await _repository.shareImage(sourcePath: sourcePath, text: text);
    } on Object catch (error) {
      throw AppFailure.from(error, code: 'message_image_share_failed');
    }
  }

  Future<bool> openExternal(String href) async {
    final uri = Uri.tryParse(href.trim());
    if (uri == null ||
        !((uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host.isNotEmpty ||
            uri.scheme == 'mailto')) {
      return false;
    }
    try {
      return await _repository.openExternal(uri);
    } on Object {
      return false;
    }
  }

  Future<bool> openLocalFile(String path) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) return false;
    try {
      return await _repository.openLocalFile(normalizedPath);
    } on Object {
      return false;
    }
  }
}
