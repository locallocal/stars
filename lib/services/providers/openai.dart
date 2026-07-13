import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:stars/model/model.dart';
import 'package:stars/services/providers/providers.dart';

class OpenAI extends Provider {
  static const String defaultApiModelsUrl = 'https://api.openai.com/v1/models';
  static const String defaultApiChatUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String defaultApiImageUrl =
      'https://api.openai.com/v1/images/generations';
  OpenAI(super.bot);

  @override
  bool supportWebSearch() {
    switch (bot.model.toLowerCase()) {
      case 'gpt-4o-mini-search-preview':
      case 'gpt-4o-mini-search-preview-2025-03-11':
      case 'gpt-4o-search-preview':
      case 'gpt-4o-search-preview-2025-03-11':
        return true;
    }
    return false;
  }

  @override
  bool supportDeepThinking() {
    switch (bot.model.toLowerCase()) {
      case 'o1':
      case 'o1-2024-12-17':
      case 'o1-pro':
      case 'o1-pro-2025-03-19':
      case 'o1-mini':
      case 'o1-mini-2024-09-12':
      case 'o3-mini':
      case 'o3-mini-2025-01-31':
        return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'chatgpt-4o-latest':
      case 'gpt-4.5-preview':
      case 'gpt-4.5-preview-2025-02-27':
      case 'gpt-4.1':
      case 'gpt-4.1-2025-04-14':
      case 'gpt-4.1-mini':
      case 'gpt-4.1-mini-2025-04-14':
      case 'gpt-4.1-nano-2025-04-14':
      case 'gpt-4.1-nano':
      case 'gpt-4o':
      case 'gpt-4o-2024-11-20':
      case 'gpt-4o-2024-08-06':
      case 'gpt-4o-2024-05-13':
      case 'gpt-4o-mini':
      case 'gpt-4o-mini-2024-07-18':
      case 'gpt-4o-mini-search-preview':
      case 'gpt-4o-mini-search-preview-2025-03-11':
      case 'gpt-4o-search-preview':
      case 'gpt-4o-search-preview-2025-03-11':
      case 'gpt-4-turbo':
      case 'gpt-4-turbo-2024-04-09':
      case 'gpt-4':
      case 'gpt-4-0613':
      case 'gpt-4-0314':
      case 'gpt-3.5-turbo':
      case 'gpt-3.5-turbo-0125':
      case 'o4-mini':
      case 'o4-mini-2025-04-16':
      case 'o3':
      case 'o3-2025-04-16':
      case 'o1-preview':
      case 'o1-preview-2024-09-12':
      case 'o1':
      case 'o1-2024-12-17':
      case 'o1-pro':
      case 'o1-pro-2025-03-19':
      case 'computer-use-preview':
      case 'computer-use-preview-2025-03-11':
        return [InputModality.text, InputModality.image];
      case 'gpt-4o-audio-preview':
      case 'gpt-4o-audio-preview-2024-12-17':
      case 'gpt-4o-audio-preview-2024-10-01':
      case 'gpt-4o-mini-audio-preview':
      case 'gpt-4o-mini-audio-preview-2024-12-17':
      case 'gpt-4o-realtime-preview':
      case 'gpt-4o-realtime-preview-2024-12-17':
      case 'gpt-4o-mini-realtime-preview':
      case 'gpt-4o-mini-realtime-preview-2024-12-17':
        return [InputModality.text, InputModality.audio];
      case 'o1-mini':
      case 'o1-mini-2024-09-12':
      case 'o3-mini':
      case 'o3-mini-2025-01-31':
      case 'dall-e-3':
      case 'dall-e-2':
      case 'gpt-4o-mini-tts':
      case 'tts-1':
      case 'tts-1-hd':
        return [InputModality.text];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'dall-e-3':
      case 'dall-e-2':
        return [OutputModality.image];
      case 'gpt-4o-audio-preview':
      case 'gpt-4o-audio-preview-2024-12-17':
      case 'gpt-4o-audio-preview-2024-10-01':
      case 'gpt-4o-mini-audio-preview':
      case 'gpt-4o-mini-audio-preview-2024-12-17':
      case 'gpt-4o-realtime-preview':
      case 'gpt-4o-realtime-preview-2024-12-17':
        return [OutputModality.text, OutputModality.audio];
      case 'gpt-4o-mini-tts':
      case 'tts-1':
      case 'tts-1-hd':
        return [OutputModality.speech];
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
            final delta = data['choices'][0]['delta']['content'] ?? '';
            onResponse(delta);
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
            : defaultApiImageUrl;
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
          final fileName = 'dalle_$timestamp.png';
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
    // 检查是否为 o1 或 o3 模型，这些模型不支持 system 消息
    final bool isO1OrO3Model =
        bot.model.toLowerCase().startsWith('o1') ||
        bot.model.toLowerCase().startsWith('o3');
    // 如果是 o1 或 o3 模型，过滤掉 system 消息
    final filteredMessages =
        isO1OrO3Model
            ? messages.where((msg) => msg.role != "system").toList()
            : messages;
    return filteredMessages.map((message) {
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
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
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
