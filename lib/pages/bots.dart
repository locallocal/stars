import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
  final VoidCallback? onSelectionCleared;

  const ContactsPage({
    super.key,
    this.selectedBotId,
    required this.onBotSelected,
    this.onChatCreated,
    this.onSelectionCleared,
  });

  @override
  State<ContactsPage> createState() => ContactsPageState();
}

class ContactsPageState extends State<ContactsPage> {
  List<Bot> contacts = [];
  List<Bot> filteredBots = [];
  String searchQuery = '';
  bool isLoading = true;
  final FocusNode _searchFocusNode = FocusNode();
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  void focusSearch() => _searchFocusNode.requestFocus();

  Future<void> openAddBotPage() => _openAddBotPage();

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

  Future<void> _startChat(Bot bot) async {
    final chat = await createNewChat(bot);
    if (!mounted) return;

    if (isDesktopOrTabletPlatform(context)) {
      widget.onChatCreated?.call(chat.id, bot);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(id: chat.id, bot: bot)),
    );
    ChatService.notifyChatListChanged();
  }

  void _editBot(Bot bot) {
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
  }

  Future<void> _deleteBot(Bot bot) async {
    final wasSelected = widget.selectedBotId == bot.id;
    final deletedIndex = contacts.indexWhere((item) => item.id == bot.id);
    final confirm = await showShadDialog<bool>(
      context: context,
      variant: ShadDialogVariant.alert,
      builder:
          (context) => ShadDialog.alert(
            title: Text(S.of(context).confirmDelete),
            description: Text(S.of(context).confirmDeleteBot(bot.name)),
            actions: [
              ShadButton.outline(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(S.of(context).cancel),
              ),
              ShadButton.destructive(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(S.of(context).delete),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;
    await BotService.deleteBot(bot.id);
    if (!mounted) return;
    setState(() {
      filteredBots.removeWhere((item) => item.id == bot.id);
      contacts.removeWhere((item) => item.id == bot.id);
    });
    if (wasSelected) {
      if (contacts.isEmpty) {
        widget.onSelectionCleared?.call();
      } else {
        final adjacentIndex =
            deletedIndex.clamp(0, contacts.length - 1).toInt();
        widget.onBotSelected(contacts[adjacentIndex]);
      }
    }
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
      title: '',
      description: '',
      searchHintText: S.of(context).searchBots,
      searchFocusNode: _searchFocusNode,
      onSearchChanged: _filterBots,
      contentMaxWidth: DesktopThemeTokens.formContentMaxWidth,
      padding: DesktopThemeTokens.formPagePadding,
      action: ShadButton(
        size: ShadButtonSize.sm,
        onPressed: _openAddBotPage,
        height: DesktopThemeTokens.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        leading: const Icon(LucideIcons.plus, size: 16),
        child: Text(S.of(context).addBot),
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
    if (isDesktop) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.65,
            ),
            itemCount: filteredBots.length,
            itemBuilder: (context, index) {
              final bot = filteredBots[index];
              return _DesktopBotCard(
                bot: bot,
                subtitle:
                    bot.model.isEmpty
                        ? bot.provider
                        : '${bot.provider} · ${bot.model}',
                onOpen: () => _editBot(bot),
                onStartChat: () => _startChat(bot),
                onDelete: () => _deleteBot(bot),
              );
            },
          );
        },
      );
    }
    return ListView.separated(
      padding: EdgeInsets.only(bottom: isDesktop ? 8 : 0),
      itemCount: filteredBots.length,
      separatorBuilder: (context, index) => SizedBox(height: isDesktop ? 8 : 0),
      itemBuilder: (context, index) {
        final bot = filteredBots[index];
        if (isDesktop) {
          return MenuAnchor(
            key: ValueKey('bot-menu-${bot.id}'),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 17,
                ),
                onPressed: () => _startChat(bot),
                child: Text(S.of(context).startChatting),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.edit_outlined, size: 17),
                onPressed: () => _editBot(bot),
                child: Text(S.of(context).editBot),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.delete_outline_rounded, size: 17),
                onPressed: () => _deleteBot(bot),
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(
                    DesktopThemeTokens.error(context),
                  ),
                ),
                child: Text(S.of(context).delete),
              ),
            ],
            builder: (context, controller, child) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onSecondaryTapDown: (details) {
                  if (controller.isOpen) controller.close();
                  controller.open(position: details.localPosition);
                },
                child: _BotListItem(
                  bot: bot,
                  timestamp: formatTimestamp(context, bot.createTimestamp),
                  subtitle:
                      bot.model.isEmpty
                          ? bot.provider
                          : '${bot.provider} - ${bot.model}',
                  isSelected: widget.selectedBotId == bot.id,
                  onTap: () => _editBot(bot),
                  fontSize: fontSize ?? 16,
                  trailing: ShadTooltip(
                    builder:
                        (context) => Text(
                          MaterialLocalizations.of(context).showMenuTooltip,
                        ),
                    child: ShadIconButton.ghost(
                      width: 32,
                      height: 32,
                      padding: EdgeInsets.zero,
                      onPressed:
                          controller.isOpen
                              ? controller.close
                              : controller.open,
                      icon: const Icon(Icons.more_horiz_rounded),
                      iconSize: 18,
                    ),
                  ),
                ),
              );
            },
          );
        }

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
                ? S.of(context).noMatchingBots
                : S.of(context).noBotsAvailable,
        description:
            searchQuery.isNotEmpty
                ? S.of(context).tryDifferentSearch
                : S.of(context).clickToCreateBot,
        supportingText:
            searchQuery.isNotEmpty
                ? S.of(context).botSearchScope
                : S.of(context).newBotWorkspaceHint,
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
      await showShadDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => AddBotDialog(
              onBotAdded: (newBot) async {
                await BotService.addBot(newBot);
                _loadBots();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
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

class _DesktopBotCard extends StatefulWidget {
  const _DesktopBotCard({
    required this.bot,
    required this.subtitle,
    required this.onOpen,
    required this.onStartChat,
    required this.onDelete,
  });

  final Bot bot;
  final String subtitle;
  final VoidCallback onOpen;
  final VoidCallback onStartChat;
  final VoidCallback onDelete;

  @override
  State<_DesktopBotCard> createState() => _DesktopBotCardState();
}

class _DesktopBotCardState extends State<_DesktopBotCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    return Semantics(
      button: true,
      label: widget.bot.name,
      hint: S.of(context).selectBot,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: MenuAnchor(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(LucideIcons.messageCircle, size: 16),
              onPressed: widget.onStartChat,
              child: Text(S.of(context).startChatting),
            ),
            MenuItemButton(
              leadingIcon: const Icon(LucideIcons.trash2, size: 16),
              onPressed: widget.onDelete,
              child: Text(S.of(context).delete),
            ),
          ],
          builder:
              (context, controller, child) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpen,
                onSecondaryTapDown: (details) {
                  controller.open(position: details.localPosition);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  transform:
                      _hovered
                          ? (Matrix4.identity()..translateByDouble(0, -2, 0, 1))
                          : Matrix4.identity(),
                  child: ShadCard(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: _hovered ? theme.colorScheme.accent : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: getFrostedProviderColor(
                                widget.bot.provider,
                                Theme.of(context).colorScheme.primary,
                              ),
                              backgroundImage:
                                  widget.bot.avatar.isNotEmpty
                                      ? FileImage(File(widget.bot.avatar))
                                      : null,
                              child:
                                  widget.bot.avatar.isEmpty
                                      ? buildProviderLogo(
                                        context,
                                        '',
                                        widget.bot.provider,
                                        22,
                                      )
                                      : null,
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.arrowUpRight,
                              size: 17,
                              color: muted,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          widget.bot.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.h4,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
  final Widget? trailing;

  const _BotListItem({
    required this.bot,
    required this.subtitle,
    required this.timestamp,
    required this.isSelected,
    required this.fontSize,
    required this.onTap,
    this.trailing,
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
          if (widget.trailing != null) ...[
            const SizedBox(width: 6),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
