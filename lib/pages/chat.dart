import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:bubble/services/message_service.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/services/providers/providers.dart';
import 'package:bubble/pages/common/attachment.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/chat/attachments.dart';
import 'package:bubble/pages/chat/model_features.dart';
import 'package:bubble/pages/chat/attachment_bars.dart';
import 'package:bubble/pages/common/common.dart';
import 'package:bubble/pages/chat/clear_chat_dialog.dart';
import 'package:bubble/pages/chat/message_input.dart';
import 'package:bubble/pages/chat/welcome_view.dart';
import 'package:bubble/pages/chat/message_list.dart';
import 'package:bubble/pages/chat/typing_indicator.dart';
import 'package:bubble/utils/utils.dart';
import 'package:bubble/pages/chat/image_generation_panel.dart';

// 聊天页面
class ChatPage extends StatefulWidget {
  final Bot bot;
  final String id;

  const ChatPage({super.key, required this.id, required this.bot});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Provider _provider;
  final String _currentUserId = 'me';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isTyping = false;
  bool _isStreaming = false;
  bool _isCancellable = false;
  bool _showAttachmentBar = false;
  bool _isWebSearchEnabled = false;
  bool _isDeepThinkingEnabled = false;
  String _selectedImageSize = '1024x1024';

  final List<File> _selectedImages = [];
  final List<File> _selectedFiles = [];
  List<Message> _messages = [];
  String _streamingResponse = '';
  String _reasoningResponse = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _provider = Provider.create(widget.bot);

