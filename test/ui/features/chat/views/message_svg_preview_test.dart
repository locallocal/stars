import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/features/chat/views/local_image_preview.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';

import '../../../../support/widget_test_support.dart';

const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 180">
  <rect width="320" height="180" fill="#ffffff"/>
  <circle cx="160" cy="90" r="60" fill="#4f46e5"/>
</svg>
''';

void main() {
  late Directory directory;
  late File file;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('stars-svg-preview-');
    file = File('${directory.path}/diagram.SVG')..writeAsStringSync(_svg);
  });

  tearDown(() => directory.deleteSync(recursive: true));

  for (final brightness in Brightness.values) {
    for (final size in [const Size(1100, 850), const Size(360, 740)]) {
      testWidgets('SVG file preview fits $size in $brightness', (tester) async {
        await _pumpPreviewLauncher(tester, file.path, size, brightness);
        await tester.tap(find.text('Preview'));
        await _finishImageLoading(tester);

        final dialog = find.byKey(
          const ValueKey<String>('message-local-file-dialog'),
        );
        expect(tester.widget(dialog), isA<ShadDialog>());
        expect(find.text('SVG'), findsOneWidget);
        expect(find.text('diagram.SVG'), findsOneWidget);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(find.byIcon(LucideIcons.imageOff), findsNothing);

        final preview = find.byType(LocalImagePreview);
        final bounds = tester.getRect(preview);
        expect(bounds.width, greaterThan(0));
        expect(bounds.height, greaterThan(0));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(size.width));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(size.height));

        final maximize = find.byKey(
          const ValueKey<String>('message-local-file-maximize'),
        );
        await tester.tap(maximize);
        await tester.pumpAndSettle();
        expect(tester.widget<ShadDialog>(dialog).constraints!.biggest, size);
        expect(find.byType(SvgPicture), findsOneWidget);

        await tester.tap(maximize);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('message-local-file-close-icon')),
        );
        await tester.pumpAndSettle();
        expect(dialog, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'SVG preview zooms with the mouse wheel and keeps vector content',
    (tester) async {
      await _pumpPreviewLauncher(
        tester,
        file.path,
        const Size(1100, 850),
        Brightness.light,
      );
      await tester.tap(find.text('Preview'));
      await _finishImageLoading(tester);

      final viewer = find.byType(InteractiveViewer);
      final transform = find.descendant(
        of: viewer,
        matching: find.byType(Transform),
      );
      final original =
          tester.widget<Transform>(transform.first).transform.clone();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(viewer));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(viewer),
          scrollDelta: const Offset(0, -160),
        ),
      );
      await tester.pump();

      expect(
        tester.widget<Transform>(transform.first).transform.getMaxScaleOnAxis(),
        greaterThan(original.getMaxScaleOnAxis()),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
    },
  );

  for (final missing in [false, true]) {
    testWidgets('SVG errors show a fallback (missing=$missing)', (
      tester,
    ) async {
      if (missing) {
        file.deleteSync();
      } else {
        file.writeAsStringSync('<svg><broken');
      }
      await _pumpPreviewLauncher(
        tester,
        file.path,
        const Size(360, 740),
        Brightness.dark,
      );
      await tester.tap(find.text('Preview'));
      await _finishImageLoading(tester);

      expect(find.byIcon(LucideIcons.imageOff), findsOneWidget);
      final context = tester.element(find.byType(LocalImagePreview));
      expect(
        find.text(
          missing
              ? S.of(context).fileMissing
              : S.of(context).filePreviewUnavailable,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'message SVG thumbnail opens its Shad preview from the keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1100, 850);
      addTearDown(tester.view.reset);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: Column(
                  children: [
                    MessageList(
                      messages: [
                        Message(
                          messageId: 'svg-message',
                          chatId: 'chat',
                          botId: 'bot',
                          senderId: 'user',
                          content: '',
                          images: [file.path],
                          timestamp: DateTime(2026),
                        ),
                      ],
                      scrollController: scrollController,
                      isStreaming: false,
                      streamingResponse: '',
                      currentUserId: 'user',
                      isDesktop: true,
                    ),
                  ],
                ),
              ),
        ),
      );
      await _finishImageLoading(tester);
      final thumbnail = find.byKey(
        ValueKey('message-image-preview-${file.path}'),
      );
      expect(
        find.descendant(of: thumbnail, matching: find.byType(SvgPicture)),
        findsOneWidget,
      );
      final focus = find.descendant(
        of: thumbnail,
        matching: find.byType(ShadFocusable),
      );
      tester.widget<ShadFocusable>(focus).focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _finishImageLoading(tester);

      final dialog = find.byKey(const ValueKey('message-local-file-dialog'));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.byType(SvgPicture)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpPreviewLauncher(
  WidgetTester tester,
  String filePath,
  Size size,
  Brightness brightness,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    shadHarness(
      brightness: brightness,
      homeBuilder:
          (context) => Scaffold(
            body: ShadButton(
              onPressed:
                  () => showLocalFilePreviewDialog(
                    context: context,
                    filePath: filePath,
                  ),
              child: const Text('Preview'),
            ),
          ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _finishImageLoading(WidgetTester tester) async {
  await tester.pump();
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (find.byType(ShadProgress).evaluate().isEmpty) break;
  }
  expect(find.byType(ShadProgress), findsNothing);
  await tester.pumpAndSettle();
}
