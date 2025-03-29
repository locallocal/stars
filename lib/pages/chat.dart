import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:bubble/services/message_service.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/services/models/chat_models.dart';
import 'package:bubble/pages/common/attachment.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/chat/image_attachments.dart';
import 'package:bubble/pages/chat/model_features.dart';
import 'package:bubble/pages/chat/attachment_bars.dart';
import 'package:bubble/pages/common/common.dart';
import 'package:bubble/pages/chat/clear_chat_dialog.dart';
import 'package:bubble/pages/chat/message_input.dart';
import 'package:bubble/pages/chat/welcome_view.dart';
import 'package:bubble/pages/chat/message_list.dart';
import 'package:bubble/pages/chat/typing_indicator.dart';
import 'package:bubble/utils/utils.dart';

// 聊天页面
class ChatPage extends StatefulWidget {
  final Bot bot;
  final String id;

  const ChatPage({super.key, required this.id, required this.bot});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ChatModel _chatModel;
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

  final List<File> _selectedImages = [];
  List<Message> _messages = [];
  String _streamingResponse = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _chatModel = ChatModel.create(widget.bot);
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

  Future<void> _sendMessage() async {
    final bool hasText = _messageController.text.trim().isNotEmpty;
    final bool hasImages = _selectedImages.isNotEmpty;
    if (!hasText && !hasImages) return;

    final messageText = _messageController.text;
    List<String> imagePaths = [];
    if (_selectedImages.isNotEmpty) {
      final chatDir = await getChatDirectoryPath(widget.id);

      for (var image in _selectedImages) {
        final fileName = path.basename(image.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final targetPath = path.join(chatDir, '${timestamp}_$fileName');

        try {
          await image.copy(targetPath);
          imagePaths.add(targetPath);
        } catch (e) {
          debugPrint('Copy image ${image.path} failed: $e');
        }
      }
    }

    final userMessage = Message(
      chatId: widget.id,
      botId: widget.bot.id,
      senderId: _currentUserId,
      content: messageText,
      timestamp: DateTime.now(),
      images: imagePaths,
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isTyping = true;
      _isStreaming = true;
      _streamingResponse = '';
      _isCancellable = true;
      _selectedImages.clear();
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

        // merge consecutive user messages
        String pendingUserMessage = "";
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
            if (i == _messages.length - 1) {
              chatMessages.add(
                ChatMessage(
                  role: role,
                  content: pendingUserMessage,
                  images: msg.images,
                  files: msg.files,
                ),
              );
              pendingUserMessage = "";
            }
            continue;
          }
          if (pendingUserMessage.isNotEmpty) {
            chatMessages.add(
              ChatMessage(role: 'user', content: pendingUserMessage),
            );
            pendingUserMessage = "";
          }
          // assistant message
          chatMessages.add(ChatMessage(role: role, content: msg.content));
        }
      }

      chatMessages.add(
        ChatMessage(
          role: "user",
          content: messageText,
          deepThinking: _isDeepThinkingEnabled,
          webSearch: _isWebSearchEnabled,
          images: userMessage.images,
        ),
      );
      await _chatModel.sendMessageStream(
        chatMessages,
        (text) {
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
        },
        onComplete: () async {
          if (_streamingResponse.isEmpty) {
            if (mounted) {
              setState(() {
                _isTyping = false;
                _isStreaming = false;
                _isCancellable = false;
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
            timestamp: DateTime.now(),
          );
          await MessageService.addMessage(botMessage);

          if (mounted) {
            setState(() {
              _messages.add(botMessage);
              _isTyping = false;
              _isStreaming = false;
              _streamingResponse = '';
              _isCancellable = false;
            });
          }

          await ChatService.updateLastMessage(widget.id, botMessage.content);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isTyping = false;
              _isStreaming = false;
              _isCancellable = false;
            });
            showSnackBar(context, S.of(context).responseError(error));
          }
        },
      );
    } catch (e) {
      // 处理错误
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isStreaming = false;
        });
        showSnackBar(context, S.of(context).responseError(e.toString()));
      }
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
            icon: const Icon(Icons.delete_sweep),
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
                  // 消息列表区域
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
                  if (_selectedImages.isNotEmpty) _showAttachments(),

                  // 输入框区域
                  MessageInput(
                    controller: _messageController,
                    onSend: _sendMessage,
                    onToggleAttachmentBar: () {
                      setState(() {
                        _showAttachmentBar = !_showAttachmentBar;
                      });
                    },
                    showAttachmentBar: _showAttachmentBar,
                    inputModalities: _chatModel.getInputModalites(),
                    hasAttachments: _selectedImages.isNotEmpty,
                  ),

                  // 聊天模型功能
                  if (_chatModel.supportsWebSearch() ||
                      _chatModel.supportsDeepThinking())
                    _showChatModelFeatures(),

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
    if (mounted) {
      showSnackBar(context, S.of(context).chatHistoryCleared);
    }
  }

  void _cancelRequest() {
    if (!_isCancellable) return;

    setState(() {
      _isTyping = false;
      _isStreaming = false;
      _isCancellable = false;
      _chatModel.cancelRequest();

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

  // 删除原来的 _showAttachments 方法，替换为以下代码
  Widget _showAttachments() {
    return ImageAttachments(
      images: _selectedImages,
      onClearAll: () {
        setState(() {
          _selectedImages.clear();
        });
      },
      onRemoveImage: (index) {
        setState(() {
          _selectedImages.removeAt(index);
        });
      },
    );
  }

  Widget _showChatModelFeatures() {
    return ChatModelFeatures(
      isWebSearchEnabled: _isWebSearchEnabled,
      isDeepThinkingEnabled: _isDeepThinkingEnabled,
      supportsWebSearch: _chatModel.supportsWebSearch(),
      supportsDeepThinking: _chatModel.supportsDeepThinking(),
      onWebSearchToggle: (value) {
        setState(() {
          _isWebSearchEnabled = value;
        });
      },
      onDeepThinkingToggle: (value) {
        setState(() {
          _isDeepThinkingEnabled = value;
        });
      },
    );
  }

  // 修改原文件中的引用
  Widget _showAttachmentBars() {
    return AttachmentBars(
      onCameraPressed: getAttachImageFromCamera,
      onGalleryPressed: getAttachImageFromGallery,
      onFilePressed: pickFile,
      inputModalities: _chatModel.getInputModalites(),
    );
  }
}
