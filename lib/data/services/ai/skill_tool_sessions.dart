import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/provider_transport.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';

part 'skill_tool_agent_sessions.dart';
part 'grounded_answer_protocol.dart';
part 'skill_tool_name_codec.dart';
part 'openai_native_tool_evidence.dart';

typedef ProviderResponseDecoder = Object? Function(String source);

final class OpenAiSkillToolSession implements SkillToolSession {
  OpenAiSkillToolSession({
    required Bot bot,
    required SkillToolSessionRequest request,
    required List<Map<String, dynamic>> formattedMessages,
    required Uri uri,
    required Map<String, String> headers,
    required http.Client client,
    required bool closeClient,
    required ProviderResponseDecoder decodeResponse,
    Duration requestTimeout = const Duration(minutes: 2),
    Map<String, Object?> additionalBody = const {},
  }) : _bot = bot,
       _request = request,
       _messages =
           formattedMessages
               .map((message) => Map<String, Object?>.from(message))
               .toList(),
       _uri = uri,
       _headers = headers,
       _client = client,
       _closeClient = closeClient,
       _decodeResponse = decodeResponse,
       _requestTimeout = requestTimeout,
       _additionalBody = Map<String, Object?>.unmodifiable(additionalBody);

  final Bot _bot;
  final SkillToolSessionRequest _request;
  final List<Map<String, Object?>> _messages;
  final Uri _uri;
  final Map<String, String> _headers;
  final http.Client _client;
  final bool _closeClient;
  final ProviderResponseDecoder _decodeResponse;
  final Duration _requestTimeout;
  final Map<String, Object?> _additionalBody;
  bool _started = false;

  @override
  Future<SkillToolTurn> start() {
    if (_started) throw StateError('Skill tool session already started.');
    _started = true;
    return _send();
  }

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> results) async {
    if (!_started) throw StateError('Skill tool session has not started.');
    for (final result in results) {
      _messages.add({
        'role': 'tool',
        'tool_call_id': result.callId,
        'content': result.content,
      });
    }
    return _send();
  }

  Future<SkillToolTurn> _send() async {
    final response = await sendProviderRequest(
      send:
          () => _client.post(
            _uri,
            headers: _headers,
            body: jsonEncode({
              'model': _bot.model,
              'messages': _messages,
              'tools': _openAiSkillTools(_request.catalog),
              'tool_choice': 'auto',
              'parallel_tool_calls': false,
              ..._additionalBody,
              'stream': false,
            }),
          ),
      endpointKind: ProviderEndpointKind.chatCompletions,
      timeout: _requestTimeout,
    );
    final decoded = _decodeResponse(utf8.decode(response.bodyBytes));
    final root = _objectMap(decoded);
    final choices = _objectList(root['choices']);
    if (choices.isEmpty) {
      throw const FormatException('Skill activation response has no choices.');
    }
    final message = _objectMap(_objectMap(choices.first)['message']);
    final rawCalls = _objectList(message['tool_calls']);
    final reasoningContent = message['reasoning_content'];
    final reasoning = message['reasoning'];
    _messages.add({
      'role': 'assistant',
      'content': message['content']?.toString() ?? '',
      if (reasoningContent != null) 'reasoning_content': reasoningContent,
      if (reasoning != null) 'reasoning': reasoning,
      if (rawCalls.isNotEmpty) 'tool_calls': rawCalls,
    });
    final calls = <SkillToolCall>[];
    for (final rawCall in rawCalls) {
      final call = _objectMap(rawCall);
      final function = _objectMap(call['function']);
      calls.add(
        SkillToolCall(
          callId: call['id']?.toString() ?? '',
          name: function['name']?.toString() ?? '',
          arguments: _decodeArguments(function['arguments']),
        ),
      );
    }
    return SkillToolTurn(
      calls: calls,
      isComplete: calls.isEmpty,
      tokenUsage: _openAiUsage(root, _bot.model),
    );
  }

  @override
  void close() {
    if (_closeClient) _client.close();
  }
}

