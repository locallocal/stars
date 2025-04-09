import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class PPIO extends Provider {
  static const String defaultApiModelsUrl = 'https://api.ppinfra.com/v3/model';
  static const String defaultApiChatUrl =
      'https://api.ppinfra.com/v3/openai/chat/completions';
  PPIO(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    if (bot.model.contains('deepseek-r1')) {
      return true;
    }
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
      'deepseek/deepseek-r1-turbo',
      'deepseek/deepseek-v3-turbo',
      'deepseek/deepseek-v3-0324',
      'deepseek/deepseek-r1/community',
      'deepseek/deepseek-v3/community',
      'deepseek/deepseek-r1',
      'deepseek/deepseek-v3',
      'qwen/qwq-32b',
      'deepseek/deepseek-r1-distill-qwen-32b',
      'deepseek/deepseek-r1-distill-qwen-14b',
      'deepseek/deepseek-r1-distill-llama-70b',
      'deepseek/deepseek-r1-distill-llama-8b',
      'meta-llama/llama-3.3-70b-instruct',
      'qwen/qwen-2.5-72b-instruct',
      'qwen/qwen-2-vl-72b-instruct',
      'meta-llama/llama-3.2-3b-instruct',
      'google/gemma-3-27b-it',
      'qwen/qwen2.5-vl-72b-instruct',
      'qwen/qwen2.5-32b-instruct',
      'baichuan/baichuan2-13b-chat',
      // 仅针对实名认证的企业用户开放
      // 'meta-llama/llama-3.1-70b-instruct',
      // 'meta-llama/llama-3.1-8b-instruct',
      '01-ai/yi-1.5-34b-chat',
      '01-ai/yi-1.5-9b-chat',
      'thudm/glm-4-9b-chat',
      'qwen/qwen-2-7b-instruct',
    ];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}openai/chat/completions'
            : defaultApiChatUrl;

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': processMessagesWithImages(messages),
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
              ? '${bot.baseURL}openai/chat/completions'
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
            });

      final streamedResponse = await request.send();
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      var stage = "";
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
            if (delta == '<think>') {
              stage = 'thinking';
              continue;
            }
            if (delta == '</think>') {
              stage = 'response';
              continue;
            }
            if (deepThinking && stage == 'thinking') {
              onReasoningResponse!(delta);
              continue;
            }
            if (stage == 'thinking') {
              continue;
            }
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
