import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class OpenAI extends Provider {
  static const String defaultApiModelsUrl = 'https://api.openai.com/v1/models';
  static const String defaultApiChatUrl =
      'https://api.openai.com/v1/chat/completions';
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
      case 'gpt-4.5-preview':
      case 'gpt-4.5-preview-2025-02-27':
      case 'gpt-4o':
      case 'gpt-4o-2024-08-06':
      case 'gpt-4o-mini':
      case 'gpt-4o-mini-2024-07-18':
      case 'o1':
      case 'o1-2024-12-17':
      case 'o1-pro':
      case 'o1-pro-2025-03-19':
      case 'o1-mini':
      case 'o1-mini-2024-09-12':
      case 'gpt-4o-mini-search-preview':
      case 'gpt-4o-mini-search-preview-2025-03-11':
      case 'gpt-4o-search-preview':
      case 'gpt-4o-search-preview-2025-03-11':
      case 'computer-use-preview':
      case 'computer-use-preview-2025-03-11':
      case 'gpt-4-turbo':
      case 'gpt-4-turbo-2024-04-09':
      case 'gpt-4':
      case 'gpt-4-0613':
      case 'gpt-3.5-turbo':
      case 'gpt-3.5-turbo-0125':
        return [InputModality.text, InputModality.image];
      case 'gpt-4o-audio-preview':
      case 'gpt-4o-audio-preview-2024-12-17':
      case 'gpt-4o-mini-audio-preview':
      case 'gpt-4o-mini-audio-preview-2024-12-17':
      case 'gpt-4o-realtime-preview':
      case 'gpt-4o-realtime-preview-2024-12-17':
        return [InputModality.text, InputModality.audio];
      case 'o3-mini':
      case 'o3-mini-2025-01-31':
      case 'dall-e-3':
      case 'dall-e-2':
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
      case 'gpt-4o-mini-audio-preview':
      case 'gpt-4o-mini-audio-preview-2024-12-17':
      case 'gpt-4o-realtime-preview':
      case 'gpt-4o-realtime-preview-2024-12-17':
        return [OutputModality.text, OutputModality.audio];
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
}
