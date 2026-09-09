part of 'desktop_layout.dart';

extension _DesktopLayoutOverlays on _DesktopLayoutState {
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
    _updateState(() {
      _activeChatOverlay = overlay;
      _preserveChatOverlayIntent = false;
      _sidebarVisible = true;
    });

    final navigator = Navigator.of(context, rootNavigator: true);
    _chatOverlayNavigator = navigator;
    _chatOverlayRoute = null;
    _chatOverlayRouteReady = routeReady;
    final closed = showChatShadSheet<void>(
      context: context,
      side: ShadSheetSide.left,
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
        final width = math.min(
          StarsDesktopThemeSpec.sidebarWidth,
          availableWidth,
        );
        return ShadSheet(
          draggable: false,
          scrollable: false,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: width),
          closeIcon: StarsDesktopIconAction(
            icon: LucideIcons.x,
            label: MaterialLocalizations.of(sheetContext).closeButtonTooltip,
            onPressed: () => unawaited(_dismissActiveChatOverlay()),
          ),
          child: SizedBox.expand(child: _buildSidebar(sheetContext)),
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
      if (!preserveIntent) _sidebarVisible = false;
    }

    if (mounted) {
      _updateState(clearSession);
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

  void _closeChatOverlayForBreakpoint({required bool sidebarDocked}) {
    final overlay = _activeChatOverlay;
    if (overlay == null || _chatOverlayDismissScheduled) return;
    if (!sidebarDocked) return;

    _chatOverlayDismissScheduled = true;
    _preserveChatOverlayIntent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_dismissActiveChatOverlay());
    });
  }
}
