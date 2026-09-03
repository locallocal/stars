import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/chat_workflow_facade.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_interaction_facade.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';

class ChatViewModel extends DisposableChangeNotifier {
  ChatViewModel({required ChatInteractionFacade interaction})
    : _interaction = interaction,
      chatId = interaction.chatId;

  final String chatId;
  final ChatInteractionFacade _interaction;

  Bot get bot => _interaction.bot;
  ChatWorkflowFacade get _workflow => _interaction.workflow;
  MessageActionViewModel get messageActions => _interaction.messageActions;
  ChatGenerationViewModel get generationViewModel =>
      _interaction.generationViewModel;

  List<Message> _messages = const [];
  AppFailure? _historyError;
  bool _isLoading = false;
  bool _isLoadingEarlier = false;
  bool _hasEarlierMessages = false;
  MessageCursor? _earlierCursor;
  int _historyLoadGeneration = 0;

  List<Message> get messages => _messages;
  List<Message>? get cachedMessages {
    final history = _workflow.peekHistory();
    if (history == null) return null;
    _applyHistoryState(history);
    return List<Message>.unmodifiable(history.messages);
  }

  AppFailure? get historyError => _historyError;
  bool get isLoading => _isLoading;
  bool get isLoadingEarlier => _isLoadingEarlier;
  bool get hasEarlierMessages => _hasEarlierMessages;

