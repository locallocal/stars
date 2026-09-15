import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/user_profile_scope.dart';
import 'package:stars/ui/features/app/view_models/app_view_model.dart';
import 'package:stars/ui/features/chat/views/chat.dart';
import 'package:stars/ui/features/chat/views/message_avatar.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';

import '../../../../support/conversation_task_app_harness.dart';
import '../../../../support/conversation_task_acceptance_flow.dart'
    show driveTaskUi;
import '../../../../support/foreground_turn_fixtures.dart' show foregroundBot;
import '../../../../support/widget_test_support.dart'
    show shadHarness, withDesktopPlatform, withMobilePlatform;

void main() {
  for (final desktop in [true, false]) {
    testWidgets(
      'sender avatars cover history, task status and streaming (desktop: $desktop)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(desktop ? 900 : 320, 1000);
        addTearDown(tester.view.reset);
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final bot = foregroundBot(provider: 'custom');

        await tester.pumpWidget(
          shadHarness(
            brightness: Brightness.light,
            homeBuilder:
                (_) => Scaffold(
                  body: MediaQuery(
                    data: MediaQueryData(
                      size: tester.view.physicalSize,
                      textScaler: const TextScaler.linear(1.5),
                    ),
                    child: Column(
                      children: [
                        MessageList(
                          messages: [
                            _message('user-message', 'me', '用户的问题，需要智能体帮助解答。'),
                            _message('bot-message', bot.id, '这是智能体回复。'),
                            _message(
                              'task-status',
                              bot.id,
                              '正在处理后台任务。',
                              taskStatus: true,
                            ),
                          ],
                          scrollController: controller,
                          isStreaming: true,
                          streamingResponse: '正在生成新的回复。',
                          currentUserId: 'me',
                          currentUserProfile: _profile(),
                          bot: bot,
                          isDesktop: desktop,
                          showVerificationStatus: false,
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        );
        await tester.pumpAndSettle();

        for (final id in [
          'user-message',
          'bot-message',
          'task-status',
          'streaming-message',
        ]) {
          final row = find.byKey(ValueKey(id));
          final avatar = find.descendant(
            of: row,
            matching: find.byType(MessageAvatar),
          );
          expect(avatar, findsOneWidget);
          final sender = tester.widget<MessageAvatar>(avatar);
          expect(sender.isCurrentUser, id == 'user-message');
          expect(sender.name, id == 'user-message' ? 'Alice' : bot.name);
          final avatarRect = tester.getRect(avatar);
          expect(avatarRect.left, greaterThanOrEqualTo(0));
          expect(
            avatarRect.right,
            lessThanOrEqualTo(tester.view.physicalSize.width),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'open chat reflects saved profile changes (desktop: $desktop)',
      (tester) async {
        final withPlatform = desktop ? withDesktopPlatform : withMobilePlatform;
        await withPlatform(() async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(desktop ? 1000 : 360, 800);
          addTearDown(tester.view.reset);
          final h = ConversationTaskAppHarness();
          await tester.runAsync(() async {
            await h.open();
            await h.messageRepository.upsertMessages([
              _message('user-message', 'me', 'Hello'),
              _message('bot-message', h.bot.id, 'Reply'),
            ]);
          });
          addTearDown(h.close);
          final viewModel = AppViewModel(
            initialProfile: _profile(),
            profileRepository: h.profileRepository,
          );
          addTearDown(viewModel.dispose);
          final chat = ChatPage(id: 'chat-1', bot: h.bot);
          await tester.pumpWidget(
            ListenableBuilder(
              listenable: viewModel,
              builder:
                  (_, _) => AppScope(
                    dependencies: h,
                    child: UserProfileScope(
                      profile: viewModel.profile,
                      child: shadHarness(
                        brightness: Brightness.light,
                        homeBuilder: (_) => chat,
                      ),
                    ),
                  ),
            ),
          );
          await driveTaskUi(
            tester,
            until: () => find.byType(MessageList).evaluate().isNotEmpty,
          );

          MessageAvatar userAvatar() => tester
              .widgetList<MessageAvatar>(find.byType(MessageAvatar))
              .singleWhere((avatar) => avatar.isCurrentUser);
          expect(userAvatar().name, 'Alice');
          expect(
            tester.widget<MessageList>(find.byType(MessageList)).bot,
            same(chat.bot),
          );
          final updated = _profile().copyWith(
            name: 'Updated user',
            avatar: '${h.directory.path}/new-avatar.png',
          );
          await tester.runAsync(
            () => h.profileRepository.updateProfile(updated),
          );
          await driveTaskUi(tester);

          expect(userAvatar().name, updated.name);
          expect(userAvatar().avatarPath, updated.avatar);
          expect(find.text('Hello'), findsOneWidget);
          expect(find.text('Reply'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await driveTaskUi(tester);
        });
      },
    );
  }
}

Profile _profile() => Profile(
  name: 'Alice',
  avatar: '',
  fontSize: 16,
  themeMode: 1,
  language: 'zh_CN',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

Message _message(
  String id,
  String senderId,
  String content, {
  bool taskStatus = false,
}) => Message(
  messageId: id,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: senderId,
  content: content,
  taskMessageKind: taskStatus ? TaskMessageKind.status : null,
  timestamp: DateTime(2026),
);