/// Non-streaming Skill activation over the Responses API.
///
/// Responses tool calls and tool outputs are separate input items correlated
/// by `call_id`; the complete model output is retained between turns so
/// reasoning items remain available to reasoning models.
final class OpenAiResponsesSkillToolSession implements SkillToolSession {
  OpenAiResponsesSkillToolSession({
    required Bot bot,
    required SkillToolSessionRequest request,
    required List<Map<String, dynamic>> formattedInput,
    required Uri uri,
    required Map<String, String> headers,
    required http.Client client,
    required bool closeClient,
    required ProviderResponseDecoder decodeResponse,
    Duration requestTimeout = const Duration(seconds: 60),
  }) : _bot = bot,
       _request = request,
       _input =
           formattedInput
               .map((item) => Map<String, Object?>.from(item))
               .toList(),
       _uri = uri,
       _headers = headers,
       _client = client,
       _closeClient = closeClient,
       _decodeResponse = decodeResponse,
       _requestTimeout = requestTimeout;

  final Bot _bot;
  final SkillToolSessionRequest _request;
  final List<Map<String, Object?>> _input;
  final Uri _uri;
  final Map<String, String> _headers;
  final http.Client _client;
  final bool _closeClient;
  final ProviderResponseDecoder _decodeResponse;
  final Duration _requestTimeout;
  bool _started = false;

  @override
  Future<SkillToolTurn> start() {
    if (_started) throw StateError('Skill tool session already started.');
    _started = true;
    return _send();
  }

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> results) async {
    if (!_started) throw StateError('Skill tool session has not started.');
    for (final result in results) {
      _input.add({
        'type': 'function_call_output',
        'call_id': result.callId,
        'output': result.content,
      });
    }
    return _send();
  }

  Future<SkillToolTurn> _send() async {
    final response = await sendProviderRequest(
      send:
          () => _client.post(
            _uri,
            headers: _headers,
            body: jsonEncode({
              'model': _bot.model,
              'input': _input,
              'tools': _openAiResponsesSkillTools(_request.catalog),
              'tool_choice': 'auto',
              'parallel_tool_calls': false,
            }),
          ),
      endpointKind: ProviderEndpointKind.responses,
      timeout: _requestTimeout,
    );
    final root = _objectMap(_decodeResponse(utf8.decode(response.bodyBytes)));
    final output = _objectList(root['output']);
    _input.addAll(output.map(_objectMap));

    final calls = <SkillToolCall>[];
    for (final rawItem in output) {
      final item = _objectMap(rawItem);
      if (item['type'] != 'function_call') continue;
      calls.add(
        SkillToolCall(
          callId: item['call_id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          arguments: _decodeArguments(item['arguments']),
        ),
      );
    }
    return SkillToolTurn(
      calls: calls,
      isComplete: calls.isEmpty,
      tokenUsage: _openAiResponsesUsage(root, _bot.model),
    );
  }

  @override
  void close() {
    if (_closeClient) _client.close();
  }
}

final class AnthropicSkillToolSession implements SkillToolSession {
  AnthropicSkillToolSession({
    required Bot bot,
    required SkillToolSessionRequest request,
    required String system,
    required List<Map<String, dynamic>> formattedMessages,
    required Uri uri,
    required Map<String, String> headers,
    required int maxTokens,
    required http.Client client,
    required bool closeClient,
    required ProviderResponseDecoder decodeResponse,
  }) : _bot = bot,
       _request = request,
       _system = system,
       _messages =
           formattedMessages
               .map((message) => Map<String, Object?>.from(message))
               .toList(),
       _uri = uri,
       _headers = headers,
       _maxTokens = maxTokens,
       _client = client,
       _closeClient = closeClient,
       _decodeResponse = decodeResponse;

  final Bot _bot;
  final SkillToolSessionRequest _request;
  final String _system;
  final List<Map<String, Object?>> _messages;
  final Uri _uri;
  final Map<String, String> _headers;
  final int _maxTokens;
  final http.Client _client;
  final bool _closeClient;
  final ProviderResponseDecoder _decodeResponse;
  bool _started = false;

