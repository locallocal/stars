import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/add_bot.dart';
import 'package:stars/pages/chat.dart';
import 'package:stars/pages/edit_bot.dart';
import 'package:stars/services/bot_service.dart';
import 'package:stars/services/chat_service.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/common/logo.dart';
import 'package:stars/utils/time.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stars/pages/common/new_chat.dart';
import 'package:stars/utils/utils.dart';
import 'package:stars/utils/theme.dart';

class ContactsPage extends StatefulWidget {
  final String? selectedBotId;
  final Function(Bot bot) onBotSelected;
  final void Function(String chatId, Bot bot)? onChatCreated;

  const ContactsPage({
    super.key,
    this.selectedBotId,
    required this.onBotSelected,
    this.onChatCreated,
  });

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Bot> contacts = [];
  List<Bot> filteredBots = [];
  String searchQuery = '';
  bool isLoading = true;
  StreamSubscription? _botListSubscription;

  @override
  void initState() {
    super.initState();
    _loadBots();
    _botListSubscription = BotService.botListChanged.listen((_) {
      _loadBots();
    });
  }

  @override
  void dispose() {
    _botListSubscription?.cancel();
    super.dispose();
  }

  // 加载联系人数据
  Future<void> _loadBots() async {
    setState(() {
      isLoading = true;
    });

    final loadedBots = await BotService.getBots();
    if (!mounted) return;
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
    final isDesktop = isDesktopOrTabletPlatform(context);
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    final body = isLoading ? _buildLoadingState() : _buildBody(isDesktop);

    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            S.of(context).Bots,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              onPressed: _openAddBotPage,
            ),
          ],
        ),
        body: body,
      );
    }

    return DesktopListPanel(
      title: S.of(context).Bots,
      description: '管理可用智能体，并在右侧查看或编辑当前配置。',
      searchHintText: '搜索智能体',
      onSearchChanged: _filterBots,
      action: ElevatedButton.icon(
        onPressed: _openAddBotPage,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: Text(S.of(context).addBot),
        style: DesktopThemeTokens.primaryButtonStyle(context),
      ),
      child: body,
    );
  }

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildBody(bool isDesktop) {
    if (filteredBots.isEmpty) {
      return _buildEmptyBotsView(isDesktop);
    }
    return _buildBotsList(isDesktop);
  }

  Widget _buildBotsList(bool isDesktop) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return ListView.separated(
      padding: EdgeInsets.only(bottom: isDesktop ? 8 : 0),
      itemCount: filteredBots.length,
      separatorBuilder: (context, index) => SizedBox(height: isDesktop ? 8 : 0),
      itemBuilder: (context, index) {
        final bot = filteredBots[index];
        return Slidable(
          key: Key(bot.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              CustomSlidableAction(
                onPressed: (context) async {
                  final chat = await createNewChat(bot);
                  if (!context.mounted) return;
                  if (isDesktopOrTabletPlatform(context)) {
                    widget.onChatCreated?.call(chat.id, bot);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(id: chat.id, bot: bot),
                    ),
                  ).then((_) {
                    ChatService.notifyChatListChanged();
                  });
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
                  if (isDesktopOrTabletPlatform(context)) {
                    widget.onBotSelected(bot);
                    return;
                  }
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
          child: _BotListItem(
            bot: bot,
            timestamp: formatTimestamp(context, bot.createTimestamp),
            subtitle:
                bot.model.isEmpty
                    ? bot.provider
                    : '${bot.provider} - ${bot.model}',
            isSelected: isDesktop && widget.selectedBotId == bot.id,
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
            fontSize: fontSize ?? 16,
          ),
        );
      },
    );
  }

  Widget _buildEmptyBotsView(bool isDesktop) {
    if (isDesktop) {
      return DesktopEmptyStateCard(
        icon:
            searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.smart_toy_outlined,
        imageAsset:
            searchQuery.isEmpty ? 'assets/images/profile/no_bots.png' : null,
        title:
            searchQuery.isNotEmpty
                ? '没有找到匹配的智能体'
                : S.of(context).noBotsAvailable,
        description:
            searchQuery.isNotEmpty
                ? '换个关键词试试，或直接创建一个新的智能体。'
                : S.of(context).clickToCreateBot,
        supportingText:
            searchQuery.isNotEmpty
                ? '搜索会按智能体名称过滤列表。'
                : '创建完成后会留在桌面工作台中，便于继续编辑。',
        action: ElevatedButton.icon(
          onPressed: _openAddBotPage,
          icon: const Icon(Icons.add_circle_outline),
          label: Text(S.of(context).addBot),
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
                onPressed: _openAddBotPage,
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

  Future<void> _openAddBotPage() async {
    if (isDesktopOrTabletPlatform(context)) {
      await showDialog(
        context: context,
        builder:
            (context) => Dialog(
              insetPadding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 920,
                height: 760,
                child: AddBotPage(
                  embedded: true,
                  onBotAdded: (newBot) async {
                    await BotService.addBot(newBot);
                    _loadBots();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddBotPage(
              onBotAdded: (newBot) async {
                await BotService.addBot(newBot);
                _loadBots();
              },
            ),
      ),
    );
  }
}

class _BotListItem extends StatefulWidget {
  final Bot bot;
  final String subtitle;
  final String timestamp;
  final bool isSelected;
  final double fontSize;
  final VoidCallback onTap;

  const _BotListItem({
    required this.bot,
    required this.subtitle,
    required this.timestamp,
    required this.isSelected,
    required this.fontSize,
    required this.onTap,
  });

  @override
  State<_BotListItem> createState() => _BotListItemState();
}

class _BotListItemState extends State<_BotListItem> {
  @override
  Widget build(BuildContext context) {
    final titleStyle = DesktopThemeTokens.bodyStyle(
      context,
    )?.copyWith(fontWeight: FontWeight.w700, fontSize: widget.fontSize);
    final metaStyle = DesktopThemeTokens.metaStyle(
      context,
    )?.copyWith(fontSize: widget.fontSize - 2);

    return DesktopInteractiveListItem(
      selected: widget.isSelected,
      onTap: widget.onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                widget.bot.avatar.isEmpty
                    ? getFrostedProviderColor(
                      widget.bot.provider,
                      Theme.of(context).colorScheme.primary,
                    )
                    : Theme.of(context).colorScheme.primary,
            radius: 20,
            backgroundImage:
                widget.bot.avatar.isNotEmpty
                    ? FileImage(File(widget.bot.avatar))
                    : null,
            child:
                widget.bot.avatar.isEmpty
                    ? buildProviderLogo(context, '', widget.bot.provider, 20)
                    : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.bot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(widget.timestamp, style: metaStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle?.copyWith(
                    color: DesktopThemeTokens.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
