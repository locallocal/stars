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
  bool _mutating = false;
  AppFailure? _mutationError;

  ConversationDirectorySnapshot? get snapshot => _snapshot;
  String get directoryPath => _snapshot?.path ?? '';
  bool get canNavigateUp => _requestedRelativePath.isNotEmpty;
  String get query => _query;
  bool get loading => _loading;
  AppFailure? get error => _error;
  bool get mutating => _mutating;
  bool get busy => _loading || _mutating;
  AppFailure? get mutationError => _mutationError;

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

  /// Resolves a listed file while keeping path handling out of the view.
  String? filePathFor(ConversationDirectoryEntry entry) {
    final currentPath = _snapshot?.path;
    if (currentPath == null || entry.isDirectory) return null;
    final normalizedDirectory = path.normalize(currentPath);
    final filePath = path.normalize(path.join(normalizedDirectory, entry.name));
    return path.isWithin(normalizedDirectory, filePath) ? filePath : null;
  }

  Future<void> load() async {
    if (_mutating) return;
    await _loadDirectory(_requestedRelativePath);
  }

  Future<void> openDirectory(ConversationDirectoryEntry entry) async {
    if (!entry.isDirectory || isDisposed || _mutating) return;
    await _loadDirectory(entry.relativePath);
  }

  Future<void> navigateUp() async {
    if (!canNavigateUp || isDisposed || _mutating) return;
    final parentPath = path.dirname(_requestedRelativePath);
    await _loadDirectory(parentPath == '.' ? '' : parentPath);
  }

  Future<void> _loadDirectory(
    String relativePath, {
    bool clearSearch = true,
  }) async {
    if (isDisposed) return;
    final generation = ++_loadGeneration;
    _requestedRelativePath = relativePath;
    if (clearSearch) _query = '';
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _repository.read(
        chatId,
        relativePath: relativePath,
      );
      if (isDisposed || generation != _loadGeneration) return;
      final sortedEntries =
          snapshot.entries.toList()..sort(_compareDirectoryEntries);
      _snapshot = ConversationDirectorySnapshot(
        path: snapshot.path,
        relativePath: snapshot.relativePath,
        entries: sortedEntries,
      );
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

  void clearMutationError() {
    if (isDisposed || _mutationError == null || _mutating) return;
    _mutationError = null;
    notifyListeners();
  }

  Future<bool> renameEntry(ConversationDirectoryEntry entry, String newName) =>
      _mutate(entry, () async {
        if (!isValidConversationEntryName(newName)) {
          throw const AppFailure.validation('conversation_entry_name_invalid');
        }
        await _repository.rename(
          chatId,
          relativePath: entry.relativePath,
          newName: newName,
        );
      }, 'conversation_entry_rename_failed');

  Future<bool> deleteEntry(ConversationDirectoryEntry entry) => _mutate(
    entry,
    () => _repository.delete(chatId, relativePath: entry.relativePath),
    'conversation_entry_delete_failed',
  );

  Future<bool> _mutate(
    ConversationDirectoryEntry entry,
    Future<void> Function() operation,
    String failureCode,
  ) async {
    if (isDisposed || busy) return false;
    if (!(_snapshot?.entries.contains(entry) ?? false)) {
      _mutationError = const AppFailure.validation(
        'conversation_entry_missing',
      );
      notifyListeners();
      return false;
    }
    _mutating = true;
    _mutationError = null;
    notifyListeners();
    try {
      await operation();
      if (isDisposed) return false;
      await _loadDirectory(_requestedRelativePath, clearSearch: false);
      // A refresh failure is shown by the browser. The mutation still succeeded
      // and must not be offered for submission a second time.
      return !isDisposed;
    } on Object catch (error) {
      if (!isDisposed) {
        _mutationError = AppFailure.from(error, code: failureCode);
      }
      return false;
    } finally {
      if (!isDisposed) {
        _mutating = false;
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

int _compareDirectoryEntries(
  ConversationDirectoryEntry left,
  ConversationDirectoryEntry right,
) {
  if (left.isDirectory != right.isDirectory) {
    return left.isDirectory ? -1 : 1;
  }
  final normalizedNameComparison = left.name.toLowerCase().compareTo(
    right.name.toLowerCase(),
  );
  if (normalizedNameComparison != 0) return normalizedNameComparison;
  return left.name.compareTo(right.name);
}
