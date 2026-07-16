import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/chat.dart';
import 'package:stars/pages/chat/desktop_chat_primitives.dart';
import 'package:stars/pages/common/logo.dart';
import 'package:stars/pages/edit_bot.dart';
import 'package:stars/utils/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
    super.dispose();
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
              DesktopThemeTokens.sidebarMinWidth,
              DesktopThemeTokens.sidebarMaxWidth,
            );
    final inspectorAvailable =
        width >= 800 && widget.currentIndex != 2 && _activeBot != null;
    final inspectorShouldDock =
        width >= 1500 && _inspectorOpen && inspectorAvailable;
    final dockInspector =
        inspectorShouldDock && _activeChatOverlay != _ChatOverlay.inspector;
    final overlayInspector =
        width < 1500 && _inspectorOpen && inspectorAvailable;
    final inspectorMaxWidth = math.min(
      DesktopThemeTokens.inspectorMaxWidth,
      math.max(
        DesktopThemeTokens.inspectorMinWidth,
        width -
            (showSidebar ? sidebarWidth : 0) -
            DesktopThemeTokens.detailMinWidth -
            DesktopThemeTokens.splitterHitWidth * 2,
      ),
    );
    final inspectorWidth =
        _inspectorWidth
            .clamp(DesktopThemeTokens.inspectorMinWidth, inspectorMaxWidth)
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
            color: DesktopThemeTokens.shellBackground(context),
            child: SafeArea(
              child: Column(
                children: [
                  _UnifiedDesktopToolbar(
                    currentIndex: widget.currentIndex,
                    bot: _activeBot,
                    sidebarVisible:
                        overlaySidebar
                            ? isChat
                                ? _activeChatOverlay == _ChatOverlay.sidebar
                                : _compactSidebarOpen
                            : _sidebarVisible,
                    inspectorVisible:
                        dockInspector ||
                        (isChat
                            ? _activeChatOverlay == _ChatOverlay.inspector
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
                    onOpenSettings: () => _selectPage(2),
                    onSearchRequested:
                        widget.currentIndex == 2
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
                                child: _buildInspector(context, overlay: false),
                              ),
                            ],
                          ],
                        ),
                        if (!isChat && overlaySidebar && _compactSidebarOpen)
                          _buildSidebarOverlay(context, width),
                        if (!isChat && overlayInspector)
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
  }

  Map<ShortcutActivator, VoidCallback> _shortcutBindings({
    required BuildContext context,
    required bool isChat,
    required bool overlaySidebar,
    required bool inspectorAvailable,
    required bool useInspectorSheet,
  }) {
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyB, control: true):
          () => _toggleSidebar(
            context,
            overlay: overlaySidebar,
            useChatSheet: isChat,
          ),
      const SingleActivator(LogicalKeyboardKey.keyS, control: true, meta: true):
          () => _toggleSidebar(
            context,
            overlay: overlaySidebar,
            useChatSheet: isChat,
          ),
      const SingleActivator(
        LogicalKeyboardKey.keyI,
        control: true,
        alt: true,
      ): () {
        if (inspectorAvailable) {
          _toggleInspector(context, useChatSheet: useInspectorSheet);
        }
      },
      const SingleActivator(
        LogicalKeyboardKey.keyI,
        meta: true,
        alt: true,
      ): () {
        if (inspectorAvailable) {
          _toggleInspector(context, useChatSheet: useInspectorSheet);
        }
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
          () => _requestSearch(
            context,
            isChat: isChat,
            overlaySidebar: overlaySidebar,
          ),
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
          () => _requestSearch(
            context,
            isChat: isChat,
            overlaySidebar: overlaySidebar,
          ),
      const SingleActivator(LogicalKeyboardKey.keyK, control: true):
          () => _requestSearch(
            context,
            isChat: isChat,
            overlaySidebar: overlaySidebar,
          ),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
          () => _requestSearch(
            context,
            isChat: isChat,
            overlaySidebar: overlaySidebar,
          ),
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

  Future<void> _requestSearch(
    BuildContext context, {
    required bool isChat,
    required bool overlaySidebar,
  }) async {
    if (widget.currentIndex == 2 || widget.onSearchRequested == null) return;
    if (isChat && overlaySidebar) {
      await _openChatOverlay(
        context,
        _ChatOverlay.sidebar,
        toggleIfActive: false,
      );
    } else {
      setState(() {
        if (overlaySidebar) {
          _compactSidebarOpen = true;
        } else {
          _sidebarVisible = true;
        }
      });
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) widget.onSearchRequested?.call();
  }

  void _toggleSidebar(
    BuildContext context, {
    required bool overlay,
    required bool useChatSheet,
  }) {
    if (overlay && useChatSheet) {
      unawaited(_openChatOverlay(context, _ChatOverlay.sidebar));
      return;
    }
    setState(() {
      if (overlay) {
        _compactSidebarOpen = !_compactSidebarOpen;
      } else {
        _sidebarVisible = !_sidebarVisible;
      }
    });
  }

  void _toggleInspector(BuildContext context, {required bool useChatSheet}) {
    if (useChatSheet) {
      unawaited(_openChatOverlay(context, _ChatOverlay.inspector));
      return;
    }
    setState(() {
      _inspectorOpen = !_inspectorOpen;
      if (_inspectorOpen) _compactSidebarOpen = false;
    });
  }

  void _closeTopOverlay() {
    if (_activeChatOverlay != null) {
      unawaited(_dismissActiveChatOverlay());
      return;
    }
    if (_inspectorOpen) {
      setState(() => _inspectorOpen = false);
    } else if (_compactSidebarOpen) {
      setState(() => _compactSidebarOpen = false);
    }
  }

  Future<void> _openChatOverlay(
    BuildContext context,
    _ChatOverlay overlay, {
    bool toggleIfActive = true,
  }) => _enqueueChatOverlayTransition(
    () => _openChatOverlayNow(context, overlay, toggleIfActive: toggleIfActive),
  );

  Future<void> _openChatOverlayNow(
    BuildContext context,
    _ChatOverlay overlay, {
    required bool toggleIfActive,
  }) async {
    if (_activeChatOverlay == overlay) {
      if (toggleIfActive) {
        await _dismissActiveChatOverlayNow();
      } else {
        await _waitForChatOverlayRoute();
      }
      return;
    }
    if (_activeChatOverlay != null) {
      await _dismissActiveChatOverlayNow();
    }
    if (!mounted || !context.mounted || widget.currentIndex != 0) return;

    final session = ++_chatOverlaySession;
    final routeReady = Completer<ModalRoute<dynamic>?>();
    setState(() {
      _activeChatOverlay = overlay;
      _preserveChatOverlayIntent = false;
      if (overlay == _ChatOverlay.sidebar) {
        _sidebarVisible = true;
        _inspectorOpen = false;
      } else {
        _inspectorOpen = true;
      }
    });

    final navigator = Navigator.of(context, rootNavigator: true);
    _chatOverlayNavigator = navigator;
    _chatOverlayRoute = null;
    _chatOverlayRouteReady = routeReady;
    final side =
        overlay == _ChatOverlay.sidebar
            ? ShadSheetSide.left
            : ShadSheetSide.right;
    final targetWidth =
        overlay == _ChatOverlay.sidebar
            ? DesktopThemeTokens.sidebarWidth
            : 320.0;
    final closed = showChatShadSheet<void>(
      context: context,
      side: side,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      useRootNavigator: true,
      builder: (sheetContext) {
        final route = ModalRoute.of(sheetContext);
        if (!routeReady.isCompleted) routeReady.complete(route);
        if (_chatOverlaySession == session && _activeChatOverlay == overlay) {
          _chatOverlayRoute = route;
        }
        final availableWidth = math.max(
          0.0,
          MediaQuery.sizeOf(sheetContext).width - 32,
        );
        final width = math.min(targetWidth, availableWidth);
        return ShadSheet(
          draggable: false,
          scrollable: false,
          padding: overlay == _ChatOverlay.sidebar ? EdgeInsets.zero : null,
          constraints: BoxConstraints.tightFor(width: width),
          title:
              overlay == _ChatOverlay.inspector
                  ? Text(S.of(sheetContext).botInformation)
                  : null,
          closeIcon: StarsDesktopIconAction(
            icon: LucideIcons.x,
            label: MaterialLocalizations.of(sheetContext).closeButtonTooltip,
            onPressed: () => unawaited(_dismissActiveChatOverlay()),
          ),
          child: SizedBox.expand(
            child:
                overlay == _ChatOverlay.sidebar
                    ? _buildSidebar(sheetContext)
                    : _buildInspector(
                      sheetContext,
                      overlay: true,
                      showHeader: false,
                      contentPadding: const EdgeInsets.only(top: 12),
                    ),
          ),
        );
      },
    ).then<void>((_) {});
    _chatOverlayClosed = closed;
    unawaited(_watchChatOverlayClosed(session, overlay, closed));
    await _waitForChatOverlayRoute();
  }

  Future<void> _dismissActiveChatOverlay() =>
      _enqueueChatOverlayTransition(_dismissActiveChatOverlayNow);

  Future<void> _dismissActiveChatOverlayNow() async {
    final session = _chatOverlaySession;
    final overlay = _activeChatOverlay;
    final closed = _chatOverlayClosed;
    final navigator = _chatOverlayNavigator;
    if (overlay == null || closed == null || navigator == null) {
      return;
    }
    final route = _chatOverlayRoute ?? await _waitForChatOverlayRoute();
    if (session != _chatOverlaySession || _chatOverlayClosed != closed) return;
    if (route != null && route.isActive) {
      if (route.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(route);
      }
    }
    await closed;
    _completeChatOverlaySession(session, overlay, closed);
  }

  Future<ModalRoute<dynamic>?> _waitForChatOverlayRoute() async {
    final route = _chatOverlayRoute;
    if (route != null) return route;
    final routeReady = _chatOverlayRouteReady;
    final closed = _chatOverlayClosed;
    if (routeReady == null || closed == null) return null;
    return Future.any<ModalRoute<dynamic>?>([
      routeReady.future,
      closed.then<ModalRoute<dynamic>?>((_) => null),
    ]);
  }

  Future<void> _watchChatOverlayClosed(
    int session,
    _ChatOverlay overlay,
    Future<void> closed,
  ) async {
    await closed;
    await _enqueueChatOverlayTransition(() async {
      _completeChatOverlaySession(session, overlay, closed);
    });
  }

  void _completeChatOverlaySession(
    int session,
    _ChatOverlay overlay,
    Future<void> closed,
  ) {
    if (session != _chatOverlaySession || _chatOverlayClosed != closed) return;
    final preserveIntent = _preserveChatOverlayIntent;
    void clearSession() {
      _activeChatOverlay = null;
      _chatOverlayNavigator = null;
      _chatOverlayRoute = null;
      _chatOverlayRouteReady = null;
      _chatOverlayClosed = null;
      _preserveChatOverlayIntent = false;
      _chatOverlayDismissScheduled = false;
      if (!preserveIntent) {
        if (overlay == _ChatOverlay.sidebar) {
          _sidebarVisible = false;
        } else {
          _inspectorOpen = false;
        }
      }
    }

    if (mounted) {
      setState(clearSession);
    } else {
      clearSession();
    }
  }

  Future<void> _enqueueChatOverlayTransition(
    Future<void> Function() operation,
  ) {
    final scheduled = _chatOverlayTransition.then<void>((_) => operation());
    final guarded = scheduled.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Stars desktop chat overlay',
          ),
        );
      },
    );
    _chatOverlayTransition = guarded;
    return guarded;
  }

  void _closeChatOverlayForBreakpoint({
    required double width,
    required bool sidebarDocked,
    required bool inspectorDocked,
    required bool inspectorAvailable,
  }) {
    final overlay = _activeChatOverlay;
    if (overlay == null || _chatOverlayDismissScheduled) return;
    final mustClose = switch (overlay) {
      _ChatOverlay.sidebar => sidebarDocked,
      _ChatOverlay.inspector => inspectorDocked || !inspectorAvailable,
    };
    if (!mustClose) return;

    _chatOverlayDismissScheduled = true;
    _preserveChatOverlayIntent = switch (overlay) {
      _ChatOverlay.sidebar => width >= 960,
      _ChatOverlay.inspector => width >= 1500,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_dismissActiveChatOverlay());
    });
  }

  void _resizeSidebar(
    double delta, {
    required double availableWidth,
    required bool dockInspector,
    required double inspectorWidth,
  }) {
    final reserved =
        DesktopThemeTokens.detailMinWidth +
        (dockInspector ? inspectorWidth : 0) +
        DesktopThemeTokens.splitterHitWidth * (dockInspector ? 2 : 1);
    final compactDock = availableWidth < 1200;
    final minWidth = compactDock ? 260.0 : DesktopThemeTokens.sidebarMinWidth;
    final requestedMax =
        compactDock ? 280.0 : DesktopThemeTokens.sidebarMaxWidth;
    final maxWidth = math.min(
      requestedMax,
      math.max(minWidth, availableWidth - reserved),
    );
    final effectiveWidth = _sidebarWidth.clamp(minWidth, maxWidth).toDouble();
    setState(() {
      _sidebarWidth = (effectiveWidth + delta).clamp(minWidth, maxWidth);
    });
  }

  void _resetSidebarWidth(double availableWidth) {
    final defaultWidth =
        availableWidth < 1200 ? 280.0 : DesktopThemeTokens.sidebarWidth;
    setState(() => _sidebarWidth = defaultWidth);
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
    final effectiveWidth =
        _inspectorWidth
            .clamp(DesktopThemeTokens.inspectorMinWidth, maxWidth)
            .toDouble();
    setState(() {
      _inspectorWidth = (effectiveWidth + delta).clamp(
        DesktopThemeTokens.inspectorMinWidth,
        maxWidth,
      );
    });
  }

  void _resetInspectorWidth() {
    setState(() => _inspectorWidth = DesktopThemeTokens.inspectorWidth);
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
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    size: ShadButtonSize.sm,
                    onPressed: widget.onCreateChat,
                    leading: const Icon(LucideIcons.squarePen, size: 16),
                    child: Text(S.of(context).newChat),
                  ),
                ),
                const SizedBox(height: 6),
                _SidebarDestination(
                  label: S.of(context).Bots,
                  icon: LucideIcons.bot,
                  selected: widget.currentIndex == 1,
                  onTap: () => _selectPage(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const ShadSeparator.horizontal(),
          Expanded(
            // The conversation list remains the stable navigation context.
            // Agents and settings are rendered in the workspace instead of
            // replacing the sidebar's lower section.
            child: widget.pages[0],
          ),
          const ShadSeparator.horizontal(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _AccountButton(
              selected: widget.currentIndex == 2,
              useLucideIcon: widget.currentIndex == 0,
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
          widget.selectedBot == null
              ? widget.pages[1]
              : _buildBotDetail(context),
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
      icon: LucideIcons.messageCircle,
      title: S.of(context).chats,
      description: S.of(context).clickToStartChat,
      imageAsset: 'assets/icon/app_icon.png',
      action:
          widget.onCreateChat == null
              ? null
              : ShadButton(
                size: ShadButtonSize.sm,
                onPressed: widget.onCreateChat,
                leading: const Icon(LucideIcons.plus, size: 16),
                child: Text(S.of(context).newChat),
              ),
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

  Widget _buildInspector(
    BuildContext context, {
    required bool overlay,
    bool showHeader = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final bot = _activeBot;
    final decoration =
        overlay && showHeader
            ? DesktopThemeTokens.overlayInspectorDecoration(context)
            : showHeader
            ? DesktopThemeTokens.inspectorDecoration(context)
            : const BoxDecoration();
    return Container(
      decoration: decoration,
      child: ListView(
        key: const PageStorageKey<String>('desktop-context-inspector'),
        controller: _inspectorScrollController,
        padding: contentPadding ?? const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).botInformation,
                    style: DesktopThemeTokens.sectionTitleStyle(context),
                  ),
                ),
                if (widget.currentIndex == 0)
                  StarsDesktopIconAction(
                    label: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => setState(() => _inspectorOpen = false),
                    icon: LucideIcons.x,
                  )
                else
                  _DesktopToolbarIconAction(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => setState(() => _inspectorOpen = false),
                    icon: const Icon(Icons.close_rounded, size: 17),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (bot != null) ...[
            _InspectorRow(
              icon:
                  widget.currentIndex == 0
                      ? LucideIcons.bot
                      : Icons.auto_awesome_outlined,
              label: S.of(context).name,
              value: bot.name,
            ),
            _InspectorRow(
              icon:
                  widget.currentIndex == 0
                      ? LucideIcons.server
                      : Icons.hub_outlined,
              label: S.of(context).provider,
              value: bot.provider.isEmpty ? '—' : bot.provider,
            ),
            _InspectorRow(
              icon:
                  widget.currentIndex == 0
                      ? LucideIcons.cpu
                      : Icons.memory_outlined,
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
  final bool isChat;
  final bool compact;
  final bool sidebarVisible;
  final bool inspectorVisible;
  final bool inspectorAvailable;
  final VoidCallback onToggleSidebar;
  final VoidCallback? onToggleInspector;
  final VoidCallback? onCreateChat;
  final VoidCallback onOpenSettings;
  final VoidCallback? onSearchRequested;
  final VoidCallback? onClearChat;

  const _UnifiedDesktopToolbar({
    required this.currentIndex,
    required this.bot,
    required this.isChat,
    required this.compact,
    required this.sidebarVisible,
    required this.inspectorVisible,
    required this.inspectorAvailable,
    required this.onToggleSidebar,
    required this.onToggleInspector,
    required this.onCreateChat,
    required this.onOpenSettings,
    required this.onSearchRequested,
    required this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    final activeBot = bot;
    final title = switch (currentIndex) {
      0 => activeBot?.name ?? S.of(context).chats,
      1 => activeBot?.name ?? S.of(context).Bots,
      _ => S.of(context).profile,
    };
    final summary =
        activeBot == null
            ? null
            : [
              activeBot.provider.trim(),
              activeBot.model.trim(),
            ].where((value) => value.isNotEmpty).join(' · ');

    return Container(
      height: DesktopThemeTokens.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: DesktopThemeTokens.toolbarSurface(context),
        border: Border(
          bottom: BorderSide(
            width: isChat ? 1 : 0,
            color: DesktopThemeTokens.divider(context),
          ),
        ),
      ),
      child: Row(
        children: [
          if (isChat)
            StarsDesktopIconAction(
              key: const ValueKey<String>('desktop-toolbar-sidebar'),
              label:
                  sidebarVisible
                      ? S.of(context).hideSidebar
                      : S.of(context).showSidebar,
              onPressed: onToggleSidebar,
              selected: sidebarVisible,
              variant:
                  sidebarVisible
                      ? ShadButtonVariant.secondary
                      : ShadButtonVariant.ghost,
              icon:
                  sidebarVisible
                      ? LucideIcons.panelLeftClose
                      : LucideIcons.panelLeftOpen,
            )
          else
            _DesktopToolbarIconAction(
              key: const ValueKey<String>('desktop-toolbar-sidebar'),
              tooltip:
                  sidebarVisible
                      ? S.of(context).hideSidebar
                      : S.of(context).showSidebar,
              onPressed: onToggleSidebar,
              icon: const Icon(Icons.view_sidebar_outlined, size: 17),
            ),
          const SizedBox(width: 8),
          if (isChat && activeBot != null) ...[
            ShadAvatar(
              activeBot.avatar.isEmpty ? null : File(activeBot.avatar),
              size: const Size.square(28),
              placeholder: buildProviderLogo(
                context,
                '',
                activeBot.provider,
                14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Row(
              mainAxisAlignment:
                  isChat ? MainAxisAlignment.start : MainAxisAlignment.center,
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
          if (isChat)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (compact && onCreateChat != null)
                  StarsDesktopIconAction(
                    key: const ValueKey<String>('desktop-toolbar-new-chat'),
                    label: S.of(context).newChat,
                    onPressed: onCreateChat,
                    icon: LucideIcons.plus,
                  ),
                if (onSearchRequested != null)
                  StarsDesktopIconAction(
                    key: const ValueKey<String>('desktop-toolbar-search'),
                    label: MaterialLocalizations.of(context).searchFieldLabel,
                    onPressed: onSearchRequested,
                    icon: LucideIcons.search,
                  ),
                if (inspectorAvailable)
                  StarsDesktopIconAction(
                    key: const ValueKey<String>('desktop-toolbar-inspector'),
                    label:
                        inspectorVisible
                            ? S.of(context).hideInspector
                            : S.of(context).showInspector,
                    onPressed: onToggleInspector,
                    selected: inspectorVisible,
                    variant:
                        inspectorVisible
                            ? ShadButtonVariant.secondary
                            : ShadButtonVariant.ghost,
                    icon:
                        inspectorVisible
                            ? LucideIcons.panelRightClose
                            : LucideIcons.panelRightOpen,
                  ),
                _ChatToolbarMoreMenu(
                  key: const ValueKey<String>('desktop-toolbar-more'),
                  onClearChat: onClearChat,
                  onOpenSettings: onOpenSettings,
                ),
              ],
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: DesktopThemeTokens.controlFill(context),
                borderRadius: DesktopThemeTokens.controlRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onSearchRequested != null)
                    _DesktopToolbarIconAction(
                      key: const ValueKey<String>('desktop-toolbar-search'),
                      tooltip:
                          MaterialLocalizations.of(context).searchFieldLabel,
                      onPressed: onSearchRequested,
                      icon: const Icon(Icons.search_rounded, size: 17),
                    ),
                  if (inspectorAvailable)
                    _DesktopToolbarIconAction(
                      key: const ValueKey<String>('desktop-toolbar-inspector'),
                      tooltip:
                          inspectorVisible
                              ? S.of(context).hideInspector
                              : S.of(context).showInspector,
                      onPressed: onToggleInspector,
                      selected: inspectorVisible,
                      icon: Icon(
                        inspectorVisible
                            ? Icons.vertical_split_rounded
                            : Icons.vertical_split_outlined,
                        size: 17,
                      ),
                    ),
                  if (currentIndex != 2)
                    _DesktopToolbarIconAction(
                      key: const ValueKey<String>('desktop-toolbar-settings'),
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

class _ChatToolbarMoreMenu extends StatefulWidget {
  final VoidCallback? onClearChat;
  final VoidCallback onOpenSettings;

  const _ChatToolbarMoreMenu({
    super.key,
    required this.onClearChat,
    required this.onOpenSettings,
  });

  @override
  State<_ChatToolbarMoreMenu> createState() => _ChatToolbarMoreMenuState();
}

class _ChatToolbarMoreMenuState extends State<_ChatToolbarMoreMenu> {
  final ShadPopoverController _controller = ShadPopoverController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _invoke(VoidCallback action) {
    _controller.hide();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return ShadPopover(
      controller: _controller,
      padding: const EdgeInsets.all(4),
      anchor: const ShadAnchorAuto(offset: Offset(0, 4)),
      popover:
          (context) => SizedBox(
            width: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.onClearChat != null) ...[
                  ShadButton.ghost(
                    height: 36,
                    expands: true,
                    mainAxisAlignment: MainAxisAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: scheme.destructive,
                    leading: const Icon(LucideIcons.trash2, size: 16),
                    onPressed: () => _invoke(widget.onClearChat!),
                    child: Text(S.of(context).clearChatHistory),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: ShadSeparator.horizontal(),
                  ),
                ],
                ShadButton.ghost(
                  height: 36,
                  expands: true,
                  mainAxisAlignment: MainAxisAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  leading: const Icon(LucideIcons.settings, size: 16),
                  onPressed: () => _invoke(widget.onOpenSettings),
                  child: Text(S.of(context).settings),
                ),
              ],
            ),
          ),
      child: StarsDesktopIconAction(
        label: MaterialLocalizations.of(context).moreButtonTooltip,
        onPressed: _controller.toggle,
        selected: _controller.isOpen,
        variant:
            _controller.isOpen
                ? ShadButtonVariant.secondary
                : ShadButtonVariant.ghost,
        icon: LucideIcons.ellipsis,
      ),
    );
  }
}

class _DesktopToolbarIconAction extends StatefulWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  final bool selected;

  const _DesktopToolbarIconAction({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.selected = false,
  });

  @override
  State<_DesktopToolbarIconAction> createState() =>
      _DesktopToolbarIconActionState();
}

class _DesktopToolbarIconActionState extends State<_DesktopToolbarIconAction> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      selected: widget.selected,
      label: widget.tooltip,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: ShadTooltip(
            focusNode: _focusNode,
            builder: (context) => Text(widget.tooltip),
            child: ShadIconButton.raw(
              variant:
                  widget.selected
                      ? ShadButtonVariant.secondary
                      : ShadButtonVariant.ghost,
              focusNode: _focusNode,
              width: 32,
              height: 32,
              iconSize: 18,
              enabled: widget.onPressed != null,
              onPressed: widget.onPressed,
              icon: widget.icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopResizeHandle extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onResize;
  final VoidCallback onReset;
  final bool reversed;

  const _DesktopResizeHandle({
    required this.label,
    required this.value,
    required this.onResize,
    required this.onReset,
    this.reversed = false,
  });

  @override
  State<_DesktopResizeHandle> createState() => _DesktopResizeHandleState();
}

class _DesktopResizeHandleState extends State<_DesktopResizeHandle> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _hovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _moveHandle(double delta) {
    widget.onResize(widget.reversed ? -delta : delta);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 24.0 : 8.0;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveHandle(-step);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveHandle(step);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Semantics(
      label: widget.label,
      value: '${widget.value.round()} px',
      increasedValue: '${(widget.value + 8).round()} px',
      decreasedValue: '${math.max(0, widget.value - 8).round()} px',
      focusable: true,
      focused: _focused,
      onIncrease: () => widget.onResize(8),
      onDecrease: () => widget.onResize(-8),
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _focusNode.requestFocus,
            onDoubleTap: () {
              _focusNode.requestFocus();
              widget.onReset();
            },
            onHorizontalDragStart: (_) => _focusNode.requestFocus(),
            onHorizontalDragUpdate: (details) => _moveHandle(details.delta.dx),
            child: SizedBox(
              width: DesktopThemeTokens.splitterHitWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color:
                          _focused
                              ? scheme.ring
                              : _hovered
                              ? scheme.foreground.withValues(alpha: 0.35)
                              : scheme.border,
                      child: SizedBox(width: _focused ? 3 : 1),
                    ),
                  ),
                  if (_focused)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: scheme.border,
                        child: const SizedBox(width: 1),
                      ),
                    ),
                ],
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
  final bool useLucideIcon;
  final VoidCallback onTap;

  const _AccountButton({
    required this.selected,
    required this.useLucideIcon,
    required this.onTap,
  });

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
          Icon(
            useLucideIcon ? LucideIcons.settings : Icons.settings_outlined,
            size: 17,
          ),
        ],
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
