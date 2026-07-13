import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stars/services/providers/providers.dart';
import 'package:stars/model/model.dart';

class BaiChuan extends Provider {
  static const String defaultApiChatUrl =
      'https://api.baichuan-ai.com/v1/chat/completions';

  BaiChuan(super.bot);

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
    return const [
      'Baichuan4-Turbo',
      'Baichuan4-Air',
      'Baichuan4',
      'Baichuan3-Turbo',
      'Baichuan3-Turbo-128k',
      'Baichuan2-Turbo',
    ];
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
              if (webSearch)
                'web_search': {"enable": true, "enable_trace": true},
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
        if (line.startsWith('data:')) {
          final jsonStr = line.substring(5);
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
        } else if (line.isNotEmpty) {
          try {
            final data = jsonDecode(line);
            if (data['error'] != null && onError != null) {
              onError!(
                'Code: ${data['error']['code']}, Message: ${data['error']['message']}',
              );
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
}
