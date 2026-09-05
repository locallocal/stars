part of 'skill_tool_sessions.dart';

final class _OpenAiStreamedToolCallBuilder {
  String id = '';
  String type = '';
  final StringBuffer name = StringBuffer();
  final StringBuffer arguments = StringBuffer();

  void append(Map<String, Object?> rawCall) {
    final idDelta = rawCall['id']?.toString() ?? '';
    if (idDelta.isNotEmpty) id = idDelta;
    final typeDelta = rawCall['type']?.toString() ?? '';
    if (typeDelta.isNotEmpty) type = typeDelta;

    final function = _objectMap(rawCall['function']);
    name.write(function['name']?.toString() ?? '');
    arguments.write(function['arguments']?.toString() ?? '');
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.isEmpty ? 'function' : type,
    'function': {
      'name': name.toString(),
      'arguments': arguments.isEmpty ? '{}' : arguments.toString(),
    },
  };
}

final class OpenAiResponsesAgentModelSession implements AgentModelSession {
  OpenAiResponsesAgentModelSession({
    required Bot bot,
    required ModelRequest request,
    required List<Map<String, dynamic>> formattedInput,
    required Uri uri,
    required Map<String, String> headers,
    required http.Client client,
    required bool closeClient,
    required ProviderResponseDecoder decodeResponse,
    String? reasoningEffort,
    Duration requestTimeout = defaultProviderGenerationTimeout,
  }) : _bot = bot,
       _request = request,
       _toolNames = _ProviderToolNameCodec(request.tools),
       _input =
           formattedInput
               .map((item) => Map<String, Object?>.from(item))
               .toList(),
       _uri = uri,
       _headers = headers,
       _client = client,
       _closeClient = closeClient,
       _decodeResponse = decodeResponse,
       _reasoningEffort = reasoningEffort,
       _requestTimeout = requestTimeout;

  final Bot _bot;
  final ModelRequest _request;
  final _ProviderToolNameCodec _toolNames;
  final List<Map<String, Object?>> _input;
  final Uri _uri;
  final Map<String, String> _headers;
  final http.Client _client;
  final bool _closeClient;
  final ProviderResponseDecoder _decodeResponse;
  final String? _reasoningEffort;
  final Duration _requestTimeout;
  final DateTime Function() _now = DateTime.now;
  bool _started = false;
  bool _closed = false;

