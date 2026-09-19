import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/features/chat/views/message_anchor_rail.dart';
import 'package:stars/ui/features/chat/views/message_avatar.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/utils/theme.dart';

import '../../../../support/widget_test_support.dart' show shadHarness;

Message message(int index, {String? content, List<String> files = const []}) =>
    Message(
      messageId: 'message-$index',
      chatId: 'chat-1',
      botId: 'bot-1',
      senderId: index.isEven ? 'me' : 'bot-1',
      content:
          content ??
          'Message $index ${'A paragraph of variable length. ' * (index % 7)}',
      files: files,
      timestamp: DateTime(2026, 9, 19, 10).add(Duration(minutes: index)),
    );

Widget harness(
  List<Message> messages,
  ScrollController controller, {
  bool desktop = true,
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
  bool streaming = false,
}) => shadHarness(
  brightness: brightness,
  homeBuilder:
      (context) => ShadTheme(
        // The shared harness disables tooltip effects. Exercise the real
        // animation theme here so intermediate-frame failures stay covered.
        data: buildStarsShadTheme(brightness: brightness, fontSize: 16),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: Scaffold(
            body: Column(
              children: [
                MessageList(
                  messages: messages,
                  scrollController: controller,
                  currentUserId: 'me',
                  currentUserProfile: Profile(
                    name: 'Alex',
                    avatar: '',
                    fontSize: 14,
                    themeMode: 0,
                    language: 'en',
                    createTimestamp: DateTime(2026),
                    modifyTimestamp: DateTime(2026),
                  ),
                  isDesktop: desktop,
                  isStreaming: streaming,
                  streamingResponse: streaming ? 'Incoming reply' : '',
                ),
              ],
            ),
          ),
        ),
      ),
);

Finder anchor(int index) =>
    find.byKey(ValueKey('message-anchor-message-$index'));
Finder line(int index) =>
    find.byKey(ValueKey('message-anchor-line-message-$index'));
Finder preview(int index) =>
    find.byKey(ValueKey('message-anchor-preview-message-$index'));

