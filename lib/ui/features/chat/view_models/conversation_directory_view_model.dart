import 'package:path/path.dart' as path;
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/conversation_directory_repository.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

final class ConversationDirectoryViewModel extends DisposableChangeNotifier {
  ConversationDirectoryViewModel({
    required this.chatId,
    required ConversationDirectoryRepository repository,
  }) : _repository = repository;

  final String chatId;
  final ConversationDirectoryRepository _repository;

  ConversationDirectorySnapshot? _snapshot;
  String _query = '';
  bool _loading = false;
  AppFailure? _error;
  int _loadGeneration = 0;
  String _requestedRelativePath = '';

  ConversationDirectorySnapshot? get snapshot => _snapshot;
  String get directoryPath => _snapshot?.path ?? '';
  bool get canNavigateUp => _requestedRelativePath.isNotEmpty;
  String get query => _query;
  bool get loading => _loading;
  AppFailure? get error => _error;

  List<ConversationDirectoryEntry> get visibleEntries {
    final entries = _snapshot?.entries ?? const <ConversationDirectoryEntry>[];
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return entries;
    return List<ConversationDirectoryEntry>.unmodifiable(
      entries.where(
        (entry) => entry.name.toLowerCase().contains(normalizedQuery),
      ),
    );
  }

  Future<void> load() => _loadDirectory(_requestedRelativePath);

  Future<void> openDirectory(ConversationDirectoryEntry entry) async {
    if (!entry.isDirectory || isDisposed) return;
    await _loadDirectory(entry.relativePath);
  }

  Future<void> navigateUp() async {
    if (!canNavigateUp || isDisposed) return;
    final parentPath = path.dirname(_requestedRelativePath);
    await _loadDirectory(parentPath == '.' ? '' : parentPath);
  }

  Future<void> _loadDirectory(String relativePath) async {
    if (isDisposed) return;
    final generation = ++_loadGeneration;
    _requestedRelativePath = relativePath;
    _query = '';
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _repository.read(
        chatId,
        relativePath: relativePath,
      );
      if (isDisposed || generation != _loadGeneration) return;
      _snapshot = snapshot;
      _requestedRelativePath = snapshot.relativePath;
    } on Object catch (error) {
      if (isDisposed || generation != _loadGeneration) return;
      _error = AppFailure.from(
        error,
        code: 'conversation_directory_load_failed',
      );
    } finally {
      if (!isDisposed && generation == _loadGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void search(String value) {
    if (isDisposed || value == _query) return;
    _query = value;
    notifyListeners();
  }

  void clearSearch() => search('');
}
