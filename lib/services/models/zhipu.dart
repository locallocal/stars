import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/model/model.dart';

class ZhipuChatModel extends ChatModel {
  static const String defaultApiUrl =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';

  ZhipuChatModel(Bot bot) : super(bot);

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
    return [
      // 文本模型
      'glm-4-plus',
      'glm-4-air',
      'glm-4-air-0111',
      'glm-4-airx',
      'glm-4-long',
      'glm-4-flashx',
      'glm-4-flash',
      // 多模态模型
      'glm-4v-plus-0111',
      'glm-4v-flash',
      // 推理模型
      'glm-zero-preview',
      // 图片模型
      'cogview-4-250304',
      'cogview-4',
      'cogview-3-flash',
    ];
  }

  @override
  bool supportsWebSearch() {
    if (bot.model.toLowerCase().contains('glm-4-')) {
      return true;
    }
    return false;
  }

  @override
  bool supportsDeepThinking() {
    if (bot.model.toLowerCase().contains('glm-zero')) {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model.toLowerCase()) {
      case 'glm-4-plus':
      case 'glm-4-air':
      case 'glm-4-air-0111':
      case 'glm-4-airx':
      case 'glm-4-long':
      case 'glm-4-flashx':
      case 'glm-4-flash':
      case 'glm-zero-preview':
        return [InputModality.text];
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
    }
    return [OutputModality.text];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/api/paas/v4/chat/completions'
            : defaultApiUrl;
    final token = _generateToken();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'model': bot.model,
        'messages': _processMessagesWithImages(messages),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception(
        'Send Message Failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      // 重置取消状态
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/api/paas/v4/chat/completions'
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
              'messages': _processMessagesWithImages(messages),
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

  // 处理带有图片的消息
  List<Map<String, dynamic>> _processMessagesWithImages(
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
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            });
          }
        } catch (e) {
          print('处理图片失败: $e');
        }
      }

      return {'role': message.role, 'content': content};
    }).toList();
  }
}
