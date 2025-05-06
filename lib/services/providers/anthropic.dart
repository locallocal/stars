import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class Anthropic extends Provider {
  static const String defaultApiModelsUrl =
      'https://api.anthropic.com/v1/models';
  static const String defaultApiChatUrl =
      'https://api.anthropic.com/v1/messages';
  Anthropic(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    switch (bot.model.toLowerCase()) {
      case 'claude-3-7-sonnet-latest':
      case 'claude-3-7-sonnet-20250219':
        return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
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
  Future<List<String>> listModels() async {
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
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final models =
        (data['data'] as List).map((model) => model['id'] as String).toList();
    models.sort();
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
              if (deepThinking)
                'thinking': {"type": "enabled", "budget_tokens": 16000},
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
        print(line);
        if (line.contains('error')) {
          throw Exception('Anthropic API Error: $line');
        }
        // 检查是否已取消
        if (isCancelled) break;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') return;

          try {
            final data = jsonDecode(jsonStr);
            if (data['type'] == 'content_block_delta') {
              final delta = data['delta'];
              if (delta['type'] == 'text_delta') {
                onResponse(delta['text']);
              } else if (delta['type'] == 'thinking_delta' && deepThinking) {
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
}
