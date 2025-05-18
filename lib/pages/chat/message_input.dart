import 'package:bubble/services/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/pages/common/common.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Provider provider;
  final bool waitingBotMessage;
  final Function() onSend;
  final Function() onCancelRequest;
  final Function() onCameraPressed;
  final Function() onGalleryPressed;
  final Function() onFilePressed;
  final Function(String) onImageSizeSelected;
  final Function(String) onImageStyleSelected;
  final Function(String) onVideoRatioSelected;

  const MessageInput({
    super.key,
    required this.provider,
    required this.controller,
    required this.waitingBotMessage,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    required this.onFilePressed,
    required this.onImageSizeSelected,
    required this.onImageStyleSelected,
    required this.onVideoRatioSelected,
    required this.onSend,
    required this.onCancelRequest,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  String selectedImageStyle = '';
  String selectedImageRatio = '';
  String selectedVideoRatio = '';
  bool isWebSearchEnabled = false;
  bool isDeepThinkingEnabled = false;
  bool showGenerateImageOptions = false;
  bool showGenerateVideoOptions = false;
  bool showAttachmentInputs = false;

  @override
  void initState() {
    super.initState();
    if (widget.provider.getOutputModalites().contains(OutputModality.image)) {
      if (widget.provider.getSupportedImageSizes().isNotEmpty) {
        selectedImageRatio = widget.provider.getSupportedImageSizes().first;
      }
    }
    if (widget.provider.getOutputModalites().contains(OutputModality.video)) {
      if (widget.provider.getSupportVideoRatios().isNotEmpty) {
        selectedVideoRatio = widget.provider.getSupportVideoRatios().first;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return Column(
      children: [
        // 主输入区域
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            bottom:
                (widget.provider.supportWebSearch() ||
                        widget.provider.supportDeepThinking() ||
                        widget.provider.getOutputModalites().contains(
                          OutputModality.image,
                        ) ||
                        widget.provider.getOutputModalites().contains(
                          OutputModality.video,
                        ))
                    ? 8
                    : 0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            children: [
              // 文本输入区域
              TextField(
                controller: widget.controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) => widget.onSend(),
                decoration: InputDecoration(
                  hintText: '请输入提示词',
                  hintStyle: TextStyle(
                    fontSize: fontSize,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  border: InputBorder.none,
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, child) {
                      if (widget.waitingBotMessage) {
                        return IconButton(
                          onPressed: widget.onCancelRequest,
                          icon: const Icon(Icons.pause_circle_filled),
                          tooltip: S.of(context).pauseGeneration,
                          padding: EdgeInsets.zero,
                        );
                      }
                      // 同时显示附件和发送按钮
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 附件按钮
                          if (widget.provider.getInputModalites().contains(
                                InputModality.image,
                              ) ||
                              widget.provider.getInputModalites().contains(
                                InputModality.file,
                              ))
                            IconButton(
                              icon:
                                  showAttachmentInputs
                                      ? buildCloseIcon(context)
                                      : Icon(Icons.add_circle_rounded),
                              onPressed: () {
                                setState(() {
                                  showAttachmentInputs = !showAttachmentInputs;
                                });
                                // 这里添加处理附件的逻辑
                              },
                            ),

                          // 发送按钮 - 仅当有文本或附件时显示
                          if (value.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              onPressed: widget.onSend,
                            ),
                        ],
                      );
                    },
                  ),
                ),
                maxLines: 6,
                minLines: 3,
                textAlignVertical: TextAlignVertical.center,
              ),

              // 底部工具栏
              Row(
                children: [
                  if (widget.provider.supportWebSearch())
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isWebSearchEnabled = !isWebSearchEnabled;
                          widget.provider.setWebSearch(isWebSearchEnabled);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isWebSearchEnabled
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3)
                                  : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.public,
                              size: fontSize,
                              color:
                                  isWebSearchEnabled
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(width: 4),
                            Text(
                              S.of(context).webSearch,
                              style: TextStyle(
                                fontSize: fontSize! - 2,
                                color:
                                    isWebSearchEnabled
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                fontWeight:
                                    isWebSearchEnabled
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.provider.supportWebSearch()) SizedBox(width: 8),

                  if (widget.provider.supportDeepThinking())
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isDeepThinkingEnabled = !isDeepThinkingEnabled;
                          widget.provider.setDeepThinking(
                            isDeepThinkingEnabled,
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDeepThinkingEnabled
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3)
                                  : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.psychology,
                              size: fontSize! + 2,
                              color:
                                  isDeepThinkingEnabled
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(width: 4),
                            Text(
                              S.of(context).deepThinking,
                              style: TextStyle(
                                fontSize: fontSize - 2,
                                color:
                                    isDeepThinkingEnabled
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                fontWeight:
                                    isDeepThinkingEnabled
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.provider.supportDeepThinking()) SizedBox(width: 8),

                  if (widget.provider.getOutputModalites().contains(
                    OutputModality.image,
                  ))
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showGenerateImageOptions = !showGenerateImageOptions;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: fontSize! - 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              selectedImageStyle,
                              style: TextStyle(
                                fontSize: fontSize - 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              selectedImageRatio,
                              style: TextStyle(
                                fontSize: fontSize - 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              showGenerateImageOptions
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (widget.provider.getOutputModalites().contains(
                    OutputModality.video,
                  ))
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showGenerateVideoOptions = !showGenerateVideoOptions;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_camera_back_rounded,
                              size: fontSize! - 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              selectedVideoRatio,
                              style: TextStyle(
                                fontSize: fontSize - 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              showGenerateVideoOptions
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              if (showAttachmentInputs)
                Row(
                  children: [
                    if (widget.provider.getInputModalites().contains(
                      InputModality.image,
                    ))
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                              right: 8,
                              bottom: 8,
                              top: 8,
                            ),
                            padding: const EdgeInsets.only(
                              bottom: 8,
                              left: 6,
                              right: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.photo_camera,
                                    size: 24,
                                  ),
                                  onPressed: widget.onCameraPressed,
                                ),
                                Text(
                                  S.of(context).takePhoto,
                                  style: TextStyle(fontSize: fontSize! - 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    if (widget.provider.getInputModalites().contains(
                      InputModality.image,
                    ))
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                              right: 8,
                              bottom: 8,
                              top: 8,
                            ),
                            padding: const EdgeInsets.only(
                              bottom: 8,
                              left: 6,
                              right: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.insert_photo,
                                    size: 24,
                                  ),
                                  onPressed: widget.onGalleryPressed,
                                ),
                                Text(
                                  S.of(context).chooseFromGallery,
                                  style: TextStyle(fontSize: fontSize! - 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    if (widget.provider.getInputModalites().contains(
                      InputModality.file,
                    ))
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8, bottom: 8),
                            padding: const EdgeInsets.only(
                              bottom: 8,
                              left: 6,
                              right: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.upload_file_rounded,
                                    size: 24,
                                  ),
                                  onPressed: widget.onFilePressed,
                                ),
                                Text(
                                  S.of(context).uploadFile,
                                  style: TextStyle(fontSize: fontSize! - 2),
                                ),
                                SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

              if (showGenerateImageOptions) SizedBox(height: 12),
              // 展开的选项面板
              if (showGenerateImageOptions &&
                  widget.provider.getSupportImageStyles().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 模型选择
                    Text(
                      '选择风格: $selectedImageStyle',
                      style: TextStyle(
                        fontSize: fontSize! - 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 96,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...(widget.provider.getSupportImageStyles()).map(
                            (style) => _buildStyleOption(style),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              if (showGenerateImageOptions &&
                  widget.provider.getSupportedImageSizes().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择比例: $selectedImageRatio',
                      style: TextStyle(
                        fontSize: fontSize! - 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          constraints: BoxConstraints(
                            maxHeight: 100,
                            minHeight: 80,
                          ),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...(widget.provider.getSupportedImageSizes()).map(
                                (size) => _buildImageRatioOption(size),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),

              if (showGenerateVideoOptions) SizedBox(height: 12),
              // 展开的选项面板
              if (showGenerateVideoOptions &&
                  widget.provider.getSupportVideoRatios().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择比例: $selectedVideoRatio',
                      style: TextStyle(
                        fontSize: fontSize! - 2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          constraints: BoxConstraints(
                            maxHeight: 120,
                            minHeight: 80,
                          ),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...(widget.provider.getSupportVideoRatios()).map(
                                (size) => _buildVideoRatioOption(size),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyleOption(String name) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedImageStyle == name) {
            selectedImageStyle = '';
          } else {
            selectedImageStyle = name;
          }
          widget.onImageStyleSelected(selectedImageStyle);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color:
              selectedImageStyle == name
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 风格图标或预览图
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                Icons.image,
                color:
                    selectedImageStyle == name
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            // 风格名称
            Text(
              name,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize! - 2,
                fontWeight:
                    selectedImageStyle == name
                        ? FontWeight.bold
                        : FontWeight.normal,
                color:
                    selectedImageStyle == name
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageRatioOption(String ratio) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    // 解析比例
    var width = 1.0;
    var height = 1.0;
    if (ratio.contains(':')) {
      final parts = ratio.split(':');
      width = double.parse(parts[0]);
      height = double.parse(parts[1]);
    } else if (ratio.contains('x')) {
      final parts = ratio.split('x');
      width = double.parse(parts[0]);
      height = double.parse(parts[1]);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedImageRatio = ratio;
          widget.onImageSizeSelected(ratio);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              selectedImageRatio == ratio
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 比例可视化
            Container(
              width: 24,
              height: 24 * (height / width),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color:
                      selectedImageRatio == ratio
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                  width: 0.3,
                ),
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            // 比例文本
            Text(
              ratio,
              style: TextStyle(
                fontSize: fontSize! - 2,
                fontWeight: FontWeight.bold,
                color:
                    selectedImageRatio == ratio
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoRatioOption(String ratio) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    // 解析比例
    var width = 1.0;
    var height = 1.0;
    if (ratio.contains(':')) {
      final parts = ratio.split(':');
      width = double.parse(parts[0]);
      height = double.parse(parts[1]);
    } else if (ratio.contains('x')) {
      final parts = ratio.split('x');
      width = double.parse(parts[0]);
      height = double.parse(parts[1]);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVideoRatio = ratio;
          widget.onVideoRatioSelected(ratio);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              selectedVideoRatio == ratio
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 比例可视化
            Container(
              width: 24,
              height: 24 * (height / width),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color:
                      selectedVideoRatio == ratio
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                  width: 0.3,
                ),
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            // 比例文本
            Text(
              ratio,
              style: TextStyle(
                fontSize: fontSize! - 2,
                fontWeight: FontWeight.bold,
                color:
                    selectedVideoRatio == ratio
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
