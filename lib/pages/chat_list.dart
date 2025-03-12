import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/pages/chat.dart';
import 'package:bubble/pages/chat_list_item.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/bot_service.dart';
import 'package:bubble/services/chat_service.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  // 聊天列表数据
  List<Chat> chatList = [];
  List<Bot> bots = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatList();
  }

  // 加载聊天列表
  Future<void> _loadChatList() async {
    setState(() {
      isLoading = true;
    });
    
    final loadedChats = await ChatService.getChatList();
    final loadedBots = await BotService.getBots();
    setState(() {
      chatList = loadedChats;
      bots = loadedBots;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        title: const Text('对话'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // 获取智能体列表
              if (!mounted) return;
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Center(
                    child: Text(
                      '选择智能体',
                      style: TextStyle(
                        fontSize: 16,
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
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('没有的智能体'));
                        }
                        
                        final bots = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: bots.length,
                          itemBuilder: (context, index) {
                            final bot = bots[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                backgroundImage: bot.avatar.isNotEmpty 
                                    ? FileImage(File(bot.avatar)) 
                                    : null,
                                child: bot.avatar.isEmpty
                                    ? Text(
                                        bot.name.isNotEmpty ? bot.name.substring(0, 1) : '?',
                                        style: const TextStyle(color: Colors.white),
                                      )
                                    : null,
                              ),
                              title: Text(bot.name),
                              subtitle: Text('智能体 (${bot.provider}-${bot.model})'),
                              onTap: () async {
                                Navigator.pop(context); // 关闭对话框
                                
                                // 添加到聊天列表
                                final newChat = Chat(
                                  botId: bot.id,
                                  lastMessage: '',
                                  lastMessageTimestamp: DateTime.now(),
                                  createTimestamp: DateTime.now(),
                                  modifyTimestamp: DateTime.now(),
                                );
                                
                                await ChatService.addOrUpdateChat(newChat);
                                
                                // 导航到聊天页面
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(bot: bot),
                                  ),
                                ).then((_) {
                                  // 刷新聊天列表
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 搜索框
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜索聊天记录',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                // 聊天列表
                Expanded(
                  child: chatList.isEmpty
                      ? const Center(
                          child: Text('还没有聊天记录\n点击右上角 + 开始聊天',
                              textAlign: TextAlign.center),
                        )
                      : ListView.builder(
                          itemCount: chatList.length,
                          itemBuilder: (context, index) {
                            final chat = chatList[index];
                            // 获取bot信息，确保方法返回非空值
                            final bot = bots.where((bot) {
                              if (bot.id == chat.botId) {
                                return true;
                              }
                              return false;
                            }).first;
                            
                            return Dismissible(
                              // 使用chat.botId作为key，而不是bot.botId
                              key: Key(chat.botId),
                              background: Container(
                                color: Theme.of(context).colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('删除聊天'),
                                    // 使用bot.name替代chat.botId显示更友好的名称
                                    content: Text('确定要删除与 "${bot.name}" 的聊天吗？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('取消'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('删除'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) async {
                                await ChatService.deleteChat(chat.botId);
                                setState(() {
                                  chatList.removeAt(index);
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      // 使用bot.name替代chat.botId
                                      content: Text('已删除与 ${bot.name} 的聊天'),
                                      action: SnackBarAction(
                                        label: '撤销',
                                        onPressed: () async {
                                          await ChatService.addOrUpdateChat(chat);
                                          _loadChatList();
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: ChatListItem(
                                // 使用bot.name替代chat.name
                                nickname: bot.name,
                                avatar: bot.avatar,
                                lastMessage: chat.lastMessage.isEmpty
                                    ? '开始聊天吧'
                                    : chat.lastMessage,
                                // 使用chat.lastMessageTimestamp替代chat.timestamp
                                timestamp: _formatTimestamp(chat.lastMessageTimestamp),
                                // 确保Chat类中有unreadCount属性，如果没有则使用0
                                unreadCount:  0,
                                isStarred: false,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          // 传递bot而不是contact
                                          ChatPage(bot: bot),
                                    ),
                                  ).then((_) {
                                    // 聊天页面返回后刷新聊天列表
                                    _loadChatList();
                                  });
                                },
                                onLongPress: () {
                                  // 长按删除聊天
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('删除聊天'),
                                      // 使用bot.name
                                      content: Text('确定要删除与 "${bot.name}" 的聊天吗？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            // 使用chat.botId
                                            await ChatService.deleteChat(chat.botId);
                                            _loadChatList();
                                          },
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                                  );
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
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}