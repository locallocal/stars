import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class Xinghe extends Provider {
  static const String defaultApiChatUrl =
      'https://aistudio.baidu.com/llm/lmapi/v3/chat/completions';

  Xinghe(super.bot);

  @override
  bool supportWebSearch() {
    switch (bot.model.toLowerCase()) {
      case 'ernie-4.5-8k-preview':
      case 'ernie-3.5-8k':
      case 'ernie-4.0-8k':
      case 'ernie-4.0-turbo-8k':
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
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model) {
      case 'Stable-Diffusion-XL':
        return [OutputModality.image];
    }
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    return const [
      'ernie-4.5-8k-preview',
      'ernie-3.5-8k',
      'ernie-4.0-8k',
      'ernie-4.0-turbo-8k',
      'ernie-char-8k',
      'ernie-speed-8k',
      'ernie-speed-128k',
      'ernie-tiny-8k',
      'ernie-lite-8k',
      'deepseek-r1',
      'Stable-Diffusion-XL',
    ];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    try {
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/chat/completions'
              : defaultApiChatUrl;

      final Map<String, dynamic> requestBody = {
        'model': bot.model,
        'messages': processMessagesWithImages(messages),
        if (webSearch) 'web_search': {"enable": true, "enable_trace": true},
      };

      // 发送请求
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${bot.apiKey}',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode(requestBody),
        encoding: Encoding.getByName('utf-8'), // 确保请求体使用UTF-8编码
      );

      if (response.statusCode == 200) {
        // 确保使用UTF-8解码响应内容
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(decodedBody);

        if (data['choices'] != null && data['choices'].length > 0) {
          final String content = data['choices'][0]['message']['content'];
          // 再次确保内容是有效的UTF-8字符串
          return content;
        } else {
          return 'Invalid Response Body: ${data['msg'] ?? 'Unknown Error'}';
        }
      } else {
        // 处理HTTP错误
        try {
          // 使用UTF-8解码错误响应
          final String decodedError = utf8.decode(response.bodyBytes);
          Map<String, dynamic> errorData = jsonDecode(decodedError);
          String errorMessage = errorData['msg'] ?? 'Unkown Error';
          return '$errorMessage (${response.statusCode})';
        } catch (e) {
          return 'HTTP: ${response.statusCode}';
        }
      }
    } catch (e) {
      return 'Send Message Failed: $e';
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}/chat/completions'
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

      final streamedResponse = await request.send();
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
            final data = jsonDecode(jsonStr);
            final delta = data['choices'][0]['delta']['content'] ?? '';
            onResponse(delta);
          } catch (e) {
            // 忽略解析错误
          }
        } else if (line.isNotEmpty) {
          try {
            final data = jsonDecode(line);
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
  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath, {
    List<String> referenceImages = const [],
    String style = '',
  }) async {
    // 检查模型是否支持图像生成
    if (bot.model != 'Stable-Diffusion-XL') {
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
