part of 'skill_library.dart';

class _DesktopSkillCard extends StatefulWidget {
  const _DesktopSkillCard({
    required this.skill,
    required this.hasScriptTools,
    required this.scriptEnabled,
    required this.update,
    required this.onOpen,
    required this.onTest,
    required this.onUninstall,
    required this.onToggleScripts,
    required this.onUpdate,
  });

  final SkillDescriptor skill;
  final bool hasScriptTools;
  final bool scriptEnabled;
  final OnlineSkillCatalogEntry? update;
  final VoidCallback onOpen;
  final VoidCallback onTest;
  final VoidCallback? onUninstall;
  final VoidCallback onToggleScripts;
  final VoidCallback? onUpdate;

  @override
  State<_DesktopSkillCard> createState() => _DesktopSkillCardState();
}

class _DesktopSkillCardState extends State<_DesktopSkillCard> {
  static const double _menuContentWidth = 184;
  static const EdgeInsets _menuPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  final ShadPopoverController _menuController = ShadPopoverController();
  final FocusNode _menuFocusNode = FocusNode(
    debugLabel: 'desktop-skill-card-actions',
  );
  bool _menuActionInvokedByPointer = false;
  bool _hovered = false;

  @override
  void dispose() {
    _menuController.dispose();
    _menuFocusNode.dispose();
    super.dispose();
  }

