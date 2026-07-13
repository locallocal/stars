import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:stars/services/message_service.dart';
import 'package:stars/model/model.dart';
import 'package:stars/services/chat_service.dart';
import 'package:stars/services/providers/providers.dart';
import 'package:stars/pages/common/attachment.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/chat/attachments.dart';
import 'package:stars/pages/common/common.dart';
import 'package:stars/pages/chat/clear_chat_dialog.dart';
import 'package:stars/pages/chat/message_input.dart';
import 'package:stars/pages/chat/welcome_view.dart';
import 'package:stars/pages/chat/message_list.dart';
import 'package:stars/pages/chat/typing_indicator.dart';
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
  static final Map<String, String> _draftsByChat = <String, String>{};
  static final Map<String, List<File>> _draftImagesByChat =
      <String, List<File>>{};
  static final Map<String, List<File>> _draftFilesByChat =
      <String, List<File>>{};

  late Provider _provider;
  final String _currentUserId = 'me';
  late final TextEditingController _messageController;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isTyping = false;
  bool _isStreaming = false;
  bool _isCancellable = false;
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
  bool _providerNeedsRefresh = false;
  String? _pendingDraftText;
  List<File> _pendingDraftImages = const [];
  List<File> _pendingDraftFiles = const [];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: _draftsByChat[widget.id] ?? '',
    )..addListener(_persistTextDraft);
    _selectedImages.addAll(_draftImagesByChat[widget.id] ?? const []);
    _selectedFiles.addAll(_draftFilesByChat[widget.id] ?? const []);
    _scrollController.addListener(_handleScrollPositionChanged);
    _loadMessages();
    _configureProvider(widget.bot);
  }

  void _configureProvider(Bot bot) {
    _provider = Provider.create(bot);
    _provider.setCallbacks(
      onResponse: _handleStreamResponse,
      onComplete: _handleStreamComplete,
      onError: _handleStreamError,
      onReasoningResponse: _handleReasoningResponse,
      onToolCall: _handleToolCall,
      onCommandExecution: _handleCommandExecution,
    );
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bot != widget.bot) {
      if (_isTyping) {
        _providerNeedsRefresh = true;
      } else {
        _configureProvider(widget.bot);
      }
    }
  }

  void _refreshProviderIfNeeded() {
    if (!_providerNeedsRefresh) return;
    _providerNeedsRefresh = false;
    _configureProvider(widget.bot);
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    final messages = await MessageService.getMessages(widget.id);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _isLoading = false;
      _followLatest = true;
      _showJumpToLatest = false;
    });

    _scheduleScrollToLatest(force: true);
  }

  @override
  void dispose() {
    _persistAttachmentDrafts();
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
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  // 从相册获取图片
  Future<void> getAttachImageFromGallery() async {
    final image = await getImageFromGallery();
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  // 获取文件
  Future<void> getAttacheFile() async {
    final file = await pickFile();
    if (file != null) {
      setState(() {
        _selectedFiles.add(file);
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_isTyping) {
      return;
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
    final imagePaths = await _getSelectedImagePaths();
    final filePahts = await _getSelectedFilePaths();
    final userMessage = Message(
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

    _startProcessTracking();
    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isTyping = true;
      _isStreaming = true;
      _streamingResponse = '';
      _isCancellable = true;
      _selectedImages.clear();
      _selectedFiles.clear();
      _followLatest = true;
      _showJumpToLatest = false;
    });

    await MessageService.addMessage(userMessage);
    await ChatService.updateLastMessage(widget.id, messageText);
    _scheduleScrollToLatest(force: true, animate: true);

    try {
      final List<ChatMessage> chatMessages = [];
      if (widget.bot.systemPrompt.isNotEmpty) {
        chatMessages.add(
          ChatMessage(role: "system", content: widget.bot.systemPrompt),
        );
      }

      // merge consecutive user messages
      String pendingUserMessage = "";
      if (_messages.length > 1) {
        int startIdx = _messages.length > 100 ? _messages.length - 100 : 0;
        // find the first user message
        for (int i = startIdx; i < _messages.length - 1; i++) {
          final msg = _messages[i];
          if (msg.senderId == _currentUserId) {
            startIdx = i;
            break;
          }
        }

        for (int i = startIdx; i < _messages.length - 1; i++) {
          final msg = _messages[i];
          final role = msg.senderId == _currentUserId ? 'user' : 'assistant';

          // user message
          if (role == "user") {
            if (pendingUserMessage.isNotEmpty) {
              pendingUserMessage += '\n${msg.content}';
            } else {
              pendingUserMessage = msg.content;
            }
            continue;
          }
          chatMessages.add(
            ChatMessage(role: 'user', content: pendingUserMessage),
          );
          pendingUserMessage = "";
          // assistant message
          chatMessages.add(ChatMessage(role: role, content: msg.content));
        }
      }

      String lastUserMessage = messageText;
      if (pendingUserMessage.isNotEmpty) {
        lastUserMessage = '$messageText\n$pendingUserMessage';
      }
      chatMessages.add(
        ChatMessage(
          role: "user",
          content: lastUserMessage,
          images: userMessage.images,
          files: userMessage.files,
        ),
      );
      await _provider.generateText(chatMessages);
    } catch (e) {
      _resetProcessTracking();
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isStreaming = false;
          _isCancellable = false;
          _restorePendingDraft();
        });
        _refreshProviderIfNeeded();
        showSnackBar(context, S.of(context).responseError(e.toString()));
      }
    }
  }

  void _handleStreamError(String error) {
    if (mounted) {
      setState(() {
        _isTyping = false;
        _isStreaming = false;
        _isCancellable = false;
        _reasoningResponse = '';
        _restorePendingDraft();
      });
      _resetProcessTracking();
      _refreshProviderIfNeeded();
      showSnackBar(context, S.of(context).responseError(error));
    }
  }

  Future<void> _handleStreamComplete() async {
    if (_streamingResponse.isEmpty) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isStreaming = false;
          _isCancellable = false;
          _reasoningResponse = '';
          _restorePendingDraft();
        });
        _resetProcessTracking();
        _refreshProviderIfNeeded();
        showSnackBar(context, S.of(context).emptyResponseError);
      }
      return;
    }
    final botMessage = Message(
      chatId: widget.id,
      botId: widget.bot.id,
      senderId: widget.bot.id,
      content: _streamingResponse,
      reasoning: _reasoningResponse,
      processInfo: _buildProcessInfo(
        durationMs: _stopProcessTracking(),
        reasoningStatus:
            _reasoningResponse.isNotEmpty
                ? 'completed'
                : (_provider.getDeepThinking() ? 'completed' : ''),
        toolCalls: _toolCalls,
        commandExecutions: _commandExecutions,
      ),
      timestamp: DateTime.now(),
    );
    await MessageService.addMessage(botMessage);
    await ChatService.updateLastMessage(widget.id, botMessage.content);

    if (mounted) {
      setState(() {
        _messages.add(botMessage);
        _isTyping = false;
        _isStreaming = false;
        _streamingResponse = '';
        _reasoningResponse = '';
        _isCancellable = false;
      });
      _toolCalls.clear();
      _commandExecutions.clear();
      _clearPendingDraft();
      _refreshProviderIfNeeded();
    }
    _scheduleScrollToLatest(animate: true);
  }

  void _handleStreamResponse(String text) {
    if (mounted) {
      setState(() {
        _streamingResponse += text;
      });
      _scheduleScrollToLatest();
    }
  }

  void _handleReasoningResponse(String reasoning) {
    if (mounted) {
      setState(() {
        _reasoningResponse += reasoning;
      });
      _scheduleScrollToLatest();
    }
  }

  void _handleToolCall(MessageToolCall toolCall) {
    if (!mounted) {
      return;
    }
    setState(() {
      _toolCalls.add(toolCall);
    });
  }

  void _handleCommandExecution(MessageCommandExecution commandExecution) {
    if (!mounted) {
      return;
    }
    setState(() {
      _commandExecutions.add(commandExecution);
    });
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
            tooltip: S.of(context).clearChatHistory,
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
              MessageInput(
                provider: _provider,
                controller: _messageController,
                waitingBotMessage: _isTyping && _isCancellable,
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
              MessageInput(
                provider: _provider,
                controller: _messageController,
                waitingBotMessage: _isTyping && _isCancellable,
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
      return const Center(child: CircularProgressIndicator());
    }

    final conversation =
        _messages.isEmpty
            ? WelcomeView(bot: widget.bot, fontSize: fontSize)
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
                if (_isTyping)
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
            child: FilledButton.tonalIcon(
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

  Future<void> requestClearChat() async {
    final shouldClear = await showClearChatDialog(context, widget.bot.name);
    if (!mounted) return;
    if (shouldClear) {
      await _clearChatMessages();
    }
  }

  Future<void> _clearChatMessages() async {
    setState(() {
      _messages = [];
    });

    await MessageService.deleteChatMessage(widget.id);
    await ChatService.updateLastMessage(widget.id, '');
    await _loadMessages();
  }

  void _cancelRequest() {
    if (!_isCancellable) return;

    setState(() {
      _isTyping = false;
      _isStreaming = false;
      _isCancellable = false;
      _provider.cancelRequest();
      _clearPendingDraft();

      if (_streamingResponse.isNotEmpty) {
        final botMessage = Message(
          chatId: widget.id,
          botId: widget.bot.id,
          senderId: widget.bot.id,
          content: _streamingResponse,
          reasoning: _reasoningResponse,
          processInfo: _buildProcessInfo(
            durationMs: _stopProcessTracking(),
            reasoningStatus:
                _reasoningResponse.isNotEmpty
                    ? 'cancelled'
                    : (_provider.getDeepThinking() ? 'cancelled' : ''),
            toolCalls: _toolCalls,
            commandExecutions: _commandExecutions,
          ),
          timestamp: DateTime.now(),
        );
        _messages.add(botMessage);
        _streamingResponse = '';
        _reasoningResponse = '';

        MessageService.addMessage(botMessage).then((_) {
          ChatService.updateLastMessage(widget.id, botMessage.content);
        });
      }
    });
    _toolCalls.clear();
    _commandExecutions.clear();
    _resetProcessTracking();
    _refreshProviderIfNeeded();
    showSnackBar(context, S.of(context).replyCancelled);
  }

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
    setState(() {
      _isTyping = true;
      _isCancellable = false;
    });

    try {
      _startProcessTracking();
      final imagePaths = await _getSelectedImagePaths();
      // 创建系统消息记录生成的图片
      final userMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: _currentUserId,
        content: prompt,
        images: imagePaths,
        processInfo: _buildProcessInfo(
          imagePaths: imagePaths,
          fileStatus: 'attached',
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _selectedImages.clear();
        _messageController.clear();
      });
      // 保存消息到数据库
      await MessageService.addMessage(userMessage);
      await ChatService.updateLastMessage(widget.id, userMessage.content);

      // 调用模型生成图片
      var imageDirPath = await getChatDirectoryPath(widget.id);
      // 准备参数
      final params = {
        'prompt': prompt,
        'size': _selectedImageSize,
        'dirPath': imageDirPath,
        'referenceImages': imagePaths,
        'style': _selectedImageStype,
      };
      // 使用compute在后台线程执行图片生成
      final imagePath = await compute(_generateImageInBackground, {
        'bot': widget.bot,
        'params': params,
      });

      final botMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: widget.bot.id,
        content: '',
        images: imagePath,
        processInfo: _buildProcessInfo(
          durationMs: _stopProcessTracking(),
          imagePaths: imagePath,
          fileStatus: 'created',
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(botMessage);
      });
      await MessageService.addMessage(botMessage);

      if (mounted) {
        await ChatService.updateLastMessage(
          widget.id,
          S.of(context).generatedImage,
        );
      }

      _scheduleScrollToLatest(animate: true);
    } catch (e) {
      _resetProcessTracking();
      if (mounted) {
        showSnackBar(context, S.of(context).generateImageFailed(e.toString()));
      }
    } finally {
      setState(() {
        _isTyping = false;
        _isCancellable = false;
      });
    }
  }

  Future<void> _generateSpeech() async {
    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      showSnackBar(context, '请输入语音描述');
      return;
    }
    setState(() {
      _isTyping = true;
      _isCancellable = false;
    });

    try {
      _startProcessTracking();
      // 创建用户消息记录
      final userMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: _currentUserId,
        content: prompt,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
      });
      // 保存消息到数据库
      await MessageService.addMessage(userMessage);
      await ChatService.updateLastMessage(widget.id, userMessage.content);

      // 获取语音类型列表
      List<String> voiceTypes = [];
      try {
        voiceTypes = _provider.getSupportVoicTypes();
      } catch (e) {
        // 忽略不支持的方法调用
      }

      // 使用默认语音类型或第一个可用的语音类型
      String voiceType = '';
      if (voiceTypes.isNotEmpty) {
        voiceType = voiceTypes.first;
      }

      // 调用模型生成语音
      var outputDirPath = await getChatDirectoryPath(widget.id);
      final params = {
        'prompt': prompt,
        'dirPath': outputDirPath,
        'voiceType': voiceType,
      };
      // 使用compute在后台线程执行语音的生成
      final audioPath = await compute(_generateSpeechInBackground, {
        'bot': widget.bot,
        'params': params,
      });
      // 创建机器人回复消息
      final botMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: widget.bot.id,
        content: '',
        audio: audioPath,
        processInfo: _buildProcessInfo(
          durationMs: _stopProcessTracking(),
          audioPath: audioPath,
          fileStatus: 'created',
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(botMessage);
      });
      await MessageService.addMessage(botMessage);

      if (mounted) {
        await ChatService.updateLastMessage(widget.id, '语音已生成');
      }
    } catch (e) {
      _resetProcessTracking();
      if (mounted) {
        showSnackBar(context, '生成语音失败：$e');
      }
    } finally {
      setState(() {
        _isTyping = false;
        _isCancellable = false;
      });
    }
  }

  Future<void> _generateMusic() async {
    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      showSnackBar(context, '请输入音乐描述');
      return;
    }
    setState(() {
      _isTyping = true;
      _isCancellable = false;
    });

    try {
      _startProcessTracking();
      // 获取文件列表的第一个文件作为音乐文件
      final filePahts = await _getSelectedFilePaths();
      var referMusicPath = "";
      if (filePahts.isNotEmpty) {
        referMusicPath = filePahts.first;
      }

      // 创建用户消息记录
      final userMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: _currentUserId,
        content: prompt,
        music: referMusicPath,
        processInfo: _buildProcessInfo(
          musicPath: referMusicPath,
          fileStatus: 'attached',
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
        _selectedFiles.clear();
      });
      // 保存消息到数据库
      await MessageService.addMessage(userMessage);
      await ChatService.updateLastMessage(widget.id, userMessage.content);

      // 调用模型生成音乐
      var musicDirPath = await getChatDirectoryPath(widget.id);
      final params = {
        'prompt': prompt,
        'dirPath': musicDirPath,
        'referMusicPath': referMusicPath,
      };
      final musicPath = await compute(_generateMusicInBackground, {
        'bot': widget.bot,
        'params': params,
      });
      final botMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: widget.bot.id,
        content: '',
        audio: musicPath,
        processInfo: _buildProcessInfo(
          durationMs: _stopProcessTracking(),
          musicPath: musicPath,
          fileStatus: 'created',
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(botMessage);
      });
      await MessageService.addMessage(botMessage);

      if (mounted) {
        await ChatService.updateLastMessage(widget.id, '生成了音乐');
      }

      _scheduleScrollToLatest(animate: true);
    } catch (e) {
      _resetProcessTracking();
      if (mounted) {
        showSnackBar(context, '生成音乐失败: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isTyping = false;
        _isCancellable = false;
      });
    }
  }

  Future<void> _generateVideo() async {
    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      showSnackBar(context, '请输入视频描述');
      return;
    }
    setState(() {
      _isTyping = true;
      _isCancellable = false;
    });

    try {
      _startProcessTracking();
      // 创建用户消息记录
      final imagePaths = await _getSelectedImagePaths();
      final userMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: _currentUserId,
        content: prompt,
        images: imagePaths,
        processInfo: _buildProcessInfo(
          imagePaths: imagePaths,
          fileStatus: 'attached',
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
        _selectedImages.clear();
      });
      // 保存消息到数据库
      await MessageService.addMessage(userMessage);
      await ChatService.updateLastMessage(widget.id, userMessage.content);

      // 调用模型生成视频
      var videoDirPath = await getChatDirectoryPath(widget.id);
      // 准备参数
      final params = {
        'prompt': prompt,
        'ratio': _selectedVideoRatio,
        'dirPath': videoDirPath,
        'referenceImage': imagePaths,
      };
      // 使用compute在后台线程执行图片生成
      final videoPath = await compute(_generateVedioInBackground, {
        'bot': widget.bot,
        'params': params,
      });
      final botMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: widget.bot.id,
        content: '',
        video: videoPath,
        processInfo: _buildProcessInfo(
          durationMs: _stopProcessTracking(),
          videoPath: videoPath,
          fileStatus: 'created',
        ),
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(botMessage);
      });
      await MessageService.addMessage(botMessage);
      if (mounted) {
        await ChatService.updateLastMessage(widget.id, '生成了视频');
      }

      _scheduleScrollToLatest(animate: true);
    } catch (e) {
      _resetProcessTracking();
      if (mounted) {
        showSnackBar(context, '生成视频失败: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isTyping = false;
        _isCancellable = false;
      });
    }
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
  }) {
    final fileEdits = <MessageFileEdit>[
      ...imagePaths.map(
        (imagePath) => MessageFileEdit(
          path: imagePath,
          type: 'image',
          status: fileStatus,
          detail: fileStatus == 'attached' ? '图片附件' : '图片结果',
        ),
      ),
      ...filePaths.map(
        (filePath) => MessageFileEdit(
          path: filePath,
          type: 'file',
          status: fileStatus,
          detail: fileStatus == 'attached' ? '文件附件' : '文件结果',
        ),
      ),
    ];

    if (audioPath.isNotEmpty) {
      fileEdits.add(
        MessageFileEdit(
          path: audioPath,
          type: 'audio',
          status: fileStatus,
          detail: '语音结果',
        ),
      );
    }
    if (musicPath.isNotEmpty) {
      fileEdits.add(
        MessageFileEdit(
          path: musicPath,
          type: 'music',
          status: fileStatus,
          detail: fileStatus == 'attached' ? '参考音频' : '音乐结果',
        ),
      );
    }
    if (videoPath.isNotEmpty) {
      fileEdits.add(
        MessageFileEdit(
          path: videoPath,
          type: 'video',
          status: fileStatus,
          detail: '视频结果',
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

    return await provider.generateSpeech(
      params['prompt'],
      params['dirPath'],
      params['referMusicPath'],
    );
  }
}
