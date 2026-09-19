import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/provider_service.dart';
import 'package:stars/domain/models/models.dart';

class Gemini extends Provider {
  static const String defaultApiModelKey =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String defaultApiChatUrl =
      'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions';

  Gemini(super.bot);

  @override
  ForegroundRoutingTransport get foregroundRoutingTransport =>
      ForegroundRoutingTransport.bufferedText;

  // The current Gemini implementation uses a single http.post request and
  // cannot abort it or acknowledge cancellation before the response arrives.
  @override
  bool get supportsCancellation => false;

  @override
  bool supportWebSearch() {
    return builtInModelInfo()?.supportsWebSearch ?? false;
  }

  @override
  bool supportDeepThinking() {
    final documented = builtInModelInfo()?.supportsDeepThinking;
    if (documented != null) return documented;
    final model = bot.model.toLowerCase();
    if (model.contains('gemini-2.5-pro') ||
        model.contains('gemini-2.5-flash')) {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    final documented = builtInModelInfo();
    if (documented != null) return documented.inputModalities;
    final model = bot.model.toLowerCase();
    if (model.contains('imagen2') || model.contains('gemma')) {
      return [InputModality.text];
    } else if (model.contains('veo')) {
      return [InputModality.text, InputModality.image];
    }
    return [
      InputModality.text,
      InputModality.image,
      InputModality.audio,
      InputModality.video,
    ];
  }

  @override
  List<OutputModality> getOutputModalites() {
    final model = bot.model.toLowerCase();
    if (model.contains('imagen')) {
      return [OutputModality.image];
    } else if (model.contains('gemini-2.0-flash-lite')) {
      return [OutputModality.text];
    } else if (model.contains('gemini-2.0-flash')) {
      return [OutputModality.multi];
    } else if (model.contains('veo')) {
      return [OutputModality.video];
    }
    return [OutputModality.text];
  }

  @override
  Future<List<AiModelInfo>> fetchModels() async {
    final pageSize = 100;
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}models?pageSize=$pageSize&key=${bot.apiKey}'
            : '$defaultApiModelKey?pageSize=$pageSize&key=${bot.apiKey}';

    final response = await http
        .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = decodeProviderResponse(utf8.decode(response.bodyBytes));
      final models = providerModelInfos(data['models']);
      return models;
    } else {
      throw Exception('Request Failed: ${response.body}');
    }
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
    try {
      resetCancelState();

      await _sendMessage(messages);
      if (!isCancelled && onComplete != null) {
        onComplete!();
      } else if (isCancelled && onError != null) {
        onError!('Request Cancelled');
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

  Future<void> _sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}${bot.model}:generateContent?key=${bot.apiKey}'
            : defaultApiChatUrl;

    final body = _generateGeminiContent(messages);
    final response = await httpPost(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      _processResponse(response);
    } else {
      throw Exception('Request Failed: ${response.body}');
    }
  }

  String _generateGeminiContent(List<ChatMessage> messages) {
    final geminiMessages =
        messages.map((m) {
          // 处理不同类型的消息内容
          final parts = <Map<String, dynamic>>[];

          // 如果消息包含文本内容
          if (m.content.isNotEmpty) {
            parts.add({'text': m.content});
          }

          // 如果消息包含图片
          if (m.images.isNotEmpty) {
            for (final image in m.images) {
              final imageData = _readImage(image);
              parts.add({
                'inline_data': {
                  'mime_type': imageData['mimeType'],
                  'data': imageData['data'],
                },
              });
            }
          }

          // 如果消息包含音频
          /*
          if (m.audio != null && m.audio!.isNotEmpty) {
            parts.add({
              'inline_data': {
                'mime_type': 'audio/mp3', // 根据实际音频格式调整
                'data': m.audio,
              },
            });
          }

          // 如果消息包含视频
          if (m.video != null && m.video!.isNotEmpty) {
            parts.add({
              'inline_data': {
                'mime_type': 'video/mp4', // 根据实际视频格式调整
                'data': m.video,
              },
            });
          }

          // 如果消息包含文件
          if (m.files != null && m.files!.isNotEmpty) {
            for (final file in m.files!) {
              parts.add({
                'file_data': {'mime_type': file.mimeType, 'file_uri': file.uri},
              });
            }
          }
          */
          return {'role': m.role == 'user' ? 'user' : 'model', 'parts': parts};
        }).toList();
    return jsonEncode({
      'contents': geminiMessages,
      if (webSearch)
        'tools': [
          {'google_search': <String, Object>{}},
        ],
      if (supportDeepThinking() && deepThinking)
        'generationConfig': {'thinkingConfig': _thinkingConfig()},
    });
  }

  Map<String, Object> _thinkingConfig() {
    if (bot.model.toLowerCase().contains('gemini-3')) {
      return {'thinkingLevel': 'high', 'includeThoughts': true};
    }
    return {'thinkingBudget': 1024, 'includeThoughts': true};
  }

  Map<String, String> _readImage(String imagePath) {
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        final base64Image = base64Encode(bytes);
        final imageType = getImageMediaType(bytes);
        return {'data': base64Image, 'mimeType': imageType};
      }
    } catch (e) {
      throw Exception('Process image $imagePath failed: $e');
    }
    return {'data': '', 'mimeType': ''};
  }

  String _processResponse(http.Response response) {
    final data = decodeProviderResponse(utf8.decode(response.bodyBytes));
    if (data['candidates'] != null && data['candidates'].isEmpty) {
      throw Exception('No response content found');
    }
    for (final part in data['candidates'][0]['content']['parts']) {
      final text = part['text'];
      if (text != null && text.isNotEmpty) {
        if (part['thought'] == true &&
            deepThinking &&
            onReasoningResponse != null) {
          onReasoningResponse!(text);
        } else if (part['thought'] != true) {
          onResponse(text);
        }
      }
      final inlineData = part['inlineData'] ?? {};
      if (inlineData.isNotEmpty && inlineData['data'].isNotEmpty) {
        try {
          final String mimeType = inlineData['mime_type'] ?? '';
          final String base64Data = inlineData['data'];

          if (mimeType.startsWith('image/')) {
            final String markdownImage =
                '\n![Generated Image](data:$mimeType;base64,$base64Data)\n';
            onResponse(markdownImage);
          }
        } catch (e) {
          if (onError != null) {
            onError!('Process Output Image Failed, ${e.toString()}');
          }
        }
      }
    }

    return data['candidates'][0]['content']['parts'][0]['text'];
  }
}