  Future<void> loadMessages() async {
    if (isDisposed) return;
    final generation = ++_historyLoadGeneration;
    _isLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      final history = await _workflow.loadHistory();
      if (isDisposed || generation != _historyLoadGeneration) return;
      _messages = List<Message>.unmodifiable(history.messages);
      _applyHistoryState(history);
    } catch (error) {
      if (isDisposed || generation != _historyLoadGeneration) return;
      _historyError = AppFailure.from(
        error,
        code: 'message_history_load_failed',
      );
    } finally {
      if (!isDisposed && generation == _historyLoadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<List<Message>> loadEarlierMessages() async {
    if (isDisposed || _isLoadingEarlier || !_hasEarlierMessages) {
      return _messages;
    }
    final cursor = _earlierCursor;
    if (cursor == null) {
      _hasEarlierMessages = false;
      return _messages;
    }
    _isLoadingEarlier = true;
    notifyListeners();
    try {
      final history = await _workflow.loadHistory(before: cursor);
      if (isDisposed) return _messages;
      final byId = <String, Message>{
        for (final message in history.messages) message.messageId: message,
        for (final message in _messages) message.messageId: message,
      };
      _messages = List<Message>.unmodifiable(
        byId.values.toList()..sort(_compareMessages),
      );
      _applyHistoryState(history);
      return _messages;
    } catch (error) {
      if (isDisposed) return _messages;
      _historyError = AppFailure.from(error, code: 'message_page_load_failed');
      rethrow;
    } finally {
      if (!isDisposed) {
        _isLoadingEarlier = false;
        notifyListeners();
      }
    }
  }

  void _applyHistoryState(ChatHistoryBatch history) {
    _hasEarlierMessages = history.hasMore;
    _earlierCursor = history.nextCursor;
  }

  String createId(String prefix) => _workflow.createId(prefix);

  Message createUserMessage({
    required String currentUserId,
    required String content,
    List<String> imagePaths = const [],
    List<String> filePaths = const [],
    String imageDetail = '',
    String fileDetail = '',
  }) => _workflow.createUserMessage(
    currentUserId: currentUserId,
    content: content,
    imagePaths: imagePaths,
    filePaths: filePaths,
    imageDetail: imageDetail,
    fileDetail: fileDetail,
  );

  Future<Message> upsertMessage(Message message) =>
      _workflow.upsertMessage(message);

  Future<void> updateLastMessage(String content) =>
      _workflow.updateLastMessage(content);

  Future<void> clearHistory() => _workflow.clearHistory();

  Future<PreparedChatTurn> prepareTextTurn({
    required List<Message> history,
    required Message userMessage,
    required String currentUserId,
  }) => _workflow.prepareTextTurn(
    history: history,
    userMessage: userMessage,
    currentUserId: currentUserId,
  );

  Future<PreparedTextGeneration> prepareTextGeneration({
    required List<Message> history,
    required Message userMessage,
    required String currentUserId,
  }) async {
    final prepared = await _workflow.prepareTextGeneration(
      history: history,
      userMessage: userMessage,
      currentUserId: currentUserId,
    );
    return PreparedTextGeneration(
      userMessage: prepared.userMessage,
      messages: prepared.messages,
      activatedSkills: prepared.activatedSkills,
      activationAttempts: prepared.activationAttempts,
      skillToolCalls: prepared.skillToolCalls,
      preflightTokenUsage: prepared.preflightTokenUsage,
      requestedToolNames: prepared.requestedToolNames,
      approvalExemptToolNames: prepared.approvalExemptToolNames,
      runScopedTools: prepared.runScopedTools,
      contextAssemblyReport: prepared.contextAssemblyReport,
      reliabilityPolicyEnabled: prepared.reliabilityPolicyEnabled,
    );
  }

  Future<String?> captureImage() => _workflow.captureImage();

  Future<String?> selectImage() => _workflow.selectImage();

  Future<String?> selectFile() => _workflow.selectFile();

  Future<List<String>> persistAssets(Iterable<String> sourcePaths) =>
      _workflow.persistAssets(sourcePaths);

  Future<MediaTurnResult> generateMediaTurn(
    MediaTurnRequest request, {
    MediaUserPersisted? onUserPersisted,
  }) async {
    return _interaction.generateMediaTurn(
      request,
      onUserPersisted: onUserPersisted,
    );
  }

  Future<ConversationDraft?> readDraft() => _workflow.readDraft();

  Future<void> writeDraft(ConversationDraft draft) =>
      _workflow.writeDraft(draft);

  Future<void> deleteDraft() => _workflow.deleteDraft();

  Future<List<String>> generateImage({
    required String prompt,
    required String size,
    required String outputDirectory,
    required List<String> referenceImages,
    required String style,
  }) => _workflow.generateImage(
    prompt: prompt,
    size: size,
    outputDirectory: outputDirectory,
    referenceImages: referenceImages,
    style: style,
  );

  Future<String> generateSpeech({
    required String prompt,
    required String voiceType,
    required String outputDirectory,
  }) => _workflow.generateSpeech(
    prompt: prompt,
    voiceType: voiceType,
    outputDirectory: outputDirectory,
  );

  Future<String> generateMusic({
    required String prompt,
    required String outputDirectory,
    required String referenceMusic,
  }) => _workflow.generateMusic(
    prompt: prompt,
    outputDirectory: outputDirectory,
    referenceMusic: referenceMusic,
  );

  Future<String> generateVideo({
    required String prompt,
    required String ratio,
    required String outputDirectory,
    required List<String> referenceImages,
  }) => _workflow.generateVideo(
    prompt: prompt,
    ratio: ratio,
    outputDirectory: outputDirectory,
    referenceImages: referenceImages,
  );

  Future<bool> cancelMedia() => _workflow.cancelMedia();

  bool get hasBlockingRun => _interaction.hasBlockingRun;

  void updateBot(Bot bot) => _interaction.updateBot(bot);

  bool get supportsRunCancellation => _interaction.supportsRunCancellation;

  Future<bool> stopActiveRun() => _interaction.stopActiveRun();

  void notifyChatListChanged() => _workflow.notifyChatListChanged();
}

int _compareMessages(Message left, Message right) {
  final timestamp = left.timestamp.compareTo(right.timestamp);
  if (timestamp != 0) return timestamp;
  return left.messageId.compareTo(right.messageId);
}
