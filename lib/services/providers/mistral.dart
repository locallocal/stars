import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bubble/model/model.dart';
import 'package:bubble/services/providers/providers.dart';

class Mistral extends Provider {
  static const defaultApiModelsUrl = 'https://api.mistral.ai/v1/models';
  Mistral(super.bot);

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
      case 'pixtral-12b-latest':
      case 'pixtral-large-latest':
      case 'mistral-small-latest':
      case 'pixtral-12b-2409':
      case 'pixtral-large-2411':
      case 'mistral-small-2503':
        return [InputModality.text, InputModality.image];
    }
    return [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    return [OutputModality.text];
  }

  @override
  Future<List<String>> listModels() async {
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}models' : defaultApiModelsUrl;

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
  Future<void> sendMessageStream(List<ChatMessage> messages) async {
    await _sendRequest(messages, true);
  }

  Future<String> _sendRequest(List<ChatMessage> messages, bool isStream) async {
    resetCancelState();
    final url = Uri.parse('${bot.baseURL}chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${bot.apiKey}',
    };

    final formattedMessages =
        messages.map((message) {
          if (message.images.isNotEmpty) {
            return processMessagesWithImages([message])[0];
          } else {
            return message.toJson();
          }
        }).toList();

    final body = jsonEncode({
      'model': bot.model,
      'messages': formattedMessages,
      'stream': isStream,
    });

    try {
      if (isStream) {
        final request = http.Request('POST', url);
        request.headers.addAll(headers);
        request.body = body;

        final response = await http.Client().send(request);

        if (response.statusCode != 200) {
          final errorBody = await response.stream.bytesToString();
          final errorMessage = _extractErrorMessage(errorBody);
          onError?.call(errorMessage);
          return errorMessage;
        }

        final stream = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        String fullResponse = '';

        await for (final line in stream) {
          if (isCancelled) {
            break;
          }

          if (line.isEmpty || line.trim() == '') continue;
          if (line.startsWith('data: [DONE]')) continue;

          if (line.startsWith('data: ')) {
            final jsonData = line.substring(6);
            try {
              final data = jsonDecode(jsonData);
              final choices = data['choices'] as List;
              if (choices.isNotEmpty) {
                final delta = choices[0]['delta'];
                if (delta != null && delta.containsKey('content')) {
                  final content = delta['content'] as String;
                  fullResponse += content;
                  onResponse(content);
                }
              }
            } catch (e) {
              print('Parse stream response failed: $e');
            }
          }
        }

        onComplete?.call();
        return fullResponse;
      } else {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode != 200) {
          final errorMessage = _extractErrorMessage(response.body);
          onError?.call(errorMessage);
          return errorMessage;
        }

        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content;
      }
    } catch (e) {
      final errorMessage = 'Send request failed: $e';
      onError?.call(errorMessage);
      return errorMessage;
    }
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      if (data.containsKey('error')) {
        return data['error']['message'] ?? 'Unknown error';
      }
      return 'Request failed: ${data.toString()}';
    } catch (e) {
      return 'Request failed: $responseBody';
    }
  }
}
