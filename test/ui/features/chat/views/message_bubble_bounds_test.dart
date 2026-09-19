import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/features/chat/views/message_avatar.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/utils/theme.dart';

import '../../../../support/widget_test_support.dart' show shadHarness;

void main() {
  for (final (width, desktop) in [
    (320.0, false),
    (560.0, true),
    (1200.0, true),
  ]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets(
        'message content stays between both avatar columns at $width / $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 1200);
          addTearDown(tester.view.reset);
          final controller = ScrollController();
          addTearDown(controller.dispose);
          final sidePadding =
              desktop ? StarsDesktopThemeSpec.formPagePadding.left : 12.0;
          final rowWidth = math.min(
            width - sidePadding * 2,
            desktop ? StarsDesktopThemeSpec.contentMaxWidth : double.infinity,
          );
          final rowLeft = (width - rowWidth) / 2;
          final avatarSpace = MessageAvatar.size + (desktop ? 12 : 8);
          final left = rowLeft + avatarSpace;
          final right = rowLeft + rowWidth - avatarSpace;

          for (final role in ['user', 'assistant', 'streaming']) {
            final isUser = role == 'user';
            final streaming = role == 'streaming';
            final content = '''
${'这是一段需要在两侧头像之间换行的消息。' * 10}

```dart
final longValue = '${'unbroken_value_' * 20}';
```
''';
            const files = ['/tmp/一份用于验证气泡宽度和头像边界的报告.md'];
            await tester.pumpWidget(
              shadHarness(
                brightness: scale == 1 ? Brightness.light : Brightness.dark,
                homeBuilder:
                    (context) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: Scaffold(
                        body: Column(
                          children: [
                            MessageList(
                              messages:
                                  streaming
                                      ? const []
                                      : [
                                        Message(
                                          messageId: role,
                                          chatId: 'chat-1',
                                          botId: 'bot-1',
                                          senderId: isUser ? 'me' : 'bot-1',
                                          content: content,
                                          files: files,
                                          processInfo: const MessageProcessInfo(
                                            durationMs: 1200,
                                          ),
                                          timestamp: DateTime(2026),
                                        ),
                                      ],
                              scrollController: controller,
                              isDesktop: desktop,
                              currentUserId: 'me',
                              isStreaming: streaming,
                              streamingResponse: streaming ? content : '',
                              streamingFiles: streaming ? files : const [],
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            );
            await tester.pumpAndSettle();
            final avatar = tester.getRect(find.byType(MessageAvatar));
            expect(avatar.size, const Size.square(MessageAvatar.size));
            expect(
              isUser ? avatar.right : avatar.left,
              closeTo(isUser ? rowLeft + rowWidth : rowLeft, .01),
            );
            for (final key in [
              'message-bubble-surface',
              if (!isUser) 'message-file-results',
              if (!isUser && !streaming) 'message-execution',
              if (desktop && !streaming) 'desktop-message-hover-region',
            ]) {
              final finder = find.byKey(ValueKey<String>(key));
              expect(finder, findsOneWidget);
              final rect = tester.getRect(finder);
              expect(
                rect.left,
                greaterThanOrEqualTo(left - .01),
                reason: '$role $key',
              );
              expect(
                rect.right,
                lessThanOrEqualTo(right + .01),
                reason: '$role $key',
              );
            }
            expect(tester.takeException(), isNull, reason: role);
          }
        },
      );
    }
  }
}
