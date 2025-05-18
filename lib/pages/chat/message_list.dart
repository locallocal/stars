import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/pages/chat/audio_player_widget.dart';
import 'package:bubble/pages/chat/video_player_widget.dart';
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
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    // 在构建完成后直接滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: messages.length + (isStreaming ? 1 : 0),
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
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
                    color: Theme.of(context).colorScheme.secondary,
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
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: fontSize,
                          ),
                          code: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          blockquote: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
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
                            : Theme.of(context).colorScheme.secondary,
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
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: fontSize,
                            ),
                            code: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                            ),
                            blockquote: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      // 显示图片列表
                      if (message.images.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: message.content.isNotEmpty ? 8.0 : 0,
                          ),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children:
                                message.images.map((imagePath) {
                                  return GestureDetector(
                                    onTap: () {
                                      // 点击图片时显示大图
                                      _showImageDialog(context, imagePath);
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: 150,
                                          maxHeight: 200,
                                        ),
                                        child: Image.file(
                                          File(imagePath),
                                          fit: BoxFit.contain,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              width: 75,
                                              height: 75,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                              child: Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
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

                      // 展示语音文件并支持播放和暂停
                      if (message.audio.isNotEmpty)
                        AudioPlayerWidget(audioFilePath: message.audio),

                      if (message.music.isNotEmpty)
                        AudioPlayerWidget(audioFilePath: message.music),

                      if (message.video.isNotEmpty)
                        VideoPlayerWidget(videoFilePath: message.video),
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

void _showImageDialog(BuildContext context, String imagePath) {
  showDialog(
    context: context,
    builder:
        (context) => Dialog(
          child: Stack(
            children: [
              Image.file(File(imagePath), fit: BoxFit.contain),
              Positioned(
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    // 添加保存按钮
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.black.withOpacity(0.5),
                      onPressed: () async {
                        try {
                          // 获取图片文件
                          final file = File(imagePath);
                          // 获取原始文件名
                          final fileName =
                              imagePath.split(Platform.pathSeparator).last;

                          // 根据平台选择不同的保存方法
                          if (Platform.isAndroid || Platform.isIOS) {
                            // 移动平台使用gallery_saver_plus
                            final result = await GallerySaver.saveImage(
                              imagePath,
                              albumName: 'Bubble',
                            );
                            if (result == true) {
                              if (context.mounted) {
                                // 在图片上方中央显示保存成功提示
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  builder:
                                      (context) => AlertDialog(
                                        backgroundColor: Colors.black
                                            .withOpacity(0.7),
                                        content: const Text(
                                          '图片已保存到相册',
                                          style: TextStyle(color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                );
                                // 1.5秒后自动关闭提示
                                Future.delayed(
                                  const Duration(milliseconds: 1500),
                                  () {
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                );
                              }
                            } else {
                              throw Exception('保存到相册失败');
                            }
                          } else {
                            // 桌面平台使用FilePicker
                            final result = await FilePicker.platform.saveFile(
                              dialogTitle: '保存图片',
                              fileName: fileName,
                              type: FileType.image,
                              allowedExtensions: ['png', 'jpg', 'jpeg'],
                            );

                            if (result != null) {
                              // 复制文件到选择的位置
                              await file.copy(result);
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showSnackBar(context, '保存失败: $e');
                          }
                        }
                      },
                      child: const Icon(Icons.save_alt, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.black.withOpacity(0.5),
                      onPressed: () async {
                        try {
                          await Share.shareXFiles([
                            XFile(imagePath),
                          ], text: '来自Bubble的图片');
                        } catch (e) {
                          if (context.mounted) {
                            showSnackBar(context, '分享失败: $e');
                          }
                        }
                      },
                      child: const Icon(Icons.share, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.black.withOpacity(0.5),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
  );
}

// 在MessageList类中添加这个新方法
Widget _buildReasoningSection(BuildContext context, String reasoning) {
  return ReasoningSection(reasoning: reasoning);
}

// 添加一个新的有状态Widget类
class ReasoningSection extends StatefulWidget {
  final String reasoning;

  const ReasoningSection({super.key, required this.reasoning});

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
