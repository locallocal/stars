part of 'desktop_layout.dart';

extension _DesktopLayoutResizing on _DesktopLayoutState {
  void _resizeSidebar(
    double delta, {
    required double availableWidth,
    required bool dockInspector,
    required double inspectorWidth,
  }) {
    final reserved =
        StarsDesktopThemeSpec.detailMinWidth +
        (dockInspector ? inspectorWidth : 0) +
        StarsDesktopThemeSpec.splitterHitWidth * (dockInspector ? 2 : 1);
    final compactDock = availableWidth < 1200;
    final minWidth =
        compactDock ? 260.0 : StarsDesktopThemeSpec.sidebarMinWidth;
    final requestedMax =
        compactDock ? 280.0 : StarsDesktopThemeSpec.sidebarMaxWidth;
    final maxWidth = math.min(
      requestedMax,
      math.max(minWidth, availableWidth - reserved),
    );
    final effectiveWidth = _sidebarWidth.clamp(minWidth, maxWidth).toDouble();
    _updateState(() {
      _sidebarWidth = (effectiveWidth + delta).clamp(minWidth, maxWidth);
    });
  }

  void _resetSidebarWidth(double availableWidth) {
    final defaultWidth =
        availableWidth < 1200 ? 280.0 : StarsDesktopThemeSpec.sidebarWidth;
    _updateState(() => _sidebarWidth = defaultWidth);
  }

  void _resizeInspector(
    double delta, {
    required double availableWidth,
    required double sidebarWidth,
  }) {
    final maxWidth = math.min(
      StarsDesktopThemeSpec.inspectorMaxWidth,
      math.max(
        StarsDesktopThemeSpec.inspectorMinWidth,
        availableWidth -
            sidebarWidth -
            StarsDesktopThemeSpec.detailMinWidth -
            StarsDesktopThemeSpec.splitterHitWidth * 2,
      ),
    );
    final effectiveWidth =
        _inspectorWidth
            .clamp(StarsDesktopThemeSpec.inspectorMinWidth, maxWidth)
            .toDouble();
    _updateState(() {
      _inspectorWidth = (effectiveWidth + delta).clamp(
        StarsDesktopThemeSpec.inspectorMinWidth,
        maxWidth,
      );
    });
  }

  void _resetInspectorWidth() {
    _updateState(() => _inspectorWidth = StarsDesktopThemeSpec.inspectorWidth);
  }

  Future<void> _requestClearChat() async {
    await _chatPageKey?.currentState?.requestClearChat();
  }

  Future<void> _requestBrowseConversationDirectory(BuildContext context) async {
    final dependencies = _dependencies;
    final chatId = widget.selectedChatId;
    if (dependencies == null || chatId == null || !context.mounted) return;
    await showConversationDirectoryDialog(
      context: context,
      viewModel: dependencies.createConversationDirectoryViewModel(chatId),
      actionViewModel: dependencies.createMessageActionViewModel(),
    );
  }
}
