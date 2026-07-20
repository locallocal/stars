import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/services/chat_generation_controller.dart';
import 'package:stars/model/model.dart';
import 'package:stars/services/providers/providers.dart';
import 'package:stars/pages/common/attachment.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/chat/attachments.dart';
import 'package:stars/pages/common/common.dart';
import 'package:stars/pages/chat/clear_chat_dialog.dart';
import 'package:stars/pages/chat/desktop_chat_primitives.dart';
import 'package:stars/pages/chat/message_input.dart';
import 'package:stars/pages/chat/welcome_view.dart';
import 'package:stars/pages/chat/message_list.dart';
import 'package:stars/pages/chat/typing_indicator.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/features/chat/view_models/chat_view_model.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

// 聊天页面
class ChatPage extends StatefulWidget {
  final Bot bot;
  final String id;

  const ChatPage({super.key, required this.id, required this.bot});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  static const double _followLatestThreshold = 96;
  static final Set<String> _composerFocusRequests = <String>{};
  static final Map<String, String> _draftsByChat = <String, String>{};
  static final Map<String, List<File>> _draftImagesByChat =
      <String, List<File>>{};
  static final Map<String, List<File>> _draftFilesByChat =
      <String, List<File>>{};
  static final Map<String, _PendingChatDraft> _pendingDraftsByChat =
      <String, _PendingChatDraft>{};

  static void requestComposerFocus(String chatId) {
    _composerFocusRequests.add(chatId);
  }

