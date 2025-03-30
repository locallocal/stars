import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class OpenAIChatModel extends ChatModel {
  static const String defaultApiModelsUrl = 'https://api.openai.com/v1/models';
  static const String defaultApiChatUrl =
      'https://api.openai.com/v1/chat/completions';
  OpenAIChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/models'
            : defaultApiModelsUrl;

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer ${bot.apiKey}'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final models =
            (data['data'] as List)
                .map((model) => model['id'] as String)
                .toList();
        return models;
      } else {
        throw Exception('List Models Failed: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('List Models Timeout, Retry later.');
    } finally {
      client.close();
    }
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/chat/completions'
            : defaultApiChatUrl;

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': _processMessagesWithImages(messages),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Send Message Failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      // 重置取消状态
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v1/chat/completions'
              : defaultApiChatUrl;

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': _processMessagesWithImages(messages),
              'stream': true,
            });

      final streamedResponse = await request.send();
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      await for (final line in stream) {
        // 检查是否已取消
        if (isCancelled) break;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') {
            // 当收到[DONE]标记时，确保调用onComplete
            if (!isCancelled && onComplete != null) {
              onComplete!();
            }
            return;
          }

          try {
            final data = jsonDecode(jsonStr);
            final delta = data['choices'][0]['delta']['content'] ?? '';
            onResponse(delta);
          } catch (e) {
            // 忽略解析错误
          }
        }
      }

      if (!isCancelled && onComplete != null) {
        onComplete!();
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
}

// 处理带有图片的消息
List<Map<String, dynamic>> _processMessagesWithImages(
  List<ChatMessage> messages,
) {
  return messages.map((message) {
    if (message.images.isEmpty) {
      return message.toJson();
    }

    final List<Map<String, dynamic>> content = [];
    if (message.content.isNotEmpty) {
      content.add({'type': 'text', 'text': message.content});
    }

    // 添加图片内容
    for (final imagePath in message.images) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          final base64Image = base64Encode(bytes);

          content.add({
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          });
        }
      } catch (e) {
        print('Process image ${imagePath} failed: $e');
      }
    }

    return {'role': message.role, 'content': content};
  }).toList();
}
