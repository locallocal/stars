import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/provider_service.dart';
import 'package:stars/domain/models/models.dart';

class Baidu extends Provider {
  static const String defaultApiChatUrl =
      'https://qianfan.baidubce.com/v2/chat/completions';

  Baidu(super.bot);

  @override
  bool supportWebSearch() {
    switch (bot.model.toLowerCase()) {
      case 'ernie-4.5-8k-preview':
      case 'ernie-4.0-8k-latest':
      case 'ernie-4.0-8k-preview':
      case 'ernie-4.0-8k':
      case 'ernie-4.0-turbo-8k-latest':
      case 'ernie-4.0-turbo-8k-preview':
      case 'ernie-4.0-turbo-8k':
      case 'ernie-4.0-turbo-128k':
      case 'ernie-3.5-8k-preview':
      case 'ernie-3.5-8k':
      case 'ernie-3.5-128k':
        return true;
    }
    return false;
  }

  @override
  bool supportDeepThinking() {
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'ernie-4.5-8k-preview':
      case 'deepseek-vl2':
      case 'deepseek-vl2-small':
      case 'qwen2.5-vl-7b-instruct':
      case 'internvl2.5-38b-mpo':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model) {
      case 'irag-1.0':
      case 'flux.1-schnell':
        return [OutputModality.image];
    }
    return [OutputModality.text];
  }

  @override
  Future<List<AiModelInfo>> fetchModels() async {
    throw UnsupportedError(
      "${bot.apiType} does not expose an external model catalog.",
    );
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
              if (webSearch)
                'web_search': {"enable": true, "enable_trace": true},
            });

      final streamedResponse = await sendHttpRequest(request);
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      await for (final line in stream) {
        if (isCancelled) break;
        if (line.startsWith('data:')) {
          final jsonStr = line.substring(5);
          if (jsonStr == '[DONE]') {
            // 当收到[DONE]标记时，确保调用onComplete
            if (!isCancelled && onComplete != null) {
              onComplete!();
            }
            return;
          }
          try {
            final data = decodeProviderResponse(jsonStr);
            final delta = data['choices'][0]['delta']['content'] ?? '';
            onResponse(delta);
          } catch (e) {
            // 忽略解析错误
          }
        } else if (line.isNotEmpty) {
          try {
            final data = decodeProviderResponse(line);
            if (data['error'] != null && onError != null) {
              onError!(
                'Code: ${data['error']['code']}, Message: ${data['error']['message']}',
              );
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
  List<String> getSupportedImageSizes() {
    return [
      '512x512',
      '768x768',
      '1024x1024',
      '1536x1536',
      '2048x2048',
      '1024x768',
      '2048x1536',
      '768x1024',
      '1536x2048',
      '1024x576',
      '2048x1152',
      '576x1024',
      '1152x2048',
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
    // 检查模型是否支持图像生成
    if (bot.model.toLowerCase() != 'irag-1.0' &&
        bot.model.toLowerCase() != 'flux.1-schnell') {
      throw UnsupportedError(
        'Model ${bot.model} dont support generate image，please use Stable-Diffusion-XL model',
      );
    }

    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}images/generations'
            : 'https://aistudio.baidu.com/llm/lmapi/v3/images/generations';
    // 准备请求参数
    final Map<String, dynamic> requestBody = {
      'model': bot.model,
      'prompt': prompt,
      'n': 1, // 生成图片数量
      'size': size, // 图片尺寸
      'response_format': 'url', // 返回URL而不是base64
    };

    try {
      final response = await httpPost(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bot.apiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = decodeProviderResponse(utf8.decode(response.bodyBytes));
        final imageUrl = data['data'][0]['url'];
        final imageResponse = await httpGet(Uri.parse(imageUrl));

        if (imageResponse.statusCode == 200) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'cogview_$timestamp.png';
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
