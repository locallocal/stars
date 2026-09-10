part of 'desktop_layout.dart';

class _DesktopResizeHandle extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onResize;
  final VoidCallback onReset;

  const _DesktopResizeHandle({
    super.key,
    required this.label,
    required this.value,
    required this.onResize,
    required this.onReset,
  });

  @override
  State<_DesktopResizeHandle> createState() => _DesktopResizeHandleState();
}

class _DesktopResizeHandleState extends State<_DesktopResizeHandle> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _hovered = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _moveHandle(double delta) {
    widget.onResize(delta);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 24.0 : 8.0;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveHandle(-step);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveHandle(step);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Semantics(
      label: widget.label,
      value: '${widget.value.round()} px',
      increasedValue: '${(widget.value + 8).round()} px',
      decreasedValue: '${math.max(0, widget.value - 8).round()} px',
      focusable: true,
      focused: _focused,
      onIncrease: () => widget.onResize(8),
      onDecrease: () => widget.onResize(-8),
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _focusNode.requestFocus,
            onDoubleTap: () {
              _focusNode.requestFocus();
              widget.onReset();
            },
            onHorizontalDragStart: (_) => _focusNode.requestFocus(),
            onHorizontalDragUpdate: (details) => _moveHandle(details.delta.dx),
            child: SizedBox(
              width: StarsDesktopThemeSpec.splitterHitWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color:
                          _focused
                              ? scheme.ring
                              : _hovered
                              ? scheme.foreground.withValues(alpha: 0.35)
                              : scheme.border,
                      child: SizedBox(width: _focused ? 3 : 1),
                    ),
                  ),
                  if (_focused)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: scheme.border,
                        child: const SizedBox(width: 1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarDestination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBackground = StarsDesktopThemeSpec.inactivePrimaryActionColor(
      context,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: SizedBox(
        width: double.infinity,
        child: ShadButton.raw(
          variant:
              selected ? ShadButtonVariant.primary : ShadButtonVariant.ghost,
          size: ShadButtonSize.sm,
          height: StarsDesktopThemeSpec.botFormFieldHeight,
          backgroundColor: selected ? selectedBackground : null,
          hoverBackgroundColor: selected ? selectedBackground : null,
          pressedBackgroundColor: selected ? selectedBackground : null,
          foregroundColor:
              selected
                  ? ShadTheme.of(context).colorScheme.primaryForeground
                  : null,
          hoverForegroundColor:
              selected
                  ? ShadTheme.of(context).colorScheme.primaryForeground
                  : null,
          pressedForegroundColor:
              selected
                  ? ShadTheme.of(context).colorScheme.primaryForeground
                  : null,
          mainAxisAlignment: MainAxisAlignment.start,
          expands: true,
          onPressed: onTap,
          child: _SidebarButtonContent(icon: icon, label: label),
        ),
      ),
    );
  }
}

class _SidebarButtonContent extends StatelessWidget {
  const _SidebarButtonContent({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Icon(icon, size: 16),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _AccountButton extends StatelessWidget {
  final bool selected;
  final bool useLucideIcon;
  final VoidCallback onTap;

  const _AccountButton({
    required this.selected,
    required this.useLucideIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopInteractiveListItem(
      selected: selected,
      minHeight: StarsDesktopThemeSpec.botFormFieldHeight,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundImage: ResizeImage(
              AssetImage('assets/images/profile/avatar.png'),
              width: 60,
              height: 60,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(S.of(context).profile)),
          Icon(
            useLucideIcon ? LucideIcons.settings : LucideIcons.settings,
            size: 17,
          ),
        ],
      ),
    );
  }
}

class _ConversationInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConversationInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => StarsInspectorInfoRow(
    icon: icon,
    label: label,
    value: value,
    layout: StarsInspectorInfoRowLayout.settings,
  );
}

class _ConversationInformationHeader extends StatelessWidget {
  const _ConversationInformationHeader({required this.bot});

  final Bot bot;

  @override
  Widget build(BuildContext context) {
    final provider = bot.provider.trim();
    final model = bot.model.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.of(context).conversationInformation,
          key: const ValueKey<String>('desktop-conversation-information-title'),
          style: StarsDesktopThemeSpec.pageTitleStyle(context),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: ShadAvatar(
                key: const ValueKey<String>(
                  'desktop-conversation-information-avatar',
                ),
                bot.avatar.isEmpty ? null : File(bot.avatar),
                size: const Size.square(40),
                backgroundColor: getFrostedProviderColor(
                  provider,
                  Theme.of(context).colorScheme.primary,
                ),
                placeholder: buildProviderLogo(context, '', provider, 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bot.name,
                    key: const ValueKey<String>(
                      'desktop-conversation-information-description',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StarsDesktopThemeSpec.bodyStyle(
                      context,
                    )?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (provider.isNotEmpty || model.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (provider.isNotEmpty)
                          _ConversationMetadataBadge(
                            key: const ValueKey<String>(
                              'desktop-conversation-provider-badge',
                            ),
                            label: S.of(context).provider,
                            value: provider,
                          ),
                        if (model.isNotEmpty)
                          _ConversationMetadataBadge(
                            key: const ValueKey<String>(
                              'desktop-conversation-model-badge',
                            ),
                            label: S.of(context).model,
                            value: model,
                            emphasized: true,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConversationMetadataBadge extends StatelessWidget {
  const _ConversationMetadataBadge({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final badgeText = Text(value, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child:
          emphasized
              ? ShadBadge.secondary(child: badgeText)
              : ShadBadge.outline(child: badgeText),
    );
  }
}
