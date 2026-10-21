import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/models/conversation_task.dart';

final class TurnRoutingRequest {
  TurnRoutingRequest({
    required this.bot,
    required this.userMessage,
    required this.language,
    this.cancellation,
    this.requiresBackgroundTask = false,
    required List<ChatMessage> messages,
    List<ConversationTask> activeTasks = const [],
  }) : messages = List.unmodifiable(messages),
       activeTasks = List.unmodifiable(activeTasks);
  final AgentCancellationToken? cancellation;
  final bool requiresBackgroundTask;
  final Bot bot;
  final Message userMessage;
  final String language;
  final List<ChatMessage> messages;
  final List<ConversationTask> activeTasks;
}

abstract interface class ConversationTurnRouter {
  /// One tool-free main reply call. Raw Provider JSON never crosses this boundary.
  Stream<TurnRoutingEvent> route(TurnRoutingRequest request);
}

abstract interface class ConversationTaskEnqueuer {
  /// A notification after commit. The durable queued row is the recovery source.
  Future<void> enqueue(String taskId);
}
