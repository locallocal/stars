import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/features/profile/views/profile.dart';
import 'package:stars/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop font reset restores the 14px default', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    Profile? savedProfile;
    try {
      await tester.pumpWidget(
        _profileHarness(
          onProfileSaved: (profile) async => savedProfile = profile,
        ),
      );
      await tester.pumpAndSettle();

      final resetButton = find.widgetWithText(ShadButton, '恢复默认');
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(savedProfile?.fontSize, ProfileDefaults.desktopFontSize);
      expect(find.text('14 px'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

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

  testWidgets('desktop name uses a setting row and keeps the edit dialog', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(_profileHarness());
      await tester.pumpAndSettle();

      final nameButton = find.byKey(
        const ValueKey<String>('profile-name-setting'),
      );
      final themeButton = find.ancestor(
        of: find.text('浅色模式'),
        matching: find.byType(ShadButton),
      );
      final nameChevron = find.descendant(
        of: nameButton,
        matching: find.byIcon(Icons.chevron_right_rounded),
      );

      expect(nameButton, findsOneWidget);
      expect(nameChevron, findsOneWidget);
      expect(find.text('修改名称'), findsNothing);
      expect(
        tester.getRect(nameButton).left,
        closeTo(tester.getRect(themeButton).left, 1),
      );
      expect(
        tester.getRect(nameButton).right,
        closeTo(tester.getRect(themeButton).right, 1),
      );

      await tester.tap(nameButton);
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.text('修改名称'), findsOneWidget);
      expect(find.byType(ShadInput), findsOneWidget);
      _expectDesktopDialogCloseAligned(
        tester,
        dialogKey: 'profile-edit-name-dialog',
        closeKey: 'profile-edit-name-close',
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
        S.of(profileContext).desktopGeneral,
        S.of(profileContext).desktopHelpAndSupport,
        S.of(profileContext).desktopAboutAndLegal,
      ];

      for (final title in sectionTitles) {
        final titleText = tester.widget<Text>(find.text(title));
        expect(
          titleText.style?.fontSize,
          StarsDesktopThemeSpec.botFormSectionTitleFontSize,
        );
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop about dialog groups app and legal information', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(_profileHarness());
      await tester.pumpAndSettle();

      final aboutEntry = find.byKey(const ValueKey<String>('profile-about'));
      await tester.scrollUntilVisible(
        aboutEntry,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(aboutEntry);
      await tester.pumpAndSettle();

      final aboutDialog = find.byKey(
        const ValueKey<String>('profile-about-dialog'),
      );
      final brandCard = find.byKey(
        const ValueKey<String>('profile-about-brand-card'),
      );
      expect(aboutDialog, findsOneWidget);
      expect(find.byType(ShadDialog), findsOneWidget);
      _expectDesktopDialogCloseAligned(
        tester,
        dialogKey: 'profile-about-dialog',
        closeKey: 'profile-about-close',
      );
      expect(brandCard, findsOneWidget);
      expect(
        find.descendant(of: brandCard, matching: find.byType(StarsLogo)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile-about-version')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile-about-user-agreement')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile-about-privacy-policy')),
        findsOneWidget,
      );
      expect(find.text('© ${DateTime.now().year} Stars 团队'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop general setting persists execution status visibility', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    Profile? savedProfile;
    try {
      await tester.pumpWidget(
        _profileHarness(
          onProfileSaved: (profile) async => savedProfile = profile,
        ),
      );
      await tester.pumpAndSettle();

      final generalSection = find.text('通用');
      final switchFinder = find.byKey(
        const ValueKey<String>('profile-show-execution-status-switch'),
      );
      expect(generalSection, findsOneWidget);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<ShadSwitch>(switchFinder).value, isTrue);
      expect(
        tester.getTopLeft(generalSection).dy,
        greaterThan(tester.getTopLeft(find.text('外观与语言')).dy),
      );

      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<ShadSwitch>(switchFinder).value, isFalse);
      expect(savedProfile?.showExecutionStatus, isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('general section shows the application prompt as read only', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    const prompt = '''<stars_application_context>
Application: Stars
</stars_application_context>''';
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _profileHarness(applicationPromptProvider: () => prompt),
      );
      await tester.pumpAndSettle();

      final promptPanel = find.byKey(
        const ValueKey<String>('profile-application-injected-prompt'),
      );
      final promptValue = find.byKey(
        const ValueKey<String>('profile-application-prompt-value'),
      );
      await tester.scrollUntilVisible(
        promptPanel,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(promptValue);
      await tester.pumpAndSettle();

      expect(promptPanel, findsOneWidget);
      expect(promptValue, findsOneWidget);
      expect(find.text('系统提示词'), findsOneWidget);
      expect(find.text('只读'), findsNothing);
      expect(
        find.descendant(
          of: promptPanel,
          matching: find.widgetWithText(SelectableText, prompt),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: promptPanel, matching: find.byType(ShadTextarea)),
        findsNothing,
      );
      expect(
        tester.getSemantics(promptValue),
        matchesSemantics(
          label: '系统提示词',
          value: prompt,
          isTextField: true,
          isReadOnly: true,
        ),
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('system prompt switch persists the injection preference', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    Profile? savedProfile;
    try {
      await tester.pumpWidget(
        _profileHarness(
          onProfileSaved: (profile) async => savedProfile = profile,
        ),
      );
      await tester.pumpAndSettle();

      final promptPanel = find.byKey(
        const ValueKey<String>('profile-application-injected-prompt'),
      );
      final switchFinder = find.byKey(
        const ValueKey<String>('profile-inject-application-prompt-switch'),
      );
      await tester.scrollUntilVisible(
        promptPanel,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<ShadSwitch>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<ShadSwitch>(switchFinder).value, isFalse);
      expect(savedProfile?.injectApplicationPrompt, isFalse);
      expect(
        find.byKey(const ValueKey<String>('profile-application-prompt-value')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop general section opens Skill and MCP pages', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    var skillOpenCount = 0;
    var mcpOpenCount = 0;
    try {
      await tester.pumpWidget(
        _profileHarness(
          onOpenSkillLibrary: () => skillOpenCount += 1,
          onOpenMcpServers: () => mcpOpenCount += 1,
        ),
      );
      await tester.pumpAndSettle();

      final skillEntry = find.byKey(
        const ValueKey<String>('profile-skill-library'),
      );
      final mcpEntry = find.byKey(
        const ValueKey<String>('profile-mcp-servers'),
      );
      final promptPanel = find.byKey(
        const ValueKey<String>('profile-application-injected-prompt'),
      );
      await tester.scrollUntilVisible(
        skillEntry,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(skillEntry, findsOneWidget);
      expect(mcpEntry, findsOneWidget);
      expect(promptPanel, findsOneWidget);
      expect(
        find.descendant(
          of: mcpEntry,
          matching: find.byIcon(Icons.hub_outlined),
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(skillEntry);
      await tester.tap(skillEntry);
      await Scrollable.ensureVisible(tester.element(mcpEntry), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(mcpEntry);

      expect(skillOpenCount, 1);
      expect(mcpOpenCount, 1);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('mobile general section opens Skill and MCP pages', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var skillOpenCount = 0;
    var mcpOpenCount = 0;
    try {
      await tester.pumpWidget(
        _profileHarness(
          onOpenSkillLibrary: () => skillOpenCount += 1,
          onOpenMcpServers: () => mcpOpenCount += 1,
        ),
      );
      await tester.pumpAndSettle();

      final skillEntry = find.byKey(
        const ValueKey<String>('profile-skill-library'),
      );
      final mcpEntry = find.byKey(
        const ValueKey<String>('profile-mcp-servers'),
      );
      final promptPanel = find.byKey(
        const ValueKey<String>('profile-application-injected-prompt'),
      );
      await tester.scrollUntilVisible(
        skillEntry,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(skillEntry, findsOneWidget);
      expect(mcpEntry, findsOneWidget);
      expect(promptPanel, findsOneWidget);

      await tester.ensureVisible(skillEntry);
      await tester.tap(skillEntry);
      await Scrollable.ensureVisible(tester.element(mcpEntry), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(mcpEntry);

      expect(skillOpenCount, 1);
      expect(mcpOpenCount, 1);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('mobile about dialog uses the shared responsive content', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    try {
      await tester.pumpWidget(_profileHarness());
      await tester.pumpAndSettle();

      final aboutEntry = find.byKey(const ValueKey<String>('profile-about'));
      await tester.scrollUntilVisible(
        aboutEntry,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(aboutEntry);
      await tester.pumpAndSettle();
      await tester.tap(aboutEntry);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('profile-about-brand-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile-about-description')),
        findsOneWidget,
      );
      expect(find.text('© ${DateTime.now().year} Stars 团队'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
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
      _expectDesktopDialogCloseAligned(
        tester,
        dialogKey: 'profile-theme-dialog',
        closeKey: 'profile-theme-close',
      );
      expect(options, findsOneWidget);
      expect(systemOption, findsOneWidget);
      expect(lightOption, findsOneWidget);
      expect(darkOption, findsOneWidget);
      final optionsContainer = tester.widget<Container>(options);
      expect((optionsContainer.decoration! as BoxDecoration).border, isNull);
      expect(
        find.descendant(of: options, matching: find.byType(ShadButton)),
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
          matching: find.byIcon(LucideIcons.check),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: systemOption,
          matching: find.byIcon(LucideIcons.check),
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
                matching: find.byIcon(LucideIcons.check),
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
      _expectDesktopDialogCloseAligned(
        tester,
        dialogKey: 'profile-language-dialog',
        closeKey: 'profile-language-close',
      );
      expect(find.byType(ShadRadioGroup<String>), findsNothing);
      expect(options, findsOneWidget);
      expect(chineseOption, findsOneWidget);
      expect(englishOption, findsOneWidget);
      expect(tester.getRect(options).width, closeTo(380, 1));

      final optionsContainer = tester.widget<Container>(options);
      expect((optionsContainer.decoration! as BoxDecoration).border, isNull);
      expect(
        find.descendant(of: options, matching: find.byType(ShadButton)),
        findsNWidgets(12),
      );
      expect(
        find.descendant(
          of: chineseOption,
          matching: find.byIcon(LucideIcons.check),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: englishOption,
          matching: find.byIcon(LucideIcons.check),
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

void _expectDesktopDialogCloseAligned(
  WidgetTester tester, {
  required String dialogKey,
  required String closeKey,
}) {
  final dialog = find.byKey(ValueKey<String>(dialogKey));
  final close = find.byKey(ValueKey<String>(closeKey));
  expect(dialog, findsOneWidget);
  expect(close, findsOneWidget);
  final dialogSurface =
      find.ancestor(of: close, matching: find.byType(Stack)).first;
  expect(tester.getSize(close), const Size.square(44));
  expect(
    find.descendant(of: close, matching: find.byIcon(LucideIcons.x)),
    findsOneWidget,
  );
  expect(
    tester.getRect(dialogSurface).right - tester.getRect(close).right,
    closeTo(8, 0.01),
  );
  expect(
    tester.getRect(close).top - tester.getRect(dialogSurface).top,
    closeTo(12, 0.01),
  );
}

Widget _profileHarness({
  Future<void> Function(Profile profile)? onProfileSaved,
  VoidCallback? onOpenSkillLibrary,
  VoidCallback? onOpenMcpServers,
  String Function()? applicationPromptProvider,
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
                showExecutionStatus: true,
                createTimestamp: DateTime(2026),
                modifyTimestamp: DateTime(2026),
              ),
              onProfileSaved: onProfileSaved ?? (_) async {},
              applicationPromptProvider: applicationPromptProvider,
              onOpenSkillLibrary: onOpenSkillLibrary ?? () {},
              onOpenMcpServers: onOpenMcpServers ?? () {},
            ),
          ),
        ),
  );
}
