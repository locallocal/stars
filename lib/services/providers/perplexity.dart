import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class Perplexity extends Provider {
  static const String defaultApiModelKey = 'https://api.perplexity.ai/models';
  static const String defaultApiChatUrl =
      'https://api.perplexity.ai/chat/completions';
  Perplexity(super.bot);

  @override
  bool supportWebSearch() {
    if (bot.model.toLowerCase() == 'r1-1776') {
      return false;
    }
    return true;
  }

  @override
  bool supportDeepThinking() {
    switch (bot.model.toLowerCase()) {
      case 'sonar-reasoning-pro':
      case 'sonar-reasoning':
      case 'r1-1776':
        return true;
    }
    return false;
  }

  @override
  bool supportDeepResearch() {
    if (bot.model.toLowerCase() == 'sonar-deep-research') {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    // deepseek-chat
    // deepseek-reasoner
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}models' : defaultApiModelKey;

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
      return models;
    } else {
      throw Exception('List models Failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();

      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}chat/completions'
              : defaultApiChatUrl;

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'stream': true,
              'return_images': true,
              if (webSearch)
                'web_search_options': {"search_context_size": "high"},
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
        if (isCancelled) break;
        if (line.isEmpty) continue;

        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr == '[DONE]') {
            // 当收到[DONE]标记时，确保调用onComplete
            if (!isCancelled && onComplete != null) {
              onComplete!();
            }
            return;
          }

          try {
            final data = jsonDecode(jsonStr);
            if (data.containsKey('choices') &&
                data['choices'].isNotEmpty &&
                data['choices'][0].containsKey('delta')) {
              if (deepThinking &&
                  data['choices'][0]['delta'].containsKey(
                    'reasoning_content',
                  )) {
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
            }
          } catch (e) {
            // ignore
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
}
