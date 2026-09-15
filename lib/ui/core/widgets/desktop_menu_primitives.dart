part of 'desktop_chat_primitives.dart';

/// Data for one entry in a [StarsDesktopMenu].
class StarsDesktopMenuItem<T> {
  const StarsDesktopMenuItem({
    required this.value,
    required this.label,
    this.key,
    this.leading,
    this.enabled = true,
    this.selected = false,
    this.destructive = false,
  });

  final T value;
  final String label;
  final Key? key;
  final Widget? leading;
  final bool enabled;
  final bool selected;
  final bool destructive;
}

/// The standard click/tap menu for desktop controls.
///
/// This keeps all desktop selection and overflow menus on Shad popovers while
/// [StarsContextMenu] owns secondary-click menus. The trigger is responsible
/// for its own visual style and should normally be a
/// [StarsDesktopIconAction], [ShadButton], or [ShadInput].
class StarsDesktopMenu<T> extends StatefulWidget {
  const StarsDesktopMenu({
    super.key,
    required this.items,
    required this.onSelected,
    required this.triggerBuilder,
    this.width = 220,
    this.maxHeight = 360,
    this.alignEnd = false,
  });

  final List<StarsDesktopMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget Function(BuildContext context, VoidCallback toggle, bool isOpen)
  triggerBuilder;
  final double width;
  final double maxHeight;
  final bool alignEnd;

  @override
  State<StarsDesktopMenu<T>> createState() => _StarsDesktopMenuState<T>();
}

class _StarsDesktopMenuState<T> extends State<StarsDesktopMenu<T>> {
  late final ShadPopoverController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ShadPopoverController()..addListener(_handleChanged);
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  void _select(StarsDesktopMenuItem<T> item) {
    if (!item.enabled) return;
    _controller.hide();
    widget.onSelected(item.value);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadTheme.of(context).colorScheme;
    final anchor = ShadAnchor(
      offset: const Offset(0, 4),
      childAlignment:
          widget.alignEnd
              ? AlignmentDirectional.topEnd
              : AlignmentDirectional.topStart,
      overlayAlignment:
          widget.alignEnd
              ? AlignmentDirectional.bottomEnd
              : AlignmentDirectional.bottomStart,
    );
    return ShadPopover(
      controller: _controller,
      anchor: anchor,
      padding: EdgeInsets.zero,
      popover:
          (context) => ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.width,
              maxWidth: widget.width,
              maxHeight: widget.maxHeight,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in widget.items)
                    Semantics(
                      selected: item.selected,
                      child: ShadButton.raw(
                        key: item.key,
                        variant:
                            item.selected
                                ? ShadButtonVariant.secondary
                                : ShadButtonVariant.ghost,
                        size: ShadButtonSize.sm,
                        height: 36,
                        enabled: item.enabled,
                        expands: true,
                        mainAxisAlignment: MainAxisAlignment.start,
                        foregroundColor:
                            item.destructive ? colors.destructive : null,
                        leading: item.leading,
                        trailing:
                            item.selected
                                ? const Icon(LucideIcons.check, size: 16)
                                : const SizedBox.square(dimension: 16),
                        onPressed: () => _select(item),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      child: widget.triggerBuilder(
        context,
        _controller.toggle,
        _controller.isOpen,
      ),
    );
  }
}

class _OpenStarsContextMenuIntent extends Intent {
  const _OpenStarsContextMenuIntent();
}

/// Adds mouse and keyboard access to the same Shad context-menu items.
///
/// shadcn_ui 0.55's [ShadContextMenuRegion] owns pointer positioning but does
/// not handle Shift+F10 or the platform Menu key. This adapter keeps the
/// pointer region and keyboard-anchored menu independently controlled while
/// ensuring only one is open at a time.
class StarsContextMenu extends StatefulWidget {
  const StarsContextMenu({
    super.key,
    required this.child,
    required this.items,
    this.focusNode,
    this.constraints = const BoxConstraints(minWidth: 180),
    this.keyboardAnchor = const ShadAnchorAuto(
      offset: Offset(0, 4),
      followerAnchor: AlignmentDirectional.topStart,
      targetAnchor: AlignmentDirectional.bottomStart,
      fallback: ShadAnchorAuto(
        offset: Offset(0, -4),
        followerAnchor: AlignmentDirectional.bottomStart,
        targetAnchor: AlignmentDirectional.topStart,
      ),
    ),
    this.enabled = true,
  });

