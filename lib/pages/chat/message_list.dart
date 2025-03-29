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

  const MessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isStreaming,
    required this.streamingResponse,
    required this.currentUserId,
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
                  child: MarkdownBody(
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
                  child: MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: Colors.black,
                        fontSize:
                            Theme.of(context).textTheme.bodyLarge?.fontSize,
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
