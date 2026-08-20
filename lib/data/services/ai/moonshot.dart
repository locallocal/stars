import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/provider_service.dart';
import 'package:stars/data/services/ai/skill_tool_sessions.dart';
import 'package:stars/domain/models/models.dart';

class Moonshot extends Provider {
  static const String defaultApiModelsUrl = 'https://api.moonshot.cn/v1/models';
  static const String defaultApiChatUrl =
      'https://api.moonshot.cn/v1/chat/completions';
  static const int _maxWebSearchRounds = 8;
  static const String _webSearchToolName = r'$web_search';
  Moonshot(super.bot, {http.Client? client}) : _client = client;

  final http.Client? _client;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  AiModelInfo providerModelInfo(Map<String, dynamic> model, {String? modelId}) {
    return super.providerModelInfo({
      ...model,
      'supports_mcp': true,
      'supports_skills': true,
      'supports_automatic_skill_activation': true,
    }, modelId: modelId);
  }

  @override
  List<Map<String, dynamic>> processMessagesWithImages(
    List<ChatMessage> messages,
  ) {
    final formatted = super.processMessagesWithImages(messages);
    if (!bot.model.toLowerCase().startsWith('kimi-k3')) return formatted;

    for (var index = 0; index < messages.length; index++) {
      final message = messages[index];
      if (message.role == 'assistant' && message.reasoning.isNotEmpty) {
        formatted[index]['reasoning_content'] = message.reasoning;
      }
    }
    return formatted;
  }

  @override
  bool supportMcp() {
    return (bot.configuredSupportsMcp ?? true) &&
        capabilities.supportsAgentLoop;
  }

  @override
  AgentModelSession openModelSession(ModelRequest request) {
    final client = _client ?? http.Client();
    return OpenAiAgentModelSession(
      bot: bot,
      request: request,
      formattedMessages: processMessagesWithImages(request.messages),
      uri: _chatCompletionsUri,
      headers: _headers,
      client: client,
      closeClient: _client == null,
      decodeResponse: decodeProviderResponse,
      streamResponses: true,
      additionalBody: _reasoningConfiguration(
        enabled: request.options.deepThinking,
      ),
    );
  }

  @override
  SkillToolSession openSkillToolSession(SkillToolSessionRequest request) {
    final client = _client ?? http.Client();
    return OpenAiSkillToolSession(
      bot: bot,
      request: request,
      formattedMessages: processMessagesWithImages(request.messages),
      uri: _chatCompletionsUri,
      headers: _headers,
      client: client,
      closeClient: _client == null,
      decodeResponse: decodeProviderResponse,
      additionalBody: _reasoningConfiguration(enabled: false),
    );
  }

  @override
  bool supportWebSearch() {
    return builtInModelInfo()?.supportsWebSearch ?? false;
  }

  @override
  bool supportDeepThinking() {
    final documented = builtInModelInfo()?.supportsDeepThinking;
    if (documented != null) return documented;
    return bot.model.toLowerCase().contains('thinking');
  }

  @override
  List<InputModality> getInputModalites() {
    final documented = builtInModelInfo();
    if (documented != null) return documented.inputModalities;
    if (bot.model.toLowerCase().contains('vision')) {
      return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    return [OutputModality.text];
  }

  @override
  Future<List<AiModelInfo>> fetchModels() async {
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}models' : defaultApiModelsUrl;

    try {
      final response = await (_client?.get(
                Uri.parse(url),
                headers: {'Authorization': 'Bearer ${bot.apiKey}'},
              ) ??
              http.get(
                Uri.parse(url),
                headers: {'Authorization': 'Bearer ${bot.apiKey}'},
              ))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = decodeProviderResponse(utf8.decode(response.bodyBytes));
        return providerModelInfos(data['data']);
      } else {
        throw Exception(
          'List models failed: ${response.statusCode}- ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('List models Timeout, retry later.');
    } catch (e) {
      throw Exception('List models failed: $e');
    }
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
    try {
      resetCancelState();
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}chat/completions'
              : defaultApiChatUrl;
      final requestMessages = List<Map<String, dynamic>>.from(
        processMessagesWithImages(messages),
      );
      final useWebSearch = webSearch && supportWebSearch();

      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      for (var round = 0; round < _maxWebSearchRounds; round++) {
        final result = await _streamCompletionRound(
          url: url,
          messages: requestMessages,
          useWebSearch: useWebSearch,
        );
        if (isCancelled) break;

        if (!useWebSearch || result.toolCalls.isEmpty) {
          onComplete?.call();
          return;
        }
        if (result.finishReason != 'tool_calls') {
          throw StateError(
            'Moonshot returned web search calls without finish_reason=tool_calls.',
          );
        }

        requestMessages.add(result.assistantMessage());
        for (final toolCall in result.toolCalls) {
          requestMessages.add({
            'role': 'tool',
            'tool_call_id': toolCall.id,
            'name': toolCall.name,
            'content':
                toolCall.name == _webSearchToolName
                    ? toolCall.arguments
                    : jsonEncode({
                      'error': 'Unsupported Moonshot tool: ${toolCall.name}',
                    }),
          });
        }
      }

      if (!isCancelled) {
        throw StateError(
          'Moonshot web search exceeded $_maxWebSearchRounds rounds.',
        );
      } else if (isCancelled && onError != null) {
        onError!('Request cancelled');
      }
    } catch (e) {
      if (!isCancelled && onError != null) {
        onError!(e.toString());
      }
    } finally {
      // 清理资源
      cancelController?.close();
      cancelController = null;
    }
  }

