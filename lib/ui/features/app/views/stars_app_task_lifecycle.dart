part of 'stars_app.dart';

final class _TaskAppLifecycle with WidgetsBindingObserver {
  _TaskAppLifecycle(this.tasks) {
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null) didChangeAppLifecycleState(state);
  }
  final AppConversationTasks tasks;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.resumed) {
      _observe(tasks.setSuspended(state != AppLifecycleState.resumed));
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _observe(tasks.dispose());
  }

  void _observe(Future<void> operation) {
    unawaited(
      operation.catchError((Object _) {
        tasks.scheduler.metrics.failures++;
      }),
    );
  }
}
