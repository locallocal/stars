import 'dart:async';
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
  List<Chat> filteredChatList = [];
  List<Bot> bots = [];
  bool isLoading = true;
  String searchQuery = '';
  late StreamSubscription _chatListSubscription;

  @override
  void initState() {
    super.initState();
    _loadChatList();

    // 添加监听器，当聊天列表变化时重新加载
    _chatListSubscription = ChatService.chatListChanged.listen((_) {
      _loadChatList();
    });
  }

  @override
  void dispose() {
    _chatListSubscription.cancel();
    super.dispose();
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
        filteredChatList = loadedChats;
        bots = loadedBots;
        isLoading = false;
      });
    }
  }

  void _filterChats(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredChatList = chatList;
      } else {
        filteredChatList =
            chatList.where((chat) {
              final bot = bots.firstWhere(
                (bot) => bot.id == chat.botId,
                orElse:
                    () => Bot(
                      id: '',
                      name: '',
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

              return chat.lastMessage.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  bot.name.toLowerCase().contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          S.of(context).chats,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: () async {
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
                  // 搜索框
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: TextField(
                        onChanged: _filterChats,
                        decoration: InputDecoration(
                          hintText: '搜索聊天记录',
                          hintStyle: TextStyle(
                            fontSize: fontSize,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          prefixIcon: const Icon(Icons.search),
                          prefixIconColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 0,
                              style: BorderStyle.none,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(24.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        filteredChatList.isEmpty
                            ? Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (searchQuery.isNotEmpty)
                                        Text(
                                          S.of(context).noModelsRetrieved,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                        )
                                      else
                                        Image.asset(
                                          'assets/images/profile/no_chats.png',
                                          width: 384,
                                          height: 384,
                                          fit: BoxFit.cover,
                                        ),

                                      const SizedBox(height: 16),
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
                                ),
                              ),
                            )
                            : ChatListBuilder(
                              chatList: filteredChatList, // 使用过滤后的列表
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