  final Widget child;
  final List<Widget> items;
  final FocusNode? focusNode;
  final BoxConstraints constraints;
  final ShadAnchorBase keyboardAnchor;
  final bool enabled;

  @override
  State<StarsContextMenu> createState() => _StarsContextMenuState();
}

class _StarsContextMenuState extends State<StarsContextMenu> {
  late final ShadContextMenuController _pointerController;
  late final ShadContextMenuController _keyboardController;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  FocusNode? _pointerReturnFocus;

  bool get _canOpen => widget.enabled && widget.items.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pointerController = ShadContextMenuController();
    _keyboardController = ShadContextMenuController();
    _pointerController.addListener(_handlePointerMenuChanged);
    _keyboardController.addListener(_handleKeyboardMenuChanged);
    _setFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant StarsContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (_ownsFocusNode) _focusNode.dispose();
      _setFocusNode(widget.focusNode);
    }
    if (!_canOpen) {
      _pointerController.hide();
      _keyboardController.hide();
    }
  }

  void _setFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _focusNode = focusNode ?? FocusNode(debugLabel: 'StarsContextMenu');
  }

  void _handlePointerMenuChanged() {
    if (_pointerController.isOpen) {
      _pointerReturnFocus ??= FocusManager.instance.primaryFocus;
      _keyboardController.hide();
    } else {
      final returnFocus = _pointerReturnFocus;
      _pointerReturnFocus = null;
      _scheduleFocusRestore(returnFocus);
    }
  }

  void _handleKeyboardMenuChanged() {
    if (_keyboardController.isOpen) {
      _pointerController.hide();
      _focusNode.requestFocus();
    } else {
      _scheduleFocusRestore();
    }
  }

  void _scheduleFocusRestore([FocusNode? preferredFocus]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pointerController.isOpen || _keyboardController.isOpen) {
        return;
      }
      final target =
          preferredFocus?.context != null && preferredFocus!.canRequestFocus
              ? preferredFocus
              : _focusNode;
      if (target.context != null && target.canRequestFocus) {
        target.requestFocus();
      }
    });
  }

  Object? _openKeyboardMenu(_OpenStarsContextMenuIntent intent) {
    if (_canOpen) _keyboardController.show();
    return null;
  }

  @override
  void dispose() {
    _pointerController.removeListener(_handlePointerMenuChanged);
    _keyboardController.removeListener(_handleKeyboardMenuChanged);
    _pointerController.dispose();
    _keyboardController.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget trigger = Focus(
      focusNode: _focusNode,
      canRequestFocus: widget.enabled,
      child: widget.child,
    );

    if (!_canOpen) return trigger;

    trigger = Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.f10, shift: true):
            _OpenStarsContextMenuIntent(),
        SingleActivator(LogicalKeyboardKey.contextMenu):
            _OpenStarsContextMenuIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenStarsContextMenuIntent:
              CallbackAction<_OpenStarsContextMenuIntent>(
                onInvoke: _openKeyboardMenu,
              ),
        },
        child: trigger,
      ),
    );

    return ShadContextMenu(
      controller: _keyboardController,
      anchor: widget.keyboardAnchor,
      constraints: widget.constraints,
      items: widget.items,
      child: ShadContextMenuRegion(
        controller: _pointerController,
        constraints: widget.constraints,
        items: widget.items,
        child: trigger,
      ),
    );
  }
}
