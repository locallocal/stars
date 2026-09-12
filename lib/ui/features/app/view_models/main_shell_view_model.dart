import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

class MainShellViewModel extends DisposableChangeNotifier {
  MainShellViewModel({required BotRepository botRepository})
    : _botRepository = botRepository;

  final BotRepository _botRepository;

  int _currentIndex = 0;
  String? _selectedChatId;
  String? _selectedChatName;
  Bot? _selectedChatBot;
  Bot? _selectedBot;
  bool _isEditingSelectedBot = false;
  int _selectedProfileSection = 0;

  int get currentIndex => _currentIndex;
  String? get selectedChatId => _selectedChatId;
  String? get selectedChatName => _selectedChatName;
  Bot? get selectedChatBot => _selectedChatBot;
  Bot? get selectedBot => _selectedBot;
  bool get isEditingSelectedBot => _isEditingSelectedBot;
  int get selectedProfileSection => _selectedProfileSection;
  bool get isChatSelectionVisible => _currentIndex == 0;

  void selectChat(String chatId, Bot bot, {String? chatName}) {
    final normalizedChatName = chatName?.trim();
    _selectedChatId = chatId;
    _selectedChatName =
        normalizedChatName?.isNotEmpty == true ? normalizedChatName : bot.name;
    _selectedChatBot = bot;
    _currentIndex = 0;
    notifyListeners();
  }

  void selectBot(Bot bot) {
    _selectedBot = bot;
    _isEditingSelectedBot = false;
    _currentIndex = 1;
    notifyListeners();
  }

  void editBot(Bot bot) {
    _selectedBot = bot;
    _isEditingSelectedBot = true;
    _currentIndex = 1;
    notifyListeners();
  }

  void clearSelectedChat() {
    _selectedChatId = null;
    _selectedChatName = null;
    _selectedChatBot = null;
    notifyListeners();
  }

  void clearSelectedBot() {
    _selectedBot = null;
    _isEditingSelectedBot = false;
    notifyListeners();
  }

  void selectPage(int index) {
    _currentIndex = index;
    if (index == 1) {
      _selectedBot = null;
      _isEditingSelectedBot = false;
    }
    notifyListeners();
  }

  void selectProfileSection(int section) {
    _selectedProfileSection = section;
    _currentIndex = 4;
    notifyListeners();
  }

  void applyBotUpdate(Bot bot) {
    if (_selectedBot?.id == bot.id) _selectedBot = bot;
    if (_selectedChatBot?.id == bot.id) _selectedChatBot = bot;
    notifyListeners();
  }

  void applyChatNameUpdate(String chatId, String name) {
    if (_selectedChatId != chatId) return;
    final normalizedName = name.trim();
    _selectedChatName =
        normalizedName.isEmpty ? _selectedChatBot?.name : normalizedName;
    notifyListeners();
  }

  Future<void> updateBot(Bot bot) async {
    if (isDisposed) return;
    await _botRepository.updateBot(bot);
    if (isDisposed) return;
    applyBotUpdate(bot);
  }

  Future<void> deleteSelectedBot() async {
    if (isDisposed) return;
    final botId = _selectedBot?.id;
    if (botId == null) return;
    await _botRepository.deleteBot(botId);
    if (isDisposed) return;
    if (_selectedChatBot?.id == botId) {
      _selectedChatId = null;
      _selectedChatName = null;
      _selectedChatBot = null;
    }
    _selectedBot = null;
    _isEditingSelectedBot = false;
    notifyListeners();
  }
}
