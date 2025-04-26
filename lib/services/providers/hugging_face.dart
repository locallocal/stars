import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class HuggingFace extends Provider {
  static const defaultApiModelUrl = '';

  HuggingFace(super.bot);

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
    final model = bot.model.toLowerCase();
    if (model.contains('qwen2-audio')) {
      return [InputModality.text, InputModality.audio];
    } else if (model.contains('llava-1.5-7b-hf') ||
        model.contains('llava-2') ||
        model.contains('qwen2-vl') ||
        model.contains('qwen2.5-vl') ||
        model.contains('ui-tars-1.5') ||
        model.contains('skywork-r1v2') ||
        model.contains('dam-3b') ||
        model.contains('hyperclovax-ssed-vision-instruct') ||
        model.contains('gemma-3-27b-it') ||
        model.contains('llama-4-scout-17b') ||
        model.contains('llama-3.2-11b-vision') ||
        model.contains('mistral-small-3.1-24b-instruct') ||
        model.contains('qvq-72b-preview') ||
        model.contains('llama-4-maverick-17b')) {
      return [InputModality.text, InputModality.image];
    } else if (model.contains('magi-1') || model.contains('skyreels-v2-i2v')) {
      return [InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    final model = bot.model.toLowerCase();
    if (model.contains('flux') ||
        model.contains('stable-diffusion') ||
        model.contains('sdxl-lightning') ||
        model.contains('hyper-sd') ||
        model.contains('sana_sprint') ||
        model.contains('hidream-i1') ||
        model.contains('flex.2') ||
        model.contains('lumina-image-2.0') ||
        model.contains('cogview4') ||
        model.contains('playground-v2.5') ||
        model.contains('pixart-sigma-xl-2') ||
        model.contains('auraflow-v0.2') ||
        model.contains('cogview3-plus') ||
        model.contains('sana_1600m') ||
        model.contains('sana1.5_4.8b') ||
        model.contains('sana-1024')) {
      return [OutputModality.image];
    } else if (model.contains('whisper') ||
        model.contains('dia-1.6b') ||
        model.contains('kokoro-82m') ||
        model.contains('orpheus-3b')) {
      return [OutputModality.speech];
    } else if (model.contains('wan2.1') ||
        model.contains('magi-1') ||
        model.contains('skyreels-v2-i2v') ||
        model.contains('ltx-video') ||
        model.contains('hunyuanvideo') ||
        model.contains('cogvideox') ||
        model.contains('mochi-1')) {
      return [OutputModality.video];
    }
    return [OutputModality.text];
  }

  String _getSubProvider() {
    final uri = Uri.parse(bot.baseURL);
    final pathSegments = uri.pathSegments;

    // 确保路径段不为空
    if (pathSegments.isNotEmpty) {
      // 第一个路径段通常是子提供商名称
      return pathSegments.first;
    }
    return '';
  }

  @override
  Future<List<String>> listModels() async {
    final provider = _getSubProvider();
    final url =
        'https://huggingface.co/api/models?inference_provider=${provider}';

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
            (data as List).map((model) {
              final m = model['id'] as String;
              return m.substring(m.lastIndexOf('/') + 1); // 提取模型名称部分
            }).toList();
        models.sort();
        return models;
      } else {
        throw Exception('List models failed: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('List models timeout, retry later.');
    } catch (e) {
      throw Exception('List models failed: $e');
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();
      final url = '${bot.baseURL}chat/completions';
      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
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
        // 检查是否已取消
        if (isCancelled) break;
        if (line.contains('error')) {
          throw Exception('Response failed, $line}');
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
            final delta = data['choices'][0]['delta']['content'] ?? '';
            onResponse(delta);
          } catch (e) {
            // 忽略解析错误
          }
        }
      }

      // 确保在流处理完成后调用onComplete
      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('请求已取消');
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
    final url = '${bot.baseURL}${bot.model}';
    var width = 1024;
    var height = 1024;
    if (size.contains('x')) {
      width = int.parse(size.split('x')[0]);
      height = int.parse(size.split('x')[1]);
    }
    final Map<String, dynamic> requestBody = {
      'inputs': prompt,
      'parameters': {'width': width, 'height': height},
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'x-key': bot.apiKey},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // 生成唯一文件名
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final imagePath = '$imageDirPath/huggingface_$timestamp.png';
        // 将二进制数据写入文件
        final file = File(imagePath);
        await file.writeAsBytes(response.bodyBytes);
        return [imagePath];
      }
      throw Exception('$response.body');
    } catch (e) {
      throw Exception('Generate image failed: $e');
    }
  }
}
