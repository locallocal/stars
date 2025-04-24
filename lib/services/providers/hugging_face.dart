import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';

class HuggingFace extends Provider {
  static const defaultApiModelUrl = '';

  HuggingFace(super.bot);

  String _getSubProvider() {
    final uri = Uri.parse(bot.baseURL);
    final pathSegments = uri.pathSegments;

    // 确保路径段不为空
    if (pathSegments.isNotEmpty) {
      // 第一个路径段通常是子提供商名称
      return pathSegments.first;
    }
    return '';
  }

  @override
  Future<List<String>> listModels() async {
    final provider = _getSubProvider();
    final url =
        'https://huggingface.co/api/models?inference_provider=${provider}';

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
            (data as List).map((model) {
              final m = model['id'] as String;
              return m.substring(m.lastIndexOf('/') + 1); // 提取模型名称部分
            }).toList();
        models.sort();
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
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();
      final url = '${bot.baseURL}chat/completions';
      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
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
            onResponse(delta);
          } catch (e) {
            // 忽略解析错误
          }
        }
      }

      // 确保在流处理完成后调用onComplete
      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('请求已取消');
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
}
