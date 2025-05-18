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
  static const String defaultApiVideoUrl =
      'https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks';

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
      case 'wan2-1-14b-i2v-250225':
      case 'wan2-1-14b-flf2v-250417':
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

  @override
  List<String> getSupportVideoResolutions() {
    return ['480p', '720p'];
  }

  @override
  List<String> getSupportVideoRatios() {
    final ratios = ['16:9', '4:3', '1:1', '3:4', '9:16', '21:9', '9:21'];
    if (bot.model.contains('wan2-1-14b')) {
      ratios.add('keep_ratio');
    }
    if (bot.model.contains('doubao-seawee')) {
      ratios.add('adaptive');
    }
    if (bot.model.contains('doubao-seedanc')) {
      ratios.add('adaptive');
    }
    return ratios;
  }

  @override
  Future<String> generateVideo(
    String prompt,
    String ratio,
    String outputDirPath,
    List<String> referImages,
  ) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}contents/generations/tasks'
            : defaultApiVideoUrl;
    prompt = '$prompt --wm false';
    if (ratio.isNotEmpty) {
      prompt = '$prompt --rt $ratio';
    }
    final body = {'model': bot.model, 'watermark': false};
    List<Map<String, Object>> content = [
      {'type': 'text', 'text': prompt},
    ];
    if (referImages.isNotEmpty) {
      try {
        final file = File(referImages[0]);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          final base64Image = base64Encode(bytes);
          content.add({
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            'role': 'first_frame',
          });
        }
      } catch (e) {
        throw Exception('Process first image $referImages failed: $e');
      }
      if (referImages.length > 1 && bot.model.contains('wan2-1-14b-flf2v')) {
        try {
          final file = File(referImages[1]);
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            final base64Image = base64Encode(bytes);
            content.add({
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              'role': 'last_frame',
            });
          }
        } catch (e) {
          throw Exception('Process last image $referImages failed: $e');
        }
      }
    }
    body['content'] = content;

    final request =
        http.Request('POST', Uri.parse(url))
          ..headers.addAll({
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer ${bot.apiKey}',
          })
          ..body = jsonEncode(body);

    final response = await request.send();
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'Generate video failed, ${response.statusCode}, $errorBody',
      );
    }
    final responseBytes = await response.stream.toBytes();
    final data = jsonDecode(utf8.decode(responseBytes));

    final videoUrl = await _waitVideoFinished(data['id']);
    return await _downloadVideo(videoUrl, outputDirPath);
  }

  Future<String> _waitVideoFinished(String taskId) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}contents/generations/tasks/$taskId'
            : '$defaultApiVideoUrl/$taskId';

    for (var i = 0; i < 3000; i++) {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${bot.apiKey}',
          'content-type': 'application/json',
        },
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['status'] == 'succeeded') {
        return data['content']['video_url'];
      }
      if (data['status'] == 'failed') {
        throw Exception('视频生成失败: $data');
      }
      if (data['status'] == 'cancelled') {
        throw Exception('视频生成已取消: $data');
      }
      sleep(Duration(milliseconds: 500));
    }
    throw Exception('视频生成超时');
  }

  Future<String> _downloadVideo(String videoUrl, String outputDirPath) async {
    // 下载真正的视频文件
    final videoResponse = await http.get(Uri.parse(videoUrl));
    if (videoResponse.statusCode == 200) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'volcano_engine_video_$timestamp.mp4';
      final filePath = '$outputDirPath/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(videoResponse.bodyBytes);
      // 验证文件大小
      final fileSize = await file.length();
      if (fileSize < 1000) {
        // 如果文件太小，可能不是有效的视频
      }
      return filePath;
    } else {
      throw Exception('从URL下载视频失败: $videoUrl $videoResponse');
    }
  }
}
