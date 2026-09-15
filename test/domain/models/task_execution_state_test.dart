import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/task_execution_state.dart';
import 'package:stars/domain/models/tool.dart';

void main() {
  TaskPendingCall pending() => TaskPendingCall(
    call: ToolCallRequest(
      callId: 'p',
      name: 'read',
      arguments: {
        'scope': {
          'pages': [1, 2],
        },
      },
    ),
    idempotencyKey: 'key',
    toolVersion: '1',
  );

  test('continuation arguments are deeply immutable and portable', () {
    final original = pending();
    final state = TaskExecutionState(calls: [original]);
    final restored = TaskExecutionState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>,
    );
    expect(restored.toJson(), state.toJson());
    final nested = restored.calls.single.call.arguments['scope']! as Map;
    expect(() => (nested['pages']! as List).add(3), throwsUnsupportedError);
    expect(() => nested['secret'] = 'changed', throwsUnsupportedError);
  });

  for (final field in [
    'reasoning',
    'api_key',
    'rawOutput',
    'providerSession',
  ]) {
    test('rejects unexpected continuation field $field', () {
      expect(
        () => TaskExecutionState.fromJson({
          ...TaskExecutionState().toJson(),
          field: 'sensitive',
        }),
        throwsFormatException,
      );
      expect(
        () => TaskPendingCall.fromJson({
          ...pending().toJson(),
          field: 'sensitive',
        }),
        throwsFormatException,
      );
    });
  }

  test('reconciliation requires a durable attempt identity', () {
    expect(
      () => pending().withAttempt(null, reconcile: true),
      throwsArgumentError,
    );
  });
}