  @override
  Future<SkillToolTurn> start() {
    if (_started) throw StateError('Skill tool session already started.');
    _started = true;
    return _send();
  }

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> results) async {
    if (!_started) throw StateError('Skill tool session has not started.');
    _messages.add({
      'role': 'user',
      'content': [
        for (final result in results)
          {
            'type': 'tool_result',
            'tool_use_id': result.callId,
            'content': result.content,
            'is_error': result.isError,
          },
      ],
    });
    return _send();
  }

  Future<SkillToolTurn> _send() async {
    final response = await sendProviderRequest(
      send:
          () => _client.post(
            _uri,
            headers: _headers,
            body: jsonEncode({
              'model': _bot.model,
              'messages': _messages,
              'system': _system,
              'tools': _anthropicSkillTools(_request.catalog),
              'tool_choice': {'type': 'auto'},
              'max_tokens': _maxTokens < 1024 ? _maxTokens : 1024,
              'stream': false,
            }),
          ),
      endpointKind: ProviderEndpointKind.messages,
      timeout: const Duration(seconds: 30),
    );
    final decoded = _decodeResponse(utf8.decode(response.bodyBytes));
    final root = _objectMap(decoded);
    final content = _objectList(root['content']);
    _messages.add({'role': 'assistant', 'content': content});
    final calls = <SkillToolCall>[];
    for (final rawBlock in content) {
      final block = _objectMap(rawBlock);
      if (block['type'] != 'tool_use') continue;
      calls.add(
        SkillToolCall(
          callId: block['id']?.toString() ?? '',
          name: block['name']?.toString() ?? '',
          arguments: _objectMap(block['input']),
        ),
      );
    }
    return SkillToolTurn(
      calls: calls,
      isComplete: calls.isEmpty,
      tokenUsage: _anthropicUsage(root, _bot.model),
    );
  }

  @override
  void close() {
    if (_closeClient) _client.close();
  }
}

final class OpenAiAgentModelSession implements AgentModelSession {
  OpenAiAgentModelSession({
    required Bot bot,
    required ModelRequest request,
    required List<Map<String, dynamic>> formattedMessages,
    required Uri uri,
    required Map<String, String> headers,
    required http.Client client,
    required bool closeClient,
    required ProviderResponseDecoder decodeResponse,
    String? reasoningEffort,
    bool streamResponses = false,
    Map<String, Object?> additionalBody = const {},
  }) : _bot = bot,
       _request = request,
       _toolNames = _ProviderToolNameCodec(request.tools),
       _messages =
           formattedMessages
               .map((message) => Map<String, Object?>.from(message))
               .toList(),
       _uri = uri,
       _headers = headers,
       _client = client,
       _closeClient = closeClient,
       _decodeResponse = decodeResponse,
       _reasoningEffort = reasoningEffort,
       _streamResponses = streamResponses,
       _additionalBody = Map<String, Object?>.unmodifiable(additionalBody);

  final Bot _bot;
  final ModelRequest _request;
  final _ProviderToolNameCodec _toolNames;
  final List<Map<String, Object?>> _messages;
  final Uri _uri;
  final Map<String, String> _headers;
  final http.Client _client;
  final bool _closeClient;
  final ProviderResponseDecoder _decodeResponse;
  final String? _reasoningEffort;
  final bool _streamResponses;
  final Map<String, Object?> _additionalBody;
  bool _started = false;
  bool _closed = false;

