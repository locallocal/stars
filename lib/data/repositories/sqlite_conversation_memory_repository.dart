import 'dart:async';
import 'dart:convert';

import 'package:stars/data/services/conversation_summary_storage.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/conversation_memory.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';

final class SqliteConversationMemoryRepository
    implements ConversationMemoryRepository {
  SqliteConversationMemoryRepository({
    required LocalDatabaseService localDatabase,
    required ConversationSummaryStorage storage,
  }) : _localDatabase = localDatabase,
       _storage = storage;

  final LocalDatabaseService _localDatabase;
  final ConversationSummaryStorage _storage;
  final StreamController<String> _changes = StreamController.broadcast();

  @override
  Stream<String> get changes => _changes.stream;

  @override
  Future<ConversationMemoryState> getState(String chatId) async {
    final rows = await _localDatabase.loadConversationMemoryState(chatId);
    if (rows.isEmpty) {
      return ConversationMemoryState(chatId: chatId, updatedAt: DateTime.now());
    }
    return _stateFromRow(rows.first);
  }

  @override
  Future<ConversationSummaryDocument?> getActiveSummary(String chatId) async {
    final rows = await _localDatabase.loadActiveConversationSummary(chatId);
    if (rows.isEmpty) return null;
    final metadata = _summaryFromRow(rows.first);
    try {
      final markdown = await _storage.read(metadata);
      return ConversationSummaryDocument(
        metadata: metadata,
        markdown: markdown,
      );
    } on ConversationSummaryStorageException catch (error) {
      await _localDatabase.invalidateConversationSummary(
        chatId,
        metadata.id,
        error.message,
      );
      _emit(chatId);
      return null;
    }
  }

  @override
  Future<List<ConversationMemoryItem>> getItems(String chatId) async {
    final rows = await _localDatabase.loadConversationMemoryItems(chatId);
    return List.unmodifiable(rows.map(_itemFromRow));
  }

  @override
  Future<bool> commitCompaction({
    required String chatId,
    required int expectedRevision,
    required ConversationSummaryDocument summary,
    required List<ConversationMemoryItem> items,
  }) async {
    if (summary.metadata.chatId != chatId ||
        summary.metadata.baseRevision != expectedRevision) {
      throw ArgumentError('Summary metadata does not match the CAS request.');
    }
    final stored = await _storage.write(
      chatId: chatId,
      summaryId: summary.metadata.id,
      markdown: summary.markdown,
    );
    final metadata = summary.metadata.copyWith(
      contentDigest: stored.contentDigest,
      contentBytes: stored.contentBytes,
    );
    try {
      final committed = await _localDatabase.commitConversationCompaction(
        chatId: chatId,
        expectedRevision: expectedRevision,
        summary: _summaryToRow(metadata),
        items: items.map(_itemToRow),
      );
      if (!committed) {
        await _storage.deleteSummary(chatId, summary.metadata.id);
        return false;
      }
      _emit(chatId);
      return true;
    } catch (_) {
      await _storage.deleteSummary(chatId, summary.metadata.id);
      rethrow;
    }
  }

  @override
  Future<void> saveUserItem(ConversationMemoryItem item) async {
    await _localDatabase.upsertConversationMemoryItem(
      _itemToRow(
        item.copyWith(
          origin: ConversationMemoryOrigin.user,
          updatedAt: DateTime.now(),
        ),
      ),
    );
    _emit(item.chatId);
  }

  @override
  Future<void> forgetItem(String chatId, String itemId) async {
    await _localDatabase.updateConversationMemoryItemState(
      chatId,
      itemId,
      ConversationMemoryItemState.forgotten.name,
    );
    _emit(chatId);
  }

  @override
  Future<void> restoreItem(String chatId, String itemId) async {
    await _localDatabase.updateConversationMemoryItemState(
      chatId,
      itemId,
      ConversationMemoryItemState.active.name,
    );
    _emit(chatId);
  }

  @override
  Future<void> setAutoMemoryEnabled(String chatId, bool enabled) async {
    await _localDatabase.setConversationAutoMemoryEnabled(chatId, enabled);
    _emit(chatId);
  }

  @override
  Future<void> setCompactionStatus(
    String chatId,
    ConversationCompactionStatus status, {
    String lastError = '',
  }) async {
    await _localDatabase.setConversationCompactionStatus(
      chatId,
      status.name,
      lastError,
    );
    _emit(chatId);
  }

  @override
  Future<void> clearAutomaticMemory(String chatId) async {
    await _storage.clearSummaries(chatId);
    await _localDatabase.clearAutomaticConversationMemory(chatId);
    _emit(chatId);
  }

  @override
  Future<void> clearForChat(String chatId) async {
    await _storage.clearSummaries(chatId);
    await _localDatabase.deleteConversationMemory(chatId);
    _emit(chatId);
  }

  @override
  Future<void> deleteForChat(String chatId) async {
    await _storage.deleteChatDirectory(chatId);
    await _localDatabase.deleteConversationMemory(chatId);
    _emit(chatId);
  }

  void _emit(String chatId) {
    if (!_changes.isClosed) _changes.add(chatId);
  }
}

