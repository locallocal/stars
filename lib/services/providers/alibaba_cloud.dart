import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:stars/model/model.dart';
import 'package:stars/services/providers/providers.dart';

class AlibabaCloud extends Provider {
  static const String defaultApiModelUrl =
      'https://dashscope.aliyuncs.com/api/v1/models';
  static const String defaultApiChatUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/chat/completions';
  static const String defaultApiImageUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis';

  AlibabaCloud(super.bot);

  @override
  bool supportWebSearch() {
    switch (bot.model) {
      case 'qwen-max':
      case 'qwen-max-latest':
      case 'qwen-max-2025-01-25':
      case 'qwen-max-0125':
      case 'qwen-max-2024-09-19':
      case 'qwen-max-0919':
      case 'qwen-max-2024-04-28':
      case 'qwen-max-0428':
      case 'qwen-max-2024-04-03':
      case 'qwen-max-0403':
      case 'qwen-max-2024-01-07':
      case 'qwen-max-0107':
      case 'qwen-plus':
      case 'qwen-plus-latest':
      case 'qwen-plus-2025-01-25':
      case 'qwen-plus-0125':
      case 'qwen-plus-2025-01-12':
      case 'qwen-plus-0112':
      case 'qwen-plus-2024-12-20':
      case 'qwen-plus-1220':
      case 'qwen-plus-2024-11-27':
      case 'qwen-plus-1127':
      case 'qwen-plus-2024-11-25':
      case 'qwen-plus-1125':
      case 'qwen-plus-2024-09-19':
      case 'qwen-plus-0919':
      case 'qwen-plus-2024-08-06':
      case 'qwen-plus-0806':
      case 'qwen-plus-2024-07-23':
      case 'qwen-plus-0723':
      case 'qwen-plus-2024-06-24':
      case 'qwen-plus-0624':
      case 'qwen-plus-2024-02-06':
      case 'qwen-plus-0206':
      case 'qwen-turbo':
      case 'qwen-turbo-latest':
      case 'qwen-turbo-2025-02-11':
      case 'qwen-turbo-0211':
      case 'qwen-turbo-2024-11-01':
      case 'qwen-turbo-1101':
      case 'qwen-turbo-2024-09-19':
      case 'qwen-turbo-0919':
      case 'qwen-turbo-2024-06-24':
      case 'qwen-turbo-0624':
      case 'qwen-turbo-2024-02-06':
      case 'qwen-turbo-0206':
        return true;
    }
    return false;
  }

  @override
  bool supportDeepThinking() {
    if (bot.model.contains('deepseek-r1')) {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model) {
      case 'qwen-vl-max':
      case 'qwen-vl-max-latest':
      case 'qwen-vl-max-2025-04-08':
      case 'qwen-vl-max-2025-04-02':
      case 'qwen-vl-max-2025-01-25':
      case 'qwen-vl-max-2024-12-30':
      case 'qwen-vl-max-2024-11-19':
      case 'qwen-vl-max-2024-10-30':
      case 'qwen-vl-max-2024-08-09':
      case 'qwen-vl-max-2024-02-01':
      case 'qwen-vl-max-1030':
      case 'qwen-vl-max-1119':
      case 'qwen-vl-max-1230':
      case 'qwen-vl-plus':
      case 'qwen-vl-plus-latest':
      case 'qwen-vl-plus-2025-01-25':
      case 'qwen-vl-plus-2025-01-02':
      case 'qwen-vl-plus-2024-08-09':
      case 'qwen-vl-plus-2023-12-01':
      case 'qvq-72b-preview':
      case 'qwen2.5-vl-72b-instruct':
      case 'qwen2.5-vl-7b-instruct':
      case 'qwen2.5-vl-3b-instruct':
      case 'qwen2-vl-72b-instruct':
      case 'qwen2-vl-7b-instruct':
      case 'qwen2-vl-2b-instruct':
      case 'qwen-vl-v1':
      case 'qwen-vl-chat-v1':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    switch (bot.model) {
      case 'wanx2.1-t2i-turbo':
      case 'wanx2.1-t2i-plus':
      case 'wanx2.0-t2i-turbo':
      case 'flux-schnell':
      case 'flux-dev':
      case 'flux-merged':
      case 'facechain-finetune':
      case 'wanx-background-generation-v2':
      case 'facechain-generation':
      case 'wordart-texture':
        return [OutputModality.image];
    }
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}models' : defaultApiModelUrl;
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final models =
          (data['data'] as List).map((model) => model['id'] as String).toList();
      if (!models.contains('wanx2.1-t2i-turbo')) {
        models.add('wanx2.1-t2i-turbo');
      }
      if (!models.contains('wanx2.1-t2i-plus')) {
        models.add('wanx2.1-t2i-plus');
      }
      if (!models.contains('wanx2.0-t2i-turbo')) {
        models.add('wanx2.0-t2i-turbo');
      }
      final uniqueModels = models.toSet().toList();
      // 可选：对模型列表进行排序
      uniqueModels.sort();
      return uniqueModels;
    } else {
      throw Exception('List models Failed: ${response.statusCode}');
    }
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
              if (webSearch) 'enable_search': true,
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
            if (data['choices'][0]['delta'].containsKey('reasoning_content')) {
              final reasoning =
                  data['choices'][0]['delta']['reasoning_content'] ?? '';
              if (reasoning.isNotEmpty &&
                  onReasoningResponse != null &&
                  deepThinking) {
                onReasoningResponse!(reasoning);
              }
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
  List<String> getSupportedImageSizes() {
    return const [
      '512x512',
      '768x768',
      '1024x1024',
      '1280x1280',
      '1440x1440',
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
    final newSize = size.replaceAll('x', '*');
    final url = defaultApiImageUrl;
    try {
      // 准备请求参数
      final Map<String, dynamic> requestBody = {
        'model': bot.model,
        'input': {'prompt': prompt},
        "parameters": {'size': newSize, 'n': 1, 'watermark': false},
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'X-DashScope-Async': 'enable',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bot.apiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final pollingId = data['output']['task_id'];
        final pollingUrl =
            'https://dashscope.aliyuncs.com/api/v1/tasks/$pollingId';

        // 轮询获取生成结果
        bool isCompleted = false;
        String? imageUrl;
        // 最多尝试240次，每次间隔500毫秒
        for (int i = 0; i < 240; i++) {
          await Future.delayed(const Duration(milliseconds: 500));

          final resultResponse = await http.get(
            Uri.parse(pollingUrl),
            headers: {'Authorization': 'Bearer ${bot.apiKey}'},
          );

          if (resultResponse.statusCode == 200) {
            final resultData = jsonDecode(
              utf8.decode(resultResponse.bodyBytes),
            );
            final status = resultData['output']['task_status'];

            if (status == 'SUCCEEDED') {
              isCompleted = true;
              imageUrl = resultData['output']['results'][0]['url'];
              break;
            } else if (status == 'FAILED' || status == 'UNKNOWN') {
              final code = resultData['output']['code'];
              final message = resultData['output']['message'];
              throw Exception(
                'Image generation failed: Code: $code Message: $message Status: $status',
              );
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
          final fileName = 'alibaba_cloud_$timestamp.png';
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
