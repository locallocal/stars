import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stars/data/services/ai/provider_log_sink.dart';
import 'package:stars/domain/repositories/model_log_repository.dart';

/// Serializes diagnostic writes and bounds both disk use and queued memory.
final class FileModelLogRepository
    implements ModelLogRepository, ProviderLogSink {
  FileModelLogRepository({
    required this.chatId,
    required Future<Directory> Function() directoryProvider,
    this.maxFileBytes = 10 * 1024 * 1024,
    this.maxFiles = 5,
    this.maxQueuedBytes = 8 * 1024 * 1024,
  }) : _directoryProvider = directoryProvider,
       assert(maxFileBytes > 0),
       assert(maxFiles > 0),
       assert(maxQueuedBytes > 0);

  final Future<Directory> Function() _directoryProvider;
  final String chatId;
  final int maxFileBytes;
  final int maxFiles;
  final int maxQueuedBytes;
  final _changes = StreamController<ModelLogSettings>.broadcast();
  Future<ModelLogSettings>? _loading;
  ModelLogSettings? _settings;
  Future<void> _pending = Future.value();
  int _queuedBytes = 0;
  int _droppedEntries = 0;

  @override
  Stream<ModelLogSettings> get changes => _changes.stream;

  @override
  Future<ModelLogSettings> load() =>
      _settings == null ? _loading ??= _load() : Future.value(_settings!);

  Future<ModelLogSettings> _load() async {
    try {
      final directory = await _directoryProvider();
      final config = File(p.join(directory.path, 'settings.json'));
      var enabled = false;
      if (await config.exists()) {
        final value = jsonDecode(await config.readAsString());
        enabled = value is Map && value['enabled'] == true;
      }
      return _settings = ModelLogSettings(
        enabled: enabled,
        directoryPath: directory.path,
      );
    } on Object {
      _loading = null;
      rethrow;
    }
  }

  @override
  Future<bool> get enabled async {
    try {
      return (_settings ?? await load()).enabled;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final current = _settings ?? await load();
    final directory = Directory(current.directoryPath);
    await directory.create(recursive: true);
    final temporary = File(p.join(directory.path, 'settings.json.tmp'));
    await temporary.writeAsString(
      jsonEncode({'enabled': enabled}),
      flush: true,
    );
    await temporary.rename(p.join(directory.path, 'settings.json'));
    _publish(ModelLogSettings(enabled: enabled, directoryPath: directory.path));
  }

  @override
  Future<void> ensureDirectory() async {
    final settings = await load();
    await Directory(settings.directoryPath).create(recursive: true);
  }

  @override
  void add(Map<String, Object?> event) {
    final settings = _settings;
    if (settings == null || !settings.enabled) return;
    final bytes = utf8.encode(
      '${jsonEncode({'schema_version': 1, ...event, 'chat_id': chatId, if (_droppedEntries > 0) 'dropped_entries': _droppedEntries})}\n',
    );
    if (bytes.length > maxFileBytes ||
        _queuedBytes + bytes.length > maxQueuedBytes) {
      _droppedEntries++;
      return;
    }
    _droppedEntries = 0;
    _queuedBytes += bytes.length;
    _pending = _pending.then((_) async {
      try {
        if (_settings?.enabled != true) return;
        final directory = Directory(settings.directoryPath);
        await directory.create(recursive: true);
        final file = File(p.join(directory.path, 'model-requests.jsonl'));
        final length = await file.exists() ? await file.length() : 0;
        if (length > 0 && length + bytes.length > maxFileBytes) {
          await _rotate(directory);
        }
        await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
        _setWriteFailed(false);
      } on Object {
        _setWriteFailed(true);
      } finally {
        _queuedBytes -= bytes.length;
      }
    });
  }

  Future<void> _rotate(Directory directory) async {
    for (var index = maxFiles - 1; index >= 0; index--) {
      final file = File(p.join(directory.path, _name(index)));
      if (!await file.exists()) continue;
      if (index == maxFiles - 1) {
        await file.delete();
      } else {
        await file.rename(p.join(directory.path, _name(index + 1)));
      }
    }
  }

  String _name(int index) =>
      index == 0 ? 'model-requests.jsonl' : 'model-requests.$index.jsonl';

  void _setWriteFailed(bool failed) {
    final current = _settings;
    if (current == null || current.writeFailed == failed) return;
    _publish(
      ModelLogSettings(
        enabled: current.enabled,
        directoryPath: current.directoryPath,
        writeFailed: failed,
      ),
    );
  }

  void _publish(ModelLogSettings settings) {
    _settings = settings;
    if (!_changes.isClosed) _changes.add(settings);
  }

  Future<void> flush() => _pending;

  Future<void> dispose() async {
    await flush();
    await _changes.close();
  }
}
