import 'package:flutter/material.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/chat.dart';
import 'package:stars/pages/chats/chat_item.dart';
import 'package:stars/services/chat_service.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/utils/utils.dart';
import 'package:stars/utils/time.dart';
import 'package:stars/utils/theme.dart';
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
      separatorBuilder: (context, index) => SizedBox(height: isDesktop ? 8 : 0),
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
        void openChat({bool refreshAfterClose = false}) {
          if (isDesktop) {
            onChatSelected(chat.id, bot);
            return;
          }

          final navigation = Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(id: chat.id, bot: bot),
            ),
          );
          if (refreshAfterClose) {
            navigation.then((_) => onChatDeleted(''));
          }
        }

        Future<void> deleteChat() async {
          final confirm = await showDialog<bool>(
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
                      child: Text(S.of(context).cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        S.of(context).delete,
                        style: TextStyle(
                          color: DesktopThemeTokens.error(context),
                        ),
                      ),
                    ),
                  ],
                ),
          );

          if (confirm != true || !context.mounted) return;
          await ChatService.deleteChat(chat.id);
          await deleteChatDirectory(chat.id);
          onChatDeleted(chat.id);
        }

        ChatListItem buildListItem({Widget? trailing}) {
          return ChatListItem(
            bot: bot,
            isSelected: isDesktop && selectedChatId == chat.id,
            lastMessage:
                chat.lastMessage.isEmpty
                    ? S.of(context).startChatting
                    : chat.lastMessage.length > 25
                    ? '${chat.lastMessage.substring(0, 25)}...'
                    : chat.lastMessage,
            timestamp: formatTimestamp(context, chat.lastMessageTimestamp),
            trailing: trailing,
            onTap: () => openChat(refreshAfterClose: !isDesktop),
          );
        }

        if (isDesktop) {
          return MenuAnchor(
            key: ValueKey('chat-menu-${chat.id}'),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 17,
                ),
                onPressed: openChat,
                child: Text(S.of(context).startChatting),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.delete_outline_rounded, size: 17),
                onPressed: deleteChat,
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(
                    DesktopThemeTokens.error(context),
                  ),
                ),
                child: Text(S.of(context).delete),
              ),
            ],
            builder: (context, controller, child) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onSecondaryTapDown: (details) {
                  if (controller.isOpen) controller.close();
                  controller.open(position: details.localPosition);
                },
                child: buildListItem(
                  trailing: IconButton(
                    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                    onPressed:
                        controller.isOpen ? controller.close : controller.open,
                    icon: const Icon(Icons.more_horiz_rounded, size: 18),
                  ),
                ),
              );
            },
          );
        }

        return Slidable(
          key: Key(chat.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              CustomSlidableAction(
                onPressed: (_) => openChat(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_rounded, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (_) {},
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: const Icon(Icons.edit_square, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (_) => deleteChat(),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: const Icon(Icons.delete_rounded, size: 20),
              ),
            ],
          ),
          child: buildListItem(),
        );
      },
    );
  }
}
