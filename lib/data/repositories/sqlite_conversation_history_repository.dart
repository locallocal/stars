import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/conversation_history.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/repositories/conversation_history_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/services/retrieval_terms.dart';

/// Current-chat history reader. It only projects user-visible message fields.
final class SqliteConversationHistoryRepository
    implements ConversationHistoryRepository {
  const SqliteConversationHistoryRepository({
    required MessageRepository messageRepository,
  }) : _messageRepository = messageRepository;

  final MessageRepository _messageRepository;

  @override
  Future<ConversationHistoryPage> search({
    required String chatId,
    required ConversationHistoryQuery query,
  }) async {
    final normalizedQuery = _normalizeQuery(query.query);
    if (normalizedQuery.isEmpty || normalizedQuery.length > 256) {
      throw ArgumentError.value(
        query.query,
        'query',
        'Must be 1-256 characters.',
      );
    }
    if (query.limit < 1 || query.limit > 12) {
      throw ArgumentError.value(
        query.limit,
        'limit',
        'Must be between 1 and 12.',
      );
    }
    if (query.after != null &&
        query.before != null &&
        !query.after!.isBefore(query.before!)) {
      throw ArgumentError('after must be before before.');
    }
    final cursor = _decodeCursor(
      query.cursor,
      chatId: chatId,
      operation: 'search',
      fingerprint: _fingerprint(
        '$normalizedQuery|${query.role.name}|${query.after?.toIso8601String()}|'
        '${query.before?.toIso8601String()}',
      ),
    );
    final terms = buildRetrievalTerms(normalizedQuery);
    final messages = await _messageRepository.getMessages(chatId);
    final scored = <({ConversationHistoryHit hit, double score})>[];
    for (final message in messages) {
      if (message.chatId != chatId || message.content.trim().isEmpty) continue;
      if (query.excludedRunId.isNotEmpty &&
          message.runId == query.excludedRunId) {
        continue;
      }
      final role = _roleOf(message);
      if (query.role != ConversationHistoryRole.any && query.role != role) {
        continue;
      }
      if (query.after != null && message.timestamp.isBefore(query.after!)) {
        continue;
      }
      if (query.before != null && !message.timestamp.isBefore(query.before!)) {
        continue;
      }
      final contentTerms = buildRetrievalTerms(message.content);
      final matchedTerms = terms.where(contentTerms.contains).toList();
      if (matchedTerms.isEmpty) continue;
      scored.add((
        hit: ConversationHistoryHit(
          turnId: message.turnId,
          messageId: message.messageId,
          role: role,
          timestamp: message.timestamp,
          excerpt: _excerpt(message.content, matchedTerms.first),
          terminalOutcome: message.terminalOutcome,
          hasPartialContent: message.hasPartialContent,
        ),
        score: matchedTerms.length / terms.length,
      ));
    }
    scored.sort((left, right) {
      final relevance = right.score.compareTo(left.score);
      if (relevance != 0) return relevance;
      final timestamp = right.hit.timestamp.compareTo(left.hit.timestamp);
      if (timestamp != 0) return timestamp;
      return left.hit.messageId.compareTo(right.hit.messageId);
    });
    final start = cursor.offset.clamp(0, scored.length);
    final end = (start + query.limit).clamp(start, scored.length);
    final truncated = end < scored.length;
    return ConversationHistoryPage(
      hits: [for (final item in scored.sublist(start, end)) item.hit],
      truncated: truncated,
      nextCursor:
          truncated
              ? _encodeCursor(
                chatId: chatId,
                operation: 'search',
                fingerprint: cursor.fingerprint,
                offset: end,
              )
              : null,
    );
  }

  @override
  Future<ConversationHistoryPage> read({
    required String chatId,
    required List<String> references,
    required int surroundingTurns,
    String? cursor,
    String excludedRunId = '',
  }) async {
    if (references.isEmpty || references.length > 8) {
      throw ArgumentError.value(
        references,
        'references',
        'Must contain 1-8 references.',
      );
    }
    if (surroundingTurns < 0 || surroundingTurns > 1) {
      throw ArgumentError.value(surroundingTurns, 'surroundingTurns');
    }
    final normalizedReferences = references.toSet().toList()..sort();
    if (normalizedReferences.any(
      (reference) =>
          !reference.startsWith('turn:') && !reference.startsWith('message:'),
    )) {
      throw ArgumentError('References must use turn: or message: prefixes.');
    }
    final fingerprint = _fingerprint(
      '${normalizedReferences.join('|')}|$surroundingTurns',
    );
    final decoded = _decodeCursor(
      cursor,
      chatId: chatId,
      operation: 'read',
      fingerprint: fingerprint,
    );
    final all = await _messageRepository.getMessages(chatId);
    final visible = [
      for (final message in all)
        if (message.chatId == chatId &&
            message.content.trim().isNotEmpty &&
            (excludedRunId.isEmpty || message.runId != excludedRunId))
          message,
    ];
    final turnIds = <String>{};
    final messageIds = <String>{};
    for (final reference in normalizedReferences) {
      if (reference.startsWith('turn:')) {
        turnIds.add(reference.substring('turn:'.length));
      } else {
        messageIds.add(reference.substring('message:'.length));
      }
    }
    final orderedTurnIds = <String>[];
    for (final message in visible) {
      if (!orderedTurnIds.contains(message.turnId)) {
        orderedTurnIds.add(message.turnId);
      }
    }
    final selectedTurnIds = <String>{...turnIds};
    for (final message in visible) {
      if (messageIds.contains(message.messageId)) {
        selectedTurnIds.add(message.turnId);
      }
    }
    if (surroundingTurns == 1) {
      final original = selectedTurnIds.toList(growable: false);
      for (final turnId in original) {
        final index = orderedTurnIds.indexOf(turnId);
        if (index > 0) selectedTurnIds.add(orderedTurnIds[index - 1]);
        if (index >= 0 && index + 1 < orderedTurnIds.length) {
          selectedTurnIds.add(orderedTurnIds[index + 1]);
        }
      }
    }
    final selected = [
      for (final message in visible)
        if (selectedTurnIds.contains(message.turnId) ||
            messageIds.contains(message.messageId))
          _project(message),
    ];
    const pageSize = 16;
    final start = decoded.offset.clamp(0, selected.length);
    final end = (start + pageSize).clamp(start, selected.length);
    final truncated = end < selected.length;
    return ConversationHistoryPage(
      messages: selected.sublist(start, end),
      truncated: truncated,
      nextCursor:
          truncated
              ? _encodeCursor(
                chatId: chatId,
                operation: 'read',
                fingerprint: fingerprint,
                offset: end,
              )
              : null,
    );
  }
}

