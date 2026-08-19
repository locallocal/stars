import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/features/app/views/stars_app.dart';

void main() {
  testWidgets('desktop startup shell uses the 14px default font size', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(const StartupShell.loading());
      await tester.pump();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      expect(
        Theme.of(scaffoldContext).textTheme.bodyLarge?.fontSize,
        ProfileDefaults.desktopFontSize,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('startup shell uses the platform locale before Profile loads', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.binding.platformDispatcher.localesTestValue = const [
      Locale('en', 'US'),
    ];
    try {
      await tester.pumpWidget(const StartupShell.loading());
      await tester.pump();

      expect(find.text('Starting…'), findsOneWidget);
      expect(find.textContaining('正在启动'), findsNothing);

      await tester.pumpWidget(
        StartupShell.failure(
          error: const AppFailure.storage('database_downgrade_not_supported'),
          onRetry: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Startup failed. Please try again.'), findsOneWidget);
      expect(
        find.text(
          'This database was created by a newer version of Stars. '
          'Update the app before opening it.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    } finally {
      tester.binding.platformDispatcher.clearLocalesTestValue();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('startup shell distinguishes Traditional Chinese', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.binding.platformDispatcher.localesTestValue = const [
      Locale('zh', 'TW'),
    ];
    try {
      await tester.pumpWidget(const StartupShell.loading());
      await tester.pump();
      await tester.pump();

      expect(find.text('正在啟動…'), findsOneWidget);
      expect(find.text('正在启动…'), findsNothing);
    } finally {
      tester.binding.platformDispatcher.clearLocalesTestValue();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
