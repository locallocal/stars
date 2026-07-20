import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/provider_service.dart';
import 'package:stars/domain/models/models.dart';

class Flux extends Provider {
  Flux(super.bot);

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
      case 'flux-pro-1.1':
      case 'flux-pro':
      case 'flux-dev':
      case 'flux-pro-1.1-ultra':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    return [OutputModality.image];
  }

  @override
  Future<List<String>> listModels() async {
    return const ['flux-pro-1.1', 'flux-pro', 'flux-dev', 'flux-pro-1.1-ultra'];
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}

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
    if (referenceImages.length > 1) {
      throw Exception('Flux not support multi images');
    }

    final url = '${bot.baseURL}${bot.model}';
    var width = 1024;
    var height = 1024;
    if (size.contains('x')) {
      width = int.parse(size.split('x')[0]);
      height = int.parse(size.split('x')[1]);
    }
    final Map<String, dynamic> requestBody = {
      'prompt': prompt,
      'output_format': 'png',
    };
    if (referenceImages.isNotEmpty) {
      final file = File(referenceImages[0]);
      final bytes = file.readAsBytesSync();
      final base64Image = base64Encode(bytes);
      requestBody['image_prompt'] = base64Image;
    }
    if (bot.model.toLowerCase() == 'flux-pro-1.1-ultra') {
      var ratio = '16:9';
      if (size.isNotEmpty) {
        ratio = transformRatio(width, height);
      }
      requestBody['raw'] = true;
      requestBody['aspect_ratio'] = ratio;
    } else {
      requestBody['width'] = width;
      requestBody['height'] = height;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'x-key': bot.apiKey},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final pollingUrl = data['polling_url'];

        // 轮询获取生成结果
        bool isCompleted = false;
        String? imageUrl;

        // 最多尝试120次，每次间隔500毫秒
        for (int i = 0; i < 120; i++) {
          await Future.delayed(const Duration(milliseconds: 500));

          final resultResponse = await http.get(
            Uri.parse(pollingUrl),
            headers: {'x-key': bot.apiKey},
          );

          if (resultResponse.statusCode == 200) {
            final resultData = jsonDecode(
              utf8.decode(resultResponse.bodyBytes),
            );
            final status = resultData['status'];

            if (status == 'Ready') {
              isCompleted = true;
              imageUrl = resultData['result']['sample'];
              break;
            } else if (status == 'Error' || status == 'Task not found') {
              throw Exception('Image generation failed: $status');
            }
            // 如果状态是 PENDING 或 RUNNING，继续轮询
          } else {
            throw Exception(
              'Check task status failed: ${resultResponse.statusCode} - ${resultResponse.body}',
            );
          }
        }
        if (!isCompleted || imageUrl == null) {
          throw Exception('Image generation timed out after 60 seconds');
        }

        // 下载生成的图片
        final imageResponse = await http.get(Uri.parse(imageUrl));
        if (imageResponse.statusCode == 200) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'flux_$timestamp.png';
          final filePath = '$imageDirPath/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(imageResponse.bodyBytes);
          return [filePath];
        } else {
          throw Exception('Download image failed: ${imageResponse.statusCode}');
        }
      } else {
        throw Exception(
          'Generate image task failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Generate image failed: $e');
    }
  }
}
