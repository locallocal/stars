import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/core/widgets/logo.dart';
import 'package:stars/utils/theme.dart';

class ChatListItem extends StatefulWidget {
  final Bot bot;
  final String? name;
  final String lastMessage;
  final String timestamp;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const ChatListItem({
    super.key,
    required this.bot,
    this.name,
    required this.lastMessage,
    required this.timestamp,
    this.isSelected = false,
    required this.onTap,
    this.trailing,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  bool _trailingHovered = false;

  void _setTrailingHovered(bool hovered) {
    if (_trailingHovered == hovered) return;
    setState(() => _trailingHovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;
    final selectedTextColor =
        widget.isSelected
            ? ShadTheme.of(context).colorScheme.primaryForeground
            : null;
    final titleStyle = StarsDesktopThemeSpec.bodyStyle(context)?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: (fontSize - 2).clamp(13, 14),
      color: selectedTextColor,
    );
    final metaStyle = StarsDesktopThemeSpec.metaStyle(context)?.copyWith(
      fontSize: (fontSize - 3).clamp(12, 13),
      color: selectedTextColor,
    );
    final displayName = widget.name ?? widget.bot.name;
    final subtitleParts = <String>[
      if (displayName.trim() != widget.bot.name.trim()) widget.bot.name,
      if (widget.bot.provider.isNotEmpty) widget.bot.provider,
      widget.lastMessage,
    ];
    final subtitle = subtitleParts.join(' · ');
    final timestamp = Text(widget.timestamp, style: metaStyle);
    final timestampWithTooltip =
        ShadTheme.maybeOf(context) == null
            ? Tooltip(message: widget.timestamp, child: timestamp)
            : ShadTooltip(
              builder: (context) => Text(widget.timestamp),
              child: timestamp,
            );

    return DesktopInteractiveListItem(
      selected: widget.isSelected,
      suppressHoverBackground: _trailingHovered,
      onTap: widget.onTap,
      padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 8, 10),
      child: Row(
        children: [
          ShadAvatar(
            widget.bot.avatar.isEmpty ? null : File(widget.bot.avatar),
            size: const Size.square(32),
            backgroundColor:
                widget.bot.avatar.isEmpty
                    ? getFrostedProviderColor(
                      widget.bot.provider,
                      Theme.of(context).colorScheme.primary,
                    )
                    : Theme.of(context).colorScheme.primary,
            placeholder: buildProviderLogo(
              context,
              '',
              widget.bot.provider,
              16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    timestampWithTooltip,
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle?.copyWith(
                    color:
                        widget.isSelected
                            ? ShadTheme.of(
                              context,
                            ).colorScheme.primaryForeground
                            : StarsDesktopThemeSpec.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 6),
            MouseRegion(
              onEnter: (_) => _setTrailingHovered(true),
              onExit: (_) => _setTrailingHovered(false),
              child: widget.trailing!,
            ),
          ],
        ],
      ),
    );
  }
}
