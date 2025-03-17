import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class OllamaChatModel extends ChatModel {
  OllamaChatModel(Bot bot) : super(bot);

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/api/tags'
            : 'http://localhost:11434/api/tags';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final models =
            (data['models'] as List)
                .map((model) => model['name'] as String)
                .toList();
        return models;
      } else {
        throw Exception('获取模型列表失败: ${response.statusCode}');
      }
    } catch (e) {
      // 如果API调用失败，返回一些默认模型
      return ['llama3', 'mistral', 'mixtral', 'phi3', 'qwen'];
    }
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/api/chat'
            : 'http://localhost:11434/api/chat';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': bot.model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['message']['content'];
    } else {
      throw Exception('请求失败: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(
    List<ChatMessage> messages,
    StreamResponseCallback onResponse, {
    Function? onComplete,
    Function(String)? onError,
  }) async {
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

      final streamedResponse = await request.send();
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
          final data = jsonDecode(line);
          if (data.containsKey('message')) {
            final content = data['message']['content'] ?? '';
            onResponse(content);
          }
        } catch (e) {
          // 忽略解析错误
        }
      }

      if (!isCancelled && onComplete != null) {
        onComplete();
      } else if (isCancelled && onError != null) {
        onError('请求已取消');
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
    }
  }
}
