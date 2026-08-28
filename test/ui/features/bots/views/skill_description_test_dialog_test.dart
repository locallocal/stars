import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/bots/views/skill_description_test_dialog.dart';
import 'package:stars/utils/theme.dart';

void main() {
  testWidgets('desktop dialog runs the test and keeps the result visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_desktopHarness());
    final runCompleter = Completer<SkillDescriptionTestResult>();
    SkillDescriptionTestCase? submittedCase;
    final resultFuture = showSkillDescriptionTestDialog(
      context: tester.element(
        find.byKey(const ValueKey<String>('skill-description-test-host')),
      ),
      skill: _skill,
      desktopMode: true,
      onRun: (testCase) {
        submittedCase = testCase;
        return runCompleter.future;
      },
    );
    await tester.pumpAndSettle();

    expect(find.byType(ShadDialog), findsOneWidget);
    expect(find.byType(ShadTextarea), findsOneWidget);
    expect(find.byType(ShadSwitch), findsOneWidget);
    final dialog = find.byKey(
      const ValueKey<String>('skill-description-test-dialog'),
    );
    final close = find.byKey(
      const ValueKey<String>('skill-description-test-close'),
    );
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
    expect(find.text('Release notes'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('skill-description-test-summary')),
      findsOneWidget,
    );

    final runButton = find.byKey(
      const ValueKey<String>('run-skill-description-test'),
    );
    expect(tester.widget<ShadButton>(runButton).enabled, isFalse);

    final input = find.descendant(
      of: find.byKey(const ValueKey<String>('skill-description-test-input')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(input, '  Write release notes  ');
    await tester.pump();
    expect(tester.widget<ShadButton>(runButton).enabled, isTrue);

    final expectationSwitch = find.byKey(
      const ValueKey<String>('skill-description-should-activate'),
    );
    await tester.tap(expectationSwitch);
    await tester.pump();
    expect(tester.widget<ShadSwitch>(expectationSwitch).value, isFalse);

    await tester.tap(runButton);
    await tester.pump();

    expect(dialog, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('skill-description-test-progress')),
      findsOneWidget,
    );
    expect(tester.widget<ShadButton>(runButton).enabled, isFalse);
    expect(submittedCase?.input, 'Write release notes');
    expect(submittedCase?.shouldActivate, isFalse);

    runCompleter.complete(
      SkillDescriptionTestResult(
        testCase: submittedCase!,
        runs: 3,
        activations: 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(dialog, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('skill-description-test-result')),
      findsOneWidget,
    );
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('cancel-skill-description-test')),
    );
    await tester.pumpAndSettle();
    await resultFuture;
    expect(dialog, findsNothing);
  });

  testWidgets('mobile dialog keeps Material controls and fits narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_mobileHarness());
    final resultFuture = showSkillDescriptionTestDialog(
      context: tester.element(
        find.byKey(const ValueKey<String>('skill-description-test-host')),
      ),
      skill: _skill,
      desktopMode: false,
      onRun:
          (_) => throw StateError('The cancelled dialog must not run a test.'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('cancel-skill-description-test')),
    );
    await tester.pumpAndSettle();
    await resultFuture;
  });

  testWidgets('desktop dialog keeps test failures visible', (tester) async {
    tester.view.physicalSize = const Size(900, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_desktopHarness());
    final dialogFuture = showSkillDescriptionTestDialog(
      context: tester.element(
        find.byKey(const ValueKey<String>('skill-description-test-host')),
      ),
      skill: _skill,
      desktopMode: true,
      onRun: (_) => throw StateError('Provider failed.'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('skill-description-test-input')),
        matching: find.byType(EditableText),
      ),
      'Write release notes',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('run-skill-description-test')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('skill-description-test-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('skill-description-test-error')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('cancel-skill-description-test')),
    );
    await tester.pumpAndSettle();
    await dialogFuture;
  });
}

Widget _desktopHarness() {
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
          locale: const Locale('en'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: const Scaffold(
            body: SizedBox(
              key: ValueKey<String>('skill-description-test-host'),
            ),
          ),
        ),
  );
}

Widget _mobileHarness() => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: supportedLocales,
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    S.delegate,
  ],
  home: const Scaffold(
    body: SizedBox(key: ValueKey<String>('skill-description-test-host')),
  ),
);

final _skill = SkillDescriptor(
  id: 'user:release-notes',
  name: 'Release notes',
  description: 'Draft release notes from completed work.',
  version: '1.0.0',
  scope: SkillScope.user,
  sourceUri: 'file:///release-notes',
  rootPath: '/skills/release-notes',
  contentDigest: 'digest',
  trustState: SkillTrustState.userReviewed,
  validationStatus: SkillValidationStatus.valid,
  compatibility: '',
  installedAt: DateTime(2026, 8, 7),
  updatedAt: DateTime(2026, 8, 7),
);
