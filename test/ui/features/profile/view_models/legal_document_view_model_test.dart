import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/legal_document.dart';
import 'package:stars/domain/repositories/legal_document_repository.dart';
import 'package:stars/ui/features/profile/view_models/legal_document_view_model.dart';

void main() {
  group('LegalDocumentViewModel', () {
    test('publishes repository content', () async {
      final viewModel = LegalDocumentViewModel(
        type: LegalDocumentType.privacyPolicy,
        repository: _FakeLegalDocumentRepository(content: 'policy'),
      );
      addTearDown(viewModel.dispose);

      await viewModel.load(localeName: 'zh_CN', fallbackContent: 'fallback');

      expect(viewModel.content, 'policy');
      expect(viewModel.error, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('publishes localized fallback content on failure', () async {
      final viewModel = LegalDocumentViewModel(
        type: LegalDocumentType.userAgreement,
        repository: _FakeLegalDocumentRepository(error: StateError('asset')),
      );
      addTearDown(viewModel.dispose);

      await viewModel.load(localeName: 'zh_CN', fallbackContent: '无法加载');

      expect(viewModel.content, '无法加载');
      expect(viewModel.error, isA<StateError>());
      expect(viewModel.isLoading, isFalse);
    });
  });
}

class _FakeLegalDocumentRepository implements LegalDocumentRepository {
  const _FakeLegalDocumentRepository({this.content, this.error});

  final String? content;
  final Object? error;

  @override
  Future<String> getDocument({
    required LegalDocumentType type,
    required String localeName,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    return content!;
  }
}
