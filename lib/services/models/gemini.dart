import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/models/chat_models.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bubble/model/model.dart';

class GeminiChatModel extends ChatModel {
  static const String defaultApiModelKey =
      'https://generativelanguage.googleapis.com/v1beta/openai/models';
  static const String defaultApiChatUrl =
      'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions';

  GeminiChatModel(super.bot) {
    final model = GenerativeModel(model: bot.model, apiKey: bot.apiKey);
    final chat = model.startChat(history: []);
  }

  @override
  bool supportsWebSearch() {
    return false;
  }

  @override
  bool supportsDeepThinking() {
    if (bot.model.toLowerCase().contains('gemini-2.0-flash-thinking')) {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    if (bot.model == 'imagen-3.0-generate-002' ||
        bot.model.contains('imagen')) {
      return [InputModality.text];
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
    if (bot.model == 'imagen-3.0-generate-002' ||
        bot.model.contains('imagen')) {
      return [OutputModality.image];
    } else if (bot.model == 'gemini-2.0-flash' ||
        bot.model == ('gemini-2.0-flash-001')) {
      return [OutputModality.text, OutputModality.image, OutputModality.audio];
    }
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}models' : defaultApiModelKey;

    final response = await http.get(
      Uri.parse('$url?key=${bot.apiKey}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final models = data['models'] as List<dynamic>;
      return models.map((m) => m['id'] as String).toList();
    }
    print('List Models Failed: ${response.statusCode}');
    return const [
      'gemini-2.5-pro-exp-03-25',
      'gemini-2.0-flash',
      'gemini-2.0-flash-001',
      'gemini-2.0-flash-exp',
      'gemini-2.0-flash-thinking-exp-01-21',
      'gemini-2.0-flash-lite',
      'gemini-2.0-flash-lite-001',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash',
      'gemini-1.5-flash-001',
      'gemini-1.5-flash-002',
      'gemini-1.5-flash-8b-latest',
      'gemini-1.5-flash-8b',
      'gemini-1.5-flash-8b-001',
      'gemini-1.5-pro-latest',
      'gemini-1.5-pro',
      'gemini-1.5-pro-001',
      'gemini-1.5-pro-002',
      'imagen-3.0-generate-002',
    ];
  }

  @override
  Future<String> sendMessage(List<ChatMessage> messages) async {
    final url =
        bot.baseURL.isNotEmpty
            ? '${bot.baseURL}/chat/completions'
            : defaultApiChatUrl;

    final geminiMessages =
        messages
            .map(
              (m) => {
                'role': m.role == 'user' ? 'user' : 'model',
                'parts': [
                  {'text': m.content},
                ],
              },
            )
            .toList();

    final response = await http.post(
      Uri.parse('$url?key=${bot.apiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': geminiMessages,
        'generationConfig': {'temperature': 0.7},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Request Failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();

      final response = await sendMessage(messages);
      const chunkSize = 10;
      for (var i = 0; i < response.length; i += chunkSize) {
        // 检查是否已取消
        if (isCancelled) break;

        final end =
            (i + chunkSize < response.length) ? i + chunkSize : response.length;
        final chunk = response.substring(i, end);
        onResponse(chunk);
        await Future.delayed(const Duration(milliseconds: 50));
      }

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
}
