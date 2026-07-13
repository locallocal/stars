import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:stars/model/model.dart';
import 'package:stars/services/providers/providers.dart';

class TogetherAI extends Provider {
  static const String defaultApiModelsUrl =
      'https://api.together.xyz/v1/models';
  static const String defaultApiChatUrl =
      'https://api.together.xyz/v1/chat/completions';
  static const String defaultApiImageUrl =
      'https://api.together.xyz/v1/images/generations';
  TogetherAI(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    if (bot.model.toLowerCase().contains('deepseek-r1')) {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model) {
      case 'meta-llama/Llama-3.2-90B-Vision-Instruct-Turbo':
      case 'meta-llama/Llama-3.2-11B-Vision-Instruct-Turbo':
      case 'meta-llama/Llama-Vision-Free':
      case 'meta-llama/Llama-Guard-3-11B-Vision-Turbo':
      case 'Qwen/Qwen2.5-VL-72B-Instruct':
      case 'Qwen/Qwen2-VL-72B-Instruct':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model) {
      case 'black-forest-labs/FLUX.1-dev':
      case 'black-forest-labs/FLUX.1-dev-lora':
      case 'black-forest-labs/FLUX.1-schnell':
      case 'black-forest-labs/FLUX.1-canny':
      case 'black-forest-labs/FLUX.1-depth':
      case 'black-forest-labs/FLUX.1-redux':
      case 'black-forest-labs/FLUX.1-pro':
      case 'black-forest-labs/FLUX.1.1-pro':
      case 'black-forest-labs/FLUX.1-schnell-Free':
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
            (data as List).map((model) => model['id'] as String).toList();
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

      var stage = "";
      await for (final line in stream) {
        // 检查是否已取消
        if (isCancelled) break;
        if (line.contains('error')) {
          final errorData = jsonDecode(line);
          final errorMessage = errorData['error']['message'];
          throw Exception('Request failed: $errorMessage');
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
            var delta = data['choices'][0]['delta']['content'] ?? '';
            if (stage.isEmpty) {
              if (delta.contains('<think>')) {
                stage = 'thinking';
                delta = delta.replaceAll('<think>', '');
              }
            }
            if (stage == 'thinking') {
              if (delta.contains('</think>')) {
                // 将</think>作为分隔符，分割推理部分和响应部分
                var parts = delta.split('</think>');
                if (parts.length > 0 &&
                    deepThinking &&
                    onReasoningResponse != null) {
                  // 前面部分作为推理内容
                  onReasoningResponse!(parts[0]);
                }
                if (parts.length > 1) {
                  // 后面部分作为实际响应内容
                  delta = parts[1];
                  stage = 'response';
                } else {
                  // 如果没有后续内容，只切换状态
                  stage = 'response';
                  continue;
                }
              } else if (deepThinking &&
                  delta.isNotEmpty &&
                  onReasoningResponse != null) {
                onReasoningResponse!(delta);
                continue;
              }
            }
            if (stage.isEmpty || stage == 'response') {
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
      // 清理资源
      cancelController?.close();
      cancelController = null;
    }
  }

  @override
  List<String> getSupportedImageSizes() {
    return const [
      '512x512',
      '1024x1024',
      '1440x1440',
      '768x768',
      '1024x768',
      '768x1024',
      '1280x720',
      '720x1280',
      '1440x768',
      '768x1440',
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
    var height = 1024;
    var width = 1024;
    if (size.isNotEmpty) {
      final parts = size.split('x');
      if (parts.length == 2) {
        height = int.tryParse(parts[0]) ?? 1024;
        width = int.tryParse(parts[1]) ?? 1024;
      }
    }
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}images/generations'
            : defaultApiImageUrl;
    final Map<String, dynamic> requestBody = {
      'model': bot.model,
      'prompt': prompt,
      'n': 1, // 生成图片数量
      'height': height,
      'width': width,
      'output_format': 'png',
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
          final fileName = 'together_ai_$timestamp.png';
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
