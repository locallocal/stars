abstract interface class AttachmentRepository {
  Future<String?> captureImage();

  Future<String?> selectImage();

  Future<String?> selectFile();
}
