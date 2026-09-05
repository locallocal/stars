import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_dependencies.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/core/widgets/logo.dart';
import 'package:stars/ui/core/widgets/model_modalities.dart';
import 'package:stars/ui/features/bots/views/edit_bot.dart';
import 'package:stars/ui/features/chat/view_models/chat_token_usage_view_model.dart';
import 'package:stars/ui/features/chat/view_models/conversation_memory_view_model.dart';
import 'package:stars/ui/features/chat/views/chat.dart';
import 'package:stars/ui/features/chat/views/conversation_directory_dialog.dart';
import 'package:stars/ui/features/chat/views/conversation_memory_panel.dart';
import 'package:stars/ui/features/chat/views/conversation_model_controls.dart';
import 'package:stars/ui/features/chat/views/token_usage_chart.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

part 'desktop_layout_workspace.dart';
part 'desktop_layout_toolbar.dart';
part 'desktop_layout_components.dart';
part 'desktop_layout_shortcuts.dart';
part 'desktop_layout_overlays.dart';
part 'desktop_layout_resizing.dart';

enum _ChatOverlay { sidebar, inspector }

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
  final bool isEditingBot;
  final bool showExecutionStatus;
  final bool strictGroundingMode;
  final int selectedProfileSection;
  final ValueChanged<int>? onProfileSectionChanged;
  final VoidCallback? onCreateChat;
  final VoidCallback? onAddBot;
  final VoidCallback? onSearchRequested;
  final Future<void> Function(Bot) onBotUpdated;
  final Future<void> Function() onBotDeleted;
  final Future<String?> Function()? avatarPicker;

  const DesktopLayout({
    super.key,
    required this.currentIndex,
    required this.onPageChanged,
    required this.pages,
    this.selectedChatId,
    this.selectedChatBot,
    this.selectedBot,
    this.isEditingBot = false,
    this.showExecutionStatus = true,
    this.strictGroundingMode = false,
    this.selectedProfileSection = 0,
    this.onProfileSectionChanged,
    this.onCreateChat,
    this.onAddBot,
    this.onSearchRequested,
    required this.onBotUpdated,
    required this.onBotDeleted,
    this.avatarPicker,
  });

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  void _updateState(VoidCallback callback) => setState(callback);

  double _sidebarWidth = StarsDesktopThemeSpec.sidebarWidth;
  double _inspectorWidth = StarsDesktopThemeSpec.inspectorWidth;
  bool _sidebarVisible = true;
  bool _compactSidebarOpen = false;
  bool _inspectorOpen = false;
  final ScrollController _inspectorScrollController = ScrollController();
  _ChatOverlay? _activeChatOverlay;
  NavigatorState? _chatOverlayNavigator;
  ModalRoute<dynamic>? _chatOverlayRoute;
  Completer<ModalRoute<dynamic>?>? _chatOverlayRouteReady;
  Future<void>? _chatOverlayClosed;
  Future<void> _chatOverlayTransition = Future<void>.value();
  int _chatOverlaySession = 0;
  bool _preserveChatOverlayIntent = false;
  bool _chatOverlayDismissScheduled = false;

  String? _chatPageKeyId;
  GlobalKey<ChatPageState>? _chatPageKey;
  AppDependencies? _dependencies;
  ChatTokenUsageViewModel? _tokenUsageViewModel;
  ConversationMemoryViewModel? _memoryViewModel;

  Bot? get _activeBot => switch (widget.currentIndex) {
    0 => widget.selectedChatBot,
    1 => widget.selectedBot,
    _ => null,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppScope.maybeOf(context);
    if (_dependencies == dependencies) return;
    _tokenUsageViewModel?.dispose();
    _memoryViewModel?.dispose();
    _tokenUsageViewModel = null;
    _memoryViewModel = null;
    _dependencies = dependencies;
    _replaceTokenUsageViewModel();
    _replaceMemoryViewModel();
  }

  @override
  void didUpdateWidget(covariant DesktopLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedChatId != widget.selectedChatId) {
      _chatPageKeyId = null;
      _chatPageKey = null;
      _replaceTokenUsageViewModel();
      _replaceMemoryViewModel();
    } else if (oldWidget.selectedChatBot != widget.selectedChatBot) {
      _replaceMemoryViewModel();
    }
    if (widget.currentIndex != 0 && _inspectorOpen) {
      _inspectorOpen = false;
    }
    if (oldWidget.currentIndex == 0 && widget.currentIndex != 0) {
      _preserveChatOverlayIntent = false;
      unawaited(_dismissActiveChatOverlay());
    }
  }

  @override
  void dispose() {
    final navigator = _chatOverlayNavigator;
    final route = _chatOverlayRoute;
    final routeReady = _chatOverlayRouteReady;
    _chatOverlaySession += 1;
    if (route != null && route.isActive) {
      navigator?.removeRoute(route);
    } else if (routeReady != null && !routeReady.isCompleted) {
      unawaited(
        routeReady.future.then((pendingRoute) {
          if (pendingRoute != null && pendingRoute.isActive) {
            navigator?.removeRoute(pendingRoute);
          }
        }),
      );
    }
    _inspectorScrollController.dispose();
    _tokenUsageViewModel?.dispose();
    _memoryViewModel?.dispose();
    super.dispose();
  }

  void _replaceTokenUsageViewModel() {
    final chatId = widget.selectedChatId;
    if (_tokenUsageViewModel?.chatId == chatId && chatId != null) return;
    _tokenUsageViewModel?.dispose();
    final dependencies = _dependencies;
    _tokenUsageViewModel =
        chatId == null || dependencies == null
            ? null
            : dependencies.createChatTokenUsageViewModel(chatId);
    final viewModel = _tokenUsageViewModel;
    if (viewModel != null) unawaited(viewModel.load());
  }

  void _replaceMemoryViewModel() {
    _memoryViewModel?.dispose();
    final chatId = widget.selectedChatId;
    final bot = widget.selectedChatBot;
    final dependencies = _dependencies;
    _memoryViewModel =
        chatId == null || bot == null || dependencies == null
            ? null
            : dependencies.createConversationMemoryViewModel(chatId, bot);
  }

  @override
  Widget build(BuildContext context) {
    final shell = LayoutBuilder(
      builder:
          (context, constraints) => _buildShell(
            context,
            constraints,
            isChat: widget.currentIndex == 0,
          ),
    );
    final baseTheme = ShadTheme.of(context);
    return StarsChatThemeScope(
      child: Builder(
        builder:
            (chatThemeContext) => ShadTheme(
              data:
                  widget.currentIndex == 0
                      ? ShadTheme.of(chatThemeContext)
                      : baseTheme,
              child: shell,
            ),
      ),
    );
  }

  Widget _buildShell(
    BuildContext context,
    BoxConstraints constraints, {
    required bool isChat,
  }) {
    final width = constraints.maxWidth;
    final overlaySidebar = width < 960;
    final sidebarDocked = !overlaySidebar;
    final showSidebar =
        sidebarDocked &&
        _sidebarVisible &&
        _activeChatOverlay != _ChatOverlay.sidebar;
    final sidebarWidth =
        width < 1200
            ? _sidebarWidth.clamp(260.0, 280.0)
            : _sidebarWidth.clamp(
              StarsDesktopThemeSpec.sidebarMinWidth,
              StarsDesktopThemeSpec.sidebarMaxWidth,
            );
    final inspectorAvailable =
        width >= 800 && widget.currentIndex == 0 && _activeBot != null;
    final inspectorShouldDock =
        width >= 1500 && _inspectorOpen && inspectorAvailable;
    final dockInspector =
        inspectorShouldDock && _activeChatOverlay != _ChatOverlay.inspector;
    final overlayInspector =
        width < 1500 && _inspectorOpen && inspectorAvailable;
    final inspectorMaxWidth = math.min(
      StarsDesktopThemeSpec.inspectorMaxWidth,
      math.max(
        StarsDesktopThemeSpec.inspectorMinWidth,
        width -
            (showSidebar ? sidebarWidth : 0) -
            StarsDesktopThemeSpec.detailMinWidth -
            StarsDesktopThemeSpec.splitterHitWidth * 2,
      ),
    );
    final inspectorWidth =
        _inspectorWidth
            .clamp(StarsDesktopThemeSpec.inspectorMinWidth, inspectorMaxWidth)
            .toDouble();

    if (isChat) {
      _closeChatOverlayForBreakpoint(
        width: width,
        sidebarDocked: sidebarDocked,
        inspectorDocked: inspectorShouldDock,
        inspectorAvailable: inspectorAvailable,
      );
    }

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: CallbackShortcuts(
        bindings: _shortcutBindings(
          context: context,
          isChat: isChat,
          overlaySidebar: overlaySidebar,
          inspectorAvailable: inspectorAvailable,
          useInspectorSheet: isChat && width < 1500,
        ),
        child: Focus(
          autofocus: true,
          child: ColoredBox(
            color: StarsDesktopThemeSpec.shellBackground(context),
            child: SafeArea(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showSidebar) ...[
                        SizedBox(
                          width: sidebarWidth,
                          child: _buildSidebar(
                            context,
                            onToggleSidebar:
                                () => _toggleSidebar(
                                  context,
                                  overlay: overlaySidebar,
                                  useChatSheet: isChat,
                                ),
                          ),
                        ),
                        _DesktopResizeHandle(
                          key: const ValueKey<String>(
                            'desktop-sidebar-resize-handle',
                          ),
                          label: S.of(context).showSidebar,
                          value: sidebarWidth,
                          onResize:
                              (delta) => _resizeSidebar(
                                delta,
                                availableWidth: width,
                                dockInspector: dockInspector,
                                inspectorWidth: inspectorWidth,
                              ),
                          onReset: () => _resetSidebarWidth(width),
                        ),
                      ],
                      Expanded(
                        child: Column(
                          children: [
                            _UnifiedDesktopToolbar(
                              currentIndex: widget.currentIndex,
                              bot: _activeBot,
                              sidebarVisible:
                                  overlaySidebar
                                      ? isChat
                                          ? _activeChatOverlay ==
                                              _ChatOverlay.sidebar
                                          : _compactSidebarOpen
                                      : _sidebarVisible,
                              inspectorVisible:
                                  dockInspector ||
                                  (isChat
                                      ? _activeChatOverlay ==
                                          _ChatOverlay.inspector
                                      : overlayInspector),
                              inspectorAvailable: inspectorAvailable,
                              compact: isChat && overlaySidebar,
                              isChat: isChat,
                              onToggleSidebar:
                                  () => _toggleSidebar(
                                    context,
                                    overlay: overlaySidebar,
                                    useChatSheet: isChat,
                                  ),
                              onToggleInspector:
                                  inspectorAvailable
                                      ? () => _toggleInspector(
                                        context,
                                        useChatSheet: isChat && width < 1500,
                                      )
                                      : null,
                              onCreateChat: widget.onCreateChat,
                              onSearchRequested:
                                  widget.currentIndex >= 2
                                      ? null
                                      : () => _requestSearch(
                                        context,
                                        isChat: isChat,
                                        overlaySidebar: overlaySidebar,
                                      ),
                              onClearChat:
                                  widget.currentIndex == 0 &&
                                          widget.selectedChatId != null
                                      ? _requestClearChat
                                      : null,
                              onBrowseConversationDirectory:
                                  widget.currentIndex == 0 &&
                                          widget.selectedChatId != null
                                      ? () => unawaited(
                                        _requestBrowseConversationDirectory(
                                          context,
                                        ),
                                      )
                                      : null,
                            ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: _buildWorkspace(context)),
                                  if (dockInspector) ...[
                                    _DesktopResizeHandle(
                                      label: S.of(context).showInspector,
                                      value: inspectorWidth,
                                      reversed: true,
                                      onResize:
                                          (delta) => _resizeInspector(
                                            delta,
                                            availableWidth: width,
                                            sidebarWidth:
                                                showSidebar ? sidebarWidth : 0,
                                          ),
                                      onReset: _resetInspectorWidth,
                                    ),
                                    SizedBox(
                                      width: inspectorWidth,
                                      child: _buildInspector(
                                        context,
                                        overlay: false,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isChat && overlaySidebar && _compactSidebarOpen)
                    _buildSidebarOverlay(context, width),
                  if (!isChat && overlayInspector)
                    _buildInspectorOverlay(context, width),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
