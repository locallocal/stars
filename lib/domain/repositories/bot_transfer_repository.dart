import 'package:stars/domain/models/bot_export_document.dart';

enum BotExportResult { saved, cancelled }

/// Reads and writes portable, secret-free Bot configuration documents.
abstract interface class BotTransferRepository {
  Future<BotExportResult> exportBot(
    BotExportDocument document, {
    required String suggestedFileName,
    required String dialogTitle,
  });

  /// Returns `null` when the platform file picker is cancelled.
  Future<BotExportDocument?> importBot({required String dialogTitle});
}
