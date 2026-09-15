import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/services/ai/anthropic.dart';
import 'package:stars/data/services/ai/moonshot.dart';
import 'package:stars/data/services/ai/openai.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/provider_failure.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';

import '../../../support/foreground_turn_fixtures.dart';

void main() {
  for (final kind in ['chat', 'responses', 'anthropic', 'moonshot']) {
    test(
      '$kind honors the task request timeout at the HTTP boundary',
      () async {
        final pending = Completer<http.Response>();
        final client = MockClient((_) => pending.future);
        final bot = foregroundBot(
          provider: kind == 'responses' ? 'OpenAI' : 'provider',
          model: kind == 'responses' ? 'gpt-5.5' : 'test-model',
        );
        final AiProvider provider = switch (kind) {
          'anthropic' => Anthropic(bot, skillToolClient: client),
          'moonshot' => Moonshot(bot, client: client),
          _ => OpenAI(bot, skillToolClient: client),
        };
        final session = provider.openModelSession(
          ModelRequest(
            messages: [ChatMessage(role: 'user', content: 'Continue task')],
            options: const ModelGenerationOptions(
              requestTimeout: Duration(milliseconds: 5),
            ),
          ),
        );
        try {
          final events = await session.start().toList().timeout(
            const Duration(seconds: 2),
          );
          expect(
            events.whereType<ModelTurnFailed>().single.providerFailure!.kind,
            ProviderFailureKind.timeout,
          );
        } finally {
          session.close();
          client.close();
          pending.complete(http.Response('{}', 200));
        }
      },
    );
  }
}
