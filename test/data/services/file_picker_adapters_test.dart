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
      filePicker.selectedFile = _FakePlatformFile(
        name: 'example.zip',
        size: 1,
        path: '/tmp/example.zip',
      );

      final source = await const SkillPickerService().pickZipArchive();

      expect(source?.kind, SkillImportKind.zipArchive);
      expect(source?.path, '/tmp/example.zip');
      expect(filePicker.fileType, FileType.custom);
      expect(filePicker.allowedExtensions, ['zip']);
    },
  );

  test('Attachment picker selects one supported document', () async {
    filePicker.selectedFile = _FakePlatformFile(
      name: 'notes.pdf',
      size: 1,
      path: '/tmp/notes.pdf',
    );

    final path = await AttachmentPickerService().selectFile();

    expect(path, '/tmp/notes.pdf');
    expect(filePicker.fileType, FileType.custom);
    expect(filePicker.allowedExtensions, ['pdf', 'txt', 'doc', 'docx']);
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
    final exportedText = utf8.decode(filePicker.bytes!);
    expect(exportedText, contains('\n  "format": "stars.bot"'));
    expect(jsonDecode(exportedText), isA<Map<String, Object?>>());
  });

  for (final sizeKnown in [true, false]) {
    test(
      'Bot transfer repository reads JSON with sizeKnown=$sizeKnown',
      () async {
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
        filePicker.selectedFile = _FakePlatformFile(
          name: 'import.stars-bot.json',
          size: sizeKnown ? bytes.length : null,
          bytes: bytes,
        );
        const repository = PlatformBotTransferRepository(
          fileService: BotTransferFileService(),
        );

        final document = await repository.importBot(dialogTitle: 'Import Bot');

        expect(document?.name, 'Imported');
        expect(filePicker.fileType, FileType.custom);
        expect(filePicker.allowedExtensions, ['json']);
      },
    );
  }

  test('Bot transfer repository maps malformed JSON to validation', () async {
    final bytes = Uint8List.fromList(utf8.encode('{not json'));
    filePicker.selectedFile = _FakePlatformFile(
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

  for (final sizeKnown in [true, false]) {
    test(
      'Bot transfer rejects oversized JSON with sizeKnown=$sizeKnown',
      () async {
        final bytes = Uint8List(
          PlatformBotTransferRepository.maxDocumentBytes + 1,
        );
        final file = _FakePlatformFile(
          name: 'oversized.json',
          size: sizeKnown ? bytes.length : null,
          bytes: bytes,
        );
        filePicker.selectedFile = file;
        const repository = PlatformBotTransferRepository(
          fileService: BotTransferFileService(),
        );

        await expectLater(
          repository.importBot(dialogTitle: 'Import Bot'),
          throwsA(
            isA<AppFailure>().having(
              (failure) => failure.code,
              'code',
              'bot_import_invalid',
            ),
          ),
        );
        expect(file.wasRead, !sizeKnown);
      },
    );
  }
}

final class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile({
    required this.name,
    this.size,
    String? path,
    Uint8List? bytes,
  }) : uri = Uri.file(path ?? '/tmp/$name'),
       _bytes = bytes ?? Uint8List(0);

  @override
  final String name;
  @override
  final Uri uri;
  final int? size;
  final Uint8List _bytes;
  bool wasRead = false;

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => size;

  @override
  Future<int?> length() async => size;

  @override
  Future<Uint8List> readAsBytes() async {
    wasRead = true;
    return _bytes;
  }

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(_bytes);
}

final class _FakeFilePicker extends FilePickerPlatform {
  String? directoryPath;
  PlatformFile? selectedFile;
  String? savedPath;
  String? dialogTitle;
  String? fileName;
  FileType? fileType;
  List<String>? allowedExtensions;
  Uint8List? bytes;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => directoryPath;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    fileType = type;
    this.allowedExtensions = allowedExtensions;
    return selectedFile;
  }

  @override
  Future<Uri?> saveFile({
    String? dialogTitle,
    required String fileName,
    String? initialDirectory,
    required Uint8List bytes,
    required String mimeType,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    this.dialogTitle = dialogTitle;
    this.fileName = fileName;
    this.bytes = bytes;
    final path = savedPath;
    return path == null ? null : Uri.file(path);
  }
}
