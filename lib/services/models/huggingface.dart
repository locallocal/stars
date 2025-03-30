import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class HuggingFaceChatModel extends ChatModel {
  static const defaultApiModelUrl = '';

  HuggingFaceChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    return [
      'google/gemma-2-2b-it',
      'deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B',
      'meta-llama/Meta-Llama-3.1-8B-Instruct',
      'microsoft/phi-4',
      'Qwen/Qwen2.5-Coder-32B-Instruct',
      'deepseek-ai/DeepSeek-R1',
    ];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/chat/completions'
            : 'https://router.huggingface.co/hf-inference/v1/chat/completions';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': 0.7,
        'max_new_tokens': 1000,
        'return_full_text': false,
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
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/chat/completions'
              : 'https://router.huggingface.co/hf-inference/v1/chat/completions';

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'temperature': 0.7,
              'return_full_text': false,
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

      // 确保在流处理完成后调用onComplete
      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('请求已取消');
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
