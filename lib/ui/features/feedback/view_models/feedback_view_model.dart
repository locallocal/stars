import 'package:flutter/foundation.dart';
import 'package:stars/domain/repositories/feedback_repository.dart';

class FeedbackViewModel extends ChangeNotifier {
  FeedbackViewModel({required FeedbackRepository feedbackRepository})
    : _feedbackRepository = feedbackRepository;

  final FeedbackRepository _feedbackRepository;
  bool _isSubmitting = false;
  Object? _error;

  bool get isSubmitting => _isSubmitting;
  Object? get error => _error;

  Future<bool> submit({required String content, String? contact}) async {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty || _isSubmitting) return false;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _feedbackRepository.submit(
        content: normalizedContent,
        contact: contact?.trim(),
      );
      return true;
    } catch (error) {
      _error = error;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
