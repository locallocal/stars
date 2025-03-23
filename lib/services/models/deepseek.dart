import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class DeepSeekChatModel extends ChatModel {
  static const String defaultApiModelKey = 'https://api.deepseek.com/models';
  static const String defaultApiChatUrl = 'https://api.deepseek.com/v1/chat/completions';
  DeepSeekChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/models'
            : defaultApiModelKey;

    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final models =
          (data['data'] as List)
              .map((model) => model['id'] as String)
              .toList();
      return models;
    } else {
      throw Exception('获取模型列表失败: ${response.statusCode}');
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
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': 0.7,
        'max_tokens': 2000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
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
      // 重置取消状态
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/v1/chat/completions'
              : defaultApiChatUrl;

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'temperature': 0.7,
              'max_tokens': 4096,
              'stream': true,
            });

      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('${streamedResponse.statusCode}, $errorBody');
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (isCancelled) break;
        if (line.isEmpty) continue;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr == '[DONE]') {
            // 当收到[DONE]标记时，确保调用onComplete
            if (!isCancelled && onComplete != null) {
              onComplete();
            }
            return;
          }

          try {
            final data = jsonDecode(jsonStr);
            if (data.containsKey('choices') &&
                data['choices'].isNotEmpty &&
                data['choices'][0].containsKey('delta')) {
              final delta = data['choices'][0]['delta']['content'] ?? '';
              if (delta.isNotEmpty) {
                onResponse(delta);
              }
            }
          } catch (e) {
            // ignore
          }
        }
      }

      if (!isCancelled && onComplete != null) {
        onComplete();
      } else if (isCancelled && onError != null) {
        onError('Request Cancelled');
      }
    } catch (e) {
      if (!isCancelled && onError != null) {
        onError(e.toString());
      }
    } finally {
      cancelController?.close();
      cancelController = null;
    }
  }
}
