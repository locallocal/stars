import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import '../../support/foreground_turn_fixtures.dart';

void main() {
  test(
    'absent options and persisted empty options identify the same configuration',
    () {
      expect(
        taskProviderConfigurationDigest(foregroundBot()),
        taskProviderConfigurationDigest(foregroundBot(parameters: {})),
      );
    },
  );
  test(
    'option ordering is stable but changed behavior invalidates acceptance',
    () {
      final original = taskProviderConfigurationDigest(
        foregroundBot(
          parameters: {
            'temperature': 0.2,
            'extra': {'a': 1, 'b': 2},
          },
        ),
      );
      expect(
        original,
        taskProviderConfigurationDigest(
          foregroundBot(
            parameters: {
              'extra': {'b': 2, 'a': 1},
              'temperature': 0.2,
            },
          ),
        ),
      );
      expect(
        original,
        isNot(
          taskProviderConfigurationDigest(
            foregroundBot(
              parameters: {
                'temperature': 0.8,
                'extra': {'a': 1, 'b': 2},
              },
            ),
          ),
        ),
      );
      expect(
        original,
        isNot(
          taskProviderConfigurationDigest(
            foregroundBot(model: 'changed-model'),
          ),
        ),
      );
    },
  );
}
