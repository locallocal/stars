import 'package:stars/data/services/attachment_picker_service.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  const AttachmentRepositoryImpl({required AttachmentPickerService service})
    : _service = service;

  final AttachmentPickerService _service;

  @override
  Future<String?> captureImage() => _service.captureImage();

  @override
  Future<String?> selectImage() => _service.selectImage();

  @override
  Future<String?> selectFile() => _service.selectFile();
}
