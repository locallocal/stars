import 'package:flutter/material.dart';
import 'package:bubble/services/message_service.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/services/models/chat_models.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:bubble/generated/l10n.dart';

// 聊天页面
class ChatPage extends StatefulWidget {
  final Bot bot;

  const ChatPage({super.key, required this.bot});

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

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // 初始化聊天模型
    _chatModel = ChatModel.create(widget.bot);
  }

  // 在加载消息后滚动到底部
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    final messages = await MessageService.getMessages(widget.bot.id);
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

  // 在dispose中释放ScrollController
  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // 在发送消息后滚动到底部
  // 修改发送消息方法，使用抽象聊天模型
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final messageText = _messageController.text;

    // 创建用户消息
    final userMessage = Message(
      type: "text",
      botId: widget.bot.id,
      senderId: _currentUserId,
      content: messageText,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isTyping = true; // 显示机器人正在输入
      _isStreaming = true; // 开始流式接收
      _streamingResponse = ''; // 清空流式响应
      _isCancellable = true; // 设置为可取消
    });

    // 保存用户消息到本地存储
    await MessageService.addMessage(userMessage);

    // 更新聊天列表中的最后一条消息
    await ChatService.updateLastMessage(widget.bot.id, messageText);

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

    try {
      // 准备聊天消息
      final List<ChatMessage> chatMessages = [];

      // 如果有系统提示，添加到消息列表
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

      // 添加当前用户消息
      chatMessages.add(ChatMessage(role: "user", content: messageText));

      // 使用流式响应
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
                _isCancellable = false; // 重置可取消状态
              });
              _showSnackBar(S.of(context).emptyResponseError);
            }
            return;
          }

          // 创建最终AI回复消息
          final botMessage = Message(
            type: "text",
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
          await ChatService.updateLastMessage(
            widget.bot.id,
            botMessage.content,
          );

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.bot.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
          ),
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
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.smart_toy_rounded,
                                      size: 96,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
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
                                      S.of(context).botGreeting(widget.bot.name),
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
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.8,
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                              horizontal: 8.0,
                                            ),
                                            padding: const EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  isMe
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                      : Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                            ),
                                            child: MarkdownBody(
                                              data: message.content,
                                              selectable: true,
                                              styleSheet: MarkdownStyleSheet(
                                                p: TextStyle(
                                                  color:
                                                      isMe
                                                          ? Colors.white
                                                          : Colors.black,
                                                  fontSize: 16,
                                                ),
                                                code: TextStyle(
                                                  color:
                                                      isMe
                                                          ? Colors.white
                                                          : Colors.black,
                                                  backgroundColor:
                                                      isMe
                                                          ? Colors.white
                                                              .withOpacity(0.1)
                                                          : Colors.black
                                                              .withOpacity(0.1),
                                                ),
                                                blockquote: TextStyle(
                                                  color:
                                                      isMe
                                                          ? Colors.white
                                                          : Colors.black,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // 显示"正在输入"提示
                                if (_isTyping)
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
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
                                        Text(S.of(context).botIsTyping(widget.bot.name)),
                                        const Spacer(),
                                        if (_isCancellable)
                                          IconButton(
                                            onPressed: _cancelRequest,
                                            icon: const Icon(
                                              Icons.pause_circle_filled,
                                            ),
                                            tooltip: S.of(context).pauseGeneration,
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
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
                      ),
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.center,
                    ),
                  ),
                  const SizedBox(height: 16.0),
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
    await MessageService.deleteBotMessage(widget.bot.id);
    // 更新聊天列表中的最后一条消息
    await ChatService.updateLastMessage(widget.bot.id, '');

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
          botId: widget.bot.id,
          senderId: widget.bot.id,
          content: _streamingResponse,
          timestamp: DateTime.now(),
        );
        _messages.add(botMessage);
        _streamingResponse = '';

        // 异步保存消息和更新聊天列表
        MessageService.addMessage(botMessage).then((_) {
          ChatService.updateLastMessage(widget.bot.id, botMessage.content);
        });
      }
    });
    _showSnackBar(S.of(context).replyCancelled);
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
}
