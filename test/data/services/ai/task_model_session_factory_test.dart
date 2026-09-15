import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/ai/task_model_session_factory.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/provider_failure.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';

import '../../../support/foreground_turn_fixtures.dart';

void main() {
  test(
    'matches frozen configuration before opening a fresh provider session',
    () {
      final bot = foregroundBot(
        parameters: {
          'z': 2,
          'a': {'b': 1, 'a': 0},
        },
      );
      final equivalent = foregroundBot(
        parameters: {
          'a': {'a': 0, 'b': 1},
          'z': 2,
        },
      );
      expect(
        taskProviderConfigurationDigest(bot),
        taskProviderConfigurationDigest(equivalent),
      );
      final provider = ForegroundProvider(
        bot,
        events: () => const Stream.empty(),
      );
      final factory = TaskProviderSessionFactory(
        providers: ForegroundProviders((_) => provider),
        bot: bot,
      );
      final acceptance = TaskAcceptanceSnapshot(
        providerId: bot.apiType,
        modelId: bot.model,
        configurationDigest: taskProviderConfigurationDigest(bot),
        language: 'zh-CN',
        context: [
          TaskContextMessage(role: TaskContextRole.user, content: 'accepted'),
        ],
        allowedToolNames: {},
        verification: VerificationPolicySnapshot(
          reliabilityEnabled: true,
          strictGroundingEnabled: true,
          showVerificationStatus: true,
        ),
        segmentLimits: TaskSegmentLimits(),
      );
      final request = ModelRequest(
        messages: [ChatMessage(role: 'user', content: 'accepted')],
      );
      factory.open(acceptance, request).close();
      expect(provider.sessions, hasLength(1));
      bot.parameters!['z'] = 3;
      expect(
        () => factory.open(acceptance, request),
        throwsA(
          isA<ProviderFailure>().having(
            (f) => f.code,
            'code',
            'task_provider_configuration_changed',
          ),
        ),
      );
      expect(provider.sessions, hasLength(1));
    },
  );
}
