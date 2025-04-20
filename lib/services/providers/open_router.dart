import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';

class OpenRouter extends Provider {
  static const String defaultApiModelsUrl =
      'https://openrouter.ai/api/v1/models';
  static const String defaultApiChatUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  OpenRouter(super.bot);

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/models'
            : defaultApiModelsUrl;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${bot.apiKey}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['data'] as List<dynamic>;
        return models.map((model) => model['id'] as String).toList();
      } else {
        throw Exception(
          'List models failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('List models faield: $e');
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    resetCancelState();

    try {
      final request = http.Request('POST', Uri.parse(getMessageUrl()));

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      });
      request.body = jsonEncode({
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': true,
      });

      final response = await http.Client().send(request);
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception('${response.statusCode} $errorBody');
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      await for (var line in stream) {
        if (isCancelled) break;
        if (line.isEmpty || line == 'data: [DONE]') continue;

        if (line.startsWith('data: ')) {
          line = line.substring(6);
          try {
            final data = jsonDecode(line);
            final content = data['choices'][0]['delta']['content'] ?? '';
            if (content.isNotEmpty) {
              onResponse(content);
            }
          } catch (e) {
            // 忽略解析错误，继续处理下一行
          }
        }
      }

      // 确保在流处理完成后调用onComplete
      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('Request Cancelled by User');
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

  String getMessageUrl() {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/v1/chat/completions'
            : defaultApiChatUrl;
    return url;
  }
}
