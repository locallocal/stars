import 'package:stars/generated/l10n.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/common/common.dart';
import 'package:stars/services/providers/providers.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';
import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Provider provider;
  final bool waitingBotMessage;
  final bool hasPendingAttachments;
  final bool desktopMode;
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
    this.hasPendingAttachments = false,
    this.desktopMode = false,
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
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.provider.getOutputModalites().contains(OutputModality.image) &&
        widget.provider.getSupportedImageSizes().isNotEmpty) {
      selectedImageRatio = widget.provider.getSupportedImageSizes().first;
    }
    if (widget.provider.getOutputModalites().contains(OutputModality.video) &&
        widget.provider.getSupportVideoRatios().isNotEmpty) {
      selectedVideoRatio = widget.provider.getSupportVideoRatios().first;
    }
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
  }

  bool get _canSubmit =>
      widget.controller.text.trim().isNotEmpty || widget.hasPendingAttachments;

  bool get _isDesktop => widget.desktopMode;

  String get _modelSummary {
    final provider = widget.provider.bot.provider.trim();
    final model = widget.provider.bot.model.trim();
    if (provider.isEmpty) {
      return model;
    }
    return '$provider · $model';
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14;
    final isDesktop = _isDesktop || isDesktopOrTabletPlatform(context);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.only(
            left: isDesktop ? 0 : 16,
            right: isDesktop ? 0 : 16,
            top: 8,
          ),
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 18 : 8,
            isDesktop ? 12 : 0,
            isDesktop ? 18 : 8,
            isDesktop ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color:
                isDesktop
                    ? StarsDesktopTheme.panelBackground(context)
                    : Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
            border: Border.all(
              color:
                  _hasFocus && isDesktop
                      ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.28)
                      : isDesktop
                      ? StarsDesktopTheme.borderColor(context)
                      : Colors.transparent,
              width: _hasFocus && isDesktop ? 1.4 : 1,
            ),
            boxShadow:
                isDesktop
                    ? [
                      ...StarsDesktopTheme.panelShadow(context),
                      if (_hasFocus)
                        BoxShadow(
                          color: Colors.transparent,
                          blurRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                    ]
                    : null,
          ),
          child: Column(
            children: [
              TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
                decoration: InputDecoration(
                  hintText: '输入消息、指令或任务说明',
                  hintStyle: TextStyle(
                    fontSize: fontSize,
                    color: StarsDesktopTheme.subtleText(context),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 4 : 0,
                    vertical: isDesktop ? 8 : 12,
                  ),
                ),
                maxLines: isDesktop ? 6 : 6,
                minLines: isDesktop ? 2 : 3,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  height: isDesktop ? 1.5 : null,
                  fontSize: fontSize,
                ),
              ),
              SizedBox(height: isDesktop ? 8 : 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, child) {
                  return _buildBottomToolbar(context, fontSize, isDesktop);
                },
              ),
              if (showAttachmentInputs) ...[
                const SizedBox(height: 14),
                _buildAttachmentPanel(context, fontSize, isDesktop),
              ],
              if (showGenerateImageOptions) ...[
                const SizedBox(height: 14),
                _buildGenerateImageOptions(context, fontSize),
              ],
              if (showGenerateVideoOptions) ...[
                const SizedBox(height: 14),
                _buildGenerateVideoOptions(context, fontSize),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomToolbar(
    BuildContext context,
    double fontSize,
    bool isDesktop,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isDesktop)
                _buildInfoChip(
                  context,
                  icon: Icons.tune_rounded,
                  label: _modelSummary,
                ),
              if (widget.provider.supportWebSearch())
                _buildToggleChip(
                  context,
                  icon: Icons.public,
                  label: S.of(context).webSearch,
                  active: isWebSearchEnabled,
                  onTap: () {
                    setState(() {
                      isWebSearchEnabled = !isWebSearchEnabled;
                      widget.provider.setWebSearch(isWebSearchEnabled);
                    });
                  },
                ),
              if (widget.provider.supportDeepThinking())
                _buildToggleChip(
                  context,
                  icon: Icons.psychology_alt_rounded,
                  label: S.of(context).deepThinking,
                  active: isDeepThinkingEnabled,
                  onTap: () {
                    setState(() {
                      isDeepThinkingEnabled = !isDeepThinkingEnabled;
                      widget.provider.setDeepThinking(isDeepThinkingEnabled);
                    });
                  },
                ),
              if (widget.provider.getOutputModalites().contains(
                OutputModality.image,
              ))
                _buildActionChip(
                  context,
                  icon: Icons.image_outlined,
                  label:
                      selectedImageStyle.isEmpty
                          ? selectedImageRatio
                          : '$selectedImageStyle · $selectedImageRatio',
                  active: showGenerateImageOptions,
                  onTap: () {
                    setState(() {
                      showGenerateImageOptions = !showGenerateImageOptions;
                    });
                  },
                ),
              if (widget.provider.getOutputModalites().contains(
                OutputModality.video,
              ))
                _buildActionChip(
                  context,
                  icon: Icons.video_camera_back_outlined,
                  label: selectedVideoRatio,
                  active: showGenerateVideoOptions,
                  onTap: () {
                    setState(() {
                      showGenerateVideoOptions = !showGenerateVideoOptions;
                    });
                  },
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_supportsAttachments)
              _buildCircleActionButton(
                context,
                icon:
                    showAttachmentInputs
                        ? buildCloseIcon(context)
                        : const Icon(Icons.add_rounded),
                tooltip: S.of(context).uploadFile,
                active: showAttachmentInputs || widget.hasPendingAttachments,
                onPressed: () {
                  setState(() {
                    showAttachmentInputs = !showAttachmentInputs;
                  });
                },
              ),
            const SizedBox(width: 10),
            _buildPrimaryActionButton(context, isDesktop),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryActionButton(BuildContext context, bool isDesktop) {
    final enabled = widget.waitingBotMessage || _canSubmit;
    final onPressed =
        enabled
            ? (widget.waitingBotMessage
                ? widget.onCancelRequest
                : widget.onSend)
            : null;
    final backgroundColor =
        widget.waitingBotMessage
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.92)
            : enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.18);
    final foregroundColor =
        enabled
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);

    if (!isDesktop) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: Icon(
            widget.waitingBotMessage ? Icons.pause_rounded : Icons.send_rounded,
            color: foregroundColor,
          ),
          tooltip:
              widget.waitingBotMessage
                  ? S.of(context).pauseGeneration
                  : S.of(context).send,
          onPressed: onPressed,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow:
            enabled
                ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Row(
                key: ValueKey<bool>(widget.waitingBotMessage),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.waitingBotMessage) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Icon(Icons.send_rounded, size: 18, color: foregroundColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.waitingBotMessage ? '停止生成' : '发送',
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                      fontSize:
                          Theme.of(context).textTheme.bodyMedium?.fontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentPanel(
    BuildContext context,
    double fontSize,
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDesktop
                ? StarsDesktopTheme.elevatedSurface(context)
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            isDesktop
                ? Border.all(color: StarsDesktopTheme.borderColor(context))
                : null,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (widget.provider.getInputModalites().contains(InputModality.image))
            _buildAttachmentTile(
              context,
              label: S.of(context).takePhoto,
              icon: Icons.photo_camera,
              onTap: widget.onCameraPressed,
              fontSize: fontSize,
            ),
          if (widget.provider.getInputModalites().contains(InputModality.image))
            _buildAttachmentTile(
              context,
              label: S.of(context).chooseFromGallery,
              icon: Icons.insert_photo,
              onTap: widget.onGalleryPressed,
              fontSize: fontSize,
            ),
          if (widget.provider.getInputModalites().contains(InputModality.file))
            _buildAttachmentTile(
              context,
              label: S.of(context).uploadFile,
              icon: Icons.upload_file_rounded,
              onTap: widget.onFilePressed,
              fontSize: fontSize,
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateImageOptions(BuildContext context, double fontSize) {
    return _buildOptionPanel(
      context,
      title:
          selectedImageStyle.isEmpty
              ? '图像生成设置'
              : '图像生成设置 · $selectedImageStyle',
      children: [
        if (widget.provider.getSupportImageStyles().isNotEmpty) ...[
          Text(
            '选择风格',
            style: TextStyle(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  widget.provider
                      .getSupportImageStyles()
                      .map((style) => _buildStyleOption(style))
                      .toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (widget.provider.getSupportedImageSizes().isNotEmpty) ...[
          Text(
            '选择比例',
            style: TextStyle(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  widget.provider
                      .getSupportedImageSizes()
                      .map((size) => _buildImageRatioOption(size))
                      .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenerateVideoOptions(BuildContext context, double fontSize) {
    return _buildOptionPanel(
      context,
      title: '视频生成设置',
      children: [
        Text(
          '选择比例',
          style: TextStyle(fontSize: fontSize - 1, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                widget.provider
                    .getSupportVideoRatios()
                    .map((size) => _buildVideoRatioOption(size))
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionPanel(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StarsDesktopTheme.elevatedSurface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StarsDesktopTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return _buildActionChip(
      context,
      icon: icon,
      label: label,
      active: active,
      onTap: onTap,
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color:
              active
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12)
                  : StarsDesktopTheme.elevatedSurface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                active
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.22)
                    : StarsDesktopTheme.borderColor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  active
                      ? Theme.of(context).colorScheme.primary
                      : StarsDesktopTheme.mutedText(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color:
                    active
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: StarsDesktopTheme.elevatedSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StarsDesktopTheme.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: StarsDesktopTheme.mutedText(context)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton(
    BuildContext context, {
    required Widget icon,
    required String tooltip,
    bool active = false,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            active
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
                : StarsDesktopTheme.elevatedSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              active
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : StarsDesktopTheme.borderColor(context),
        ),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color:
            active
                ? Theme.of(context).colorScheme.primary
                : StarsDesktopTheme.mutedText(context),
        icon: icon,
      ),
    );
  }

  Widget _buildAttachmentTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required double fontSize,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: StarsDesktopTheme.borderColor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize - 2),
            ),
          ],
        ),
      ),
    );
  }

  bool get _supportsAttachments =>
      widget.provider.getInputModalites().contains(InputModality.image) ||
      widget.provider.getInputModalites().contains(InputModality.file);

  Widget _buildStyleOption(String name) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedImageStyle = selectedImageStyle == name ? '' : name;
          widget.onImageStyleSelected(selectedImageStyle);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color:
              selectedImageStyle == name
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14)
                  : Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: StarsDesktopTheme.borderColor(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.image_outlined,
                color:
                    selectedImageStyle == name
                        ? Theme.of(context).colorScheme.primary
                        : StarsDesktopTheme.mutedText(context),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
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
    return _buildRatioOption(
      ratio: ratio,
      selected: selectedImageRatio == ratio,
      onTap: () {
        setState(() {
          selectedImageRatio = ratio;
          widget.onImageSizeSelected(ratio);
        });
      },
    );
  }

  Widget _buildVideoRatioOption(String ratio) {
    return _buildRatioOption(
      ratio: ratio,
      selected: selectedVideoRatio == ratio,
      onTap: () {
        setState(() {
          selectedVideoRatio = ratio;
          widget.onVideoRatioSelected(ratio);
        });
      },
    );
  }

  Widget _buildRatioOption({
    required String ratio,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14;
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
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              selected
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14)
                  : Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.75),
          border: Border.all(color: StarsDesktopTheme.borderColor(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 24,
              height: 24 * (height / width),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color:
                      selected
                          ? Theme.of(context).colorScheme.primary
                          : StarsDesktopTheme.mutedText(context),
                  width: 0.8,
                ),
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ratio,
              style: TextStyle(
                fontSize: fontSize - 2,
                fontWeight: FontWeight.bold,
                color:
                    selected
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
