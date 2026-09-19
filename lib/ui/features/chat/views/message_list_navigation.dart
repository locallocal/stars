part of 'message_list.dart';

extension _MessageAnchorNavigation on _MessageListState {
  void _indexMessageAnchors() {
    _messageAnchorIds = [
      for (var index = 0; index < messages.length; index++)
        messages[index].messageId.isEmpty
            ? 'legacy-${messages[index].timestamp.microsecondsSinceEpoch}-$index'
            : messages[index].messageId,
    ];
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
                onPointerDown: (_) => _anchorNavigationEpoch++,
                onPointerSignal: (_) => _anchorNavigationEpoch++,
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
                userName: widget.currentUserProfile?.name ?? '',
                onSelected:
                    (entry) => unawaited(_scrollToMessageAnchor(entry.id)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scrollToMessageAnchor(String id) async {
    final epoch = ++_anchorNavigationEpoch;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    bool? previousDirection;
    var useViewportSteps = false;
    while (mounted &&
        epoch == _anchorNavigationEpoch &&
        scrollController.hasClients) {
      final targetIndex = _messageAnchorIds.indexOf(id);
      if (targetIndex < 0) return;
      final target = _messageAnchorKeys[id]?.currentContext;
      if (target != null && target.mounted) {
        // The list is reversed: alignment 1 reveals the top of the message.
        await Scrollable.ensureVisible(
          target,
          alignment: 1,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }

      // Keep the history lazy. Seek using mounted rows, then use the actual
      // target's geometry; message heights can change as media and replies load.
      final mountedRows = <({int index, double height})>[];
      for (var index = 0; index < _messageAnchorIds.length; index++) {
        final render =
            _messageAnchorKeys[_messageAnchorIds[index]]?.currentContext
                ?.findRenderObject();
        if (render is RenderBox && render.attached && render.hasSize) {
          mountedRows.add((index: index, height: render.size.height));
        }
      }
      if (mountedRows.isEmpty) return;
      final older = targetIndex < mountedRows.first.index;
      if (previousDirection != null && previousDirection != older) {
        useViewportSteps = true;
      }
      previousDirection = older;
      final position = scrollController.position;
      final viewportStep = position.viewportDimension * .75;
      final nearestIndex =
          older ? mountedRows.first.index : mountedRows.last.index;
      final averageHeight =
          mountedRows.fold<double>(0, (sum, row) => sum + row.height) /
          mountedRows.length;
      final step =
          useViewportSteps
              ? viewportStep
              : ((nearestIndex - targetIndex).abs() * averageHeight).clamp(
                viewportStep,
                position.viewportDimension * 8,
              );
      final offset = (position.pixels + (older ? step : -step)).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (offset == position.pixels) return;
      position.jumpTo(offset);
      await WidgetsBinding.instance.endOfFrame;
    }
  }
}
