import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stars/data/repositories/attachment_repository_impl.dart';
import 'package:stars/data/services/attachment_picker_service.dart';

void main() {
  group('AttachmentRepositoryImpl', () {
    late ImageSource selectedSource;
    late AttachmentRepositoryImpl repository;

    setUp(() {
      final service = AttachmentPickerService(
        imagePathPicker: ({
          required ImageSource source,
          int? imageQuality,
          double? maxWidth,
          double? maxHeight,
        }) async {
          selectedSource = source;
          return '/tmp/${source.name}.jpg';
        },
        filePathPicker: () async => '/tmp/document.pdf',
      );
      repository = AttachmentRepositoryImpl(service: service);
    });

    test('delegates camera capture to the platform service', () async {
      final path = await repository.captureImage();

      expect(selectedSource, ImageSource.camera);
      expect(path, '/tmp/camera.jpg');
    });

    test('delegates gallery selection to the platform service', () async {
      final path = await repository.selectImage();

      expect(selectedSource, ImageSource.gallery);
      expect(path, '/tmp/gallery.jpg');
    });

    test('returns the selected document path', () async {
      expect(await repository.selectFile(), '/tmp/document.pdf');
    });
  });
}
