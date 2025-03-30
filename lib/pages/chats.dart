import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/bot_service.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/chats/new_chat_dialog.dart';
import 'package:bubble/pages/chats/chat_list_builder.dart';

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
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: () async {
              // 获取智能体列表
              if (!mounted) return;

              showDialog(
                context: context,
                builder:
                    (context) => NewChatDialog(onChatCreated: _loadChatList),
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
                            : ChatListBuilder(
                              chatList: chatList,
                              bots: bots,
                              onChatDeleted: (String id) {
                                if (id.isNotEmpty) {
                                  setState(() {
                                    chatList.removeWhere(
                                      (chat) => chat.id == id,
                                    );
                                  });
                                } else {
                                  _loadChatList();
                                }
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
