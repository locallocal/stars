import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class BaiChuan extends Provider {
  static const String defaultApiChatUrl =
      'https://api.baichuan-ai.com/v1/chat/completions';

  BaiChuan(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    return const [
      'Baichuan4-Turbo',
      'Baichuan4-Air',
      'Baichuan4',
      'Baichuan3-Turbo',
      'Baichuan3-Turbo-128k',
      'Baichuan2-Turbo',
    ];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    try {
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/chat/completions'
              : defaultApiChatUrl;

      // 构建请求体 - 腾讯混元API特定格式
      final Map<String, dynamic> requestBody = {
        'model': bot.model,
        'messages': processMessagesWithImages(messages),
        if (webSearch) 'web_search': {"enable": true, "enable_trace": true},
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

        if (data['choices'] != null && data['choices'].length > 0) {
          final String content = data['choices'][0]['message']['content'];
          // 再次确保内容是有效的UTF-8字符串
          return content;
        } else {
          return 'Invalid response body: ${data['msg'] ?? 'Unknown error'}';
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
      return 'Send message failed: $e';
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}chat/completions'
              : defaultApiChatUrl;
      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': processMessagesWithImages(messages),
              'stream': true,
              if (webSearch)
                'web_search': {"enable": true, "enable_trace": true},
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
