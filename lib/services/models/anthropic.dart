import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class AnthropicChatModel extends ChatModel {
  AnthropicChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    // Anthropic目前没有公开的模型列表API，返回已知模型
    return [
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
      'claude-3-haiku-20240307',
    ];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/messages'
            : 'https://api.anthropic.com/v1/messages';

    // 转换消息格式为Anthropic格式
    final systemPrompt =
        messages
            .firstWhere(
              (m) => m.role == 'system',
              orElse: () => ChatMessage(role: 'system', content: ''),
            )
            .content;

    final anthropicMessages =
        messages
            .where((m) => m.role != 'system')
            .map(
              (m) => {
                'role': m.role == 'assistant' ? 'assistant' : 'user',
                'content': m.content,
              },
            )
            .toList();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': bot.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': anthropicMessages,
        'system': systemPrompt,
        'max_tokens': 2000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'];
    } else {
      throw Exception('请求失败: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  }) async {
    try {
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v1/messages'
              : 'https://api.anthropic.com/v1/messages';

      // 提取系统提示
      final systemPrompt =
          messages
              .firstWhere(
                (m) => m.role == 'system',
                orElse: () => ChatMessage(role: 'system', content: ''),
              )
              .content;

      // 过滤掉系统提示
      final anthropicMessages =
          messages
              .where((m) => m.role != 'system')
              .map(
                (m) => {
                  'role': m.role == 'assistant' ? 'assistant' : 'user',
                  'content': m.content,
                },
              )
              .toList();

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'x-api-key': bot.apiKey,
              'anthropic-version': '2023-06-01',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': anthropicMessages,
              'system': systemPrompt,
              'max_tokens': 2000,
              'temperature': 0.7,
              'stream': true,
            });

      final streamedResponse = await request.send();

      await streamedResponse.stream
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .forEach((line) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6);
              if (jsonStr == '[DONE]') return;

              try {
                final data = jsonDecode(jsonStr);
                if (data['type'] == 'content_block_delta') {
                  final delta = data['delta']['text'] ?? '';
                  onResponse(delta);
                }
              } catch (e) {
                // 忽略解析错误
              }
            }
          });

      if (onComplete != null) {
        onComplete();
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
    }
  }
}
