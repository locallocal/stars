import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

// Shared desktop interaction primitives used by multiple feature views.
/// Applies desktop-chat-specific layout and surface overrides without
/// changing the app-wide Shad theme.
class StarsChatThemeScope extends StatelessWidget {
  const StarsChatThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ShadTheme.of(context);
    final chatTheme = baseTheme.copyWith(
      breakpoints: ShadBreakpoints(
        tn: 0,
        sm: 800,
        md: 960,
        lg: 1200,
        xl: 1500,
        xxl: 1800,
      ),
      cardTheme: baseTheme.cardTheme.copyWith(shadows: const []),
      resizableTheme: baseTheme.resizableTheme.copyWith(
        dividerSize: 5,
        dividerThickness: 1,
        resetOnDoubleTap: true,
        showHandle: false,
      ),
    );

    return ShadTheme(data: chatTheme, child: child);
  }
}

/// Shows a Shad dialog while preserving the local desktop-chat theme.
///
/// The package dialog route is inserted above the local [ShadTheme]. Capturing
/// and re-applying the theme here keeps chat-only breakpoints and component
/// overrides available inside the route.
Future<T?> showChatShadDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? barrierLabel,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  Color barrierColor = const Color(0xcc000000),
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  List<AnimateEffect<dynamic>>? animateIn,
  List<AnimateEffect<dynamic>>? animateOut,
  ShadDialogVariant variant = ShadDialogVariant.primary,
  bool opaque = true,
  FocusNode? returnFocusNode,
}) async {
  final chatTheme = ShadTheme.of(context);
  final focusToRestore = returnFocusNode ?? FocusManager.instance.primaryFocus;
  final effectiveBarrierLabel =
      barrierLabel ??
      MaterialLocalizations.of(context).modalBarrierDismissLabel;

  try {
    return await showShadDialog<T>(
      context: context,
      builder: (routeContext) {
        return ShadTheme(data: chatTheme, child: Builder(builder: builder));
      },
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: effectiveBarrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      animateIn: animateIn,
      animateOut: animateOut,
      variant: variant,
      opaque: opaque,
    );
  } finally {
    _restoreFocus(focusToRestore);
  }
}

/// Shows a Shad sheet while preserving the local desktop-chat theme.
///
/// Dialogs and sheets deliberately share the same [useRootNavigator] default
/// so nested navigators cannot split the desktop overlay stack unexpectedly.
Future<T?> showChatShadSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  ShadSheetSide? side,
  String? barrierLabel,
  bool useRootNavigator = true,
  bool isDismissible = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  Color barrierColor = const Color(0xcc000000),
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  List<AnimateEffect<dynamic>>? animateIn,
  List<AnimateEffect<dynamic>>? animateOut,
  FocusNode? returnFocusNode,
}) async {
  final chatTheme = ShadTheme.of(context);
  final focusToRestore = returnFocusNode ?? FocusManager.instance.primaryFocus;
  final effectiveBarrierLabel =
      barrierLabel ??
      MaterialLocalizations.of(context).modalBarrierDismissLabel;

  try {
    return await showShadSheet<T>(
      context: context,
      builder: (routeContext) {
        return ShadTheme(data: chatTheme, child: Builder(builder: builder));
      },
      side: side,
      backgroundColor: backgroundColor,
      barrierLabel: effectiveBarrierLabel,
      shape: shape,
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      animateIn: animateIn,
      animateOut: animateOut,
    );
  } finally {
    _restoreFocus(focusToRestore);
  }
}

void _restoreFocus(FocusNode? focusNode) {
  if (focusNode == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (focusNode.context != null && focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
  });
}

/// An accessible desktop icon action with a minimum 44 by 44 hit target.
///
/// [icon] is expected to be a Lucide icon. The tooltip and button intentionally
/// share one focus node so keyboard focus exposes the same label as hover.
class StarsDesktopIconAction extends StatefulWidget {
  const StarsDesktopIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = ShadButtonVariant.ghost,
    this.focusNode,
    this.enabled = true,
    this.selected,
    this.autofocus = false,
    this.iconSize = 18,
    this.hoverBackgroundColor,
  }) : assert(
         variant != ShadButtonVariant.link,
         'ShadIconButton does not support the link variant.',
       );

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final ShadButtonVariant variant;
  final FocusNode? focusNode;
  final bool enabled;
  final bool? selected;
  final bool autofocus;
  final double iconSize;
  final Color? hoverBackgroundColor;

  @override
  State<StarsDesktopIconAction> createState() => _StarsDesktopIconActionState();
}

class _StarsDesktopIconActionState extends State<StarsDesktopIconAction> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _setFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant StarsDesktopIconAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (_ownsFocusNode) _focusNode.dispose();
      _setFocusNode(widget.focusNode);
    }
  }

  void _setFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _focusNode =
        focusNode ??
        FocusNode(debugLabel: 'StarsDesktopIconAction(${widget.label})');
  }

  @override
  void dispose() {
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = widget.enabled && widget.onPressed != null;

    return Semantics(
      container: true,
      label: widget.label,
      button: true,
      enabled: effectiveEnabled,
      selected: widget.selected,
      onTap: effectiveEnabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: ShadTooltip(
          focusNode: _focusNode,
          builder: (context) => Text(widget.label),
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: ShadIconButton.raw(
                variant: widget.variant,
                width: 36,
                height: 36,
                padding: EdgeInsets.zero,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                enabled: effectiveEnabled,
                onPressed: widget.onPressed,
                hoverBackgroundColor: widget.hoverBackgroundColor,
                iconSize: widget.iconSize,
                icon: Icon(widget.icon, size: widget.iconSize),
              ),
            ),
          ),
        ),
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
