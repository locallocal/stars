import 'dart:async';

import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/message_file_snapshot.dart';
import 'package:stars/domain/use_cases/resolve_message_local_files.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

/// Publishes text and file cards together, retaining the last complete streaming
/// snapshot until the next one is ready.
final class MessageFilePresentationViewModel extends DisposableChangeNotifier {
  MessageFilePresentationViewModel(this.resolver);

  final ResolveMessageLocalFiles? resolver;
  MessageFileSnapshot? _snapshot;
  MessageFileSnapshot? get snapshot => _snapshot;
  MessageFileRequest? _latest;
  bool _isCurrentUser = false;
  bool _busy = false;
  int _generation = 0;

  void update({
    required String content,
    required List<String> files,
    required Message? sourceMessage,
    required bool isCurrentUser,
  }) {
    if (isDisposed) return;
    final request = MessageFileRequest(
      content: content,
      files: files,
      message: sourceMessage,
    );
    final previous = _latest;
    if (previous != null &&
        request.matches(previous) &&
        isCurrentUser == _isCurrentUser) {
      return;
    }
    final append =
        previous != null &&
        request.appendsTo(previous) &&
        isCurrentUser == _isCurrentUser;
    _latest = request;
    _isCurrentUser = isCurrentUser;
    if (!append) {
      _generation++;
      _busy = false;
      _snapshot = null;
    }
    if (isCurrentUser || resolver == null) {
      _publish(MessageFileSnapshot(content: content, files: files.toSet()));
    } else if (!_busy) {
      _start(request);
    }
  }

  void _start(MessageFileRequest request) {
    final cached = resolver!.cached(request);
    if (cached != null) {
      _publish(cached);
      return;
    }
    _busy = true;
    final generation = ++_generation;
    unawaited(_resolve(request, generation));
    notifyListeners();
  }

  Future<void> _resolve(MessageFileRequest request, int generation) async {
    final resolved = await resolver!.resolve(request);
    if (isDisposed || generation != _generation) return;
    _busy = false;
    _publish(resolved);
    // Coalesce arriving tokens without cancelling or starving the active check.
    final latest = _latest!;
    if (!latest.matches(request)) _start(latest);
  }

  void _publish(MessageFileSnapshot snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }

  @override
  void disposeResources() => _generation++;
}
