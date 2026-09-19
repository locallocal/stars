part of 'message_list.dart';

const _messageAnchorMotionDuration = Duration(milliseconds: 220);

extension _MessageAnchorNavigation on _MessageListState {
  void _indexMessageAnchors() {
    _messageAnchorIds = [
      for (var index = 0; index < messages.length; index++)
        messages[index].messageId.isEmpty
            ? 'legacy-${messages[index].timestamp.microsecondsSinceEpoch}-$index'
            : messages[index].messageId,
    ];
    _messageIndexById = {
      for (var index = 0; index < _messageAnchorIds.length; index++)
        _messageAnchorIds[index]: index,
    };
    final retainedIds = _messageAnchorIds.toSet();
    _messageAnchorKeys.removeWhere((id, _) => !retainedIds.contains(id));
    for (final id in _messageAnchorIds) {
      _messageAnchorKeys.putIfAbsent(id, GlobalKey.new);
    }
    _messageAnchors = [
      for (var index = 0; index < messages.length; index++)
        if (messages[index].senderId == currentUserId)
          MessageAnchorEntry(
            id: _messageAnchorIds[index],
            message: messages[index],
          ),
    ];
  }

  Widget _buildAnchoredMessages(BuildContext context, {required Widget child}) {
    if (!isDesktop ||
        _messageAnchors.isEmpty ||
        ShadTheme.maybeOf(context) == null) {
      return child;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const topInset = 32.0;
        const bottomInset = 72.0;
        if (constraints.maxHeight <= topInset + bottomInset) return child;
        final contentWidth = math.min(
          constraints.maxWidth -
              StarsDesktopThemeSpec.formPagePadding.horizontal,
          StarsDesktopThemeSpec.contentMaxWidth,
        );
        final sideSpace = (constraints.maxWidth - contentWidth) / 2;
        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => _finishAnchorArrival(),
                onPointerSignal: (_) => _finishAnchorArrival(),
                onPointerPanZoomStart: (_) => _finishAnchorArrival(),
                child: child,
              ),
            ),
            Positioned(
              top: topInset,
              bottom: bottomInset,
              right: math.max(8, sideSpace - 32),
              width: MessageAnchorRail.width,
              child: MessageAnchorRail(
                entries: _messageAnchors,
                scrollController: scrollController,
                userName: widget.currentUserProfile?.name ?? '',
                onSelected: (entry) => _scrollToMessageAnchor(entry.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnchorArrival({required Widget child}) {
    // Animate only the viewport's paint transform. Keep the scrollbar fixed and
    // reuse the list child, without relaying out Markdown/media on every tick.
    return ClipRect(
      child: AnimatedBuilder(
        animation: _anchorArrivalAnimation,
        child: child,
        builder:
            (context, child) => Transform.translate(
              offset: _anchorArrivalAnimation.value,
              child: child,
            ),
      ),
    );
  }

  void _finishAnchorArrival() {
    if (_anchorArrivalController.value != 1) {
      _anchorArrivalController.value = 1;
    }
  }

  void _scrollToMessageAnchor(String id) {
    _finishAnchorArrival();
    if (!scrollController.hasClients || !_messageListController.isAttached) {
      return;
    }
    final messageIndex = _messageIndexById[id];
    if (messageIndex == null) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final target = _messageAnchorKeys[id]?.currentContext;
    if (target != null && target.mounted) {
      unawaited(
        Scrollable.ensureVisible(
          target,
          alignment: 1,
          duration: reduceMotion ? Duration.zero : _messageAnchorMotionDuration,
          curve: Curves.easeOutCubic,
        ),
      );
      return;
    }

    final index = messages.length - 1 - messageIndex + (isStreaming ? 1 : 0);
    if (!reduceMotion) {
      final visibleRange = _messageListController.visibleRange;
      final towardsOlder = visibleRange == null || index > visibleRange.$2;
      final travel = math.min(
        48.0,
        scrollController.position.viewportDimension * .08,
      );
      _anchorArrivalTween.begin = Offset(0, towardsOlder ? -travel : travel);
      _anchorArrivalController.forward(from: 0);
    }
    // Resolve the target once, then slide it into place over a bounded distance.
    // The transition never traverses or rebuilds the intervening history.
    // The list is reversed: alignment 1 reveals the top of the target row.
    _messageListController.jumpToItem(
      index: index,
      scrollController: scrollController,
      alignment: 1,
    );
  }
}
