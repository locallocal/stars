import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/message_file_snapshot.dart';
import 'package:stars/domain/models/task_message_kind.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/services/local_file_preview_policy.dart';
import 'package:stars/domain/services/local_file_reference_parser.dart';

/// Prepares and memoizes complete message snapshots for one conversation.
///
/// Completed (including empty) results live as long as the conversation's
/// owner. Widget disposal, rebuilds and scrolling never expire them. A changed
/// message replaces its entry; streaming keeps only its latest revision.
final class ResolveMessageLocalFiles {
  ResolveMessageLocalFiles({
    required MessageActionRepository repository,
    ToolEvidenceRepository? evidenceRepository,
    Future<String> Function()? directoryProvider,
  }) : _repository = repository,
       _evidence = evidenceRepository,
       _directoryProvider = directoryProvider;

  final MessageActionRepository _repository;
  final ToolEvidenceRepository? _evidence;
  final Future<String> Function()? _directoryProvider;
  final _entries = <(String?, String?), _Resolution>{};
  Future<String?>? _directory;

  /// Called after successful history clearing or conversation deletion.
  /// Old futures only hold detached entries and cannot repopulate the cache.
  void clear() => _entries.clear();

  Future<String?> loadDirectory() => _directory ??= _loadDirectory();

  Future<String?> _loadDirectory() async {
    try {
      final provider = _directoryProvider;
      return provider == null ? null : await Future<String>.sync(provider);
    } on Object {
      _directory = null;
      return null;
    }
  }

  MessageFileSnapshot? cached(MessageFileRequest request) =>
      _find(request)?.value;

  _Resolution? _find(MessageFileRequest request) {
    final entry = _entries[request.identity];
    if (entry != null && entry.request.matches(request)) return entry;
    final streamed = _entries[(null, null)];
    // A completed reply can reuse fully resolved attachments/links from its
    // streaming row. Prose mentions still require the final message's evidence,
    // and streaming misses must be checked again after generation finishes.
    if (request.message != null &&
        streamed != null &&
        streamed.reusableAfterStreaming &&
        streamed.value != null &&
        request.sameContent(streamed.request)) {
      return _entries[request.identity] = _Resolution.completed(
        request,
        streamed.value!,
      );
    }
    return null;
  }

  Future<MessageFileSnapshot> resolve(MessageFileRequest request) {
    final cached = _find(request);
    if (cached != null) return cached.pending;
    final previous = _entries[request.identity];
    final entry = _Resolution(request);
    _entries[request.identity] = entry;
    final retained =
        previous != null && request.appendsTo(previous.request)
            ? previous.value?.files.toSet() ?? const <String>{}
            : const <String>{};
    return entry.pending = _resolve(entry, retained).then((snapshot) {
      entry.value = snapshot;
      return snapshot;
    });
  }

  Future<MessageFileSnapshot> _resolve(
    _Resolution entry,
    Set<String> retained,
  ) async {
    final request = entry.request;
    final resolved = <String>{...request.files};
    try {
      final directory = await loadDirectory();
      final parser = LocalFileReferenceParser(
        baseDirectory: directory,
        homeDirectory: _repository.localFileHomeDirectory,
      );
      resolved
        ..clear()
        ..addAll(request.files.map((file) => parser.resolve(file) ?? file));
      final linked = parser.linkedPathsFromMarkdown(request.content).toSet();
      final mentions =
          parser.pathsFromMarkdown(request.content).toSet()
            ..removeAll(linked)
            ..removeAll(resolved);
      final supported = const LocalFilePreviewPolicy().supportedPaths(
        parser: parser,
        evidence:
            mentions.isEmpty ? const [] : await _fileEvidence(request.message),
      );
      final candidates =
          {
            ...linked,
            ...mentions.where(supported.contains),
          }.difference(resolved).toList();
      // Bound file-system concurrency, then publish all results in source order.
      for (var start = 0; start < candidates.length; start += 4) {
        final batch = candidates.skip(start).take(4).toList();
        final exists = await Future.wait(
          batch.map((path) async {
            if (retained.contains(path)) return true;
            try {
              return await _repository.localFileExists(path);
            } on Object {
              return false;
            }
          }),
        );
        for (var i = 0; i < batch.length; i++) {
          if (exists[i]) resolved.add(batch[i]);
        }
      }
      entry.reusableAfterStreaming =
          mentions.isEmpty &&
          linked.every(resolved.contains) &&
          (_directoryProvider == null || directory != null);
    } on Object {
      // File navigation must never prevent the reply itself from being shown.
    }
    return MessageFileSnapshot(content: request.content, files: resolved);
  }

  Future<List<ToolEvidenceRecord>> _fileEvidence(Message? message) async {
    final repository = _evidence;
    if (repository == null || message == null || message.messageId.isEmpty) {
      return const [];
    }
    final owners = {
      message.messageId,
      if (message.taskId case final taskId?)
        ConversationMessageIdentity.acknowledgement(taskId),
    };
    final records = <String, ToolEvidenceRecord>{};
    for (final owner in owners) {
      try {
        for (final record in await repository.getForMessage(owner)) {
          if (record.messageId == owner &&
              record.chatId == message.chatId &&
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
}

final class _Resolution {
  _Resolution(this.request);
  _Resolution.completed(this.request, MessageFileSnapshot snapshot) {
    value = snapshot;
    pending = Future.value(snapshot);
  }
  final MessageFileRequest request;
  late final Future<MessageFileSnapshot> pending;
  MessageFileSnapshot? value;
  bool reusableAfterStreaming = false;
}
