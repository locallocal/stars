import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/domain/models/app_failure.dart';

void main() {
  late Directory documents;
  late String databasePath;
  late String backupPath;
  DatabaseService service() => DatabaseService(
    applicationDocumentsDirectoryProvider: () async => documents,
  );
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    documents = await Directory.systemTemp.createTemp('stars-cutover-');
    databasePath = path.join(documents.path, 'Stars', 'app.db');
    backupPath = path.join(documents.path, 'Stars', '.stars_backup_current');
    final database = await service().initDatabase();
    await database.close();
    // Reopening a valid current database makes a current-schema backup.
    final checked = await service().initDatabase();
    await checked.close();
  });
  tearDown(() => documents.delete(recursive: true));

  test(
    'an old database is rejected even when a current backup exists',
    () async {
      final database = await openDatabase(databasePath);
      await database.setVersion(DatabaseService.databaseVersion - 1);
      await database.close();
      final before = await File(databasePath).readAsBytes();
      await expectLater(
        service().initDatabase(),
        _failure('database_rebuild_required'),
      );
      expect(await File(databasePath).readAsBytes(), before);
      final unchanged = await openDatabase(databasePath, readOnly: true);
      expect(await unchanged.getVersion(), DatabaseService.databaseVersion - 1);
      await unchanged.close();
    },
  );

  for (final boundary in ['manifest', 'database version', 'schema']) {
    test('recovery refuses a backup with an obsolete $boundary', () async {
      if (boundary == 'manifest') {
        await File(path.join(backupPath, 'manifest.json')).writeAsString(
          jsonEncode({'schema_version': DatabaseService.databaseVersion - 1}),
        );
      } else {
        final backup = await openDatabase(path.join(backupPath, 'app.db'));
        if (boundary == 'database version') {
          await backup.setVersion(DatabaseService.databaseVersion - 1);
        } else {
          // A relabelled version must not admit the removed run-only table.
          await backup.execute(
            'CREATE TABLE agent_run_answer_checkpoints (run_id TEXT)',
          );
        }
        await backup.close();
      }
      final damaged = [0, 1, 2, 3];
      await File(databasePath).writeAsBytes(damaged, flush: true);
      final asset = File(
        path.join(documents.path, 'Stars', 'chats', 'draft.txt'),
      );
      await asset.parent.create(recursive: true);
      await asset.writeAsString('preserve current assets');
      await expectLater(
        service().initDatabase(),
        _failure('database_recovery_failed'),
      );
      expect(await File(databasePath).readAsBytes(), damaged);
      expect(await asset.readAsString(), 'preserve current assets');
    });
  }
}

Matcher _failure(String code) =>
    throwsA(isA<AppFailure>().having((failure) => failure.code, 'code', code));
