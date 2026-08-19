import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:stars/data/repositories/attachment_repository_impl.dart';
import 'package:stars/data/services/attachment_picker_service.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  late Directory root;
  late AttachmentRepositoryImpl repository;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('stars-assets-');
    repository = AttachmentRepositoryImpl(
      service: AttachmentPickerService(),
      documentsDirectoryProvider: () async => root,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('same-basename assets are unique and preserve extensions', () async {
    final firstDirectory =
        await Directory(path.join(root.path, 'source-a')).create();
    final secondDirectory =
        await Directory(path.join(root.path, 'source-b')).create();
    final first = File(path.join(firstDirectory.path, 'photo.PNG'));
    final second = File(path.join(secondDirectory.path, 'photo.PNG'));
    await first.writeAsString('first');
    await second.writeAsString('second');

    final stored = await repository.persistAssets(
      chatId: 'chat_1',
      sourcePaths: [first.path, second.path],
    );

    expect(stored, hasLength(2));
    expect(stored.toSet(), hasLength(2));
    expect(stored.every((item) => path.extension(item) == '.png'), isTrue);
    expect(await File(stored.first).readAsString(), 'first');
    expect(await File(stored.last).readAsString(), 'second');
  });

  test('a missing source rolls back every staged asset', () async {
    final source = File(path.join(root.path, 'valid.txt'));
    await source.writeAsString('valid');

    await expectLater(
      repository.persistAssets(
        chatId: 'chat_2',
        sourcePaths: [source.path, path.join(root.path, 'missing.txt')],
      ),
      throwsA(isA<AppFailure>()),
    );

    final destination = Directory(path.join(root.path, 'chats', 'chat_2'));
    expect(
      await destination.list().where((entity) => entity is File).toList(),
      isEmpty,
    );
  });

  test('selectImage accepts a supported raster image', () async {
    final image = File(path.join(root.path, 'photo.png'));
    await image.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    final imageRepository = _repositoryWithSelectedImage(root, image.path);

    expect(await imageRepository.selectImage(), image.path);
  });

  test('selectImage rejects SVG before it reaches Image.file', () async {
    final image = File(path.join(root.path, 'provider.svg'));
    await image.writeAsString('<svg xmlns="http://www.w3.org/2000/svg"/>');
    final imageRepository = _repositoryWithSelectedImage(root, image.path);

    await expectLater(
      imageRepository.selectImage(),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'unsupported_image_format',
        ),
      ),
    );
  });
}

AttachmentRepositoryImpl _repositoryWithSelectedImage(
  Directory root,
  String imagePath,
) {
  return AttachmentRepositoryImpl(
    service: AttachmentPickerService(
      imagePathPicker:
          ({
            required ImageSource source,
            int? imageQuality,
            double? maxWidth,
            double? maxHeight,
          }) async => imagePath,
    ),
    documentsDirectoryProvider: () async => root,
  );
}
