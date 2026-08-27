part of 'bots.dart';

class _DesktopBotCard extends StatefulWidget {
  const _DesktopBotCard({
    required this.bot,
    required this.metrics,
    required this.subtitle,
    required this.onOpen,
    required this.onEdit,
    required this.onStartChat,
    required this.onDelete,
  });

  final Bot bot;
  final BotCardMetrics metrics;
  final String subtitle;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onStartChat;
  final VoidCallback onDelete;

  @override
  State<_DesktopBotCard> createState() => _DesktopBotCardState();
}

class _DesktopBotCardState extends State<_DesktopBotCard> {
  static const double _menuContentWidth = 184;
  static const double _menuIconAlignmentOffset = 13;
  static const EdgeInsets _menuPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  final ShadPopoverController _menuController = ShadPopoverController();
  final FocusNode _menuFocusNode = FocusNode(
    debugLabel: 'desktop-bot-card-actions',
  );
  bool _hovered = false;

  @override
  void dispose() {
    _menuController.dispose();
    _menuFocusNode.dispose();
    super.dispose();
  }

  void _invokeMenuAction(VoidCallback action) {
    _menuController.hide();
    action();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (FocusManager.instance.highlightMode ==
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
          (context) => SizedBox(
            key: ValueKey<String>('desktop-bot-action-menu-${widget.bot.id}'),
            width: _menuContentWidth + _menuPadding.horizontal,
            child: Padding(
              padding: _menuPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    onPressed: () => _invokeMenuAction(widget.onStartChat),
                    mainAxisAlignment: MainAxisAlignment.start,
                    leading: const Icon(desktopStartConversationIcon, size: 16),
                    child: Text(
                      desktopConversationText(
                        context,
                        S.of(context).startChatting,
                      ),
                    ),
                  ),
                  ShadButton.ghost(
                    key: ValueKey<String>(
                      'desktop-bot-details-${widget.bot.id}',
                    ),
                    size: ShadButtonSize.sm,
                    onPressed: () => _invokeMenuAction(widget.onOpen),
                    mainAxisAlignment: MainAxisAlignment.start,
                    leading: const Icon(LucideIcons.info, size: 16),
                    child: Text(S.of(context).details),
                  ),
                  ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    onPressed: () => _invokeMenuAction(widget.onEdit),
                    mainAxisAlignment: MainAxisAlignment.start,
                    leading: const Icon(LucideIcons.pencil, size: 16),
                    child: Text(S.of(context).edit),
                  ),
                  ShadButton.raw(
                    variant: ShadButtonVariant.ghost,
                    size: ShadButtonSize.sm,
                    foregroundColor: colors.destructive,
                    onPressed: () => _invokeMenuAction(widget.onDelete),
                    mainAxisAlignment: MainAxisAlignment.start,
                    leading: const Icon(LucideIcons.trash2, size: 16),
                    child: Text(S.of(context).delete),
                  ),
                ],
              ),
            ),
          ),
      child: StarsDesktopIconAction(
        key: ValueKey<String>('desktop-bot-menu-button-${widget.bot.id}'),
        icon: LucideIcons.ellipsis,
        label: MaterialLocalizations.of(context).showMenuTooltip,
        focusNode: _menuFocusNode,
        onPressed: _menuController.toggle,
        hoverBackgroundColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final numberFormat = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    final mcpServerNames = widget.metrics.mcpServerNames;
    return Semantics(
      button: true,
      label: widget.bot.name,
      hint: S.of(context).selectBot,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: StarsContextMenu(
          items: [
            ShadContextMenuItem(
              leading: const Icon(desktopStartConversationIcon, size: 16),
              onPressed: widget.onStartChat,
              child: Text(
                desktopConversationText(context, S.of(context).startChatting),
              ),
            ),
            ShadContextMenuItem(
              leading: const Icon(LucideIcons.info, size: 16),
              onPressed: widget.onOpen,
              child: Text(S.of(context).details),
            ),
            ShadContextMenuItem(
              leading: const Icon(LucideIcons.pencil, size: 16),
              onPressed: widget.onEdit,
              child: Text(S.of(context).editBot),
            ),
            ShadContextMenuItem(
              leading: const Icon(LucideIcons.trash2, size: 16),
              onPressed: widget.onDelete,
              child: Text(S.of(context).deleteBot),
            ),
          ],
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onOpen,
            child: ShadCard(
              key: ValueKey<String>('desktop-bot-card-${widget.bot.id}'),
              padding: const EdgeInsets.all(18),
              backgroundColor: _hovered ? theme.colorScheme.accent : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShadAvatar(
                        widget.bot.avatar.isEmpty
                            ? null
                            : File(widget.bot.avatar),
                        size: const Size.square(44),
                        backgroundColor: getFrostedProviderColor(
                          widget.bot.provider,
                          Theme.of(context).colorScheme.primary,
                        ),
                        placeholder: buildProviderLogo(
                          context,
                          '',
                          widget.bot.provider,
                          22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          key: ValueKey<String>(
                            'bot-card-identity-${widget.bot.id}',
                          ),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bot.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.h4,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.muted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    key: ValueKey<String>(
                      'bot-card-information-panel-${widget.bot.id}',
                    ),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: StarsDesktopThemeSpec.controlFill(context),
                      borderRadius: StarsDesktopThemeSpec.controlRadius,
                    ),
                    child: Column(
                      children: [
                        Row(
                          key: ValueKey<String>(
                            'bot-card-model-features-${widget.bot.id}',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _BotCardMetric(
                                key: ValueKey<String>(
                                  'bot-card-context-window-${widget.bot.id}',
                                ),
                                icon: LucideIcons.braces,
                                name: S.of(context).modelContextWindow,
                                value:
                                    widget.metrics.contextWindowTokens == null
                                        ? '—'
                                        : numberFormat.format(
                                          widget.metrics.contextWindowTokens,
                                        ),
                                separatorKey: ValueKey<String>(
                                  'bot-card-context-window-separator-${widget.bot.id}',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: ModelModalitiesView(
                                inputModalities: widget.metrics.inputModalities,
                                outputModalities:
                                    widget.metrics.outputModalities,
                                keyPrefix:
                                    'bot-card-modalities-${widget.bot.id}',
                                density: ModelModalitiesDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          key: ValueKey<String>(
                            'bot-card-information-divider-${widget.bot.id}',
                          ),
                          width: double.infinity,
                          height: 1,
                          color: StarsDesktopThemeSpec.divider(context),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          key: ValueKey<String>(
                            'bot-card-usage-features-${widget.bot.id}',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _BotCardMetric(
                                key: ValueKey<String>(
                                  'bot-card-token-total-${widget.bot.id}',
                                ),
                                icon: Icons.data_usage_rounded,
                                name: S.of(context).totalTokens,
                                value: numberFormat.format(
                                  widget
                                      .metrics
                                      .tokenUsage
                                      .effectiveTotalTokens,
                                ),
                                separatorKey: ValueKey<String>(
                                  'bot-card-token-total-separator-${widget.bot.id}',
                                ),
                              ),
                            ),
                            Expanded(
                              child: _BotCardMetric(
                                key: ValueKey<String>(
                                  'bot-card-skill-count-${widget.bot.id}',
                                ),
                                icon: LucideIcons.wrench,
                                name: S.of(context).botSkills,
                                value: '${widget.metrics.skillCount}',
                                separatorKey: ValueKey<String>(
                                  'bot-card-skill-count-separator-${widget.bot.id}',
                                ),
                              ),
                            ),
                            Expanded(
                              child: _BotCardMetric(
                                key: ValueKey<String>(
                                  'bot-card-mcp-count-${widget.bot.id}',
                                ),
                                icon: Icons.hub_outlined,
                                name: S.of(context).mcpServers,
                                value: '${mcpServerNames.length}',
                                separatorKey: ValueKey<String>(
                                  'bot-card-mcp-count-separator-${widget.bot.id}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    key: ValueKey<String>(
                      'desktop-bot-card-footer-${widget.bot.id}',
                    ),
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BotCardMetric(
                        key: ValueKey<String>(
                          'bot-card-creation-time-${widget.bot.id}',
                        ),
                        icon: LucideIcons.clock3,
                        name: S.of(context).creationTime,
                        value: formatTimestamp(
                          context,
                          widget.bot.createTimestamp,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _BotCardMetric(
                        key: ValueKey<String>(
                          'bot-card-modification-time-${widget.bot.id}',
                        ),
                        icon: LucideIcons.history,
                        name: S.of(context).modificationTime,
                        value: formatTimestamp(
                          context,
                          widget.bot.modifyTimestamp,
                        ),
                      ),
                      const Spacer(),
                      Transform.translate(
                        offset: const Offset(_menuIconAlignmentOffset, 0),
                        child: _buildActionMenu(context),
                      ),
                    ],
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
