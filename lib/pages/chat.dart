import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bubble/services/message_service.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/services/models/chat_models.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:bubble/pages/common/logo.dart';
import 'package:bubble/generated/l10n.dart';

// 聊天页面
class ChatPage extends StatefulWidget {
  final Bot bot;
  final String id;

  const ChatPage({super.key, required this.id, required this.bot});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Message> _messages = [];
  final String _currentUserId = 'me';
  bool _isLoading = true;
  bool _isTyping = false;
  String _streamingResponse = '';
  bool _isStreaming = false;
  final ScrollController _scrollController = ScrollController();
  late ChatModel _chatModel;
  bool _isCancellable = false;
  bool _showAttachmentBar = false;

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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final messageText = _messageController.text;

    final userMessage = Message(
      type: "text",
      chatId: widget.id,
      botId: widget.bot.id,
      senderId: _currentUserId,
      content: messageText,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isTyping = true;
      _isStreaming = true;
      _streamingResponse = '';
      _isCancellable = true;
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

      final historyMessages = _messages.where((m) => m.type == "text").toList();
      if (historyMessages.length > 1) {
        final int startIdx =
            historyMessages.length > 10 ? historyMessages.length - 10 : 0;
        for (int i = startIdx; i < historyMessages.length - 1; i++) {
          final msg = historyMessages[i];
          final role = msg.senderId == _currentUserId ? "user" : "assistant";
          chatMessages.add(ChatMessage(role: role, content: msg.content));
        }
      }

      chatMessages.add(ChatMessage(role: "user", content: messageText));
      await _chatModel.sendMessageStream(
        chatMessages,
        (text) {
          if (mounted) {
            setState(() {
              _streamingResponse += text;
              // 每次收到新内容时滚动到底部
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
              _showSnackBar(S.of(context).emptyResponseError);
            }
            return;
          }

          // 创建最终AI回复消息
          final botMessage = Message(
            type: "text",
            chatId: widget.id,
            botId: widget.bot.id,
            senderId: widget.bot.id,
            content: _streamingResponse,
            timestamp: DateTime.now(),
          );

          // 保存AI回复到本地存储
          await MessageService.addMessage(botMessage);

          // 更新UI
          if (mounted) {
            setState(() {
              _messages.add(botMessage);
              _isTyping = false;
              _isStreaming = false;
              _streamingResponse = '';
              _isCancellable = false;
            });
          }

          // 更新聊天列表中的最后一条消息
          await ChatService.updateLastMessage(widget.id, botMessage.content);

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
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isTyping = false;
              _isStreaming = false;
              _isCancellable = false;
            });
            _showSnackBar(S.of(context).responseError(error));
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
        _showSnackBar(S.of(context).responseError(e.toString()));
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
                  // 消息列表
                  Expanded(
                    child:
                        _messages.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // AI智能体图标
                                  Container(
                                    width: 128,
                                    height: 128,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child:
                                        widget.bot.avatar.isEmpty
                                            ? buildProviderLogo(
                                              context,
                                              '',
                                              widget.bot.provider,
                                              96,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(height: 24),
                                  // 智能体名称
                                  Text(
                                    widget.bot.name,
                                    style: TextStyle(
                                      fontSize:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.fontSize,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // 问候语
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32.0,
                                    ),
                                    child: Text(
                                      S
                                          .of(context)
                                          .botGreeting(widget.bot.name),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // 提示开始聊天
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      S.of(context).startChatPrompt,
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount:
                                        _messages.length +
                                        (_isStreaming ? 1 : 0),
                                    padding: const EdgeInsets.all(8.0),
                                    // 添加列表构建完成后的回调
                                    itemBuilder: (context, index) {
                                      // 在列表构建完成后滚动到底部
                                      if (index == _messages.length - 1) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (_scrollController
                                                  .hasClients) {
                                                _scrollController.animateTo(
                                                  _scrollController
                                                      .position
                                                      .maxScrollExtent,
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeOut,
                                                );
                                              }
                                            });
                                      }

                                      if (_isStreaming &&
                                          index == _messages.length) {
                                        // 显示流式响应
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.8,
                                            ),
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4.0,
                                                    horizontal: 8.0,
                                                  ),
                                              padding: const EdgeInsets.all(
                                                12.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(16.0),
                                              ),
                                              child: MarkdownBody(
                                                data: _streamingResponse,
                                                selectable: true,
                                                styleSheet: MarkdownStyleSheet(
                                                  p: TextStyle(
                                                    color: Colors.black,
                                                    fontSize:
                                                        Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.fontSize,
                                                  ),
                                                  code: TextStyle(
                                                    color: Colors.black,
                                                    backgroundColor: Colors
                                                        .black
                                                        .withOpacity(0.1),
                                                  ),
                                                  blockquote: const TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      // 显示普通消息
                                      final message = _messages[index];
                                      final isMe =
                                          message.senderId == _currentUserId;

                                      return Align(
                                        alignment:
                                            isMe
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                        child: GestureDetector(
                                          onLongPress: () {
                                            // 复制消息内容到剪贴板
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: message.content,
                                              ),
                                            );
                                            _showSnackBar(
                                              S.of(context).messageCopied,
                                            );
                                          },
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.8,
                                            ),
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4.0,
                                                    horizontal: 8.0,
                                                  ),
                                              padding: const EdgeInsets.all(
                                                12.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isMe
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.5)
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(16.0),
                                              ),
                                              child: MarkdownBody(
                                                data: message.content,
                                                selectable: true,
                                                styleSheet: MarkdownStyleSheet(
                                                  p: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: fontSize,
                                                  ),
                                                  code: TextStyle(
                                                    color: Colors.black,
                                                    backgroundColor:
                                                        isMe
                                                            ? Colors.white
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                            : Colors.black
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                  ),
                                                  blockquote: const TextStyle(
                                                    color: Colors.black,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                if (_isTyping)
                                  Container(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      right: 8.0,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 8),
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          S
                                              .of(context)
                                              .botIsTyping(widget.bot.name),
                                        ),
                                        const Spacer(),
                                        if (_isCancellable)
                                          IconButton(
                                            onPressed: _cancelRequest,
                                            icon: const Icon(
                                              Icons.pause_circle_filled,
                                            ),
                                            tooltip:
                                                S.of(context).pauseGeneration,
                                            iconSize: 28,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                  ),

                  // 输入框区域
                  Container(
                    margin: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: S.of(context).messageHint,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 12.0,
                        ),
                        // 添加后缀图标按钮
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_chatModel.getInputModalites().contains(
                                  InputModality.image,
                                ) ||
                                _chatModel.getInputModalites().contains(
                                  InputModality.file,
                                ))
                              IconButton(
                                icon:
                                    !_showAttachmentBar
                                        ? const Icon(Icons.add_circle_outline)
                                        : const Icon(Icons.close),
                                tooltip: S.of(context).addAttachment,
                                onPressed: () {
                                  // 切换显示附件选择栏
                                  setState(() {
                                    _showAttachmentBar = !_showAttachmentBar;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.center,
                    ),
                  ),

                  if (_chatModel.supportsWebSearch() ||
                      _chatModel.supportsDeepThinking())
                    _showChatModelFeatures(),

                  // 附件选择栏
                  if (_showAttachmentBar) _showAttachmentBars(context),

                  const SizedBox(height: 16),
                ],
              ),
    );
  }

  // 显示清空聊天记录确认对话框
  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Center(
              child: Text(
                S.of(context).clearChatHistory,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                ),
              ),
            ),
            content: Text(S.of(context).confirmClearChat(widget.bot.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  S.of(context).cancel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearChatMessages();
                },
                child: Text(
                  S.of(context).clear,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // 清空聊天记录
  Future<void> _clearChatMessages() async {
    // 先更新UI，立即反馈给用户
    setState(() {
      _messages = [];
    });

    // 清空本地消息
    await MessageService.deleteChatMessage(widget.id);
    // 更新聊天列表中的最后一条消息
    await ChatService.updateLastMessage(widget.id, '');

    // 重新加载消息列表，确保UI与数据库同步
    await _loadMessages();
    if (mounted) {
      _showSnackBar(S.of(context).chatHistoryCleared);
    }
  }

  // 添加取消请求的方法
  void _cancelRequest() {
    if (!_isCancellable) return;

    setState(() {
      _isTyping = false;
      _isStreaming = false;
      _isCancellable = false;
      _chatModel.cancelRequest();

      // 如果已经有部分响应，将其作为最终响应保存
      if (_streamingResponse.isNotEmpty) {
        final botMessage = Message(
          type: "text",
          chatId: widget.id,
          botId: widget.bot.id,
          senderId: widget.bot.id,
          content: _streamingResponse,
          timestamp: DateTime.now(),
        );
        _messages.add(botMessage);
        _streamingResponse = '';

        // 异步保存消息和更新聊天列表
        MessageService.addMessage(botMessage).then((_) {
          ChatService.updateLastMessage(widget.id, botMessage.content);
        });
      }
    });
    _showSnackBar(S.of(context).replyCancelled);
  }

  Widget _showChatModelFeatures() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (_chatModel.supportsWebSearch())
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  // 在消息中添加联网搜索指令
                  _messageController.text = '联网搜索: ${_messageController.text}';
                },
                icon: const Icon(Icons.public, size: 16),
                label: Text(S.of(context).webSearch),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  side: const BorderSide(color: Colors.transparent),
                ),
              ),
            ),
          if (_chatModel.supportsDeepThinking())
            OutlinedButton.icon(
              onPressed: () {
                // 在消息中添加深度思考指令
                _messageController.text =
                    '深度思考 (R1): ${_messageController.text}';
              },
              icon: const Icon(Icons.psychology, size: 16),
              label: Text(S.of(context).deepThinking),
              style: OutlinedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                side: const BorderSide(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _showAttachmentBars(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;
    return Container(
      padding: const EdgeInsets.only(
        bottom: 4.0,
        left: 16.0,
        right: 16.0,
        top: 4.0
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_chatModel.getInputModalites().contains(InputModality.image))
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_camera, size: 32),
                        onPressed: _getImageFromCamera,
                      ),
                      Text(
                        S.of(context).takePhoto,
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          if (_chatModel.getInputModalites().contains(InputModality.image))
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.insert_photo, size: 32),
                        onPressed: _getImageFromGallery,
                      ),
                      Text(
                        S.of(context).chooseFromGallery,
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          if (_chatModel.getInputModalites().contains(InputModality.file))
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.upload_file_rounded, size: 32),
                        onPressed: _pickFile,
                      ),
                      Text(
                        S.of(context).uploadFile,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // 显示提示信息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80.0, left: 16.0, right: 16.0),
      ),
    );
  }

  // 从相机获取图片
  Future<void> _getImageFromCamera() async {
    // 这里需要添加相机拍照功能
    // 使用image_picker包实现
    // 实现后将图片发送到聊天
  }

  // 从相册获取图片
  Future<void> _getImageFromGallery() async {
    // 这里需要添加从相册选择图片功能
    // 使用image_picker包实现
    // 实现后将图片发送到聊天
  }

  // 选择文件
  Future<void> _pickFile() async {
    // 这里需要添加文件选择功能
    // 使用file_picker包实现
    // 实现后将文件发送到聊天
  }
}
