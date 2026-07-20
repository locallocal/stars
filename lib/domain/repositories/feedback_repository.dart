abstract interface class FeedbackRepository {
  Future<void> submit({required String content, String? contact});
}
