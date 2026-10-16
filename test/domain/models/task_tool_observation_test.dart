import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/task_execution_state.dart';
import 'package:stars/domain/models/task_tool_observation.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_tool_observation_policy.dart';

void main() {
  test('nested tool data is isolated from input and consumer mutations', () {
    final input = {
      'entries': <Object?>[1, 2],
    };
    final item = TaskToolObservation(
      attemptId: 'attempt-1',
      tool: 'resolve',
      content: 'Sources',
      structuredContent: input,
      truncated: false,
      redacted: false,
    );
    input['entries']!.clear();
    ((item.structuredContent as Map)['entries'] as List).clear();
    expect(item.structuredContent, {
      'entries': [1, 2],
    });
    final state = TaskExecutionState(
      toolResults: [item],
      consecutiveDuplicateCalls: 2,
    );
    final restored = TaskExecutionState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>,
    );
    expect(restored.toJson(), state.toJson());
  });

  test(
    'legacy checkpoints initialize new observation and duplicate fields',
    () {
      final legacy =
          TaskExecutionState().toJson()..remove('consecutiveDuplicateCalls');
      final restored = TaskExecutionState.fromJson(legacy);
      expect(restored.toolResults, isEmpty);
      expect(restored.consecutiveDuplicateCalls, 0);
    },
  );

  test('oversized JSON is omitted and explicitly marked truncated', () {
    final item = prepareTaskToolObservation(
      attemptId: 'attempt-1',
      result: ToolResult(
        callId: 'call',
        name: 'resolve',
        content: 'Sources',
        structuredContent: {
          'data': 'x' * TaskToolObservation.maxResultCharacters,
        },
      ),
    );
    expect(item.structuredContent, isNull);
    expect(item.truncated, isTrue);
    expect(
      item.characters,
      lessThanOrEqualTo(TaskToolObservation.maxResultCharacters),
    );
  });

  test(
    'large installation batches retain the manifest across receipt eviction',
    () {
      final source = TaskToolObservation(
        attemptId: 'resolve-1',
        tool: 'resolve_skill_source',
        content: 'Sources',
        structuredContent: {
          'skills': ['first', 'last'],
        },
        truncated: false,
        redacted: false,
      );
      var results = [source];
      for (var i = 0; i < 205; i++) {
        results = TaskToolObservation.retain([
          ...results,
          TaskToolObservation(
            attemptId: 'install-$i',
            tool: 'install_skill',
            content: 'Installed',
            truncated: false,
            redacted: false,
          ),
        ]);
      }

      expect(results.first.attemptId, 'resolve-1');
      expect(results.last.attemptId, 'install-204');
      expect(results, hasLength(TaskToolObservation.maxRetainedResults));
    },
  );

  test(
    'retention evicts oldest observations within count and character bounds',
    () {
      TaskToolObservation item(int id, int length) => TaskToolObservation(
        attemptId: 'attempt-$id',
        tool: 'read',
        content: 'x' * length,
        truncated: false,
        redacted: false,
      );
      final countBounded = TaskToolObservation.retain([
        for (var i = 0; i < 70; i++) item(i, 1),
      ]);
      expect(countBounded, hasLength(TaskToolObservation.maxRetainedResults));
      expect(countBounded.first.attemptId, 'attempt-6');
      final sizeBounded = TaskToolObservation.retain([
        for (var i = 0; i < 10; i++) item(i, 100000),
      ]);
      expect(
        sizeBounded.fold(0, (sum, item) => sum + item.characters),
        lessThanOrEqualTo(TaskToolObservation.maxRetainedCharacters),
      );
      expect(sizeBounded.last.attemptId, 'attempt-9');
    },
  );
}
