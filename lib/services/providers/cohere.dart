import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/model/model.dart';

class Cohere extends Provider {
  static const String defaultApiModelKey = 'https://api.cohere.com/v1/models';
  static const String defaultApiChatUrl = 'https://api.cohere.com/v2/chat';
  Cohere(super.bot);

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
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}models' : defaultApiModelKey;
    final uri = Uri.parse(url).replace(queryParameters: {'page_size': '1000'});

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'bearer ${bot.apiKey}',
      },
    );
    print('hhhhhhhhhhhhh');
    print(response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final models =
          (data['models'] as List)
              .map((model) => model['name'] as String)
              .toList();
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
          bot.baseURL.isNotEmpty ? '${bot.baseURL}chat' : defaultApiChatUrl;

      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll({
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'bearer ${bot.apiKey}',
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
            if (data['type' == 'message-start'] ||
                data['type' == 'content-delta']) {
              final delta = data['delta']['message']['content']['text'] ?? '';
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