void main() {
  testWidgets('clicked anchors reset when the mouse leaves', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    // No scrolling is needed, so leaving must dismiss the clicked state itself.
    await tester.pumpWidget(harness([message(0), message(1)], controller));
    await tester.pumpAndSettle();
    final idleWidth = tester.getSize(line(0)).width;
    final idleDecoration = tester.widget<AnimatedContainer>(line(0)).decoration;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final target = tester.getCenter(anchor(0));
    await mouse.moveTo(target);
    await tester.pumpAndSettle();
    await mouse.down(target);
    await mouse.up();
    await tester.pumpAndSettle();
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();

    expect(tester.getSize(line(0)).width, idleWidth);
    expect(
      tester.widget<AnimatedContainer>(line(0)).decoration,
      idleDecoration,
    );
    expect(preview(0), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolling dismisses anchors until the next interaction', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final messages = [for (var i = 0; i < 40; i++) message(i)];
    await tester.pumpWidget(harness(messages, controller));
    await tester.pumpAndSettle();
    final idleWidth = tester.getSize(line(12)).width;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(anchor(12)));
    await tester.pumpAndSettle();
    expect(preview(12), findsOneWidget);

    // Scrolling must dismiss even when the pointer remains over the same mark.
    controller.jumpTo(100);
    await tester.pumpAndSettle();
    expect(preview(12), findsNothing);
    expect(tester.getSize(line(12)).width, idleWidth);
    await tester.pumpWidget(
      harness([...messages], controller, streaming: true),
    );
    await tester.pumpAndSettle();
    expect(preview(12), findsNothing);

    await mouse.moveTo(Offset.zero);
    await mouse.moveTo(tester.getCenter(anchor(12)));
    await tester.pumpAndSettle();
    expect(preview(12), findsOneWidget);
    expect(tester.getSize(line(12)).width, greaterThan(idleWidth));
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final reduceMotion in [false, true]) {
    testWidgets(
      'anchor tooltip survives rebuilds during animation (reduced: $reduceMotion)',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final messages = [for (var i = 0; i < 8; i++) message(i)];
        await tester.pumpWidget(
          harness(messages, controller, reduceMotion: reduceMotion),
        );
        await tester.pumpAndSettle();
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(anchor(2)));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          find.byKey(const ValueKey('message-anchor-preview-message-2')),
          findsOneWidget,
        );

        // New stream snapshots rebuild an open tooltip before its fade completes.
        for (var frame = 0; frame < 10; frame++) {
          await tester.pumpWidget(
            harness(
              [...messages],
              controller,
              reduceMotion: reduceMotion,
              streaming: true,
            ),
          );
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            tester.takeException(),
            isNull,
            reason: 'animation frame $frame',
          );
        }
        for (final index in [4, 6, 2]) {
          await mouse.moveTo(tester.getCenter(anchor(index)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.takeException(), isNull);
        }
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [800.0, 1400.0]) {
    testWidgets('anchors fit between the avatars and scrollbar at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 850);
      addTearDown(tester.view.reset);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        harness([for (var i = 0; i < 14; i++) message(i)], controller),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MessageAnchorRail), findsOneWidget);
      for (var i = 0; i < 14; i++) {
        expect(anchor(i), i.isEven ? findsOneWidget : findsNothing);
      }
      final rail = tester.getRect(
        find.byKey(const ValueKey('message-anchor-rail')),
      );
      final avatar = tester.getRect(
        find
            .byWidgetPredicate(
              (widget) => widget is MessageAvatar && widget.isCurrentUser,
            )
            .first,
      );
      expect(rail.left, greaterThanOrEqualTo(avatar.right));
      expect(rail.right, lessThanOrEqualTo(width - 8));
      expect(find.byType(Scrollbar), findsOneWidget);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(anchor(6)));
      await tester.pumpAndSettle();
      final centerWidth = tester.getSize(line(6)).width;
      final neighbourWidth = tester.getSize(line(4)).width;
      final farWidth = tester.getSize(line(0)).width;
      expect(centerWidth, greaterThan(neighbourWidth));
      expect(neighbourWidth, greaterThan(farWidth));
      expect(tester.getSize(line(8)).width, neighbourWidth);
      expect(tester.getRect(line(6)).right, tester.getRect(line(0)).right);
      final preview = find.byKey(
        const ValueKey('message-anchor-preview-message-6'),
      );
      expect(preview, findsOneWidget);
      expect(
        find.descendant(
          of: preview,
          matching: find.textContaining('Message 6'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: preview, matching: find.textContaining('Alex')),
        findsOneWidget,
      );
      expect(tester.getRect(preview).right, lessThan(rail.left));
      await mouse.moveTo(tester.getCenter(anchor(8)));
      await tester.pumpAndSettle();
      expect(preview, findsNothing);
      expect(
        find.byKey(const ValueKey('message-anchor-preview-message-8')),
        findsOneWidget,
      );
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(preview, findsNothing);
      expect(tester.getSize(line(6)).width, farWidth);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'anchors navigate lazy variable-height messages in both directions',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final messages = [
        for (var i = 0; i < 100; i++)
          message(
            i,
            content: i == 40 ? 'A tall message paragraph.\n\n' * 80 : null,
          ),
      ];
      await tester.pumpWidget(harness(messages, controller));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('message-10')), findsNothing);

      for (final target in [10, 80, 40, 0, 98]) {
        await tester.tap(anchor(target));
        await tester.pumpAndSettle();
        final row = find.byKey(ValueKey('message-$target'));
        expect(row, findsOneWidget);
        final rect = tester.getRect(row);
        final viewport = tester.getRect(
          find.byKey(const ValueKey('conversation-messages-scrollbar')),
        );
        expect(rect.top, greaterThanOrEqualTo(viewport.top - 1));
        expect(rect.top, lessThan(viewport.bottom));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('keyboard focus previews attachments and Enter navigates', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(
        [
          message(0, content: '', files: const ['/tmp/launch-plan.md']),
          for (var i = 1; i < 20; i++) message(i),
        ],
        controller,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<ShadButton>(
      find.descendant(of: anchor(0), matching: find.byType(ShadButton)),
    );
    button.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('message-anchor-preview-message-0')),
      findsOneWidget,
    );
    expect(find.text('launch-plan.md'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('message-0')), findsOneWidget);
    expect(preview(0), findsNothing);
    // Dismiss the preview without losing the user's place in keyboard traversal.
    expect(button.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(preview(2), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dense anchors fit without another scroll view and respect reduced motion',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 300);
      addTearDown(tester.view.reset);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        harness(
          [for (var i = 0; i < 200; i++) message(i)],
          controller,
          reduceMotion: true,
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(MessageAnchorRail),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      expect(
        tester.widget<AnimatedContainer>(line(100)).duration,
        Duration.zero,
      );
      final rail = tester.getRect(
        find.byKey(const ValueKey('message-anchor-rail')),
      );
      expect(rail.top, greaterThanOrEqualTo(32));
      expect(rail.bottom, lessThanOrEqualTo(228));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('anchors update across history, streaming and mobile layouts', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness([message(2), message(3)], controller));
    await tester.pumpAndSettle();
    expect(anchor(2), findsOneWidget);
    final focusedButton = tester.widget<ShadButton>(
      find.descendant(of: anchor(2), matching: find.byType(ShadButton)),
    );
    focusedButton.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      harness(
        [for (var i = 0; i < 6; i++) message(i)],
        controller,
        streaming: true,
      ),
    );
    await tester.pumpAndSettle();
    for (final index in [0, 2, 4]) {
      expect(anchor(index), findsOneWidget);
    }
    expect(focusedButton.focusNode!.hasFocus, isTrue);
    expect(
      find.byKey(const ValueKey('message-anchor-streaming-message')),
      findsNothing,
    );
    await tester.pumpWidget(
      harness([message(2), message(3)], controller, desktop: false),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MessageAnchorRail), findsNothing);
    await tester.pumpWidget(harness([message(1)], controller));
    await tester.pumpAndSettle();
    expect(find.byType(MessageAnchorRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new anchor cancels pending navigation and disposal is safe', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness([for (var i = 0; i < 100; i++) message(i)], controller),
    );
    await tester.pumpAndSettle();
    await tester.tap(anchor(0));
    await tester.pump();
    await tester.tap(anchor(98));
    await tester.pumpAndSettle();
    final last = tester.getRect(find.byKey(const ValueKey('message-98')));
    expect(last.top, inInclusiveRange(0, 599));
    await tester.tap(anchor(0));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
