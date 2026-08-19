import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/ui/features/chat/views/attachments.dart';

import '../../../../support/widget_test_support.dart';

void main() {
  testWidgets('invalid draft image renders a fallback without throwing', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'stars-invalid-image-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final invalidImage = File('${directory.path}/invalid.png');
    await invalidImage.writeAsString('not an image');

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
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
