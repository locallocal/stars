import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class MiniMax extends Provider {
  static const String defaultApiChatUrl =
      'https://api.minimax.chat/v1/text/chatcompletion_v2';
  static const String defaultApiRealTimeUrl =
      'wss://api.minimax.chat/ws/v1/realtime';
  static const String defaultApiSpeechUrl =
      'https://api.minimax.chat/v1/t2a_v2';
  static const String defaultApiVedionUrl =
      'https://api.minimax.chat/v1/video_generation';
  static const String defaultApiMusicUrl =
      'https://api.minimax.chat/v1/music_generation';
  static const String defaultApiImageUrl =
      'https://api.minimax.chat/v1/image_generation';
  MiniMax(super.bot);

  @override
  bool supportWebSearch() {
    if (bot.model == 'MiniMax-Text-01') {
      return true;
    }
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
    if (bot.model == 'MiniMax-Text-01') {
      return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model) {
      case 'MiniMax-Text-01':
      case 'abab6.5s-chat':
      case 'DeepSeek-R1':
        return [OutputModality.text];
      case 'speech-02-hd':
      case 'speech-02-turbo':
      case 'speech-01-hd':
      case 'speech-01-turbo':
      case 'speech-01-240228':
      case 'speech-01-turbo-240228':
        return [OutputModality.speech];
      case 'T2V-01-Director':
      case 'I2V-01-Director':
      case 'S2V-01':
      case 'I2V-01':
      case 'I2V-01-live':
      case 'T2V-01':
        return [OutputModality.video];
      case 'music-01':
        return [OutputModality.music];
      case 'image-01':
      case 'image-01-live':
        return [OutputModality.image];
    }
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    return const [
      'MiniMax-Text-01',
      'abab6.5s-chat',
      'DeepSeek-R1',
      'speech-02-hd',
      'speech-02-turbo',
      'speech-01-hd',
      'speech-01-turbo',
      'speech-01-240228',
      'speech-01-turbo-240228',
      'T2V-01-Director',
      'I2V-01-Director',
      'S2V-01',
      'I2V-01',
      'I2V-01-live',
      'T2V-01',
      'music-01',
      'image-01',
      'image-01-live',
    ];
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}text/chatcompletion_v2'
              : defaultApiChatUrl;

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': processMessagesWithImages(messages),
              'stream': true,
              if (webSearch)
                'tools': [
                  {'type': 'web_search'},
                ],
            });

      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('${streamedResponse.statusCode}, $errorBody');
      }
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.contains('error')) {
          throw Exception('Send request failed: $line');
        }
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
            if (data['choices'] == null ||
                data['choices'].isEmpty ||
                data['choices'][0]['delta'] == null) {
              continue;
            }
            if (deepThinking) {
              final reasonContent =
                  data['choices'][0]['delta']['reasoning_content'] ?? '';
              if (reasonContent.isNotEmpty && onReasoningResponse != null) {
                onReasoningResponse!(reasonContent);
              }
            }
            final delta = data['choices'][0]['delta']['content'] ?? '';
            if (delta.isNotEmpty) {
              onResponse(delta);
            }
          } catch (e) {
            throw Exception('Parse response failed: $e');
          }
        }
      }

      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('Request cancelled by user');
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
    return ['1:1', '16:9', '4:3', '3:2', '2:3', '3:4', '9:16', '21:9'];
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
    if (!bot.model.toLowerCase().contains('image')) {
      throw UnsupportedError(
        'Model ${bot.model} dont support generate image, please use image model',
      );
    }

    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}image_generation'
            : defaultApiImageUrl;

    // 准备请求参数
    final Map<String, dynamic> requestBody = {
      'model': bot.model,
      'prompt': prompt,
      'aspect_ratio': size,
      'response_format': 'url',
      'n': 1,
    };
    if (style.isNotEmpty) {
      requestBody['style'] = style;
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
        if (data['base_resp']['status_code'] != 0) {
          throw Exception(
            'Generate image failed: ${data['base_resp']['status_msg']}',
          );
        }

        final imageUrl = data['data']['image_urls'][0];
        final imageResponse = await http.get(Uri.parse(imageUrl));
        if (imageResponse.statusCode == 200) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'minimax_image_$timestamp.png';
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
