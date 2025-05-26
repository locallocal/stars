import 'package:bubble/pages/edit_bot.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/pages/chat.dart';
import 'package:bubble/model/model.dart';

class DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final Function(int) onPageChanged;
  final List<Widget> pages;
  final String? selectedChatId; // 新增：选中的聊天 ID
  final Bot? selectedBot;

  const DesktopLayout({
    super.key,
    required this.currentIndex,
    required this.onPageChanged,
    required this.pages,
    this.selectedChatId,
    this.selectedBot,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSidebar(context),
        if (currentIndex == 2)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: pages[currentIndex],
            ),
          )
        else
          Container(
            width: 350,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: pages[currentIndex],
          ),
        if (currentIndex != 2) ...[
          VerticalDivider(
            width: 2,
            thickness: 2,
            color: Theme.of(context).colorScheme.secondary,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildDetailView(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailView(BuildContext context) {
    if (currentIndex == 0) {
      if (selectedChatId != null && selectedBot != null) {
        // 如果有选中的聊天，显示 ChatPage
        return ChatPage(id: selectedChatId!, bot: selectedBot!);
      } else {
        // 否则显示提示信息
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('请从左侧列表选择一个聊天'),
            ],
          ),
        );
      }
    } else if (currentIndex == 1) {
      if (selectedBot != null) {
        // 如果有选中的智能体，显示 BotDetailPage
        return EditBotPage(
          bot: selectedBot!,
          onBotUpdated: (Bot bot) => {},
          onBotDeleted: () => {},
        );
      }
      return const Center(child: Text('请选择一个智能体'));
    } else {
      // 个人资料详情不在此处显示，因为它占据整个中间区域
      return const SizedBox.shrink();
    }
  }

  Widget _buildSidebar(BuildContext context) {
    return SidebarX(
      controller: SidebarXController(selectedIndex: currentIndex),
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(24),
        ),
        hoverColor: Theme.of(context).colorScheme.primary,
        textStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        selectedTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
        hoverTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        itemTextPadding: const EdgeInsets.only(left: 30),
        selectedItemTextPadding: const EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: null,
          color: Theme.of(context).colorScheme.primary,
          boxShadow: null,
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
        selectedIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.secondary,
          size: 20,
        ),
      ),
      extendedTheme: SidebarXTheme(
        width: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      footerDivider: Divider(
        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
        height: 1,
      ),
      headerBuilder: (context, extended) {
        return InkWell(
          onTap: () => onPageChanged(2), // 使用回调更新索引
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(50),
          child: SizedBox(
            height: 100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.asset('assets/images/profile/avatar.png'),
            ),
          ),
        );
      },
      items: [
        SidebarXItem(
          icon: Icons.wechat_rounded,
          label: S.of(context).chats,
          onTap: () => onPageChanged(0), // 使用回调更新索引
        ),
        SidebarXItem(
          icon: Icons.smart_toy_rounded,
          label: S.of(context).Bots,
          onTap: () => onPageChanged(1), // 使用回调更新索引
        ),
      ],
    );
  }
}
