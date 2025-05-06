import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class Grok extends Provider {
  static const String defaultApiModelsUrl = 'https://api.grok.ai/v1/models';
  static const String defaultApiChatUrl =
      'https://api.grok.ai/v1/chat/completions';
  static const String defaultApiImageUrl =
      'https://api.grok.ai/v1/images/generations';
  Grok(super.bot);

  @override
  bool supportDeepThinking() {
    switch (bot.model) {
      case 'grok-3-mini-beta':
      case 'grok-3-mini-fast-beta':
        return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    if (bot.model.contains('grok-2-vision')) {
      return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    if (bot.model.contains('grok-2-image')) {
      return [OutputModality.image];
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
              'temperature': 0.7,
              'stream': true,
            });

      final streamedResponse = await request.send();
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(LineSplitter());

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
            final resonContent =
                data['choices'][0]['message']['reasoning_content'] ?? '';
            if (resonContent.isNotEmpty &&
                deepThinking &&
                onReasoningResponse != null) {
              onReasoningResponse!(resonContent);
            }
            final delta = data['choices'][0]['delta']['content'] ?? '';
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
        onError!('Request Cancelled');
      }
    } catch (e) {
      if (onError != null) {
        onError!(e.toString());
      }
    } finally {
      // 确保取消控制器关闭
      cancelController?.close();
      cancelController = null;
    }
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
            : defaultApiImageUrl;
    final Map<String, dynamic> requestBody = {
      'model': bot.model,
      'prompt': prompt,
      'n': 1, // 生成图片数量
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
          final fileName = 'grok_$timestamp.png';
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

  @override
  List<Map<String, dynamic>> processMessagesWithImages(
    List<ChatMessage> messages,
  ) {
    return messages.map((message) {
      // 如果消息没有图片，直接返回原始消息
      if (message.images.isEmpty) {
        return message.toJson();
      }
      // 处理带有图片的消息
      final List<Map<String, dynamic>> content = [];
      // 添加文本内容（如果有）
      if (message.content.isNotEmpty) {
        content.add({'type': 'text', 'text': message.content});
      }

      // 添加图片内容
      for (final imagePath in message.images) {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            final base64Image = base64Encode(bytes);

            content.add({
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
                'detail': 'high',
              },
            });
          }
        } catch (e) {
          print('Process image $imagePath failed: $e');
        }
      }
      return {'role': message.role, 'content': content};
    }).toList();
  }
}
