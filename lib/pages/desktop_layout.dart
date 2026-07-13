import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/chat.dart';
import 'package:stars/pages/edit_bot.dart';
import 'package:stars/utils/theme.dart';

/// Adaptive desktop shell for macOS, Windows and Linux.
///
/// Native window controls remain owned by the host platform. This widget only
/// renders the application toolbar and the resizable content columns below it.
class DesktopLayout extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final List<Widget> pages;
  final String? selectedChatId;
  final Bot? selectedChatBot;
  final Bot? selectedBot;
  final int selectedProfileSection;
  final ValueChanged<int>? onProfileSectionChanged;
  final VoidCallback? onCreateChat;
  final VoidCallback? onAddBot;
  final VoidCallback? onSearchRequested;
  final Future<void> Function(Bot) onBotUpdated;
  final Future<void> Function() onBotDeleted;

  const DesktopLayout({
    super.key,
    required this.currentIndex,
    required this.onPageChanged,
    required this.pages,
    this.selectedChatId,
    this.selectedChatBot,
    this.selectedBot,
    this.selectedProfileSection = 0,
    this.onProfileSectionChanged,
    this.onCreateChat,
    this.onAddBot,
    this.onSearchRequested,
    required this.onBotUpdated,
    required this.onBotDeleted,
  });

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  double _sidebarWidth = DesktopThemeTokens.sidebarWidth;
  double _inspectorWidth = DesktopThemeTokens.inspectorWidth;
  bool _sidebarVisible = true;
  bool _compactSidebarOpen = false;
  bool _inspectorOpen = false;
  final ScrollController _inspectorScrollController = ScrollController();

  String? _chatPageKeyId;
  GlobalKey<ChatPageState>? _chatPageKey;

  Bot? get _activeBot => switch (widget.currentIndex) {
    0 => widget.selectedChatBot,
    1 => widget.selectedBot,
    _ => null,
  };

  @override
  void didUpdateWidget(covariant DesktopLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChatId != widget.selectedChatId) {
      _chatPageKeyId = null;
      _chatPageKey = null;
    }
    if (widget.currentIndex == 2 && _inspectorOpen) {
      _inspectorOpen = false;
    }
  }

  @override
  void dispose() {
    _inspectorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final overlaySidebar = width < 960;
        final showSidebar = !overlaySidebar && _sidebarVisible;
        final sidebarWidth =
            width < 1200
                ? _sidebarWidth.clamp(260.0, 280.0)
                : _sidebarWidth.clamp(
                  DesktopThemeTokens.sidebarMinWidth,
                  DesktopThemeTokens.sidebarMaxWidth,
                );
        final inspectorAvailable =
            width >= 800 && widget.currentIndex != 2 && _activeBot != null;
        final dockInspector =
            width >= 1500 && _inspectorOpen && inspectorAvailable;
        final overlayInspector =
            width < 1500 && _inspectorOpen && inspectorAvailable;

        return FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: CallbackShortcuts(
            bindings: _shortcutBindings(
              overlaySidebar: overlaySidebar,
              inspectorAvailable: inspectorAvailable,
            ),
            child: Focus(
              autofocus: true,
              child: ColoredBox(
                color: DesktopThemeTokens.shellBackground(context),
                child: SafeArea(
                  child: Column(
                    children: [
                      _UnifiedDesktopToolbar(
                        currentIndex: widget.currentIndex,
                        bot: _activeBot,
                        sidebarVisible:
                            overlaySidebar
                                ? _compactSidebarOpen
                                : _sidebarVisible,
                        inspectorVisible: dockInspector || overlayInspector,
                        inspectorAvailable: inspectorAvailable,
                        onToggleSidebar:
                            () => _toggleSidebar(overlay: overlaySidebar),
                        onToggleInspector:
                            inspectorAvailable ? _toggleInspector : null,
                        onOpenSettings: () => _selectPage(2),
                        onSearchRequested:
                            widget.currentIndex == 2
                                ? null
                                : () => _requestSearch(
                                  overlaySidebar: overlaySidebar,
                                ),
                        onClearChat:
                            widget.currentIndex == 0 &&
                                    widget.selectedChatId != null
                                ? _requestClearChat
                                : null,
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showSidebar) ...[
                                  SizedBox(
                                    width: sidebarWidth,
                                    child: _buildSidebar(context),
                                  ),
                                  _DesktopResizeHandle(
                                    onDrag:
                                        (delta) => _resizeSidebar(
                                          delta,
                                          availableWidth: width,
                                          dockInspector: dockInspector,
                                        ),
                                  ),
                                ],
                                Expanded(child: _buildWorkspace(context)),
                                if (dockInspector) ...[
                                  _DesktopResizeHandle(
                                    onDrag:
                                        (delta) => _resizeInspector(
                                          -delta,
                                          availableWidth: width,
                                          sidebarWidth:
                                              showSidebar ? sidebarWidth : 0,
                                        ),
                                  ),
                                  SizedBox(
                                    width: _inspectorWidth,
                                    child: _buildInspector(
                                      context,
                                      overlay: false,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (overlaySidebar && _compactSidebarOpen)
                              _buildSidebarOverlay(context, width),
                            if (overlayInspector)
                              _buildInspectorOverlay(context, width),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<ShortcutActivator, VoidCallback> _shortcutBindings({
    required bool overlaySidebar,
    required bool inspectorAvailable,
  }) {
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyB, control: true):
          () => _toggleSidebar(overlay: overlaySidebar),
      const SingleActivator(LogicalKeyboardKey.keyS, control: true, meta: true):
          () => _toggleSidebar(overlay: overlaySidebar),
      const SingleActivator(
        LogicalKeyboardKey.keyI,
        control: true,
        alt: true,
      ): () {
        if (inspectorAvailable) _toggleInspector();
      },
      const SingleActivator(
        LogicalKeyboardKey.keyI,
        meta: true,
        alt: true,
      ): () {
        if (inspectorAvailable) _toggleInspector();
      },
      const SingleActivator(LogicalKeyboardKey.comma, control: true):
          () => _selectPage(2),
      const SingleActivator(LogicalKeyboardKey.comma, meta: true):
          () => _selectPage(2),
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          _invokePrimaryAction,
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
          _invokePrimaryAction,
      const SingleActivator(LogicalKeyboardKey.keyF, control: true):
          () => _requestSearch(overlaySidebar: overlaySidebar),
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
          () => _requestSearch(overlaySidebar: overlaySidebar),
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          () => _requestSearch(overlaySidebar: overlaySidebar),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
          () => _requestSearch(overlaySidebar: overlaySidebar),
      const SingleActivator(LogicalKeyboardKey.escape): _closeTopOverlay,
    };
  }

  void _invokePrimaryAction() {
    if (widget.currentIndex == 0) {
      widget.onCreateChat?.call();
    } else if (widget.currentIndex == 1) {
      widget.onAddBot?.call();
    }
  }

  void _requestSearch({required bool overlaySidebar}) {
    if (widget.currentIndex == 2 || widget.onSearchRequested == null) return;
    setState(() {
      if (overlaySidebar) {
        _compactSidebarOpen = true;
      } else {
        _sidebarVisible = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSearchRequested?.call();
    });
  }

  void _toggleSidebar({required bool overlay}) {
    setState(() {
      if (overlay) {
        _compactSidebarOpen = !_compactSidebarOpen;
      } else {
        _sidebarVisible = !_sidebarVisible;
      }
    });
  }

  void _toggleInspector() {
    setState(() {
      _inspectorOpen = !_inspectorOpen;
      if (_inspectorOpen) _compactSidebarOpen = false;
    });
  }

  void _closeTopOverlay() {
    if (_inspectorOpen) {
      setState(() => _inspectorOpen = false);
    } else if (_compactSidebarOpen) {
      setState(() => _compactSidebarOpen = false);
    }
  }

  void _resizeSidebar(
    double delta, {
    required double availableWidth,
    required bool dockInspector,
  }) {
    final reserved =
        DesktopThemeTokens.detailMinWidth +
        (dockInspector ? _inspectorWidth : 0) +
        DesktopThemeTokens.splitterHitWidth * (dockInspector ? 2 : 1);
    final maxWidth = math.min(
      DesktopThemeTokens.sidebarMaxWidth,
      math.max(DesktopThemeTokens.sidebarMinWidth, availableWidth - reserved),
    );
    setState(() {
      _sidebarWidth = (_sidebarWidth + delta).clamp(
        DesktopThemeTokens.sidebarMinWidth,
        maxWidth,
      );
    });
  }

  void _resizeInspector(
    double delta, {
    required double availableWidth,
    required double sidebarWidth,
  }) {
    final maxWidth = math.min(
      DesktopThemeTokens.inspectorMaxWidth,
      math.max(
        DesktopThemeTokens.inspectorMinWidth,
        availableWidth -
            sidebarWidth -
            DesktopThemeTokens.detailMinWidth -
            DesktopThemeTokens.splitterHitWidth * 2,
      ),
    );
    setState(() {
      _inspectorWidth = (_inspectorWidth + delta).clamp(
        DesktopThemeTokens.inspectorMinWidth,
        maxWidth,
      );
    });
  }

  Widget _buildSidebar(BuildContext context) {
    return DecoratedBox(
      decoration: DesktopThemeTokens.sidebarDecoration(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 26,
                    height: 26,
                    cacheWidth: 52,
                    cacheHeight: 52,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Stars',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _SidebarDestination(
                  label: S.of(context).chats,
                  icon: Icons.chat_bubble_outline_rounded,
                  selected: widget.currentIndex == 0,
                  onTap: () => _selectPage(0),
                ),
                const SizedBox(height: 2),
                _SidebarDestination(
                  label: S.of(context).Bots,
                  icon: Icons.auto_awesome_outlined,
                  selected: widget.currentIndex == 1,
                  onTap: () => _selectPage(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 0, thickness: 0),
          Expanded(
            child: IndexedStack(
              index: widget.currentIndex,
              children: [
                widget.pages[0],
                widget.pages[1],
                _buildProfileRail(context),
              ],
            ),
          ),
          Divider(height: 0, thickness: 0),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _AccountButton(
              selected: widget.currentIndex == 2,
              onTap: () => _selectPage(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarOverlay(BuildContext context, double availableWidth) {
    final width = math.min(
      DesktopThemeTokens.sidebarWidth,
      math.max(0.0, availableWidth - 48.0),
    );
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              button: true,
              label: MaterialLocalizations.of(context).closeButtonTooltip,
              child: GestureDetector(
                onTap: () => setState(() => _compactSidebarOpen = false),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.22)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: width,
            child: Material(
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.22),
              color: DesktopThemeTokens.sidebarSurface(context),
              child: _buildSidebar(context),
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

  Widget _buildWorkspace(BuildContext context) {
    return ColoredBox(
      color: DesktopThemeTokens.workspaceSurface(context),
      child: IndexedStack(
        index: widget.currentIndex,
        children: [
          _buildChatDetail(context),
          _buildBotDetail(context),
          widget.pages[2],
        ],
      ),
    );
  }

  Widget _buildChatDetail(BuildContext context) {
    if (widget.selectedChatId != null && widget.selectedChatBot != null) {
      if (_chatPageKeyId != widget.selectedChatId) {
        _chatPageKeyId = widget.selectedChatId;
        _chatPageKey = GlobalKey<ChatPageState>(
          debugLabel: 'chat-${widget.selectedChatId}',
        );
      }
      return ChatPage(
        key: _chatPageKey,
        id: widget.selectedChatId!,
        bot: widget.selectedChatBot!,
      );
    }
    return DesktopEmptyStateCard(
      icon: Icons.chat_bubble_outline_rounded,
      title: S.of(context).chats,
      description: S.of(context).clickToStartChat,
      imageAsset: 'assets/icon/app_icon.png',
    );
  }

  Widget _buildBotDetail(BuildContext context) {
    if (widget.selectedBot != null) {
      return EditBotPage(
        key: ValueKey<String>(widget.selectedBot!.id),
        bot: widget.selectedBot!,
        embedded: true,
        onBotUpdated: widget.onBotUpdated,
        onBotDeleted: widget.onBotDeleted,
      );
    }
    return DesktopEmptyStateCard(
      icon: Icons.auto_awesome_outlined,
      title: S.of(context).Bots,
      description: S.of(context).selectBot,
      imageAsset: 'assets/icon/app_icon.png',
    );
  }

  Widget _buildProfileRail(BuildContext context) {
    final items = <({IconData icon, String title})>[
      (
        icon: Icons.badge_outlined,
        title: S.of(context).desktopPersonalInformation,
      ),
      (
        icon: Icons.palette_outlined,
        title: S.of(context).desktopAppearanceAndLanguage,
      ),
      (
        icon: Icons.help_outline_rounded,
        title: S.of(context).desktopHelpAndSupport,
      ),
      (
        icon: Icons.info_outline_rounded,
        title: S.of(context).desktopAboutAndLegal,
      ),
    ];
    return ListView(
      key: const PageStorageKey<String>('desktop-profile-navigation'),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      children: [
        _RailLabel(S.of(context).settings),
        for (final entry in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _ProfileRailSection(
              icon: entry.$2.icon,
              title: entry.$2.title,
              selected: widget.selectedProfileSection == entry.$1,
              onTap: () {
                widget.onProfileSectionChanged?.call(entry.$1);
                if (widget.currentIndex != 2) _selectPage(2);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInspectorOverlay(BuildContext context, double availableWidth) {
    final width =
        _inspectorWidth
            .clamp(
              DesktopThemeTokens.inspectorMinWidth,
              math.min(
                DesktopThemeTokens.inspectorMaxWidth,
                math.max(
                  DesktopThemeTokens.inspectorMinWidth,
                  availableWidth - 24.0,
                ),
              ),
            )
            .toDouble();
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _inspectorOpen = false),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            bottom: 8,
            width: width,
            child: Material(
              color: Colors.transparent,
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: _buildInspector(context, overlay: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspector(BuildContext context, {required bool overlay}) {
    final bot = _activeBot;
    final decoration =
        overlay
            ? DesktopThemeTokens.overlayInspectorDecoration(context)
            : DesktopThemeTokens.inspectorDecoration(context);
    return Container(
      decoration: decoration,
      child: ListView(
        key: const PageStorageKey<String>('desktop-context-inspector'),
        controller: _inspectorScrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.of(context).botInformation,
                  style: DesktopThemeTokens.sectionTitleStyle(context),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => setState(() => _inspectorOpen = false),
                icon: const Icon(Icons.close_rounded, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (bot != null) ...[
            _InspectorRow(
              icon: Icons.auto_awesome_outlined,
              label: S.of(context).name,
              value: bot.name,
            ),
            _InspectorRow(
              icon: Icons.hub_outlined,
              label: S.of(context).provider,
              value: bot.provider.isEmpty ? '—' : bot.provider,
            ),
            _InspectorRow(
              icon: Icons.memory_outlined,
              label: S.of(context).model,
              value: bot.model.isEmpty ? '—' : bot.model,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _requestClearChat() async {
    await _chatPageKey?.currentState?.requestClearChat();
  }
}

class _UnifiedDesktopToolbar extends StatelessWidget {
  final int currentIndex;
  final Bot? bot;
  final bool sidebarVisible;
  final bool inspectorVisible;
  final bool inspectorAvailable;
  final VoidCallback onToggleSidebar;
  final VoidCallback? onToggleInspector;
  final VoidCallback onOpenSettings;
  final VoidCallback? onSearchRequested;
  final VoidCallback? onClearChat;

  const _UnifiedDesktopToolbar({
    required this.currentIndex,
    required this.bot,
    required this.sidebarVisible,
    required this.inspectorVisible,
    required this.inspectorAvailable,
    required this.onToggleSidebar,
    required this.onToggleInspector,
    required this.onOpenSettings,
    required this.onSearchRequested,
    required this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (currentIndex) {
      0 => bot?.name ?? S.of(context).chats,
      1 => bot?.name ?? S.of(context).Bots,
      _ => S.of(context).profile,
    };
    final summary =
        bot == null
            ? null
            : [
              bot!.provider.trim(),
              bot!.model.trim(),
            ].where((value) => value.isNotEmpty).join(' · ');

    return Container(
      height: DesktopThemeTokens.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: DesktopThemeTokens.toolbarSurface(context),
        border: Border(
          bottom: BorderSide(
            width: 0,
            color: DesktopThemeTokens.divider(context),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip:
                sidebarVisible
                    ? S.of(context).hideSidebar
                    : S.of(context).showSidebar,
            onPressed: onToggleSidebar,
            icon: const Icon(Icons.view_sidebar_outlined, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesktopThemeTokens.toolbarTitleStyle(context),
                  ),
                ),
                if (summary != null && summary.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesktopThemeTokens.metaStyle(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: DesktopThemeTokens.controlFill(context),
              borderRadius: DesktopThemeTokens.controlRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onSearchRequested != null)
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).searchFieldLabel,
                    onPressed: onSearchRequested,
                    icon: const Icon(Icons.search_rounded, size: 17),
                  ),
                if (inspectorAvailable)
                  IconButton(
                    tooltip:
                        inspectorVisible
                            ? S.of(context).hideInspector
                            : S.of(context).showInspector,
                    onPressed: onToggleInspector,
                    icon: Icon(
                      inspectorVisible
                          ? Icons.vertical_split_rounded
                          : Icons.vertical_split_outlined,
                      size: 17,
                    ),
                  ),
                if (onClearChat != null)
                  MenuAnchor(
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(
                          Icons.delete_sweep_outlined,
                          size: 17,
                        ),
                        onPressed: onClearChat,
                        child: Text(S.of(context).clearChatHistory),
                      ),
                    ],
                    builder: (context, controller, child) {
                      return IconButton(
                        tooltip:
                            MaterialLocalizations.of(context).moreButtonTooltip,
                        onPressed:
                            controller.isOpen
                                ? controller.close
                                : controller.open,
                        icon: const Icon(Icons.more_horiz_rounded, size: 18),
                      );
                    },
                  ),
                if (currentIndex != 2)
                  IconButton(
                    tooltip: S.of(context).settings,
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_outlined, size: 17),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopResizeHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;

  const _DesktopResizeHandle({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: SizedBox(
          width: DesktopThemeTokens.splitterHitWidth,
          child: Center(
            child: SizedBox(
              width: 0,
              height: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 0,
                      color: DesktopThemeTokens.divider(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: DesktopInteractiveListItem(
        selected: selected,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
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
    return DesktopInteractiveListItem(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundImage: ResizeImage(
              AssetImage('assets/images/profile/avatar.png'),
              width: 60,
              height: 60,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(S.of(context).profile)),
          const Icon(Icons.chevron_right_rounded, size: 17),
        ],
      ),
    );
  }
}

class _ProfileRailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileRailSection({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopInteractiveListItem(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 9),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}

class _RailLabel extends StatelessWidget {
  final String text;

  const _RailLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 7),
      child: Text(
        text,
        style: DesktopThemeTokens.metaStyle(
          context,
        )?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InspectorRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: DesktopThemeTokens.mutedText(context)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(label, style: DesktopThemeTokens.bodyStyle(context)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: DesktopThemeTokens.metaStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
