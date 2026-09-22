import 'package:stars/domain/repositories/conversation_task_repository.dart';

/// Content-free counters for the lifetime of a persistence service.
final class TaskPersistenceMetrics {
  int acceptances = 0;
  int acceptanceFailures = 0;
  int progressUpdates = 0;
  int writeFailures = 0;
  int reusedWrites = 0;
  int committedWriteMicroseconds = 0;
  int orphanAcknowledgements = 0;
  int taskListSnapshotReads = 0;
  final Map<TaskWriteConflictReason, int> _conflicts = {};

  Map<TaskWriteConflictReason, int> get conflicts =>
      Map.unmodifiable(_conflicts);

  void recordConflict(TaskWriteConflictReason reason) {
    _conflicts.update(reason, (count) => count + 1, ifAbsent: () => 1);
  }
}
