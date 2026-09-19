enum MediaExportResult { saved, cancelled }

abstract interface class MessageActionRepository {
  String? get localFileHomeDirectory;

  Future<bool> localFileExists(String path);

  Future<MediaExportResult> saveImage({
    required String sourcePath,
    required String dialogTitle,
  });

  Future<void> shareImage({required String sourcePath, required String text});

  Future<bool> openExternal(Uri uri);

  Future<bool> openLocalFile(String path);
}