ConversationHistoryRole _roleOf(Message message) =>
    message.senderId == message.botId
        ? ConversationHistoryRole.assistant
        : ConversationHistoryRole.user;

ConversationHistoryMessage _project(Message message) =>
    ConversationHistoryMessage(
      turnId: message.turnId,
      messageId: message.messageId,
      role: _roleOf(message),
      timestamp: message.timestamp,
      content: message.content,
      images: message.images,
      files: message.files,
      terminalOutcome: message.terminalOutcome,
      hasPartialContent: message.hasPartialContent,
    );

String _normalizeQuery(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _excerpt(String content, String term) {
  final index = content.toLowerCase().indexOf(term);
  final contentRunes = content.runes.toList(growable: false);
  final matchStart = content.substring(0, index).runes.length;
  final matchLength =
      content.substring(index, index + term.length).runes.length;
  final start = (matchStart - 100).clamp(0, contentRunes.length);
  final end = (matchStart + matchLength + 180).clamp(
    start,
    contentRunes.length,
  );
  final prefix = start > 0 ? '…' : '';
  final suffix = end < contentRunes.length ? '…' : '';
  return '$prefix${String.fromCharCodes(contentRunes.sublist(start, end))}$suffix';
}

String _fingerprint(String value) =>
    sha256.convert(utf8.encode(value)).toString();

typedef _Cursor = ({String fingerprint, int offset});

_Cursor _decodeCursor(
  String? value, {
  required String chatId,
  required String operation,
  required String fingerprint,
}) {
  if (value == null || value.isEmpty) {
    return (fingerprint: fingerprint, offset: 0);
  }
  try {
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(value))),
    );
    if (decoded is! Map ||
        decoded['chat'] != chatId ||
        decoded['operation'] != operation ||
        decoded['fingerprint'] != fingerprint ||
        decoded['offset'] is! int) {
      throw const FormatException();
    }
    return (fingerprint: fingerprint, offset: decoded['offset'] as int);
  } on Object {
    throw ArgumentError.value(value, 'cursor', 'Invalid or stale cursor.');
  }
}

String _encodeCursor({
  required String chatId,
  required String operation,
  required String fingerprint,
  required int offset,
}) => base64Url.encode(
  utf8.encode(
    jsonEncode({
      'chat': chatId,
      'operation': operation,
      'fingerprint': fingerprint,
      'offset': offset,
    }),
  ),
);
