import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/pages/add_bot.dart';
import 'package:bubble/pages/edit_bot.dart';
import 'package:bubble/services/bot_service.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/common/logo.dart';
import 'package:bubble/utils/time.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bubble/pages/common/new_chat.dart';
import 'package:bubble/utils/utils.dart';

class ContactsPage extends StatefulWidget {
  final Function(Bot bot) onBotSelected;
  const ContactsPage({super.key, required this.onBotSelected});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Bot> contacts = [];
  List<Bot> filteredBots = [];
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBots();
  }

  // 加载联系人数据
  Future<void> _loadBots() async {
    setState(() {
      isLoading = true;
    });

    final loadedBots = await BotService.getBots();
    setState(() {
      contacts = loadedBots;
      filteredBots = List.from(contacts);
      isLoading = false;
    });
  }

  // 过滤联系人列表
  void _filterBots(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredBots = List.from(contacts);
      } else {
        filteredBots =
            contacts
                .where(
                  (contact) =>
                      contact.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
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
          S.of(context).Bots,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0, // 防止滚动时背景色变化
        elevation: 0, // 移除阴影
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddBotPage(
                        onBotAdded: (newBot) async {
                          await BotService.addBot(newBot);
                          _loadBots(); // 重新加载联系人列表
                        },
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: TextField(
                        onChanged: _filterBots,
                        decoration: InputDecoration(
                          hintText: '搜索智能体',
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

                  // 智能体列表
                  Expanded(
                    child:
                        filteredBots.isEmpty
                            ? _buildEmptyBotsView()
                            : _buildBotsList(),
                  ),
                ],
              ),
    );
  }

  // 构建智能体列表
  Widget _buildBotsList() {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return ListView.builder(
      itemCount: filteredBots.length,
      itemBuilder: (context, index) {
        final bot = filteredBots[index];
        return Slidable(
          key: Key(bot.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              CustomSlidableAction(
                onPressed: (context) {
                  createNewChat(context, bot);
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
                onPressed: (context) {
                  // 跳转到编辑页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => EditBotPage(
                            bot: bot,
                            onBotUpdated: (updatedBot) async {
                              await BotService.updateBot(updatedBot);
                              _loadBots();
                            },
                            onBotDeleted: () async {
                              await BotService.deleteBot(bot.id);
                              _loadBots();
                            },
                          ),
                    ),
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: Icon(Icons.edit_square, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (context) async {
                  final confirm = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Center(
                          child: Text(
                            S.of(context).confirmDelete,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.fontSize,
                            ),
                          ),
                        ),
                        content: Text(S.of(context).confirmDeleteBot(bot.name)),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              S.of(context).cancel,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              S.of(context).delete,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await BotService.deleteBot(bot.id);
                    setState(() {
                      filteredBots.removeAt(index);
                      contacts.removeWhere((contact) => contact.id == bot.id);
                    });
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: Icon(Icons.delete_rounded, size: 20),
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  bot.avatar.isEmpty
                      ? getFrostedProviderColor(
                        bot.provider,
                        Theme.of(context).colorScheme.primary,
                      )
                      : Theme.of(context).colorScheme.primary,
              radius: 24,
              backgroundImage:
                  bot.avatar.isNotEmpty ? FileImage(File(bot.avatar)) : null,
              child:
                  bot.avatar.isEmpty
                      ? buildProviderLogo(context, '', bot.provider, 24)
                      : null,
            ),
            title: Text(
              bot.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize!,
              ),
            ),
            subtitle: Text(
              '${bot.provider} - ${bot.model}',
              style: TextStyle(
                fontSize: fontSize - 2,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            trailing: Text(
              formatTimestamp(context, bot.createTimestamp),
              style: TextStyle(
                fontSize: fontSize - 2,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            onTap: () {
              if (isDesktopOrTabletPlatform(context)) {
                widget.onBotSelected(bot);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditBotPage(
                        bot: bot,
                        onBotUpdated: (updatedBot) async {
                          await BotService.updateBot(updatedBot);
                          _loadBots();
                        },
                        onBotDeleted: () async {
                          await BotService.deleteBot(bot.id);
                          _loadBots();
                        },
                      ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 显示没有智能体时的UI
  Widget _buildEmptyBotsView() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/profile/no_bots.png',
                width: 256,
                height: 256,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).noBotsAvailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context).clickToCreateBot,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddBotPage(
                            onBotAdded: (newBot) async {
                              await BotService.addBot(newBot);
                              _loadBots(); // 重新加载联系人列表
                            },
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: Text(S.of(context).addBot),
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
}
