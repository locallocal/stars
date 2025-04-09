import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';

class Tencent extends Provider {
  static const String defaultApiChatUrl =
      'https://api.hunyuan.cloud.tencent.com/v1/chat/completions';

  Tencent(super.bot);

  @override
  Future<List<String>> listModels() async {
    // 腾讯混元目前支持的模型列表
    return [
      'hunyuan-t1-latest',
      'hunyuan-t1-20250321',
      'hunyuan-turbos-latest',
      'hunyuan-turbos-20250313',
      'hunyuan-turbos-20250226',
      'hunyuan-turbo-latest',
      'hunyuan-turbo',
      'hunyuan-turbo-20241223',
      'hunyuan-large',
      'hunyuan-large-longcontext',
      'hunyuan-standard-256K',
      'hunyuan-standard',
      'hunyuan-lite',
      'hunyuan-standard-vision',
      'hunyuan-lite-vision',
      'hunyuan-turbo-vision',
      'hunyuan-vision',
    ];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    try {
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v1/chat/completions'
              : defaultApiChatUrl;

      // 构建请求体 - 腾讯混元API特定格式
      final Map<String, dynamic> requestBody = {
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': 0.7,
        'stream': false,
      };

      // 发送请求
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${bot.apiKey}',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody),
        encoding: Encoding.getByName('utf-8'), // 确保请求体使用UTF-8编码
      );

      if (response.statusCode == 200) {
        // 确保使用UTF-8解码响应内容
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(decodedBody);

        // 腾讯混元API的响应格式
        if (data['choices'] != null && data['choices'].length > 0) {
          final String content = data['choices'][0]['message']['content'];
          // 再次确保内容是有效的UTF-8字符串
          return content;
        } else {
          return 'Invalid Response Body: ${data['msg'] ?? 'Unknown Error'}';
        }
      } else {
        // 处理HTTP错误
        try {
          // 使用UTF-8解码错误响应
          final String decodedError = utf8.decode(response.bodyBytes);
          Map<String, dynamic> errorData = jsonDecode(decodedError);
          String errorMessage = errorData['msg'] ?? 'Unkown Error';
          return '$errorMessage (${response.statusCode})';
        } catch (e) {
          return 'HTTP: ${response.statusCode}';
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
