import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/ai_hub_mix.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  test('AiHubMix ignores a trailing usage event with empty choices', () async {
    final provider = AiHubMix(
      _bot,
      requestSender:
          (_) async => http.StreamedResponse(
            Stream<List<int>>.value(
              utf8.encode(
                '${_event({
                  'choices': [
                    {
                      'delta': {'content': 'answer'},
                    },
                  ],
                })}'
                '${_event({
                  'id': '',
                  'object': '',
                  'model': '',
                  'choices': <Object>[],
                  'system_fingerprint': '',
                  'usage': {'prompt_tokens': 1656},
                })}'
                'data: [DONE]\n\n',
              ),
            ),
            200,
          ),
    );
    final responses = <String>[];
    final errors = <String>[];
    final terminalEvents = <ProviderTerminalEvent>[];

    provider.setCallbacks(
      onResponse: responses.add,
      onComplete: () {},
      onError: errors.add,
      onTerminal: terminalEvents.add,
    );

    await provider.generateText([ChatMessage(role: 'user', content: 'Hello')]);

    expect(responses, <String>['answer']);
    expect(errors, isEmpty);
    expect(terminalEvents, hasLength(1));
    expect(terminalEvents.single.type, ProviderTerminalType.completed);
  });
}

String _event(Map<String, Object> data) => 'data: ${jsonEncode(data)}\n\n';

final _bot = Bot(
  id: 'bot-1',
  name: 'AiHubMix',
  avatar: '',
  provider: 'AiHubMix',
  baseURL: '',
  apiKey: 'test-key',
  apiType: Bot.apiTypeAiHubMix,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: DateTime.fromMillisecondsSinceEpoch(1),
  modifyTimestamp: DateTime.fromMillisecondsSinceEpoch(1),
);
