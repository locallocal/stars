import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';

import '../../../../support/file_preview_test_support.dart';

void main() {
  const file = '/chat/登月小说第六章.md';
  const receipt = '好的，我会把《月背回声》第六章正文保存到本地的 登月小说第六章.md，完成后把保存路径和校验结果告诉你。';

  test(
    'an existing filename in any ordinary reply is not a file result',
    () async {
      final repository = _Files({file});
      final model = MessageActionViewModel(
        repository: repository,
        localFilesDirectoryProvider: () async => '/chat',
      );
      expect(
        await model.resolveLocalFiles(
          content: '$receipt\n`$file`',
          files: const [],
          sourceMessage: _message(),
        ),
        isEmpty,
      );
      expect(repository.checkedPaths, isEmpty);
    },
  );

  test(
    'attachments and explicit links do not require execution evidence',
    () async {
      final model = MessageActionViewModel(
        repository: _Files({file}),
        localFilesDirectoryProvider: () async => '/chat',
      );
      expect(
        await model.resolveLocalFiles(
          content: '[查看](登月小说第六章.md)\n[重复](file://$file)\n[丢失](missing.md)',
          files: const ['登月小说第六章.md', '/attached/missing.pdf'],
        ),
        [file, '/attached/missing.pdf'],
      );
    },
  );

  test('later evidence cannot change an earlier ordinary message', () async {
    final at = DateTime(2026, 1, 1, 0, 0, 22);
    final ledger = FilePreviewEvidenceRepository([
      filePreviewEvidence(path: file, observedAt: at),
    ]);
    final model = MessageActionViewModel(
      repository: _Files({file}),
      evidenceRepository: ledger,
      localFilesDirectoryProvider: () async => '/chat',
    );
    expect(
      await model.resolveLocalFiles(
        content: receipt,
        files: const [],
        sourceMessage: _message(),
      ),
      isEmpty,
    );
    expect(
      await model.resolveLocalFiles(
        content: '已保存到 登月小说第六章.md。',
        files: const [],
        sourceMessage: _message(timestamp: at.add(const Duration(seconds: 1))),
      ),
      [file],
    );
  });

  test(
    'historical task output resolves even when answer verification was off',
    () async {
      final ledger = FilePreviewEvidenceRepository([
        filePreviewEvidence(path: file, messageId: 'task-1:ack'),
      ]);
      final model = MessageActionViewModel(
        repository: _Files({file}),
        evidenceRepository: ledger,
        localFilesDirectoryProvider: () async => '/chat',
      );
      final message = _message(
        messageId: 'task-1:result',
        kind: TaskMessageKind.result,
        taskId: 'task-1',
      );
      expect(message.grounding.evidenceIds, isEmpty);
      expect(
        await model.resolveLocalFiles(
          content: '已保存到 登月小说第六章.md。',
          files: const [],
          sourceMessage: message,
        ),
        [file],
      );
      expect(ledger.queriedMessages, ['task-1:result', 'task-1:ack']);
    },
  );

  test(
    'a receipt can still offer an explicitly attached file or link',
    () async {
      final model = MessageActionViewModel(repository: _Files({file}));
      expect(
        await model.resolveLocalFiles(
          content: '[已有版本]($file)',
          files: const ['/attached/source.md'],
          sourceMessage: _message(
            messageId: 'task-1:ack',
            kind: TaskMessageKind.acknowledgement,
            taskId: 'task-1',
          ),
        ),
        ['/attached/source.md', file],
      );
    },
  );

  for (final problem in [
    'other-chat',
    'other-message',
    'future',
    'expired',
    'digest',
    'unpersisted',
    'unavailable',
  ]) {
    test('$problem evidence cannot promote a plain path', () async {
      final record = filePreviewEvidence(
        path: file,
        chatId: problem == 'other-chat' ? 'another-chat' : 'chat-1',
        messageId:
            problem == 'other-message'
                ? 'another-message'
                : 'message-with-local-files',
        observedAt: problem == 'future' ? DateTime(2026, 2) : null,
        validUntil:
            problem == 'expired' ? DateTime(2025, 12, 31, 23, 59, 45) : null,
        persisted: problem != 'unpersisted',
      );
      final ledger = FilePreviewEvidenceRepository([record])
        ..unavailable = problem == 'unavailable';
      if (problem == 'digest') ledger.invalidDigests.add(record.evidenceId);
      final model = MessageActionViewModel(
        repository: _Files({file}),
        evidenceRepository: ledger,
      );
      expect(
        await model.resolveLocalFiles(
          content: file,
          files: const [],
          sourceMessage: _message(),
        ),
        isEmpty,
      );
    });
  }

  test('historical validity is evaluated at the message time', () async {
    final model = MessageActionViewModel(
      repository: _Files({file}),
      evidenceRepository: FilePreviewEvidenceRepository([
        filePreviewEvidence(path: file, validUntil: DateTime(2026, 1, 2)),
      ]),
    );
    expect(
      await model.resolveLocalFiles(
        content: file,
        files: const [],
        sourceMessage: _message(),
      ),
      [file],
    );
  });

  test('one inaccessible link does not hide other previews', () async {
    final model = MessageActionViewModel(
      repository: _Files({file})..inaccessible.add('/bad.md'),
    );
    expect(
      await model.resolveLocalFiles(
        content: '[bad](/bad.md) [good]($file)',
        files: const [],
      ),
      [file],
    );
  });
}

Message _message({
  DateTime? timestamp,
  String messageId = 'message-with-local-files',
  TaskMessageKind? kind,
  String? taskId,
}) => Message(
  messageId: messageId,
  turnId: 'turn-1',
  taskId: taskId,
  taskMessageKind: kind,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'assistant',
  content: '',
  timestamp: timestamp ?? DateTime(2026),
  terminalOutcome:
      kind == TaskMessageKind.result ? MessageTerminalOutcome.completed : null,
);

final class _Files implements MessageActionRepository {
  _Files(this.existing);
  final Set<String> existing;
  final inaccessible = <String>{};
  final checkedPaths = <String>[];

  @override
  String? get localFileHomeDirectory => '/home/user';

  @override
  Future<bool> localFileExists(String path) async {
    checkedPaths.add(path);
    if (inaccessible.contains(path)) throw StateError('File unavailable');
    return existing.contains(path);
  }

  @override
  Future<bool> openExternal(Uri uri) async => false;
  @override
  Future<bool> openLocalFile(String path) async => false;
  @override
  Future<MediaExportResult> saveImage({
    required String sourcePath,
    required String dialogTitle,
  }) async => MediaExportResult.cancelled;
  @override
  Future<void> shareImage({
    required String sourcePath,
    required String text,
  }) async {}
}
