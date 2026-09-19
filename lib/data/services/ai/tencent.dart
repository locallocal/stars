import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stars/domain/models/models.dart';
import 'package:stars/data/services/ai/provider_service.dart';

class Tencent extends Provider {
  static const String defaultApiModelsUrl =
      'https://tokenhub.tencentmaas.com/v1/models';
  static const String defaultApiChatUrl =
      'https://tokenhub.tencentmaas.com/v1/chat/completions';

  Tencent(super.bot);

  @override
  bool supportWebSearch() {
    return false;
  }

  @override
  bool supportDeepThinking() {
    // TokenHub model capability metadata is authoritative; old Hunyuan name
    // rules are intentionally not carried into the new platform.
    return false;
  }

  @override
  List<InputModality> getInputModalites() {
    return bot.configuredInputModalities ?? const [InputModality.text];
  }

  @override
  List<OutputModality> getOutputModalites() {
    return bot.configuredOutputModalities ?? const [OutputModality.text];
  }

  @override
  Future<List<AiModelInfo>> fetchModels() async {
    final url =
        bot.baseURL.isNotEmpty ? '${bot.baseURL}models' : defaultApiModelsUrl;
    final response = await httpGet(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${bot.apiKey}',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppFailure.providerRejected('tencent_model_catalog_rejected');
    }
    final data = decodeProviderResponse(utf8.decode(response.bodyBytes));
    return providerModelInfos(data['data']);
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

      final streamedResponse = await sendHttpRequest(request);
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      cancelController?.stream.listen((_) {
        cancelController?.close();
      });

      await for (final line in stream) {
        if (isCancelled) break;
        if (line.contains('error')) {
          final data = decodeProviderResponse(line);
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
            final data = decodeProviderResponse(jsonStr);
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
