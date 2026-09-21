import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/utils/theme.dart';
part 'desktop_menu_primitives.dart';

// Shared desktop interaction primitives used by multiple feature views.
const IconData desktopStartConversationIcon = LucideIcons.messageCircle;
const IconData desktopBotIcon = LucideIcons.bot;
const double starsInspectorIconLabelGap = 9;
const double _appIconCornerRadiusRatio = 0.24;

BorderRadius desktopAppIconBorderRadius(double size) =>
    BorderRadius.all(Radius.circular(size * _appIconCornerRadiusRatio));

/// A compact, dismissible inline error shared by chat and form workflows.
class StarsInlineErrorAlert extends StatelessWidget {
  const StarsInlineErrorAlert({
    super.key,
    required this.error,
    required this.isDesktop,
    required this.onDismiss,
    this.alertKey,
    this.messageKey,
    this.dismissKey,
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  final String error;
  final bool isDesktop;
  final VoidCallback onDismiss;
  final Key? alertKey;
  final Key? messageKey;
  final Key? dismissKey;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final closeLabel = MaterialLocalizations.of(context).closeButtonTooltip;
    return Padding(
      padding: padding,
      child: ShadAlert.destructive(
        key: alertKey,
        decoration: const ShadDecoration(
          border: ShadBorder(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
        crossAxisAlignment: CrossAxisAlignment.center,
        iconPadding: const EdgeInsetsDirectional.only(end: 8),
        icon: const SizedBox(
          width: 36,
          height: 44,
          child: Center(child: Icon(LucideIcons.circleAlert, size: 18)),
        ),
        description: Align(
          alignment: Alignment.center,
          child: Text(error, key: messageKey, textAlign: TextAlign.center),
        ),
        trailing: StarsDesktopIconAction(
          key: dismissKey,
          icon: LucideIcons.x,
          label: closeLabel,
          iconSize: 16,
          onPressed: onDismiss,
        ),
      ),
    );
  }
}

/// A shared label/value row for desktop information panels.
///
/// The label always starts after the same icon gutter. Text values occupy the
/// available trailing region and align to the row's content edge, while
/// controls can opt into a fixed-width trailing column.
enum StarsInspectorInfoRowLayout { inspector, settings }

class StarsInspectorInfoRow extends StatelessWidget {
  const StarsInspectorInfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.value,
    this.trailing,
    this.trailingWidth,
    this.valueTextAlign = TextAlign.right,
    this.padding = const EdgeInsets.symmetric(vertical: 9),
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.iconLabelGapKey,
    this.layout = StarsInspectorInfoRowLayout.inspector,
  }) : assert(
         (value == null) != (trailing == null),
         'Provide either value or trailing.',
       );

  final IconData icon;
  final String label;
  final String? description;
  final String? value;
  final Widget? trailing;
  final double? trailingWidth;
  final TextAlign valueTextAlign;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;
  final Key? iconLabelGapKey;
  final StarsInspectorInfoRowLayout layout;

  @override
  Widget build(BuildContext context) {
    final settingsLayout = layout == StarsInspectorInfoRowLayout.settings;
    final trailingContent =
        trailing ??
        (settingsLayout
            ? Text(
              value!,
              textAlign: valueTextAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StarsDesktopThemeSpec.metaStyle(context),
            )
            : SelectableText(
              value!,
              textAlign: valueTextAlign,
              style: StarsDesktopThemeSpec.metaStyle(context),
            ));
    final Widget trailingColumn;
    if (trailingWidth case final width?) {
      trailingColumn = SizedBox(width: width, child: trailingContent);
    } else if (settingsLayout) {
      trailingColumn = ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: StarsDesktopThemeSpec.settingsRowValueMaxWidth,
        ),
        child: trailingContent,
      );
    } else {
      trailingColumn = Flexible(
        child: Align(alignment: Alignment.centerRight, child: trailingContent),
      );
    }

    final icon = Icon(
      this.icon,
      size: settingsLayout ? StarsDesktopThemeSpec.settingsRowIconSize : 17,
      color: StarsDesktopThemeSpec.mutedText(context),
    );
    final row = Row(
      crossAxisAlignment:
          settingsLayout ? CrossAxisAlignment.center : crossAxisAlignment,
      children: [
        if (settingsLayout)
          SizedBox(
            width: StarsDesktopThemeSpec.settingsRowIconSlotWidth,
            child: icon,
          )
        else
          icon,
        SizedBox(
          key: iconLabelGapKey,
          width:
              settingsLayout
                  ? StarsDesktopThemeSpec.settingsRowIconGap
                  : starsInspectorIconLabelGap,
        ),
        Expanded(
          child:
              description == null
                  ? Text(label, style: StarsDesktopThemeSpec.bodyStyle(context))
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: StarsDesktopThemeSpec.bodyStyle(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: StarsDesktopThemeSpec.metaStyle(context),
                      ),
                    ],
                  ),
        ),
        SizedBox(
          width: settingsLayout ? StarsDesktopThemeSpec.settingsRowValueGap : 8,
        ),
        trailingColumn,
      ],
    );

    return Padding(
      padding:
          settingsLayout ? StarsDesktopThemeSpec.settingsRowPadding : padding,
      child:
          settingsLayout
              ? ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: StarsDesktopThemeSpec.settingsRowMinHeight,
                ),
                child: row,
              )
              : row,
    );
  }
}

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

/// Builds the standard close action used by desktop dialogs.
Widget buildStarsDesktopDialogCloseAction(
  BuildContext context, {
  required Key key,
  required VoidCallback onPressed,
}) {
  return StarsDesktopIconAction(
    key: key,
    icon: LucideIcons.x,
    iconSize: 18,
    label: MaterialLocalizations.of(context).closeButtonTooltip,
    onPressed: onPressed,
  );
}

/// Positions a standard desktop dialog close action against its top-end edge.
ShadPosition starsDesktopDialogClosePosition(BuildContext context) {
  return ShadPosition.directional(
    top: 12,
    end: 8,
    textDirection: Directionality.of(context),
  );
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
    this.foregroundColor,
    this.showFocusRing = true,
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
  final Color? foregroundColor;
  final bool showFocusRing;

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
    final shadTheme = ShadTheme.maybeOf(context);
    if (shadTheme == null) {
      return Semantics(
        container: true,
        label: widget.label,
        button: true,
        enabled: effectiveEnabled,
        selected: widget.selected,
        onTap: effectiveEnabled ? widget.onPressed : null,
        child: Tooltip(
          message: widget.label,
          child: SizedBox.square(
            dimension: StarsDesktopThemeSpec.iconActionHitSize,
            child: IconButton(
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onPressed: effectiveEnabled ? widget.onPressed : null,
              iconSize: widget.iconSize,
              color: widget.foregroundColor,
              icon: Icon(widget.icon, size: widget.iconSize),
            ),
          ),
        ),
      );
    }

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
            dimension: StarsDesktopThemeSpec.iconActionHitSize,
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
                foregroundColor: widget.foregroundColor,
                decoration:
                    widget.showFocusRing
                        ? null
                        : const ShadDecoration(disableSecondaryBorder: true),
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
