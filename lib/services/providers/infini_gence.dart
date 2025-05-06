import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class InfiniAI extends Provider {
  static const String defaultApiModelsUrl =
      'https://cloud.infini-ai.com/maas/v1/models';
  static const String defaultApiChatUrl =
      'https://cloud.infini-ai.com/maas/v1/chat/completions';
  InfiniAI(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    switch (bot.model.toLowerCase()) {
      case 'deepseek-r1':
      case 'qwq-32b':
      case 'deepseek-r1-distill-qwen-32b':
        return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'qwen2.5-vl-72b-instruct':
      case 'qwen2.5-vl-32b-instruct':
      case 'qwen2.5-vl-7b-instruct':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'stable-diffusion-1.5':
        return [OutputModality.image];
      case 'cogvideox-2b':
      case 'vidu1.5':
        return [OutputModality.video];
    }
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
      throw Exception('List models timeout, retry later.');
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
