import 'dart:async';

import 'package:stars/data/services/ai/turn_routing_protocol.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/conversation_turn_router.dart';

/// Uses only the initial transport turn. No coordinator, continuations, tool
/// definitions, native search, or second model call for format repair.
final class ProviderConversationTurnRouter implements ConversationTurnRouter {
  const ProviderConversationTurnRouter({
    required AiProviderRepository providers,
    this.timeout = const Duration(minutes: 2),
  }) : _providers = providers;
  final AiProviderRepository _providers;
  final Duration timeout;

  @override
  Stream<TurnRoutingEvent> route(TurnRoutingRequest request) async* {
    AiProvider? provider;
    AgentModelSession? session;
    StreamIterator<ModelEvent>? iterator;
    var completed = false;
    var succeeded = false;
    try {
      request.cancellation?.throwIfCancelled();
      provider = _providers
          .forConversation(request.userMessage.chatId)
          .create(request.bot);
      final mode = provider.foregroundRoutingTransport;
      if (mode == ForegroundRoutingTransport.unavailable) {
        yield const TurnRoutingFailed(TurnRoutingFailure.unsupportedProvider);
        return;
      }
      provider.setWebSearch(false);
      provider.setDeepThinking(false);
      // Omit private reasoning, even if old history contains it.
      final messages = [
        for (final message in request.messages)
          ChatMessage(
            role: message.role,
            content: message.content,
            images: message.images,
            files: message.files,
          ),
        ChatMessage(
          role: 'system',
          content: TurnRoutingProtocol.instruction(request),
        ),
      ];
      final protocol = TurnRoutingProtocol(
        allowedToolNames: request.allowedToolNames,
      );
      final Stream<ModelEvent> events;
      if (mode == ForegroundRoutingTransport.modelSession) {
        session = provider.openModelSession(
          ModelRequest(
            messages: messages,
            options: const ModelGenerationOptions(foregroundRouting: true),
          ),
        );
        yield TurnRoutingCallStarted(
          providerSupportsAgentLoop: provider.capabilities.supportsAgentLoop,
        );
        events = session.start();
      } else {
        yield const TurnRoutingCallStarted();
        events = _buffered(provider, messages);
      }
      final elapsed = Stopwatch()..start();
      final deferred = <TurnRoutingEvent>[];
      iterator = StreamIterator(events);
      while (true) {
        final remaining = timeout - elapsed.elapsed;
        if (remaining <= Duration.zero) throw TimeoutException('routing');
        final cancelled = request.cancellation?.whenCancelled;
        final next = iterator.moveNext().timeout(remaining);
        if (!await (cancelled == null
            ? next
            : Future.any([
              next,
              cancelled.then<bool>(
                (_) => throw StateError('foreground_cancelled'),
              ),
            ]))) {
          break;
        }
        switch (iterator.current) {
          case TextDelta(:final text):
            if (completed) throw const FormatException();
            for (final event in protocol.add(text)) {
              if (mode == ForegroundRoutingTransport.bufferedText) {
                deferred.add(event);
              } else {
                yield event;
              }
            }
          case UsageReported(:final usage):
            yield TurnRoutingUsage(usage);
          case ReasoningDelta():
            break;
          case ModelTurnCompleted(:final stopReason):
            if (completed ||
                !{
                  '',
                  'stop',
                  'end_turn',
                  'completed',
                  'stop_sequence',
                }.contains(stopReason)) {
              yield const TurnRoutingFailed(
                TurnRoutingFailure.incompleteResponse,
              );
              return;
            }
            completed = true;
          case ModelTurnFailed(:final code):
            yield TurnRoutingFailed(
              code == 'cancelled' || code == 'generation_cancelled'
                  ? TurnRoutingFailure.cancelled
                  : TurnRoutingFailure.providerFailed,
            );
            return;
          case ToolCallStarted() ||
              ToolCallArgumentsDelta() ||
              ToolCallRequested() ||
              ProviderNativeToolResult():
            yield const TurnRoutingFailed(TurnRoutingFailure.forbiddenTool);
            return;
          case GroundedAnswerProduced():
            throw const FormatException();
        }
      }
      if (!completed) {
        yield const TurnRoutingFailed(TurnRoutingFailure.incompleteResponse);
        return;
      }
      final finalEvents = protocol.finish();
      succeeded = true;
      for (final event in [...deferred, ...finalEvents]) {
        yield event;
      }
    } on FormatException {
      yield const TurnRoutingFailed(TurnRoutingFailure.invalidProtocol);
    } on TimeoutException {
      yield const TurnRoutingFailed(TurnRoutingFailure.timedOut);
    } on Object {
      // Provider errors may contain request URLs, keys, or raw response bodies.
      yield TurnRoutingFailed(
        request.cancellation?.isCancelled == true
            ? TurnRoutingFailure.cancelled
            : TurnRoutingFailure.providerFailed,
      );
    } finally {
      if (!succeeded && provider != null) {
        unawaited(
          provider.cancelRequest().then<void>((_) {}, onError: (Object _) {}),
        );
      }
      if (!succeeded && session != null) {
        unawaited(session.cancel().catchError((Object _) {}));
      }
      session?.close();
      if (iterator != null) {
        unawaited(iterator.cancel().catchError((Object _) {}));
      }
    }
  }

  Stream<ModelEvent> _buffered(
    AiProvider provider,
    List<ChatMessage> messages,
  ) async* {
    final text = StringBuffer();
    ModelTokenUsage usage = ModelTokenUsage.empty;
    ProviderTerminalType? terminal;
    var forbiddenTool = false;
    var tooLarge = false;
    provider.setCallbacks(
      onResponse: (chunk) {
        if (text.length + chunk.length >
            TurnRoutingProtocol.maxResponseLength) {
          tooLarge = true;
        } else if (!tooLarge) {
          text.write(chunk);
        }
      },
      onTokenUsage: (value) => usage = usage.merge(value),
      onToolCall: (_) => forbiddenTool = true,
      onCommandExecution: (_) => forbiddenTool = true,
      onTerminal: (value) => terminal = value.type,
    );
    await provider.generateText(messages);
    if (tooLarge) throw const FormatException();
    if (forbiddenTool) {
      yield const ToolCallStarted(callId: '', name: 'forbidden');
      return;
    }
    if (usage.hasData) yield UsageReported(usage);
    if (terminal != ProviderTerminalType.completed || provider.isCancelled) {
      yield ModelTurnFailed(
        error: 'routing failed',
        code:
            provider.isCancelled || terminal == ProviderTerminalType.cancelled
                ? 'cancelled'
                : 'provider_failed',
      );
      return;
    }
    yield TextDelta(text.toString());
    yield const ModelTurnCompleted();
  }
}
