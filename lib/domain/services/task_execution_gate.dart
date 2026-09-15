import 'dart:async';

/// Serializes a worker's renewal and checkpoint writes, never its external I/O.
/// Database revision and lease fences still arbitrate other workers/commands.
final class TaskExecutionGate {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    return (() async {
      await previous;
      try {
        return await action();
      } finally {
        done.complete();
      }
    })();
  }
}
