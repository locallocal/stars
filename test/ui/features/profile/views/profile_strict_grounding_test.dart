import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/profile/views/profile.dart';
import 'package:stars/utils/theme.dart';

void main() {
  testWidgets('desktop strict mode is accessible, persisted, and restored', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final semantics = tester.ensureSemantics();
    Profile? saved;
    try {
      await tester.pumpWidget(
        _harness(onSaved: (profile) async => saved = profile),
      );
      await tester.pumpAndSettle();

      final control = find.byKey(
        const ValueKey<String>('profile-strict-grounding-switch'),
      );
      await tester.scrollUntilVisible(
        control,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(control, findsOneWidget);
      expect(tester.widget<ShadSwitch>(control).value, isFalse);
      expect(find.bySemanticsLabel(RegExp('严格验证模式')), findsWidgets);

      await tester.tap(control);
      await tester.pumpAndSettle();

      expect(saved?.strictGroundingMode, isTrue);
      expect(tester.widget<ShadSwitch>(control).value, isTrue);

      await tester.pumpWidget(_harness(initialProfile: saved));
      await tester.pumpAndSettle();
      final restored = find.byKey(
        const ValueKey<String>('profile-strict-grounding-switch'),
      );
      await tester.scrollUntilVisible(
        restored,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<ShadSwitch>(restored).value, isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('mobile strict mode control fits a compact layout', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    try {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final control = find.byKey(
        const ValueKey<String>('profile-strict-grounding-switch'),
      );
      await tester.scrollUntilVisible(
        control,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(control, findsOneWidget);
      expect(find.text('严格验证模式'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      tester.view.reset();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

Widget _harness({
  Profile? initialProfile,
  Future<void> Function(Profile profile)? onSaved,
}) {
  final shadTheme = buildStarsShadTheme(
    brightness: Brightness.light,
    fontSize: 16,
  );
  return ShadApp.custom(
    themeMode: ThemeMode.light,
    theme: shadTheme,
    appBuilder:
        (shadContext) => MaterialApp(
          theme: buildShadMaterialBridgeTheme(
            context: shadContext,
            fontSize: 16,
          ),
          locale: const Locale('zh', 'CN'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: Scaffold(
            body: ProfilePage(
              initialProfile: initialProfile ?? _profile(),
              onProfileSaved: onSaved ?? (_) async {},
              onOpenSkillLibrary: () {},
              onOpenMcpServers: () {},
            ),
          ),
        ),
  );
}

Profile _profile() => Profile(
  name: 'Test User',
  avatar: '',
  fontSize: 16,
  themeMode: 1,
  language: 'zh_CN',
  strictGroundingMode: false,
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);
