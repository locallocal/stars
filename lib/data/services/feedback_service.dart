typedef FeedbackSubmitter =
    Future<void> Function({required String content, String? contact});

Future<void> _submitFeedback({required String content, String? contact}) async {
  // The endpoint is intentionally injectable until a production feedback API
  // is configured. Keeping the delay here preserves the existing behavior.
  await Future<void>.delayed(const Duration(seconds: 5));
}

class FeedbackService {
  const FeedbackService({FeedbackSubmitter submitter = _submitFeedback})
    : _submitter = submitter;

  final FeedbackSubmitter _submitter;

  Future<void> submit({required String content, String? contact}) =>
      _submitter(content: content, contact: contact);
}
