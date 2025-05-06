import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class ModelScope extends Provider {
  static const String defaultApiModelsUrl =
      'https://api-inference.modelscope.cn/v1/models';
  static const String defaultApiChatUrl =
      'https://api-inference.modelscope.cn/v1/chat/completions';
  static const String defaultApiImageUrl =
      'https://api-inference.modelscope.cn/v1/images/generations';
  ModelScope(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model) {
      case 'Qwen/Qwen2.5-VL-7B-Instruct':
      case 'Qwen/Qwen2.5-VL-32B-Instruct':
      case 'Qwen/Qwen2.5-VL-72B-Instruct':
      case 'Qwen/Qwen2.5-VL-3B-Instruct':
      case 'Qwen/Qwen2-VL-7B-Instruct':
      case 'Qwen/QVQ-72B-Preview':
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

  @override
  List<String> getSupportedImageSizes() {
    if (bot.model == 'dall-e-3') {
      return ['1024x1024', '1792x1024', '1024x1792'];
    } else if (bot.model == 'dall-e-2') {
      return ['256x256', '512x512', '1024x1024'];
    }
    return [''];
  }

  @override
  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath, {
    List<String> referenceImages = const [],
    String style = '',
  }) async {
    // 检查是否使用DALL-E模型
    if (!bot.model.toLowerCase().contains('dall-e')) {
      throw UnsupportedError(
        'Model ${bot.model} dont support generate image, please use  dall-e-2 or dall-e-3',
      );
    }
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}images/generations'
            : 'https://api.openai.com/v1/images/generations';
    final Map<String, dynamic> requestBody = {
      'model': bot.model,
      'prompt': prompt,
      'n': 1, // 生成图片数量
      'size': size,
      'response_format': 'url', // 返回URL而不是base64
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bot.apiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final imageUrl = data['data'][0]['url'];
        final imageResponse = await http.get(Uri.parse(imageUrl));

        if (imageResponse.statusCode == 200) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'model_scope_$timestamp.png';
          final filePath = '$imageDirPath/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(imageResponse.bodyBytes);
          return [filePath];
        } else {
          throw Exception(
            'Download image $imageUrl failed: ${imageResponse.statusCode}',
          );
        }
      } else {
        throw Exception(
          'Generate image failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Generate image failed: $e');
    }
  }
}
