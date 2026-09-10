part of 'theme.dart';

enum StarsGlassRole { toolbar, sidebar, composer, popover, overlayInspector }

/// A shadcn-style content section shared by desktop settings and detail pages.
///
/// Keeping the card shell here ensures page sections use the same spacing,
/// typography, and row separators instead of recreating those decisions in
/// each feature.
class StarsDesktopSectionCard extends StatelessWidget {
  const StarsDesktopSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.titleKey,
    this.description,
    this.leadingIcon,
  });

  final String title;
  final Key? titleKey;
  final String? description;
  final IconData? leadingIcon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final sectionDescription = description;
    final sectionTitle = Text(
      title,
      key: titleKey,
      style: StarsDesktopThemeSpec.sectionTitleStyle(
        context,
      )?.copyWith(fontSize: StarsDesktopThemeSpec.botFormSectionTitleFontSize),
    );
    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.all(
        StarsDesktopThemeSpec.botFormSectionPadding,
      ),
      title:
          leadingIcon == null
              ? sectionTitle
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      leadingIcon,
                      size: 16,
                      color: StarsDesktopThemeSpec.mutedText(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: sectionTitle),
                ],
              ),
      description: sectionDescription == null ? null : Text(sectionDescription),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: StarsDesktopSettingsGroup(children: children),
      ),
    );
  }
}

/// A shadcn-style group of settings rows separated after the icon gutter.
///
/// Reusing this group keeps field separators aligned across settings and
/// inspector cards, including dynamically assembled row collections.
class StarsDesktopSettingsGroup extends StatelessWidget {
  const StarsDesktopSettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < children.length; index++) ...[
        children[index],
        if (index != children.length - 1)
          const ShadSeparator.horizontal(
            margin: StarsDesktopThemeSpec.settingsRowSeparatorMargin,
          ),
      ],
    ],
  );
}

/// Solid semantic fallback for glass-role surfaces.
///
/// This widget intentionally never constructs a BackdropFilter. Native/window
/// material integration can be added behind this API when it is reliable.
class StarsGlassSurface extends StatelessWidget {
  const StarsGlassSurface({super.key, required this.role, required this.child});

  final StarsGlassRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final transient =
        role == StarsGlassRole.popover ||
        role == StarsGlassRole.overlayInspector;
    final composer = role == StarsGlassRole.composer;
    final borderRadius =
        transient
            ? StarsDesktopThemeSpec.containerRadius
            : composer
            ? StarsDesktopThemeSpec.inputRadius
            : BorderRadius.zero;
    final color = switch (role) {
      StarsGlassRole.sidebar => tokens.sidebarOpaque,
      StarsGlassRole.toolbar => tokens.raisedSurface,
      StarsGlassRole.composer => tokens.raisedSurface,
      StarsGlassRole.popover => tokens.raisedSurface,
      StarsGlassRole.overlayInspector => tokens.raisedSurface,
    };
    final border = switch (role) {
      StarsGlassRole.toolbar => Border(
        bottom: BorderSide(color: tokens.separator, width: 0),
      ),
      StarsGlassRole.sidebar => Border(
        right: BorderSide(color: tokens.separator, width: 0),
      ),
      _ => Border.all(color: tokens.separator, width: 0),
    };

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: border,
        borderRadius: borderRadius,
        boxShadow:
            transient || composer
                ? StarsDesktopThemeSpec.floatingShadow(
                  context,
                  subtle: composer,
                )
                : null,
      ),
      clipBehavior:
          borderRadius == BorderRadius.zero ? Clip.none : Clip.antiAlias,
      child: child,
    );
  }
}

class StarsToolbarButton extends StatelessWidget {
  const StarsToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final shadTheme = ShadTheme.maybeOf(context);
    if (shadTheme != null) {
      final button = ShadIconButton.ghost(
        icon: icon,
        iconSize: 18,
        width: 32,
        height: 32,
        enabled: onPressed != null,
        onPressed: onPressed,
        foregroundColor:
            selected ? shadTheme.colorScheme.accentForeground : null,
        backgroundColor:
            selected ? shadTheme.colorScheme.accent : Colors.transparent,
      );
      return Semantics(
        button: true,
        enabled: onPressed != null,
        selected: selected,
        label: semanticLabel ?? tooltip,
        excludeSemantics: true,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: ShadTooltip(
              builder: (context) => Text(tooltip),
              child: button,
            ),
          ),
        ),
      );
    }
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
      maximumSize: const WidgetStatePropertyAll(Size(32, 32)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      iconSize: const WidgetStatePropertyAll(18),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.tertiaryText;
        }
        return selected ? tokens.accent : tokens.primaryText;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.pressed)) {
          return tokens.pressedFill;
        }
        if (selected) {
          return tokens.selectedFill;
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return tokens.hoverFill;
        }
        return Colors.transparent;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStateProperty.resolveWith((states) {
        if (!states.contains(WidgetState.focused)) {
          return BorderSide.none;
        }
        return BorderSide(
          color: tokens.focusRing,
          width: tokens.highContrast ? 2 : 1.5,
        );
      }),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: StarsDesktopThemeSpec.controlRadius,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      selected: selected,
      label: semanticLabel ?? tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: IconButton(onPressed: onPressed, style: style, icon: icon),
          ),
        ),
      ),
    );
  }
}

