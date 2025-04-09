import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';

class VolcanoEngine extends Provider {
  static const String defaultApiChatUrl =
      'https://ark.cn-beijing.volces.com/api/v3/chat/completions';

  VolcanoEngine(super.bot);

  @override
  Future<List<String>> listModels() async {
    return [
      'doubao-1-5-vision-pro-32k-250115',
      'doubao-vision-lite-32k-241015',
      'doubao-vision-pro-32k-241028',
      'doubao-1-5-pro-32k-250115',
      'doubao-1-5-lite-32k-250115',
      'doubao-1-5-pro-256k-250115',
      'doubao-pro-256k-241115',
      'doubao-pro-32k-241215',
      'doubao-pro-32k-240828',
      'doubao-pro-32k-240615',
      'doubao-lite-32k-240828',
      'doubao-lite-128k-240828',
      'deepseek-r1-250120',
      'deepseek-v3-241226',
      'deepseek-r1-distill-qwen-7b-250120',
      'deepseek-r1-distill-qwen-32b-250120',
      'mistral-7b-instruct-v0.2',
      'chatglm3-130b-fc-v1.0',
      'moonshot-v1-128k',
      'moonshot-v1-32k',
      'moonshot-v1-8k',
    ];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    try {
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v3/chat/completions'
              : defaultApiChatUrl;

      final Map<String, dynamic> requestBody = {
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': false,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bot.apiKey}',
          'X-VolcEngine-Service': 'volc-llm',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // 检查火山引擎API的响应格式
        if (data['choices'] != null && data['choices'].length > 0) {
          final String content = data['choices'][0]['message']['content'];
          return content;
        } else {
          return 'Invalid Response Body: ${data['msg'] ?? 'Unknown Error'}';
        }
      } else {
        try {
          Map<String, dynamic> errorData = jsonDecode(response.body);
          String errorMessage =
              errorData['base_resp']?['status_message'] ?? 'Unkown Error';
          return '$errorMessage (${response.statusCode})';
        } catch (e) {
          return 'HTTP ${response.statusCode}';
        }
      }
    } catch (e) {
      return 'Send Message Failed: $e';
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v3/chat/completions'
              : defaultApiChatUrl;
      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
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
}
