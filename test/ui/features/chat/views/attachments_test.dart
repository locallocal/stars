import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/ui/features/chat/views/attachments.dart';

import '../../../../support/widget_test_support.dart';

void main() {
  testWidgets('invalid draft image renders a fallback without throwing', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-invalid-image-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final invalidImage = File('${directory.path}/invalid.png');
    invalidImage.writeAsStringSync('not an image');

    // Resolve localization before starting FileImage I/O outside the fake clock.
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder: (_) => const Scaffold(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (context) => Scaffold(
                body: ImageAttachments(
                  images: [invalidImage],
                  files: const [],
                  onClearAll: () {},
                  onRemoveImage: (_) {},
                  onRemoveFile: (_) {},
                ),
              ),
        ),
      );
      expect(find.byType(ImageAttachments), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      final failed = Completer<void>();
      final stream = image.image.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (_, _) => failed.completeError(StateError('Invalid image decoded')),
        onError: (Object _, StackTrace? _) => failed.complete(),
      );
      stream.addListener(listener);
      try {
        await failed.future.timeout(const Duration(seconds: 5));
      } finally {
        stream.removeListener(listener);
      }
    });
    await tester.pump();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
