import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/model/model.dart';
import 'package:stars/ui/features/profile/views/profile.dart';
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

      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      await tester.drag(slider, const Offset(160, 0));
      await tester.pump();

      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('theme and language rows share the desktop setting layout', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(_profileHarness());
      await tester.pumpAndSettle();

      final currentTheme = find.text('浅色模式');
      final themeButton = find.ancestor(
        of: currentTheme,
        matching: find.byType(ShadButton),
      );
      final currentLanguage = find.text('简体中文');
      final languageButton = find.ancestor(
        of: currentLanguage,
        matching: find.byType(ShadButton),
      );
      final themeChevron = find.descendant(
        of: themeButton,
        matching: find.byIcon(Icons.chevron_right_rounded),
      );
      final languageChevron = find.descendant(
        of: languageButton,
        matching: find.byIcon(Icons.chevron_right_rounded),
      );

      expect(themeButton, findsOneWidget);
      expect(languageButton, findsOneWidget);
      expect(themeChevron, findsOneWidget);
      expect(languageChevron, findsOneWidget);
      expect(tester.getSize(themeButton), tester.getSize(languageButton));
      expect(
        (tester.getRect(themeButton).left - tester.getRect(languageButton).left)
            .abs(),
        lessThanOrEqualTo(1),
      );
      expect(
        (tester.getRect(themeButton).right -
                tester.getRect(languageButton).right)
            .abs(),
        lessThanOrEqualTo(1),
      );
      expect(
        (tester.getRect(themeChevron).right -
                tester.getRect(languageChevron).right)
            .abs(),
        lessThanOrEqualTo(1),
      );
      expect(
        tester.getRect(currentTheme).right,
        lessThan(tester.getRect(themeChevron).left),
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop section titles match bot detail title size', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(_profileHarness());
      await tester.pumpAndSettle();

      final profileContext = tester.element(find.byType(ProfilePage));
      final sectionTitles = [
        S.of(profileContext).desktopPersonalInformation,
        S.of(profileContext).desktopAppearanceAndLanguage,
        S.of(profileContext).desktopHelpAndSupport,
        S.of(profileContext).desktopAboutAndLegal,
      ];

      for (final title in sectionTitles) {
        final titleText = tester.widget<Text>(find.text(title));
        expect(
          titleText.style?.fontSize,
          DesktopThemeTokens.botFormSectionTitleFontSize,
        );
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop theme row opens provider-style option dialog', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(_profileHarness());
      await tester.pumpAndSettle();

      final currentTheme = find.text('浅色模式');
      final themeButton = find.ancestor(
        of: currentTheme,
        matching: find.byType(ShadButton),
      );
      final options = find.byKey(
        const ValueKey<String>('profile-theme-options'),
      );
      final systemOption = find.byKey(
        const ValueKey<String>('profile-theme-option-system'),
      );
      final lightOption = find.byKey(
        const ValueKey<String>('profile-theme-option-light'),
      );
      final darkOption = find.byKey(
        const ValueKey<String>('profile-theme-option-dark'),
      );

      expect(find.byType(ShadSelect<ThemeMode>), findsNothing);
      expect(find.byType(ShadDialog), findsNothing);
      expect(options, findsNothing);

      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(options, findsOneWidget);
      expect(systemOption, findsOneWidget);
      expect(lightOption, findsOneWidget);
      expect(darkOption, findsOneWidget);
      final optionsContainer = tester.widget<Container>(options);
      expect((optionsContainer.decoration! as BoxDecoration).border, isNull);
      expect(
        find.descendant(of: options, matching: find.byType(MenuItemButton)),
        findsNWidgets(3),
      );

      final optionsRect = tester.getRect(options);
      for (final option in [systemOption, lightOption, darkOption]) {
        final optionRect = tester.getRect(option);
        expect(optionRect.left, closeTo(optionsRect.left, 1));
        expect(optionRect.right, closeTo(optionsRect.right, 1));
      }

      expect(
        find.descendant(
          of: lightOption,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: systemOption,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: systemOption,
          matching: find.byIcon(Icons.brightness_6_rounded),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .getRect(
              find.descendant(
                of: lightOption,
                matching: find.byIcon(Icons.check_rounded),
              ),
            )
            .left,
        greaterThan(tester.getRect(find.text('浅色模式').last).right),
      );

      await tester.tap(darkOption);
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsNothing);
      expect(find.text('深色模式'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop language dialog matches the theme option style', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(_profileHarness());
      await tester.pumpAndSettle();

      final currentLanguage = find.text('简体中文');
      final languageButton = find.ancestor(
        of: currentLanguage,
        matching: find.byType(ShadButton),
      );
      final options = find.byKey(
        const ValueKey<String>('profile-language-options'),
      );
      final chineseOption = find.byKey(
        const ValueKey<String>('profile-language-option-zh_CN'),
      );
      final englishOption = find.byKey(
        const ValueKey<String>('profile-language-option-en_US'),
      );

      expect(find.byType(ShadDialog), findsNothing);
      expect(options, findsNothing);

      await tester.tap(languageButton);
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.byType(ShadRadioGroup<String>), findsNothing);
      expect(options, findsOneWidget);
      expect(chineseOption, findsOneWidget);
      expect(englishOption, findsOneWidget);
      expect(tester.getRect(options).width, closeTo(380, 1));

      final optionsContainer = tester.widget<Container>(options);
      expect((optionsContainer.decoration! as BoxDecoration).border, isNull);
      expect(
        find.descendant(of: options, matching: find.byType(MenuItemButton)),
        findsNWidgets(12),
      );
      expect(
        find.descendant(
          of: chineseOption,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: englishOption,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );

      final optionsRect = tester.getRect(options);
      for (final option in [chineseOption, englishOption]) {
        final optionRect = tester.getRect(option);
        expect(optionRect.left, closeTo(optionsRect.left, 1));
        expect(optionRect.right, closeTo(optionsRect.right, 1));
      }

      await tester.tap(englishOption);
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsNothing);
      expect(find.text('English'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
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
