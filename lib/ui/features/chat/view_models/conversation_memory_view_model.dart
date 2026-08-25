import 'dart:async';

import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/use_cases/compact_conversation.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

final class ConversationMemoryViewModel extends DisposableChangeNotifier {
  ConversationMemoryViewModel({
    required this.chatId,
    required this.bot,
    required ConversationMemoryRepository repository,
    required CompactConversation compactConversation,
    required ConversationArtifactsDirectoryProvider
    conversationArtifactsDirectoryProvider,
  }) : _repository = repository,
       _compactConversation = compactConversation,
       _conversationArtifactsDirectoryProvider =
           conversationArtifactsDirectoryProvider {
    _subscription = _repository.changes
        .where((changedChatId) => changedChatId == chatId)
        .listen((_) => unawaited(load()));
  }

  final String chatId;
  final Bot bot;
  final ConversationMemoryRepository _repository;
  final CompactConversation _compactConversation;
  final ConversationArtifactsDirectoryProvider
  _conversationArtifactsDirectoryProvider;
  StreamSubscription<String>? _subscription;

  ConversationMemoryState? _state;
  ConversationSummaryDocument? _summary;
  List<ConversationMemoryItem> _items = const [];
  String _artifactsDirectoryPath = '';
  bool _loading = false;
  bool _compacting = false;
  AppFailure? _error;
  int _loadGeneration = 0;

  ConversationMemoryState? get state => _state;
  ConversationSummaryDocument? get summary => _summary;
  List<ConversationMemoryItem> get items => _items;
  String get artifactsDirectoryPath => _artifactsDirectoryPath;
  bool get loading => _loading;
  bool get compacting => _compacting;
  AppFailure? get error => _error;

  Future<void> load() async {
    if (isDisposed) return;
    final generation = ++_loadGeneration;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final artifactsDirectoryPath =
          await _conversationArtifactsDirectoryProvider(chatId);
      if (artifactsDirectoryPath.trim().isEmpty) {
        throw StateError(
          'The conversation artifacts directory is unavailable.',
        );
      }
      final state = await _repository.getState(chatId);
      final summary = await _repository.getActiveSummary(chatId);
      final items = await _repository.getItems(chatId);
      if (isDisposed || generation != _loadGeneration) return;
      _state = state;
      _summary = summary;
      _items = List<ConversationMemoryItem>.unmodifiable(items);
      _artifactsDirectoryPath = artifactsDirectoryPath;
    } catch (error) {
      if (isDisposed || generation != _loadGeneration) return;
      _error = AppFailure.from(error, code: 'conversation_memory_load_failed');
    } finally {
      if (!isDisposed && generation == _loadGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<ConversationCompactionResult> compactNow({
    bool rebuild = false,
  }) async {
    if (isDisposed || _compacting) {
      return ConversationCompactionResult.noCandidates;
    }
    _compacting = true;
    _error = null;
    notifyListeners();
    try {
      if (rebuild) {
        await _repository.clearAutomaticMemory(chatId);
        if (isDisposed) return ConversationCompactionResult.noCandidates;
      }
      final result = await _compactConversation(
        bot: bot,
        chatId: chatId,
        manual: true,
      );
      if (!isDisposed) await load();
      return result;
    } catch (error) {
      if (!isDisposed) {
        _error = AppFailure.from(
          error,
          code: 'conversation_memory_update_failed',
        );
        notifyListeners();
      }
      rethrow;
    } finally {
      if (!isDisposed) {
        _compacting = false;
        notifyListeners();
      }
    }
  }

  Future<void> setAutoMemoryEnabled(bool enabled) async {
    if (isDisposed) return;
    await _repository.setAutoMemoryEnabled(chatId, enabled);
    if (isDisposed) return;
    await load();
  }

  Future<void> saveItem(
    ConversationMemoryItem item, {
    String? content,
    ConversationMemoryItemState? state,
  }) async {
    if (isDisposed) return;
    await _repository.saveUserItem(
      item.copyWith(content: content, state: state, updatedAt: DateTime.now()),
    );
    if (isDisposed) return;
    await load();
  }

  Future<void> forgetItem(ConversationMemoryItem item) async {
    if (isDisposed) return;
    await _repository.forgetItem(chatId, item.id);
    if (isDisposed) return;
    await load();
  }

  Future<void> restoreItem(ConversationMemoryItem item) async {
    if (isDisposed) return;
    await _repository.restoreItem(chatId, item.id);
    if (isDisposed) return;
    await load();
  }

  Future<void> clearAutomaticMemory() async {
    if (isDisposed) return;
    await _repository.clearAutomaticMemory(chatId);
    if (isDisposed) return;
    await load();
  }

  @override
  void disposeResources() {
    unawaited(_subscription?.cancel());
  }
}
