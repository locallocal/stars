import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/ui/features/chat/views/message_avatar.dart';

import '../../../../support/widget_test_support.dart' show shadHarness;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('renders local sender photos with $brightness theme', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final directory = Directory.systemTemp.createTempSync('stars-avatars-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final user = File(
        'assets/images/profile/avatar.png',
      ).copySync('${directory.path}/user.png');
      final bot = File(
        'assets/images/profile/avatar.png',
      ).copySync('${directory.path}/bot.png');
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        shadHarness(
          brightness: brightness,
          homeBuilder:
              (_) => Scaffold(
                body: Row(
                  children: [
                    MessageAvatar(
                      isCurrentUser: true,
                      name: 'Alice',
                      avatarPath: user.path,
                    ),
                    MessageAvatar(
                      isCurrentUser: false,
                      name: 'Research agent',
                      avatarPath: bot.path,
                    ),
                  ],
                ),
              ),
        ),
      );
      await _settleImages(tester);

      expect(find.byType(ShadAvatar), findsNWidgets(2));
      expect(find.bySemanticsLabel('Alice'), findsOneWidget);
      expect(find.bySemanticsLabel('Research agent'), findsOneWidget);
      for (final entry in [user, bot].indexed) {
        final avatar = find.byType(MessageAvatar).at(entry.$1);
        expect(tester.getSize(avatar), const Size.square(32));
        final photo = tester.widget<Image>(
          find.descendant(of: avatar, matching: find.byType(Image)).first,
        );
        final resized = photo.image as ResizeImage;
        expect((resized.imageProvider as FileImage).file.path, entry.$2.path);
        expect(resized.width, 32);
        final pixels = tester.widget<RawImage>(
          find.descendant(of: avatar, matching: find.byType(RawImage)),
        );
        expect(pixels.image, isNotNull);
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  for (final useShadTheme in [true, false]) {
    testWidgets('missing and corrupt photos fall back (shad: $useShadTheme)', (
      tester,
    ) async {
      final directory = Directory.systemTemp.createTempSync('stars-avatars-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final corrupt = File('${directory.path}/corrupt.png')
        ..writeAsStringSync('invalid image');
      final body = Row(
        children: [
          MessageAvatar(
            isCurrentUser: true,
            name: 'Alice',
            avatarPath: '${directory.path}/missing.png',
          ),
          MessageAvatar(
            isCurrentUser: false,
            name: 'Agent',
            avatarPath: corrupt.path,
            provider: 'Moonshot',
          ),
          const MessageAvatar(
            isCurrentUser: false,
            name: 'Custom agent',
            provider: 'custom',
          ),
        ],
      );
      await tester.pumpWidget(
        useShadTheme
            ? shadHarness(
              brightness: Brightness.light,
              homeBuilder: (_) => Scaffold(body: body),
            )
            : MaterialApp(home: Scaffold(body: body)),
      );
      await _settleImages(tester);

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
      expect(
        tester.widgetList<Image>(find.byType(Image)).any((image) {
          final source = image.image;
          return source is ResizeImage && source.imageProvider is AssetImage;
        }),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _settleImages(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // Let actual file I/O and image decoding progress outside the fake clock.
  for (var attempt = 0; attempt < 10; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}
