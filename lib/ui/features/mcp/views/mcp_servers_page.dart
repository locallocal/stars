import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/mcp/view_models/mcp_servers_view_model.dart';
import 'package:stars/utils/mcp_search.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

part 'mcp_servers_desktop.dart';
part 'mcp_servers_mobile.dart';
part 'mcp_server_editor.dart';

class McpServersPage extends StatefulWidget {
  const McpServersPage({super.key, this.viewModel});

  final McpServersViewModel? viewModel;

  @override
  State<McpServersPage> createState() => _McpServersPageState();
}

class _McpServersPageState extends State<McpServersPage> {
  McpServersViewModel? _resolvedViewModel;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _query = '';
  bool _initialized = false;

  McpServersViewModel get _viewModel => widget.viewModel ?? _resolvedViewModel!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _resolvedViewModel =
        widget.viewModel ?? AppScope.of(context).createMcpServersViewModel();
    _viewModel.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    if (widget.viewModel == null) _resolvedViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder:
          (context, _) =>
              isDesktopPlatform(context)
                  ? _buildDesktop(context)
                  : _buildMobile(context),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).mcpServers,
          key: const ValueKey<String>('mcp-servers-title'),
          style: StarsDesktopThemeSpec.pageTitleStyle(context),
        ),
        actions: [
          IconButton(
            tooltip: S.of(context).addMcpServer,
            onPressed: () => _showEditor(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(),
        icon: const Icon(Icons.add_rounded),
        label: Text(S.of(context).addMcpServer),
      ),
      body: _buildMobileBody(context),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final strings = S.of(context);
    final filteredServers = _filteredServers;
    final compactInUseError =
        _viewModel.error?.code == 'mcp_server_in_use_by_bot' &&
        _viewModel.warning == null;
    const contentMaxWidth = StarsDesktopThemeSpec.formContentMaxWidth;
    const pagePadding = StarsDesktopThemeSpec.formPagePadding;
    return ColoredBox(
      color: StarsDesktopThemeSpec.workspaceSurface(context),
      child: RefreshIndicator(
        onRefresh: _viewModel.load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final centeredInset = (constraints.maxWidth - contentMaxWidth) / 2;
            final horizontalInset =
                centeredInset > pagePadding.left
                    ? centeredInset
                    : pagePadding.left;
            return CustomScrollView(
              key: const ValueKey<String>('mcp-servers-desktop-page'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset,
                    pagePadding.top,
                    horizontalInset,
                    pagePadding.bottom,
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          key: const ValueKey<String>(
                            'mcp-servers-desktop-content',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.mcpServers,
                                        key: const ValueKey<String>(
                                          'mcp-servers-title',
                                        ),
                                        style:
                                            StarsDesktopThemeSpec.pageTitleStyle(
                                              context,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        strings.mcpServersDescription,
                                        style: StarsDesktopThemeSpec.bodyStyle(
                                          context,
                                        )?.copyWith(
                                          color:
                                              StarsDesktopThemeSpec.mutedText(
                                                context,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ShadButton(
                                  key: const ValueKey<String>(
                                    'add-mcp-server-desktop',
                                  ),
                                  onPressed: () => _showEditor(),
                                  leading: const Icon(
                                    LucideIcons.plus,
                                    size: 16,
                                  ),
                                  child: Text(strings.addMcpServer),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ShadAlert(
                              icon: const Icon(LucideIcons.shieldCheck),
                              title: Text(strings.mcpLocalProcessSecurityTitle),
                              description: Text(
                                strings.mcpLocalProcessSecurityDescription,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDesktopSearchField(context),
                            const SizedBox(height: 16),
                            Text(
                              strings.mcpProgressiveDiscoveryDescription,
                              style: StarsDesktopThemeSpec.bodyStyle(
                                context,
                              )?.copyWith(
                                color: StarsDesktopThemeSpec.mutedText(context),
                              ),
                            ),
                            if (_viewModel.error case final error?) ...[
                              SizedBox(
                                height:
                                    error.code == 'mcp_server_in_use_by_bot'
                                        ? 8
                                        : 16,
                              ),
                              _buildDesktopErrorAlert(error),
                            ],
                            if (_viewModel.warning != null) ...[
                              const SizedBox(height: 16),
                              ShadAlert(
                                key: const ValueKey<String>(
                                  'mcp-warning-alert',
                                ),
                                icon: const Icon(LucideIcons.triangleAlert),
                                title: Text(_errorMessage(_viewModel.warning!)),
                                trailing: StarsDesktopIconAction(
                                  onPressed: _viewModel.clearWarning,
                                  icon: LucideIcons.x,
                                  label:
                                      MaterialLocalizations.of(
                                        context,
                                      ).closeButtonTooltip,
                                  iconSize: 16,
                                ),
                              ),
                            ],
                            SizedBox(height: compactInUseError ? 10 : 24),
                          ],
                        ),
                      ),
                      if (_viewModel.isLoading)
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: ShadProgress(),
                            ),
                          ),
                        )
                      else if (_viewModel.servers.isEmpty)
                        SliverToBoxAdapter(
                          child: DesktopEmptyStateCard(
                            icon: Icons.hub_outlined,
                            title: strings.noMcpServers,
                            description: strings.noMcpServersDescription,
                            action: ShadButton(
                              key: const ValueKey<String>(
                                'add-mcp-server-empty-desktop',
                              ),
                              onPressed: () => _showEditor(),
                              leading: const Icon(LucideIcons.plus, size: 16),
                              child: Text(strings.addMcpServer),
                            ),
                          ),
                        )
                      else if (filteredServers.isEmpty)
                        SliverToBoxAdapter(
                          child: _buildDesktopSearchEmpty(context),
                        )
                      else
                        _buildDesktopServers(filteredServers),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopErrorAlert(AppFailure error) {
    final message = _errorMessage(error);
    if (error.code != 'mcp_server_in_use_by_bot') {
      return ShadAlert.destructive(
        key: const ValueKey<String>('mcp-error-alert'),
        crossAxisAlignment: CrossAxisAlignment.center,
        icon: const Icon(LucideIcons.circleAlert),
        title: Text(message),
        trailing: StarsDesktopIconAction(
          key: const ValueKey<String>('close-mcp-error'),
          icon: LucideIcons.x,
          label: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: _viewModel.clearError,
          iconSize: 16,
        ),
      );
    }

    return SizedBox(
      key: const ValueKey<String>('mcp-error-region'),
      width: double.infinity,
      child: StarsInlineErrorAlert(
        error: message,
        isDesktop: true,
        onDismiss: _viewModel.clearError,
        alertKey: const ValueKey<String>('mcp-error-alert'),
        messageKey: const ValueKey<String>('mcp-error-message'),
        dismissKey: const ValueKey<String>('close-mcp-error'),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDesktopSearchField(BuildContext context) {
    final strings = S.of(context);
    return StarsSearchField(
      key: const ValueKey<String>('mcp-search-field'),
      hintText: strings.searchMcpServers,
      semanticLabel: strings.searchMcpServers,
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: _search,
      suffixIcon:
          _query.isNotEmpty
              ? StarsDesktopIconAction(
                key: const ValueKey<String>('clear-mcp-search'),
                icon: LucideIcons.x,
                label: strings.clearSearch,
                onPressed: _clearSearch,
                iconSize: 16,
              )
              : null,
    );
  }

  Widget _buildDesktopSearchEmpty(BuildContext context) {
    final strings = S.of(context);
    return DesktopEmptyStateCard(
      icon: LucideIcons.search,
      title: strings.noMatchingMcpServers,
      description: strings.tryDifferentSearch,
      action: ShadButton(
        size: ShadButtonSize.sm,
        onPressed: _clearSearch,
        leading: const Icon(LucideIcons.x, size: 16),
        child: Text(strings.clearSearch),
      ),
    );
  }

  Widget _buildDesktopServers(List<McpServer> servers) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.crossAxisExtent >= 800 ? 2 : 1;
        const gap = 14.0;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: StarsDesktopThemeSpec.managementCardHeight,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final server = servers[index];
            return _DesktopServerCard(
              key: ValueKey<String>('desktop-mcp-server-${server.id}'),
              server: server,
              tools: _viewModel.toolsFor(server.id),
              busy: _viewModel.busyServerId == server.id,
              onOpenDetails: () => _showDetails(server),
              onEdit: () => _showEditor(server),
              onRefresh: () => _viewModel.refresh(server.id),
              onDelete: () => _confirmDelete(server),
            );
          }, childCount: servers.length),
        );
      },
    );
  }

  List<McpServer> get _filteredServers {
    return filterMcpServers(
      _viewModel.servers,
      _query,
      toolsForServer: _viewModel.toolsFor,
    );
  }

  void _search(String query) {
    if (_query == query) return;
    setState(() => _query = query);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
    if (_query.isNotEmpty) setState(() => _query = '');
  }

  Widget _buildMobileBody(BuildContext context) {
    if (_viewModel.isLoading && _viewModel.servers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _viewModel.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _SecurityNotice(
            title:
                isDesktopPlatform(context)
                    ? S.of(context).mcpLocalProcessSecurityTitle
                    : S.of(context).remoteMcpOnly,
            description:
                isDesktopPlatform(context)
                    ? S.of(context).mcpLocalProcessSecurityDescription
                    : S.of(context).localMcpDisabledDescription,
          ),
          const SizedBox(height: 12),
          Text(
            S.of(context).mcpProgressiveDiscoveryDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_viewModel.error != null) ...[
            const SizedBox(height: 12),
            _ErrorNotice(message: _errorMessage(_viewModel.error!)),
          ],
          if (_viewModel.warning != null) ...[
            const SizedBox(height: 12),
            _ErrorNotice(message: _errorMessage(_viewModel.warning!)),
          ],
          const SizedBox(height: 16),
          if (_viewModel.servers.isEmpty)
            _EmptyState(onAdd: () => _showEditor())
          else
            for (final server in _viewModel.servers) ...[
              _ServerCard(
                server: server,
                tools: _viewModel.toolsFor(server.id),
                busy: _viewModel.busyServerId == server.id,
                onEdit: () => _showEditor(server),
                onRefresh: () => _viewModel.refresh(server.id),
                onDelete: () => _confirmDelete(server),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error case AppFailure(:final code)) {
      return switch (code) {
        'mcp_https_required' => S.of(context).mcpHttpsRequired,
        'mcp_private_endpoint_blocked' =>
          S.of(context).mcpPrivateEndpointBlocked,
        'mcp_authorization_required' => S.of(context).mcpAuthorizationRequired,
        'mcp_request_timeout' => S.of(context).mcpRequestTimedOut,
        'mcp_unsupported_protocol' => S.of(context).mcpUnsupportedProtocol,
        'mcp_stdio_start_failed' => S.of(context).mcpStdioStartFailed,
        'mcp_invalid_stdio_environment' =>
          S.of(context).mcpInvalidStdioEnvironment,
        'mcp_invalid_endpoint' => S.of(context).mcpHttpsRequired,
        'mcp_server_in_use_by_bot' => S.of(context).mcpServerInUseByBot,
        _ => safeFailureMessage(context, error),
      };
    }
    if (error case McpException(:final code)) {
      return switch (code) {
        'mcp_https_required' => S.of(context).mcpHttpsRequired,
        'mcp_private_endpoint_blocked' =>
          S.of(context).mcpPrivateEndpointBlocked,
        'mcp_authorization_required' => S.of(context).mcpAuthorizationRequired,
        'mcp_request_timeout' => S.of(context).mcpRequestTimedOut,
        'mcp_unsupported_protocol' => S.of(context).mcpUnsupportedProtocol,
        'mcp_stdio_start_failed' => S.of(context).mcpStdioStartFailed,
        'mcp_invalid_stdio_environment' =>
          S.of(context).mcpInvalidStdioEnvironment,
        _ => S.of(context).mcpConnectionFailed(code),
      };
    }
    return S.of(context).mcpConnectionFailed('mcp_unknown_error');
  }

  Future<void> _showDetails(McpServer server) async {
    await showShadDialog<void>(
      context: context,
      builder:
          (dialogContext) => ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              var currentServer = server;
              for (final candidate in _viewModel.servers) {
                if (candidate.id == server.id) {
                  currentServer = candidate;
                  break;
                }
              }
              return _McpServerDetailsDialog(
                server: currentServer,
                tools: _viewModel.toolsFor(server.id),
                processInfo: _viewModel.getStdioProcessInfo(server.id),
              );
            },
          ),
    );
  }

  Future<void> _showEditor([McpServer? server]) async {
    final desktop = isDesktopPlatform(context);
    final draft =
        desktop
            ? await showShadDialog<McpServerDraft>(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) =>
                      _McpServerEditorDialog(server: server, desktop: true),
            )
            : await showDialog<McpServerDraft>(
              context: context,
              builder:
                  (context) =>
                      _McpServerEditorDialog(server: server, desktop: false),
            );
    if (draft == null) return;
    await _viewModel.saveAndConnect(draft);
  }

  Future<void> _confirmDelete(McpServer server) async {
    final desktop = isDesktopPlatform(context);
    final confirmed =
        desktop
            ? await showChatShadDialog<bool>(
              context: context,
              variant: ShadDialogVariant.alert,
              builder:
                  (dialogContext) => ShadDialog.alert(
                    title: Text(S.of(dialogContext).deleteMcpServer),
                    description: Text(
                      S.of(dialogContext).confirmDeleteMcpServer(server.name),
                    ),
                    actions: [
                      ShadButton.outline(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(S.of(dialogContext).cancel),
                      ),
                      ShadButton.destructive(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(S.of(dialogContext).delete),
                      ),
                    ],
                  ),
            )
            : await showDialog<bool>(
              context: context,
              builder:
                  (dialogContext) => AlertDialog(
                    title: Center(
                      child: Text(
                        S.of(dialogContext).deleteMcpServer,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:
                              Theme.of(
                                dialogContext,
                              ).textTheme.bodyLarge?.fontSize,
                        ),
                      ),
                    ),
                    content: Text(
                      S.of(dialogContext).confirmDeleteMcpServer(server.name),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(S.of(dialogContext).cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          S.of(dialogContext).delete,
                          style: TextStyle(
                            color: StarsDesktopThemeSpec.error(dialogContext),
                          ),
                        ),
                      ),
                    ],
                  ),
            );
    if (confirmed == true) await _viewModel.deleteServer(server);
  }
}

IconData _mcpStatusIcon(McpConnectionStatus status) => switch (status) {
  McpConnectionStatus.connected => Icons.cloud_done_outlined,
  McpConnectionStatus.connecting => Icons.cloud_sync_outlined,
  McpConnectionStatus.authorizationRequired => Icons.key_outlined,
  McpConnectionStatus.error => Icons.cloud_off_outlined,
  McpConnectionStatus.disconnected => Icons.cloud_outlined,
};

String _mcpStatusLabel(BuildContext context, McpConnectionStatus status) =>
    switch (status) {
      McpConnectionStatus.connected => S.of(context).mcpConnected,
      McpConnectionStatus.connecting => S.of(context).mcpConnecting,
      McpConnectionStatus.authorizationRequired =>
        S.of(context).mcpAuthorizationRequired,
      McpConnectionStatus.error => S.of(context).mcpConnectionError,
      McpConnectionStatus.disconnected => S.of(context).mcpDisconnected,
    };
