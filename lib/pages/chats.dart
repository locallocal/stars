import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/model/model.dart';
import 'package:stars/services/bot_service.dart';
import 'package:stars/services/chat_service.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/chats/new_chat_dialog.dart';
import 'package:stars/pages/chats/chat_list_builder.dart';
import 'package:stars/pages/chat/desktop_chat_primitives.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

class ChatListPage extends StatefulWidget {
  final String? selectedChatId;
  final Function(String chatId, Bot bot) onChatSelected;
  final VoidCallback? onSelectionCleared;
  const ChatListPage({
    super.key,
    this.selectedChatId,
    required this.onChatSelected,
    this.onSelectionCleared,
  });

  @override
  State<ChatListPage> createState() => ChatListPageState();
}

class ChatListPageState extends State<ChatListPage> {
  List<Chat> chatList = [];
  List<Chat> filteredChatList = [];
  List<Bot> bots = [];
  bool isLoading = true;
  String? loadError;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void focusSearch() => _searchFocusNode.requestFocus();

  void openNewChatDialog() => _openNewChatDialog();

  Future<void> _loadChatList() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }
    try {
      final loadedChats = await ChatService.getChatList();
      final loadedBots = await BotService.getBots();
      if (!mounted) return;
      setState(() {
        chatList = loadedChats;
        bots = loadedBots;
        isLoading = false;
        _applyFilter(searchQuery);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = error.toString();
      });
    }
  }

  void _filterChats(String query) {
    setState(() {
      searchQuery = query;
      _applyFilter(query);
    });
  }

  void _applyFilter(String query) {
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
  }

  void _clearSearch() {
    _searchController.clear();
    _filterChats('');
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDesktopOrTabletPlatform(context);
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    final body =
        isLoading
            ? _buildLoadingState(isDesktop)
            : loadError != null
            ? _buildErrorState(isDesktop)
            : _buildListSection(isDesktop);

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

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _searchFocusNode.hasFocus &&
            searchQuery.isNotEmpty) {
          _clearSearch();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: DesktopListPanel(
        title: S.of(context).chats,
        description: '',
        searchHintText: S.of(context).searchChats,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        onSearchChanged: _filterChats,
        action: ShadButton(
          size: ShadButtonSize.sm,
          onPressed: _openNewChatDialog,
          height: DesktopThemeTokens.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          leading: const Icon(LucideIcons.plus, size: 16),
          child: Text(S.of(context).newChat),
        ),
        child: body,
      ),
    );
  }

  Widget _buildLoadingState(bool isDesktop) => Center(
    child:
        isDesktop
            ? const SizedBox(width: 120, child: ShadProgress())
            : const CircularProgressIndicator(),
  );

  Widget _buildErrorState(bool isDesktop) {
    if (!isDesktop) {
      return Center(
        child: TextButton(
          onPressed: _loadChatList,
          child: Text(S.of(context).retry),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: ShadAlert.destructive(
          icon: const Icon(LucideIcons.circleAlert),
          title: Text(S.of(context).unableToLoadChats),
          description: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loadError ?? ''),
              const SizedBox(height: 12),
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: _loadChatList,
                leading: const Icon(LucideIcons.refreshCw, size: 16),
                child: Text(S.of(context).retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          final wasSelected = widget.selectedChatId == id;
          final deletedIndex = chatList.indexWhere((chat) => chat.id == id);
          setState(() {
            chatList.removeWhere((chat) => chat.id == id);
            filteredChatList.removeWhere((chat) => chat.id == id);
          });
          if (wasSelected) {
            if (chatList.isEmpty) {
              widget.onSelectionCleared?.call();
            } else {
              final adjacentIndex =
                  deletedIndex.clamp(0, chatList.length - 1).toInt();
              final adjacentChat = chatList[adjacentIndex];
              final adjacentBot = bots.cast<Bot?>().firstWhere(
                (bot) => bot?.id == adjacentChat.botId,
                orElse: () => null,
              );
              if (adjacentBot == null) {
                widget.onSelectionCleared?.call();
              } else {
                widget.onChatSelected(adjacentChat.id, adjacentBot);
              }
            }
          }
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
                ? LucideIcons.searchX
                : LucideIcons.messageCircle,
        imageAsset:
            searchQuery.isEmpty ? 'assets/images/profile/no_chats.png' : null,
        title:
            searchQuery.isNotEmpty
                ? S.of(context).noMatchingChats
                : S.of(context).noChats,
        description:
            searchQuery.isNotEmpty
                ? S.of(context).tryDifferentSearch
                : S.of(context).clickToStartChat,
        supportingText:
            searchQuery.isNotEmpty
                ? S.of(context).chatSearchScope
                : S.of(context).newChatWorkspaceHint,
        action: ShadButton(
          size: ShadButtonSize.sm,
          onPressed: searchQuery.isNotEmpty ? _clearSearch : _openNewChatDialog,
          height: DesktopThemeTokens.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Icon(
            searchQuery.isNotEmpty ? LucideIcons.x : LucideIcons.plus,
            size: 16,
          ),
          child: Text(
            searchQuery.isNotEmpty
                ? S.of(context).clearSearch
                : S.of(context).newChat,
          ),
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
                  S.of(context).noMatchingChats,
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
    Widget dialogBuilder(BuildContext dialogContext) => NewChatDialog(
      onChatCreated: (chatId, bot) {
        _loadChatList();
        widget.onChatSelected(chatId, bot);
      },
    );

    if (isDesktopOrTabletPlatform(context)) {
      showChatShadDialog<void>(
        context: context,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        builder: dialogBuilder,
      );
      return;
    }

    showDialog<void>(context: context, builder: dialogBuilder);
  }
}
