import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:stars/domain/models/models.dart';
import 'package:stars/data/services/ai/provider_service.dart';

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
  Future<List<AiModelInfo>> fetchModels() async {
    throw UnsupportedError(
      "${bot.apiType} does not expose an external model catalog.",
    );
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
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

      final streamedResponse = await sendHttpRequest(request);
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
            final data = decodeProviderResponse(jsonStr);
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
