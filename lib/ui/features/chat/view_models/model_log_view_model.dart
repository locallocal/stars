import 'dart:async';

import 'package:stars/domain/repositories/model_log_repository.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

enum ModelLogActionError { load, save, open, copy }

class ModelLogViewModel extends DisposableChangeNotifier {
  ModelLogViewModel({
    required this.chatId,
    required ModelLogRepository repository,
    required Future<bool> Function(Uri) openDirectory,
    required Future<void> Function(String) copyText,
  }) : _repository = repository,
       _openDirectory = openDirectory,
       _copyText = copyText {
    _subscription = repository.changes.listen((settings) {
      if (isDisposed) return;
      _settings = settings;
      notifyListeners();
    });
  }

  final String chatId;
  final ModelLogRepository _repository;
  final Future<bool> Function(Uri) _openDirectory;
  final Future<void> Function(String) _copyText;
  late final StreamSubscription<ModelLogSettings> _subscription;
  ModelLogSettings? _settings;
  ModelLogActionError? _error;
  bool _busy = false;
  bool _pathCopied = false;

  ModelLogSettings? get settings => _settings;
  ModelLogActionError? get error => _error;
  bool get busy => _busy;
  bool get pathCopied => _pathCopied;

  Future<void> load() => _run(ModelLogActionError.load, () async {
    final settings = await _repository.load();
    if (!isDisposed) _settings = settings;
  });

  Future<void> setEnabled(bool enabled) =>
      _run(ModelLogActionError.save, () async {
        await _repository.setEnabled(enabled);
        final settings = await _repository.load();
        if (!isDisposed) _settings = settings;
      });

  Future<void> openDirectory() => _run(ModelLogActionError.open, () async {
    await _repository.ensureDirectory();
    if (isDisposed) return;
    if (!await _openDirectory(Uri.directory(_settings!.directoryPath))) {
      throw StateError('Directory could not be opened');
    }
  });

  Future<void> copyPath() => _run(ModelLogActionError.copy, () async {
    await _copyText(_settings!.directoryPath);
    if (!isDisposed) _pathCopied = true;
  });

  Future<void> _run(
    ModelLogActionError error,
    Future<void> Function() action,
  ) async {
    if (_busy || isDisposed) return;
    _busy = true;
    _error = null;
    _pathCopied = false;
    notifyListeners();
    try {
      await action();
    } on Object {
      if (!isDisposed) _error = error;
    } finally {
      if (!isDisposed) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void disposeResources() => unawaited(_subscription.cancel());
}
