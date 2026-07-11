import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/bot_service.dart';
import 'package:bubble/services/chat_service.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/chats/new_chat_dialog.dart';
import 'package:bubble/pages/chats/chat_list_builder.dart';
import 'package:bubble/utils/theme.dart';
import 'package:bubble/utils/utils.dart';

class ChatListPage extends StatefulWidget {
  final String? selectedChatId;
  final Function(String chatId, Bot bot) onChatSelected;
  const ChatListPage({
    super.key,
    this.selectedChatId,
    required this.onChatSelected,
  });

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
  late StreamSubscription _botListSubscription;

  @override
  void initState() {
    super.initState();
    _loadChatList();

    // 添加监听器，当聊天列表变化时重新加载
    _chatListSubscription = ChatService.chatListChanged.listen((_) {
      _loadChatList();
    });
    _botListSubscription = BotService.botListChanged.listen((_) {
      _loadChatList();
    });
  }

  @override
  void dispose() {
    _chatListSubscription.cancel();
    _botListSubscription.cancel();
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
    final isDesktop = isDesktopOrTabletPlatform(context);
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    final body =
        isLoading ? _buildLoadingState() : _buildListSection(isDesktop);

    if (!isDesktop) {
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
              onPressed: _openNewChatDialog,
            ),
          ],
        ),
        body: body,
      );
    }

    return DesktopListPanel(
      title: S.of(context).chats,
      description: '查看最近会话，并在右侧继续当前聊天。',
      searchHintText: '搜索聊天记录',
      onSearchChanged: _filterChats,
      action: ElevatedButton.icon(
        onPressed: _openNewChatDialog,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: Text(S.of(context).newChat),
        style: DesktopThemeTokens.primaryButtonStyle(context),
      ),
      child: body,
    );
  }

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildListSection(bool isDesktop) {
    if (filteredChatList.isEmpty) {
      return _buildEmptyChatsView(isDesktop);
    }

    return ChatListBuilder(
      chatList: filteredChatList,
      bots: bots,
      selectedChatId: widget.selectedChatId,
      onChatDeleted: (String id) {
        if (id.isNotEmpty) {
          setState(() {
            chatList.removeWhere((chat) => chat.id == id);
            filteredChatList.removeWhere((chat) => chat.id == id);
          });
        } else {
          _loadChatList();
        }
      },
      onChatSelected: widget.onChatSelected,
    );
  }

  Widget _buildEmptyChatsView(bool isDesktop) {
    if (isDesktop) {
      return DesktopEmptyStateCard(
        icon:
            searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.chat_bubble_outline_rounded,
        imageAsset:
            searchQuery.isEmpty ? 'assets/images/profile/no_chats.png' : null,
        title: searchQuery.isNotEmpty ? '没有找到匹配的聊天' : S.of(context).noChats,
        description:
            searchQuery.isNotEmpty
                ? '试试更换关键词，或直接创建一个新聊天。'
                : S.of(context).clickToStartChat,
        supportingText:
            searchQuery.isNotEmpty
                ? '搜索会同时匹配消息内容和智能体名称。'
                : '新建聊天后，右侧工作区会直接打开对应会话。',
        action: ElevatedButton.icon(
          onPressed: _openNewChatDialog,
          icon: const Icon(Icons.add_circle_outline),
          label: Text(S.of(context).newChat),
          style: DesktopThemeTokens.primaryButtonStyle(context),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (searchQuery.isNotEmpty)
                Text(
                  '没有找到匹配的聊天',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                )
              else
                Image.asset(
                  'assets/images/profile/no_chats.png',
                  width: 256,
                  height: 256,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text(
                S.of(context).noChats,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context).clickToStartChat,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openNewChatDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(S.of(context).newChat),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNewChatDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => NewChatDialog(
            onChatCreated: (chatId, bot) {
              _loadChatList();
              widget.onChatSelected(chatId, bot);
            },
          ),
    );
  }
}