  late final ChatGenerationController _generationController;
  late final ChatViewModel _chatViewModel;
  bool _dependenciesInitialized = false;
  Provider get _provider => _generationController.capabilityProvider;
  final String _currentUserId = 'me';
  late final TextEditingController _messageController;
  late final bool _autofocusComposer;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
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
  String _streamingResponse = '';
  String _reasoningResponse = '';
  Stopwatch? _processStopwatch;
  final List<MessageToolCall> _toolCalls = [];
  final List<MessageCommandExecution> _commandExecutions = [];
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
    final pendingDraft = _pendingDraftsByChat[widget.id];
    _pendingDraftText = pendingDraft?.text;
    _pendingDraftImages = pendingDraft?.images ?? const [];
    _pendingDraftFiles = pendingDraft?.files ?? const [];
    _messageController = TextEditingController(
      text: _draftsByChat[widget.id] ?? '',
    )..addListener(_persistTextDraft);
    _selectedImages.addAll(_draftImagesByChat[widget.id] ?? const []);
    _selectedFiles.addAll(_draftFilesByChat[widget.id] ?? const []);
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
    _generationController =
        _chatViewModel.generationController
          ..addListener(_handleGenerationChanged);
    _handleGenerationChanged();
    _loadMessages();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dependenciesInitialized && oldWidget.bot != widget.bot) {
      _generationController.updateBot(widget.bot);
    }
  }

  void _handleGenerationChanged() {
    if (!mounted) return;
    final snapshot = _generationController.snapshot;
    final terminalMessage = snapshot.terminalMessage;
    final isNewTerminal =
        snapshot.lifecycle.isTerminal &&
        snapshot.runId != null &&
        _handledTerminalRunId != snapshot.runId;

    if (isNewTerminal) {
      _handledTerminalRunId = snapshot.runId;
      if (!snapshot.userPersisted) {
        _messages.removeWhere(
          (message) =>
              message.turnId == snapshot.turnId && message.runId.isEmpty,
        );
        _restorePendingDraft();
      } else {
        _clearPendingDraft();
      }
      if (terminalMessage != null &&
          !_messages.any(
            (message) => message.messageId == terminalMessage.messageId,
          )) {
        _messages.add(terminalMessage);
      }
      _chatViewModel.notifyChatListChanged();
    }

    setState(() {
      _isTyping = snapshot.lifecycle.isRunning;
      _isStreaming =
          snapshot.lifecycle.isRunning &&
          (snapshot.streamingResponse.isNotEmpty ||
              snapshot.reasoningResponse.isNotEmpty ||
              snapshot.toolCalls.isNotEmpty ||
              snapshot.commandExecutions.isNotEmpty);
      _isCancellable = snapshot.canCancel;
      _isStopping = snapshot.lifecycle == ChatRunLifecycle.stopping;
      _streamingResponse = snapshot.streamingResponse;
      _reasoningResponse = snapshot.reasoningResponse;
      _toolCalls
        ..clear()
        ..addAll(snapshot.toolCalls);
      _commandExecutions
        ..clear()
        ..addAll(snapshot.commandExecutions);
      if (snapshot.error != null) {
        _generationError = snapshot.error;
      } else if (snapshot.lifecycle.isRunning ||
          snapshot.lifecycle.isTerminal) {
        _generationError = null;
      }
    });

    if (isNewTerminal) {
      _scheduleScrollToLatest(animate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _generationController.snapshot.lifecycle.isTerminal) {
          _generationController.acknowledgeTerminal();
        }
      });
    }
  }

  Future<void> _loadMessages() async {
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
      setState(() {
        _messages = _mergeLoadedMessages(messages);
        _isLoading = false;
        _followLatest = true;
        _showJumpToLatest = false;
      });
      _scheduleScrollToLatest(force: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _historyError = error.toString();
      });
    }
  }

  List<Message> _mergeLoadedMessages(List<Message> loaded) {
    final merged = List<Message>.of(loaded);
    final knownIds = <String>{
      for (final message in loaded)
        if (message.messageId.isNotEmpty) message.messageId,
    };
    for (final message in _messages) {
      if (message.messageId.isNotEmpty && knownIds.add(message.messageId)) {
        merged.add(message);
      }
    }
    merged.sort((left, right) => left.timestamp.compareTo(right.timestamp));
    return merged;
  }

  @override
  void dispose() {
    _persistAttachmentDrafts();
    if (_dependenciesInitialized) {
      _generationController.removeListener(_handleGenerationChanged);
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
    final value = _messageController.text;
    if (value.isEmpty) {
      _draftsByChat.remove(widget.id);
    } else {
      _draftsByChat[widget.id] = value;
    }
  }

  void _persistAttachmentDrafts() {
    if (_selectedImages.isEmpty) {
      _draftImagesByChat.remove(widget.id);
    } else {
      _draftImagesByChat[widget.id] = List<File>.of(_selectedImages);
    }
    if (_selectedFiles.isEmpty) {
      _draftFilesByChat.remove(widget.id);
    } else {
      _draftFilesByChat[widget.id] = List<File>.of(_selectedFiles);
    }
  }

  void _handleScrollPositionChanged() {
    if (!_scrollController.hasClients) return;

    final nearLatest =
        _scrollController.position.extentAfter <= _followLatestThreshold;
    if (_followLatest == nearLatest && _showJumpToLatest == !nearLatest) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _followLatest = nearLatest;
      _showJumpToLatest = !nearLatest;
    });
  }

  void _scheduleScrollToLatest({bool force = false, bool animate = false}) {
    final shouldScroll = force || _followLatest;
    if (!shouldScroll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final target = _scrollController.position.maxScrollExtent;
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

  // 从相机获取图片
  Future<void> getAttachImageFromCamera() async {
    final image = await getImageFromCamera();
    if (image != null && mounted) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  // 从相册获取图片
  Future<void> getAttachImageFromGallery() async {
    final image = await getImageFromGallery();
    if (image != null && mounted) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  // 获取文件
  Future<void> getAttacheFile() async {
    final file = await pickFile();
    if (file != null && mounted) {
      setState(() {
        _selectedFiles.add(file);
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_isTyping) {
      return;
    }
    if (_generationError != null) {
      setState(() {
        _generationError = null;
      });
    }
    if (_provider.getOutputModalites().contains(OutputModality.image) &&
        _selectedImageSize.isNotEmpty) {
      await _generateImage();
      return;
    } else if (_provider.getOutputModalites().contains(OutputModality.speech)) {
      await _generateSpeech();
      return;
    } else if (_provider.getOutputModalites().contains(OutputModality.music)) {
      await _generateMusic();
      return;
    } else if (_provider.getOutputModalites().contains(OutputModality.video)) {
      await _generateVideo();
      return;
    }
    await _generateText();
  }

  Future<void> _generateText() async {
    final bool hasText = _messageController.text.trim().isNotEmpty;
    final bool hasImages = _selectedImages.isNotEmpty;
    final bool hasFiles = _selectedFiles.isNotEmpty;
    if (!hasText && !hasImages && !hasFiles) return;

    final messageText = _messageController.text;
    _pendingDraftText = messageText;
    _pendingDraftImages = List<File>.of(_selectedImages);
    _pendingDraftFiles = List<File>.of(_selectedFiles);
    _pendingDraftsByChat[widget.id] = _PendingChatDraft(
      text: messageText,
      images: _pendingDraftImages,
      files: _pendingDraftFiles,
    );
    _chatViewModel.generationRegistry.setNonCancellableRunActive(
      widget.id,
      true,
    );
    setState(() {
      _isTyping = true;
      _isStreaming = false;
      _isCancellable = false;
      _isStopping = false;
    });

    String? optimisticMessageId;
    try {
      final imagePaths = await _getSelectedImagePaths();
      final filePahts = await _getSelectedFilePaths();
      if (!mounted) return;

      final turnId = _chatViewModel.createId('turn');
      final userMessage = Message(
        messageId: _chatViewModel.createId('message'),
        turnId: turnId,
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: _currentUserId,
        content: messageText,
        images: imagePaths,
        files: filePahts,
        processInfo: _buildProcessInfo(
          imagePaths: imagePaths,
          filePaths: filePahts,
          fileStatus: 'attached',
        ),
        timestamp: DateTime.now(),
      );
      optimisticMessageId = userMessage.messageId;

      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
        _generationError = null;
        _streamingResponse = '';
        _selectedImages.clear();
        _selectedFiles.clear();
        _followLatest = true;
        _showJumpToLatest = false;
      });

      _scheduleScrollToLatest(force: true, animate: true);

      final chatMessages = <ChatMessage>[];
      if (widget.bot.systemPrompt.isNotEmpty) {
        chatMessages.add(
          ChatMessage(role: 'system', content: widget.bot.systemPrompt),
        );
      }
      var pendingUserMessage = '';
      if (_messages.length > 1) {
        var startIndex = _messages.length > 100 ? _messages.length - 100 : 0;
        for (var i = startIndex; i < _messages.length - 1; i++) {
          if (_messages[i].senderId == _currentUserId) {
            startIndex = i;
            break;
          }
        }
        for (var i = startIndex; i < _messages.length - 1; i++) {
          final message = _messages[i];
          if (message.senderId == _currentUserId) {
            pendingUserMessage =
                pendingUserMessage.isEmpty
                    ? message.content
                    : '$pendingUserMessage\n${message.content}';
            continue;
          }
          if (pendingUserMessage.isNotEmpty) {
            chatMessages.add(
              ChatMessage(role: 'user', content: pendingUserMessage),
            );
            pendingUserMessage = '';
          }
          chatMessages.add(
            ChatMessage(role: 'assistant', content: message.content),
          );
        }
      }
      final latestContent =
          pendingUserMessage.isEmpty
              ? messageText
              : '$pendingUserMessage\n$messageText';
      chatMessages.add(
        ChatMessage(
          role: 'user',
          content: latestContent,
          images: userMessage.images,
          files: userMessage.files,
        ),
      );

      _chatViewModel.generationRegistry.setNonCancellableRunActive(
        widget.id,
        false,
      );
      await _generationController.startText(
        userMessage: userMessage,
        messages: chatMessages,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (optimisticMessageId != null) {
          _messages.removeWhere(
            (message) => message.messageId == optimisticMessageId,
          );
        }
        _restorePendingDraft();
        _generationError = error.toString();
      });
    } finally {
      _chatViewModel.generationRegistry.setNonCancellableRunActive(
        widget.id,
        false,
      );
      if (mounted && !_generationController.snapshot.lifecycle.isRunning) {
        setState(() {
          _isTyping = false;
          _isCancellable = false;
          _isStopping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    if (isDesktopOrTabletPlatform(context)) {
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

  Widget _buildDesktopWorkspace(BuildContext context, double? fontSize) {
    return Container(
      color: StarsDesktopTheme.workspaceBackground(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: StarsDesktopTheme.panelBackground(context),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                child: _buildConversationBody(
                  context,
                  fontSize,
                  isDesktop: true,
                ),
              ),
            ),
            _buildDesktopInputSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopInputSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      decoration: BoxDecoration(
        color: StarsDesktopTheme.panelBackground(context),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: StarsDesktopTheme.inputMaxWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttachmentsBar(desktopMode: true),
              _buildGenerationAlert(isDesktop: true),
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
                desktopMode: true,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationBody(
    BuildContext context,
    double? fontSize, {
    bool isDesktop = false,
  }) {
    if (_isLoading) {
      return Center(
        child:
            isDesktop
                ? const SizedBox(width: 120, child: ShadProgress())
                : const CircularProgressIndicator(),
      );
    }
    if (_historyError != null && _messages.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ShadAlert.destructive(
            icon: Icon(
              isDesktop ? LucideIcons.circleAlert : Icons.error_outline,
            ),
            title: Text(S.of(context).unableToLoadMessages),
            description: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_historyError!),
                const SizedBox(height: 12),
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: _loadMessages,
                  leading: const Icon(LucideIcons.refreshCw, size: 16),
                  child: Text(S.of(context).retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final conversation =
        _messages.isEmpty
            ? WelcomeView(
              bot: widget.bot,
              fontSize: fontSize,
              isDesktop: isDesktop,
            )
            : Column(
              children: [
                MessageList(
                  messages: _messages,
                  scrollController: _scrollController,
                  isStreaming: _isStreaming,
                  streamingResponse: _streamingResponse,
                  streamingProcessInfo: _buildStreamingProcessInfo(),
                  currentUserId: _currentUserId,
                  deepThinking: _provider.getDeepThinking(),
                  reasoningResponse: _reasoningResponse,
                  isDesktop: isDesktop,
                ),
                if (_isTyping && !_isStreaming)
                  TypingIndicator(
                    botName: widget.bot.name,
                    isDesktop: isDesktop,
                  ),
              ],
            );

    return Stack(
      children: [
        Positioned.fill(child: conversation),
        if (_showJumpToLatest && _messages.isNotEmpty)
          Positioned(
            right: isDesktop ? 20 : 12,
            bottom: _isTyping ? 60 : 12,
            child:
                isDesktop
                    ? ShadButton.secondary(
                      size: ShadButtonSize.sm,
                      onPressed: _jumpToLatest,
                      leading: const Icon(LucideIcons.arrowDown, size: 16),
                      child: Text(S.of(context).jumpToLatest),
                    )
                    : FilledButton.tonalIcon(
                      onPressed: _jumpToLatest,
                      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                      label: Text(S.of(context).jumpToLatest),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
          ),
      ],
    );
  }

  Widget _buildAttachmentsBar({bool desktopMode = false}) {
    if (_selectedFiles.isEmpty && _selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }
    return ImageAttachments(
      images: _selectedImages,
      files: _selectedFiles,
      desktopMode: desktopMode,
      onClearAll: () {
        setState(() {
          _selectedImages.clear();
          _selectedFiles.clear();
        });
      },
      onRemoveImage: (index) {
        setState(() {
          _selectedImages.removeAt(index);
        });
      },
      onRemoveFile: (index) {
        setState(() {
          _selectedFiles.removeAt(index);
        });
      },
    );
  }

  Widget _buildGenerationAlert({required bool isDesktop}) {
    final error = _generationError;
    if (error == null || error.isEmpty) return const SizedBox.shrink();

    final closeLabel = MaterialLocalizations.of(context).closeButtonTooltip;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadAlert.destructive(
        icon: const Icon(LucideIcons.circleAlert, size: 18),
        description: Text(error),
        trailing:
            isDesktop
                ? StarsDesktopIconAction(
                  icon: LucideIcons.x,
                  label: closeLabel,
                  onPressed: _dismissGenerationError,
                )
                : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: closeLabel,
                  onPressed: _dismissGenerationError,
                ),
      ),
    );
  }

  void _dismissGenerationError() {
    setState(() {
      _generationError = null;
    });
  }

  Future<void> requestClearChat() async {
    final shouldClear = await showClearChatDialog(context, widget.bot.name);
    if (!mounted) return;
    if (shouldClear) {
      if (!await _confirmStopBeforeMutation()) return;
      if (!mounted) return;
      await _clearChatMessages();
    }
  }

  Future<void> _clearChatMessages() async {
    try {
      await _chatViewModel.clearHistory();
      if (!mounted) return;
      setState(() {
        _messages = [];
        _historyError = null;
        _composerFocusToken += 1;
      });
      _chatViewModel.notifyChatListChanged();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _generationError = desktopConversationText(
          context,
          S.of(context).clearChatFailed(error.toString()),
        );
      });
    }
  }

  Future<bool> _confirmStopBeforeMutation() async {
    final registry = _chatViewModel.generationRegistry;
    if (!registry.hasBlockingRun(widget.id)) return true;
    if (!registry.supportsCancellationForRun(widget.id)) {
      setState(() {
        _generationError = S.of(context).activeRequestCannotCancel;
      });
      return false;
    }

    final shouldStop = await showChatShadDialog<bool>(
      context: context,
      variant: ShadDialogVariant.alert,
      builder:
          (dialogContext) => ShadDialog.alert(
            title: Text(S.of(dialogContext).stopGenerationBeforeLeaving),
            description: Text(
              S.of(dialogContext).stopGenerationBeforeLeavingDescription,
            ),
            actions: [
              ShadButton.outline(
                autofocus: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(S.of(dialogContext).cancel),
              ),
              ShadButton.secondary(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                leading: const Icon(LucideIcons.square, size: 16),
                child: Text(S.of(dialogContext).stopAndContinue),
              ),
            ],
          ),
    );
    if (shouldStop != true || !mounted) return false;

    final stopped = await registry.stopForNavigation(widget.id);
    if (!stopped && mounted) {
      setState(() {
        _generationError = S.of(context).activeRequestCannotCancel;
      });
    }
    return stopped;
  }

  Future<void> _cancelRequest() async {
    if (!_isCancellable) return;
    final lifecycle = await _generationController.cancel();
    if (!mounted) return;
    if (lifecycle == ChatRunLifecycle.cancelled) {
      if (isDesktopOrTabletPlatform(context)) {
        ShadSonner.of(
          context,
        ).show(ShadToast(title: Text(S.of(context).replyCancelled)));
      } else {
        showSnackBar(context, S.of(context).replyCancelled);
      }
    }
  }

  Future<bool> stopActiveRunForNavigation() =>
      _chatViewModel.generationRegistry.stopForNavigation(widget.id);

  void _restorePendingDraft() {
    final text = _pendingDraftText;
    if (text != null && _messageController.text.isEmpty) {
      _messageController.text = text;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    }
    if (_selectedImages.isEmpty) {
      _selectedImages.addAll(_pendingDraftImages);
    }
    if (_selectedFiles.isEmpty) {
      _selectedFiles.addAll(_pendingDraftFiles);
    }
    _clearPendingDraft();
  }

  void _clearPendingDraft() {
    _pendingDraftsByChat.remove(widget.id);
    _pendingDraftText = null;
    _pendingDraftImages = const [];
    _pendingDraftFiles = const [];
  }

  Future<List<String>> _getSelectedImagePaths() async {
    List<String> imagePaths = [];
    if (_selectedImages.isNotEmpty) {
      final chatDir = await getChatDirectoryPath(widget.id);

      for (var image in _selectedImages) {
        final fileName = path.basename(image.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final targetPath = path.join(chatDir, '${fileName}_$timestamp');

        try {
          await image.copy(targetPath);
          imagePaths.add(targetPath);
        } catch (e) {
          debugPrint('Copy image ${image.path} failed: $e');
        }
      }
    }
    return imagePaths;
  }

  Future<List<String>> _getSelectedFilePaths() async {
    List<String> filePaths = [];
    if (_selectedFiles.isNotEmpty) {
      final chatDir = await getChatDirectoryPath(widget.id);

      for (var file in _selectedFiles) {
        final fileName = path.basename(file.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final targetPath = path.join(chatDir, '${fileName}_$timestamp');

        try {
          await file.copy(targetPath);
          filePaths.add(targetPath);
        } catch (e) {
          debugPrint('Copy image ${file.path} failed: $e');
        }
      }
    }
    return filePaths;
  }

  Future<void> _generateImage() async {
    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      showSnackBar(context, S.of(context).pleaseEnterImageDescription);
      return;
    }
    final chatId = widget.id;
    final bot = widget.bot;
    final runId = _chatViewModel.createId('run');
    final turnId = _chatViewModel.createId('turn');
    final originalImages = List<File>.of(_selectedImages);
    final imageAttachmentDetail = S.of(context).imageAttachment;
    final imageResultDetail = S.of(context).imageResult;
    final generatedPreview = S.of(context).generatedImage;
    var userPersisted = false;
    _beginNonCancellableRun(chatId);

    try {
      _startProcessTracking();
      final imagePaths = await _getSelectedImagePaths();
      if (!mounted) return;
      final userMessage = Message(
        messageId: '$runId:user',
        turnId: turnId,
        runId: runId,
        chatId: chatId,
        botId: bot.id,
        senderId: _currentUserId,
        content: prompt,
        images: imagePaths,
        processInfo: _buildProcessInfo(
          imagePaths: imagePaths,
          fileStatus: 'attached',
          imageDetail: imageAttachmentDetail,
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _selectedImages.clear();
        _messageController.clear();
      });
      await _chatViewModel.upsertMessage(userMessage);
      userPersisted = true;
      try {
        await _chatViewModel.updateLastMessage(userMessage.content);
      } catch (error) {
        debugPrint('Failed to update chat preview for $chatId: $error');
      }

      final imageDirPath = await getChatDirectoryPath(chatId);
      final params = {
        'prompt': prompt,
        'size': _selectedImageSize,
        'dirPath': imageDirPath,
        'referenceImages': imagePaths,
        'style': _selectedImageStype,
      };
      final imagePath = await compute(_generateImageInBackground, {
        'bot': bot,
        'params': params,
      });

      final botMessage = Message(
        messageId: '$runId:assistant',
        turnId: turnId,
        runId: runId,
        chatId: chatId,
        botId: bot.id,
        senderId: bot.id,
        content: '',
        images: imagePath,
        processInfo: _buildProcessInfo(
          durationMs: _stopProcessTracking(),
          imagePaths: imagePath,
          fileStatus: 'created',
          imageDetail: imageResultDetail,
        ),
        terminalOutcome: MessageTerminalOutcome.completed,
        timestamp: DateTime.now(),
      );
      final persistedBot = await _chatViewModel.upsertMessage(botMessage);
      try {
        await _chatViewModel.updateLastMessage(generatedPreview);
      } catch (error) {
        debugPrint('Failed to update chat preview for $chatId: $error');
      }

      if (mounted) {
        setState(() {
          _messages.add(persistedBot);
        });
        _scheduleScrollToLatest(animate: true);
      }
    } catch (e) {
      final failedMessage =
          userPersisted
              ? await _persistMediaFailure(
                runId: runId,
                turnId: turnId,
                chatId: chatId,
                botId: bot.id,
                durationMs: _stopProcessTracking(),
              )
              : null;
      _resetProcessTracking();
      if (mounted) {
        setState(() {
          if (!userPersisted) {
            _messages.removeWhere((message) => message.runId == runId);
            if (_messageController.text.isEmpty) {
              _messageController.text = prompt;
            }
            if (_selectedImages.isEmpty) {
              _selectedImages.addAll(originalImages);
            }
          } else if (failedMessage != null &&
              !_messages.any(
                (message) => message.messageId == failedMessage.messageId,
              )) {
            _messages.add(failedMessage);
          }
          _generationError = S.of(context).generateImageFailed(e.toString());
        });
      }
    } finally {
      _finishNonCancellableRun(chatId);
    }
  }

  Future<void> _generateSpeech() async {
    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      showSnackBar(context, S.of(context).pleaseEnterSpeechDescription);
      return;
    }
    final chatId = widget.id;
    final bot = widget.bot;
    final runId = _chatViewModel.createId('run');
    final turnId = _chatViewModel.createId('turn');
    final speechResultDetail = S.of(context).speechResult;
    final generatedPreview = S.of(context).speechGenerated;
    var userPersisted = false;
    _beginNonCancellableRun(chatId);

    try {
      _startProcessTracking();
      final userMessage = Message(
        messageId: '$runId:user',
        turnId: turnId,
        runId: runId,
        chatId: chatId,
        botId: bot.id,
        senderId: _currentUserId,
        content: prompt,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
      });
      await _chatViewModel.upsertMessage(userMessage);
      userPersisted = true;
      try {
        await _chatViewModel.updateLastMessage(userMessage.content);
      } catch (error) {
        debugPrint('Failed to update chat preview for $chatId: $error');
      }

      List<String> voiceTypes = [];
      try {
        voiceTypes = _provider.getSupportVoicTypes();
      } catch (e) {
        // 忽略不支持的方法调用
      }

      String voiceType = '';
      if (voiceTypes.isNotEmpty) {
        voiceType = voiceTypes.first;
      }

      final outputDirPath = await getChatDirectoryPath(chatId);
      final params = {
        'prompt': prompt,
        'dirPath': outputDirPath,
        'voiceType': voiceType,
      };
      final audioPath = await compute(_generateSpeechInBackground, {
        'bot': bot,
        'params': params,
      });
      final botMessage = Message(
        messageId: '$runId:assistant',
        turnId: turnId,
        runId: runId,
        chatId: chatId,
        botId: bot.id,
        senderId: bot.id,
        content: '',
        audio: audioPath,
        processInfo: _buildProcessInfo(
          durationMs: _stopProcessTracking(),
          audioPath: audioPath,
          fileStatus: 'created',
          audioDetail: speechResultDetail,
        ),
        terminalOutcome: MessageTerminalOutcome.completed,
        timestamp: DateTime.now(),
      );
      final persistedBot = await _chatViewModel.upsertMessage(botMessage);
      try {
        await _chatViewModel.updateLastMessage(generatedPreview);
      } catch (error) {
        debugPrint('Failed to update chat preview for $chatId: $error');
      }

      if (mounted) {
        setState(() {
          _messages.add(persistedBot);
        });
        _scheduleScrollToLatest(animate: true);
      }
    } catch (e) {
      final failedMessage =
          userPersisted
              ? await _persistMediaFailure(
                runId: runId,
                turnId: turnId,
                chatId: chatId,
                botId: bot.id,
                durationMs: _stopProcessTracking(),
              )
              : null;
      _resetProcessTracking();
      if (mounted) {
        setState(() {
          if (!userPersisted) {
            _messages.removeWhere((message) => message.runId == runId);
            if (_messageController.text.isEmpty) {
              _messageController.text = prompt;
            }
          } else if (failedMessage != null &&
              !_messages.any(
                (message) => message.messageId == failedMessage.messageId,
              )) {
            _messages.add(failedMessage);
          }
          _generationError = S.of(context).generateSpeechFailed(e.toString());
        });
      }
    } finally {
      _finishNonCancellableRun(chatId);
    }
  }

  Future<void> _generateMusic() async {
    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      showSnackBar(context, S.of(context).pleaseEnterMusicDescription);
      return;
    }
    final chatId = widget.id;
    final bot = widget.bot;
    final runId = _chatViewModel.createId('run');
    final turnId = _chatViewModel.createId('turn');
    final originalFiles = List<File>.of(_selectedFiles);
    final referenceAudioDetail = S.of(context).referenceAudio;
    final musicResultDetail = S.of(context).musicResult;
    final generatedPreview = S.of(context).musicGenerated;
    var userPersisted = false;
    _beginNonCancellableRun(chatId);

    try {
      _startProcessTracking();
      final filePahts = await _getSelectedFilePaths();
      if (!mounted) return;
      var referMusicPath = '';
      if (filePahts.isNotEmpty) {
        referMusicPath = filePahts.first;
      }

      final userMessage = Message(
        messageId: '$runId:user',
        turnId: turnId,
        runId: runId,
        chatId: chatId,
        botId: bot.id,
        senderId: _currentUserId,
        content: prompt,
        music: referMusicPath,
        processInfo: _buildProcessInfo(
          musicPath: referMusicPath,
          fileStatus: 'attached',
          musicDetail: referenceAudioDetail,
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
        _selectedFiles.clear();
      });
      await _chatViewModel.upsertMessage(userMessage);
      userPersisted = true;
      try {
        await _chatViewModel.updateLastMessage(userMessage.content);
      } catch (error) {
        debugPrint('Failed to update chat preview for $chatId: $error');
      }

      final musicDirPath = await getChatDirectoryPath(chatId);
      final params = {
        'prompt': prompt,
        'dirPath': musicDirPath,
        'referMusicPath': referMusicPath,
      };
      final musicPath = await compute(_generateMusicInBackground, {
        'bot': bot,
        'params': params,
      });
      final botMessage = Message(
        messageId: '$runId:assistant',
        turnId: turnId,
        runId: runId,
        chatId: chatId,
        botId: bot.id,
        senderId: bot.id,
        content: '',
        audio: musicPath,
        processInfo: _buildProcessInfo(
          durationMs: _stopProcessTracking(),
          musicPath: musicPath,
          fileStatus: 'created',
          musicDetail: musicResultDetail,
        ),
        terminalOutcome: MessageTerminalOutcome.completed,
        timestamp: DateTime.now(),
      );
      final persistedBot = await _chatViewModel.upsertMessage(botMessage);
      try {
        await _chatViewModel.updateLastMessage(generatedPreview);
      } catch (error) {
        debugPrint('Failed to update chat preview for $chatId: $error');
      }

      if (mounted) {
        setState(() {
          _messages.add(persistedBot);
        });
        _scheduleScrollToLatest(animate: true);
      }
    } catch (e) {
      final failedMessage =
          userPersisted
              ? await _persistMediaFailure(
                runId: runId,
                turnId: turnId,
                chatId: chatId,
                botId: bot.id,
                durationMs: _stopProcessTracking(),
              )
              : null;
      _resetProcessTracking();
      if (mounted) {
        setState(() {
          if (!userPersisted) {
            _messages.removeWhere((message) => message.runId == runId);
            if (_messageController.text.isEmpty) {
              _messageController.text = prompt;
            }
            if (_selectedFiles.isEmpty) {
              _selectedFiles.addAll(originalFiles);
            }
          } else if (failedMessage != null &&
              !_messages.any(
                (message) => message.messageId == failedMessage.messageId,
              )) {
            _messages.add(failedMessage);
          }
          _generationError = S.of(context).generateMusicFailed(e.toString());
        });
      }
    } finally {
      _finishNonCancellableRun(chatId);
    }
  }

  Future<void> _generateVideo() async {
    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      showSnackBar(context, S.of(context).pleaseEnterVideoDescription);
      return;
    }
    final chatId = widget.id;
    final bot = widget.bot;
    final runId = _chatViewModel.createId('run');
    final turnId = _chatViewModel.createId('turn');
    final originalImages = List<File>.of(_selectedImages);
    final imageAttachmentDetail = S.of(context).imageAttachment;
    final videoResultDetail = S.of(context).videoResult;
    final generatedPreview = S.of(context).videoGenerated;
    var userPersisted = false;
    _beginNonCancellableRun(chatId);

    try {
      _startProcessTracking();
      final imagePaths = await _getSelectedImagePaths();
      if (!mounted) return;
      final userMessage = Message(
        messageId: '$runId:user',
        turnId: turnId,
        runId: runId,
        chatId: chatId,
        botId: bot.id,
        senderId: _currentUserId,
        content: prompt,
        images: imagePaths,
        processInfo: _buildProcessInfo(
          imagePaths: imagePaths,
          fileStatus: 'attached',
          imageDetail: imageAttachmentDetail,
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
        _selectedImages.clear();
      });
      await _chatViewModel.upsertMessage(userMessage);
      userPersisted = true;
      try {
        await _chatViewModel.updateLastMessage(userMessage.content);
      } catch (error) {
        debugPrint('Failed to update chat preview for $chatId: $error');
      }

      final videoDirPath = await getChatDirectoryPath(chatId);
      final params = {
        'prompt': prompt,
        'ratio': _selectedVideoRatio,
        'dirPath': videoDirPath,
        'referenceImage': imagePaths,
      };
      final videoPath = await compute(_generateVedioInBackground, {
        'bot': bot,
        'params': params,
      });
      final botMessage = Message(
        messageId: '$runId:assistant',
        turnId: turnId,
        runId: runId,
        chatId: chatId,
        botId: bot.id,
        senderId: bot.id,
        content: '',
        video: videoPath,
        processInfo: _buildProcessInfo(
          durationMs: _stopProcessTracking(),
          videoPath: videoPath,
          fileStatus: 'created',
          videoDetail: videoResultDetail,
        ),
        terminalOutcome: MessageTerminalOutcome.completed,
        timestamp: DateTime.now(),
      );
      final persistedBot = await _chatViewModel.upsertMessage(botMessage);
      try {
        await _chatViewModel.updateLastMessage(generatedPreview);
      } catch (error) {
        debugPrint('Failed to update chat preview for $chatId: $error');
      }

      if (mounted) {
        setState(() {
          _messages.add(persistedBot);
        });
        _scheduleScrollToLatest(animate: true);
      }
    } catch (e) {
      final failedMessage =
          userPersisted
              ? await _persistMediaFailure(
                runId: runId,
                turnId: turnId,
                chatId: chatId,
                botId: bot.id,
                durationMs: _stopProcessTracking(),
              )
              : null;
      _resetProcessTracking();
      if (mounted) {
        setState(() {
          if (!userPersisted) {
            _messages.removeWhere((message) => message.runId == runId);
            if (_messageController.text.isEmpty) {
              _messageController.text = prompt;
            }
            if (_selectedImages.isEmpty) {
              _selectedImages.addAll(originalImages);
            }
          } else if (failedMessage != null &&
              !_messages.any(
                (message) => message.messageId == failedMessage.messageId,
              )) {
            _messages.add(failedMessage);
          }
          _generationError = S.of(context).generateVideoFailed(e.toString());
        });
      }
    } finally {
      _finishNonCancellableRun(chatId);
    }
  }

  void _beginNonCancellableRun(String chatId) {
    _chatViewModel.generationRegistry.setNonCancellableRunActive(chatId, true);
    setState(() {
      _isTyping = true;
      _isCancellable = false;
      _isStopping = false;
    });
  }

  Future<Message?> _persistMediaFailure({
    required String runId,
    required String turnId,
    required String chatId,
    required String botId,
    int? durationMs,
  }) async {
    try {
      return await _chatViewModel.upsertMessage(
        Message(
          messageId: '$runId:assistant',
          turnId: turnId,
          runId: runId,
          chatId: chatId,
          botId: botId,
          senderId: botId,
          content: '',
          processInfo: MessageProcessInfo(durationMs: durationMs),
          terminalOutcome: MessageTerminalOutcome.failed,
          timestamp: DateTime.now(),
        ),
      );
    } catch (error) {
      debugPrint('Failed to persist media failure for $chatId: $error');
      return null;
    }
  }

  void _finishNonCancellableRun(String chatId) {
    _chatViewModel.generationRegistry.setNonCancellableRunActive(chatId, false);
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _isCancellable = false;
      _isStopping = false;
    });
  }

  void _startProcessTracking() {
    _processStopwatch
      ?..stop()
      ..reset();
    _processStopwatch = Stopwatch()..start();
    _toolCalls.clear();
    _commandExecutions.clear();
  }

  int? _stopProcessTracking() {
    final elapsedMilliseconds = _processStopwatch?.elapsedMilliseconds;
    _processStopwatch?.stop();
    return elapsedMilliseconds;
  }

  void _resetProcessTracking() {
    _processStopwatch
      ?..stop()
      ..reset();
    _toolCalls.clear();
    _commandExecutions.clear();
  }

  MessageProcessInfo _buildStreamingProcessInfo() {
    if (!_isStreaming && !_isTyping) {
      return const MessageProcessInfo();
    }

    return _buildProcessInfo(
      durationMs: _processStopwatch?.elapsedMilliseconds,
      reasoningStatus: _provider.getDeepThinking() ? 'streaming' : '',
      toolCalls: _toolCalls,
      commandExecutions: _commandExecutions,
    );
  }

  MessageProcessInfo _buildProcessInfo({
    String reasoningStatus = '',
    int? durationMs,
    List<MessageToolCall> toolCalls = const [],
    List<MessageCommandExecution> commandExecutions = const [],
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
    );
  }

  // 在后台线程中执行图片生成的静态方法
  static Future<List<String>> _generateImageInBackground(
    Map<String, dynamic> args,
  ) async {
    final bot = args['bot'] as Bot;
    final params = args['params'] as Map<String, dynamic>;
    final provider = Provider.create(bot);

    return await provider.generateImage(
      params['prompt'],
      params['size'],
      params['dirPath'],
      referenceImages: params['referenceImages'],
      style: params['style'],
    );
  }

  // 在后台线程中执行视频生成的静态方法
  static Future<String> _generateVedioInBackground(
    Map<String, dynamic> args,
  ) async {
    final bot = args['bot'] as Bot;
    final params = args['params'] as Map<String, dynamic>;
    final provider = Provider.create(bot);

    return await provider.generateVideo(
      params['prompt'],
      params['ratio'],
      params['dirPath'],
      params['referenceImage'],
    );
  }

  // 在后台线程中执行语音生成的静态方法
  static Future<String> _generateSpeechInBackground(
    Map<String, dynamic> args,
  ) async {
    final bot = args['bot'] as Bot;
    final params = args['params'] as Map<String, dynamic>;
    final provider = Provider.create(bot);

    return await provider.generateSpeech(
      params['prompt'],
      params['voiceType'],
      params['dirPath'],
    );
  }

  // 在后台线程中执行语音生成的静态方法
  static Future<String> _generateMusicInBackground(
    Map<String, dynamic> args,
  ) async {
    final bot = args['bot'] as Bot;
    final params = args['params'] as Map<String, dynamic>;
    final provider = Provider.create(bot);

    return await provider.generateMusic(
      params['prompt'],
      params['dirPath'],
      params['referMusicPath'],
    );
  }
}

class _PendingChatDraft {
  const _PendingChatDraft({
    required this.text,
    required this.images,
    required this.files,
  });

  final String text;
  final List<File> images;
  final List<File> files;
}