  void _invokeMenuAction(VoidCallback action) {
    final invokedByPointer = _menuActionInvokedByPointer;
    _menuActionInvokedByPointer = false;
    if (invokedByPointer) {
      FocusManager.instance.primaryFocus?.unfocus();
      _menuFocusNode.unfocus();
    }
    _menuController.hide();
    action();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!invokedByPointer &&
          FocusManager.instance.highlightMode ==
              FocusHighlightMode.traditional) {
        _menuFocusNode.requestFocus();
      } else {
        _menuFocusNode.unfocus();
      }
    });
  }

  Widget _buildActionMenu(BuildContext context) {
    final colors = ShadTheme.of(context).colorScheme;
    return ShadPopover(
      controller: _menuController,
      anchor: const ShadAnchorAuto(
        offset: Offset(0, 4),
        followerAnchor: AlignmentDirectional.topStart,
        targetAnchor: AlignmentDirectional.bottomEnd,
        fallback: ShadAnchorAuto(
          offset: Offset(0, -4),
          followerAnchor: AlignmentDirectional.bottomStart,
          targetAnchor: AlignmentDirectional.topEnd,
        ),
      ),
      padding: EdgeInsets.zero,
      popover:
          (context) => Listener(
            onPointerDown: (_) => _menuActionInvokedByPointer = true,
            onPointerUp:
                (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
                  _menuActionInvokedByPointer = false;
                }),
            onPointerCancel: (_) => _menuActionInvokedByPointer = false,
            child: SizedBox(
              key: ValueKey<String>(
                'desktop-skill-action-menu-${widget.skill.id}',
              ),
              width: _menuContentWidth + _menuPadding.horizontal,
              child: Padding(
                padding: _menuPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShadButton.ghost(
                      key: ValueKey<String>(
                        'desktop-skill-details-${widget.skill.id}',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: () => _invokeMenuAction(widget.onOpen),
                      mainAxisAlignment: MainAxisAlignment.start,
                      leading: const Icon(LucideIcons.info, size: 16),
                      child: Text(S.of(context).details),
                    ),
                    ShadButton.ghost(
                      key: ValueKey<String>(
                        'desktop-skill-test-${widget.skill.id}',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: () => _invokeMenuAction(widget.onTest),
                      mainAxisAlignment: MainAxisAlignment.start,
                      leading: const Icon(LucideIcons.flaskConical, size: 16),
                      child: Text(S.of(context).testSkill),
                    ),
                    if (widget.hasScriptTools)
                      ShadButton.ghost(
                        key: ValueKey<String>(
                          'desktop-skill-script-${widget.skill.id}',
                        ),
                        size: ShadButtonSize.sm,
                        onPressed:
                            () => _invokeMenuAction(widget.onToggleScripts),
                        mainAxisAlignment: MainAxisAlignment.start,
                        leading: Icon(
                          widget.scriptEnabled
                              ? LucideIcons.circleStop
                              : LucideIcons.play,
                          size: 16,
                        ),
                        child: Text(
                          widget.scriptEnabled
                              ? S.of(context).disableSkillScripts
                              : S.of(context).enableSkillScripts,
                        ),
                      ),
                    if (widget.onUpdate != null)
                      ShadButton.ghost(
                        key: ValueKey<String>(
                          'desktop-skill-update-${widget.skill.id}',
                        ),
                        size: ShadButtonSize.sm,
                        onPressed: () => _invokeMenuAction(widget.onUpdate!),
                        mainAxisAlignment: MainAxisAlignment.start,
                        leading: const Icon(LucideIcons.download, size: 16),
                        child: Text(S.of(context).installSkillUpdate),
                      ),
                    if (widget.onUninstall != null)
                      ShadButton.raw(
                        key: ValueKey<String>(
                          'desktop-skill-uninstall-${widget.skill.id}',
                        ),
                        variant: ShadButtonVariant.ghost,
                        size: ShadButtonSize.sm,
                        foregroundColor: colors.destructive,
                        onPressed: () => _invokeMenuAction(widget.onUninstall!),
                        mainAxisAlignment: MainAxisAlignment.start,
                        leading: const Icon(LucideIcons.trash2, size: 16),
                        child: Text(S.of(context).uninstall),
                      ),
                  ],
                ),
              ),
            ),
          ),
      child: StarsDesktopIconAction(
        key: ValueKey<String>('desktop-skill-menu-button-${widget.skill.id}'),
        icon: LucideIcons.ellipsis,
        label: MaterialLocalizations.of(context).showMenuTooltip,
        focusNode: _menuFocusNode,
        onPressed: _menuController.toggle,
        hoverBackgroundColor: Colors.transparent,
        showFocusRing: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = ShadTheme.of(context);
    return Semantics(
      button: true,
      label: widget.skill.name,
      hint: strings.skillDetails,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onOpen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            transform:
                _hovered
                    ? (Matrix4.identity()..translateByDouble(0, -2, 0, 1))
                    : Matrix4.identity(),
            child: ShadCard(
              key: ValueKey<String>('desktop-skill-card-${widget.skill.id}'),
              width: double.infinity,
              backgroundColor: _hovered ? theme.colorScheme.accent : null,
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.skill.name,
                      key: ValueKey<String>(
                        'desktop-skill-card-title-${widget.skill.id}',
                      ),
                      style: const TextStyle(
                        fontSize: StarsDesktopThemeSpec.pageTitleFontSize,
                      ),
                    ),
                  ),
                  if (widget.skill.version.isNotEmpty)
                    _SkillCardTag(label: 'v${widget.skill.version}'),
                ],
              ),
              description: Text(
                widget.skill.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: Row(
                    key: ValueKey<String>(
                      'desktop-skill-card-footer-${widget.skill.id}',
                    ),
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (widget.skill.scope == SkillScope.bundled)
                              _SkillCardTag(label: strings.toolSourceBuiltIn)
                            else if (widget.skill.version.isEmpty)
                              _SkillCardTag(label: strings.skillUserScope),
                            if (widget.hasScriptTools)
                              widget.scriptEnabled
                                  ? _SkillCardTag(
                                    label: strings.skillScriptsEnabled,
                                  )
                                  : _SkillCardTag(
                                    label: strings.skillScriptsDisabled,
                                  ),
                            if (widget.update != null)
                              _SkillCardTag(
                                label: strings.skillUpdateAvailable,
                              ),
                            if (widget.skill.scope != SkillScope.bundled &&
                                widget.skill.signatureStatus ==
                                    SkillSignatureStatus.verified)
                              _SkillCardTag(
                                label: strings.skillSignatureVerified,
                              ),
                            if (widget.skill.scope != SkillScope.bundled &&
                                widget.skill.signatureStatus ==
                                    SkillSignatureStatus.unsigned)
                              _SkillCardTag(
                                label: strings.skillSignatureUnsigned,
                              ),
                            if (widget.skill.scope != SkillScope.bundled &&
                                widget.skill.signatureStatus ==
                                    SkillSignatureStatus.unknownPublisher)
                              _SkillCardTag(
                                label: strings.skillSignatureUnknownPublisher,
                              ),
                            if (widget.skill.scope != SkillScope.bundled &&
                                widget.skill.signatureStatus ==
                                    SkillSignatureStatus.invalid)
                              _SkillCardTag(
                                label: strings.skillSignatureInvalid,
                              ),
                            if (widget.skill.hasReferences)
                              _SkillCardTag(
                                label: strings.skillReferencesAvailable,
                              ),
                            if (widget.skill.hasAssets)
                              _SkillCardTag(
                                label: strings.skillAssetsAvailable,
                              ),
                            if (widget.skill.diagnostics.isNotEmpty)
                              _SkillCardTag(
                                label:
                                    '${strings.skillValidationWarnings} '
                                    '${widget.skill.diagnostics.length}',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildActionMenu(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillCardTag extends StatelessWidget {
  const _SkillCardTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ShadBadge.outline(child: Text(label));
  }
}
