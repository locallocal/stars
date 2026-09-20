import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/chat/view_models/model_log_view_model.dart';
import 'package:stars/ui/features/chat/views/model_log_settings.dart';
import 'package:stars/utils/theme.dart';

import '../../../../support/fake_model_log_repository.dart';

void main() {
  for (final platform in [TargetPlatform.linux, TargetPlatform.android]) {
    testWidgets('log controls work and fit on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize =
          platform == TargetPlatform.android
              ? const Size(390, 844)
              : const Size(1200, 900);
      final repository = FakeModelLogRepository();
      String? copied;
      Uri? opened;
      final vm = ModelLogViewModel(
        chatId: 'chat-a',
        repository: repository,
        openDirectory: (uri) async {
          opened = uri;
          return true;
        },
        copyText: (text) async {
          copied = text;
        },
      );
      addTearDown(() async {
        vm.dispose();
        await repository.dispose();
      });
      try {
        await tester.pumpWidget(_harness(vm));
        await tester.pumpAndSettle();
        final control = find.byKey(const ValueKey('model-log-switch'));
        await tester.scrollUntilVisible(
          control,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(repository.settings.enabled, isTrue);
        expect(tester.widget<ShadSwitch>(control).value, isTrue);
        // Explicitly focus the switch: pointer taps do not claim keyboard focus.
        final focusable = tester.widget<ShadFocusable>(
          find
              .descendant(of: control, matching: find.byType(ShadFocusable))
              .first,
        );
        focusable.focusNode!.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(repository.settings.enabled, isFalse);
        final copy = find.byKey(const ValueKey('model-log-copy-path'));
        final path = find.text(repository.settings.directoryPath);
        final copyOpacity = find.ancestor(
          of: copy,
          matching: find.byType(AnimatedOpacity),
        );
        await tester.ensureVisible(copy);
        await tester.pumpAndSettle();
        if (platform == TargetPlatform.linux) {
          expect(tester.widget<AnimatedOpacity>(copyOpacity).opacity, 0);
          final originalPathBounds = tester.getRect(path);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(tester.getCenter(path));
          await tester.pumpAndSettle();
          expect(tester.widget<AnimatedOpacity>(copyOpacity).opacity, 1);
          expect(tester.getRect(path), originalPathBounds);
          await mouse.moveTo(tester.getCenter(copy));
          await tester.pumpAndSettle();
          expect(tester.widget<AnimatedOpacity>(copyOpacity).opacity, 1);
          await mouse.moveTo(Offset.zero);
          await tester.pumpAndSettle();
          expect(tester.widget<AnimatedOpacity>(copyOpacity).opacity, 0);

          // The hidden action remains reachable without a mouse.
          final copyFocusable = tester.widget<ShadFocusable>(
            find.descendant(of: copy, matching: find.byType(ShadFocusable)),
          );
          copyFocusable.focusNode!.requestFocus();
          await tester.pumpAndSettle();
          expect(tester.widget<AnimatedOpacity>(copyOpacity).opacity, 1);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        } else {
          expect(tester.widget<AnimatedOpacity>(copyOpacity).opacity, 1);
          await tester.tap(copy);
        }
        await tester.pumpAndSettle();
        expect(copied, repository.settings.directoryPath);
        expect(find.byIcon(LucideIcons.check), findsOneWidget);
        expect(
          find.byKey(const ValueKey('model-log-open-directory')),
          findsNothing,
        );
        expect(find.text('打开目录'), findsNothing);
        expect(opened, isNull);
        expect(tester.takeException(), isNull);
      } finally {
        tester.view.reset();
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
  testWidgets(
    'switching conversations does not reuse the previous log setting',
    (tester) async {
      final first = FakeModelLogRepository();
      final second = FakeModelLogRepository();
      ModelLogViewModel model(String id, FakeModelLogRepository repository) =>
          ModelLogViewModel(
            chatId: id,
            repository: repository,
            openDirectory: (_) async => true,
            copyText: (_) async {},
          );
      final firstVm = model('first', first);
      final secondVm = model('second', second);
      addTearDown(() async {
        firstVm.dispose();
        secondVm.dispose();
        await first.dispose();
        await second.dispose();
      });
      await tester.pumpWidget(_harness(firstVm));
      await tester.pumpAndSettle();
      final control = find.byKey(const ValueKey('model-log-switch'));
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(first.settings.enabled, isTrue);
      await tester.pumpWidget(_harness(secondVm));
      await tester.pumpAndSettle();
      expect(tester.widget<ShadSwitch>(control).value, isFalse);
      await tester.pumpWidget(_harness(firstVm));
      await tester.pumpAndSettle();
      expect(tester.widget<ShadSwitch>(control).value, isTrue);
      expect(second.settings.enabled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _harness(ModelLogViewModel vm) {
  return ShadApp.custom(
    themeMode: ThemeMode.light,
    theme: buildStarsShadTheme(brightness: Brightness.light, fontSize: 16),
    appBuilder:
        (context) => MaterialApp(
          theme: buildShadMaterialBridgeTheme(context: context, fontSize: 16),
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
            body: SingleChildScrollView(
              child: ModelLogSettingsView(viewModel: vm),
            ),
          ),
        ),
  );
}
