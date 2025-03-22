import 'dart:io';
import 'package:flutter/material.dart';

class ChatListItem extends StatelessWidget {
  final String avatar;
  final String nickname;
  final String lastMessage;
  final String timestamp;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.avatar,
    required this.nickname,
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: avatar.isNotEmpty ? FileImage(File(avatar)) : null,
              child: avatar.isEmpty ? const Icon(Icons.smart_toy) : null,
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
                        nickname,
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
