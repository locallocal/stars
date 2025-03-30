import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class AnthropicChatModel extends ChatModel {
  AnthropicChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/models'
            : 'https://api.anthropic.com/v1/models';
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
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['data'].map<String>((model) => model['id']).toList();
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url = getMessageUrl();

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
        'max_tokens': getMaxTokens(),
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['content'][0]['text'];
    } else {
      throw Exception(
        'Request Failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      // 重置取消状态
      resetCancelState();

      final url = getMessageUrl();

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
              'max_tokens': getMaxTokens(),
              'temperature': 0.7,
              'stream': true,
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
        // 检查是否已取消
        if (isCancelled) break;

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
      }

      // 确保在流处理完成后调用onComplete
      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('Request Cancelled by User');
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

  String getMessageUrl() {
    return bot.baseURL.isNotEmpty
        ? '${bot.baseURL}/v1/messages'
        : 'https://api.anthropic.com/v1/messages';
  }

  int getMaxTokens() {
    if (bot.model.contains("3-7-sonnet") ||
        bot.model.contains("3-5-sonnet") ||
        bot.model.contains("3-5-haiku")) {
      return 8192;
    }
    return 4096;
  }
}