ConversationMemoryState _stateFromRow(Map<String, Object?> row) {
  final lastCompactedAt = _nullableInt(row['last_compacted_at']);
  return ConversationMemoryState(
    chatId: _text(row['chat_id'], 'chat_id'),
    revision: _int(row['revision']),
    activeSummaryId: _text(row['active_summary_id'], 'active_summary_id'),
    coveredThroughMessageId: _text(
      row['covered_through_message_id'],
      'covered_through_message_id',
    ),
    autoMemoryEnabled: _bool(row['auto_memory_enabled']),
    compactionStatus: _enumByName(
      ConversationCompactionStatus.values,
      _text(row['compaction_status'], 'compaction_status'),
      'compaction_status',
    ),
    lastError: _text(row['last_error'], 'last_error'),
    lastCompactedAt:
        lastCompactedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastCompactedAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(_int(row['updated_at'])),
  );
}

ConversationSummaryMetadata _summaryFromRow(Map<String, Object?> row) {
  return ConversationSummaryMetadata(
    id: _text(row['id'], 'id'),
    chatId: _text(row['chat_id'], 'chat_id'),
    status: _enumByName(
      ConversationSummaryStatus.values,
      _text(row['status'], 'status'),
      'status',
    ),
    fileName: _text(row['file_name'], 'file_name'),
    markdownSchemaVersion: _int(row['markdown_schema_version']),
    contentDigest: _text(row['content_digest'], 'content_digest'),
    contentBytes: _int(row['content_bytes']),
    sourceStartMessageId: _text(
      row['source_start_message_id'],
      'source_start_message_id',
    ),
    sourceEndMessageId: _text(
      row['source_end_message_id'],
      'source_end_message_id',
    ),
    sourceMessageIds: _stringList(row['source_message_ids']),
    sourceDigest: _text(row['source_digest'], 'source_digest'),
    estimatedTokenCount: _int(row['estimated_token_count']),
    provider: _text(row['provider'], 'provider'),
    model: _text(row['model'], 'model'),
    promptVersion: _int(row['prompt_version']),
    baseRevision: _int(row['base_revision']),
    createdAt: DateTime.fromMillisecondsSinceEpoch(_int(row['created_at'])),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(_int(row['updated_at'])),
  );
}

Map<String, Object?> _summaryToRow(ConversationSummaryMetadata metadata) => {
  'id': metadata.id,
  'chat_id': metadata.chatId,
  'status': metadata.status.name,
  'file_name': metadata.fileName,
  'markdown_schema_version': metadata.markdownSchemaVersion,
  'content_digest': metadata.contentDigest,
  'content_bytes': metadata.contentBytes,
  'source_start_message_id': metadata.sourceStartMessageId,
  'source_end_message_id': metadata.sourceEndMessageId,
  'source_message_ids': jsonEncode(metadata.sourceMessageIds),
  'source_digest': metadata.sourceDigest,
  'estimated_token_count': metadata.estimatedTokenCount,
  'provider': metadata.provider,
  'model': metadata.model,
  'prompt_version': metadata.promptVersion,
  'base_revision': metadata.baseRevision,
  'created_at': metadata.createdAt.millisecondsSinceEpoch,
  'updated_at': metadata.updatedAt.millisecondsSinceEpoch,
};

