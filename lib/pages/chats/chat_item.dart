import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/pages/common/logo.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/utils/theme.dart';

class ChatListItem extends StatefulWidget {
  final Bot bot;
  final String lastMessage;
  final String timestamp;
  final bool isSelected;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.bot,
    required this.lastMessage,
    required this.timestamp,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;
    final titleStyle = DesktopThemeTokens.bodyStyle(
      context,
    )?.copyWith(fontWeight: FontWeight.w700, fontSize: fontSize);
    final metaStyle = DesktopThemeTokens.metaStyle(
      context,
    )?.copyWith(fontSize: fontSize - 2);
    final subtitle =
        widget.bot.provider.isEmpty
            ? widget.lastMessage
            : '${widget.bot.provider} · ${widget.lastMessage}';

    return DesktopInteractiveListItem(
      selected: widget.isSelected,
      onTap: widget.onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                widget.bot.avatar.isEmpty
                    ? getFrostedProviderColor(
                      widget.bot.provider,
                      Theme.of(context).colorScheme.primary,
                    )
                    : Theme.of(context).colorScheme.primary,
            backgroundImage:
                widget.bot.avatar.isNotEmpty
                    ? FileImage(File(widget.bot.avatar))
                    : null,
            child:
                widget.bot.avatar.isEmpty
                    ? buildProviderLogo(context, '', widget.bot.provider, 20)
                    : null,
          ),
          const SizedBox(width: 14),
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
                    Tooltip(
                      message: widget.timestamp,
                      child: Text(widget.timestamp, style: metaStyle),
                    ),
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
        ],
      ),
    );
  }
}
