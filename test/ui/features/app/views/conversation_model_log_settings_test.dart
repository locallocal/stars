import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/model_log_repository.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/features/app/views/desktop_layout.dart';
import 'package:stars/ui/features/chat/view_models/model_log_view_model.dart';
import 'package:stars/ui/features/chat/views/model_log_settings.dart';

import '../../../../support/conversation_task_acceptance_flow.dart'
    show driveTaskUi;
import '../../../../support/conversation_task_app_harness.dart';
import '../../../../support/fake_model_log_repository.dart';
import '../../../../support/widget_test_support.dart'
    show shadHarness, withDesktopPlatform;

void main() {
  late ConversationTaskAppHarness harness;
  late Map<String, FakeModelLogRepository> logs;

  setUp(() async {
    harness = ConversationTaskAppHarness();
    await harness.open();
    final now = harness.clock.now();
    await harness.local.insertChat(
      ChatRecord.fromDomain(
        Chat(
          id: 'chat-2',
          botId: harness.bot.id,
          lastMessageTimestamp: now,
          createTimestamp: now,
          modifyTimestamp: now,
        ),
      ).values,
    );
    logs = {
      for (final id in ['chat-1', 'chat-2'])
        id:
            FakeModelLogRepository()
              ..settings = ModelLogSettings(
                enabled: false,
                directoryPath: '/logs/conversations/$id',
              ),
    };
    harness.modelLogViewModelFactory = (chatId) {
      return ModelLogViewModel(
        chatId: chatId,
        repository: logs[chatId]!,
        openDirectory: (_) async => true,
        copyText: (_) async {},
      );
    };
  });
  tearDown(() async {
    for (final repository in logs.values) {
      await repository.dispose();
    }
    await harness.close();
  });

  testWidgets(
    'conversation details bind settings and directory to the selected chat',
    (tester) async {
      await withDesktopPlatform(() async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Widget page(String chatId) => AppScope(
          dependencies: harness,
          child: shadHarness(
            brightness: Brightness.light,
            homeBuilder:
                (_) => Scaffold(
                  body: DesktopLayout(
                    currentIndex: 0,
                    onPageChanged: (_) {},
                    pages: const [SizedBox.shrink(), SizedBox.shrink()],
                    selectedChatId: chatId,
                    selectedChatBot: harness.bot,
                    onBotUpdated: (_) async {},
                    onBotDeleted: () async {},
                  ),
                ),
          ),
        );
        final control = find.byKey(const ValueKey('model-log-switch'));
        Future<void> showDetails(String chatId) async {
          await tester.pumpWidget(page(chatId));
          await driveTaskUi(tester);
          await tester.tap(
            find.byKey(const ValueKey('desktop-toolbar-conversation-info')),
          );
          await driveTaskUi(tester);
          await Scrollable.ensureVisible(
            tester.element(control),
            alignment: 0.5,
          );
          await tester.pumpAndSettle();
          expect(find.byType(ModelLogSettingsView), findsOneWidget);
          expect(find.text('/logs/conversations/$chatId'), findsOneWidget);
        }

        await showDetails('chat-1');
        expect(tester.widget<ShadSwitch>(control).value, isFalse);
        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(logs['chat-1']!.settings.enabled, isTrue);

        await showDetails('chat-2');
        expect(tester.widget<ShadSwitch>(control).value, isFalse);
        expect(find.text('/logs/conversations/chat-1'), findsNothing);

        await showDetails('chat-1');
        expect(tester.widget<ShadSwitch>(control).value, isTrue);
        expect(logs['chat-2']!.settings.enabled, isFalse);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await driveTaskUi(tester);
      });
    },
  );
}
