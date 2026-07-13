import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:stars/model/model.dart';
import 'package:stars/services/providers/providers.dart';

class Monica extends Provider {
  static const String defaultApiModelsUrl =
      'https://openapi.monica.im/v1/models';
  static const String defaultApiChatUrl =
      'https://openapi.monica.im/v1/chat/completions';
  Monica(super.bot);

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
    switch (bot.model.toLowerCase()) {
      case 'gpt-4o':
      case 'gpt-4o-2024-11-20':
      case 'gpt-4o-2024-08-06':
      case 'gpt-4o-mini':
      case 'gpt-4o-mini-2024-07-18':
      case 'o1-preview':
      case 'o1-preview-2024-09-12':
      case 'claude-3-opus-20240229':
      case 'claude-3-haiku-20240307':
      case 'gemini-1.5-pro-002':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'flux_pro':
      case 'flux_dev':
      case 'flux_schnell':
      case 'sdxl':
      case 'sd3':
      case 'sd3_5':
      case 'dall-e-3':
      case 'playground-v2-5':
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
    switch (bot.model) {
      case 'flux_pro':
      case 'flux_dev':
      case 'flux_schnell':
      case 'sdxl':
      case 'sd3':
      case 'sd3_5':
      case 'playground-v2-5':
        return const ['1024x1024', '768x1344', '1344x768'];
      case 'dall-e-3':
        return const ['1024x1024', '1024x1792', '1792x1024'];
      case 'V_2':
        return const [
          'ASPECT_10_16',
          'ASPECT_16_10',
          'ASPECT_9_16',
          'ASPECT_16_9',
          'ASPECT_3_2',
          'ASPECT_2_3',
          'ASPECT_4_3',
          'ASPECT_3_4',
          'ASPECT_1_1',
          'ASPECT_1_3',
          'ASPECT_3_1',
        ];
    }
    return [''];
  }

  @override
  List<String> getSupportImageStyles() {
    switch (bot.model) {
      case 'dall-e-3':
        return const ['vivid', 'natural'];
      case 'V_2':
        return const [
          'AUTO',
          'GENERAL',
          'REALISTIC',
          'DESIGN',
          'RENDER_3D',
          'ANIME ',
        ];
    }
    return [];
  }

  @override
  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath, {
    List<String> referenceImages = const [],
    String style = '',
  }) async {
    final Map<String, dynamic> requestBody = {
      'model': bot.model,
      'prompt': prompt,
      'n': 1, // 生成图片数量
      'response_format': 'url', // 返回URL而不是base64
    };

    var url = "";
    switch (bot.model) {
      case 'flux_pro':
      case 'flux_dev':
      case 'flux_schnell':
        url = '${bot.baseURL}image/gen/fluxs';
        requestBody['size'] = size;
        requestBody['num_outputs'] = 1;
      case 'sdxl':
      case 'sd3':
      case 'sd3_5':
        url = '${bot.baseURL}image/gen/sd';
        requestBody['size'] = size;
        requestBody['num_outputs'] = 1;
      case 'playground-v2-5':
        url = '${bot.baseURL}image/gen/playground';
        requestBody['size'] = size;
        requestBody['count'] = 1;
      case 'dall-e-3':
        url = '${bot.baseURL}image/gen/dalle';
        requestBody['size'] = size;
        requestBody['n'] = 1;
        if (style.isNotEmpty) {
          requestBody['style'] = style;
        }
      case 'V_2':
        url = '${bot.baseURL}image/gen/ideogram';
        requestBody['aspect_ratio'] = size;
        if (style.isNotEmpty) {
          requestBody['style_type'] = style;
        }
    }

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
          final fileName = '${bot.model}_$timestamp.png';
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
