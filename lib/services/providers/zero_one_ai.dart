import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class ZeroOneAI extends Provider {
  static const String _defaultApiModelsUrl =
      'https://api.lingyiwanwu.com/v1/models';
  static const String _defaultApiChatUrl =
      'https://api.lingyiwanwu.com/v1/chat/completions';

  ZeroOneAI(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    return false;
  }

  @override
  Future<List<String>> listModels() async {
    // yi-lightning
    // yi-vision-v2
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}models' : _defaultApiModelsUrl;

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
            (data['data'] as List)
                .map((model) => model['id'] as String)
                .toList();
        return models;
      } else {
        throw Exception('List models failed: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('List models Timeout, retry later.');
    } catch (e) {
      throw Exception('List models failed: $e');
    }
  }

  @override
  List<OutputModality> getOutputModalites() {
    return [OutputModality.text];
  }

  @override
  List<InputModality> getInputModalites() {
    if (bot.model == 'yi-lightning') {
      return [InputModality.text];
    } else if (bot.model.contains('yi-vision')) {
      return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    try {
      resetCancelState();
      final url =
          bot.baseURL.isNotEmpty
              ? '${bot.baseURL}chat/completions'
              : _defaultApiChatUrl;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      };

      final formattedMessages = processMessagesWithImages(messages);
      final body = jsonEncode({
        'model': bot.model,
        'messages': formattedMessages,
        'stream': true,
      });

      final request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.body = body;
      final streamedResponse = await http.Client().send(request);
      if (streamedResponse.statusCode != 200) {
        final response = await http.Response.fromStream(streamedResponse);
        throw Exception(
          'Send stream message failed: ${response.statusCode} ${response.body}',
        );
      }
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (isCancelled) {
          break;
        }

        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') {
            break;
          }

          try {
            final jsonData = jsonDecode(data);
            final delta = jsonData['choices'][0]['delta'];
            if (delta.containsKey('content')) {
              final content = delta['content'];
              if (content != null && content.isNotEmpty) {
                onResponse(content);
              }
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      }

      if (onComplete != null) {
        onComplete!();
      }
    } catch (e) {
      if (onError != null) {
        onError!(e.toString());
      }
    }
  }
}
