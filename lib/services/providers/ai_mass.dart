import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class AiMass extends Provider {
  static const String defaultApiChatUrl =
      'https://platform.wair.ac.cn/maas/v1/chat/completions';
  AiMass(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    switch (bot.model) {
      case 'taichu_o1':
      case 'deepseek_r1_distill_qwen_32b':
      case 'deepseek_r1_distill_qwen_14b':
      case 'deepseek_r1_distill_llama_70b':
      case 'deepseek_r1':
        return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model) {
      case 'taichu_vl':
      case 'taichu_vlr_7b':
      case 'taichu_vlr_3b':
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
    return const [
      'taichu_llm',
      'qwq_32b',
      'taichu_o1',
      'deepseek_r1_distill_qwen_32b',
      'deepseek_r1_distill_qwen_14b',
      'deepseek_r1_distill_llama_70b',
      'deepseek_r1',
      'taichu_vl',
      'taichu_vlr_7b',
      'taichu_vlr_3b',
    ];
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      // 重置取消状态
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
        // 检查错误范围
        if (line.contains('error')) {
          final errorData = jsonDecode(line);
          final errorMessage = errorData['error']['message'];
          throw Exception('Send Message Failed: $errorMessage');
        }
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
