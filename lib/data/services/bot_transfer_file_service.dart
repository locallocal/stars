import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Small platform adapter around the file picker used by Bot transfer.
final class BotTransferFileService {
  const BotTransferFileService();

  static const int maxDocumentBytes = 1024 * 1024;

  Future<Uint8List?> pickJson({required String dialogTitle}) async {
    final file = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    if (file.size > maxDocumentBytes) {
      throw const FormatException('Bot export exceeds the size limit.');
    }
    return file.readAsBytes();
  }

  Future<bool> saveJson({
    required String dialogTitle,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final destination = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );
    return destination != null;
  }
}
