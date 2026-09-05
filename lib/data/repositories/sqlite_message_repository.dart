import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/message_repository.dart';

class SqliteMessageRepository
    implements
        CachedMessageRepository,
        PaginatedMessageRepository,
        BotScopedMessageMetricsRepository,
        GroundedMessageRepository {
  SqliteMessageRepository({required LocalDatabaseService localDatabase})
    : _localDatabase = localDatabase;

  final LocalDatabaseService _localDatabase;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final StreamController<Set<String>> _botMetricChanges =
      StreamController<Set<String>>.broadcast();
  final LinkedHashMap<String, _CachedMessagePage> _messageCache =
      LinkedHashMap<String, _CachedMessagePage>();
  int _identitySequence = 0;

  static const int _maxCachedChats = 5;
  static const int _messageWindowSize = 50;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Stream<Set<String>> get botMetricChanges => _botMetricChanges.stream;

  @override
  String createId(String prefix) {
    _identitySequence = (_identitySequence + 1) & 0x7fffffff;
    return '$prefix:${DateTime.now().microsecondsSinceEpoch}:'
        '$_identitySequence';
  }

  Message _ensureIdentity(Message message) {
    final messageId =
        message.messageId.isEmpty ? createId('message') : message.messageId;
    final turnId = message.turnId.isEmpty ? createId('turn') : message.turnId;
    return message.copyWith(messageId: messageId, turnId: turnId);
  }

  @override
  Future<List<Message>> getMessages(String chatId) async {
    final records = await _localDatabase.loadMessages(chatId);
    return List<Message>.unmodifiable(
      records.map((record) => MessageRecord(record).toDomain()),
    );
  }

  @override
  Future<MessagePage> getMessagePage(
    String chatId, {
    MessageCursor? before,
    int limit = _messageWindowSize,
  }) async {
    if (before == null && limit == _messageWindowSize) {
      final cached = peekMessagePage(chatId);
      if (cached != null) return cached;
    }
    final revisionBeforeLoad = _localDatabase.messageRevision(chatId);
    final records = await _localDatabase.loadMessagePage(
      chatId,
      beforeTimestamp: before?.timestamp.millisecondsSinceEpoch,
      beforeMessageId: before?.messageId,
      limit: limit,
    );
    final hasMore = records.length > limit;
    final selected = records.take(limit).toList(growable: false).reversed;
    final messages = List<Message>.unmodifiable(
      selected.map((record) => MessageRecord(record).toDomain()),
    );
    final page = MessagePage(
      messages: messages,
      hasMore: hasMore,
      nextCursor:
          hasMore && messages.isNotEmpty
              ? MessageCursor(
                timestamp: messages.first.timestamp,
                messageId: messages.first.messageId,
              )
              : null,
    );
    if (before == null &&
        limit == _messageWindowSize &&
        _localDatabase.messageRevision(chatId) == revisionBeforeLoad) {
      _cachePage(chatId, revisionBeforeLoad, page);
    }
    return page;
  }

  @override
  List<Message>? peekMessages(String chatId) {
    return peekMessagePage(chatId)?.messages;
  }

  @override
  MessagePage? peekMessagePage(String chatId) {
    final cached = _messageCache.remove(chatId);
    if (cached == null) return null;
    if (cached.revision != _localDatabase.messageRevision(chatId)) return null;
    _messageCache[chatId] = cached;
    return cached.page;
  }

  void _cachePage(String chatId, int revision, MessagePage page) {
    _messageCache.remove(chatId);
    _messageCache[chatId] = _CachedMessagePage(revision: revision, page: page);
    while (_messageCache.length > _maxCachedChats) {
      _messageCache.remove(_messageCache.keys.first);
    }
  }

  @override
  Future<List<ModelTokenUsageRecord>> getTokenUsageRecordsForChat(
    String chatId,
  ) async {
    final records = await _localDatabase.loadTokenUsageRecordsForChat(chatId);
    return _toTokenUsageRecords(records);
  }

  @override
  Future<List<ModelTokenUsageRecord>> getTokenUsageRecordsForBot(
    String botId,
  ) async {
    final records = await _localDatabase.loadTokenUsageRecordsForBot(botId);
    return _toTokenUsageRecords(records);
  }

  @override
  Future<ModelTokenUsage> getTokenUsageForBot(String botId) async {
    final record = await _localDatabase.loadTokenUsageForBot(botId);
    return ModelTokenUsage(
      inputTokens: _readCount(record['input_token_count']),
      outputTokens: _readCount(record['output_token_count']),
      totalTokens: _readCount(record['total_token_count']),
    );
  }

  @override
  Future<Map<String, ModelTokenUsage>> getTokenUsageForBots(
    Iterable<String> botIds,
  ) async {
    final ids = botIds.toSet();
    final records = await _localDatabase.loadTokenUsageForBots(ids);
    return Map<String, ModelTokenUsage>.unmodifiable({
      for (final id in ids) id: ModelTokenUsage.empty,
      for (final record in records)
        record['bot_id']?.toString() ?? '': ModelTokenUsage(
          inputTokens: _readCount(record['input_token_count']),
          outputTokens: _readCount(record['output_token_count']),
          totalTokens: _readCount(record['total_token_count']),
        ),
    });
  }

  @override
  Future<Map<String, ModelTokenUsage>> getTokenUsageByChatForBot(
    String botId,
  ) async {
    final records = await _localDatabase.loadTokenUsageByChatForBot(botId);
    return Map<String, ModelTokenUsage>.unmodifiable({
      for (final record in records)
        record['chat_id']?.toString() ?? '': ModelTokenUsage(
          inputTokens: _readCount(record['input_token_count']),
          outputTokens: _readCount(record['output_token_count']),
          totalTokens: _readCount(record['total_token_count']),
        ),
    });
  }

  @override
  Future<Message> upsertMessage(Message message) async {
    final identified = _ensureIdentity(message);
    final values = MessageRecord.fromDomain(identified).values;
    if (identified.grounding.evidenceIds.isEmpty) {
      await _localDatabase.upsertMessage(values);
    } else {
      await _localDatabase.upsertGroundedMessage(
        values,
        claimEvidenceIds: _claimEvidenceIds(identified),
      );
    }
    _publishPersistedMessage(identified);
    return identified;
  }

  @override
  Future<Message> upsertGroundedMessage(Message message) async {
    final identified = _ensureIdentity(message);
    await _localDatabase.upsertGroundedMessage(
      MessageRecord.fromDomain(identified).values,
      claimEvidenceIds: _claimEvidenceIds(identified),
    );
    _publishPersistedMessage(identified);
    return identified;
  }

  void _publishPersistedMessage(Message identified) {
    _updateCachedMessages(identified.chatId, [identified]);
    _changes.add(null);
    if (identified.botId.isNotEmpty) {
      _botMetricChanges.add({identified.botId});
    }
  }

  @override
  Future<List<Message>> upsertMessages(Iterable<Message> messages) async {
    final identified = messages.map(_ensureIdentity).toList(growable: false);
    if (identified.any((message) => message.grounding.evidenceIds.isNotEmpty)) {
      throw ArgumentError.value(
        messages,
        'messages',
        'Evidence-backed messages require an individual grounded commit.',
      );
    }
    await _localDatabase.upsertMessages(
      identified.map((message) => MessageRecord.fromDomain(message).values),
    );
    final messagesByChat = <String, List<Message>>{};
    for (final message in identified) {
      (messagesByChat[message.chatId] ??= <Message>[]).add(message);
    }
    for (final entry in messagesByChat.entries) {
      _updateCachedMessages(entry.key, entry.value);
    }
    _changes.add(null);
    final botIds =
        identified.map((message) => message.botId).toSet()..remove('');
    if (botIds.isNotEmpty) _botMetricChanges.add(botIds);
    return List<Message>.unmodifiable(identified);
  }

  @override
  Future<void> deleteMessages(String chatId) async {
    final botIds = await _localDatabase.loadBotIdsForChat(chatId);
    await _localDatabase.deleteMessages(chatId);
    _messageCache.remove(chatId);
    _changes.add(null);
    if (botIds.isNotEmpty) _botMetricChanges.add(botIds);
  }

  void _updateCachedMessages(String chatId, Iterable<Message> updates) {
    final cached = _messageCache.remove(chatId);
    if (cached == null) return;
    final currentRevision = _localDatabase.messageRevision(chatId);
    if (currentRevision != cached.revision + 1) return;

    final messages = List<Message>.of(cached.page.messages);
    final indexesById = <String, int>{
      for (var index = 0; index < messages.length; index++)
        if (messages[index].messageId.isNotEmpty)
          messages[index].messageId: index,
    };
    for (final message in updates) {
      final index = indexesById[message.messageId];
      if (index == null) {
        indexesById[message.messageId] = messages.length;
        messages.add(message);
      } else {
        messages[index] = message;
      }
    }
    messages.sort(_compareMessages);
    final trimmed = messages.length > _messageWindowSize;
    if (trimmed) {
      messages.removeRange(0, messages.length - _messageWindowSize);
    }
    final hasMore = cached.page.hasMore || trimmed;
    final page = MessagePage(
      messages: List<Message>.unmodifiable(messages),
      hasMore: hasMore,
      nextCursor:
          hasMore && messages.isNotEmpty
              ? MessageCursor(
                timestamp: messages.first.timestamp,
                messageId: messages.first.messageId,
              )
              : null,
    );
    _cachePage(chatId, currentRevision, page);
  }

  List<ModelTokenUsageRecord> _toTokenUsageRecords(
    Iterable<Map<String, Object?>> records,
  ) {
    return List<ModelTokenUsageRecord>.unmodifiable(
      records.map((record) {
        return ModelTokenUsageRecord(
          messageId: record['message_id']?.toString() ?? '',
          chatId: record['chat_id']?.toString() ?? '',
          botId: record['bot_id']?.toString() ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            _readCount(record['timestamp']),
          ),
          operationKind: record['operation_kind']?.toString() ?? 'chat_reply',
          usage: ModelTokenUsage(
            model: record['token_model']?.toString() ?? '',
            inputTokens: _readCount(record['input_token_count']),
            outputTokens: _readCount(record['output_token_count']),
            totalTokens: _readCount(record['total_token_count']),
          ),
        );
      }),
    );
  }

  @visibleForTesting
  Future<void> dispose() async {
    await _changes.close();
    await _botMetricChanges.close();
  }
}

Map<String, Iterable<String>> _claimEvidenceIds(Message message) {
  final claims = message.grounding.claims;
  if (claims.isNotEmpty) {
    return {
      for (final claim in claims)
        if (claim.acceptedEvidenceIds.isNotEmpty)
          claim.claim.claimId: claim.acceptedEvidenceIds,
    };
  }
  return {
    if (message.grounding.evidenceIds.isNotEmpty)
      '${message.messageId}:answer': message.grounding.evidenceIds,
  };
}

class _CachedMessagePage {
  const _CachedMessagePage({required this.revision, required this.page});

  final int revision;
  final MessagePage page;
}

int _compareMessages(Message left, Message right) {
  final timestamp = left.timestamp.compareTo(right.timestamp);
  if (timestamp != 0) return timestamp;
  return left.messageId.compareTo(right.messageId);
}

int _readCount(Object? value) {
  return switch (value) {
    final int count => count,
    final num count => count.toInt(),
    _ => int.tryParse(value?.toString() ?? '') ?? 0,
  };
}
