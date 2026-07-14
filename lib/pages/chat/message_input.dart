import 'package:stars/generated/l10n.dart';
import 'package:stars/model/model.dart';
import 'package:stars/services/providers/providers.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (selectedImageRatio.isNotEmpty) {
        widget.onImageSizeSelected(selectedImageRatio);
      }
      if (selectedVideoRatio.isNotEmpty) {
        widget.onVideoRatioSelected(selectedVideoRatio);
      }
    });
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

  bool get _isComposing {
    final composing = widget.controller.value.composing;
    return composing.isValid && !composing.isCollapsed;
  }

  KeyEventResult _handleComposerKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.numpadEnter)) {
      return KeyEventResult.ignored;
    }

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed ||
        keyboard.isAltPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        _isComposing) {
      return KeyEventResult.ignored;
    }

    if (!widget.waitingBotMessage && _canSubmit) {
      widget.onSend();
    }
    return KeyEventResult.handled;
  }

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
            isDesktop ? 12 : 8,
            isDesktop ? 8 : 0,
            isDesktop ? 12 : 8,
            isDesktop ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color:
                isDesktop
                    ? StarsDesktopTheme.panelBackground(context)
                    : Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _hasFocus && isDesktop
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.72)
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isDesktop ? 96 : double.infinity,
                ),
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onKeyEvent: isDesktop ? _handleComposerKeyEvent : null,
                  child:
                      isDesktop
                          ? ShadInput(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            placeholder: Text(S.of(context).messageHint),
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            minLines: 1,
                            maxLines: null,
                            constraints: const BoxConstraints(
                              minHeight: 44,
                              maxHeight: 96,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            style: TextStyle(height: 1.45, fontSize: fontSize),
                          )
                          : TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) {
                              if (!_isComposing && _canSubmit) {
                                widget.onSend();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: S.of(context).messageHint,
                              hintStyle: TextStyle(
                                fontSize: fontSize,
                                color: StarsDesktopTheme.subtleText(context),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 6,
                            minLines: 3,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(fontSize: fontSize),
                          ),
                ),
              ),
              SizedBox(height: isDesktop ? 6 : 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, child) {
                  return _buildBottomToolbar(context, fontSize, isDesktop);
                },
              ),
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
                  ) &&
                  (widget.provider.getSupportImageStyles().isNotEmpty ||
                      widget.provider.getSupportedImageSizes().isNotEmpty))
                _buildImageOptionsMenu(context),
              if (widget.provider.getOutputModalites().contains(
                    OutputModality.video,
                  ) &&
                  widget.provider.getSupportVideoRatios().isNotEmpty)
                _buildVideoOptionsMenu(context),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_supportsAttachments) _buildAttachmentMenu(context),
            const SizedBox(width: 10),
            _buildPrimaryActionButton(context, isDesktop),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentMenu(BuildContext context) {
    final menuChildren = <Widget>[
      if (widget.provider.getInputModalites().contains(InputModality.image))
        MenuItemButton(
          leadingIcon: const Icon(Icons.photo_camera_outlined, size: 18),
          onPressed: widget.onCameraPressed,
          child: Text(S.of(context).takePhoto),
        ),
      if (widget.provider.getInputModalites().contains(InputModality.image))
        MenuItemButton(
          leadingIcon: const Icon(Icons.photo_library_outlined, size: 18),
          onPressed: widget.onGalleryPressed,
          child: Text(S.of(context).chooseFromGallery),
        ),
      if (widget.provider.getInputModalites().contains(InputModality.file))
        MenuItemButton(
          leadingIcon: const Icon(Icons.upload_file_outlined, size: 18),
          onPressed: widget.onFilePressed,
          child: Text(S.of(context).uploadFile),
        ),
    ];

    return MenuAnchor(
      menuChildren: menuChildren,
      builder: (context, controller, child) {
        return _buildCircleActionButton(
          context,
          icon: const Icon(Icons.add_rounded, size: 18),
          tooltip: S.of(context).uploadFile,
          active: controller.isOpen || widget.hasPendingAttachments,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }

  Widget _buildImageOptionsMenu(BuildContext context) {
    final styles = widget.provider.getSupportImageStyles();
    final sizes = widget.provider.getSupportedImageSizes();

    return MenuAnchor(
      menuChildren: [
        if (styles.isNotEmpty)
          SubmenuButton(
            leadingIcon: const Icon(Icons.brush_outlined, size: 18),
            menuChildren:
                styles
                    .map(
                      (style) => MenuItemButton(
                        leadingIcon:
                            selectedImageStyle == style
                                ? const Icon(Icons.check_rounded, size: 18)
                                : const SizedBox(width: 18),
                        onPressed: () {
                          setState(() {
                            selectedImageStyle =
                                selectedImageStyle == style ? '' : style;
                          });
                          widget.onImageStyleSelected(selectedImageStyle);
                        },
                        child: Text(style),
                      ),
                    )
                    .toList(),
            child: Text(S.of(context).imageStyle),
          ),
        if (sizes.isNotEmpty)
          SubmenuButton(
            leadingIcon: const Icon(Icons.aspect_ratio_outlined, size: 18),
            menuChildren:
                sizes
                    .map(
                      (size) => MenuItemButton(
                        leadingIcon:
                            selectedImageRatio == size
                                ? const Icon(Icons.check_rounded, size: 18)
                                : const SizedBox(width: 18),
                        onPressed: () {
                          setState(() {
                            selectedImageRatio = size;
                          });
                          widget.onImageSizeSelected(size);
                        },
                        child: Text(size),
                      ),
                    )
                    .toList(),
            child: Text(S.of(context).imageSize),
          ),
      ],
      builder: (context, controller, child) {
        return _buildActionChip(
          context,
          icon: Icons.image_outlined,
          label:
              selectedImageStyle.isEmpty
                  ? selectedImageRatio
                  : '$selectedImageStyle · $selectedImageRatio',
          active: controller.isOpen,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }

  Widget _buildVideoOptionsMenu(BuildContext context) {
    final ratios = widget.provider.getSupportVideoRatios();

    return MenuAnchor(
      menuChildren:
          ratios
              .map(
                (ratio) => MenuItemButton(
                  leadingIcon:
                      selectedVideoRatio == ratio
                          ? const Icon(Icons.check_rounded, size: 18)
                          : const SizedBox(width: 18),
                  onPressed: () {
                    setState(() {
                      selectedVideoRatio = ratio;
                    });
                    widget.onVideoRatioSelected(ratio);
                  },
                  child: Text(ratio),
                ),
              )
              .toList(),
      builder: (context, controller, child) {
        return _buildActionChip(
          context,
          icon: Icons.video_camera_back_outlined,
          label: selectedVideoRatio,
          active: controller.isOpen,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
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
            widget.waitingBotMessage ? Icons.stop_rounded : Icons.send_rounded,
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

    final label =
        widget.waitingBotMessage ? S.of(context).stop : S.of(context).send;
    final icon = Icon(
      widget.waitingBotMessage ? Icons.stop_rounded : Icons.send_rounded,
      size: 17,
    );
    if (widget.waitingBotMessage) {
      return ShadButton.destructive(
        size: ShadButtonSize.sm,
        width: 96,
        height: 36,
        onPressed: onPressed,
        leading: icon,
        child: Text(label),
      );
    }
    return ShadButton(
      size: ShadButtonSize.sm,
      width: 96,
      height: 36,
      enabled: enabled,
      onPressed: onPressed,
      leading: icon,
      child: Text(label),
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
    if (_isDesktop || isDesktopOrTabletPlatform(context)) {
      final iconWidget = Icon(icon, size: 16);
      return active
          ? ShadButton.secondary(
            size: ShadButtonSize.sm,
            leading: iconWidget,
            onPressed: onTap,
            child: Text(label),
          )
          : ShadButton.outline(
            size: ShadButtonSize.sm,
            leading: iconWidget,
            onPressed: onTap,
            child: Text(label),
          );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color:
              active
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12)
                  : StarsDesktopTheme.elevatedSurface(context),
          borderRadius: BorderRadius.circular(8),
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
    if (_isDesktop || isDesktopOrTabletPlatform(context)) {
      return ShadCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: ShadTheme.of(context).colorScheme.mutedForeground,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ShadTheme.of(context).textTheme.small,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: StarsDesktopTheme.elevatedSurface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StarsDesktopTheme.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: StarsDesktopTheme.mutedText(context)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
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
    if (_isDesktop || isDesktopOrTabletPlatform(context)) {
      final button =
          active
              ? ShadIconButton.secondary(
                icon: icon,
                iconSize: 18,
                width: 34,
                height: 34,
                onPressed: onPressed,
              )
              : ShadIconButton.outline(
                icon: icon,
                iconSize: 18,
                width: 34,
                height: 34,
                onPressed: onPressed,
              );
      return Semantics(
        label: tooltip,
        child: ShadTooltip(builder: (context) => Text(tooltip), child: button),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            active
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
                : StarsDesktopTheme.elevatedSurface(context),
        borderRadius: BorderRadius.circular(8),
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
        style: IconButton.styleFrom(
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        color:
            active
                ? Theme.of(context).colorScheme.primary
                : StarsDesktopTheme.mutedText(context),
        icon: icon,
      ),
    );
  }

  bool get _supportsAttachments =>
      widget.provider.getInputModalites().contains(InputModality.image) ||
      widget.provider.getInputModalites().contains(InputModality.file);
}
