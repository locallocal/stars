import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/ui/features/chat/views/task_execution_value.dart';

import '../../../../support/widget_test_support.dart' show shadHarness;

void main() {
  testWidgets(
    'copies the complete result and resets feedback for a new value',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      final value = ValueNotifier('exit_code: 0\nstdout:\n你好\nDone.');
      addTearDown(value.dispose);
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (_) => Scaffold(
                body: ValueListenableBuilder(
                  valueListenable: value,
                  builder:
                      (_, text, _) =>
                          TaskExecutionValue(label: '执行结果', value: text),
                ),
              ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ShadButton, '复制'));
      await tester.pump();
      expect(copied, value.value);
      expect(find.text('已复制'), findsOneWidget);
      value.value = 'New output';
      await tester.pump();
      expect(find.text('已复制'), findsNothing);
      expect(find.text('复制'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ShadButton, '复制'));
      await tester.pump();
      expect(copied, 'New output');
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('clipboard failure offers feedback and permits another attempt', (
    tester,
  ) async {
    var fail = true;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData' && fail) {
          throw PlatformException(code: 'unavailable');
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (_) => const Scaffold(
              body: TaskExecutionValue(label: '命令', value: 'flutter test'),
            ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ShadButton, '复制'));
    await tester.pump();
    expect(find.text('复制失败'), findsOneWidget);
    fail = false;
    await tester.tap(find.widgetWithText(ShadButton, '复制失败'));
    await tester.pump();
    expect(find.text('已复制'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('复制'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
