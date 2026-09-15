import 'dart:async';
import 'dart:convert';

import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/conversation_draft_repository.dart';
import 'package:stars/domain/repositories/conversation_turn_router.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';

final foregroundTime = DateTime.utc(2026, 9, 15);

Bot foregroundBot({
  Map<String, dynamic>? parameters,
  String apiType = 'openai',
  String model = 'test-model',
  String provider = 'provider',
}) => Bot(
  id: 'bot-1',
  name: 'Bot',
  avatar: '',
  provider: provider,
  baseURL: 'https://provider.invalid/',
  apiKey: 'test-credential-not-persisted',
  apiType: apiType,
  model: model,
  systemPrompt: 'Be helpful.',
  parameters: parameters,
  createTimestamp: foregroundTime,
  modifyTimestamp: foregroundTime,
);

ConversationTurnInput foregroundInput({
  String turnId = 'turn-1',
  String chatId = 'chat-1',
  String content = '整理报告',
  String language = 'zh-CN',
  String? explicitTaskId,
  Bot? bot,
  List<String> images = const [],
  List<String> files = const [],
}) => ConversationTurnInput(
  bot: bot ?? foregroundBot(),
  language: language,
  userMessage: Message(
    messageId: '$turnId:user',
    turnId: turnId,
    chatId: chatId,
    botId: 'bot-1',
    senderId: 'user',
    content: content,
    images: images,
    files: files,
    timestamp: foregroundTime,
  ),
  verification: VerificationPolicySnapshot(
    reliabilityEnabled: true,
    strictGroundingEnabled: true,
    showVerificationStatus: true,
  ),
  segmentLimits: TaskSegmentLimits(maxModelTurns: 7),
  explicitTaskId: explicitTaskId,
);

Map<String, Object?> foregroundPlan({String draft = ''}) => {
  'title': '整理报告',
  'objective': '读取资料并整理报告',
  'steps': [
    {'stepId': 'read', 'summary': '读取资料'},
    {'stepId': 'write', 'summary': '整理报告'},
  ],
  'allowedToolNames': ['read_file'],
  'acknowledgementDraft': draft,
};

String routeFrames(
  String kind,
  List<Map<String, Object?>> payloads, {
  bool done = true,
}) => [
  {'kind': kind},
  ...payloads,
  if (done) {'done': true},
].map(jsonEncode).join('\n');

final class ForegroundProviders implements AiProviderRepository {
  ForegroundProviders(this.factory);
  final AiProvider Function(Bot) factory;
  int creates = 0;
  @override
  AiProvider create(Bot bot) {
    creates++;
    return factory(bot);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class ForegroundProvider extends AiProvider {
  ForegroundProvider(
    super.bot, {
    this.mode = ForegroundRoutingTransport.modelSession,
    this.events,
    this.generate,
  });
  final ForegroundRoutingTransport mode;
  Stream<ModelEvent> Function()? events;
  Future<void> Function(ForegroundProvider)? generate;
  final sessions = <ForegroundModelSession>[];
  List<ChatMessage>? legacyMessages;
  int legacyCalls = 0;
  int cancellations = 0;
  @override
  ForegroundRoutingTransport get foregroundRoutingTransport => mode;
  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );
  @override
  AgentModelSession openModelSession(ModelRequest request) {
    final session = ForegroundModelSession(request, events!);
    sessions.add(session);
    return session;
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
    legacyCalls++;
    legacyMessages = messages;
    await generate!(this);
  }

  @override
  Future<ProviderCancellationResult> cancelRequest() async {
    cancellations++;
    return super.cancelRequest();
  }
}

final class ForegroundModelSession implements AgentModelSession {
  ForegroundModelSession(this.request, this.events);
  final ModelRequest request;
  final Stream<ModelEvent> Function() events;
  int starts = 0;
  int cancellations = 0;
  bool closed = false;
  @override
  Stream<ModelEvent> start() {
    starts++;
    return events();
  }

  @override
  Future<void> cancel() async {
    cancellations++;
  }

  @override
  void close() {
    closed = true;
  }

  // Unexpected continuation/synthesis calls fail the test immediately.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class ForegroundDrafts implements ConversationDraftRepository {
  final values = <String, ConversationDraft>{};
  bool failWrite = false;
  @override
  Future<ConversationDraft?> read(String chatId) async => values[chatId];
  @override
  Future<void> write(String chatId, ConversationDraft draft) async {
    if (failWrite) throw StateError('draft failed');
    values[chatId] = draft;
  }

  @override
  Future<void> delete(String chatId) async {
    values.remove(chatId);
  }
}

final class ForegroundEnqueuer implements ConversationTaskEnqueuer {
  final calls = <String>[];
  Future<void> Function(String)? onEnqueue;
  @override
  Future<void> enqueue(String taskId) async {
    calls.add(taskId);
    await onEnqueue?.call(taskId);
  }
}

final class ForegroundTool implements ExecutableTool {
  int calls = 0;
  @override
  final definition = ToolDefinition(
    name: 'read_file',
    description: 'Read a report file.',
    inputSchema: const {'type': 'object'},
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
  );
  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    calls++;
    throw StateError('Foreground routing must not execute tools.');
  }
}
