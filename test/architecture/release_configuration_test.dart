import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/bot_api_key_cipher.dart';
import 'package:stars/data/services/mcp/secure_mcp_credential_store.dart';
import 'package:stars/domain/models/grounding_metrics.dart';

void main() {
  const applicationId = 'io.github.locallocal.stars';

  test('all platform release identifiers use the Stars application id', () {
    final expectedConfiguration = <String, String>{
      'android/app/build.gradle.kts': applicationId,
      'android/app/src/main/kotlin/io/github/locallocal/stars/MainActivity.kt':
          'package $applicationId',
      'ios/Runner.xcodeproj/project.pbxproj': applicationId,
      'macos/Runner/Configs/AppInfo.xcconfig': applicationId,
      'macos/Runner.xcodeproj/project.pbxproj': applicationId,
      'linux/CMakeLists.txt': applicationId,
      'windows/runner/Runner.rc': '"CompanyName", "locallocal"',
    };

    for (final entry in expectedConfiguration.entries) {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(file.readAsStringSync(), contains(entry.value), reason: entry.key);
    }
  });

  test('template release identifiers cannot return', () {
    const roots = ['android', 'ios', 'macos', 'linux', 'windows', 'lib'];
    const legacyMigrationAllowlist = {
      'lib/data/services/bot_api_key_cipher.dart',
      'lib/data/services/mcp/secure_mcp_credential_store.dart',
    };
    const textFileSuffixes = {
      '.dart',
      '.gradle',
      '.h',
      '.kt',
      '.kts',
      '.plist',
      '.pbxproj',
      '.rc',
      '.xcconfig',
      'CMakeLists.txt',
    };
    for (final root in roots) {
      final files = Directory(
        root,
      ).listSync(recursive: true).whereType<File>().where((file) {
        final path = file.path.replaceAll('\\', '/');
        final parts = path.split('/');
        return !parts.any((part) => part.startsWith('.')) &&
            !parts.contains('build') &&
            textFileSuffixes.any(path.endsWith);
      });
      for (final file in files) {
        final path = file.path.replaceAll('\\', '/');
        if (legacyMigrationAllowlist.contains(path)) continue;
        expect(
          file.readAsStringSync(),
          isNot(contains('com.example')),
          reason: file.path,
        );
      }
    }
  });

  test('secure storage namespaces follow the application id', () {
    expect(
      SecureBotApiKeyCipher.secureStorageAccountName,
      '$applicationId.bot.api-key',
    );
    expect(
      SecureMcpCredentialStore.secureStorageAccountName,
      '$applicationId.mcp.credentials',
    );
  });

  test('Linux runner waits for the first Flutter frame to show its window', () {
    final source = File('linux/runner/my_application.cc').readAsStringSync();

    expect(source, isNot(contains('gtk_widget_show(GTK_WIDGET(window));')));

    final addView = source.indexOf(
      'gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));',
    );
    final connectFirstFrame = source.indexOf(
      'g_signal_connect_swapped(view, "first-frame"',
    );
    final realizeView = source.indexOf('gtk_widget_realize(GTK_WIDGET(view));');
    final registerPlugins = source.indexOf(
      'fl_register_plugins(FL_PLUGIN_REGISTRY(view));',
    );

    expect(addView, isNonNegative);
    expect(connectFirstFrame, greaterThan(addView));
    expect(realizeView, greaterThan(connectFirstFrame));
    expect(registerPlugins, greaterThan(realizeView));
  });

  test('grounding reliability invariants block a release', () {
    final healthy = GroundingMetricsSnapshot({
      GroundingMetricName.unsupportedClaimPass: const {'': 0},
      GroundingMetricName.verifiedEvidenceRequired: const {'': 5},
      GroundingMetricName.verifiedEvidencePersisted: const {'': 5},
      GroundingMetricName.duplicateSideEffect: const {'': 0},
    });
    const gate = GroundingReleaseGate();

    expect(gate.evaluate(healthy).passes, isTrue);
    for (final failing in <GroundingMetricsSnapshot>[
      GroundingMetricsSnapshot({
        GroundingMetricName.unsupportedClaimPass: const {'': 1},
      }),
      GroundingMetricsSnapshot({
        GroundingMetricName.verifiedEvidenceRequired: const {'': 2},
        GroundingMetricName.verifiedEvidencePersisted: const {'': 1},
      }),
      GroundingMetricsSnapshot({
        GroundingMetricName.duplicateSideEffect: const {'': 1},
      }),
    ]) {
      final result = gate.evaluate(failing);
      expect(result.passes, isFalse);
      expect(result.requirePass, throwsStateError);
    }
  });

  test('grounding metrics reject content-bearing categories', () {
    for (final unsafe in const [
      'https://provider.test/path?token=secret',
      'user supplied sentence',
      'authorization:bearer_secret',
      'raw-tool-output!',
    ]) {
      expect(
        () => GroundingMetricDelta(
          name: GroundingMetricName.gateRejection,
          category: unsafe,
        ),
        throwsArgumentError,
      );
    }
  });
}