  Future<_MoonshotCompletionRound> _streamCompletionRound({
    required String url,
    required List<Map<String, dynamic>> messages,
    required bool useWebSearch,
  }) async {
    final request =
        http.Request('POST', Uri.parse(url))
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${bot.apiKey}',
          })
          ..body = jsonEncode({
            'model': bot.model,
            'messages': messages,
            'response_format': {'type': 'text'},
            'stream': true,
            if (useWebSearch)
              'tools': [
                {
                  'type': 'builtin_function',
                  'function': {'name': _webSearchToolName},
                },
              ],
            ..._reasoningConfiguration(),
          });

    final streamedResponse = await (_client?.send(request) ?? request.send());
    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final body = await streamedResponse.stream.bytesToString();
      throw Exception(
        'Send message failed: ${streamedResponse.statusCode} - $body',
      );
    }

    final content = StringBuffer();
    final reasoningContent = StringBuffer();
    final toolCalls = <int, _MoonshotToolCallBuilder>{};
    String finishReason = '';
    final stream = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      if (isCancelled) break;
      if (!line.startsWith('data: ')) continue;

      final jsonSource = line.substring(6).trim();
      if (jsonSource.isEmpty || jsonSource == '[DONE]') continue;

      final data = decodeProviderResponse(jsonSource);
      if (data['error'] case final Map error) {
        throw Exception(
          'Send message failed: (${error['code']}, ${error['type']}) '
          '${error['message']}',
        );
      }
      final choices = data['choices'];
      if (choices is! List || choices.isEmpty || choices.first is! Map) {
        continue;
      }
      final choice = choices.first as Map;
      final nextFinishReason = choice['finish_reason']?.toString() ?? '';
      if (nextFinishReason.isNotEmpty) finishReason = nextFinishReason;
      final delta = choice['delta'];
      if (delta is! Map) continue;

      final reasoningDelta = delta['reasoning_content']?.toString() ?? '';
      if (reasoningDelta.isNotEmpty) {
        reasoningContent.write(reasoningDelta);
        if (deepThinking) onReasoningResponse?.call(reasoningDelta);
      }

      final contentDelta = delta['content']?.toString() ?? '';
      if (contentDelta.isNotEmpty) {
        content.write(contentDelta);
        onResponse(contentDelta);
      }

      final deltaToolCalls = delta['tool_calls'];
      if (deltaToolCalls is! List) continue;
      for (var position = 0; position < deltaToolCalls.length; position++) {
        final rawCall = deltaToolCalls[position];
        if (rawCall is! Map) continue;
        final index = (rawCall['index'] as num?)?.toInt() ?? position;
        toolCalls
            .putIfAbsent(index, _MoonshotToolCallBuilder.new)
            .append(rawCall);
      }
    }

    return _MoonshotCompletionRound(
      content: content.toString(),
      reasoningContent: reasoningContent.toString(),
      finishReason: finishReason,
      toolCalls: [
        for (final entry
            in toolCalls.entries.toList()
              ..sort((left, right) => left.key.compareTo(right.key)))
          entry.value.build(),
      ],
    );
  }

  Map<String, Object> _reasoningConfiguration({bool? enabled}) {
    final thinkingEnabled = enabled ?? deepThinking;
    return switch (bot.model.toLowerCase()) {
      'kimi-k3' => {'reasoning_effort': thinkingEnabled ? 'max' : 'low'},
      'kimi-k2.6' || 'kimi-k2.5' => {
        'thinking': {'type': thinkingEnabled ? 'enabled' : 'disabled'},
      },
      _ => const {},
    };
  }

  Uri get _chatCompletionsUri => Uri.parse(
    bot.baseURL.isNotEmpty
        ? '${bot.baseURL}chat/completions'
        : defaultApiChatUrl,
  );

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${bot.apiKey}',
  };
}

final class _MoonshotCompletionRound {
  const _MoonshotCompletionRound({
    required this.content,
    required this.reasoningContent,
    required this.finishReason,
    required this.toolCalls,
  });

  final String content;
  final String reasoningContent;
  final String finishReason;
  final List<_MoonshotToolCall> toolCalls;

  Map<String, dynamic> assistantMessage() => {
    'role': 'assistant',
    'content': content.isEmpty ? null : content,
    if (reasoningContent.isNotEmpty) 'reasoning_content': reasoningContent,
    'tool_calls': [for (final toolCall in toolCalls) toolCall.toJson()],
  };
}

final class _MoonshotToolCall {
  const _MoonshotToolCall({
    required this.id,
    required this.type,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String type;
  final String name;
  final String arguments;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'function': {'name': name, 'arguments': arguments},
  };
}

final class _MoonshotToolCallBuilder {
  String id = '';
  String type = '';
  final name = StringBuffer();
  final arguments = StringBuffer();

  void append(Map rawCall) {
    final idDelta = rawCall['id']?.toString() ?? '';
    if (idDelta.isNotEmpty) id = idDelta;
    final typeDelta = rawCall['type']?.toString() ?? '';
    if (typeDelta.isNotEmpty) type = typeDelta;

    final function = rawCall['function'];
    if (function is! Map) return;
    name.write(function['name']?.toString() ?? '');
    arguments.write(function['arguments']?.toString() ?? '');
  }

  _MoonshotToolCall build() => _MoonshotToolCall(
    id: id,
    type: type.isEmpty ? 'function' : type,
    name: name.toString(),
    arguments: arguments.isEmpty ? '{}' : arguments.toString(),
  );
}
