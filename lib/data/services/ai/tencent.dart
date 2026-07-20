import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stars/domain/models/models.dart';
import 'package:stars/data/services/ai/provider_service.dart';

class Tencent extends Provider {
  static const String defaultApiChatUrl =
      'https://api.hunyuan.cloud.tencent.com/v1/chat/completions';

  Tencent(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    if (bot.model.startsWith('hunyuan-t1')) {
      return true;
    }
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    switch (bot.model) {
      case 'hunyuan-turbos-vision':
      case 'hunyuan-standard-vision':
      case 'hunyuan-lite-vision':
      case 'hunyuan-turbo-vision':
      case 'hunyuan-vision':
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
    // 腾讯混元目前支持的模型列表
    return const [
      'hunyuan-t1-latest',
      'hunyuan-t1-20250403',
      'hunyuan-t1-20250321',
      'hunyuan-turbos-latest',
      'hunyuan-turbos-20250313',
      'hunyuan-turbos-20250226',
      'hunyuan-turbos-longtext-128k-20250325',
      'hunyuan-turbo-latest',
      'hunyuan-turbo',
      'hunyuan-turbo-20241223',
      'hunyuan-large',
      'hunyuan-large-longcontext',
      'hunyuan-standard-256K',
      'hunyuan-standard',
      'hunyuan-lite',
      'hunyuan-turbos-vision',
      'hunyuan-standard-vision',
      'hunyuan-lite-vision',
      'hunyuan-turbo-vision',
      'hunyuan-vision',
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
        if (isCancelled) break;
        if (line.contains('error')) {
          final data = jsonDecode(line);
          throw Exception(
            'Code: ${data['error']['code']}, Message: ${data['error']['message']}',
          );
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
            if (data['choices'][0]['delta'].containsKey('reasoning_content')) {
              final reasoning =
                  data['choices'][0]['delta']['reasoning_content'] ?? '';
              if (reasoning.isNotEmpty &&
                  onReasoningResponse != null &&
                  deepThinking) {
                onReasoningResponse!(reasoning);
              }
            }
            final delta = data['choices'][0]['delta']['content'] ?? '';
            if (delta.isNotEmpty) {
              onResponse(delta);
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
