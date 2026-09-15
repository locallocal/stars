import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/provider_service.dart';
import 'package:stars/data/services/ai/provider_transport.dart';
import 'package:stars/data/services/ai/skill_tool_sessions.dart';
import 'package:stars/domain/models/models.dart';

class Anthropic extends Provider {
  static const String defaultApiModelsUrl =
      'https://api.anthropic.com/v1/models';
  static const String defaultApiChatUrl =
      'https://api.anthropic.com/v1/messages';
  Anthropic(super.bot, {http.Client? skillToolClient})
    : _skillToolClient = skillToolClient;

  final http.Client? _skillToolClient;

  @override
  ForegroundRoutingTransport get foregroundRoutingTransport =>
      ForegroundRoutingTransport.modelSession;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
    supportsParallelToolCalls: true,
  );

  @override
  AgentModelSession openModelSession(ModelRequest request) {
    final formatted = formatMessages(request.messages);
    final rawMessages = formatted['messages'];
    final messages =
        rawMessages is List
            ? rawMessages
                .whereType<Map>()
                .map((message) => Map<String, dynamic>.from(message))
                .toList(growable: false)
            : <Map<String, dynamic>>[];
    final client = _skillToolClient ?? http.Client();
    return AnthropicAgentModelSession(
      bot: bot,
      request: request,
      requestTimeout:
          request.options.requestTimeout ?? defaultProviderGenerationTimeout,
      system: formatted['system']?.toString() ?? '',
      formattedMessages: messages,
      uri: Uri.parse(_getMessageUrl()),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': bot.apiKey,
        'anthropic-version': '2023-06-01',
      },
      maxTokens: _getMaxTokens(),
      client: client,
      closeClient: _skillToolClient == null,
      decodeResponse: decodeProviderResponse,
    );
  }

  @override
  SkillToolSession openSkillToolSession(SkillToolSessionRequest request) {
    final formatted = formatMessages(request.messages);
    final rawMessages = formatted['messages'];
    final messages =
        rawMessages is List
            ? rawMessages
                .whereType<Map>()
                .map((message) => Map<String, dynamic>.from(message))
                .toList(growable: false)
            : <Map<String, dynamic>>[];
    final client = _skillToolClient ?? http.Client();
    return AnthropicSkillToolSession(
      bot: bot,
      request: request,
      system: formatted['system']?.toString() ?? '',
      formattedMessages: messages,
      uri: Uri.parse(_getMessageUrl()),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': bot.apiKey,
        'anthropic-version': '2023-06-01',
      },
      maxTokens: _getMaxTokens(),
      client: client,
      closeClient: _skillToolClient == null,
      decodeResponse: decodeProviderResponse,
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
    switch (bot.model.toLowerCase()) {
      case 'claude-3-7-sonnet-latest':
      case 'claude-3-7-sonnet-20250219':
        return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    final documented = builtInModelInfo();
    if (documented != null) return documented.inputModalities;
    switch (bot.model.toLowerCase()) {
      case 'claude-3-7-sonnet-latest':
      case 'claude-3-7-sonnet-20250219':
      case 'claude-3-5-haiku-latest':
      case 'claude-3-5-haiku-20241022':
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
    // 添加limit参数，设置为1000
    final uri = Uri.parse(url).replace(queryParameters: {'limit': '1000'});

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': bot.apiKey,
        'anthropic-version': '2023-06-01',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        'List Models Failed: ${response.statusCode} - ${response.body}',
      );
    }
    final data = decodeProviderResponse(utf8.decode(response.bodyBytes));
    final models = providerModelInfos(data['data']);
    return models;
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
    try {
      // 重置取消状态
      resetCancelState();
      final url = _getMessageUrl();
      // 获取格式化的消息
      final formattedMessages = formatMessages(messages);

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'x-api-key': bot.apiKey,
              'anthropic-version': '2023-06-01',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': formattedMessages['messages'],
              'system': formattedMessages['system'],
              'stream': true,
              'max_tokens': _getMaxTokens(),
              if (_thinkingConfig() case final thinking?) 'thinking': thinking,
              if (webSearch)
                'tools': [
                  {
                    'type': 'web_search_20250305',
                    'name': 'web_search',
                    'max_uses': 5,
                  },
                ],
            });

      final streamedResponse = await request.send();
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      // 监听取消事件
      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      await for (final line in stream) {
        if (line.contains('error')) {
          throw Exception('Anthropic API Error: $line');
        }
        // 检查是否已取消
        if (isCancelled) break;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') return;

          try {
            final data = decodeProviderResponse(jsonStr);
            if (data['type'] == 'content_block_delta') {
              final delta = data['delta'];
              if (delta['type'] == 'text_delta') {
                onResponse(delta['text']);
              } else if (delta['type'] == 'thinking_delta' &&
                  deepThinking &&
                  onReasoningResponse != null) {
                onReasoningResponse!(delta['thinking']);
              }
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      }

      // 确保在流处理完成后调用onComplete
      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('Request canceled by User');
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

  // 格式化消息为Anthropic API所需格式
  Map<String, dynamic> formatMessages(List<ChatMessage> messages) {
    // 提取系统提示
    final systemPrompt =
        messages
            .firstWhere(
              (m) => m.role == 'system',
              orElse: () => ChatMessage(role: 'system', content: ''),
            )
            .content;

    // 过滤掉系统提示，转换其他消息
    final anthropicMessages =
        messages.where((m) => m.role != 'system').map((m) {
          if (m.role == 'assistant') {
            return {'role': 'assistant', 'content': m.content};
          } else {
            // 处理用户消息，可能包含图片
            final List<Map<String, dynamic>> content = [];

            // 如果有文本内容，添加文本部分
            if (m.content.isNotEmpty) {
              content.add({'type': 'text', 'text': m.content});
            }

            // 如果有图片，添加图片部分
            if (m.images.isNotEmpty) {
              for (final image in m.images) {
                final file = File(image);
                if (file.existsSync()) {
                  final bytes = file.readAsBytesSync();
                  final base64Image = base64Encode(bytes);
                  final mediaType = getImageMediaType(bytes);
                  content.add({
                    'type': 'image',
                    'source': {
                      'type': 'base64',
                      'media_type': mediaType,
                      'data': base64Image,
                    },
                  });
                }
              }
            }
            return {'role': 'user', 'content': content};
          }
        }).toList();

    return {'system': systemPrompt, 'messages': anthropicMessages};
  }

  String _getMessageUrl() {
    return bot.baseURL.isNotEmpty
        ? '${bot.baseURL}messages'
        : defaultApiChatUrl;
  }

  int _getMaxTokens() {
    final documented = builtInModelInfo()?.maxOutputTokens;
    if (documented != null) return documented;
    switch (bot.model.toLowerCase()) {
      case 'claude-3-7-sonnet-latest':
      case 'claude-3-7-sonnet-20250219':
        return 64000;
      case 'claude-3-5-haiku-latest':
      case 'claude-3-5-haiku-20241022':
      case 'claude-3-5-sonnet-latest':
      case 'claude-3-5-sonnet-20241022':
      case 'claude-3-5-sonnet-20240620':
        return 8192;
      case 'claude-3-opus-latest':
      case 'claude-3-opus-20240229':
      case 'claude-3-haiku-20240307':
        return 4096;
    }
    return 4096;
  }

  Map<String, Object>? _thinkingConfig() {
    if (!deepThinking) return null;
    switch (bot.model.toLowerCase()) {
      case 'claude-fable-5':
      case 'claude-opus-5':
      case 'claude-sonnet-5':
        return {'type': 'adaptive'};
      default:
        return {'type': 'enabled', 'budget_tokens': 16000};
    }
  }
}
