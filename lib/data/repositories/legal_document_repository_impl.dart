import 'package:stars/data/services/asset_text_service.dart';
import 'package:stars/domain/models/legal_document.dart';
import 'package:stars/domain/repositories/legal_document_repository.dart';

class LegalDocumentRepositoryImpl implements LegalDocumentRepository {
  const LegalDocumentRepositoryImpl({required AssetTextService service})
    : _service = service;

  final AssetTextService _service;

  @override
  Future<String> getDocument({
    required LegalDocumentType type,
    required String localeName,
  }) async {
    final localizedPath = _assetPath(type, localeName);
    try {
      return await _service.load(localizedPath);
    } on Object {
      if (localeName == 'en_US') rethrow;
      return _service.load(_assetPath(type, 'en_US'));
    }
  }

  String _assetPath(LegalDocumentType type, String localeName) =>
      'assets/markdown/${type.assetName}_$localeName.md';
}
