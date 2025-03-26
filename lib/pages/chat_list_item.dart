import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/pages/common/logo.dart';
import 'package:bubble/model/model.dart';

class ChatListItem extends StatelessWidget {
  final Bot bot;
  final String lastMessage;
  final String timestamp;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.bot,
    required this.lastMessage,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // 头像
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  bot.avatar.isEmpty
                      ? getFrostedProviderColor(
                        bot.provider,
                        Theme.of(context).colorScheme.primary,
                      )
                      : Theme.of(context).colorScheme.primary,
              backgroundImage:
                  bot.avatar.isNotEmpty ? FileImage(File(bot.avatar)) : null,
              child:
                  bot.avatar.isEmpty
                      ? buildProviderLogo(context, '', bot.provider, 24)
                      : null,
            ),
            const SizedBox(width: 16),
            // 聊天信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bot.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                      // 修复这里的 Tooltip，确保 message 不为 null
                      Tooltip(
                        message: timestamp, // 添加空字符串作为默认值
                        child: Text(
                          timestamp,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: fontSize - 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
