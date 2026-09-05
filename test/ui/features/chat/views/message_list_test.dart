import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';
import 'package:stars/utils/theme.dart';

void main() {
  testWidgets('message list starts at the latest lazily built messages', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 600);
    addTearDown(tester.view.reset);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    final messages = [
      for (var index = 0; index < 500; index++)
        Message(
          messageId: 'message-$index',
          chatId: 'chat-1',
          botId: 'bot-1',
          senderId: 'bot-1',
          content: 'content-$index',
          timestamp: DateTime(2026).add(Duration(seconds: index)),
        ),
    ];

    await tester.pumpWidget(
      _messageListHarness(
        MessageList(
          messages: messages,
          scrollController: scrollController,
          isStreaming: false,
          streamingResponse: '',
          currentUserId: 'me',
        ),
      ),
    );
    await tester.pump();

    expect(tester.widget<ListView>(find.byType(ListView)).reverse, isTrue);
    expect(find.text('content-499'), findsOneWidget);
    expect(find.text('content-0'), findsNothing);
    expect(scrollController.offset, 0);
  });

  testWidgets('assistant code block copies retain the trust boundary', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 800);
    addTearDown(tester.view.reset);
    final clipboardWrites = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboardWrites.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    final message = Message(
      messageId: 'assistant-code',
      chatId: 'chat-1',
      botId: 'bot-1',
      senderId: 'bot-1',
      content: '''Run the command:

```bash
flutter test test/widget_test.dart
```

Then use this code:

```dart
void main() => print('done');
```''',
      timestamp: DateTime(2026, 8, 11),
    );

    await tester.pumpWidget(
      _messageListHarness(
        MessageList(
          messages: [message],
          scrollController: scrollController,
          isStreaming: false,
          streamingResponse: '',
          currentUserId: 'me',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('bash'), findsOneWidget);
    expect(find.text('dart'), findsOneWidget);
    final copyButtons = find.byKey(
      const ValueKey<String>('message-code-copy-button'),
    );
    expect(copyButtons, findsNWidgets(2));

    await tester.tap(copyButtons.at(1));
    await tester.pump();

    expect(clipboardWrites, hasLength(1));
    final copied = (clipboardWrites.single.arguments as Map)['text'] as String;
    expect(copied, startsWith("void main() => print('done');\n\n---\n\n"));
    expect(copied, contains('可信状态: 未验证'));
  });

  testWidgets('desktop message hover shows its persisted timestamp', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 800);
    addTearDown(tester.view.reset);
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    final timestamp = DateTime(2026, 8, 11, 14, 5, 9);

    await tester.pumpWidget(
      _desktopMessageListHarness(
        MessageList(
          messages: [
            Message(
              messageId: 'timestamped-message',
              chatId: 'chat-1',
              botId: 'bot-1',
              senderId: 'bot-1',
              content: 'hover me',
              timestamp: timestamp,
            ),
          ],
          scrollController: scrollController,
          isStreaming: false,
          streamingResponse: '',
          currentUserId: 'me',
          isDesktop: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final timestampText = find.byKey(
      const ValueKey<String>('desktop-message-timestamp'),
    );
    expect(timestampText, findsOneWidget);
    expect(
      tester.widget<Text>(timestampText).data,
      intl.DateFormat.yMd('zh_CN').add_Hms().format(timestamp),
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.ancestor(
              of: timestampText,
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      0,
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('hover me')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.ancestor(
              of: timestampText,
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      1,
    );
    expect(
      find.byKey(const ValueKey<String>('desktop-message-copy-action')),
      findsOneWidget,
    );
  });

  testWidgets('desktop reasoning icon rotates while the model is thinking', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(isStreaming: true));
    await tester.pump(const Duration(milliseconds: 200));

    final spinner = find.byKey(
      const ValueKey<String>('reasoning-streaming-spinner'),
    );
    expect(spinner, findsOneWidget);
    final initialTurns = tester.widget<RotationTransition>(spinner).turns.value;

    await tester.pump(const Duration(milliseconds: 225));

    final rotatedTurns = tester.widget<RotationTransition>(spinner).turns.value;
    expect(rotatedTurns, isNot(closeTo(initialTurns, 0.01)));
    expect(rotatedTurns, closeTo(0.25, 0.05));

    await tester.pumpWidget(_harness(isStreaming: false));
    await tester.pump();

    expect(spinner, findsNothing);
    expect(find.byIcon(LucideIcons.brain), findsOneWidget);
  });

  testWidgets('desktop reasoning icon respects disabled animations', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(isStreaming: true, disableAnimations: true),
    );
    await tester.pump(const Duration(milliseconds: 200));

    final spinner = find.byKey(
      const ValueKey<String>('reasoning-streaming-spinner'),
    );
    final initialTurns = tester.widget<RotationTransition>(spinner).turns.value;

    await tester.pump(const Duration(milliseconds: 225));

    expect(
      tester.widget<RotationTransition>(spinner).turns.value,
      initialTurns,
    );
  });

  testWidgets(
    'desktop completed reasoning icon aligns with execution status icon',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          isStreaming: false,
          body: const Column(
            children: [
              ReasoningSection(reasoning: 'reasoning', isDesktop: true),
              ProcessInfoSection(
                processInfo: MessageProcessInfo(durationMs: 1000),
                isDesktop: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reasoningIcon = find.byKey(
        const ValueKey<String>('reasoning-status-icon'),
      );
      final executionIcon = find.byKey(
        const ValueKey<String>('execution-status-icon'),
      );

      expect(tester.getSize(reasoningIcon), const Size.square(28));
      expect(tester.getSize(reasoningIcon), tester.getSize(executionIcon));
      expect(
        tester.getTopLeft(reasoningIcon).dx,
        closeTo(tester.getTopLeft(executionIcon).dx, 0.01),
      );

      final background = tester.widget<DecoratedBox>(
        find.descendant(of: reasoningIcon, matching: find.byType(DecoratedBox)),
      );
      expect((background.decoration as BoxDecoration).color, isNotNull);
    },
  );

  testWidgets(
    'execution durations use localized units and decimal separators',
    (tester) async {
      await tester.pumpWidget(
        _messageListHarness(
          const ProcessInfoSection(
            processInfo: MessageProcessInfo(durationMs: 1200),
          ),
          locale: const Locale('de', 'DE'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dauer 1,2 s'), findsOneWidget);
      expect(find.textContaining('1.2s'), findsNothing);
    },
  );

  testWidgets('renders all trust levels with expandable claim evidence', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(520, 900);
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final actions = MessageActionViewModel(
      repository: const _MessageActions(),
      evidenceRepository: _EvidenceRepository(_evidence()),
    );
    final verified = _groundedMessage(
      id: 'verified-message',
      trust: AnswerTrustLevel.verified,
      claimTrust: ClaimTrustLevel.verified,
      evidenceIds: const [_evidenceId],
      reasonCode: 'all_evidence_validated',
      processInfo: const MessageProcessInfo(
        toolCalls: [
          MessageToolCall(
            callId: 'read-state',
            attemptId: _attemptId,
            name: 'inventory.read',
            status: 'succeeded',
            approvalStatus: 'allowOnce',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _harness(
        isStreaming: false,
        highContrast: true,
        body: Column(
          children: [
            MessageList(
              messages: [verified],
              scrollController: controller,
              isStreaming: false,
              streamingResponse: '',
              currentUserId: 'me',
              isDesktop: true,
              actionViewModel: actions,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已验证'), findsWidgets);
    await tester.tap(find.text('执行状态'));
    await tester.pumpAndSettle();
    expect(find.text('动作已接受'), findsOneWidget);
    expect(find.text('动作已完成'), findsOneWidget);
    expect(find.text('状态已回读验证'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('message-trust-details-toggle')),
    );
    await tester.pumpAndSettle();

    expect(find.text('工具: inventory.read'), findsOneWidget);
    expect(find.text('来源: 内置'), findsOneWidget);
    expect(find.textContaining('观测时间:'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey<String>('message-trust-status')),
    );
    expect(semantics.label, contains('已验证'));

    for (final entry in <(AnswerTrustLevel, String)>[
      (AnswerTrustLevel.partiallyVerified, '部分已验证'),
      (AnswerTrustLevel.unverified, '未验证'),
      (AnswerTrustLevel.failed, '失败'),
    ]) {
      final levelController = ScrollController();
      addTearDown(levelController.dispose);
      final message =
          entry.$1 == AnswerTrustLevel.failed
              ? _failedMessage()
              : _groundedMessage(
                id: '${entry.$1.name}-message',
                trust: entry.$1,
                claimTrust: ClaimTrustLevel.unverified,
                evidenceIds:
                    entry.$1 == AnswerTrustLevel.partiallyVerified
                        ? const [_evidenceId]
                        : const [],
                reasonCode:
                    entry.$1 == AnswerTrustLevel.partiallyVerified
                        ? 'partial_evidence_validated'
                        : 'no_claims_verified',
              );
      await tester.pumpWidget(
        _harness(
          isStreaming: false,
          body: Column(
            children: [
              MessageList(
                messages: [message],
                scrollController: levelController,
                isStreaming: false,
                streamingResponse: '',
                currentUserId: 'me',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsWidgets);
    }
  });

  testWidgets(
    'strict mode hides unverified facts but keeps failure details and copy boundary',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 900);
      addTearDown(tester.view.reset);
      final clipboardWrites = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') clipboardWrites.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final message = _groundedMessage(
        id: 'strict-message',
        trust: AnswerTrustLevel.unverified,
        claimTrust: ClaimTrustLevel.unverified,
        evidenceIds: const [],
        reasonCode: 'tool_failed',
        content: 'Secret unverified factual answer.',
        processInfo: const MessageProcessInfo(
          toolCalls: [
            MessageToolCall(
              callId: 'failed-call',
              attemptId: 'run-1:attempt:2',
              name: 'inventory.read',
              status: 'failed',
              detail: 'permission denied',
              errorCode: 'permission_denied',
            ),
          ],
        ),
      ).copyWith(reasoning: 'Secret unverified reasoning.');

      await tester.pumpWidget(
        _harness(
          isStreaming: false,
          body: Column(
            children: [
              MessageList(
                messages: [message],
                scrollController: controller,
                isStreaming: false,
                streamingResponse: '',
                currentUserId: 'me',
                strictGroundingMode: true,
                isDesktop: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secret unverified factual answer.'), findsNothing);
      expect(find.text('Secret unverified reasoning.'), findsNothing);
      final notice = find.textContaining('Stars 无法验证此事实回答');
      expect(notice, findsOneWidget);
      await tester.tap(find.text('执行状态'));
      await tester.pumpAndSettle();
      expect(find.textContaining('permission denied'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('message-trust-details-toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.text('严格模式已隐藏未验证的事实声明。'), findsOneWidget);
      expect(find.textContaining('失败原因:'), findsOneWidget);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(notice));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('desktop-message-copy-action')),
      );
      await tester.pump();
      expect(clipboardWrites, hasLength(1));
      final copied =
          (clipboardWrites.single.arguments as Map)['text'] as String;
      expect(copied, isNot(contains('Secret unverified factual answer.')));
      expect(copied, contains('可信状态: 未验证'));
    },
  );

  testWidgets('strict mode does not expose unverified streaming text', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _messageListHarness(
        MessageList(
          messages: const [],
          scrollController: controller,
          isStreaming: true,
          streamingResponse: 'Unverified streaming fact.',
          reasoningResponse: 'Unverified streaming reasoning.',
          deepThinking: true,
          currentUserId: 'me',
          strictGroundingMode: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Unverified streaming fact.'), findsNothing);
    expect(find.text('Unverified streaming reasoning.'), findsNothing);
  });

  testWidgets('strict mode keeps creative text visibly not fact checked', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final message = Message(
      messageId: 'creative-message',
      chatId: 'chat-1',
      botId: 'bot-1',
      senderId: 'bot-1',
      content: 'A tiny fictional constellation.',
      grounding: MessageGrounding(
        reasonCode: 'no_verifiable_claims',
        claims: [
          MessageClaimGrounding(
            claim: AnswerClaim(
              claimId: 'creative-claim',
              text: 'A tiny fictional constellation.',
              kind: ClaimKind.nonFactual,
            ),
            trustLevel: ClaimTrustLevel.notVerifiable,
            reasonCode: 'not_fact_checked',
          ),
        ],
      ),
      terminalOutcome: MessageTerminalOutcome.completed,
      timestamp: DateTime(2026, 9, 5),
    );

    await tester.pumpWidget(
      _messageListHarness(
        MessageList(
          messages: [message],
          scrollController: controller,
          isStreaming: false,
          streamingResponse: '',
          currentUserId: 'me',
          strictGroundingMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(message.content), findsOneWidget);
    expect(find.text('未进行事实核验'), findsWidgets);
  });
}

Widget _messageListHarness(
  Widget child, {
  Locale locale = const Locale('zh', 'CN'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: supportedLocales,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      S.delegate,
    ],
    home: Scaffold(body: Column(children: [child])),
  );
}

Widget _desktopMessageListHarness(Widget child) {
  return _harness(isStreaming: false, body: Column(children: [child]));
}

Widget _harness({
  required bool isStreaming,
  bool disableAnimations = false,
  bool highContrast = false,
  Widget? body,
}) {
  final shadTheme = buildStarsShadTheme(
    brightness: Brightness.light,
    fontSize: 16,
    highContrast: highContrast,
  );
  return ShadApp.custom(
    themeMode: ThemeMode.light,
    theme: shadTheme,
    appBuilder:
        (shadContext) => MaterialApp(
          theme: buildShadMaterialBridgeTheme(
            context: shadContext,
            fontSize: 16,
            highContrast: highContrast,
          ),
          locale: const Locale('zh', 'CN'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: disableAnimations,
                  highContrast: highContrast,
                ),
                child: ShadAppBuilder(child: child!),
              ),
          home: Scaffold(
            body:
                body ??
                ReasoningSection(
                  reasoning: 'reasoning',
                  isDesktop: true,
                  isStreaming: isStreaming,
                ),
          ),
        ),
  );
}

const _attemptId = 'run-1:attempt:1';
const _evidenceId = '$_attemptId:evidence';

Message _groundedMessage({
  required String id,
  required AnswerTrustLevel trust,
  required ClaimTrustLevel claimTrust,
  required List<String> evidenceIds,
  required String reasonCode,
  String content = 'Grounded factual answer.',
  MessageProcessInfo processInfo = const MessageProcessInfo(),
}) {
  final proposedEvidence =
      claimTrust == ClaimTrustLevel.verified
          ? evidenceIds
          : trust == AnswerTrustLevel.partiallyVerified
          ? evidenceIds
          : const <String>[];
  final claims = <MessageClaimGrounding>[
    if (trust == AnswerTrustLevel.partiallyVerified)
      MessageClaimGrounding(
        claim: AnswerClaim(
          claimId: '$id-verified',
          text: 'Verified portion.',
          kind: ClaimKind.currentFact,
          evidenceIds: evidenceIds,
        ),
        trustLevel: ClaimTrustLevel.verified,
        acceptedEvidenceIds: evidenceIds,
        reasonCode: 'evidence_accepted',
      ),
    MessageClaimGrounding(
      claim: AnswerClaim(
        claimId: '$id-claim',
        text: content,
        kind: ClaimKind.currentFact,
        evidenceIds: proposedEvidence,
      ),
      trustLevel: claimTrust,
      acceptedEvidenceIds:
          claimTrust == ClaimTrustLevel.verified ? evidenceIds : const [],
      reasonCode:
          claimTrust == ClaimTrustLevel.verified
              ? 'evidence_accepted'
              : 'claimHasNoEvidence',
    ),
  ];
  return Message(
    messageId: id,
    turnId: 'turn-1',
    runId: 'run-1',
    chatId: 'chat-1',
    botId: 'bot-1',
    senderId: 'bot-1',
    content:
        trust == AnswerTrustLevel.partiallyVerified
            ? 'Verified portion.\n\n$content'
            : content,
    processInfo: processInfo,
    grounding: MessageGrounding(
      trustLevel: trust,
      reasonCode: reasonCode,
      evidenceIds: evidenceIds,
      claims: claims,
    ),
    terminalOutcome: MessageTerminalOutcome.completed,
    timestamp: DateTime(2026, 9, 5),
  );
}

Message _failedMessage() => Message(
  messageId: 'failed-message',
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'bot-1',
  content: 'Failed response.',
  grounding: MessageGrounding(
    trustLevel: AnswerTrustLevel.failed,
    reasonCode: 'provider_failed',
  ),
  terminalOutcome: MessageTerminalOutcome.failed,
  timestamp: DateTime(2026, 9, 5),
);

ToolEvidenceRecord _evidence() => ToolEvidenceRecord(
  evidenceId: _evidenceId,
  runId: 'run-1',
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'verified-message',
  invocationId: 'run-1:invocation:1',
  attemptId: _attemptId,
  toolName: 'inventory.read',
  toolVersion: '1.0.0',
  source: ToolSource.builtIn,
  capabilities: const {ToolCapability.externalRead},
  terminalStatus: ToolInvocationStatus.succeeded,
  evidenceKind: EvidenceKind.observation,
  subject: 'inventory:item-1',
  scope: const {'item_id': 'item-1'},
  resultSummary: 'Inventory state observed.',
  argumentsDigest: 'a' * 64,
  resultDigest: 'b' * 64,
  structuredFacts: [StructuredFact(name: 'inventory.state', value: 'ready')],
  observedAt: DateTime.utc(2026, 9, 5, 8, 30),
  validUntil: DateTime.utc(2026, 9, 5, 8, 35),
  persisted: true,
);

final class _EvidenceRepository implements ToolEvidenceRepository {
  const _EvidenceRepository(this.record);

  final ToolEvidenceRecord record;

  @override
  Future<ToolEvidenceRecord?> getById(String evidenceId) async =>
      evidenceId == record.evidenceId ? record : null;

  @override
  Future<List<ToolEvidenceRecord>> getForMessage(String messageId) async =>
      record.messageId == messageId ? [record] : const [];

  @override
  Future<List<ToolInvocationEvent>> getInvocationEventsForRun(
    String runId,
  ) async => const [];

  @override
  Future<bool> verifyDigest(String evidenceId) async => true;

  @override
  Future<void> commitRun({
    required String runId,
    required String chatId,
    required List<ToolInvocationEvent> invocationEvents,
    required List<ToolEvidenceRecord> evidenceRecords,
  }) async {}
}

final class _MessageActions implements MessageActionRepository {
  const _MessageActions();

  @override
  Future<bool> openExternal(Uri uri) async => true;

  @override
  Future<bool> openLocalFile(String path) async => true;

  @override
  Future<MediaExportResult> saveImage({
    required String sourcePath,
    required String dialogTitle,
  }) async => MediaExportResult.saved;

  @override
  Future<void> shareImage({
    required String sourcePath,
    required String text,
  }) async {}
}
