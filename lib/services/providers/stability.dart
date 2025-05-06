import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class Stability extends Provider {
  Stability(super.bot);

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
      case 'ultra':
      case 'sd3-large':
      case 'sd3-large-turbo':
      case 'sd3-medium':
      case 'sd3.5-large':
      case 'sd3.5-large-turbo':
      case 'sd3.5-medium':
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
    return const [
      'ultra',
      'core',
      'sd3-large',
      'sd3-large-turbo',
      'sd3-medium',
      'sd3.5-large',
      'sd3.5-large-turbo',
      'sd3.5-medium',
    ];
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}

  @override
  List<String> getImageStyles() {
    return const [
      '3d-model',
      'analog-film',
      'anime',
      'cinematic',
      'comic-book',
      'digital-art',
      'enhance',
      'fantasy-art',
      'isometric',
      'line-art',
      'low-poly',
      'modeling-compound',
      'neon-punk',
      'origami',
      'photographic',
      'pixel-art',
      'tile-texture',
    ];
  }

  @override
  List<String> getSupportedImageSizes() {
    return ['16:9', '1:1', '21:9', '2:3', '3:2', '4:5', '5:4', '9:16', '9:21'];
  }

  @override
  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath, {
    List<String> referenceImages = const [],
    String style = '',
  }) async {
    var model = bot.model;
    switch (model) {
      case 'sd3-large':
      case 'sd3-large-turbo':
      case 'sd3-medium':
      case 'sd3.5-large':
      case 'sd3.5-large-turbo':
      case 'sd3.5-medium':
        model = 'sd3';
    }
    if (size.isEmpty || size == '1024x1024') {
      size = '1:1';
    }
    final url = '${bot.baseURL}stable-image/generate/$model';
    // 准备请求参数
    final Map<String, dynamic> requestBody = {
      'prompt': prompt,
      'aspect_ratio': size,
      'output_format': 'png',
    };
    if (model == 'sd3') {
      requestBody['model'] = bot.model;
      requestBody['mode'] = 'text-to-image';
    }

    try {
      // 创建一个multipart请求
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // 添加headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Authorization': 'Bearer ${bot.apiKey}',
        'accept': 'application/json',
      });

      // 添加form字段
      requestBody.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // 发送请求并获取响应
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<String> generatedImagePaths = [];

        // 检查响应数据中是否包含图像
        if (responseData.containsKey('finish_reason') &&
            responseData['finish_reason'] == 'SUCCESS') {
          final base64Image = responseData['image'] as String;
          final imageBytes = base64Decode(base64Image);

          // 生成唯一文件名
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '$imageDirPath/stability_$timestamp.png';

          // 写入文件
          final imageFile = File(fileName);
          await imageFile.writeAsBytes(imageBytes);
          generatedImagePaths.add(fileName);
        } else {
          throw Exception(
            'Response not sucess, ${responseData['finish_reason']}',
          );
        }
        return generatedImagePaths;
      } else {
        final errorMessage =
            'Request failed: ${response.statusCode} - ${response.body}';
        onError?.call(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Generate image failed: $e');
    }
  }
}