    _provider.setCallbacks(
      onResponse: _handleStreamResponse,
      onComplete: _handleStreamComplete,
      onError: _handleStreamError,
      onReasoningResponse: _handleReasoningResponse,
    );
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    final messages = await MessageService.getMessages(widget.id);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });

    // 延迟滚动以确保列表已构建
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // 从相机获取图片
  Future<void> getAttachImageFromCamera() async {
    final image = await getImageFromCamera();
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
        _showAttachmentBar = false;
      });
    }
  }

  // 从相册获取图片
  Future<void> getAttachImageFromGallery() async {
    final image = await getImageFromGallery();
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
        _showAttachmentBar = false;
      });
    }
  }

  // 获取文件
  Future<void> getAttacheFile() async {
    final file = await pickFile();
    if (file != null) {
      setState(() {
        _selectedFiles.add(file);
        _showAttachmentBar = false;
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
    }
    await _generateText();
  }

  Future<void> _generateText() async {
    final bool hasText = _messageController.text.trim().isNotEmpty;
    final bool hasImages = _selectedImages.isNotEmpty;
    if (!hasText && !hasImages) return;

    final messageText = _messageController.text;
    final imagePaths = await _getSelectedImagePaths();
    final filePahts = await _getSelectedFilePaths();
    final userMessage = Message(
      chatId: widget.id,
      botId: widget.bot.id,
      senderId: _currentUserId,
      content: messageText,
      images: imagePaths,
      files: filePahts,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isTyping = true;
      _isStreaming = true;
      _streamingResponse = '';
      _isCancellable = true;
      _selectedImages.clear();
      _selectedFiles.clear();
    });

    await MessageService.addMessage(userMessage);
    await ChatService.updateLastMessage(widget.id, messageText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

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
      await _provider.sendMessageStream(chatMessages);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isStreaming = false;
        });
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
      });
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
        });
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
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleStreamResponse(String text) {
    if (mounted) {
      setState(() {
        _streamingResponse += text;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }

  void _handleReasoningResponse(String reasoning) {
    if (mounted) {
      setState(() {
        _reasoningResponse += reasoning;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;

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
            onPressed: () {
              _showClearChatDialog();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child:
                        _messages.isEmpty
                            ? WelcomeView(bot: widget.bot, fontSize: fontSize)
                            : Column(
                              children: [
                                MessageList(
                                  messages: _messages,
                                  scrollController: _scrollController,
                                  isStreaming: _isStreaming,
                                  streamingResponse: _streamingResponse,
                                  currentUserId: _currentUserId,
                                  deepThinking: _isDeepThinkingEnabled,
                                  reasoningResponse: _reasoningResponse,
                                ),

                                if (_isTyping)
                                  TypingIndicator(
                                    botName: widget.bot.name,
                                    isCancellable: _isCancellable,
                                    onCancelRequest: _cancelRequest,
                                  ),
                              ],
                            ),
                  ),

                  // 图片区域
                  if (_selectedImages.isNotEmpty || _selectedFiles.isNotEmpty)
                    _showAttachments(),

                  // 图片生成功能
                  if (_provider.getOutputModalites().contains(
                    OutputModality.image,
                  ))
                    _buildImageGenerationPanel(),

                  if (_provider.supportWebSearch() ||
                      _provider.supportDeepThinking())
                    _showChatModelFeatures(),

                  MessageInput(
                    controller: _messageController,
                    onSend: _sendMessage,
                    onToggleAttachmentBar: () {
                      setState(() {
                        _showAttachmentBar = !_showAttachmentBar;
                      });
                    },
                    showAttachmentBar: _showAttachmentBar,
                    inputModalities: _provider.getInputModalites(),
                    hasAttachments:
                        (_selectedImages.isNotEmpty ||
                            _selectedFiles.isNotEmpty),
                  ),

                  // 附件选择栏
                  if (_showAttachmentBar) _showAttachmentBars(),

                  const SizedBox(height: 16),
                ],
              ),
    );
  }

  void _showClearChatDialog() async {
    final shouldClear = await showClearChatDialog(context, widget.bot.name);
    if (shouldClear) {
      _clearChatMessages();
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

      if (_streamingResponse.isNotEmpty) {
        final botMessage = Message(
          chatId: widget.id,
          botId: widget.bot.id,
          senderId: widget.bot.id,
          content: _streamingResponse,
          timestamp: DateTime.now(),
        );
        _messages.add(botMessage);
        _streamingResponse = '';

        MessageService.addMessage(botMessage).then((_) {
          ChatService.updateLastMessage(widget.id, botMessage.content);
        });
      }
    });
    showSnackBar(context, S.of(context).replyCancelled);
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

  // 删除原来的 _showAttachments 方法，替换为以下代码
  Widget _showAttachments() {
    return ImageAttachments(
      images: _selectedImages,
      files: _selectedFiles,
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

  Widget _showChatModelFeatures() {
    return ChatModelFeatures(
      isWebSearchEnabled: _isWebSearchEnabled,
      isDeepThinkingEnabled: _isDeepThinkingEnabled,
      supportWebSearch: _provider.supportWebSearch(),
      supportDeepThinking: _provider.supportDeepThinking(),
      onWebSearchToggle: (value) {
        setState(() {
          _isWebSearchEnabled = value;
          _provider.setWebSearch(_isWebSearchEnabled);
        });
      },
      onDeepThinkingToggle: (value) {
        setState(() {
          _isDeepThinkingEnabled = value;
          _provider.setDeepThinking(_isDeepThinkingEnabled);
        });
      },
    );
  }

  // 修改原文件中的引用
  Widget _showAttachmentBars() {
    return AttachmentBars(
      onCameraPressed: getAttachImageFromCamera,
      onGalleryPressed: getAttachImageFromGallery,
      onFilePressed: getAttacheFile,
      inputModalities: _provider.getInputModalites(),
    );
  }

  // 修改原文件中的方法
  Widget _buildImageGenerationPanel() {
    // 获取支持的图片尺寸
    List<String> supportedSizes = ['1024x1024'];
    // 如果模型支持获取图片尺寸列表，则使用模型提供的尺寸
    try {
      final sizes = _provider.getSupportedImageSizes();
      if (sizes.isNotEmpty) {
        supportedSizes = sizes;
      }
    } catch (e) {
      // 忽略不支持的方法调用
    }

    return ImageGenerationPanel(
      supportedSizes: supportedSizes,
      selectedSize: _selectedImageSize,
      onSizeSelected: (size) {
        setState(() {
          _selectedImageSize = size;
        });
      },
    );
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
      final imagePaths = await _getSelectedImagePaths();
      // 创建系统消息记录生成的图片
      final userMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: _currentUserId,
        content: prompt,
        images: imagePaths,
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
      final imagePath = await _provider.generateImage(
        prompt,
        _selectedImageSize,
        imageDirPath,
        referenceImages: imagePaths,
      );
      final botMessage = Message(
        chatId: widget.id,
        botId: widget.bot.id,
        senderId: widget.bot.id,
        content: '',
        images: imagePath,
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

      // 滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
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
}
