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
    if (bot.model.contains('DeepSeek-R1') ||
        bot.model == 'deepseek-reasoner' ||
        bot.model.contains('deepseek-r1')) {
      return true;
    }
    return false;
  }

  bool supportMultiModalities() {
    if (bot.model == 'gemini-2.0-flash-exp') {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    if (supportMultiModalities()) {
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
      var modelName = bot.model;
      if (webSearch) {
        modelName += ':surfing';
      }
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}chat/completions'
              : defaultApiChatUrl;

      if (supportMultiModalities()) {
        _sendMessageMultiModalities(url, modelName, messages);
        return;
      }

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': modelName,
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
          print(line);
          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') {
            if (!isCancelled && onComplete != null) {
              onComplete!();
            }
            return;
          }

          try {
            final data = jsonDecode(jsonStr);
            if (supportDeepThinking()) {
              final reasonContent =
                  data['choices'][0]['delta']['reasoning_content'] ?? '';
              if (deepThinking &&
                  reasonContent.isNotEmpty &&
                  onReasoningResponse != null) {
                onReasoningResponse!(reasonContent);
              }
            }
            final delta = data['choices'][0]['delta']['content'] ?? '';
            if (delta.isNotEmpty) {
              onResponse(delta);
            }
          } catch (e) {
            onError!('Decode result failed: $line, ${e.toString()}');
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

  void _sendMessageMultiModalities(
    String url,
    String modelName,
    List<ChatMessage> messages,
  ) async {
    final request =
        http.Request('POST', Uri.parse(url))
          ..headers.addAll({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${bot.apiKey}',
          })
          ..body = jsonEncode({
            'model': modelName,
            'messages': processMessagesWithImages(messages),
            'stream': false,
            "modalities": ["text", "image"],
          });

    final response = await request.send();
    if (isCancelled) {
      if (onError != null) {
        onError!('Request cancelled');
      }
      return;
    }
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      final multiModalContent =
          data['choices'][0]['message']['multi_mod_content'] ?? [];
      if (multiModalContent.isNotEmpty) {
        for (var item in multiModalContent) {
          final text = item['text'] ?? '';
          if (text.isNotEmpty) {
            onResponse(text);
          }
          final inlineData = item['inline_data'] ?? {};
          if (inlineData.isNotEmpty && inlineData['data'].isNotEmpty) {
            try {
              final String mimeType = inlineData['mime_type'] ?? 'image/jpeg';
              final String base64Data = inlineData['data'];

              // 直接将base64图片数据以Markdown格式返回
              final String markdownImage =
                  '\n![Generated Image](data:$mimeType;base64,$base64Data)\n';
              onResponse(markdownImage);
            } catch (e) {
              if (onError != null) {
                onError!('Process Output Image Failed, ${e.toString()}');
              }
            }
          }
        }
      } else {
        final content = data['choices'][0]['message']['content'] ?? '';
        if (content.isNotEmpty) {
          onResponse(content);
        }
      }

      if (onComplete != null) {
        onComplete!();
      }
    } else {
      final errorBody = await response.stream.bytesToString();
      if (onError != null) {
        onError!('Request Failed: ${response.statusCode}, $errorBody');
      }
    }
  }
}
