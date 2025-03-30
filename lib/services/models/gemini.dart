import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class GeminiChatModel extends ChatModel {
  GeminiChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}/v1beta/openai/models' : '';

    final response = await http.get(
      Uri.parse('$url?key=${bot.apiKey}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final models = data['models'] as List<dynamic>;
      return models.map((m) => m['name'] as String).toList();
    }
    throw Exception('List Models Failed: ${response.statusCode}');
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1beta/models/${bot.model}:generateContent'
            : 'https://generativelanguage.googleapis.com/v1beta/models/${bot.model}:generateContent';

    final geminiMessages =
        messages
            .map(
              (m) => {
                'role': m.role == 'user' ? 'user' : 'model',
                'parts': [
                  {'text': m.content},
                ],
              },
            )
            .toList();

    final response = await http.post(
      Uri.parse('$url?key=${bot.apiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': geminiMessages,
        'generationConfig': {'temperature': 0.7},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Request Failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();

      final response = await sendMessage(messages);
      const chunkSize = 10;
      for (var i = 0; i < response.length; i += chunkSize) {
        // 检查是否已取消
        if (isCancelled) break;

        final end =
            (i + chunkSize < response.length) ? i + chunkSize : response.length;
        final chunk = response.substring(i, end);
        onResponse(chunk);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('Request Cancelled');
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
