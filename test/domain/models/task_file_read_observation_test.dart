import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/task_execution_state.dart';
import 'package:stars/domain/models/task_file_read_observation.dart';

void main() {
  TaskFileReadObservation page(String id, {int length = 1}) =>
      TaskFileReadObservation(
        attemptId: id,
        stepId: 'read',
        requestedPath: 'report.md',
        path: '/reports/report.md',
        encoding: 'utf8',
        content: 'a' * length,
        offsetBytes: 0,
        nextOffsetBytes: length,
        sizeBytes: length,
        maxBytes: 65536,
        redacted: false,
      );

  test(
    'prepared pages are portable and immutable; legacy states stay valid',
    () {
      final state = TaskExecutionState(fileReads: [page('attempt')]);
      final restored = TaskExecutionState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>,
      );
      expect(restored.toJson(), state.toJson());
      expect(() => restored.fileReads.clear(), throwsUnsupportedError);
      final legacy = TaskExecutionState().toJson();
      expect(legacy, isNot(contains('fileReads')));
      expect(TaskExecutionState.fromJson(legacy).fileReads, isEmpty);
      expect(
        () => TaskFileReadObservation.fromJson({
          ...page('attempt').toJson(),
          'rawOutput': 'unprepared output',
        }),
        throwsFormatException,
      );
    },
  );

  test('retention evicts oldest pages by both page and character budget', () {
    final small = TaskFileReadObservation.retain([
      for (var i = 0; i < 17; i++) page('attempt-$i'),
    ]);
    expect(small, hasLength(16));
    expect(small.first.attemptId, 'attempt-1');
    final large = TaskFileReadObservation.retain([
      for (var i = 0; i < 5; i++) page('attempt-$i', length: 65536),
    ]);
    expect(large, hasLength(4));
    expect(large.first.attemptId, 'attempt-1');
    expect(large.last.attemptId, 'attempt-4');
    expect(() => large.clear(), throwsUnsupportedError);
  });

  test('persisted states reject oversized or duplicate page collections', () {
    for (final pages in [
      [page('same'), page('same')],
      [for (var i = 0; i < 17; i++) page('attempt-$i')],
      [for (var i = 0; i < 5; i++) page('attempt-$i', length: 65536)],
    ]) {
      expect(() => TaskExecutionState(fileReads: pages), throwsArgumentError);
      expect(
        () => TaskExecutionState.fromJson({
          ...TaskExecutionState().toJson(),
          'fileReads': pages.map((page) => page.toJson()).toList(),
        }),
        throwsArgumentError,
      );
    }
  });

  test(
    'persisted pages reject invalid source ranges and unbounded content',
    () {
      for (final change in <Map<String, Object?>>[
        {'offsetBytes': -1},
        {'nextOffsetBytes': 2},
        {'maxBytes': 65537},
        {'content': 'a' * 90001},
        {'encoding': 'unknown'},
      ]) {
        expect(
          () => TaskFileReadObservation.fromJson({
            ...page('attempt').toJson(),
            ...change,
          }),
          throwsArgumentError,
        );
      }
    },
  );
}
