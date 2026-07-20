import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/legal_document.dart';
import 'package:stars/domain/repositories/legal_document_repository.dart';

class LegalDocumentViewModel extends ChangeNotifier {
  LegalDocumentViewModel({
    required LegalDocumentType type,
    required LegalDocumentRepository repository,
  }) : _type = type,
       _repository = repository;

  final LegalDocumentType _type;
  final LegalDocumentRepository _repository;

  String _content = '';
  Object? _error;
  bool _isLoading = false;
  bool _hasLoaded = false;

  String get content => _content;
  Object? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load({
    required String localeName,
    required String fallbackContent,
  }) async {
    if (_hasLoaded || _isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _content = await _repository.getDocument(
        type: _type,
        localeName: localeName,
      );
    } catch (error) {
      _error = error;
      _content = fallbackContent;
    } finally {
      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    }
  }
}
