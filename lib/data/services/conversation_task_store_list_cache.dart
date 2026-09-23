part of 'conversation_task_store.dart';

/// Shared by repositories using the same open database. No background stream
/// subscription is retained: committed writes update cached summaries directly.
final class _ConversationTaskListCache {
  static const _capacity = 32;
  final _entries = <String, _ConversationTaskListEntry>{};

  _ConversationTaskListEntry acquire(String chatId) {
    final entry = _entries.remove(chatId) ?? _ConversationTaskListEntry();
    _entries[chatId] = entry;
    entry.listeners++;
    trim();
    return entry;
  }

  void release(_ConversationTaskListEntry entry) {
    entry.listeners--;
    trim();
  }

  void trim() {
    for (final id in _entries.keys.toList()) {
      if (_entries.length <= _capacity) return;
      final entry = _entries[id]!;
      if (entry.listeners == 0 && entry.loading == null) {
        _entries.remove(id);
        unawaited(entry.changes.close());
      }
    }
  }

  void accept(ConversationTaskListItem summary) {
    _entries[summary.chatId]?.accept(summary);
  }

  void clearChat(String chatId) => _entries[chatId]?.clear();
}

final class _ConversationTaskListEntry {
  final changes = StreamController<void>.broadcast();
  final _values = <String, ConversationTaskListItem>{};
  Map<String, ConversationTaskListItem>? _duringLoad;
  List<ConversationTaskListItem>? snapshot;
  Future<void>? loading;
  int listeners = 0;
  int _generation = 0;

  void accept(ConversationTaskListItem summary) {
    final previous = _values[summary.taskId];
    if (previous != null &&
        previous.summaryRevision >= summary.summaryRevision) {
      return;
    }
    _values[summary.taskId] = summary;
    _duringLoad?[summary.taskId] = summary;
    if (snapshot != null) _publish();
  }

  void clear() {
    // An older read must never restore tasks after a committed deletion.
    _generation++;
    _values.clear();
    _duringLoad?.clear();
    _publish();
  }

  void _publish() {
    snapshot = List.unmodifiable(_values.values);
    changes.add(null);
  }

  Future<void> load(
    Future<List<ConversationTaskListItem>> Function() read, {
    required bool refresh,
  }) {
    if (loading case final pending?) return pending;
    if (!refresh && snapshot != null) return Future.value();
    return loading = _load(read).whenComplete(() => loading = null);
  }

  Future<void> _load(
    Future<List<ConversationTaskListItem>> Function() read,
  ) async {
    final generation = _generation;
    final updates = _duringLoad = {};
    try {
      final initial = await read();
      if (generation != _generation) return;
      _values
        ..clear()
        ..addEntries(initial.map((s) => MapEntry(s.taskId, s)));
      for (final summary in updates.values) {
        final previous = _values[summary.taskId];
        if (previous == null ||
            summary.summaryRevision > previous.summaryRevision) {
          _values[summary.taskId] = summary;
        }
      }
      _publish();
    } finally {
      _duringLoad = null;
    }
  }
}
