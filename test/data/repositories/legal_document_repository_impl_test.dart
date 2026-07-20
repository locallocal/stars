import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/legal_document_repository_impl.dart';
import 'package:stars/data/services/asset_text_service.dart';
import 'package:stars/domain/models/legal_document.dart';

void main() {
  group('LegalDocumentRepositoryImpl', () {
    test('loads the localized document when it exists', () async {
      final repository = _repository(<String, String>{
        'assets/markdown/privacy_policy_zh_CN.md': '本地隐私政策',
      });

      final content = await repository.getDocument(
        type: LegalDocumentType.privacyPolicy,
        localeName: 'zh_CN',
      );

      expect(content, '本地隐私政策');
    });

    test('falls back to the English document', () async {
      final repository = _repository(<String, String>{
        'assets/markdown/user_agreement_en_US.md': 'English agreement',
      });

      final content = await repository.getDocument(
        type: LegalDocumentType.userAgreement,
        localeName: 'fr_FR',
      );

      expect(content, 'English agreement');
    });

    test('propagates an error when the fallback is missing', () async {
      final repository = _repository(const <String, String>{});

      expect(
        repository.getDocument(
          type: LegalDocumentType.privacyPolicy,
          localeName: 'en_US',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

LegalDocumentRepositoryImpl _repository(Map<String, String> assets) {
  return LegalDocumentRepositoryImpl(
    service: AssetTextService(
      loader: (assetPath) async {
        final content = assets[assetPath];
        if (content == null) throw StateError('Missing $assetPath');
        return content;
      },
    ),
  );
}