  @override
  Stream<ModelEvent> start() {
    if (_started) throw StateError('Agent model session already started.');
    _started = true;
    return _send();
  }

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) {
    if (!_started) {
      throw StateError('Agent model session has not started.');
    }
    _appendToolResults(results);
    return _send();
  }

  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) {
    if (!_started) {
      throw StateError('Agent model session has not started.');
    }
    _input.add({
      'role': 'user',
      'content': [
        {'type': 'input_text', 'text': feedback},
      ],
    });
    return _send();
  }

  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request, {
    List<ToolResult> pendingToolResults = const [],
  }) {
    if (!_started) {
      throw StateError('Agent model session has not started.');
    }
    _appendToolResults(pendingToolResults, includePayload: false);
    _input.add({
      'role': 'user',
      'content': [
        {'type': 'input_text', 'text': _groundedAnswerSynthesisPrompt(request)},
      ],
    });
    return _send(groundedRequest: request);
  }

  void _appendToolResults(
    List<ToolResult> results, {
    bool includePayload = true,
  }) {
    for (final result in results) {
      _input.add({
        'type': 'function_call_output',
        'call_id': result.callId,
        'output': encodeToolResultForModel(
          result,
          includePayload: includePayload,
        ),
      });
    }
  }

  Stream<ModelEvent> _send({
    GroundedAnswerSynthesisRequest? groundedRequest,
  }) async* {
    final tools = <Map<String, Object?>>[];
    if (groundedRequest == null) {
      tools.addAll(_openAiResponsesTools(_request.tools, _toolNames));
      if (_request.options.webSearch) tools.add({'type': 'web_search'});
    }
    late final http.Response response;
    try {
      response = await sendProviderRequest(
        send:
            () => _client.post(
              _uri,
              headers: _headers,
              body: jsonEncode({
                'model': _bot.model,
                'input': _input,
                if (tools.isNotEmpty) ...{
                  'tools': tools,
                  'tool_choice': 'auto',
                  'parallel_tool_calls':
                      _request.options.allowParallelToolCalls,
                },
                if (groundedRequest == null && _request.options.webSearch)
                  'include': const ['web_search_call.action.sources'],
                if (_request.options.deepThinking && _reasoningEffort != null)
                  'reasoning': {'effort': _reasoningEffort, 'summary': 'auto'},
              }),
            ),
        endpointKind: ProviderEndpointKind.responses,
        timeout: _requestTimeout,
      );
    } on ProviderFailure catch (failure) {
      yield ModelTurnFailed.fromProvider(failure);
      return;
    }

    final root = _objectMap(_decodeResponse(utf8.decode(response.bodyBytes)));
    final output = _objectList(root['output']);
    if (output.isEmpty) {
      yield const ModelTurnFailed(
        error: 'Model response has no output items.',
        code: 'invalid_provider_response',
      );
      return;
    }
    _input.addAll(output.map(_objectMap));
    if (groundedRequest != null) {
      final groundedText = StringBuffer();
      var invalidOutput = false;
      for (final rawItem in output) {
        final item = _objectMap(rawItem);
        switch (item['type']) {
          case 'reasoning':
            for (final rawSummary in _objectList(item['summary'])) {
              final summary = _objectMap(rawSummary);
              final text = summary['text']?.toString() ?? '';
              if (text.isNotEmpty) yield ReasoningDelta(text);
            }
          case 'message':
            for (final rawContent in _objectList(item['content'])) {
              final content = _objectMap(rawContent);
              if (content['type'] != 'output_text') {
                invalidOutput = true;
                continue;
              }
              groundedText.write(content['text']?.toString() ?? '');
            }
          default:
            invalidOutput = true;
        }
      }
      if (invalidOutput || groundedText.isEmpty) {
        yield const ModelTurnFailed(
          error: 'invalid_grounded_provider_response',
          code: 'invalid_grounded_provider_response',
        );
        return;
      }
      final event = _parseGroundedAnswerOutput(
        groundedText.toString(),
        groundedRequest,
      );
      yield event;
      if (event is ModelTurnFailed) return;
      final usage = _openAiResponsesUsage(root, _bot.model);
      if (usage.hasData) yield UsageReported(usage);
      yield ModelTurnCompleted(stopReason: root['status']?.toString() ?? '');
      return;
    }
    final providerToolResults = _normalizeOpenAiNativeToolResults(
      root: root,
      output: output,
      now: _now,
    );

    var hasToolCalls = false;
    for (final rawItem in output) {
      final item = _objectMap(rawItem);
      switch (item['type']) {
        case 'reasoning':
          for (final rawSummary in _objectList(item['summary'])) {
            final summary = _objectMap(rawSummary);
            final text = summary['text']?.toString() ?? '';
            if (text.isNotEmpty) yield ReasoningDelta(text);
          }
        case 'message':
          for (final rawContent in _objectList(item['content'])) {
            final content = _objectMap(rawContent);
            if (content['type'] != 'output_text') continue;
            final text = content['text']?.toString() ?? '';
            if (text.isNotEmpty) yield TextDelta(text);
          }
        case 'function_call':
          hasToolCalls = true;
          final callId = item['call_id']?.toString() ?? '';
          final name = _toolNames.canonical(item['name']?.toString() ?? '');
          final rawArguments = item['arguments'];
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
        case 'web_search_call':
          final normalized = providerToolResults[item['id']?.toString() ?? ''];
          if (normalized != null) yield normalized;
      }
    }

    final usage = _openAiResponsesUsage(root, _bot.model);
    if (usage.hasData) yield UsageReported(usage);
    yield ModelTurnCompleted(
      stopReason:
          hasToolCalls ? 'tool_calls' : root['status']?.toString() ?? '',
    );
  }

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

final class AnthropicAgentModelSession implements AgentModelSession {
  AnthropicAgentModelSession({
    required Bot bot,
    required ModelRequest request,
    required String system,
    required List<Map<String, dynamic>> formattedMessages,
    required Uri uri,
    required Map<String, String> headers,
    required int maxTokens,
    required http.Client client,
    required bool closeClient,
    required ProviderResponseDecoder decodeResponse,
    Duration requestTimeout = defaultProviderGenerationTimeout,
  }) : _bot = bot,
       _request = request,
       _toolNames = _ProviderToolNameCodec(request.tools),
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
       _decodeResponse = decodeResponse,
       _requestTimeout = requestTimeout;

