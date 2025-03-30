import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/common/common.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final bool isStreaming;
  final String streamingResponse;
  final String currentUserId;
  final bool? deepThinking;
  final String? reasoningResponse;

  const MessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isStreaming,
    required this.streamingResponse,
    required this.currentUserId,
    this.deepThinking = false,
    this.reasoningResponse = '',
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: messages.length + (isStreaming ? 1 : 0),
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          if (index == messages.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }

          if (isStreaming && index == messages.length) {
            return Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 如果开启了深度思考且有思维链内容，显示思维链部分
                      if (deepThinking == true &&
                          reasoningResponse != null &&
                          reasoningResponse!.isNotEmpty)
                        _buildReasoningSection(context, reasoningResponse!),

                      // 显示主要响应内容
                      MarkdownBody(
                        data: streamingResponse,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: Colors.black,
                            fontSize:
                                Theme.of(context).textTheme.bodyLarge?.fontSize,
                          ),
                          code: TextStyle(
                            color: Colors.black,
                            backgroundColor: Colors.black.withOpacity(0.1),
                          ),
                          blockquote: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final message = messages[index];
          final isMe = message.senderId == currentUserId;

          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.content));
                showSnackBar(context, S.of(context).messageCopied);
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
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
                            ).colorScheme.primary.withOpacity(0.3)
                            : Theme.of(
                              context,
                            ).colorScheme.secondary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.reasoning.isNotEmpty)
                        _buildReasoningSection(context, message.reasoning),

                      // 显示文本内容
                      if (message.content.isNotEmpty)
                        MarkdownBody(
                          data: message.content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: Colors.black,
                              fontSize:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.fontSize,
                            ),
                            code: TextStyle(
                              color: Colors.black,
                              backgroundColor:
                                  isMe
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.1),
                            ),
                            blockquote: const TextStyle(
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      // 显示图片列表
                      if (message.images.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children:
                              message.images.map((imagePath) {
                                return GestureDetector(
                                  onTap: () {
                                    // 点击图片时显示大图
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => Dialog(
                                            child: Image.file(
                                              File(imagePath),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.file(
                                      File(imagePath),
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          width: 150,
                                          height: 150,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                      // 显示文件列表
                      if (message.files.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children:
                              message.files.map((filePath) {
                                final fileName = filePath.split('/').last;
                                return GestureDetector(
                                  onTap: () {
                                    // 点击文件时打开文件
                                    // 这里可以添加打开文件的逻辑
                                  },
                                  child: Container(
                                    width: 150,
                                    height: 80,
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color:
                                          isMe
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.black.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.insert_drive_file,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          fileName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 在MessageList类中添加这个新方法
Widget _buildReasoningSection(BuildContext context, String reasoning) {
  return ReasoningSection(reasoning: reasoning);
}

// 添加一个新的有状态Widget类
class ReasoningSection extends StatefulWidget {
  final String reasoning;

  const ReasoningSection({Key? key, required this.reasoning}) : super(key: key);

  @override
  State<ReasoningSection> createState() => _ReasoningSectionState();
}

class _ReasoningSectionState extends State<ReasoningSection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge!.fontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 深度思考标题栏，可点击展开/折叠
        InkWell(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 4),
                Text(
                  '深度思考',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: fontSize! - 2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 思维链内容，根据展开状态显示或隐藏
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: MarkdownBody(
                data: widget.reasoning,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: fontSize - 2,
                    fontStyle: FontStyle.italic,
                  ),
                  code: TextStyle(
                    color: Colors.black87,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.05),
                    fontSize: fontSize - 2,
                  ),
                ),
              ),
            ),
          ),
        const Divider(),
      ],
    );
  }
}
