import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class Zhipu extends Provider {
  static const String defaultApiUrl =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  static const String defaultApiImageUrl =
      'https://open.bigmodel.cn/api/paas/v4/images/generations';

  Zhipu(super.bot);

  // 生成JWT令牌
  String _generateToken() {
    final apiKey = bot.apiKey;
    if (apiKey.isEmpty || !apiKey.contains('.')) {
      throw Exception('Invalid API Key format');
    }

    final parts = apiKey.split('.');
    final id = parts[0];
    final secret = parts[1];

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expireTime = now + 3600; // 1小时后过期

    final header = {'alg': 'HS256', 'sign_type': 'SIGN'};
    final payload = {'api_key': id, 'exp': expireTime, 'timestamp': now};

    final headerBase64 = base64Url.encode(utf8.encode(jsonEncode(header)));
    final payloadBase64 = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final message = '$headerBase64.$payloadBase64';
    final hmacSha256 = Hmac(sha256, utf8.encode(secret));
    final signature = hmacSha256.convert(utf8.encode(message)).bytes;
    final signatureBase64 = base64Url.encode(signature);

    return '$message.$signatureBase64';
  }

  @override
  Future<List<String>> listModels() async {
    // 智普AI目前支持的模型
    return const [
      // 推理模型
      'glm-z1-air',
      'glm-z1-airx',
      'glm-z1-flash',
      // 文本模型
      'glm-4-plus',
      'glm-4-air',
      'glm-4-air-250414',
      'glm-4-air-0111',
      'glm-4-airx',
      'glm-4-long',
      'glm-4-flash',
      'glm-4-flash-250414',
      'glm-4-flashx',
      'glm-4-0520',
      'chatglm3-6b',
      // 多模态模型
      'glm-4v-plus-0111',
      'glm-4v-flash',
      // 推理模型
      'glm-zero-preview',
      // 图片模型
      'cogview-4',
      'cogview-4-250304',
      'cogview-3',
      'cogview-3-plus',
      'cogview-3-flash',
      // 视频模型
      'cogvideox',
      'cogvideox-2',
      'cogvideox-flash',
      // 实时语言
      'glm-4-realtime',
      'glm-4-voice',
    ];
  }

  @override
  bool supportWebSearch() {
    if (bot.model.toLowerCase().contains('glm-4-')) {
      return true;
    }
    return false;
  }

  @override
  bool supportDeepThinking() {
    if (bot.model.toLowerCase().contains('glm-zero') ||
        bot.model.toLowerCase().contains('glm-z1')) {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'glm-4v-plus-0111':
      case 'glm-4v-flash':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    if (bot.model.toLowerCase().contains('glm')) {
      return [OutputModality.text];
    } else if (bot.model.toLowerCase().contains('cogview')) {
      return [OutputModality.image];
    } else if (bot.model.toLowerCase().contains('cogvideo')) {
      return [OutputModality.video];
    }
    return [OutputModality.text];
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      // 重置取消状态
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}chat/completions'
              : defaultApiUrl;
      final token = _generateToken();

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': processMessagesWithImages(messages),
              'stream': true,
              if (webSearch)
                'tools': [
                  {
                    'type': 'web_search',
                    'web_search': {'enable': true, 'search_result': true},
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

      var stage = '';
      var thinkingContent = '';
      var hasThinkStart = false;
      var hasThinkEnd = false;
      await for (final line in stream) {
        if (isCancelled) break;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') {
            if (!isCancelled && onComplete != null) {
              onComplete!();
            }
            return;
          }
          try {
            final data = jsonDecode(jsonStr);
            final content = data['choices'][0]['delta']['content'] ?? '';

            // 处理深度思考模式
            if (supportDeepThinking() &&
                (stage == 'thinking' || stage.isEmpty)) {
              thinkingContent += content;
              // 检查是否包含开始标签
              if (!hasThinkStart && thinkingContent.contains('<think>')) {
                stage = 'thinking';
                hasThinkStart = true;
                var thinkPart = '';
                if (content.contains('<think>') && stage.isEmpty) {
                  // 提取<think>后面的内容
                  final startIndex =
                      content.indexOf('<think>') + '<think>'.length;
                  thinkPart = content.substring(startIndex);
                } else {
                  final endIndex =
                      thinkingContent.indexOf('<think>') + '<think>'.length;
                  thinkPart = thinkingContent.substring(endIndex);
                }

                if (deepThinking && onReasoningResponse != null) {
                  onReasoningResponse!(thinkPart);
                }
                thinkingContent = thinkingContent.replaceAll('<think>', '');
                continue; // 跳过正常内容处理
              }

              // 检查是否包含结束标签
              if (hasThinkStart &&
                  !hasThinkEnd &&
                  thinkingContent.contains('</think>')) {
                stage = 'response';
                hasThinkEnd = true;
                // 提取</think>前面的内容
                if (content.contains('</think>')) {
                  final endIndex = content.indexOf('</think>');
                  final thinkPart = content.substring(0, endIndex);

                  if (deepThinking &&
                      onReasoningResponse != null &&
                      thinkPart.isNotEmpty) {
                    onReasoningResponse!(thinkPart);
                  }

                  // 提取</think>后面的内容作为正常响应
                  final responseContent = content.substring(
                    endIndex + '</think>'.length,
                  );
                  if (responseContent.isNotEmpty) {
                    onResponse(responseContent);
                  }
                } else {
                  final endIndex = thinkingContent.indexOf('</think>');
                  // 提取</think>后面的内容作为正常响应
                  final responseContent = thinkingContent.substring(
                    endIndex + '</think>'.length,
                  );
                  if (responseContent.isNotEmpty) {
                    onResponse(responseContent);
                  }
                }
                thinkingContent = thinkingContent.replaceAll('<think>', '');
                continue;
              }
              if (thinkingContent.contains('<')) {
                continue;
              }

              // 处理思考过程中的内容
              if (hasThinkStart && !hasThinkEnd) {
                if (deepThinking && onReasoningResponse != null) {
                  onReasoningResponse!(content);
                }
              }
              continue; // 跳过正常内容处理
            }
            // 处理正常内容
            if (stage == 'response' || !supportDeepThinking()) {
              onResponse(content);
            }
          } catch (e) {
            // 忽略解析错误
            print('Parse response failed: $e');
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
    return [
      '1024x1024',
      '768x1344',
      '864x1152',
      '1344x768',
      '1152x864',
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
    // 检查模型是否支持图像生成
    if (!bot.model.toLowerCase().contains('cogview')) {
      throw UnsupportedError(
        'Model ${bot.model} dont support generate image, please use cogview model',
      );
    }

    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}images/generations'
            : defaultApiImageUrl;

    final token = _generateToken();
    // 准备请求参数
    final Map<String, dynamic> requestBody = {
      'model': bot.model,
      'prompt': prompt,
      'n': 1, // 生成图片数量
      'size': size, // 图片尺寸
      'response_format': 'url', // 返回URL而不是base64
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final imageUrl = data['data'][0]['url'];
        final imageResponse = await http.get(Uri.parse(imageUrl));

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
