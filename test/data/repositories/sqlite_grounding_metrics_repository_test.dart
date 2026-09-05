import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/sqlite_grounding_metrics_repository.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/grounding_metrics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test(
    'terminal metric batches are atomic and idempotent by message hash',
    () async {
      final database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DatabaseService.databaseVersion,
          onConfigure: DatabaseService.configure,
          onCreate: DatabaseService.createSchema,
        ),
      );
      addTearDown(database.close);
      final repository = SqliteGroundingMetricsRepository(
        localDatabase: LocalDatabaseService(
          databaseProvider: () async => database,
        ),
      );
      final deltas = [
        GroundingMetricDelta(
          name: GroundingMetricName.verifiedEvidenceRequired,
        ),
        GroundingMetricDelta(
          name: GroundingMetricName.verifiedEvidencePersisted,
        ),
      ];
      final observationId = 'message_${'a' * 64}';

      await repository.record(deltas, observationId: observationId);
      await repository.record(deltas, observationId: observationId);
      final snapshot = await repository.snapshot();

      expect(snapshot.total(GroundingMetricName.verifiedEvidenceRequired), 1);
      expect(snapshot.total(GroundingMetricName.verifiedEvidencePersisted), 1);
      expect(snapshot.verifiedEvidencePersistenceRate, 1);
      final observations = await database.query(
        'grounding_metric_observations',
      );
      expect(observations, hasLength(1));
      expect(observations.single['observation_id'], observationId);
    },
  );
}
