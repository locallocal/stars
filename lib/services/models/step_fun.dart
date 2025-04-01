import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/models/chat_models.dart';

class StepFunChatModel extends ChatModel {
  static const String defaultApiModelsUrl = 'https://api.stepfun.com/v1/models';
  static const String defaultApiChatUrl =
      'https://api.stepfun.com/v1/chat/completions';
  StepFunChatModel(super.bot);

  @override
  bool supportsWebSearch() {
    switch (bot.model.toLowerCase()) {
      case 'step-1-flash':
      case 'step-1-8k':
      case 'step-1-32k':
      case 'step-1-128k':
      case 'step-1-256k':
      case 'step-1v-8k':
      case 'step-1v-32k':
      case 'step-2-16k':
        return true;
    }
    return false;
  }

  @override
  bool supportsDeepThinking() {
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'step-1v-8k':
      case 'step-1v-32k':
      case 'step-1o-vision-32k':
        return [InputModality.text, InputModality.image];
      case 'step-1.5v-mini':
        return [InputModality.text, InputModality.image, InputModality.video];
      case 'step-1o-audio':
        return [InputModality.realtime];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'step-1x-medium':
        return [OutputModality.image];
      case 'step-tts-mini':
        return [OutputModality.audio];
      case 'step-1o-audio':
        return [OutputModality.realtime];
    }
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}/models' : defaultApiModelsUrl;

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
        if (!models.contains('step-1o-audio')) {
          models.add('step-1o-audio');
        }
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
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}chat/completions'
            : defaultApiChatUrl;

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': processMessagesWithImages(messages),
        if (webSearch)
          'tools ': [
            {
              'type': 'web_search',
              'function': {'description': '这个web_search用来搜索互联网的信息'},
            },
          ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Send Message Failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
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
              if (webSearch)
                'tools ': [
                  {
                    'type': 'web_search',
                    'function': {'description': '这个web_search用来搜索互联网的信息'},
                  },
                ],
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
    if (bot.model == 'step-1x-medium') {
      return [
        '256x256',
        '512x512',
        '768x768',
        '1024x1024',
        '1280x800',
        '800x1280',
      ];
    }
    return [''];
  }

  @override
  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath,
  ) async {
    // 检查是否使用DALL-E模型
    if (bot.model.toLowerCase() != 'step-1x-medium') {
      throw UnsupportedError(
        'Model ${bot.model} dont support generate image, please use step-1x-medium',
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
          final fileName = 'step-1x-medium_$timestamp.png';
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
