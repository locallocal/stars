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
  List<Chat> filteredChatList = []; // 添加过滤后的聊天列表
  List<Bot> bots = [];
  bool isLoading = true;
  String searchQuery = ''; // 添加搜索查询状态

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
        filteredChatList = loadedChats; // 初始化过滤列表
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

  // 过滤聊天列表
  void _filterChats(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredChatList = chatList;
      } else {
        filteredChatList =
            chatList.where((chat) {
              // 获取对应的机器人名称
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

              // 搜索聊天标题、最后消息和机器人名称
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
                  // 搜索框
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: TextField(
                        onChanged: _filterChats,
                        decoration: InputDecoration(
                          hintText: '搜索聊天记录',
                          fillColor: Theme.of(context).colorScheme.secondary,
                          focusColor: Theme.of(context).colorScheme.secondary,
                          hoverColor: Theme.of(context).colorScheme.secondary,
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        filteredChatList.isEmpty
                            ? Center(
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
