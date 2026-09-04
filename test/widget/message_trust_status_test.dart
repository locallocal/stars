import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';

import '../support/widget_test_support.dart';

void main() {
  testWidgets(
    'reloaded grounding displays an accessible status independent of tools',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final reloaded =
            MessageRecord.fromDomain(
              _assistant(
                grounding: MessageGrounding(
                  trustLevel: AnswerTrustLevel.unverified,
                  reasonCode: 'no_tool_evidence',
                ),
                processInfo: const MessageProcessInfo(
                  toolCalls: [
                    MessageToolCall(
                      callId: 'successful-but-not-evidence',
                      name: 'legacy.tool',
                      status: 'succeeded',
                    ),
                  ],
                ),
              ),
            ).toDomain();

        await _pumpMessage(tester, reloaded, isDesktop: true);

        expect(find.text('未验证'), findsOneWidget);
        expect(find.text('此回复没有可用的工具证据。'), findsOneWidget);
        expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);
        expect(find.text('执行状态'), findsOneWidget);
        final status = find.byKey(
          const ValueKey<String>('message-trust-status'),
        );
        expect(status, findsOneWidget);
        expect(tester.getSemantics(status).label, '未验证。此回复没有可用的工具证据。');
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('localizes every minimum trust reason category', (tester) async {
    final cases = <({AnswerTrustLevel trust, String code, String text})>[
      (
        trust: AnswerTrustLevel.unverified,
        code: 'no_tool_evidence',
        text: '此回复没有可用的工具证据。',
      ),
      (
        trust: AnswerTrustLevel.unverified,
        code: 'provider_tools_unsupported',
        text: '当前 Provider 不支持验证工具。',
      ),
      (
        trust: AnswerTrustLevel.unverified,
        code: 'tool_rejected',
        text: '验证工具请求已被拒绝。',
      ),
      (
        trust: AnswerTrustLevel.failed,
        code: 'provider_generation_failed',
        text: 'Provider 请求失败，无法验证此回复。',
      ),
      (
        trust: AnswerTrustLevel.failed,
        code: 'answer_trust_gate_failed',
        text: '此回复未通过应用可信门禁。',
      ),
    ];

    for (final testCase in cases) {
      await _pumpMessage(
        tester,
        _assistant(
          grounding: MessageGrounding(
            trustLevel: testCase.trust,
            reasonCode: testCase.code,
          ),
        ),
      );

      expect(find.text(testCase.text), findsOneWidget, reason: testCase.code);
      expect(
        find.text(testCase.trust == AnswerTrustLevel.failed ? '失败' : '未验证'),
        findsOneWidget,
        reason: testCase.code,
      );
    }
  });

  testWidgets(
    'P0 does not show verified status or status below user messages',
    (tester) async {
      await _pumpMessages(tester, [
        _assistant(
          messageId: 'verified-assistant',
          grounding: MessageGrounding(
            trustLevel: AnswerTrustLevel.verified,
            reasonCode: 'all_evidence_validated',
            evidenceIds: const ['evidence-1'],
          ),
        ),
        _assistant(
          messageId: 'partially-verified-assistant',
          grounding: MessageGrounding(
            trustLevel: AnswerTrustLevel.partiallyVerified,
            reasonCode: 'partial_evidence_validated',
            evidenceIds: const ['evidence-2'],
          ),
        ),
        Message(
          messageId: 'user-message',
          chatId: 'chat-1',
          botId: 'bot-1',
          senderId: 'user-1',
          content: 'User assertion',
          grounding: MessageGrounding(
            trustLevel: AnswerTrustLevel.failed,
            reasonCode: 'provider_generation_failed',
          ),
          timestamp: DateTime(2026),
        ),
      ]);

      expect(
        find.byKey(const ValueKey<String>('message-trust-status')),
        findsNothing,
      );
      expect(find.text('已验证'), findsNothing);
      expect(find.text('未验证'), findsNothing);
      expect(find.text('失败'), findsNothing);
    },
  );
}

Message _assistant({
  String messageId = 'assistant-message',
  required MessageGrounding grounding,
  MessageProcessInfo processInfo = const MessageProcessInfo(),
}) => Message(
  messageId: messageId,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'bot-1',
  content: 'Assistant response',
  processInfo: processInfo,
  grounding: grounding,
  terminalOutcome: MessageTerminalOutcome.completed,
  timestamp: DateTime(2026),
);

Future<void> _pumpMessage(
  WidgetTester tester,
  Message message, {
  bool isDesktop = false,
}) => _pumpMessages(tester, [message], isDesktop: isDesktop);

Future<void> _pumpMessages(
  WidgetTester tester,
  List<Message> messages, {
  bool isDesktop = false,
}) async {
  final scrollController = ScrollController();
  addTearDown(scrollController.dispose);
  await tester.pumpWidget(
    shadHarness(
      brightness: Brightness.light,
      homeBuilder:
          (context) => Scaffold(
            body: Column(
              children: [
                MessageList(
                  messages: messages,
                  scrollController: scrollController,
                  isStreaming: false,
                  streamingResponse: '',
                  currentUserId: 'user-1',
                  isDesktop: isDesktop,
                ),
              ],
            ),
          ),
    ),
  );
  await tester.pumpAndSettle();
}
