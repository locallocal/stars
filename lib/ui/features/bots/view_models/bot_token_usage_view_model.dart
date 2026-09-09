import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/ui/core/view_models/token_usage_timeline.dart';

@immutable
class BotConversationTokenUsage {
  const BotConversationTokenUsage({
    required this.chatId,
    required this.preview,
    required this.usage,
  });

  const BotConversationTokenUsage.deleted({required this.usage})
    : chatId = null,
      preview = '';

  final String? chatId;
  final String preview;
  final ModelTokenUsage usage;

  bool get isDeleted => chatId == null;
}

class BotTokenUsageViewModel extends ChangeNotifier {
  BotTokenUsageViewModel({
    required this.botId,
    required MessageRepository messageRepository,
    required ChatRepository chatRepository,
    DateTime Function()? now,
  }) : _messageRepository = messageRepository,
       _chatRepository = chatRepository,
       _timeline = TokenUsageTimelineState(now: now) {
    _messageSubscription = messageRepository.changes.listen(
      (_) => _scheduleLoad(),
    );
    _chatSubscription = chatRepository.changes.listen((_) => _scheduleLoad());
  }

  final String botId;
  final MessageRepository _messageRepository;
  final ChatRepository _chatRepository;
  final TokenUsageTimelineState _timeline;
  late final StreamSubscription<void> _messageSubscription;
  late final StreamSubscription<List<Chat>> _chatSubscription;

  ModelTokenUsage _usage = ModelTokenUsage.empty;
  List<BotConversationTokenUsage> _conversationUsages = const [];
  AppFailure? _error;
  bool _isLoading = false;
  bool _loadScheduled = false;
  bool _disposed = false;
  int _loadGeneration = 0;

  ModelTokenUsage get usage => _usage;
  List<BotConversationTokenUsage> get conversationUsages => _conversationUsages;
  List<TokenUsageBucket> get dailyBuckets => _timeline.dailyBuckets;
  List<TokenUsageBucket> get visibleBuckets => _timeline.visibleBuckets;
  DateTime? get selectedDay => _timeline.selectedDay;
  TokenUsageGranularity get granularity => _timeline.granularity;
  AppFailure? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final (records, chats) =
          await (
            _messageRepository.getTokenUsageRecordsForBot(botId),
            _chatRepository.getChats(),
          ).wait;
      if (_disposed || generation != _loadGeneration) return;

      _timeline.replaceRecords(records);
      final usageByChat = <String, ModelTokenUsage>{};
      for (final record in records) {
        if (!record.usage.hasData) continue;
        usageByChat[record.chatId] =
            (usageByChat[record.chatId] ?? ModelTokenUsage.empty) +
            record.usage;
      }
      final chatsById = {for (final chat in chats) chat.id: chat};
      final entries = <BotConversationTokenUsage>[];
      var deletedConversationUsage = ModelTokenUsage.empty;
      for (final entry in usageByChat.entries) {
        if (!entry.value.hasData) continue;
        final chat = chatsById[entry.key];
        if (chat == null) {
          deletedConversationUsage += entry.value;
          continue;
        }
        entries.add(
          BotConversationTokenUsage(
            chatId: entry.key,
            preview: chat.lastMessage.trim(),
            usage: entry.value,
          ),
        );
      }
      if (deletedConversationUsage.hasData) {
        entries.add(
          BotConversationTokenUsage.deleted(usage: deletedConversationUsage),
        );
      }
      entries.sort(_compareConversationUsage);
      _usage = _timeline.totalUsage;
      _conversationUsages = List<BotConversationTokenUsage>.unmodifiable(
        entries,
      );
    } catch (error) {
      if (_disposed || generation != _loadGeneration) return;
      _error = AppFailure.from(error, code: 'bot_usage_load_failed');
    } finally {
      if (!_disposed && generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void selectDay(DateTime day) {
    if (_timeline.selectDay(day)) notifyListeners();
  }

  void showDaily() {
    if (_timeline.showDaily()) notifyListeners();
  }

  void _scheduleLoad() {
    if (_disposed || _loadScheduled) return;
    _loadScheduled = true;
    scheduleMicrotask(() {
      _loadScheduled = false;
      if (!_disposed) unawaited(load());
    });
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_messageSubscription.cancel());
    unawaited(_chatSubscription.cancel());
    super.dispose();
  }
}

int _compareConversationUsage(
  BotConversationTokenUsage left,
  BotConversationTokenUsage right,
) {
  final usageOrder = right.usage.effectiveTotalTokens.compareTo(
    left.usage.effectiveTotalTokens,
  );
  if (usageOrder != 0) return usageOrder;
  if (left.isDeleted != right.isDeleted) return left.isDeleted ? 1 : -1;
  return (left.chatId ?? '').compareTo(right.chatId ?? '');
}
