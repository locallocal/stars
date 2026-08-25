import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/app_failure.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';

void main() {
  test(
    'forwards save cancellation without converting it to an error',
    () async {
      final repository =
          _FakeMessageActionRepository()
            ..saveResult = MediaExportResult.cancelled;
      final viewModel = MessageActionViewModel(repository: repository);

      expect(
        await viewModel.saveImage(
          sourcePath: '/image.png',
          dialogTitle: 'Save',
        ),
        MediaExportResult.cancelled,
      );
    },
  );

  test('normalizes platform save failures', () async {
    final repository =
        _FakeMessageActionRepository()..saveError = StateError('private path');
    final viewModel = MessageActionViewModel(repository: repository);

    await expectLater(
      viewModel.saveImage(sourcePath: '/image.png', dialogTitle: 'Save'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'message_image_export_failed',
        ),
      ),
    );
  });

  test('rejects unsupported links before invoking the platform', () async {
    final repository = _FakeMessageActionRepository();
    final viewModel = MessageActionViewModel(repository: repository);

    expect(await viewModel.openExternal('file:///private/data'), isFalse);
    expect(repository.openCalls, 0);
    expect(await viewModel.openExternal('https://example.com'), isTrue);
    expect(repository.openCalls, 1);
  });

  test('opens a normalized local file through the dedicated API', () async {
    final repository = _FakeMessageActionRepository();
    final viewModel = MessageActionViewModel(repository: repository);

    expect(await viewModel.openLocalFile('  /tmp/report.pdf  '), isTrue);
    expect(repository.localFileCalls, ['/tmp/report.pdf']);
    expect(await viewModel.openLocalFile('   '), isFalse);
    expect(repository.localFileCalls, hasLength(1));
  });
}

final class _FakeMessageActionRepository implements MessageActionRepository {
  MediaExportResult saveResult = MediaExportResult.saved;
  Object? saveError;
  int openCalls = 0;
  final List<String> localFileCalls = [];

  @override
  Future<bool> openExternal(Uri uri) async {
    openCalls += 1;
    return true;
  }

  @override
  Future<bool> openLocalFile(String path) async {
    localFileCalls.add(path);
    return true;
  }

  @override
  Future<MediaExportResult> saveImage({
    required String sourcePath,
    required String dialogTitle,
  }) async {
    if (saveError case final error?) throw error;
    return saveResult;
  }

  @override
  Future<void> shareImage({
    required String sourcePath,
    required String text,
  }) async {}
}
