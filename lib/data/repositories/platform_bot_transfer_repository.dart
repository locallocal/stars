import 'dart:convert';
import 'dart:typed_data';

import 'package:stars/data/services/bot_transfer_file_service.dart';
import 'package:stars/domain/models/app_failure.dart';
import 'package:stars/domain/models/bot_export_document.dart';
import 'package:stars/domain/repositories/bot_transfer_repository.dart';

final class PlatformBotTransferRepository implements BotTransferRepository {
  const PlatformBotTransferRepository({required this.fileService});

  static const int maxDocumentBytes = BotTransferFileService.maxDocumentBytes;

  final BotTransferFileService fileService;

  @override
  Future<BotExportResult> exportBot(
    BotExportDocument document, {
    required String suggestedFileName,
    required String dialogTitle,
  }) async {
    try {
      final json = '${const JsonEncoder.withIndent('  ').convert(document)}\n';
      final saved = await fileService.saveJson(
        dialogTitle: dialogTitle,
        fileName: suggestedFileName,
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      return saved ? BotExportResult.saved : BotExportResult.cancelled;
    } on Object catch (error) {
      throw AppFailure.storage('bot_export_failed', cause: error);
    }
  }

  @override
  Future<BotExportDocument?> importBot({required String dialogTitle}) async {
    try {
      final bytes = await fileService.pickJson(dialogTitle: dialogTitle);
      if (bytes == null) return null;
      if (bytes.length > maxDocumentBytes) {
        throw const FormatException('Bot export exceeds the size limit.');
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        throw const FormatException('Bot export must be a JSON object.');
      }
      return BotExportDocument.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on FormatException catch (error) {
      throw AppFailure.validation('bot_import_invalid', cause: error);
    } on ArgumentError catch (error) {
      throw AppFailure.validation('bot_import_invalid', cause: error);
    } on AppFailure {
      rethrow;
    } on Object catch (error) {
      throw AppFailure.storage('bot_import_failed', cause: error);
    }
  }
}
