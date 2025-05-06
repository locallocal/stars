import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
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

  static const Map<String, String> voiceTypes = {
    '青涩青年音色': 'male-qn-qingse',
    '精英青年音色': 'male-qn-jingying',
    '霸道青年音色': 'male-qn-badao',
    '青年大学生音色': 'male-qn-daxuesheng',
    '少女音色': 'female-shaonv',
    '御姐音色': 'female-yujie',
    '成熟女性音色': 'female-chengshu',
    '甜美女性音色': 'female-tianmei',
    '男性主持人': 'presenter_male',
    '女性主持人': 'presenter_female',
    '男性有声书1': 'audiobook_male_1',
    '男性有声书2': 'audiobook_male_2',
    '女性有声书1': 'audiobook_female_1',
    '女性有声书2': 'audiobook_female_2',
    '青涩青年音色-beta': 'male-qn-qingse-jingpin',
    '精英青年音色-beta': 'male-qn-jingying-jingpin',
    '霸道青年音色-beta': 'male-qn-badao-jingpin',
    '青年大学生音色-beta': 'male-qn-daxuesheng-jingpin',
    '少女音色-beta': 'female-shaonv-jingpin',
    '御姐音色-beta': 'female-yujie-jingpin',
    '成熟女性音色-beta': 'female-chengshu-jingpin',
    '甜美女性音色-beta': 'female-tianmei-jingpin',
    '聪明男童': 'clever_boy',
    '可爱男童': 'cute_boy',
    '萌萌女童': 'lovely_girl',
    '卡通猪小琪': 'cartoon_pig',
    '病娇弟弟': 'bingjiao_didi',
    '俊朗男友': 'junlang_nanyou',
    '纯真学弟': 'chunzhen_xuedi',
    '冷淡学长': 'lengdan_xiongzhang',
    '霸道少爷': 'badao_shaoye',
    '甜心小玲': 'tianxin_xiaoling',
    '俏皮萌妹': 'qiaopi_mengmei',
    '妩媚御姐': 'wumei_yujie',
    '嗲嗲学妹': 'diadia_xuemei',
    '淡雅学姐': 'danya_xuejie',
    'Santa Claus': 'Santa_Claus',
    'Grinch': 'Grinch',
    'Rudolph': 'Rudolph',
    'Arnold': 'Arnold',
    'Charming Santa': 'Charming_Santa',
    'Charming Lady': 'Charming_Lady',
    'Sweet Girl': 'Sweet_Girl',
    'Cute Elf': 'Cute_Elf',
    'Attractive Girl': 'Attractive_Girl',
    'Serene Woman': 'Serene_Woman',
  };

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
  Future<void> generateText(List<ChatMessage> messages) async {
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

  @override
  List<String> getSupportVoicTypes() {
    return voiceTypes.keys.toList();
  }

  @override
  Future<String> generateSpeech(
    String prompt,
    String voiceType,
    String outputDirPath,
  ) async {
    if (voiceType.isEmpty) {
      voiceType = 'male-qn-qingse';
    } else {
      voiceType = voiceTypes[voiceType] ?? voiceType;
    }
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}t2a_v2' : defaultApiSpeechUrl;

    final request =
        http.Request('POST', Uri.parse(url))
          ..headers.addAll({
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer ${bot.apiKey}',
          })
          ..body = jsonEncode({
            'model': bot.model,
            'stream': false,
            'text': prompt,
            'voice_setting': {'voice_id': voiceType},
            'audio_setting': {'format': 'mp3'},
            'output_format': 'hex',
          });
    final response = await request.send();
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'Generate speech failed, ${response.statusCode}, $errorBody',
      );
    }

    final responseBytes = await response.stream.toBytes();
    final data = jsonDecode(utf8.decode(responseBytes));
    if (data['base_resp']['status_code'] != 0) {
      throw Exception(
        'Generate speech failed: ${data['base_resp']['status_msg']}',
      );
    }

    // 解析十六进制字符串为字节数据
    final audioHex = data['data']['audio'];
    final audioBytes = _hexToBytes(audioHex);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'minimax_speech_$timestamp.mp3';
    final filePath = '$outputDirPath/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(audioBytes);
    return filePath;
  }

  // 将十六进制字符串转换为字节数组
  Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }
}
