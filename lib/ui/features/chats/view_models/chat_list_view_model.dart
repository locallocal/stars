import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';

class ChatListViewModel extends ChangeNotifier {
  ChatListViewModel({
    required ChatRepository chatRepository,
    required BotRepository botRepository,
  }) : _chatRepository = chatRepository,
       _botRepository = botRepository {
    _chatSubscription = _chatRepository.changes.listen((_) => load());
    _botSubscription = _botRepository.changes.listen((_) => load());
  }

  final ChatRepository _chatRepository;
  final BotRepository _botRepository;
  late final StreamSubscription<List<Chat>> _chatSubscription;
  late final StreamSubscription<List<Bot>> _botSubscription;

  List<Chat> _chats = const [];
  List<Bot> _bots = const [];
  List<Chat> _filteredChats = const [];
  String _query = '';
  Object? _error;
  bool _isLoading = false;
  int _loadGeneration = 0;

  List<Chat> get chats => _chats;
  List<Bot> get bots => _bots;
  List<Chat> get filteredChats => _filteredChats;
  String get query => _query;
  Object? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _chatRepository.getChats(),
        _botRepository.getBots(),
      ]);
      if (generation != _loadGeneration) return;
      _chats = List<Chat>.unmodifiable(results[0] as List<Chat>);
      _bots = List<Bot>.unmodifiable(results[1] as List<Bot>);
      _applyFilter();
    } catch (error) {
      if (generation != _loadGeneration) return;
      _error = error;
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void search(String query) {
    _query = query;
    _applyFilter();
    notifyListeners();
  }

  Future<void> deleteChat(String id) => _chatRepository.deleteChat(id);

  void _applyFilter() {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      _filteredChats = _chats;
      return;
    }
    final botNames = <String, String>{
      for (final bot in _bots) bot.id: bot.name.toLowerCase(),
    };
    _filteredChats = List<Chat>.unmodifiable(
      _chats.where(
        (chat) =>
            chat.lastMessage.toLowerCase().contains(normalized) ||
            (botNames[chat.botId]?.contains(normalized) ?? false),
      ),
    );
  }

  @override
  void dispose() {
    _chatSubscription.cancel();
    _botSubscription.cancel();
    super.dispose();
  }
}
