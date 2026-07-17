import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/profile.dart';
import 'package:stars/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop font slider keeps the semantics tree consistent', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_profileHarness());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      await tester.drag(slider, const Offset(160, 0));
      await tester.pump();

      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

Widget _profileHarness() {
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
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          supportedLocales: supportedLocales,
          locale: const Locale('zh', 'CN'),
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: Scaffold(
            body: ProfilePage(
              initialProfile: Profile(
                name: 'Test User',
                avatar: '',
                fontSize: 16,
                themeMode: 1,
                language: 'zh_CN',
                createTimestamp: DateTime(2026),
                modifyTimestamp: DateTime(2026),
              ),
              onProfileSaved: (_) async {},
            ),
          ),
        ),
  );
}
