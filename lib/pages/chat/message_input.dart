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

  const MessageInput({
    super.key,
    required this.provider,
    required this.controller,
    required this.waitingBotMessage,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    required this.onFilePressed,
    required this.onSend,
    required this.onCancelRequest,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  String selectedModel = '图片 2.0 Pro';
  String selectedRatio = '3:4';
  bool isWebSearchEnabled = false;
  bool isDeepThinkingEnabled = false;
  bool showGenerateImageOptions = false;
  bool showAttachmentInputs = false;

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
                        widget.provider.supportDeepThinking())
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
                            Text(
                              selectedModel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              selectedRatio,
                              style: TextStyle(
                                fontSize: 14,
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
              if (showGenerateImageOptions)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 模型选择
                    Text(
                      '选择风格:',
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
                          _buildModelOption('图片 3.0', true),
                          _buildModelOption('图片 2.1', false),
                          _buildModelOption('图片 2.0 Pro', false),
                          _buildModelOption('图片 2.0', false),
                          _buildModelOption('图片 XL Pro', false),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              if (showGenerateImageOptions)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择比例:',
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
                          _buildRatioOption('9:16'),
                          _buildRatioOption('3:4'),
                          _buildRatioOption('2:3'),
                          _buildRatioOption('1:1'),
                          _buildRatioOption('3:2'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelOption(String name, bool isNew) {
    final isSelected = selectedModel == name;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedModel = name;
        });
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // 模型预览图
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  color:
                      name == '图片 3.0'
                          ? Colors.purple.withOpacity(0.2)
                          : name == '图片 2.1'
                          ? Colors.blue.withOpacity(0.2)
                          : name == '图片 2.0 Pro'
                          ? Colors.green.withOpacity(0.2)
                          : name == '图片 2.0'
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                ),
              ),
            ),

            // New 标签
            if (isNew)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'New',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // 模型名称
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioOption(String ratio) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    // 解析比例
    final parts = ratio.split(':');
    final width = double.parse(parts[0]);
    final height = double.parse(parts[1]);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRatio = ratio;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              selectedRatio == ratio
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
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      selectedRatio == ratio
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                  width: 0.5,
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
                    selectedRatio == ratio
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
