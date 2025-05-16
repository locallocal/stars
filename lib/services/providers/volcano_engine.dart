import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class VolcanoEngine extends Provider {
  static const String defaultApiChatUrl =
      'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
  static const String defaultApiImageUrl =
      'https://ark.cn-beijing.volces.com/api/v3/images/generations';

  VolcanoEngine(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    if (bot.model.contains('thinking')) {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model) {
      case 'doubao-1-5-thinking-pro-m-250415':
      case 'doubao-1.5-vision-pro-250328':
      case 'doubao-1-5-vision-pro-32k-250115':
      case 'doubao-1.5-vision-lite-250315':
      case 'doubao-vision-pro-32k-241028':
      case 'doubao-vision-lite-32k-241015':
      case 'doubao-seaweed-241128':
      case 'doubao-seedance-1-0-lite-i2v-250428':
      case 'wan2-1-14b-i2v':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model) {
      case 'doubao-seedance-1-0-lite-i2v-250428':
      case 'doubao-seedance-1-0-lite-t2v-250428':
      case 'doubao-seaweed-241128':
      case 'wan2-1-14b-t2v-250225':
      case 'wan2-1-14b-i2v-250225':
      case 'wan2-1-14b-flf2v-250417':
        return [OutputModality.video];
      case 'doubao-seedream-3-0-t2i-250415':
        return [OutputModality.image];
    }
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    return const [
      'doubao-1-5-thinking-vision-pro-250428',
      'doubao-1-5-thinking-pro-m-250428',
      'doubao-1-5-thinking-pro-250415',
      'doubao-1-5-thinking-pro-m-250415',
      'doubao-1.5-vision-pro-250328',
      'doubao-1-5-vision-pro-32k-250115',
      'doubao-1-5-pro-256k-250115',
      'doubao-1-5-pro-32k-250115',
      'doubao-1-5-lite-32k-250115',
      'doubao-1.5-vision-lite-250315',
      'doubao-vision-pro-32k-241028',
      'doubao-vision-lite-32k-241015',
      'doubao-pro-256k-241115',
      'doubao-pro-32k-241215',
      'doubao-pro-32k-240828',
      'doubao-pro-32k-240615',
      'doubao-lite-32k-240828',
      'doubao-lite-128k-240828',
      'doubao-seedance-1-0-lite-i2v-250428',
      'doubao-seedance-1-0-lite-t2v-250428',
      'doubao-seaweed-241128',
      'wan2-1-14b-t2v-250225',
      'wan2-1-14b-i2v-250225',
      'wan2-1-14b-flf2v-250417',
      'doubao-seedream-3-0-t2i-250415',
      'deepseek-r1-250120',
      'deepseek-v3-241226',
      'deepseek-r1-distill-qwen-7b-250120',
      'deepseek-r1-distill-qwen-32b-250120',
      'mistral-7b-instruct-v0.2',
      'chatglm3-130b-fc-v1.0',
      'moonshot-v1-128k',
      'moonshot-v1-32k',
      'moonshot-v1-8k',
    ];
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
    try {
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
        if (isCancelled) break;
        if (line.contains('error')) {
          final data = jsonDecode(line);
          if (data['error'] != null && onError != null) {
            throw Exception(
              'Code: ${data['error']['code']}, Message: ${data['error']['message']}',
            );
          }
        }

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
            if (deepThinking &&
                data['choices'][0]['delta'].containsKey('reasoning_content')) {
              final reasoning =
                  data['choices'][0]['delta']['reasoning_content'] ?? '';
              if (reasoning.isNotEmpty && onReasoningResponse != null) {
                onReasoningResponse!(reasoning);
              }
              continue;
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
        onError!('Request cancelled');
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

  @override
  List<String> getSupportImageStyles() {
    return [];
  }

  @override
  List<String> getSupportedImageSizes() {
    return [
      '1024x1024',
      '864x1152',
      '1152x864',
      '1280x720',
      '720x1280',
      '832x1248',
      '1248x832',
      '1512x648',
    ];
  }

  @override
  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath, {
    List<String> referenceImages = const [],
    String style = '',
  }) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}images/generations'
            : defaultApiImageUrl;

    // 准备请求参数
    final Map<String, dynamic> requestBody = {
      'model': bot.model,
      'prompt': prompt,
      'size': size,
      'response_format': 'url',
      'watermark': false,
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
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final imageUrl = data['data'][0]['url'];
        final imageResponse = await http.get(Uri.parse(imageUrl));
        if (imageResponse.statusCode == 200) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'volcano_engine_image_$timestamp.png';
          final filePath = '$imageDirPath/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(imageResponse.bodyBytes);
          return [filePath];
        } else {
          throw Exception('Download image $imageUrl failed: $imageResponse');
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
