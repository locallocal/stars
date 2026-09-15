import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/features/chat/views/chat.dart';
import 'package:stars/ui/features/chat/views/conversation_tasks_page.dart';
import 'package:stars/ui/features/chat/views/message_input.dart';
import 'package:stars/ui/features/chats/views/chat_list_builder.dart';

import '../../../../support/conversation_task_app_harness.dart';
import '../../../../support/conversation_task_acceptance_flow.dart'
    show driveTaskUi;
import '../../../../support/widget_test_support.dart'
    show shadHarness, withMobilePlatform;

void main() {
  late ConversationTaskAppHarness h;
  setUp(() async {
    h = ConversationTaskAppHarness();
    await h.open();
  });
  tearDown(() => h.close());

  testWidgets(
    'mobile toolbar opens a task page and returns to the preserved draft',
    (tester) async {
      await withMobilePlatform(() async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          AppScope(
            dependencies: h,
            child: shadHarness(
              brightness: Brightness.light,
              homeBuilder: (_) => ChatPage(id: 'chat-1', bot: h.bot),
            ),
          ),
        );
        await driveTaskUi(tester);
        final input = tester.widget<MessageInput>(find.byType(MessageInput));
        input.controller.text = 'Unsent draft';
        final clear = find.byKey(const ValueKey('chat-clear-history'));
        final tasks = find.byKey(const ValueKey('chat-conversation-tasks'));
        expect(
          tester.getCenter(tasks).dx,
          greaterThan(tester.getCenter(clear).dx),
        );
        expect(find.text('查看状态'), findsNothing);
        await tester.tap(tasks);
        await driveTaskUi(tester);
        expect(find.byType(ConversationTasksPage), findsOneWidget);
        expect(
          find.byKey(const ValueKey('conversation-tasks-search')),
          findsOneWidget,
        );
        expect(find.text('当前会话没有任务。'), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await driveTaskUi(
          tester,
          until: () => find.byType(ConversationTasksPage).evaluate().isEmpty,
        );
        expect(find.byType(ConversationTasksPage), findsNothing);
        expect(
          tester
              .widget<MessageInput>(find.byType(MessageInput))
              .controller
              .text,
          'Unsent draft',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await driveTaskUi(tester);
      });
    },
  );

  testWidgets('mobile conversation row opens tasks for that conversation', (
    tester,
  ) async {
    await withMobilePlatform(() async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final chats = await tester.runAsync(() => h.chatRepository.getChats());
      await tester.pumpWidget(
        AppScope(
          dependencies: h,
          child: shadHarness(
            brightness: Brightness.light,
            homeBuilder:
                (_) => Scaffold(
                  body: ChatListBuilder(
                    chatList: chats!,
                    bots: [h.bot],
                    generationRegistry: h.generationRegistry,
                    onChatDeleted: (_) {},
                    onChatSelected: (_, _) {},
                    onDeleteChat: (_) async {},
                  ),
                ),
          ),
        ),
      );
      await driveTaskUi(tester);
      await tester.drag(find.byKey(const Key('chat-1')), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-tasks-chat-1')));
      await driveTaskUi(tester);
      expect(find.byType(ConversationTasksPage), findsOneWidget);
      expect(
        tester
            .widget<ConversationTasksPage>(find.byType(ConversationTasksPage))
            .viewModel
            .chatId,
        'chat-1',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await driveTaskUi(tester);
    });
  });
}
