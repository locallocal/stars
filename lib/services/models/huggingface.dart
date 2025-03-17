import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class HuggingFaceChatModel extends ChatModel {
  HuggingFaceChatModel(Bot bot) : super(bot);

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? bot.baseURL
            : 'https://api-inference.huggingface.co/models/${bot.model}';

    // 将消息格式化为单个文本
    final prompt = _formatMessagesToPrompt(messages);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'temperature': 0.7,
          'max_new_tokens': 1024,
          'return_full_text': false,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      // HuggingFace API可能返回不同格式的响应，需要根据实际情况处理
      if (data is List && data.isNotEmpty) {
        return data[0]['generated_text'] ?? '';
      } else if (data is Map) {
        return data['generated_text'] ?? '';
      }
      return data.toString();
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
      // HuggingFace Inference API目前不支持原生流式输出，这里模拟流式输出
      final response = await sendMessage(messages);

      // 将完整响应分成小块模拟流式输出
      const chunkSize = 8;
      for (var i = 0; i < response.length; i += chunkSize) {
        final end =
            (i + chunkSize < response.length) ? i + chunkSize : response.length;
        final chunk = response.substring(i, end);
        onResponse(chunk);
        await Future.delayed(const Duration(milliseconds: 30));
      }

      if (onComplete != null) {
        onComplete();
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
    }
  }

  // 将消息列表格式化为适合HuggingFace模型的提示文本
  String _formatMessagesToPrompt(List<ChatMessage> messages) {
    final buffer = StringBuffer();

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];

      if (message.role == 'system') {
        buffer.write('System: ${message.content}\n\n');
      } else if (message.role == 'user') {
        buffer.write('Human: ${message.content}\n');
      } else if (message.role == 'assistant') {
        buffer.write('AI: ${message.content}\n');
      }

      // 如果是最后一条用户消息，添加AI前缀以提示模型生成回复
      if (i == messages.length - 1 && message.role == 'user') {
        buffer.write('AI: ');
      }
    }

    return buffer.toString();
  }
}
