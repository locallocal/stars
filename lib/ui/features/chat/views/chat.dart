import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_view_model.dart';
import 'package:stars/ui/features/chat/views/attachments.dart';
import 'package:stars/ui/features/chat/views/clear_chat_dialog.dart';
import 'package:stars/ui/features/chat/views/message_input.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/ui/features/chat/views/typing_indicator.dart';
import 'package:stars/ui/features/chat/views/tool_approval_card.dart';
import 'package:stars/ui/features/chat/views/welcome_view.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

// 聊天页面
part 'chat_workspace.dart';
part 'chat_draft_and_media.dart';
part 'chat_send_commands.dart';
part 'chat_session_commands.dart';

class ChatPage extends StatefulWidget {
  final Bot bot;
  final String id;
  final bool showExecutionStatus;

  const ChatPage({
    super.key,
    required this.id,
    required this.bot,
    this.showExecutionStatus = true,
  });

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  void _updateState(VoidCallback callback) => setState(callback);

  static const double _followLatestThreshold = 96;
  static final Set<String> _composerFocusRequests = <String>{};

  static void requestComposerFocus(String chatId) {
    _composerFocusRequests.add(chatId);
  }

  late final ChatGenerationViewModel _generationViewModel;
  late final ChatViewModel _chatViewModel;
  bool _dependenciesInitialized = false;
  AiProvider get _provider => _generationViewModel.capabilityProvider;
  final String _currentUserId = 'me';
  late final TextEditingController _messageController;
  late final bool _autofocusComposer;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingEarlier = false;
  String? _historyError;
  int _composerFocusToken = 0;
  bool _isTyping = false;
  bool _isStreaming = false;
  bool _isCancellable = false;
  bool _isStopping = false;
  String _selectedImageSize = '1024x1024';
  String _selectedImageStype = '';
  String _selectedVideoRatio = '';

  final List<File> _selectedImages = [];
  final List<File> _selectedFiles = [];
  List<Message> _messages = [];
  int _messageRevision = 0;
  String _streamingResponse = '';
  List<String> _streamingFiles = const [];
  String _reasoningResponse = '';
  ModelTokenUsage _streamingTokenUsage = ModelTokenUsage.empty;
  final List<MessageToolCall> _toolCalls = [];
  final List<MessageCommandExecution> _commandExecutions = [];
  final List<MessageSkillActivation> _skillActivations = [];
  bool _followLatest = true;
  bool _showJumpToLatest = false;
  String? _generationError;
  String? _handledTerminalRunId;
  String? _pendingDraftText;
  List<File> _pendingDraftImages = const [];
  List<File> _pendingDraftFiles = const [];

