import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/core/widgets/logo.dart';
import 'package:stars/utils/theme.dart';

class ChatListItem extends StatefulWidget {
  final Bot bot;
  final String lastMessage;
  final String timestamp;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const ChatListItem({
    super.key,
    required this.bot,
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
  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;
    final titleStyle = DesktopThemeTokens.bodyStyle(context)?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: (fontSize - 2).clamp(13, 14),
    );
    final metaStyle = DesktopThemeTokens.metaStyle(
      context,
    )?.copyWith(fontSize: (fontSize - 3).clamp(12, 13));
    final subtitle =
        widget.bot.provider.isEmpty
            ? widget.lastMessage
            : '${widget.bot.provider} · ${widget.lastMessage}';
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
                        widget.bot.name,
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
                    color: DesktopThemeTokens.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 6),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