class StarsSearchField extends StatelessWidget {
  const StarsSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
    this.enabled = true,
    this.autofocus = false,
    this.suffixIcon,
    this.insetFocusRing = false,
  }) : assert(!insetFocusRing || focusNode != null);

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;
  final bool enabled;
  final bool autofocus;
  final Widget? suffixIcon;

  /// Paints the Shad focus border inside the field bounds so an ancestor clip
  /// cannot cover it. Material search fields already paint their focus border
  /// inside their bounds.
  final bool insetFocusRing;

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    Widget field;
    if (shadTheme == null) {
      field = TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: StarsDesktopThemeSpec.searchDecoration(
          context,
          hintText: hintText,
          suffixIcon: suffixIcon,
        ),
      );
    } else {
      field = ShadInput(
        controller: controller,
        focusNode: focusNode,
        padding: StarsDesktopThemeSpec.formFieldPadding,
        enabled: enabled,
        autofocus: autofocus,
        decoration:
            insetFocusRing
                ? ShadDecoration(
                  focusedBorder: ShadBorder.all(
                    color: shadTheme.colorScheme.ring,
                    width: 1,
                    radius: shadTheme.radius,
                  ),
                  secondaryFocusedBorder: ShadBorder.none,
                )
                : null,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        placeholder: Text(hintText),
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: SizedBox(
            width: 16,
            height: 44,
            child: Icon(
              LucideIcons.search,
              size: 16,
              color: shadTheme.colorScheme.mutedForeground,
            ),
          ),
        ),
        trailing: suffixIcon,
        alignment: Alignment.centerLeft,
        placeholderAlignment: Alignment.centerLeft,
        constraints: const BoxConstraints(
          minHeight: StarsDesktopThemeSpec.botFormFieldHeight,
        ),
      );
      if (insetFocusRing) {
        field = _StarsInsetFocusRing(
          focusNode: focusNode!,
          color: shadTheme.colorScheme.ring,
          borderRadius: shadTheme.radius,
          child: field,
        );
      }
    }

    return Semantics(
      container: true,
      textField: true,
      enabled: enabled,
      label: semanticLabel ?? hintText,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: StarsDesktopThemeSpec.botFormFieldHeight,
        ),
        child: field,
      ),
    );
  }
}

class _StarsInsetFocusRing extends StatelessWidget {
  const _StarsInsetFocusRing({
    required this.focusNode,
    required this.color,
    required this.borderRadius,
    required this.child,
  });

  final FocusNode focusNode;
  final Color color;
  final BorderRadiusGeometry borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      child: child,
      builder: (context, child) {
        return Stack(
          fit: StackFit.passthrough,
          children: [
            child!,
            if (focusNode.hasFocus)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey<String>(
                      'stars-search-inset-focus-ring',
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: color, width: 2),
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class StarsSearchEmptyState extends StatelessWidget {
  const StarsSearchEmptyState({
    super.key,
    required this.message,
    required this.clearLabel,
    required this.onClear,
  });

  final String message;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            LucideIcons.search,
            size: 28,
            color: StarsDesktopThemeSpec.mutedText(context),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: StarsDesktopThemeSpec.bodyStyle(context),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(LucideIcons.x, size: 16),
            label: Text(clearLabel),
          ),
        ],
      ),
    );
  }
}

/// Retained name for source compatibility; the visual is intentionally flat.
class DesktopEmptyStateCard extends StatelessWidget {
  static const double imageSize = 56;

  final IconData icon;
  final String title;
  final String description;
  final String? supportingText;
  final Widget? action;
  final String? imageAsset;
  final BorderRadius? imageBorderRadius;

  const DesktopEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.supportingText,
    this.action,
    this.imageAsset,
    this.imageBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final shadTheme = ShadTheme.maybeOf(context);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: tokens.primaryText,
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: tokens.secondaryText);

    Widget buildImage() {
      final image = Image.asset(
        imageAsset!,
        width: imageSize,
        height: imageSize,
        cacheWidth: imageSize.toInt() * 2,
        cacheHeight: imageSize.toInt() * 2,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) =>
                _EmptyStateIcon(icon: icon, tokens: tokens),
      );
      final radius = imageBorderRadius;
      return radius == null
          ? image
          : ClipRRect(
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: image,
          );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageAsset != null) ...[
          buildImage(),
          const SizedBox(height: 12),
        ] else ...[
          _EmptyStateIcon(icon: icon, tokens: tokens),
          const SizedBox(height: 16),
        ],
        Text(title, textAlign: TextAlign.center, style: titleStyle),
        const SizedBox(height: 8),
        Text(description, textAlign: TextAlign.center, style: bodyStyle),
        if (supportingText != null) ...[
          const SizedBox(height: 6),
          Text(
            supportingText!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.tertiaryText),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding:
                shadTheme == null ? EdgeInsets.zero : const EdgeInsets.all(8),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon({required this.icon, required this.tokens});

  final IconData icon;
  final StarsDesktopTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tokens.selectedFill,
          borderRadius: StarsDesktopThemeSpec.containerRadius,
        ),
        child: Icon(icon, size: 18, color: tokens.accent),
      ),
    );
  }
}

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
