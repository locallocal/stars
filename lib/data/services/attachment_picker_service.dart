import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

typedef ImagePathPicker =
    Future<String?> Function({
      required ImageSource source,
      int? imageQuality,
      double? maxWidth,
      double? maxHeight,
    });
typedef FilePathPicker = Future<String?> Function();

class AttachmentPickerService {
  AttachmentPickerService({
    ImagePathPicker imagePathPicker = _pickImagePath,
    FilePathPicker filePathPicker = _pickFilePath,
  }) : _imagePathPicker = imagePathPicker,
       _filePathPicker = filePathPicker;

  final ImagePathPicker _imagePathPicker;
  final FilePathPicker _filePathPicker;

  Future<String?> captureImage() => _imagePathPicker(
    source: ImageSource.camera,
    imageQuality: 80,
    maxWidth: 1200,
    maxHeight: 1200,
  );

  Future<String?> selectImage() => _imagePathPicker(
    source: ImageSource.gallery,
    imageQuality: 80,
    maxWidth: 1200,
    maxHeight: 1200,
  );

  Future<String?> selectFile() => _filePathPicker();
}

Future<String?> _pickImagePath({
  required ImageSource source,
  int? imageQuality,
  double? maxWidth,
  double? maxHeight,
}) async {
  final image = await ImagePicker().pickImage(
    source: source,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );
  return image?.path;
}

Future<String?> _pickFilePath() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'txt', 'doc', 'docx'],
  );
  return result?.files.single.path;
}
