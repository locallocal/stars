import 'dart:io';
import 'package:flutter/material.dart';

class ChatListItem extends StatelessWidget {
  final String avatar;
  final String nickname;
  final String lastMessage;
  final String timestamp;
  final bool isStarred;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChatListItem({
    super.key,
    required this.avatar,
    required this.nickname,
    required this.lastMessage,
    required this.timestamp,
    this.isStarred = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 头像区域
            Stack(
              children: [
                Tooltip(
                  message: '点击查看资料',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        avatar.isNotEmpty ? FileImage(File(avatar)) : null,
                    child: avatar.isEmpty ? const Icon(Icons.smart_toy) : null,
                  ),
                ),
                if (isStarred)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: const Icon(Icons.star, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // 聊天信息区域
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
                          fontSize:
                              Theme.of(context).textTheme.bodyLarge?.fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(timestamp),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
