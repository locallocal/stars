import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class Jina extends Provider {
  static const String defaultApiChatUrl =
      'https://deepsearch.jina.ai/v1/chat/completions';
  Jina(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    return true;
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
    return const ['jina-deepsearch-v1'];
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
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer ${bot.apiKey}',
            })
            ..body = jsonEncode({
              'model': bot.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'stream': true,
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
              final delta = data['choices'][0]['delta']['content'] ?? '';
              if (data['choices'][0]['delta']['type'] == 'think') {
                if (deepThinking) {
                  onReasoningResponse!(delta);
                }
                continue;
              }
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
