import 'package:stars/domain/models/app_failure.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_message_kind.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/services/local_file_preview_policy.dart';
import 'package:stars/domain/services/local_file_reference_parser.dart';

final class MessageActionViewModel {
  const MessageActionViewModel({
    required MessageActionRepository repository,
    ToolEvidenceRepository? evidenceRepository,
    Future<String> Function()? localFilesDirectoryProvider,
  }) : _repository = repository,
       _evidenceRepository = evidenceRepository,
       _localFilesDirectoryProvider = localFilesDirectoryProvider;

  final MessageActionRepository _repository;
  final ToolEvidenceRepository? _evidenceRepository;
  final Future<String> Function()? _localFilesDirectoryProvider;

  Future<String?> loadLocalFilesDirectory() async {
    try {
      return await _localFilesDirectoryProvider?.call();
    } on Object {
      return null;
    }
  }

  Future<List<String>> resolveLocalFiles({
    required String content,
    required List<String> files,
    Message? sourceMessage,
  }) async {
    final parser = LocalFileReferenceParser(
      baseDirectory: await loadLocalFilesDirectory(),
      homeDirectory: _repository.localFileHomeDirectory,
    );
    final resolved = <String>{
      for (final file in files) parser.resolve(file) ?? file,
    };
    final linked = parser.linkedPathsFromMarkdown(content).toSet();
    final mentions =
        parser.pathsFromMarkdown(content).toSet()
          ..removeAll(linked)
          ..removeAll(resolved);
    final supported = const LocalFilePreviewPolicy().supportedPaths(
      parser: parser,
      evidence:
          mentions.isEmpty ? const [] : await _fileEvidence(sourceMessage),
    );
    for (final candidate in {
      ...linked,
      ...mentions.where(supported.contains),
    }) {
      if (resolved.contains(candidate)) continue;
      try {
        if (await _repository.localFileExists(candidate)) {
          resolved.add(candidate);
        }
      } on Object {
        // One inaccessible reference must not hide other attachments.
      }
    }
    return List.unmodifiable(resolved);
  }

  Future<List<ToolEvidenceRecord>> _fileEvidence(Message? message) async {
    final repository = _evidenceRepository;
    if (repository == null || message == null || message.messageId.isEmpty) {
      return const [];
    }
    // Task attempts are stored under the acceptance message. Their timestamps
    // prevent later output from appearing in an earlier message on re-render.
    final owners = {
      message.messageId,
      if (message.taskId case final taskId?)
        ConversationMessageIdentity.acknowledgement(taskId),
    };
    final records = <String, ToolEvidenceRecord>{};
    for (final owner in owners) {
      try {
        for (final record in await repository.getForMessage(owner)) {
          if (record.chatId == message.chatId &&
              record.canSupportBusinessFactsAt(message.timestamp) &&
              await repository.verifyDigest(record.evidenceId)) {
            records[record.evidenceId] = record;
          }
        }
      } on Object {
        // Missing or damaged evidence never promotes a prose mention.
      }
    }
    return List.unmodifiable(records.values);
  }

  Future<Map<String, ToolEvidenceRecord?>> loadEvidenceRecords(
    Iterable<String> evidenceIds,
  ) async {
    final repository = _evidenceRepository;
    final ids = evidenceIds.toSet().toList(growable: false);
    if (repository == null || ids.isEmpty) return const {};
    final entries = await Future.wait(
      ids.map((id) async {
        try {
          return MapEntry(id, await repository.getById(id));
        } on Object {
          return MapEntry<String, ToolEvidenceRecord?>(id, null);
        }
      }),
    );
    return Map<String, ToolEvidenceRecord?>.unmodifiable(
      Map<String, ToolEvidenceRecord?>.fromEntries(entries),
    );
  }

  Future<MediaExportResult> saveImage({
    required String sourcePath,
    required String dialogTitle,
  }) async {
    try {
      return await _repository.saveImage(
        sourcePath: sourcePath,
        dialogTitle: dialogTitle,
      );
    } on Object catch (error) {
      throw AppFailure.from(error, code: 'message_image_export_failed');
    }
  }

  Future<void> shareImage({
    required String sourcePath,
    required String text,
  }) async {
    try {
      await _repository.shareImage(sourcePath: sourcePath, text: text);
    } on Object catch (error) {
      throw AppFailure.from(error, code: 'message_image_share_failed');
    }
  }

  Future<bool> openExternal(String href) async {
    final uri = Uri.tryParse(href.trim());
    if (uri == null ||
        !((uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.host.isNotEmpty ||
            uri.scheme == 'mailto')) {
      return false;
    }
    try {
      return await _repository.openExternal(uri);
    } on Object {
      return false;
    }
  }

  Future<bool> openLocalFile(String path) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) return false;
    try {
      return await _repository.openLocalFile(normalizedPath);
    } on Object {
      return false;
    }
  }
}
