import 'dart:io';
import 'package:flutter/material.dart';

class ChatListItem extends StatelessWidget {
  final String avatar;
  final String nickname;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isStarred;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChatListItem({
    super.key,
    required this.avatar,
    required this.nickname,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
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
                    radius: 25,
                    backgroundColor: Colors.blue,
                    backgroundImage:
                        avatar.isNotEmpty ? FileImage(File(avatar)) : null,
                    child:
                        avatar.isEmpty
                            ? const Icon(Icons.smart_toy, color: Colors.white)
                            : null,
                  ),
                ),
                if (isStarred)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.orange,
                      ),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timestamp,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
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
