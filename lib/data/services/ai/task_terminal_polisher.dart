import 'dart:async';
import 'dart:convert';

import 'package:stars/data/services/ai/task_model_session_factory.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_terminal.dart';

/// Resolves credentials at call time. The Provider sees only the safe summary
/// grammar, never acceptance history, raw errors, tool arguments or reasoning.
final class TaskTerminalPolisherFactory {
  const TaskTerminalPolisherFactory({
    required this.bots,
    required this.providers,
  });
  final BotRepository bots;
  final AiProviderRepository providers;

  TaskTerminalPolisher forTask(ConversationTask task) => (
    request,
    cancellation,
  ) async {
    final bot =
        (await bots.getBots(
          forceRefresh: true,
        )).where((bot) => bot.id == task.botId).firstOrNull;
    cancellation.throwIfCancelled();
    if (bot == null) throw StateError('task_bot_unavailable');
    if (bot.apiKey.trim().isEmpty && bot.apiType != 'ollama') {
      throw StateError('task_missing_credentials');
    }
    final session = TaskProviderSessionFactory(
      providers: providers,
      bot: bot,
    ).open(
      task.acceptance,
      ModelRequest(
        messages: [
          ChatMessage(
            role: 'system',
            content:
                'Select one of the supplied safe terminal narrations. Return it verbatim as text. '
                'Do not add facts, tools, completion promises or rollback claims.',
          ),
          ChatMessage(
            role: 'user',
            content: jsonEncode({
              'language': request.language,
              'status': request.summary.status.name,
              'reason_code': request.summary.reasonCode,
              'side_effect_status': request.summary.sideEffectStatus.name,
              'can_retry': request.summary.canRetry,
              'cancellation_source': request.summary.cancellationSource?.name,
              'allowed_narrations': request.allowedNarrations,
            }),
          ),
        ],
        tools: const [],
        options: const ModelGenerationOptions(
          requestTimeout: Duration(seconds: 2),
        ),
      ),
    );
    final done = Completer<String>();
    final text = StringBuffer();
    var completed = false;
    StreamSubscription<ModelEvent>? subscription;
    void fail() {
      if (!done.isCompleted) {
        done.completeError(StateError('task_narration_unavailable'));
      }
    }

    try {
      unawaited(
        cancellation.whenCancelled.then((_) {
          if (!done.isCompleted) {
            fail();
            unawaited(session.cancel().catchError((Object _) {}));
          }
        }),
      );
      subscription = session.start().listen(
        (event) {
          if (done.isCompleted) return;
          if (completed) {
            fail();
            return;
          }
          switch (event) {
            case TextDelta():
              text.write(event.text);
              if (text.length > 16000) fail();
            case ModelTurnCompleted():
              completed = true;
            case ReasoningDelta():
            case UsageReported():
              break;
            default:
              fail();
          }
        },
        onError: (Object _) => fail(),
        onDone: () {
          if (done.isCompleted) return;
          if (!completed) {
            fail();
            return;
          }
          done.complete(text.toString());
        },
      );
      return await done.future;
    } finally {
      unawaited(subscription?.cancel());
      session.close();
    }
  };
}
