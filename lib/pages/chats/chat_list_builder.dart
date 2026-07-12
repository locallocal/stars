import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/pages/chat.dart';
import 'package:bubble/pages/chats/chat_item.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/utils/utils.dart';
import 'package:bubble/utils/time.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ChatListBuilder extends StatelessWidget {
  final List<Chat> chatList;
  final List<Bot> bots;
  final String? selectedChatId;
  final Function onChatDeleted;
  final Function(String chatId, Bot bot) onChatSelected;

  const ChatListBuilder({
    super.key,
    required this.chatList,
    required this.bots,
    this.selectedChatId,
    required this.onChatDeleted,
    required this.onChatSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDesktopOrTabletPlatform(context);
    return ListView.separated(
      padding: EdgeInsets.only(bottom: isDesktop ? 8 : 0),
      itemCount: chatList.length,
      separatorBuilder:
          (context, index) => SizedBox(height: isDesktop ? 8 : 0),
      itemBuilder: (context, index) {
        final chat = chatList[index];
        final bot = bots.firstWhere(
          (bot) => bot.id == chat.botId,
          orElse:
              () => Bot(
                id: '',
                name: 'Unknown Bot',
                avatar: '',
                provider: '',
                baseURL: '',
                apiKey: '',
                apiType: '',
                systemPrompt: '',
                model: '',
                createTimestamp: DateTime.now(),
                modifyTimestamp: DateTime.now(),
              ),
        );
        return Slidable(
          key: Key(chat.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              CustomSlidableAction(
                onPressed: (context) {
                  if (isDesktopOrTabletPlatform(context)) {
                    onChatSelected(chat.id, bot);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(id: chat.id, bot: bot),
                    ),
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Icon(Icons.chat_bubble_rounded, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (context) {},
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: Icon(Icons.edit_square, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (context) async {
                  final confirm = await showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Center(
                            child: Text(
                              S.of(context).deleteChat,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.fontSize,
                              ),
                            ),
                          ),
                          content: Text(
                            S.of(context).confirmDeleteChat(bot.name),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                S.of(context).cancel,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                S.of(context).delete,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    // 删除聊天记录
                    await ChatService.deleteChat(chat.id);
                    // 删除聊天目录
                    await deleteChatDirectory(chat.id);
                    // 通知父组件更新
                    onChatDeleted(chat.id);
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: Icon(Icons.delete_rounded, size: 20),
              ),
            ],
          ),
          child: ChatListItem(
            bot: bot,
            isSelected: isDesktop && selectedChatId == chat.id,
            lastMessage:
                chat.lastMessage.isEmpty
                    ? S.of(context).startChatting
                    : chat.lastMessage.length > 25
                    ? '${chat.lastMessage.substring(0, 25)}...'
                    : chat.lastMessage,
            timestamp: formatTimestamp(context, chat.lastMessageTimestamp),
            onTap: () {
              // 恢复平台判断
              if (isDesktopOrTabletPlatform(context)) {
                onChatSelected(chat.id, bot);
                return;
              }

              // 在移动设备上，执行导航
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(id: chat.id, bot: bot),
                ),
              ).then((_) {
                // 刷新聊天列表
                onChatDeleted('');
              });
            },
          ),
        );
      },
    );
  }
}