  @override
  Stream<ModelEvent> start() {
    if (_started) {
      throw StateError('Agent model session already started.');
    }
    _started = true;
    return _send();
  }

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) {
    if (!_started) {
      throw StateError('Agent model session has not started.');
    }
    for (final result in results) {
      _messages.add({
        'role': 'tool',
        'tool_call_id': result.callId,
        'content': encodeToolResultForModel(result),
      });
    }
    return _send();
  }

  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) {
    if (!_started) {
      throw StateError('Agent model session has not started.');
    }
    _messages.add({'role': 'user', 'content': feedback});
    return _send();
  }

  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request,
  ) {
    if (!_started) {
      throw StateError('Agent model session has not started.');
    }
    _messages.add({
      'role': 'user',
      'content': _groundedAnswerSynthesisPrompt(request),
    });
    return _send(groundedRequest: request);
  }

  Stream<ModelEvent> _send({
    GroundedAnswerSynthesisRequest? groundedRequest,
  }) async* {
    if (groundedRequest == null &&
        _streamResponses &&
        _request.options.stream) {
      yield* _sendStreaming();
      return;
    }

    late final http.Response response;
    try {
      response = await sendProviderRequest(
        send:
            () => _client.post(
              _uri,
              headers: _headers,
              body: jsonEncode(
                _requestBody(
                  stream: false,
                  includeTools: groundedRequest == null,
                ),
              ),
            ),
        endpointKind: ProviderEndpointKind.chatCompletions,
        timeout: const Duration(seconds: 60),
      );
    } on ProviderFailure catch (failure) {
      yield ModelTurnFailed.fromProvider(failure);
      return;
    }
    final root = _objectMap(_decodeResponse(utf8.decode(response.bodyBytes)));
    final choices = _objectList(root['choices']);
    if (choices.isEmpty) {
      yield const ModelTurnFailed(
        error: 'Model response has no choices.',
        code: 'invalid_provider_response',
      );
      return;
    }
    final choice = _objectMap(choices.first);
    final message = _objectMap(choice['message']);
    final rawCalls = _objectList(message['tool_calls']);
    _messages.add({
      'role': 'assistant',
      'content': message['content']?.toString() ?? '',
      if (rawCalls.isNotEmpty) 'tool_calls': rawCalls,
    });

    final reasoning =
        message['reasoning_content']?.toString() ??
        message['reasoning']?.toString() ??
        '';
    if (reasoning.isNotEmpty) yield ReasoningDelta(reasoning);
    final content = message['content']?.toString() ?? '';
    if (groundedRequest != null) {
      if (rawCalls.isNotEmpty || content.isEmpty) {
        yield const ModelTurnFailed(
          error: 'invalid_grounded_provider_response',
          code: 'invalid_grounded_provider_response',
        );
        return;
      }
      final event = _parseGroundedAnswerOutput(content, groundedRequest);
      yield event;
      if (event is ModelTurnFailed) return;
      final usage = _openAiUsage(root, _bot.model);
      if (usage.hasData) yield UsageReported(usage);
      yield ModelTurnCompleted(
        stopReason: choice['finish_reason']?.toString() ?? '',
      );
      return;
    }
    if (content.isNotEmpty) yield TextDelta(content);
    for (final rawCall in rawCalls) {
      final call = _objectMap(rawCall);
      final function = _objectMap(call['function']);
      final callId = call['id']?.toString() ?? '';
      final name = _toolNames.canonical(function['name']?.toString() ?? '');
      final rawArguments = function['arguments'];
      yield ToolCallStarted(callId: callId, name: name);
      if (rawArguments is String && rawArguments.isNotEmpty) {
        yield ToolCallArgumentsDelta(
          callId: callId,
          argumentsDelta: rawArguments,
        );
      }
      yield ToolCallRequested(
        callId: callId,
        name: name,
        arguments: _decodeArguments(rawArguments),
      );
    }
    final usage = _openAiUsage(root, _bot.model);
    if (usage.hasData) yield UsageReported(usage);
    yield ModelTurnCompleted(
      stopReason: choice['finish_reason']?.toString() ?? '',
    );
  }

  Stream<ModelEvent> _sendStreaming() async* {
    late final http.StreamedResponse response;
    try {
      response = await sendProviderStreamRequest(
        send: () {
          final request =
              http.Request('POST', _uri)
                ..headers.addAll(_headers)
                ..body = jsonEncode(_requestBody(stream: true));
          return _client.send(request);
        },
        endpointKind: ProviderEndpointKind.chatCompletions,
        timeout: const Duration(seconds: 60),
      );
    } on ProviderFailure catch (failure) {
      yield ModelTurnFailed.fromProvider(failure);
      return;
    }

    final content = StringBuffer();
    final reasoning = StringBuffer();
    final toolCalls = <int, _OpenAiStreamedToolCallBuilder>{};
    var usage = ModelTokenUsage.empty;
    var finishReason = '';
    var receivedDone = false;

    await for (final source in _sseData(response.stream)) {
      if (source == '[DONE]') {
        receivedDone = true;
        break;
      }

      final root = _objectMap(_decodeResponse(source));
      if (root['error'] != null) {
        yield ModelTurnFailed.fromProvider(
          ProviderFailure.invalidResponse(
            endpointKind: ProviderEndpointKind.chatCompletions,
            code: 'provider_stream_error',
          ),
        );
        return;
      }
      usage = usage.merge(_openAiUsage(root, _bot.model));

      final choices = _objectList(root['choices']);
      if (choices.isEmpty) continue;
      final choice = _objectMap(choices.first);
      usage = usage.merge(_openAiUsage(choice, _bot.model));
      final nextFinishReason = choice['finish_reason']?.toString() ?? '';
      if (nextFinishReason.isNotEmpty) finishReason = nextFinishReason;

      final delta = _objectMap(choice['delta']);
      final reasoningDelta = _streamedText(
        delta['reasoning_content'] ?? delta['reasoning'],
      );
      if (reasoningDelta.isNotEmpty) {
        reasoning.write(reasoningDelta);
        yield ReasoningDelta(reasoningDelta);
      }
      final contentDelta = _streamedText(delta['content']);
      if (contentDelta.isNotEmpty) {
        content.write(contentDelta);
        yield TextDelta(contentDelta);
      }

      final rawCalls = _objectList(delta['tool_calls']);
      for (var position = 0; position < rawCalls.length; position++) {
        final rawCall = _objectMap(rawCalls[position]);
        final index = _integer(rawCall['index'], fallback: position);
        toolCalls
            .putIfAbsent(index, _OpenAiStreamedToolCallBuilder.new)
            .append(rawCall);
      }
    }

    if (!receivedDone) {
      yield const ModelTurnFailed(
        error: 'Model response stream ended before data: [DONE].',
        code: 'incomplete_provider_stream',
      );
      return;
    }

    final orderedCalls =
        toolCalls.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key));
    final rawCalls = [for (final entry in orderedCalls) entry.value.toJson()];
    _messages.add({
      'role': 'assistant',
      'content': content.toString(),
      if (reasoning.isNotEmpty) 'reasoning_content': reasoning.toString(),
      if (rawCalls.isNotEmpty) 'tool_calls': rawCalls,
    });

    for (final entry in orderedCalls) {
      final call = entry.value;
      final name = _toolNames.canonical(call.name.toString());
      yield ToolCallStarted(callId: call.id, name: name);
      final arguments = call.arguments.toString();
      if (arguments.isNotEmpty) {
        yield ToolCallArgumentsDelta(
          callId: call.id,
          argumentsDelta: arguments,
        );
      }
      yield ToolCallRequested(
        callId: call.id,
        name: name,
        arguments: _decodeArguments(arguments),
      );
    }
    if (usage.hasData) yield UsageReported(usage);
    yield ModelTurnCompleted(stopReason: finishReason);
  }

  Map<String, Object?> _requestBody({
    required bool stream,
    bool includeTools = true,
  }) => {
    'model': _bot.model,
    'messages': _messages,
    if (includeTools && _request.tools.isNotEmpty) ...{
      'tools': _openAiTools(_request.tools, _toolNames),
      'tool_choice': 'auto',
      'parallel_tool_calls': _request.options.allowParallelToolCalls,
    },
    if (_request.options.deepThinking && _reasoningEffort != null)
      'reasoning_effort': _reasoningEffort,
    ..._additionalBody,
    'stream': stream,
    if (stream) 'stream_options': const {'include_usage': true},
  };

  @override
  Future<void> cancel() async {
    if (_closed) return;
    _closed = true;
    _client.close();
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    if (_closeClient) _client.close();
  }
}
