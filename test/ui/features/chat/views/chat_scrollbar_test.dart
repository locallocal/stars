import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/features/chat/views/chat.dart';
import 'package:stars/ui/features/chat/views/message_avatar.dart';
import 'package:stars/ui/features/chat/views/message_input.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/utils/theme.dart';

import '../../../../support/conversation_task_app_harness.dart';
import '../../../../support/conversation_task_acceptance_flow.dart'
    show driveTaskUi;
import '../../../../support/widget_test_support.dart'
    show shadHarness, withDesktopPlatform;

void main() {
  for (final width in [800.0, 1400.0]) {
    testWidgets('chat scrollbar stays at the workspace edge at $width', (
      tester,
    ) async {
      await withDesktopPlatform(() async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 850);
        addTearDown(tester.view.reset);
        final h = ConversationTaskAppHarness();
        await tester.runAsync(() async {
          await h.open();
          await h.messageRepository.upsertMessages([
            for (var index = 0; index < 40; index++)
              Message(
                messageId: 'message-$index',
                chatId: 'chat-1',
                botId: h.bot.id,
                senderId: index.isOdd ? 'me' : h.bot.id,
                content: 'Message $index',
                timestamp: DateTime(2026).add(Duration(seconds: index)),
              ),
          ]);
        });
        addTearDown(h.close);
        await tester.pumpWidget(
          AppScope(
            dependencies: h,
            child: shadHarness(
              brightness: Brightness.dark,
              homeBuilder: (_) => ChatPage(id: 'chat-1', bot: h.bot),
            ),
          ),
        );
        await driveTaskUi(
          tester,
          until: () => find.byType(MessageList).evaluate().isNotEmpty,
        );
        final messageList = find.byType(MessageList);
        final list = tester.widget<BoxScrollView>(
          find.descendant(
            of: messageList,
            matching: find.bySubtype<BoxScrollView>(),
          ),
        );
        final bars = find.descendant(
          of: messageList,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollbar && widget.controller == list.controller,
          ),
        );
        expect(bars, findsOneWidget);
        final barRect = tester.getRect(bars);
        expect(barRect.right, width);
        expect(barRect.left, 0);
        final userAvatar =
            find
                .byWidgetPredicate(
                  (widget) => widget is MessageAvatar && widget.isCurrentUser,
                )
                .first;
        final composerRect = tester.getRect(find.byType(MessageInput));
        expect(
          tester.getRect(userAvatar).right,
          closeTo(composerRect.right, .01),
        );
        expect(
          barRect.right - tester.getRect(userAvatar).right,
          greaterThanOrEqualTo(StarsDesktopThemeSpec.formPagePadding.right),
        );

        expect(list.reverse, isTrue);
        expect(list.controller!.offset, 0);
        await tester.drag(messageList, const Offset(0, 300));
        await tester.pumpAndSettle();
        expect(list.controller!.offset, greaterThan(0));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await driveTaskUi(tester);
      });
    });
  }
}
