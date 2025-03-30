import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/pages/chat.dart';
import 'package:bubble/pages/chats/chat_item.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/utils/utils.dart';
import 'package:bubble/utils/time.dart';

class ChatListBuilder extends StatelessWidget {
  final List<Chat> chatList;
  final List<Bot> bots;
  final Function onChatDeleted;

  const ChatListBuilder({
    super.key,
    required this.chatList,
    required this.bots,
    required this.onChatDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: chatList.length,
      itemBuilder: (context, index) {
        final chat = chatList[index];
        final bot =
            bots.where((bot) {
              if (bot.id == chat.botId) {
                return true;
              }
              return false;
            }).first;

        return Dismissible(
          key: Key(chat.id),
          background: Container(
            color: Theme.of(context).colorScheme.primary,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Center(
                      child: Text(
                        S.of(context).deleteChat,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:
                              Theme.of(context).textTheme.bodyLarge?.fontSize,
                        ),
                      ),
                    ),
                    content: Text(S.of(context).confirmDeleteChat(bot.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          S.of(context).cancel,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          S.of(context).delete,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
            );
          },
          onDismissed: (direction) async {
            // 删除聊天记录
            await ChatService.deleteChat(chat.id);

            // 删除聊天目录
            await deleteChatDirectory(chat.id);

            // 通知父组件更新
            onChatDeleted(chat.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).chatDeleted(bot.name))),
              );
            }
          },
          child: ChatListItem(
            bot: bot,
            lastMessage:
                chat.lastMessage.isEmpty
                    ? S.of(context).startChatting
                    : chat.lastMessage.length > 25
                    ? '${chat.lastMessage.substring(0, 25)}...'
                    : chat.lastMessage,
            timestamp: formatTimestamp(context, chat.lastMessageTimestamp),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(id: chat.id, bot: bot),
                ),
              ).then((_) {
                // 刷新聊天列表
                onChatDeleted(''); // 使用-1表示不删除任何项，只刷新
              });
            },
          ),
        );
      },
    );
  }
}
