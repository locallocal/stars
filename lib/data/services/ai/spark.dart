import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:stars/domain/models/models.dart';
import 'package:stars/data/services/ai/provider_service.dart';

class Spark extends Provider {
  static const String defaultApiChatUrl =
      'https://spark-api-open.xf-yun.com/v1/chat/completions';
  Spark(super.bot);

  @override
  bool supportWebSearch() {
    switch (bot.model) {
      case 'pro-128k':
      case 'max-32k':
      case '4.0Ultra':
        return true;
    }
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
      'lite',
      'generalv3',
      'pro-128k',
      'generalv3.5',
      'max-32k',
      '4.0Ultra',
    ];
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
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
              if (webSearch)
                'tools': [
                  {
                    'type': 'web_search',
                    'web_search': {
                      'enable': true,
                      "show_ref_label": true,
                      "search_mode": "deep",
                    },
                  },
                ],
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
