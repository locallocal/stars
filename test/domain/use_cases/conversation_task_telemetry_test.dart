import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/conversation_task_telemetry.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';
import '../../support/task_terminal_harness.dart';

void main() {
  test(
    'export aggregates bounded numeric values and discards conversation identities',
    () {
      final telemetry = ConversationTaskTelemetry();
      final initial = telemetry.snapshot();
      for (var i = 0; i < 1000; i++) {
        telemetry.recordDispatch(
          const TurnDispatchMetrics(
            chatId: 'private-chat',
            turnId: 'private-turn',
            preparationCalls: 1,
            mainReplyCalls: 1,
            preflightUsage: ModelTokenUsage.empty,
            preparationDuration: Duration(milliseconds: 1),
            elapsed: Duration(milliseconds: 8),
            directFirstCharacterLatency: Duration(milliseconds: 2),
            directCompletionLatency: Duration(milliseconds: 8),
            acknowledgementCommitLatency: null,
            routingFallbacks: 0,
            acknowledgementFallbacks: 0,
          ),
        );
      }
      final snapshot = telemetry.snapshot();
      expect(snapshot.keys, initial.keys);
      expect(initial['foreground.dispatches'], 0);
      expect(snapshot['foreground.mainCalls'], 1000);
      expect(snapshot['foreground.directCompletionUs'], 8000000);
      expect(snapshot['foreground.acknowledgements'], 0);
      expect(jsonEncode(snapshot), isNot(contains('private')));
      expect(() => snapshot['injected'] = 1, throwsUnsupportedError);
    },
  );

  test(
    'failed terminal transaction does not count evidence and retry counts once',
    () async {
      final h = TaskTerminalHarness();
      await h.open();
      addTearDown(h.close);
      await h.observe();
      await h.candidate(unsupported: true);
      final finalizer = h.finalizer();
      await h.runner.db.failWrite('messages');
      await expectLater(finalizer('task-1'), throwsA(isA<Exception>()));
      expect(finalizer.metrics.committed, 0);
      expect(finalizer.metrics.factualClaims, 0);
      expect(finalizer.metrics.verifiedClaims, 0);
      expect(finalizer.metrics.suppressedClaims, 0);
      await h.runner.db.clearFailure();
      await finalizer('task-1');
      expect(finalizer.metrics.committed, 1);
      expect(finalizer.metrics.failed, 1);
      expect(finalizer.metrics.factualClaims, 2);
      expect(finalizer.metrics.verifiedClaims, 1);
      expect(finalizer.metrics.suppressedClaims, 1);
      await finalizer('task-1');
      expect(finalizer.metrics.committed, 1);
      expect(finalizer.metrics.factualClaims, 2);
    },
  );
}
