import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/platform_message_action_repository.dart';
import 'package:stars/data/repositories/platform_bot_transfer_repository.dart';
import 'package:stars/data/services/attachment_picker_service.dart';
import 'package:stars/data/services/bot_transfer_file_service.dart';
import 'package:stars/data/services/skills/skill_picker_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/domain/repositories/bot_transfer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FilePickerPlatform previousFilePicker;
  late _FakeFilePicker filePicker;

  setUp(() {
    previousFilePicker = FilePickerPlatform.instance;
    filePicker = _FakeFilePicker();
    FilePickerPlatform.instance = filePicker;
  });

  tearDown(() {
    FilePickerPlatform.instance = previousFilePicker;
  });

  test('Skill picker selects directories through the current API', () async {
    filePicker.directoryPath = '/tmp/example-skill';

    final source = await const SkillPickerService().pickDirectory();

    expect(source?.kind, SkillImportKind.directory);
    expect(source?.path, '/tmp/example-skill');
  });

  test(
    'Skill picker selects one ZIP archive through the current API',
    () async {
      filePicker.selectedFile = PlatformFile(
        name: 'example.zip',
        size: 1,
        path: '/tmp/example.zip',
      );

      final source = await const SkillPickerService().pickZipArchive();

      expect(source?.kind, SkillImportKind.zipArchive);
      expect(source?.path, '/tmp/example.zip');
      expect(filePicker.fileType, FileType.custom);
      expect(filePicker.allowedExtensions, ['zip']);
      expect(filePicker.allowMultiple, isFalse);
    },
  );

  test('Attachment picker selects one supported document', () async {
    filePicker.selectedFile = PlatformFile(
      name: 'notes.pdf',
      size: 1,
      path: '/tmp/notes.pdf',
    );

    final path = await AttachmentPickerService().selectFile();

    expect(path, '/tmp/notes.pdf');
    expect(filePicker.fileType, FileType.custom);
    expect(filePicker.allowedExtensions, ['pdf', 'txt', 'doc', 'docx']);
    expect(filePicker.allowMultiple, isFalse);
  });

  test(
    'Message action repository saves image bytes through FilePicker',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars-file-picker-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/image.png');
      await source.writeAsBytes([1, 2, 3]);
      filePicker.savedPath = '${directory.path}/saved.png';

      final result = await PlatformMessageActionRepository().saveImage(
        sourcePath: source.path,
        dialogTitle: 'Save image',
      );

      expect(result, MediaExportResult.saved);
      expect(filePicker.dialogTitle, 'Save image');
      expect(filePicker.fileName, 'image.png');
      expect(filePicker.fileType, FileType.image);
      expect(filePicker.allowedExtensions, ['png', 'jpg', 'jpeg']);
      expect(filePicker.bytes, [1, 2, 3]);
    },
  );

  test('Message action repository shares an image with text', () async {
    String? sharedPath;
    String? sharedText;
    final repository = PlatformMessageActionRepository(
      imageShare: ({required sourcePath, required text}) async {
        sharedPath = sourcePath;
        sharedText = text;
      },
    );

    await repository.shareImage(
      sourcePath: '/tmp/image.png',
      text: 'Generated image',
    );

    expect(sharedPath, '/tmp/image.png');
    expect(sharedText, 'Generated image');
  });

  test('Bot transfer repository writes readable, indented JSON', () async {
    filePicker.savedPath = '/tmp/research.stars-bot.json';
    const repository = PlatformBotTransferRepository(
      fileService: BotTransferFileService(),
    );

    final result = await repository.exportBot(
      BotExportDocument(
        name: 'Research',
        provider: 'OpenAI',
        baseUrl: 'https://example.invalid',
        apiType: Bot.apiTypeOpenAI,
        model: 'gpt-test',
        systemPrompt: 'Be helpful.',
      ),
      suggestedFileName: 'research.stars-bot.json',
      dialogTitle: 'Export Bot',
    );

    expect(result, BotExportResult.saved);
    expect(filePicker.dialogTitle, 'Export Bot');
    expect(filePicker.fileName, 'research.stars-bot.json');
    expect(filePicker.fileType, FileType.custom);
    expect(filePicker.allowedExtensions, ['json']);
    final exportedText = utf8.decode(filePicker.bytes!);
    expect(exportedText, contains('\n  "format": "stars.bot"'));
    expect(jsonDecode(exportedText), isA<Map<String, Object?>>());
  });

  test('Bot transfer repository reads a selected JSON document', () async {
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode(
          BotExportDocument(
            name: 'Imported',
            provider: 'OpenAI',
            baseUrl: '',
            apiType: Bot.apiTypeOpenAI,
            model: 'gpt-test',
            systemPrompt: '',
          ),
        ),
      ),
    );
    filePicker.selectedFile = PlatformFile(
      name: 'import.stars-bot.json',
      size: bytes.length,
      bytes: bytes,
    );
    const repository = PlatformBotTransferRepository(
      fileService: BotTransferFileService(),
    );

    final document = await repository.importBot(dialogTitle: 'Import Bot');

    expect(document?.name, 'Imported');
    expect(filePicker.fileType, FileType.custom);
    expect(filePicker.allowedExtensions, ['json']);
    expect(filePicker.allowMultiple, isFalse);
  });

  test('Bot transfer repository maps malformed JSON to validation', () async {
    final bytes = Uint8List.fromList(utf8.encode('{not json'));
    filePicker.selectedFile = PlatformFile(
      name: 'broken.json',
      size: bytes.length,
      bytes: bytes,
    );
    const repository = PlatformBotTransferRepository(
      fileService: BotTransferFileService(),
    );

    expect(
      () => repository.importBot(dialogTitle: 'Import Bot'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'bot_import_invalid',
        ),
      ),
    );
  });

  test('Bot transfer repository rejects oversized documents', () async {
    final bytes = Uint8List(PlatformBotTransferRepository.maxDocumentBytes + 1);
    filePicker.selectedFile = PlatformFile(
      name: 'oversized.json',
      size: bytes.length,
      bytes: bytes,
    );
    const repository = PlatformBotTransferRepository(
      fileService: BotTransferFileService(),
    );

    expect(
      () => repository.importBot(dialogTitle: 'Import Bot'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'bot_import_invalid',
        ),
      ),
    );
  });
}

final class _FakeFilePicker extends FilePickerPlatform {
  String? directoryPath;
  PlatformFile? selectedFile;
  String? savedPath;
  String? dialogTitle;
  String? fileName;
  FileType? fileType;
  List<String>? allowedExtensions;
  bool? allowMultiple;
  Uint8List? bytes;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
    AndroidSAFOptions? androidSafOptions,
  }) async => directoryPath;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    AndroidSAFOptions? androidSafOptions,
  }) async {
    fileType = type;
    this.allowedExtensions = allowedExtensions;
    this.allowMultiple = allowMultiple;
    final file = selectedFile;
    return file == null ? null : FilePickerResult([file]);
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    required String fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    required Uint8List bytes,
    Function(FilePickerStatus)? onFileLoading,
    bool lockParentWindow = false,
  }) async {
    this.dialogTitle = dialogTitle;
    this.fileName = fileName;
    fileType = type;
    this.allowedExtensions = allowedExtensions;
    this.bytes = bytes;
    return savedPath;
  }
}
