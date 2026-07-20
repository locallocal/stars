import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/use_cases/create_chat.dart';

class BotListViewModel extends ChangeNotifier {
  BotListViewModel({
    required BotRepository botRepository,
    required CreateChat createChat,
  }) : _botRepository = botRepository,
       _createChat = createChat {
    _subscription = _botRepository.changes.listen(_applyBots);
  }

  final BotRepository _botRepository;
  final CreateChat _createChat;
  late final StreamSubscription<List<Bot>> _subscription;

  List<Bot> _bots = const [];
  List<Bot> _filteredBots = const [];
  String _query = '';
  Object? _error;
  bool _isLoading = false;
  int _loadGeneration = 0;

  List<Bot> get bots => _bots;
  List<Bot> get filteredBots => _filteredBots;
  String get query => _query;
  Object? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final bots = await _botRepository.getBots();
      if (generation != _loadGeneration) return;
      _applyBots(bots, notify: false);
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

  Future<Chat> startChat(Bot bot) => _createChat(bot);

  Future<void> addBot(Bot bot) => _botRepository.addBot(bot);

  Future<void> updateBot(Bot bot) => _botRepository.updateBot(bot);

  Future<void> deleteBot(String id) => _botRepository.deleteBot(id);

  void _applyBots(List<Bot> bots, {bool notify = true}) {
    _bots = List<Bot>.unmodifiable(bots);
    _applyFilter();
    if (notify) notifyListeners();
  }

  void _applyFilter() {
    final normalized = _query.trim().toLowerCase();
    _filteredBots =
        normalized.isEmpty
            ? _bots
            : List<Bot>.unmodifiable(
              _bots.where((bot) => bot.name.toLowerCase().contains(normalized)),
            );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
