import 'package:stars/generated/l10n.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/chat.dart';
import 'package:stars/pages/edit_bot.dart';
import 'package:stars/utils/theme.dart';
import 'package:flutter/material.dart';

class DesktopLayout extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final List<Widget> pages;
  final String? selectedChatId;
  final Bot? selectedBot;
  final Future<void> Function(Bot) onBotUpdated;
  final Future<void> Function() onBotDeleted;

  const DesktopLayout({
    super.key,
    required this.currentIndex,
    required this.onPageChanged,
    required this.pages,
    this.selectedChatId,
    this.selectedBot,
    required this.onBotUpdated,
    required this.onBotDeleted,
  });

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  bool _compactSidebarOpen = false;
  bool _wideInspectorVisible = true;
  bool _overlayInspectorOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 960;
        final sidebarWidth = width < 1200 ? 280.0 : 340.0;
        final inspectorAvailable = width >= 960 && widget.currentIndex != 2;
        final showDockedInspector =
            width >= 1500 && _wideInspectorVisible && inspectorAvailable;
        final showOverlayInspector =
            width < 1500 && _overlayInspectorOpen && inspectorAvailable;

        return ColoredBox(
          color: DesktopThemeTokens.shellBackground(context),
          child: SafeArea(
            child: Column(
              children: [
                _DesktopMenuBar(
                  sidebarOpen: !compact || _compactSidebarOpen,
                  inspectorVisible: showDockedInspector || showOverlayInspector,
                  onToggleSidebar:
                      compact
                          ? () => setState(
                            () => _compactSidebarOpen = !_compactSidebarOpen,
                          )
                          : null,
                  onToggleInspector:
                      !inspectorAvailable
                          ? null
                          : () => setState(() {
                            if (width >= 1500) {
                              _wideInspectorVisible = !_wideInspectorVisible;
                            } else {
                              _overlayInspectorOpen = !_overlayInspectorOpen;
                            }
                          }),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!compact)
                            SizedBox(
                              width: sidebarWidth,
                              child: _buildSidebar(context),
                            ),
                          Expanded(child: _buildWorkspace(context)),
                          if (showDockedInspector)
                            SizedBox(
                              width: DesktopThemeTokens.inspectorWidth,
                              child: _buildInspector(
                                context,
                                onClose:
                                    () => setState(
                                      () => _wideInspectorVisible = false,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      if (compact && _compactSidebarOpen) ...[
                        Positioned.fill(
                          child: GestureDetector(
                            onTap:
                                () =>
                                    setState(() => _compactSidebarOpen = false),
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 320,
                          child: Material(
                            elevation: 12,
                            color: DesktopThemeTokens.sidebarSurface(context),
                            child: _buildSidebar(context),
                          ),
                        ),
                      ],
                      if (showOverlayInspector)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: DesktopThemeTokens.inspectorWidth,
                          child: Material(
                            color: Colors.transparent,
                            elevation: 12,
                            child: _buildInspector(
                              context,
                              onClose:
                                  () => setState(
                                    () => _overlayInspectorOpen = false,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return DecoratedBox(
      decoration: DesktopThemeTokens.sidebarDecoration(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Stars',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '搜索',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _SidebarDestination(
                    label: S.of(context).chats,
                    icon: Icons.chat_bubble_outline_rounded,
                    selected: widget.currentIndex == 0,
                    onTap: () => _selectPage(0),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _SidebarDestination(
                    label: S.of(context).Bots,
                    icon: Icons.smart_toy_outlined,
                    selected: widget.currentIndex == 1,
                    onTap: () => _selectPage(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: DesktopThemeTokens.divider(context)),
          Expanded(child: _buildListPanel(context)),
          Divider(height: 1, color: DesktopThemeTokens.divider(context)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _AccountButton(
              selected: widget.currentIndex == 2,
              onTap: () => _selectPage(2),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPage(int index) {
    widget.onPageChanged(index);
    if (_compactSidebarOpen) {
      setState(() => _compactSidebarOpen = false);
    }
  }

  Widget _buildListPanel(BuildContext context) {
    if (widget.currentIndex == 2) {
      return _buildProfileRail(context);
    }
    return widget.pages[widget.currentIndex];
  }

  Widget _buildWorkspace(BuildContext context) {
    return ColoredBox(
      color: DesktopThemeTokens.workspaceSurface(context),
      child:
          widget.currentIndex == 2
              ? widget.pages[widget.currentIndex]
              : _buildDetailView(context),
    );
  }

  Widget _buildDetailView(BuildContext context) {
    if (widget.currentIndex == 0) {
      if (widget.selectedChatId != null && widget.selectedBot != null) {
        return ChatPage(id: widget.selectedChatId!, bot: widget.selectedBot!);
      }
      return const DesktopEmptyStateCard(
        icon: Icons.forum_outlined,
        title: '选择一个聊天开始工作',
        description: '从左侧列表打开最近会话，或新建一个聊天继续任务。',
      );
    }

    if (widget.currentIndex == 1) {
      if (widget.selectedBot != null) {
        return EditBotPage(
          bot: widget.selectedBot!,
          embedded: true,
          onBotUpdated: widget.onBotUpdated,
          onBotDeleted: widget.onBotDeleted,
        );
      }
      return const DesktopEmptyStateCard(
        icon: Icons.smart_toy_outlined,
        title: '选择一个智能体查看详情',
        description: '在左侧列表选择智能体，即可查看和编辑当前配置。',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildProfileRail(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: const [
        _RailLabel('设置'),
        _ProfileRailSection(icon: Icons.badge_outlined, title: '个人信息'),
        _ProfileRailSection(icon: Icons.palette_outlined, title: '外观与语言'),
        _ProfileRailSection(icon: Icons.help_outline_rounded, title: '帮助与支持'),
      ],
    );
  }

  Widget _buildInspector(
    BuildContext context, {
    required VoidCallback onClose,
  }) {
    final bot = widget.selectedBot;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: DesktopThemeTokens.inspectorDecoration(context),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '上下文',
                    style: DesktopThemeTokens.sectionTitleStyle(context),
                  ),
                ),
                IconButton(
                  tooltip: '关闭面板',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _RailLabel('运行环境'),
            _InspectorRow(
              icon: Icons.computer_rounded,
              label: '环境',
              value: '本地桌面',
            ),
            _InspectorRow(
              icon: Icons.verified_outlined,
              label: '状态',
              value: '就绪',
              valueColor: DesktopThemeTokens.success(context),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: DesktopThemeTokens.divider(context)),
            const SizedBox(height: 20),
            const _RailLabel('当前智能体'),
            _InspectorRow(
              icon: Icons.smart_toy_outlined,
              label: '名称',
              value: bot?.name ?? '未选择',
            ),
            _InspectorRow(
              icon: Icons.hub_outlined,
              label: '提供方',
              value: bot?.provider ?? '—',
            ),
            _InspectorRow(
              icon: Icons.memory_outlined,
              label: '模型',
              value: bot?.model ?? '—',
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopMenuBar extends StatelessWidget {
  final bool sidebarOpen;
  final bool inspectorVisible;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onToggleInspector;

  const _DesktopMenuBar({
    required this.sidebarOpen,
    required this.inspectorVisible,
    this.onToggleSidebar,
    this.onToggleInspector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DesktopThemeTokens.menuBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesktopThemeTokens.divider(context)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: sidebarOpen ? '隐藏侧栏' : '显示侧栏',
            onPressed: onToggleSidebar,
            icon: const Icon(Icons.view_sidebar_outlined, size: 18),
          ),
          const SizedBox(width: 4),
          for (final label in const ['文件', '编辑', '视图', '帮助'])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Text(label, style: DesktopThemeTokens.metaStyle(context)),
            ),
          const Spacer(),
          IconButton(
            tooltip: inspectorVisible ? '隐藏上下文' : '显示上下文',
            onPressed: onToggleInspector,
            icon: const Icon(Icons.vertical_split_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarDestination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: DesktopThemeTokens.controlRadius,
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected ? DesktopThemeTokens.selectedFill(context) : null,
            borderRadius: DesktopThemeTokens.controlRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _AccountButton({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: DesktopThemeTokens.selectionRadius,
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? DesktopThemeTokens.selectedFill(context) : null,
            borderRadius: DesktopThemeTokens.selectionRadius,
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage('assets/images/profile/avatar.png'),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(S.of(context).profile)),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRailSection extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ProfileRailSection({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minLeadingWidth: 20,
      shape: RoundedRectangleBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
      ),
      leading: Icon(icon, size: 18),
      title: Text(title),
    );
  }
}

class _RailLabel extends StatelessWidget {
  final String text;

  const _RailLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Text(text, style: DesktopThemeTokens.metaStyle(context)),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InspectorRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Icon(icon, size: 18, color: DesktopThemeTokens.mutedText(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: DesktopThemeTokens.bodyStyle(context)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: DesktopThemeTokens.metaStyle(
                context,
              )?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
