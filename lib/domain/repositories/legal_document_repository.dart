import 'package:stars/domain/models/legal_document.dart';

abstract interface class LegalDocumentRepository {
  Future<String> getDocument({
    required LegalDocumentType type,
    required String localeName,
  });
}
