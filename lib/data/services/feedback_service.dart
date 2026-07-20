import 'package:stars/services/api_service.dart';

typedef FeedbackSubmitter =
    Future<void> Function({required String content, String? contact});

class FeedbackService {
  const FeedbackService({
    FeedbackSubmitter submitter = ApiService.submitFeedback,
  }) : _submitter = submitter;

  final FeedbackSubmitter _submitter;

  Future<void> submit({required String content, String? contact}) =>
      _submitter(content: content, contact: contact);
}
