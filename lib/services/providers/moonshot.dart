import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class Moonshot extends Provider {
  static const String defaultApiModelsUrl = 'https://api.moonshot.cn/v1/models';
  static const String defaultApiChatUrl =
      'https://api.moonshot.cn/v1/chat/completions';
  Moonshot(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    if (bot.model.toLowerCase().contains('thinking')) {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    if (bot.model.toLowerCase().contains('vision')) {
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
        models.sort();
        return models;
      } else {
        throw Exception(
          'List models failed: ${response.statusCode}- ${response.body}',
        );
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
              'response_format': {'type': 'text'},
              'stream': true,
            });

      final streamedResponse = await request.send();
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      var responseContent = '';
      await for (final line in stream) {
        // 检查是否已取消
        if (isCancelled) break;
        responseContent += line;

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
            if (deepThinking) {
              // 处理深度思考的情况
              final reasonContent =
                  data['choices'][0]['delta']['reasoning_content'] ?? '';
              if (reasonContent.isNotEmpty && onReasoningResponse != null) {
                onReasoningResponse!(reasonContent);
              }
            }
            final content = data['choices'][0]['delta']['content'] ?? '';
            if (content.isEmpty) continue;
            onResponse(content);
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
      if (responseContent.contains('error')) {
        final errorData = jsonDecode(responseContent);
        final errorMessage = errorData['error']['message'];
        final errorCode = errorData['error']['code'];
        final errorType = errorData['error']['type'];
        throw Exception(
          'Send message failed: ($errorCode, $errorType) $errorMessage',
        );
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