  @override
  void initState() {
    super.initState();
    _autofocusComposer = _composerFocusRequests.remove(widget.id);
    _messageController =
        TextEditingController()..addListener(_persistTextDraft);
    _scrollController.addListener(_handleScrollPositionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesInitialized) return;
    _dependenciesInitialized = true;
    _chatViewModel = AppScope.of(
      context,
    ).createChatViewModel(widget.id, widget.bot);
    _generationViewModel =
        _chatViewModel.generationViewModel
          ..addListener(_handleGenerationChanged);
    _handleGenerationChanged();
    unawaited(_restoreConversationDraft());
    _loadMessages();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dependenciesInitialized && oldWidget.bot != widget.bot) {
      _chatViewModel.updateBot(widget.bot);
    }
  }

  void _handleGenerationChanged() {
    if (!mounted) return;
    final snapshot = _generationViewModel.snapshot;
    final terminalMessage = snapshot.terminalMessage;
    final isNewTerminal =
        snapshot.lifecycle.isTerminal &&
        snapshot.runId != null &&
        _handledTerminalRunId != snapshot.runId;
    final submittedUserMessage = snapshot.submittedUserMessage;
    var addedSubmittedUser = false;
    var messagesChanged = false;

    if (snapshot.userPersisted && submittedUserMessage != null) {
      final index = _messages.indexWhere(
        (message) => message.messageId == submittedUserMessage.messageId,
      );
      if (index < 0) {
        _messages.add(submittedUserMessage);
        _messages.sort(
          (left, right) => left.timestamp.compareTo(right.timestamp),
        );
        addedSubmittedUser = true;
        messagesChanged = true;
      } else if (!identical(_messages[index], submittedUserMessage)) {
        _messages[index] = submittedUserMessage;
        messagesChanged = true;
      }
    }

    if (isNewTerminal) {
      _handledTerminalRunId = snapshot.runId;
      if (!snapshot.userPersisted) {
        final previousLength = _messages.length;
        _messages.removeWhere(
          (message) =>
              message.turnId == snapshot.turnId && message.runId.isEmpty,
        );
        messagesChanged = messagesChanged || _messages.length != previousLength;
        _restorePendingDraft();
      } else {
        _clearPendingDraft();
      }
      if (terminalMessage != null &&
          !_messages.any(
            (message) => message.messageId == terminalMessage.messageId,
          )) {
        _messages.add(terminalMessage);
        messagesChanged = true;
      }
      _chatViewModel.notifyChatListChanged();
    }

    setState(() {
      if (messagesChanged) _messageRevision += 1;
      _isTyping = snapshot.lifecycle.isRunning;
      _isStreaming =
          snapshot.lifecycle.isRunning &&
          (snapshot.streamingResponse.isNotEmpty ||
              snapshot.reasoningResponse.isNotEmpty ||
              snapshot.toolCalls.isNotEmpty ||
              snapshot.commandExecutions.isNotEmpty ||
              snapshot.skillActivations.isNotEmpty ||
              snapshot.localFiles.isNotEmpty);
      _isCancellable = snapshot.canCancel;
      _isStopping = snapshot.lifecycle == ChatRunLifecycle.stopping;
      _streamingResponse = snapshot.streamingResponse;
      _streamingFiles = List<String>.of(snapshot.localFiles);
      _reasoningResponse = snapshot.reasoningResponse;
      _streamingTokenUsage = snapshot.tokenUsage;
      _toolCalls
        ..clear()
        ..addAll(snapshot.toolCalls);
      _commandExecutions
        ..clear()
        ..addAll(snapshot.commandExecutions);
      _skillActivations
        ..clear()
        ..addAll(snapshot.skillActivations);
      if (snapshot.error != null) {
        _generationError = safeFailureMessage(context, snapshot.error!);
      } else if (snapshot.lifecycle.isRunning ||
          snapshot.lifecycle.isTerminal) {
        _generationError = null;
      }
    });

    if (isNewTerminal) {
      _scheduleScrollToLatest(animate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _generationViewModel.snapshot.lifecycle.isTerminal) {
          _generationViewModel.acknowledgeTerminal();
        }
      });
    } else if (addedSubmittedUser) {
      _scheduleScrollToLatest(animate: true);
    }
  }

  Future<void> _loadMessages() async {
    final cachedMessages = _chatViewModel.cachedMessages;
    if (cachedMessages != null) {
      final mergedMessages = _mergeLoadedMessages(cachedMessages);
      setState(() {
        _messages = mergedMessages;
        _messageRevision += 1;
        _isLoading = false;
        _historyError = null;
        _followLatest = true;
        _showJumpToLatest = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _historyError = null;
    });

    try {
      await _chatViewModel.loadMessages();
      final messages = _chatViewModel.messages;
      final historyError = _chatViewModel.historyError;
      if (historyError != null) throw historyError;
      if (!mounted) return;
      final mergedMessages = _mergeLoadedMessages(messages);
      setState(() {
        _messages = mergedMessages;
        _messageRevision += 1;
        _isLoading = false;
        _followLatest = true;
        _showJumpToLatest = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _historyError = safeFailureMessage(context, error);
      });
    }
  }

  List<Message> _mergeLoadedMessages(List<Message> loaded) {
    final snapshot = _generationViewModel.snapshot;
    final activeAssistantMessageId =
        snapshot.lifecycle.isRunning && snapshot.runId != null
            ? '${snapshot.runId}:assistant'
            : null;
    final merged = <Message>[
      for (final message in loaded)
        if (message.messageId != activeAssistantMessageId) message,
    ];
    final indexesById = <String, int>{
      for (var index = 0; index < merged.length; index++)
        if (merged[index].messageId.isNotEmpty) merged[index].messageId: index,
    };
    for (final message in _messages) {
      final messageId = message.messageId;
      final existingIndex = indexesById[messageId];
      if (messageId.isEmpty || existingIndex == null) {
        if (messageId.isNotEmpty) indexesById[messageId] = merged.length;
        merged.add(message);
      } else {
        // The in-memory snapshot may have reached a newer terminal state while
        // the database query was in flight, so it wins for the same message.
        merged[existingIndex] = message;
      }
    }
    merged.sort((left, right) => left.timestamp.compareTo(right.timestamp));
    return merged;
  }

  @override
  void dispose() {
    if (_dependenciesInitialized) unawaited(_persistDraft());
    if (_dependenciesInitialized) {
      _generationViewModel.removeListener(_handleGenerationChanged);
      _chatViewModel.dispose();
    }
    _scrollController.removeListener(_handleScrollPositionChanged);
    _scrollController.dispose();
    _messageController
      ..removeListener(_persistTextDraft)
      ..dispose();
    super.dispose();
  }

  void _persistTextDraft() {
    if (_dependenciesInitialized) unawaited(_persistDraft());
  }

  Future<void> _persistDraft() => _chatViewModel.writeDraft(
    ConversationDraft(
      text: _messageController.text,
      imagePaths: [for (final image in _selectedImages) image.path],
      filePaths: [for (final file in _selectedFiles) file.path],
    ),
  );

  Future<void> _restoreConversationDraft() async {
    final draft = await _chatViewModel.readDraft();
    if (!mounted || draft == null) return;
    setState(() {
      if (_messageController.text.isEmpty) {
        _messageController.text = draft.text;
        _messageController.selection = TextSelection.collapsed(
          offset: draft.text.length,
        );
      }
      if (_selectedImages.isEmpty) {
        _selectedImages.addAll(draft.imagePaths.map(File.new));
      }
      if (_selectedFiles.isEmpty) {
        _selectedFiles.addAll(draft.filePaths.map(File.new));
      }
    });
  }

  void _handleScrollPositionChanged() {
    if (!_scrollController.hasClients) return;

    final nearLatest =
        _scrollController.position.extentBefore <= _followLatestThreshold;
    if (_scrollController.position.extentAfter <= 240 &&
        _chatViewModel.hasEarlierMessages &&
        !_isLoadingEarlier) {
      unawaited(_loadEarlierMessages());
    }
    if (_followLatest == nearLatest && _showJumpToLatest == !nearLatest) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _followLatest = nearLatest;
      _showJumpToLatest = !nearLatest;
    });
  }

  Future<void> _loadEarlierMessages() async {
    if (_isLoadingEarlier || !_chatViewModel.hasEarlierMessages) return;
    setState(() => _isLoadingEarlier = true);
    try {
      final messages = await _chatViewModel.loadEarlierMessages();
      if (!mounted) return;
      setState(() {
        _messages = _mergeLoadedMessages(messages);
        _messageRevision += 1;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _historyError = safeFailureMessage(context, error));
    } finally {
      if (mounted) setState(() => _isLoadingEarlier = false);
    }
  }

  void _scheduleScrollToLatest({bool force = false, bool animate = false}) {
    final shouldScroll = force || _followLatest;
    if (!shouldScroll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final target = _scrollController.position.minScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _jumpToLatest() {
    setState(() {
      _followLatest = true;
      _showJumpToLatest = false;
    });
    _scheduleScrollToLatest(force: true, animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    if (isDesktopPlatform(context)) {
      return _buildDesktopWorkspace(context, fontSize);
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.bot.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(Icons.cleaning_services_rounded, size: 24),
            tooltip: desktopConversationText(
              context,
              S.of(context).clearChatHistory,
            ),
            onPressed: requestClearChat,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(child: _buildConversationBody(context, fontSize)),
              _buildAttachmentsBar(),
              _buildToolApprovalCard(isDesktop: false),
              _buildGenerationAlert(isDesktop: false),
              MessageInput(
                provider: _provider,
                controller: _messageController,
                requestInProgress: _isTyping,
                canCancel: _isCancellable,
                isStopping: _isStopping,
                autofocus: _autofocusComposer,
                focusRequestToken: _composerFocusToken,
                hasPendingAttachments:
                    _selectedFiles.isNotEmpty || _selectedImages.isNotEmpty,
                onCameraPressed: getAttachImageFromCamera,
                onGalleryPressed: getAttachImageFromGallery,
                onFilePressed: getAttacheFile,
                onImageSizeSelected: (size) {
                  setState(() {
                    _selectedImageSize = size;
                  });
                },
                onImageStyleSelected: (style) {
                  setState(() {
                    _selectedImageStype = style;
                  });
                },
                onVideoRatioSelected: (ratio) {
                  setState(() {
                    _selectedVideoRatio = ratio;
                  });
                },
                onSend: _sendMessage,
                onCancelRequest: _cancelRequest,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  MessageProcessInfo _buildStreamingProcessInfo() {
    if (!_isStreaming && !_isTyping) {
      return const MessageProcessInfo();
    }

    return _buildProcessInfo(
      reasoningStatus: _provider.getDeepThinking() ? 'streaming' : '',
      toolCalls: _toolCalls,
      commandExecutions: _commandExecutions,
      skillActivations: _skillActivations,
    );
  }

  MessageProcessInfo _buildProcessInfo({
    String reasoningStatus = '',
    int? durationMs,
    List<MessageToolCall> toolCalls = const [],
    List<MessageCommandExecution> commandExecutions = const [],
    List<MessageSkillActivation> skillActivations = const [],
    List<String> imagePaths = const [],
    List<String> filePaths = const [],
    String audioPath = '',
    String musicPath = '',
    String videoPath = '',
    String fileStatus = '',
    String? imageDetail,
    String? fileDetail,
    String? audioDetail,
    String? musicDetail,
    String? videoDetail,
  }) {
    final fileEdits = <MessageFileEdit>[
      ...imagePaths.map(
        (imagePath) => MessageFileEdit(
          path: imagePath,
          type: 'image',
          status: fileStatus,
          detail:
              imageDetail ??
              (fileStatus == 'attached'
                  ? S.of(context).imageAttachment
                  : S.of(context).imageResult),
        ),
      ),
      ...filePaths.map(
        (filePath) => MessageFileEdit(
          path: filePath,
          type: 'file',
          status: fileStatus,
          detail:
              fileDetail ??
              (fileStatus == 'attached'
                  ? S.of(context).fileAttachment
                  : S.of(context).fileResult),
        ),
      ),
    ];

    if (audioPath.isNotEmpty) {
      fileEdits.add(
        MessageFileEdit(
          path: audioPath,
          type: 'audio',
          status: fileStatus,
          detail: audioDetail ?? S.of(context).speechResult,
        ),
      );
    }
    if (musicPath.isNotEmpty) {
      fileEdits.add(
        MessageFileEdit(
          path: musicPath,
          type: 'music',
          status: fileStatus,
          detail:
              musicDetail ??
              (fileStatus == 'attached'
                  ? S.of(context).referenceAudio
                  : S.of(context).musicResult),
        ),
      );
    }
    if (videoPath.isNotEmpty) {
      fileEdits.add(
        MessageFileEdit(
          path: videoPath,
          type: 'video',
          status: fileStatus,
          detail: videoDetail ?? S.of(context).videoResult,
        ),
      );
    }

    return MessageProcessInfo(
      reasoningStatus: reasoningStatus,
      durationMs: durationMs,
      toolCalls: List<MessageToolCall>.from(toolCalls),
      commandExecutions: List<MessageCommandExecution>.from(commandExecutions),
      fileEdits: fileEdits,
      skillActivations: List<MessageSkillActivation>.from(skillActivations),
    );
  }
}

class ChatGenerationErrorAlert extends StatelessWidget {
  const ChatGenerationErrorAlert({
    super.key,
    required this.error,
    required this.isDesktop,
    required this.onDismiss,
  });

  final String error;
  final bool isDesktop;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => StarsInlineErrorAlert(
    error: error,
    isDesktop: isDesktop,
    onDismiss: onDismiss,
    alertKey: const ValueKey<String>('chat-generation-error-alert'),
    messageKey: const ValueKey<String>('chat-generation-error-message'),
    dismissKey: const ValueKey<String>('dismiss-chat-generation-error'),
  );
}