ConversationMemoryItem _itemFromRow(Map<String, Object?> row) {
  final expiresAt = _nullableInt(row['expires_at']);
  final sources = _memoryItemSources(row['source_message_ids']);
  return ConversationMemoryItem(
    id: _text(row['id'], 'id'),
    chatId: _text(row['chat_id'], 'chat_id'),
    memoryKey: _text(row['memory_key'], 'memory_key'),
    kind: _enumByName(
      ConversationMemoryKind.values,
      _text(row['kind'], 'kind'),
      'kind',
    ),
    content: _text(row['content'], 'content'),
    state: _enumByName(
      ConversationMemoryItemState.values,
      _text(row['state'], 'state'),
      'state',
    ),
    origin: _enumByName(
      ConversationMemoryOrigin.values,
      _text(row['origin'], 'origin'),
      'origin',
    ),
    importance: _double(row['importance']),
    confidence: _double(row['confidence']),
    sourceMessageIds: sources.messageIds,
    sourceClaimIds: sources.claimIds,
    sourceDigest: _text(row['source_digest'], 'source_digest'),
    expiresAt:
        expiresAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(expiresAt),
    createdAt: DateTime.fromMillisecondsSinceEpoch(_int(row['created_at'])),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(_int(row['updated_at'])),
  );
}

Map<String, Object?> _itemToRow(ConversationMemoryItem item) => {
  'id': item.id,
  'chat_id': item.chatId,
  'memory_key': item.memoryKey,
  'kind': item.kind.name,
  'content': item.content,
  'state': item.state.name,
  'origin': item.origin.name,
  'importance': item.importance,
  'confidence': item.confidence,
  'source_message_ids': jsonEncode(<String, Object?>{
    'message_ids': item.sourceMessageIds,
    'claim_ids': item.sourceClaimIds,
  }),
  'source_digest': item.sourceDigest,
  'expires_at': item.expiresAt?.millisecondsSinceEpoch,
  'created_at': item.createdAt.millisecondsSinceEpoch,
  'updated_at': item.updatedAt.millisecondsSinceEpoch,
};

({List<String> messageIds, List<String> claimIds}) _memoryItemSources(
  Object? value,
) {
  if (value is! String) {
    throw const FormatException('Memory source ids must be JSON text.');
  }
  final decoded = jsonDecode(value);
  if (decoded is List<Object?>) {
    return (messageIds: _checkedStringList(decoded), claimIds: const []);
  }
  if (decoded is! Map<Object?, Object?> ||
      decoded.keys.toSet().difference(const {
        'message_ids',
        'claim_ids',
      }).isNotEmpty ||
      decoded.length != 2) {
    throw const FormatException('Memory source ids are invalid.');
  }
  final messageIds = decoded['message_ids'];
  final claimIds = decoded['claim_ids'];
  if (messageIds is! List<Object?> || claimIds is! List<Object?>) {
    throw const FormatException('Memory source id lists are invalid.');
  }
  return (
    messageIds: _checkedStringList(messageIds),
    claimIds: _checkedStringList(claimIds),
  );
}

List<String> _checkedStringList(List<Object?> values) {
  if (values.any((item) => item is! String)) {
    throw const FormatException('Memory source ids must be string lists.');
  }
  return List<String>.unmodifiable(values.cast<String>());
}

int _int(Object? value) => switch (value) {
  final int number => number,
  _ => throw const FormatException('Memory record integer is invalid.'),
};

int? _nullableInt(Object? value) => value == null ? null : _int(value);

double _double(Object? value) => switch (value) {
  final num number => number.toDouble(),
  _ => throw const FormatException('Memory record number is invalid.'),
};

List<String> _stringList(Object? value) {
  if (value is! String) {
    throw const FormatException('Memory record JSON must be text.');
  }
  final decoded = jsonDecode(value);
  if (decoded is! List<Object?> || decoded.any((item) => item is! String)) {
    throw const FormatException('Memory source ids must be a string list.');
  }
  return List<String>.unmodifiable(decoded.cast<String>());
}

T _enumByName<T extends Enum>(List<T> values, String name, String field) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('Memory record field "$field" has an unknown value.');
}

String _text(Object? value, String field) {
  if (value is String) return value;
  throw FormatException('Memory record field "$field" must be a string.');
}

bool _bool(Object? value) => switch (value) {
  0 => false,
  1 => true,
  _ => throw const FormatException('Memory record boolean must be 0 or 1.'),
};
