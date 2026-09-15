import 'dart:async';
import 'dart:convert';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_progress.dart';

final class TaskProgressPolisherFactory {
  const TaskProgressPolisherFactory({
    required this.bots,
    required this.providers,
  });
  final BotRepository bots;
  final AiProviderRepository providers;
  TaskProgressPolisher forBot(String botId) => (request, cancellation) async {
    final bot =
        (await bots.getBots(
          forceRefresh: true,
        )).where((b) => b.id == botId).firstOrNull;
    cancellation.throwIfCancelled();
    if (bot == null) throw StateError('task_bot_unavailable');
    final provider =
        providers.create(bot)
          ..setWebSearch(false)
          ..setDeepThinking(false);
    final session = provider.openModelSession(
      ModelRequest(
        messages: [
          ChatMessage(
            role: 'system',
            content:
                'Return JSON with exactly taskId, summaryRevision, content. Copy the IDs from summary. '
                'Select content verbatim from allowedNarrations. No tools or additional facts. '
                '${request.repair ? "The previous response was invalid; use the supplied grammar." : ""}',
          ),
          ChatMessage(
            role: 'user',
            content: jsonEncode({
              'summary': request.summary,
              'language': request.language,
              'allowedNarrations': request.allowedNarrations,
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
        done.completeError(StateError('task_progress_narration_unavailable'));
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
              if (text.length > 32000) fail();
            case ModelTurnCompleted():
              if (!{
                '',
                'stop',
                'end_turn',
                'completed',
                'stop_sequence',
              }.contains(event.stopReason)) {
                fail();
              }
              completed = true;
            case ReasoningDelta() || UsageReported():
              break;
            default:
              fail();
          }
        },
        onError: (Object _) => fail(),
        onDone: () {
          if (done.isCompleted) return;
          if (completed) {
            done.complete(text.toString());
          } else {
            fail();
          }
        },
      );
      return await done.future;
    } finally {
      unawaited(subscription?.cancel());
      session.close();
    }
  };
}
