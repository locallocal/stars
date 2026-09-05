import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/ai/provider_transport.dart';

void main() {
  group('withProviderStreamTimeout', () {
    test('uses one total deadline even while events keep arriving', () async {
      final stopwatch = Stopwatch()..start();
      final source = Stream<int>.periodic(
        const Duration(milliseconds: 5),
        (index) => index,
      ).take(100);

      await expectLater(
        withProviderStreamTimeout(
          source,
          const Duration(milliseconds: 60),
        ).drain<void>(),
        throwsA(isA<TimeoutException>()),
      );

      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 300)));
    });

    test('forwards completion before the deadline', () async {
      final values =
          await withProviderStreamTimeout(
            Stream<int>.fromIterable(const [1, 2, 3]),
            const Duration(seconds: 1),
          ).toList();

      expect(values, [1, 2, 3]);
    });
  });
}
