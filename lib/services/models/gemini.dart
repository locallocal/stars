import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class GeminiChatModel extends ChatModel {
  GeminiChatModel(Bot bot) : super(bot);

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1beta/models/${bot.model}:generateContent'
            : 'https://generativelanguage.googleapis.com/v1beta/models/${bot.model}:generateContent';

    // 转换消息格式为Gemini格式
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

      // Gemini目前不支持原生流式输出，这里模拟流式输出
      final response = await sendMessage(messages);

      // 将完整响应分成小块模拟流式输出
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
        onComplete();
      } else if (isCancelled && onError != null) {
        onError('请求已取消');
      }
    } catch (e) {
      if (!isCancelled && onError != null) {
        onError(e.toString());
      }
    } finally {
      // 清理资源
      cancelController?.close();
      cancelController = null;
    }
  }
}
