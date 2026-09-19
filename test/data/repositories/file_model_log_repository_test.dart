import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/file_model_log_repository.dart';

void main() {
  late Directory root;
  late FileModelLogRepository repository;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('stars-model-logs-');
    repository = FileModelLogRepository(
      chatId: 'chat-a',
      directoryProvider: () async => root,
    );
  });
  tearDown(() async {
    await repository.dispose();
    await root.delete(recursive: true);
  });

  test(
    'defaults off, persists the switch and reloads the current value',
    () async {
      expect((await repository.load()).enabled, isFalse);
      repository.add({'event': 'ignored'});
      await repository.flush();
      expect(await root.list().isEmpty, isTrue);
      await repository.setEnabled(true);
      expect((await repository.load()).enabled, isTrue);
      final restarted = FileModelLogRepository(
        chatId: 'chat-a',
        directoryProvider: () async => root,
      );
      addTearDown(restarted.dispose);
      expect(await restarted.enabled, isTrue);
      await repository.setEnabled(false);
      expect((await repository.load()).enabled, isFalse);
    },
  );

  test('concurrent entries remain separate ordered JSON lines', () async {
    await repository.setEnabled(true);
    for (var i = 0; i < 100; i++) {
      repository.add({'event': 'request', 'index': i, 'body': '第一行\n第二行'});
    }
    await repository.flush();
    final lines = await File('${root.path}/model-requests.jsonl').readAsLines();
    expect(lines, hasLength(100));
    for (var i = 0; i < lines.length; i++) {
      final entry = jsonDecode(lines[i]) as Map;
      expect(entry['index'], i);
      expect(entry['schema_version'], 1);
      expect(entry['body'], '第一行\n第二行');
    }
  });

  test('rotation bounds storage and retains newest entries', () async {
    await repository.dispose();
    repository = FileModelLogRepository(
      chatId: 'chat-a',
      directoryProvider: () async => root,
      maxFileBytes: 100,
      maxFiles: 3,
    );
    await repository.setEnabled(true);
    for (var i = 0; i < 6; i++) {
      repository.add({'index': i, 'body': '012345678901234567890123456789'});
    }
    await repository.flush();
    final logs =
        await root.list().where((f) => f.path.endsWith('.jsonl')).toList();
    expect(logs, hasLength(3));
    for (final file in logs.cast<File>()) {
      expect(await file.length(), lessThanOrEqualTo(100));
    }
    expect(
      jsonDecode(
        await File('${root.path}/model-requests.jsonl').readAsString(),
      )['index'],
      5,
    );
    expect(
      jsonDecode(
        await File('${root.path}/model-requests.2.jsonl').readAsString(),
      )['index'],
      3,
    );
    expect(await File('${root.path}/settings.json').exists(), isTrue);
  });

  test('reports dropped entries after a bounded queue recovers', () async {
    await repository.dispose();
    repository = FileModelLogRepository(
      chatId: 'chat-a',
      directoryProvider: () async => root,
      maxQueuedBytes: 140,
    );
    await repository.setEnabled(true);
    repository.add({'body': 'a' * 60});
    repository.add({'body': 'b' * 60});
    await repository.flush();
    repository.add({'body': 'recovered'});
    await repository.flush();
    final lines = await File('${root.path}/model-requests.jsonl').readAsLines();
    expect(lines, hasLength(2));
    expect(jsonDecode(lines.last)['dropped_entries'], 1);
  });

  test(
    'disabling logging stops writes without deleting existing logs',
    () async {
      await repository.setEnabled(true);
      repository.add({'body': 'before'});
      await repository.flush();
      await repository.setEnabled(false);
      repository.add({'body': 'after'});
      await repository.flush();
      final lines =
          await File('${root.path}/model-requests.jsonl').readAsLines();
      expect(lines, hasLength(1));
      expect(jsonDecode(lines.single)['body'], 'before');
    },
  );

  test('write errors are observable and later writes recover', () async {
    final folder = Directory('${root.path}/logs');
    await repository.dispose();
    repository = FileModelLogRepository(
      chatId: 'chat-a',
      directoryProvider: () async => folder,
    );
    await repository.setEnabled(true);
    await folder.delete(recursive: true);
    final obstacle = await File(folder.path).writeAsString('blocked');
    repository.add({'body': 'cannot write'});
    await repository.flush();
    expect((await repository.load()).writeFailed, isTrue);
    await obstacle.delete();
    repository.add({'body': 'recovered'});
    await repository.flush();
    expect((await repository.load()).writeFailed, isFalse);
  });

  test('load errors disable diagnostics and can be retried', () async {
    await File('${root.path}/settings.json').writeAsString('{broken');
    expect(await repository.enabled, isFalse);
    await File('${root.path}/settings.json').writeAsString('{"enabled":true}');
    expect(await repository.enabled, isTrue);
  });
}
