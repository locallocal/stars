import 'dart:io';
import 'package:stars/model/model.dart';
import 'package:stars/pages/chat/audio_player_widget.dart';
import 'package:stars/pages/chat/video_player_widget.dart';
import 'package:stars/pages/common/common.dart';
import 'package:stars/utils/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final bool isStreaming;
  final String streamingResponse;
  final MessageProcessInfo streamingProcessInfo;
  final String currentUserId;
  final bool? deepThinking;
  final String? reasoningResponse;
  final bool isDesktop;

  const MessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isStreaming,
    required this.streamingResponse,
    this.streamingProcessInfo = const MessageProcessInfo(),
    required this.currentUserId,
    this.deepThinking = false,
    this.reasoningResponse = '',
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: messages.length + (isStreaming ? 1 : 0),
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 18 : 0,
          isDesktop ? 12 : 8,
          isDesktop ? 18 : 0,
          isDesktop ? 36 : 8,
        ),
        itemBuilder: (context, index) {
          if (isStreaming && index == messages.length) {
            return _buildMessageRow(
              context,
              bubble: _MessageBubble(
                isCurrentUser: false,
                isDesktop: isDesktop,
                reasoning: deepThinking == true ? reasoningResponse ?? '' : '',
                processInfo: streamingProcessInfo,
                content: streamingResponse,
              ),
            );
          }

          final message = messages[index];
          final isMe = message.senderId == currentUserId;
          return _buildMessageRow(
            context,
            isCurrentUser: isMe,
            bubble: GestureDetector(
              onLongPress:
                  message.content.isEmpty
                      ? null
                      : () {
                        Clipboard.setData(ClipboardData(text: message.content));
                      },
              child: _MessageBubble(
                isCurrentUser: isMe,
                isDesktop: isDesktop,
                reasoning: message.reasoning,
                processInfo: message.processInfo,
                content: message.content,
                images: message.images,
                files: message.files,
                audio: message.audio,
                music: message.music,
                video: message.video,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageRow(
    BuildContext context, {
    required Widget bubble,
    bool isCurrentUser = false,
  }) {
    final viewportMaxWidth =
        isDesktop ? StarsDesktopTheme.contentMaxWidth : double.infinity;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 10 : 4),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: viewportMaxWidth),
          child: Align(
            alignment:
                isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    isDesktop
                        ? (isCurrentUser
                            ? StarsDesktopTheme.messageBubbleMaxWidth
                            : StarsDesktopTheme.contentMaxWidth - 48)
                        : MediaQuery.of(context).size.width * 0.8,
              ),
              child: bubble,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool isCurrentUser;
  final bool isDesktop;
  final String reasoning;
  final MessageProcessInfo processInfo;
  final String content;
  final List<String> images;
  final List<String> files;
  final String audio;
  final String music;
  final String video;

  const _MessageBubble({
    required this.isCurrentUser,
    required this.isDesktop,
    required this.reasoning,
    this.processInfo = const MessageProcessInfo(),
    required this.content,
    this.images = const [],
    this.files = const [],
    this.audio = '',
    this.music = '',
    this.video = '',
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14;
    final hasStructuredSections =
        reasoning.isNotEmpty ||
        processInfo.hasData ||
        images.isNotEmpty ||
        files.isNotEmpty ||
        audio.isNotEmpty ||
        music.isNotEmpty ||
        video.isNotEmpty;
    final useBubbleShell = !isDesktop || isCurrentUser || hasStructuredSections;
    final backgroundColor =
        isCurrentUser
            ? StarsDesktopTheme.userBubble(context)
            : StarsDesktopTheme.assistantBubble(context);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reasoning.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  content.isNotEmpty ||
                          processInfo.hasData ||
                          _hasStructuredMedia
                      ? 14
                      : 0,
            ),
            child: ReasoningSection(reasoning: reasoning, isDesktop: isDesktop),
          ),
        if (processInfo.hasData)
          Padding(
            padding: EdgeInsets.only(
              bottom: content.isNotEmpty || _hasStructuredMedia ? 14 : 0,
            ),
            child: ProcessInfoSection(
              processInfo: processInfo,
              isDesktop: isDesktop,
              hasReasoningContent: reasoning.isNotEmpty,
            ),
          ),
        if (content.isNotEmpty)
          MarkdownBody(
            data: content,
            selectable: true,
            styleSheet: _buildMarkdownStyleSheet(context, fontSize),
          ),
        if (images.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: content.isNotEmpty ? 14 : 0),
            child: _StatusCardSection(
              isDesktop: isDesktop,
              icon: Icons.image_outlined,
              title: isCurrentUser ? '图片附件' : '图片结果',
              subtitle: '${images.length} 项',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    images
                        .map(
                          (imagePath) => _buildImagePreview(context, imagePath),
                        )
                        .toList(),
              ),
            ),
          ),
        if (files.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: (content.isNotEmpty || images.isNotEmpty) ? 12 : 0,
            ),
            child: _StatusCardSection(
              isDesktop: isDesktop,
              icon: Icons.attach_file_rounded,
              title: isCurrentUser ? '文件附件' : '文件结果',
              subtitle: '${files.length} 个文件',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    files
                        .map(
                          (filePath) => _buildFilePreview(
                            context,
                            filePath,
                            isCurrentUser,
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        if (audio.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: _hasMediaAbove ? 12 : 0),
            child: _StatusCardSection(
              isDesktop: isDesktop,
              icon: Icons.graphic_eq_rounded,
              title: '语音结果',
              subtitle: '可直接播放',
              child: AudioPlayerWidget(audioFilePath: audio),
            ),
          ),
        if (music.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: _hasMediaAbove || audio.isNotEmpty ? 12 : 0,
            ),
            child: _StatusCardSection(
              isDesktop: isDesktop,
              icon: Icons.music_note_rounded,
              title: '音乐结果',
              subtitle: '可直接播放',
              child: AudioPlayerWidget(audioFilePath: music),
            ),
          ),
        if (video.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top:
                  _hasMediaAbove || audio.isNotEmpty || music.isNotEmpty
                      ? 12
                      : 0,
            ),
            child: _StatusCardSection(
              isDesktop: isDesktop,
              icon: Icons.video_camera_back_outlined,
              title: '视频结果',
              subtitle: '可直接预览',
              child: VideoPlayerWidget(videoFilePath: video),
            ),
          ),
      ],
    );

    if (!useBubbleShell) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 8),
        child: body,
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 8),
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          isDesktop ? StarsDesktopTheme.bubbleRadius : 16,
        ),
        border:
            isDesktop
                ? Border.all(color: StarsDesktopTheme.borderColor(context))
                : null,
      ),
      child: body,
    );
  }

  bool get _hasMediaAbove =>
      content.isNotEmpty || images.isNotEmpty || files.isNotEmpty;

  bool get _hasStructuredMedia =>
      images.isNotEmpty ||
      files.isNotEmpty ||
      audio.isNotEmpty ||
      music.isNotEmpty ||
      video.isNotEmpty;

  Widget _buildImagePreview(BuildContext context, String imagePath) {
    return GestureDetector(
      onTap: () {
        _showImageDialog(context, imagePath);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 220 : 150,
            maxHeight: isDesktop ? 240 : 200,
          ),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 96,
                height: 96,
                color: Theme.of(context).colorScheme.onSurface,
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(
    BuildContext context,
    String filePath,
    bool isCurrentUser,
  ) {
    final fileName = filePath.split(Platform.pathSeparator).last;

    return Container(
      width: isDesktop ? 220 : 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? Colors.white.withValues(alpha: 0.28)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StarsDesktopTheme.borderColor(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            size: 24,
            color: StarsDesktopTheme.mutedText(context),
          ),
          const SizedBox(height: 8),
          Text(
            fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(
    BuildContext context,
    double fontSize,
  ) {
    return MarkdownStyleSheet(
      p: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize,
        height: 1.55,
      ),
      code: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        backgroundColor: StarsDesktopTheme.elevatedSurface(context),
        fontSize: fontSize - 1,
      ),
      h1: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize + 6,
        fontWeight: FontWeight.w700,
      ),
      h2: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize + 3,
        fontWeight: FontWeight.w700,
      ),
      h3: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize + 1,
        fontWeight: FontWeight.w600,
      ),
      blockquote: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
      ),
      codeblockDecoration: BoxDecoration(
        color: StarsDesktopTheme.elevatedSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StarsDesktopTheme.borderColor(context)),
      ),
      blockSpacing: 10,
      listBullet: TextStyle(
        color: StarsDesktopTheme.mutedText(context),
        fontSize: fontSize,
      ),
    );
  }
}

