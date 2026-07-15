import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:stars/services/providers/providers.dart';
import 'package:stars/model/model.dart';

class SenseNova extends Provider {
  static const String defaultApiModelsUrl =
      'https://api.sensenova.cn/v1/llm/models';
  static const String defaultApiChatUrl =
      'https://api.sensenova.cn/v1/llm/chat-completions';

  SenseNova(super.bot);

  @override
  bool supportWebSearch() {
    switch (bot.model) {
      case 'DeepSeek-R1':
      case 'DeepSeek-V3':
      case 'DeepSeek-R1-Distill-Qwen-14B':
      case 'DeepSeek-R1-Distill-Qwen-32B':
      case 'SenseChat-Vision':
        return false;
    }
    return true;
  }

  @override
  bool supportDeepThinking() {
    switch (bot.model) {
      case 'DeepSeek-R1':
      case 'DeepSeek-V3':
      case 'DeepSeek-R1-Distill-Qwen-14B':
      case 'DeepSeek-R1-Distill-Qwen-32B':
        return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model) {
      case 'SenseChat-Vision':
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
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}llm/models'
            : defaultApiModelsUrl;

    try {
      final response = await http
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
        throw Exception('List models failed: ${response.statusCode}');
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
              ? '${bot.baseURL}llm/chat-completions'
              : defaultApiChatUrl;
      var requestBody = {
        'model': bot.model,
        'messages': processMessagesWithImages(messages),
        'stream': true,
      };
      if (webSearch) {
        requestBody['plugins'] = {
          "web_search": {"search_enable": true, "result_enable": true},
        };
      }
      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode(requestBody);

      final streamedResponse = await request.send();
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      await for (final line in stream) {
        if (isCancelled) break;
        if (line.startsWith('data:')) {
          final jsonStr = line.substring(5);
          if (jsonStr == '[DONE]') {
            // 当收到[DONE]标记时，确保调用onComplete
            if (!isCancelled && onComplete != null) {
              onComplete!();
            }
            return;
          }
          try {
            final data = jsonDecode(jsonStr);
            if (deepThinking &&
                data['data']['choices'][0].containsKey('reasoning_content')) {
              final reasoning =
                  data['data']['choices'][0]['reasoning_content'] ?? '';
              if (reasoning.isNotEmpty && onReasoningResponse != null) {
                onReasoningResponse!(reasoning);
              }
              continue;
            }

            final delta = data['data']['choices'][0]['delta'] ?? '';
            onResponse(delta);
          } catch (e) {
            // 忽略解析错误
          }
        } else if (line.isNotEmpty) {
          try {
            final data = jsonDecode(line);
            if (data['error'] != null && onError != null) {
              onError!(
                'Code: ${data['error']['code']}, Message: ${data['error']['message']}',
              );
            }
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
      cancelController?.close();
      cancelController = null;
    }
  }

  @override
  List<Map<String, dynamic>> processMessagesWithImages(
    List<ChatMessage> messages,
  ) {
    return messages.map((message) {
      // 处理带有图片的消息
      final List<Map<String, dynamic>> content = [];
      // 添加文本内容（如果有）
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
            content.add({'type': 'image_base64', 'image_base64': base64Image});
          }
        } catch (_) {
          // Skip unreadable optional images and continue the request.
        }
      }
      return {'role': message.role, 'content': content};
    }).toList();
  }
}
