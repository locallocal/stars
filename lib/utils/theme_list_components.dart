part of 'theme.dart';

class DesktopListPanel extends StatelessWidget {
  final String title;
  final String description;
  final String searchHintText;
  final ValueChanged<String> onSearchChanged;
  final Widget action;
  final Widget child;
  final FocusNode? searchFocusNode;
  final TextEditingController? searchController;
  final Widget? searchSuffix;
  final double? contentMaxWidth;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool showHeader;

  const DesktopListPanel({
    super.key,
    required this.title,
    required this.description,
    required this.searchHintText,
    required this.onSearchChanged,
    required this.action,
    required this.child,
    this.searchFocusNode,
    this.searchController,
    this.searchSuffix,
    this.contentMaxWidth,
    this.padding = StarsDesktopThemeSpec.panelPadding,
    this.backgroundColor,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final content = Column(
      children: [
        if (showHeader) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StarsDesktopThemeSpec.sectionTitleStyle(context),
                      ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: StarsDesktopThemeSpec.metaStyle(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              action,
            ],
          ),
          const SizedBox(height: 12),
        ],
        StarsSearchField(
          hintText: searchHintText,
          controller: searchController,
          focusNode: searchFocusNode,
          onChanged: onSearchChanged,
          suffixIcon: searchSuffix,
        ),
        const SizedBox(height: 12),
        Expanded(child: child),
      ],
    );
    return ColoredBox(
      color: backgroundColor ?? tokens.sidebarOpaque,
      child: Padding(
        padding: padding,
        child:
            contentMaxWidth == null
                ? content
                : Center(
                  child: SizedBox(
                    width: contentMaxWidth,
                    height: double.infinity,
                    child: content,
                  ),
                ),
      ),
    );
  }
}

class DesktopInteractiveListItem extends StatefulWidget {
  final bool selected;
  final bool suppressHoverBackground;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  const DesktopInteractiveListItem({
    super.key,
    required this.selected,
    this.suppressHoverBackground = false,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.minHeight = StarsDesktopThemeSpec.listItemMinHeight,
  });

  @override
  State<DesktopInteractiveListItem> createState() =>
      _DesktopInteractiveListItemState();
}

class _DesktopInteractiveListItemState
    extends State<DesktopInteractiveListItem> {
  final FocusNode _shadFocusNode = FocusNode(
    debugLabel: 'DesktopInteractiveListItem',
  );
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  void dispose() {
    _shadFocusNode.dispose();
    super.dispose();
  }

  void _handleShadFocusChange(bool focused) {
    final showFocusRing =
        focused &&
        _shadFocusNode.hasPrimaryFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (_focused != showFocusRing) {
      setState(() => _focused = showFocusRing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (ShadTheme.maybeOf(context) != null) {
      final selectedBackground =
          StarsDesktopThemeSpec.inactivePrimaryActionColor(context);
      return Semantics(
        button: true,
        selected: widget.selected,
        child: AnimatedContainer(
          duration:
              disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          decoration: StarsDesktopThemeSpec.listItemDecoration(
            context,
            selected: false,
            hovered: false,
            focused: _focused,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ShadButton.raw(
              variant:
                  widget.selected
                      ? ShadButtonVariant.primary
                      : ShadButtonVariant.ghost,
              expands: true,
              height: 0,
              backgroundColor: widget.selected ? selectedBackground : null,
              hoverBackgroundColor:
                  widget.selected
                      ? selectedBackground
                      : widget.suppressHoverBackground
                      ? Colors.transparent
                      : null,
              pressedBackgroundColor:
                  widget.selected ? selectedBackground : null,
              foregroundColor:
                  widget.selected
                      ? ShadTheme.of(context).colorScheme.primaryForeground
                      : null,
              hoverForegroundColor:
                  widget.selected
                      ? ShadTheme.of(context).colorScheme.primaryForeground
                      : null,
              pressedForegroundColor:
                  widget.selected
                      ? ShadTheme.of(context).colorScheme.primaryForeground
                      : null,
              padding: widget.padding,
              focusNode: _shadFocusNode,
              onFocusChange: _handleShadFocusChange,
              decoration: const ShadDecoration(disableSecondaryBorder: true),
              mainAxisAlignment: MainAxisAlignment.start,
              onPressed: widget.onTap,
              child: widget.child,
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      selected: widget.selected,
      child: AnimatedContainer(
        duration:
            disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(minHeight: widget.minHeight),
        decoration: StarsDesktopThemeSpec.listItemDecoration(
          context,
          selected: widget.selected,
          hovered: _hovered && !widget.suppressHoverBackground,
          pressed: _pressed,
          focused: _focused,
        ),
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                widget.onTap();
                return null;
              },
            ),
          },
          onShowHoverHighlight: (value) {
            if (_hovered != value) {
              setState(() => _hovered = value);
            }
          },
          onShowFocusHighlight: (value) {
            if (_focused != value) {
              setState(() => _focused = value);
            }
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                if (_pressed != value) {
                  setState(() => _pressed = value);
                }
              },
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              borderRadius: StarsDesktopThemeSpec.itemRadius,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