  final Bot _bot;
  final ModelRequest _request;
  final _ProviderToolNameCodec _toolNames;
  final String _system;
  final List<Map<String, Object?>> _messages;
  final Uri _uri;
  final Map<String, String> _headers;
  final int _maxTokens;
  final http.Client _client;
  final bool _closeClient;
  final ProviderResponseDecoder _decodeResponse;
  final Duration _requestTimeout;
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
    _appendToolResults(results);
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
    GroundedAnswerSynthesisRequest request, {
    List<ToolResult> pendingToolResults = const [],
  }) {
    if (!_started) {
      throw StateError('Agent model session has not started.');
    }
    _appendToolResults(pendingToolResults, includePayload: false);
    _messages.add({
      'role': 'user',
      'content': _groundedAnswerSynthesisPrompt(request),
    });
    return _send(groundedRequest: request);
  }

  void _appendToolResults(
    List<ToolResult> results, {
    bool includePayload = true,
  }) {
    if (results.isEmpty) return;
    _messages.add({
      'role': 'user',
      'content': [
        for (final result in results)
          {
            'type': 'tool_result',
            'tool_use_id': result.callId,
            'content': encodeToolResultForModel(
              result,
              includePayload: includePayload,
            ),
            'is_error': result.isError,
          },
      ],
    });
  }

  Stream<ModelEvent> _send({
    GroundedAnswerSynthesisRequest? groundedRequest,
  }) async* {
    late final http.Response response;
    try {
      response = await sendProviderRequest(
        send:
            () => _client.post(
              _uri,
              headers: _headers,
              body: jsonEncode({
                'model': _bot.model,
                'messages': _messages,
                'system': _system,
                if (groundedRequest == null && _request.tools.isNotEmpty) ...{
                  'tools': _anthropicTools(_request.tools, _toolNames),
                  'tool_choice': {'type': 'auto'},
                },
                'max_tokens': _maxTokens,
                if (_request.options.deepThinking)
                  'thinking': {'type': 'enabled', 'budget_tokens': 16000},
                'stream': false,
              }),
            ),
        endpointKind: ProviderEndpointKind.messages,
        timeout: _requestTimeout,
      );
    } on ProviderFailure catch (failure) {
      yield ModelTurnFailed.fromProvider(failure);
      return;
    }
    final root = _objectMap(_decodeResponse(utf8.decode(response.bodyBytes)));
    final content = _objectList(root['content']);
    _messages.add({'role': 'assistant', 'content': content});
    if (groundedRequest != null) {
      final groundedText = StringBuffer();
      var invalidOutput = false;
      for (final rawBlock in content) {
        final block = _objectMap(rawBlock);
        switch (block['type']) {
          case 'text':
            groundedText.write(block['text']?.toString() ?? '');
          case 'thinking':
            final thinking = block['thinking']?.toString() ?? '';
            if (thinking.isNotEmpty) yield ReasoningDelta(thinking);
          default:
            invalidOutput = true;
        }
      }
      if (invalidOutput || groundedText.isEmpty) {
        yield const ModelTurnFailed(
          error: 'invalid_grounded_provider_response',
          code: 'invalid_grounded_provider_response',
        );
        return;
      }
      final event = _parseGroundedAnswerOutput(
        groundedText.toString(),
        groundedRequest,
      );
      yield event;
      if (event is ModelTurnFailed) return;
      final usage = _anthropicUsage(root, _bot.model);
      if (usage.hasData) yield UsageReported(usage);
      yield ModelTurnCompleted(
        stopReason: root['stop_reason']?.toString() ?? '',
      );
      return;
    }
    for (final rawBlock in content) {
      final block = _objectMap(rawBlock);
      switch (block['type']) {
        case 'text':
          final text = block['text']?.toString() ?? '';
          if (text.isNotEmpty) yield TextDelta(text);
        case 'thinking':
          final thinking = block['thinking']?.toString() ?? '';
          if (thinking.isNotEmpty) yield ReasoningDelta(thinking);
        case 'tool_use':
          final callId = block['id']?.toString() ?? '';
          final name = _toolNames.canonical(block['name']?.toString() ?? '');
          yield ToolCallStarted(callId: callId, name: name);
          yield ToolCallRequested(
            callId: callId,
            name: name,
            arguments: _objectMap(block['input']),
          );
      }
    }
    final usage = _anthropicUsage(root, _bot.model);
    if (usage.hasData) yield UsageReported(usage);
    yield ModelTurnCompleted(stopReason: root['stop_reason']?.toString() ?? '');
  }

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

List<Map<String, Object?>> _openAiSkillTools(List<SkillCatalogEntry> catalog) {
  final names = catalog.map((entry) => entry.name).toList(growable: false);
  return [
    {
      'type': 'function',
      'function': {
        'name': 'activate_skill',
        'description':
            'Load one available Skill when it is relevant to the user request.',
        'strict': true,
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'enum': names},
          },
          'required': ['name'],
          'additionalProperties': false,
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'read_skill_resource',
        'description':
            'Read a UTF-8 text file under references/ for an activated Skill.',
        'strict': true,
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'enum': names},
            'path': {
              'type': 'string',
              'description': 'A relative path beginning with references/.',
            },
          },
          'required': ['name', 'path'],
          'additionalProperties': false,
        },
      },
    },
  ];
}

List<Map<String, Object?>> _openAiResponsesSkillTools(
  List<SkillCatalogEntry> catalog,
) {
  return [
    for (final tool in _openAiSkillTools(catalog))
      {'type': 'function', ..._objectMap(tool['function'])},
  ];
}

List<Map<String, Object?>> _openAiTools(
  List<ToolDefinition> definitions,
  _ProviderToolNameCodec names,
) {
  return [
    for (final definition in definitions)
      {
        'type': 'function',
        'function': {
          'name': names.wire(definition.name),
          'description': definition.description,
          'parameters': definition.inputSchema,
        },
      },
  ];
}

List<Map<String, Object?>> _openAiResponsesTools(
  List<ToolDefinition> definitions,
  _ProviderToolNameCodec names,
) {
  return [
    for (final definition in definitions)
      {
        'type': 'function',
        'name': names.wire(definition.name),
        'description': definition.description,
        'parameters': definition.inputSchema,
      },
  ];
}

List<Map<String, Object?>> _anthropicTools(
  List<ToolDefinition> definitions,
  _ProviderToolNameCodec names,
) {
  return [
    for (final definition in definitions)
      {
        'name': names.wire(definition.name),
        'description': definition.description,
        'input_schema': definition.inputSchema,
      },
  ];
}
