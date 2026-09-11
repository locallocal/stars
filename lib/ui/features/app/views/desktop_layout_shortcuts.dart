part of 'desktop_layout.dart';

extension _DesktopLayoutShortcuts on _DesktopLayoutState {
  Map<ShortcutActivator, VoidCallback> _shortcutBindings({
    required BuildContext context,
    required bool isChat,
    required bool overlaySidebar,
    required bool conversationInfoAvailable,
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
        if (conversationInfoAvailable) _toggleConversationInfo();
      },
      const SingleActivator(
        LogicalKeyboardKey.keyI,
        meta: true,
        alt: true,
      ): () {
        if (conversationInfoAvailable) _toggleConversationInfo();
      },
      const SingleActivator(LogicalKeyboardKey.comma, control: true):
          () => _selectPage(4),
      const SingleActivator(LogicalKeyboardKey.comma, meta: true):
          () => _selectPage(4),
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
    if (widget.currentIndex >= 2 || widget.onSearchRequested == null) return;
    if (isChat && overlaySidebar) {
      await _openChatOverlay(
        context,
        _ChatOverlay.sidebar,
        toggleIfActive: false,
      );
    } else {
      _updateState(() {
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
    _updateState(() {
      if (overlay) {
        _compactSidebarOpen = !_compactSidebarOpen;
      } else {
        _sidebarVisible = !_sidebarVisible;
      }
    });
  }

  void _toggleConversationInfo() {
    _updateState(() {
      _chatWorkspacePane =
          _conversationInfoOpen
              ? _ChatWorkspacePane.messages
              : _ChatWorkspacePane.information;
      if (_conversationInfoOpen) _compactSidebarOpen = false;
    });
  }

  void _toggleConversationDirectory() {
    if (_conversationDirectoryOpen) {
      _updateState(() => _chatWorkspacePane = _ChatWorkspacePane.messages);
      return;
    }
    if (!_ensureConversationDirectoryViewModel()) return;
    _updateState(() {
      _chatWorkspacePane = _ChatWorkspacePane.directory;
      _compactSidebarOpen = false;
    });
    if (_activeChatOverlay != null) {
      unawaited(_dismissActiveChatOverlay());
    }
  }

  void _showConversationInfo() {
    _updateState(() {
      _chatWorkspacePane = _ChatWorkspacePane.information;
      _compactSidebarOpen = false;
    });
    if (_activeChatOverlay != null) {
      unawaited(_dismissActiveChatOverlay());
    }
  }

  void _closeTopOverlay() {
    if (_activeChatOverlay != null) {
      unawaited(_dismissActiveChatOverlay());
      return;
    }
    if (_chatWorkspacePane != _ChatWorkspacePane.messages) {
      _updateState(() => _chatWorkspacePane = _ChatWorkspacePane.messages);
    } else if (_compactSidebarOpen) {
      _updateState(() => _compactSidebarOpen = false);
    }
  }
}
