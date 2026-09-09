import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/bots/views/bot_skill_settings_dialog.dart';
import 'package:stars/utils/theme.dart';

void main() {
  testWidgets('Skill settings dialog locks and reconciles async changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(520, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness());
    final update = Completer<bool>();
    final dialogFuture = showBotSkillSettingsDialog(
      context: tester.element(
        find.byKey(const ValueKey<String>('skill-settings-host')),
      ),
      skill: _skill,
      embedded: true,
      isEnabled: true,
      isApprovalExempt: false,
      dialogKey: const ValueKey<String>('skill-settings-dialog'),
      closeButtonKey: const ValueKey<String>('skill-settings-close'),
      enabledSwitchKey: const ValueKey<String>('skill-enabled'),
      approvalSwitchKey: const ValueKey<String>('skill-approval'),
      onEnabledChanged: (_) => update.future,
      onApprovalExemptChanged: (value) async => value,
    );
    await tester.pumpAndSettle();

    final enabledSwitch = find.byKey(const ValueKey<String>('skill-enabled'));
    final approvalSwitch = find.byKey(const ValueKey<String>('skill-approval'));
    final details = find.byKey(
      const ValueKey<String>('bot-skill-settings-details'),
    );
    final controls = find.byKey(
      const ValueKey<String>('bot-skill-settings-controls'),
    );

    expect(
      find.byKey(const ValueKey<String>('skill-settings-dialog')),
      findsOneWidget,
    );
    expect(
      tester.getRect(details).bottom,
      lessThan(tester.getRect(controls).top),
    );
    expect(tester.widget<ShadSwitch>(enabledSwitch).value, isTrue);
    expect(tester.widget<ShadSwitch>(approvalSwitch).enabled, isTrue);
    final approvalLeft = tester.getRect(approvalSwitch).left;

    await tester.tap(enabledSwitch);
    await tester.pump();

    expect(tester.widget<ShadSwitch>(enabledSwitch).value, isFalse);
    expect(tester.widget<ShadSwitch>(enabledSwitch).enabled, isFalse);
    expect(tester.widget<ShadSwitch>(approvalSwitch).enabled, isFalse);
    expect(tester.getRect(approvalSwitch).left, closeTo(approvalLeft, 0.01));

    update.complete(true);
    await tester.pumpAndSettle();

    expect(tester.widget<ShadSwitch>(enabledSwitch).value, isTrue);
    expect(tester.widget<ShadSwitch>(enabledSwitch).enabled, isTrue);
    expect(tester.widget<ShadSwitch>(approvalSwitch).enabled, isTrue);

    await tester.tap(
      find.byKey(const ValueKey<String>('skill-settings-close')),
    );
    await tester.pumpAndSettle();
    await dialogFuture;
    expect(
      find.byKey(const ValueKey<String>('skill-settings-dialog')),
      findsNothing,
    );
  });
}

Widget _harness() {
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
              key: ValueKey<String>('skill-settings-host'),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
  );
}

final _skill = SkillDescriptor(
  id: 'user:release-notes',
  name: 'Release notes',
  description: 'Create a concise release summary from repository changes.',
  version: '1.0.0',
  scope: SkillScope.user,
  sourceUri: 'file:///skills/release-notes',
  rootPath: '/skills/release-notes',
  contentDigest: 'digest',
  trustState: SkillTrustState.userReviewed,
  validationStatus: SkillValidationStatus.valid,
  compatibility: '',
  installedAt: DateTime(2026, 9, 9),
  updatedAt: DateTime(2026, 9, 9),
);