class _StatusCardSection extends StatelessWidget {
  final bool isDesktop;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _StatusCardSection({
    required this.isDesktop,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isDesktop ? StarsDesktopTheme.cardRadius : 14.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 14 : 12),
      decoration: BoxDecoration(
        color: StarsDesktopTheme.statusCardBackground(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: StarsDesktopTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:
                            (Theme.of(context).textTheme.bodyLarge?.fontSize ??
                                14) -
                            1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: StarsDesktopTheme.mutedText(context),
                        fontSize:
                            (Theme.of(context).textTheme.bodyMedium?.fontSize ??
                                12) -
                            1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
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
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      onPressed: () async {
                        try {
                          final file = File(imagePath);
                          final fileName =
                              imagePath.split(Platform.pathSeparator).last;

                          if (Platform.isAndroid || Platform.isIOS) {
                            final result = await GallerySaver.saveImage(
                              imagePath,
                              albumName: 'Stars',
                            );
                            if (result == true) {
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  builder:
                                      (context) => AlertDialog(
                                        backgroundColor: Colors.black
                                            .withValues(alpha: 0.7),
                                        content: const Text(
                                          '图片已保存到相册',
                                          style: TextStyle(color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                );
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
                            final result = await FilePicker.platform.saveFile(
                              dialogTitle: '保存图片',
                              fileName: fileName,
                              type: FileType.image,
                              allowedExtensions: ['png', 'jpg', 'jpeg'],
                            );

                            if (result != null) {
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
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      onPressed: () async {
                        try {
                          await Share.shareXFiles([
                            XFile(imagePath),
                          ], text: '来自 Stars 的图片');
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
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
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

class ReasoningSection extends StatefulWidget {
  final String reasoning;
  final bool isDesktop;

  const ReasoningSection({
    super.key,
    required this.reasoning,
    this.isDesktop = false,
  });

  @override
  State<ReasoningSection> createState() => _ReasoningSectionState();
}

class ProcessInfoSection extends StatelessWidget {
  final MessageProcessInfo processInfo;
  final bool isDesktop;
  final bool hasReasoningContent;

  const ProcessInfoSection({
    super.key,
    required this.processInfo,
    this.isDesktop = false,
    this.hasReasoningContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final summaryChips = <Widget>[];

    if (!hasReasoningContent && processInfo.reasoningStatus.isNotEmpty) {
      summaryChips.add(
        _ProcessChip(
          icon: Icons.psychology_alt_rounded,
          label: _reasoningStatusLabel(processInfo.reasoningStatus),
        ),
      );
    }

    if (processInfo.durationMs != null) {
      summaryChips.add(
        _ProcessChip(
          icon: Icons.timelapse_rounded,
          label: '耗时 ${_formatDuration(processInfo.durationMs!)}',
        ),
      );
    }

    if (processInfo.toolCalls.isNotEmpty) {
      summaryChips.add(
        _ProcessChip(
          icon: Icons.build_outlined,
          label: '工具 ${processInfo.toolCalls.length}',
        ),
      );
    }

    if (processInfo.commandExecutions.isNotEmpty) {
      summaryChips.add(
        _ProcessChip(
          icon: Icons.terminal_rounded,
          label: '命令 ${processInfo.commandExecutions.length}',
        ),
      );
    }

    if (processInfo.fileEdits.isNotEmpty) {
      summaryChips.add(
        _ProcessChip(
          icon: Icons.edit_note_rounded,
          label: '文件 ${processInfo.fileEdits.length}',
        ),
      );
    }

    return _StatusCardSection(
      isDesktop: isDesktop,
      icon: Icons.auto_awesome_motion_rounded,
      title: '执行状态',
      subtitle: _buildSubtitle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summaryChips.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: summaryChips),
          if (processInfo.toolCalls.isNotEmpty) ...[
            SizedBox(height: summaryChips.isNotEmpty ? 12 : 0),
            _ProcessListCard<MessageToolCall>(
              title: '工具调用',
              icon: Icons.build_outlined,
              items: processInfo.toolCalls,
              titleBuilder: (item) => item.name,
              subtitleBuilder: (item) => _joinMeta([
                if (item.detail.isNotEmpty) item.detail,
                if (item.durationMs != null)
                  '耗时 ${_formatDuration(item.durationMs!)}',
              ]),
              statusBuilder: (item) => item.status,
            ),
          ],
          if (processInfo.commandExecutions.isNotEmpty) ...[
            SizedBox(height: summaryChips.isNotEmpty ? 12 : 0),
            _ProcessListCard<MessageCommandExecution>(
              title: '命令执行',
              icon: Icons.terminal_rounded,
              items: processInfo.commandExecutions,
              titleBuilder: (item) => item.command,
              subtitleBuilder: (item) => _joinMeta([
                if (item.detail.isNotEmpty) item.detail,
                if (item.durationMs != null)
                  '耗时 ${_formatDuration(item.durationMs!)}',
              ]),
              statusBuilder: (item) => item.status,
            ),
          ],
          if (processInfo.fileEdits.isNotEmpty) ...[
            SizedBox(height: summaryChips.isNotEmpty ? 12 : 0),
            _ProcessListCard<MessageFileEdit>(
              title: '文件状态',
              icon: Icons.description_outlined,
              items: processInfo.fileEdits,
              titleBuilder: (item) => item.path.split(Platform.pathSeparator).last,
              subtitleBuilder: (item) => _joinMeta([
                if (item.detail.isNotEmpty) item.detail,
                if (item.type.isNotEmpty) _fileTypeLabel(item.type),
              ]),
              statusBuilder: (item) => item.status,
            ),
          ],
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (processInfo.durationMs != null) {
      parts.add('包含耗时');
    }
    if (processInfo.toolCalls.isNotEmpty) {
      parts.add('${processInfo.toolCalls.length} 次工具调用');
    }
    if (processInfo.commandExecutions.isNotEmpty) {
      parts.add('${processInfo.commandExecutions.length} 次命令执行');
    }
    if (processInfo.fileEdits.isNotEmpty) {
      parts.add('${processInfo.fileEdits.length} 条文件状态');
    }
    return parts.isEmpty ? '结构化过程信息' : parts.join(' · ');
  }
}

class _ProcessChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProcessChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: StarsDesktopTheme.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: StarsDesktopTheme.mutedText(context),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessListCard<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<T> items;
  final String Function(T item) titleBuilder;
  final String Function(T item) subtitleBuilder;
  final String Function(T item) statusBuilder;

  const _ProcessListCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.statusBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StarsDesktopTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: StarsDesktopTheme.mutedText(context)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final subtitle = subtitleBuilder(item);
            final hasSubtitle = subtitle.isNotEmpty;
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key == items.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleBuilder(item),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (hasSubtitle) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: StarsDesktopTheme.mutedText(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(status: statusBuilder(item)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.isEmpty ? 'unknown' : status;
    final colors = _statusColors(context, normalized);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$2),
      ),
      child: Text(
        _statusLabel(normalized),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.$3,
        ),
      ),
    );
  }

  (Color, Color, Color) _statusColors(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'completed':
      case 'created':
      case 'attached':
        return (
          colorScheme.primary.withValues(alpha: 0.10),
          colorScheme.primary.withValues(alpha: 0.18),
          colorScheme.primary,
        );
      case 'streaming':
      case 'running':
        return (
          Colors.orange.withValues(alpha: 0.12),
          Colors.orange.withValues(alpha: 0.2),
          Colors.orange.shade800,
        );
      case 'cancelled':
        return (
          Colors.grey.withValues(alpha: 0.14),
          Colors.grey.withValues(alpha: 0.2),
          Colors.grey.shade800,
        );
      default:
        return (
          StarsDesktopTheme.elevatedSurface(context),
          StarsDesktopTheme.borderColor(context),
          StarsDesktopTheme.mutedText(context),
        );
    }
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'completed':
      return '已完成';
    case 'created':
      return '已生成';
    case 'attached':
      return '已附加';
    case 'streaming':
      return '进行中';
    case 'running':
      return '执行中';
    case 'cancelled':
      return '已取消';
    default:
      return '已记录';
  }
}

String _reasoningStatusLabel(String status) {
  switch (status) {
    case 'completed':
      return '思考完成';
    case 'cancelled':
      return '思考中断';
    case 'streaming':
      return '思考中';
    default:
      return '过程信息';
  }
}

String _fileTypeLabel(String type) {
  switch (type) {
    case 'image':
      return '图片';
    case 'audio':
      return '语音';
    case 'music':
      return '音乐';
    case 'video':
      return '视频';
    default:
      return '文件';
  }
}

String _joinMeta(List<String> parts) {
  final filtered = parts.where((item) => item.isNotEmpty).toList();
  return filtered.join(' · ');
}

String _formatDuration(int durationMs) {
  if (durationMs < 1000) {
    return '${durationMs}ms';
  }
  final seconds = durationMs / 1000;
  return '${seconds.toStringAsFixed(seconds >= 10 ? 0 : 1)}s';
}

class _ReasoningSectionState extends State<ReasoningSection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14;

    return Container(
      decoration: BoxDecoration(
        color: StarsDesktopTheme.statusCardBackground(context),
        borderRadius: BorderRadius.circular(
          widget.isDesktop ? StarsDesktopTheme.cardRadius : 14,
        ),
        border: Border.all(color: StarsDesktopTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(
              widget.isDesktop ? StarsDesktopTheme.cardRadius : 14,
            ),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '过程信息',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: fontSize - 1,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '深度思考',
                          style: TextStyle(
                            fontSize: fontSize - 3,
                            color: StarsDesktopTheme.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: isExpanded ? 0 : 0.5,
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: StarsDesktopTheme.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: MarkdownBody(
                  data: widget.reasoning,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: StarsDesktopTheme.mutedText(context),
                      fontSize: fontSize - 1,
                      height: 1.5,
                    ),
                    code: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      backgroundColor: StarsDesktopTheme.elevatedSurface(
                        context,
                      ),
                      fontSize: fontSize - 2,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: StarsDesktopTheme.elevatedSurface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: StarsDesktopTheme.borderColor(context),
                      ),
                    ),
                    blockSpacing: 8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
