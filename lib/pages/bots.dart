import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/pages/add_bot.dart';
import 'package:bubble/pages/edit_bot.dart';
import 'package:bubble/services/bot_service.dart';

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
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        title: const Text('智能体'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
                  // 搜索联系人输入框
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: _filterBots,
                      decoration: InputDecoration(
                        hintText: '搜索智能体',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  // 联系人列表
                  Expanded(
                    child:
                        filteredBots.isEmpty
                            ? const Center(
                              child: Text(
                                '还没有智能体\n点击右上角 + 添加',
                                textAlign: TextAlign.center,
                              ),
                            )
                            : ListView.builder(
                              itemCount: filteredBots.length,
                              itemBuilder: (context, index) {
                                final bot = filteredBots[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    backgroundImage:
                                        bot.avatar.isNotEmpty
                                            ? FileImage(File(bot.avatar))
                                            : null,
                                    child:
                                        bot.avatar.isEmpty
                                            ? const Icon(
                                              Icons.smart_toy,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                  title: Text(bot.name),
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
                                              onBotUpdated: (updatedBot) async {
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
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
