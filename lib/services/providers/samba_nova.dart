import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:stars/model/model.dart';
import 'package:stars/services/providers/providers.dart';

class SambaNova extends Provider {
  static const String defaultApiModelsUrl =
      'https://api.sambanova.ai/v1/models';
  static const String defaultApiChatUrl =
      'https://api.sambanova.ai/v1/chat/completions';
  SambaNova(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    if (bot.model.toLowerCase().contains('deepseek-r1')) {
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
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}models' : defaultApiModelsUrl;

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer ${bot.apiKey}'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final models =
            (data['data'] as List)
                .map((model) => model['id'] as String)
                .toList();
        return models;
      } else {
        throw Exception('List models failed: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('List models Timeout, retry later.');
    } catch (e) {
      throw Exception('List models failed: $e');
    }
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
            var delta = data['choices'][0]['delta']['content'] ?? '';

            if (stage.isEmpty) {
              if (delta.contains('<think>')) {
                stage = 'thinking';
                delta = delta.replaceAll('<think>', '');
              }
            }
            if (stage == 'thinking') {
              if (delta.contains('</think>')) {
                // 将</think>作为分隔符，分割推理部分和响应部分
                var parts = delta.split('</think>');
                if (parts.length > 0 &&
                    deepThinking &&
                    onReasoningResponse != null) {
                  // 前面部分作为推理内容
                  onReasoningResponse!(parts[0]);
                }
                if (parts.length > 1) {
                  // 后面部分作为实际响应内容
                  delta = parts[1];
                  stage = 'response';
                } else {
                  // 如果没有后续内容，只切换状态
                  stage = 'response';
                  continue;
                }
              } else if (deepThinking &&
                  delta.isNotEmpty &&
                  onReasoningResponse != null) {
                onReasoningResponse!(delta);
                continue;
              }
            }
            if (delta.isNotEmpty) {
              onResponse(delta);
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
      // 清理资源
      cancelController?.close();
      cancelController = null;
    }
  }
}
