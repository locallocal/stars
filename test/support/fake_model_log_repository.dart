import 'dart:async';

import 'package:stars/domain/repositories/model_log_repository.dart';

final class FakeModelLogRepository implements ModelLogRepository {
  ModelLogSettings settings = const ModelLogSettings(
    enabled: false,
    directoryPath: '/home/test/Documents/Stars/logs/models',
  );
  final controller = StreamController<ModelLogSettings>.broadcast();
  bool failLoad = false;
  bool failSave = false;
  int saves = 0;
  int directoryRequests = 0;
  Completer<void>? pendingSave;
  @override
  Stream<ModelLogSettings> get changes => controller.stream;
  @override
  Future<ModelLogSettings> load() async {
    if (failLoad) throw StateError('cannot load');
    return settings;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    saves++;
    await pendingSave?.future;
    if (failSave) throw StateError('cannot save');
    settings = ModelLogSettings(
      enabled: enabled,
      directoryPath: settings.directoryPath,
    );
    controller.add(settings);
  }

  @override
  Future<void> ensureDirectory() async {
    directoryRequests++;
  }

  Future<void> dispose() => controller.close();
}
