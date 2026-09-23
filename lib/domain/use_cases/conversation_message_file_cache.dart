import 'package:stars/domain/use_cases/resolve_message_local_files.dart';

/// Owns file snapshots across conversation page lifetimes within the app.
/// Each chat retains its own directory, evidence scope and in-flight requests.
final class ConversationMessageFileCache {
  ConversationMessageFileCache({required this.createResolver});

  final ResolveMessageLocalFiles Function(String chatId) createResolver;
  final _conversations = <String, ResolveMessageLocalFiles>{};

  ResolveMessageLocalFiles forChat(String chatId) =>
      _conversations.putIfAbsent(chatId, () => createResolver(chatId));

  void remove(String chatId) => _conversations.remove(chatId)?.clear();

  void clear() {
    for (final resolver in _conversations.values) {
      resolver.clear();
    }
    _conversations.clear();
  }
}
