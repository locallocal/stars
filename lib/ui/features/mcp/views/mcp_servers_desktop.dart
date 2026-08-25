part of 'mcp_servers_page.dart';

class _DesktopServerCard extends StatefulWidget {
  const _DesktopServerCard({
    super.key,
    required this.server,
    required this.tools,
    required this.busy,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onRefresh,
    required this.onDelete,
  });

  final McpServer server;
  final List<McpToolDescriptor> tools;
  final bool busy;
  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  @override
  State<_DesktopServerCard> createState() => _DesktopServerCardState();
}

class _DesktopServerCardState extends State<_DesktopServerCard> {
  static const double _menuContentWidth = 184;
  static const EdgeInsets _menuPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  final ShadPopoverController _menuController = ShadPopoverController();
  final FocusNode _menuFocusNode = FocusNode(
    debugLabel: 'desktop-mcp-server-card-actions',
  );
  bool _menuActionInvokedByPointer = false;
  bool _hovered = false;

  @override
  void didUpdateWidget(covariant _DesktopServerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.busy && widget.busy) _menuController.hide();
  }

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
                'desktop-mcp-server-action-menu-${widget.server.id}',
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
                        'desktop-mcp-server-details-${widget.server.id}',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed: () => _invokeMenuAction(widget.onOpenDetails),
                      mainAxisAlignment: MainAxisAlignment.start,
                      leading: const Icon(LucideIcons.info, size: 16),
                      child: Text(S.of(context).details),
                    ),
                    ShadButton.ghost(
                      key: ValueKey<String>(
                        'desktop-mcp-server-refresh-${widget.server.id}',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed:
                          widget.busy
                              ? null
                              : () => _invokeMenuAction(widget.onRefresh),
                      mainAxisAlignment: MainAxisAlignment.start,
                      leading: const Icon(LucideIcons.refreshCw, size: 16),
                      child: Text(S.of(context).refresh),
                    ),
                    ShadButton.ghost(
                      key: ValueKey<String>(
                        'desktop-mcp-server-edit-${widget.server.id}',
                      ),
                      size: ShadButtonSize.sm,
                      onPressed:
                          widget.busy
                              ? null
                              : () => _invokeMenuAction(widget.onEdit),
                      mainAxisAlignment: MainAxisAlignment.start,
                      leading: const Icon(LucideIcons.pencil, size: 16),
                      child: Text(S.of(context).edit),
                    ),
                    ShadButton.raw(
                      key: ValueKey<String>(
                        'desktop-mcp-server-delete-${widget.server.id}',
                      ),
                      variant: ShadButtonVariant.ghost,
                      size: ShadButtonSize.sm,
                      foregroundColor: colors.destructive,
                      onPressed:
                          widget.busy
                              ? null
                              : () => _invokeMenuAction(widget.onDelete),
                      mainAxisAlignment: MainAxisAlignment.start,
                      leading: const Icon(LucideIcons.trash2, size: 16),
                      child: Text(S.of(context).delete),
                    ),
                  ],
                ),
              ),
            ),
          ),
      child: StarsDesktopIconAction(
        key: ValueKey<String>('desktop-mcp-server-actions-${widget.server.id}'),
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
    final strings = S.of(context);
    final theme = ShadTheme.of(context);
    final tokens = StarsDesktopTokens.of(context);
    final statusColor = _statusColor(tokens, widget.server.status);

    return Semantics(
      button: true,
      label: widget.server.name,
      hint: strings.mcpServerDetails,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onOpenDetails,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            transform:
                _hovered
                    ? (Matrix4.identity()..translateByDouble(0, -2, 0, 1))
                    : Matrix4.identity(),
            child: ShadCard(
              width: double.infinity,
              backgroundColor: _hovered ? theme.colorScheme.accent : null,
              title: Row(
                children: [
                  if (widget.busy)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _mcpStatusIcon(widget.server.status),
                      size: 18,
                      color: statusColor,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.server.name,
                      key: ValueKey<String>(
                        'desktop-mcp-server-title-${widget.server.id}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StarsDesktopThemeSpec.pageTitleStyle(context),
                    ),
                  ),
                ],
              ),
              description: Text(
                mcpConnectionSummary(widget.server),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: Row(
                    key: ValueKey<String>(
                      'desktop-mcp-server-footer-${widget.server.id}',
                    ),
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _McpServerTag(
                              label: _mcpStatusLabel(
                                context,
                                widget.server.status,
                              ),
                              foregroundColor: statusColor,
                            ),
                            _McpServerTag(
                              label:
                                  widget.server.transport.type ==
                                          McpTransportType.stdio
                                      ? strings.mcpTransportStdio
                                      : strings.mcpTransportStreamableHttp,
                            ),
                            _McpServerTag(
                              label:
                                  '${widget.tools.length} ${strings.mcpTools}',
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

  Color _statusColor(StarsDesktopTokens tokens, McpConnectionStatus status) =>
      switch (status) {
        McpConnectionStatus.connected => tokens.success,
        McpConnectionStatus.connecting => tokens.warning,
        McpConnectionStatus.authorizationRequired => tokens.warning,
        McpConnectionStatus.error => tokens.danger,
        McpConnectionStatus.disconnected => tokens.secondaryText,
      };
}

class _McpServerDetailsDialog extends StatefulWidget {
  const _McpServerDetailsDialog({
    required this.server,
    required this.tools,
    required this.processInfo,
  });

  final McpServer server;
  final List<McpToolDescriptor> tools;
  final McpStdioProcessInfo? processInfo;

  @override
  State<_McpServerDetailsDialog> createState() =>
      _McpServerDetailsDialogState();
}

class _McpServerDetailsDialogState extends State<_McpServerDetailsDialog> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _query = '';

  @override
  void didUpdateWidget(covariant _McpServerDetailsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server.id != widget.server.id) {
      _clearSearch(requestFocus: false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (_query == query) return;
    setState(() => _query = query);
  }

  void _clearSearch({bool requestFocus = true}) {
    _searchController.clear();
    if (requestFocus) _searchFocusNode.requestFocus();
    if (_query.isNotEmpty) setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final tokens = StarsDesktopTokens.of(context);
    final server = widget.server;
    final tools = widget.tools;
    final filteredTools = filterMcpTools(tools, _query);
    final statusColor = switch (server.status) {
      McpConnectionStatus.connected => tokens.success,
      McpConnectionStatus.connecting => tokens.warning,
      McpConnectionStatus.authorizationRequired => tokens.warning,
      McpConnectionStatus.error => tokens.danger,
      McpConnectionStatus.disconnected => tokens.secondaryText,
    };

    return ShadDialog(
      key: ValueKey<String>('desktop-mcp-server-details-dialog-${server.id}'),
      closeIcon: StarsDesktopIconAction(
        key: ValueKey<String>('desktop-mcp-server-details-close-${server.id}'),
        icon: LucideIcons.x,
        iconSize: 18,
        label: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: () => Navigator.of(context).pop(),
      ),
      closeIconPosition: ShadPosition.directional(
        top: 12,
        end: 8,
        textDirection: Directionality.of(context),
      ),
      title: Text(
        server.name,
        key: ValueKey<String>('mcp-server-details-title-${server.id}'),
        style: StarsDesktopThemeSpec.pageTitleStyle(context),
      ),
      description: Text(
        mcpConnectionSummary(server),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      constraints: const BoxConstraints(maxWidth: 720),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
      child: SizedBox(
        height: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _McpServerTag(
                    label: _mcpStatusLabel(context, server.status),
                    foregroundColor: statusColor,
                  ),
                  _McpServerTag(
                    label:
                        server.transport.type == McpTransportType.stdio
                            ? strings.mcpTransportStdio
                            : strings.mcpTransportStreamableHttp,
                  ),
                  _McpServerTag(label: '${tools.length} ${strings.mcpTools}'),
                ],
              ),
              const SizedBox(height: 18),
              if (server.transport case McpStdioServerTransport transport) ...[
                _McpStdioRuntimeDetails(
                  serverId: server.id,
                  transport: transport,
                  processInfo: widget.processInfo,
                ),
                const SizedBox(height: 8),
              ],
              const ShadSeparator.horizontal(),
              const SizedBox(height: 18),
              Text(
                strings.mcpTools,
                key: ValueKey<String>('mcp-tools-title-${server.id}'),
                style: StarsDesktopThemeSpec.pageTitleStyle(
                  context,
                )?.copyWith(color: tokens.secondaryText),
              ),
              const SizedBox(height: 10),
              if (tools.isNotEmpty) ...[
                StarsSearchField(
                  key: ValueKey<String>('desktop-mcp-tool-search-${server.id}'),
                  hintText: strings.searchMcpTools,
                  semanticLabel: strings.searchMcpTools,
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _search,
                  insetFocusRing: true,
                  suffixIcon:
                      _query.isEmpty
                          ? null
                          : StarsDesktopIconAction(
                            key: ValueKey<String>(
                              'clear-desktop-mcp-tool-search-${server.id}',
                            ),
                            icon: LucideIcons.x,
                            label: strings.clearSearch,
                            onPressed: _clearSearch,
                            iconSize: 16,
                          ),
                ),
                const SizedBox(height: 12),
              ],
              if (tools.isEmpty)
                Text(
                  strings.noMcpToolsDiscovered,
                  style: StarsDesktopThemeSpec.metaStyle(context),
                )
              else if (filteredTools.isEmpty)
                StarsSearchEmptyState(
                  key: ValueKey<String>(
                    'desktop-mcp-tool-search-empty-${server.id}',
                  ),
                  message: strings.noMatchingMcpTools,
                  clearLabel: strings.clearSearch,
                  onClear: _clearSearch,
                )
              else
                for (var index = 0; index < filteredTools.length; index++) ...[
                  _DesktopMcpToolCard(
                    key: ValueKey<String>(
                      'desktop-mcp-tool-${server.id}-${filteredTools[index].remoteName}',
                    ),
                    tool: filteredTools[index],
                  ),
                  if (index != filteredTools.length - 1)
                    const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _McpStdioRuntimeDetails extends StatelessWidget {
  const _McpStdioRuntimeDetails({
    required this.serverId,
    required this.transport,
    required this.processInfo,
  });

  final String serverId;
  final McpStdioServerTransport transport;
  final McpStdioProcessInfo? processInfo;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final info = processInfo;
    final arguments = info?.arguments ?? transport.arguments;
    return Column(
      key: ValueKey<String>('mcp-stdio-runtime-$serverId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.mcpStdioProcessAndChannel,
          key: ValueKey<String>('mcp-stdio-runtime-title-$serverId'),
          style: StarsDesktopThemeSpec.pageTitleStyle(
            context,
          )?.copyWith(color: StarsDesktopTokens.of(context).secondaryText),
        ),
        const SizedBox(height: 12),
        _McpServerDetailRow(
          label: strings.mcpProcessStatus,
          value:
              info == null
                  ? strings.mcpProcessNotRunning
                  : strings.mcpProcessRunning,
        ),
        _McpServerDetailRow(
          label: strings.mcpProcessId,
          value: info?.processId.toString() ?? '—',
        ),
        _McpServerDetailRow(
          label: strings.mcpCommand,
          value: info?.command ?? transport.command,
        ),
        _McpServerDetailRow(
          label: strings.mcpArguments,
          value: arguments.isEmpty ? '—' : arguments.join('\n'),
        ),
        _McpServerDetailRow(
          label: strings.mcpProcessStartedAt,
          value:
              info == null ? '—' : _formatMcpProcessStartedAt(info.startedAt),
        ),
        _McpServerDetailRow(
          label: strings.mcpSecureEnvironmentVariables,
          value:
              info == null
                  ? '—'
                  : strings.mcpHiddenEnvironmentVariableCount(
                    info.environmentVariableCount,
                  ),
        ),
        _McpServerDetailRow(
          label: strings.mcpCommunicationChannel,
          value: strings.mcpStdioPipeChannel,
        ),
      ],
    );
  }
}

class _McpServerDetailRow extends StatelessWidget {
  const _McpServerDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 168,
            child: Text(label, style: ShadTheme.of(context).textTheme.muted),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

String _formatMcpProcessStartedAt(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}:'
      '${twoDigits(local.second)}';
}

class _McpServerTag extends StatelessWidget {
  const _McpServerTag({required this.label, this.foregroundColor});

  final String label;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return ShadBadge.outline(
      foregroundColor: foregroundColor,
      child: Text(label),
    );
  }
}

class _DesktopMcpToolCard extends StatelessWidget {
  const _DesktopMcpToolCard({super.key, required this.tool});

  final McpToolDescriptor tool;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final supported = tool.isSupportedByClient;
    final title = tool.title.isEmpty ? tool.remoteName : tool.title;

    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      backgroundColor: tokens.controlFill,
      border: ShadBorder.all(color: tokens.separator, width: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              tool.annotations.destructiveHint
                  ? LucideIcons.triangleAlert
                  : tool.annotations.readOnlyHint
                  ? LucideIcons.eye
                  : LucideIcons.pencil,
              size: 16,
              color:
                  tool.annotations.destructiveHint
                      ? tokens.warning
                      : tokens.secondaryText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ShadTheme.of(
                    context,
                  ).textTheme.small.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  tool.canonicalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StarsDesktopThemeSpec.metaStyle(context),
                ),
                if (tool.description.isNotEmpty || !supported) ...[
                  const SizedBox(height: 4),
                  Text(
                    supported
                        ? tool.description
                        : S.of(context).mcpToolSchemaUnsupported,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StarsDesktopThemeSpec.metaStyle(context)?.copyWith(
                      color: supported ? tokens.secondaryText : tokens.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
