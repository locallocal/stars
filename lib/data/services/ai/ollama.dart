import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/provider_service.dart';

class Ollama extends Provider {
  Ollama(super.bot);

  @override
  ForegroundRoutingTransport get foregroundRoutingTransport =>
      ForegroundRoutingTransport.bufferedText;

  @override
  Future<List<AiModelInfo>> fetchModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/api/tags'
            : 'http://localhost:11434/api/tags';

    final response = await httpGet(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = decodeProviderResponse(utf8.decode(response.bodyBytes));
      final models = providerModelInfos(data['models']);
      return models;
    } else {
      throw Exception('List Models Failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
    try {
      // 重置取消状态
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/api/chat'
              : 'http://localhost:11434/api/chat';

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({'Content-Type': 'application/json'})
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'stream': true,
            });

      final streamedResponse = await sendHttpRequest(request);
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(LineSplitter());

      // 监听取消事件
      cancelController?.stream.listen((_) {
        // request.abort(); // 使用abort()方法来取消请求 - 这是错误的
        // 在Dart的http包中，没有直接的方法来取消请求
        // 我们可以通过关闭控制器来间接实现取消
        cancelController?.close();
      });

      await for (final line in stream) {
        // 检查是否已取消
        if (isCancelled) break;

        try {
          final data = decodeProviderResponse(line);
          if (data.containsKey('message')) {
            final content = data['message']['content'] ?? '';
            onResponse(content);
          }
        } catch (e) {
          // 忽略解析错误
        }
      }

      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('Request Cancelled');
      }
    } catch (e) {
      if (onError != null) {
        onError!(e.toString());
      }
    }
  }
}
