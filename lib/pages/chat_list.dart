import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/pages/chat.dart';
import 'package:bubble/pages/chat_list_item.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/bot_service.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/generated/l10n.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Chat> chatList = [];
  List<Bot> bots = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatList();
  }

  Future<void> _loadChatList() async {
    setState(() {
      isLoading = true;
    });

    final loadedChats = await ChatService.getChatList();
    final loadedBots = await BotService.getBots();
    if (mounted) {
      setState(() {
        chatList = loadedChats;
        bots = loadedBots;
        isLoading = false;
      });
    }
  }

  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          S.of(context).chats,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0, // 防止滚动时背景色变化
        elevation: 0, // 移除阴影
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () async {
              // 获取智能体列表
              if (!mounted) return;

              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Center(
                        child: Text(
                          S.of(context).newChat,
                          style: TextStyle(
                            fontSize:
                                Theme.of(context).textTheme.bodyLarge?.fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 300,
                        child: FutureBuilder<List<Bot>>(
                          future: BotService.getBots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(S.of(context).noBotsAvailable),
                              );
                            }

                            final bots = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: bots.length,
                              itemBuilder: (context, index) {
                                final bot = bots[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    backgroundImage:
                                        bot.avatar.isNotEmpty
                                            ? FileImage(File(bot.avatar))
                                            : null,
                                    child:
                                        bot.avatar.isEmpty
                                            ? const Icon(Icons.smart_toy)
                                            : null,
                                  ),
                                  title: Text(
                                    bot.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${bot.provider}-${bot.model}',
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);

                                    final id =
                                        'chat_${DateTime.now().millisecondsSinceEpoch}';
                                    final newChat = Chat(
                                      id: id,
                                      botId: bot.id,
                                      lastMessage: '',
                                      lastMessageTimestamp: DateTime.now(),
                                      createTimestamp: DateTime.now(),
                                      modifyTimestamp: DateTime.now(),
                                    );
                                    await ChatService.addOrUpdateChat(newChat);
                                    if (!mounted) return;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                ChatPage(id: id, bot: bot),
                                      ),
                                    ).then((_) {
                                      _loadChatList();
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
              );
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 聊天列表
                  Expanded(
                    child:
                        chatList.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    S.of(context).noChats,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    S.of(context).clickToStartChat,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                                                      Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.fontSize,
                                                ),
                                              ),
                                            ),
                                            content: Text(
                                              S
                                                  .of(context)
                                                  .confirmDeleteChat(bot.name),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: Text(
                                                  S.of(context).cancel,
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: Text(
                                                  S.of(context).delete,
                                                  style: TextStyle(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                  onDismissed: (direction) async {
                                    setState(() {
                                      chatList.removeAt(index);
                                    });
                                    await ChatService.deleteChat(chat.id);

                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            S.of(context).chatDeleted(bot.name),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: ChatListItem(
                                    nickname: bot.name,
                                    avatar: bot.avatar,
                                    lastMessage:
                                        chat.lastMessage.isEmpty
                                            ? S.of(context).startChatting
                                            : chat.lastMessage.length > 25
                                            ? '${chat.lastMessage.substring(0, 25)}...'
                                            : chat.lastMessage,
                                    timestamp: _formatTimestamp(
                                      chat.lastMessageTimestamp,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ChatPage(
                                                id: chat.id,
                                                bot: bot,
                                              ),
                                        ),
                                      ).then((_) {
                                        _loadChatList();
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  // 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.month}-${timestamp.day}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return S.of(context).minutesAgo(difference.inMinutes);
    } else {
      return S.of(context).justNow;
    }
  }
}
