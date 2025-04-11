import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class SenseNova extends Provider {
  static const String defaultApiModelsUrl =
      'https://api.sensenova.cn/v1/llm/models';
  static const String defaultApiChatUrl =
      'https://api.sensenova.cn/v1/llm/chat-completions';

  SenseNova(super.bot);

  @override
  bool supportWebSearch() {
    switch (bot.model) {
      case 'DeepSeek-R1':
      case 'DeepSeek-V3':
      case 'DeepSeek-R1-Distill-Qwen-14B':
      case 'DeepSeek-R1-Distill-Qwen-32B':
      case 'SenseChat-Vision':
        return false;
    }
    return true;
  }

  @override
  bool supportDeepThinking() {
    switch (bot.model) {
      case 'DeepSeek-R1':
      case 'DeepSeek-V3':
      case 'DeepSeek-R1-Distill-Qwen-14B':
      case 'DeepSeek-R1-Distill-Qwen-32B':
        return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model) {
      case 'SenseChat-Vision':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}llm/models'
            : defaultApiModelsUrl;

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
  Future<String> sendMessage(List<ChatMessage> messages) async {
    try {
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}llm/chat-completions'
              : defaultApiChatUrl;

      // 构建请求体 - 腾讯混元API特定格式
      final Map<String, dynamic> requestBody = {
        'model': bot.model,
        'messages': processMessagesWithImages(messages),
        'stream': false,
      };
      if (webSearch) {
        requestBody["plugins"] = {
          "web_search": {"search_enable": true, "result_enable": true},
        };
      }

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

        if (data['data']['choices'] != null &&
            data['data']['choices'].length > 0) {
          final String content = data['choices'][0]['delta'];
          // 再次确保内容是有效的UTF-8字符串
          return content;
        } else {
          return 'Invalid response body: ${data['msg'] ?? 'Unknown error'}';
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
      return 'Send message failed: $e';
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}llm/chat-completions'
              : defaultApiChatUrl;
      var requestBody = {
        'model': bot.model,
        'messages': processMessagesWithImages(messages),
        'stream': true,
      };
      if (webSearch) {
        requestBody['plugins'] = {
          "web_search": {"search_enable": true, "result_enable": true},
        };
      }
      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode(requestBody);

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
            if (deepThinking &&
                data['data']['choices'][0].containsKey('reasoning_content')) {
              final reasoning =
                  data['data']['choices'][0]['reasoning_content'] ?? '';
              if (reasoning.isNotEmpty && onReasoningResponse != null) {
                onReasoningResponse!(reasoning);
              }
              continue;
            }

            final delta = data['data']['choices'][0]['delta'] ?? '';
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
  List<Map<String, dynamic>> processMessagesWithImages(
    List<ChatMessage> messages,
  ) {
    return messages.map((message) {
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
            content.add({'type': 'image_base64', 'image_base64': base64Image});
          }
        } catch (e) {
          print('Process images failed: $e');
        }
      }
      return {'role': message.role, 'content': content};
    }).toList();
  }
}
