import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';

class MainShellViewModel extends ChangeNotifier {
  MainShellViewModel({required BotRepository botRepository})
    : _botRepository = botRepository;

  final BotRepository _botRepository;

  int _currentIndex = 0;
  String? _selectedChatId;
  Bot? _selectedChatBot;
  Bot? _selectedBot;
  int _selectedProfileSection = 0;

  int get currentIndex => _currentIndex;
  String? get selectedChatId => _selectedChatId;
  Bot? get selectedChatBot => _selectedChatBot;
  Bot? get selectedBot => _selectedBot;
  int get selectedProfileSection => _selectedProfileSection;

  void selectChat(String chatId, Bot bot) {
    _selectedChatId = chatId;
    _selectedChatBot = bot;
    _currentIndex = 0;
    notifyListeners();
  }

  void selectBot(Bot bot) {
    _selectedBot = bot;
    _currentIndex = 1;
    notifyListeners();
  }

  void clearSelectedChat() {
    _selectedChatId = null;
    _selectedChatBot = null;
    notifyListeners();
  }

  void clearSelectedBot() {
    _selectedBot = null;
    notifyListeners();
  }

  void selectPage(int index) {
    _currentIndex = index;
    if (index == 1) _selectedBot = null;
    notifyListeners();
  }

  void selectProfileSection(int section) {
    _selectedProfileSection = section;
    _currentIndex = 2;
    notifyListeners();
  }

  void applyBotUpdate(Bot bot) {
    if (_selectedBot?.id == bot.id) _selectedBot = bot;
    if (_selectedChatBot?.id == bot.id) _selectedChatBot = bot;
    notifyListeners();
  }

  Future<void> updateBot(Bot bot) async {
    await _botRepository.updateBot(bot);
    applyBotUpdate(bot);
  }

  Future<void> deleteSelectedBot() async {
    final botId = _selectedBot?.id;
    if (botId == null) return;
    await _botRepository.deleteBot(botId);
    if (_selectedChatBot?.id == botId) {
      _selectedChatId = null;
      _selectedChatBot = null;
    }
    _selectedBot = null;
    notifyListeners();
  }
}
