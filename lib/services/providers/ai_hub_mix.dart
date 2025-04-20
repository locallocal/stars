import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class AiHubMix extends Provider {
  static const String defaultApiModelsUrl = 'https://aihubmix.com/v1/models';
  static const String defaultApiChatUrl =
      'https://aihubmix.com/v1/chat/completions';
  AiHubMix(super.bot);

  @override
  bool supportWebSearch() {
    return true;
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
        // 对模型列表进行去重处理
        final uniqueModels = models.toSet().toList();
        // 可选：对模型列表进行排序
        uniqueModels.sort();
        return uniqueModels;
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
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      // 重置取消状态
      resetCancelState();
      var modeName = bot.model;
      if (webSearch) {
        modeName += ':surfing';
      }

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
              'model': modeName,
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

      await for (final line in stream) {
        if (isCancelled) break;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') {
            if (!isCancelled && onComplete != null) {
              onComplete!();
            }
            return;
          }

          try {
            final data = jsonDecode(jsonStr);
            final delta = data['choices'][0]['delta']['content'] ?? '';
            onResponse(delta);
          } catch (e) {}
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
