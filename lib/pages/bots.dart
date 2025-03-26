import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/pages/add_bot.dart';
import 'package:bubble/pages/edit_bot.dart';
import 'package:bubble/services/bot_service.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/common/logo.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          S.of(context).Bots,
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
                  // 搜索框
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: TextField(
                        onChanged: _filterBots,
                        decoration: InputDecoration(
                          hintText: S.of(context).selectBot,
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

                  // 智能体列表
                  Expanded(
                    child:
                        filteredBots.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    S.of(context).noBotsAvailable,
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
                                    S.of(context).clickToCreateBot,
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
                              itemCount: filteredBots.length,
                              itemBuilder: (context, index) {
                                final bot = filteredBots[index];
                                return Dismissible(
                                  key: Key(bot.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    child: const Icon(Icons.delete),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Center(
                                            child: Text(
                                              S.of(context).confirmDelete,
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
                                                .confirmDeleteBot(bot.name),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
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
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(true),
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
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (direction) async {
                                    await BotService.deleteBot(bot.id);
                                    setState(() {
                                      filteredBots.removeAt(index);
                                      contacts.removeWhere(
                                        (contact) => contact.id == bot.id,
                                      );
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            S.of(context).botDeleted(bot.name),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          bot.avatar.isEmpty
                                              ? getFrostedProviderColor(
                                                bot.provider,
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              )
                                              : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                      radius: 24,
                                      backgroundImage:
                                          bot.avatar.isNotEmpty
                                              ? FileImage(File(bot.avatar))
                                              : null,
                                      child:
                                          bot.avatar.isEmpty
                                              ? buildProviderLogo(
                                                context,
                                                '',
                                                bot.provider,
                                                24,
                                              )
                                              : null,
                                    ),
                                    title: Text(
                                      bot.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${bot.provider} - ${bot.model}',
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => EditBotPage(
                                                bot: bot,
                                                onBotUpdated: (
                                                  updatedBot,
                                                ) async {
                                                  await BotService.updateBot(
                                                    updatedBot,
                                                  );
                                                  _loadBots(); // 重新加载联系人列表
                                                },
                                                onBotDeleted: () async {
                                                  await BotService.deleteBot(
                                                    bot.id,
                                                  );
                                                  _loadBots(); // 重新加载联系人列表
                                                },
                                              ),
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
}
