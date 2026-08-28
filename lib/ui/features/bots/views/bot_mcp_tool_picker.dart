import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/utils/mcp_search.dart';
import 'package:stars/utils/theme.dart';

part 'bot_mcp_server_search_list.dart';
part 'bot_mcp_tool_list_viewport.dart';

typedef BotMcpCatalog =
    ({
      List<McpServer> servers,
      Map<String, List<McpToolDescriptor>> toolsByServer,
    });

typedef _BotMcpToolBatchActionsBuilder =
    Widget Function(
      List<McpToolDescriptor> tools, {
      required StateSetter refresh,
    });

typedef _BotMcpToolRowBuilder =
    Widget Function(McpToolDescriptor tool, {required StateSetter refresh});

/// Selects MCP Servers for a Bot and configures their individual Tools.
class BotMcpToolPicker extends StatefulWidget {
  const BotMcpToolPicker({
    super.key,
    required this.servers,
    required this.toolsByServer,
    required this.selectedServerIds,
    required this.configurations,
    required this.onSelectedServerIdsChanged,
    required this.onChanged,
    this.isLoading = false,
    this.embedded = false,
    this.readOnly = false,
  });

  final List<McpServer> servers;
  final Map<String, List<McpToolDescriptor>> toolsByServer;
  final Set<String> selectedServerIds;
  final Set<McpToolConfiguration> configurations;
  final ValueChanged<Set<String>> onSelectedServerIdsChanged;
  final ValueChanged<Set<McpToolConfiguration>> onChanged;
  final bool isLoading;
  final bool embedded;
  final bool readOnly;

  @override
  State<BotMcpToolPicker> createState() => _BotMcpToolPickerState();
}

class _BotMcpToolPickerState extends State<BotMcpToolPicker> {
  late Set<McpToolConfiguration> _configurations;

  @override
  void initState() {
    super.initState();
    _configurations = widget.configurations;
  }

  @override
  void didUpdateWidget(covariant BotMcpToolPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configurations = widget.configurations;
  }

  Map<String, McpServer> get _serversById => {
    for (final server in widget.servers) server.id: server,
  };

  Map<String, McpToolConfiguration> get _configuredByKey => {
    for (final configuration in _configurations)
      configuration.key: configuration,
  };

  List<McpServer> get _availableServers {
    final available =
        widget.servers
            .where(
              (server) =>
                  server.status == McpConnectionStatus.connected &&
                  !widget.selectedServerIds.contains(server.id),
            )
            .toList();
    available.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return available;
  }

  List<String> get _selectedServerIds {
    final ids = widget.selectedServerIds.toList();
    ids.sort((left, right) {
      final leftName = _serversById[left]?.name ?? left;
      final rightName = _serversById[right]?.name ?? right;
      return leftName.toLowerCase().compareTo(rightName.toLowerCase());
    });
    return ids;
  }

  List<McpToolDescriptor> _toolsFor(String serverId) =>
      (widget.toolsByServer[serverId] ?? const <McpToolDescriptor>[])
          .where((tool) => tool.isSupportedByClient)
          .toList(growable: false);

  int _enabledToolCount(String serverId) =>
      _configurations
          .where((configuration) => configuration.serverId == serverId)
          .length;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final strings = S.of(context);
    final availableServers = _availableServers;
    final addButton =
        widget.embedded
            ? ShadButton.outline(
              key: const ValueKey<String>('add-bot-mcp-server'),
              size: ShadButtonSize.sm,
              width: 0,
              enabled: !widget.readOnly && availableServers.isNotEmpty,
              onPressed:
                  widget.readOnly || availableServers.isEmpty
                      ? null
                      : _showAddServerDialog,
              leading: const Icon(LucideIcons.plus, size: 15),
              child: Text(strings.addMcpServer),
            )
            : OutlinedButton.icon(
              key: const ValueKey<String>('add-bot-mcp-server'),
              onPressed:
                  widget.readOnly || availableServers.isEmpty
                      ? null
                      : _showAddServerDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(strings.addMcpServer),
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.botMcpToolsDescription,
                style:
                    widget.embedded
                        ? StarsDesktopThemeSpec.metaStyle(context)
                        : Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (!widget.readOnly) ...[const SizedBox(width: 12), addButton],
          ],
        ),
        const SizedBox(height: 10),
        if (_selectedServerIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.noMcpServers,
                  style:
                      widget.embedded
                          ? ShadTheme.of(context).textTheme.small
                          : Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  strings.noMcpServersDescription,
                  style:
                      widget.embedded
                          ? StarsDesktopThemeSpec.metaStyle(context)
                          : Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < _selectedServerIds.length; index++) ...[
            _buildSelectedServerRow(_selectedServerIds[index]),
            if (index != _selectedServerIds.length - 1)
              widget.embedded
                  ? const ShadSeparator.horizontal()
                  : const Divider(height: 1),
          ],
      ],
    );
  }

  Widget _buildSelectedServerRow(String serverId) {
    final server = _serversById[serverId];
    final tools = _toolsFor(serverId);
    final enabledCount = _enabledToolCount(serverId);
    final strings = S.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server?.name ?? serverId,
                  style: (widget.embedded
                          ? ShadTheme.of(context).textTheme.small
                          : Theme.of(context).textTheme.titleSmall)
                      ?.copyWith(color: StarsDesktopThemeSpec.text(context)),
                ),
                const SizedBox(height: 3),
                Text(
                  '$enabledCount/${tools.length} ${strings.mcpTools}',
                  style:
                      widget.embedded
                          ? StarsDesktopThemeSpec.metaStyle(context)
                          : Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(LucideIcons.chevronRight, size: 16),
          const SizedBox(width: 8),
          if (!widget.readOnly)
            widget.embedded
                ? StarsDesktopIconAction(
                  key: ValueKey<String>('remove-bot-mcp-server-$serverId'),
                  icon: LucideIcons.trash2,
                  label: strings.removeMcpServer,
                  iconSize: 16,
                  onPressed: () => _removeServer(serverId),
                )
                : IconButton(
                  key: ValueKey<String>('remove-bot-mcp-server-$serverId'),
                  tooltip: strings.removeMcpServer,
                  onPressed: () => _removeServer(serverId),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: server?.name ?? serverId,
      child: InkWell(
        key: ValueKey<String>('bot-mcp-server-$serverId'),
        onTap: () => _showToolDialog(serverId),
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }

  Future<void> _showAddServerDialog() async {
    if (widget.readOnly || _availableServers.isEmpty) return;
    if (widget.embedded) {
      await showShadDialog<void>(
        context: context,
        builder:
            (dialogContext) => ShadDialog(
              key: const ValueKey<String>('bot-add-mcp-server-dialog'),
              closeIcon: StarsDesktopIconAction(
                key: const ValueKey<String>('bot-add-mcp-server-close'),
                icon: LucideIcons.x,
                iconSize: 18,
                label:
                    MaterialLocalizations.of(dialogContext).closeButtonTooltip,
                onPressed: () => Navigator.pop(dialogContext),
              ),
              closeIconPosition: ShadPosition.directional(
                top: 12,
                end: 8,
                textDirection: Directionality.of(dialogContext),
              ),
              title: Text(S.of(context).addMcpServer),
              description: Text(S.of(context).botMcpToolsDescription),
              constraints: const BoxConstraints(maxWidth: 620),
              actions: [
                ShadButton.outline(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(S.of(context).cancel),
                ),
              ],
              child: _BotMcpServerSearchList(
                servers: _availableServers,
                toolsByServer: widget.toolsByServer,
                embedded: widget.embedded,
                onSelected: (serverId) => _addServer(dialogContext, serverId),
              ),
            ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            key: const ValueKey<String>('bot-add-mcp-server-dialog'),
            title: Text(S.of(context).addMcpServer),
            content: SizedBox(
              width: 520,
              child: _BotMcpServerSearchList(
                servers: _availableServers,
                toolsByServer: widget.toolsByServer,
                embedded: widget.embedded,
                onSelected: (serverId) => _addServer(dialogContext, serverId),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(S.of(context).cancel),
              ),
            ],
          ),
    );
  }

  Future<void> _showToolDialog(String serverId) async {
    final server = _serversById[serverId];
    final tools = _toolsFor(serverId);
    final title = server?.name ?? serverId;
    final description = '${tools.length} ${S.of(context).mcpTools}';
    if (widget.embedded) {
      await showShadDialog<void>(
        context: context,
        builder:
            (dialogContext) => ShadDialog(
              key: ValueKey<String>('bot-mcp-tools-dialog-$serverId'),
              closeIcon: StarsDesktopIconAction(
                key: ValueKey<String>('bot-mcp-tools-close-$serverId'),
                icon: LucideIcons.x,
                iconSize: 18,
                label:
                    MaterialLocalizations.of(dialogContext).closeButtonTooltip,
                onPressed: () => Navigator.pop(dialogContext),
              ),
              closeIconPosition: ShadPosition.directional(
                top: 12,
                end: 8,
                textDirection: Directionality.of(dialogContext),
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: StarsDesktopThemeSpec.text(dialogContext),
                ),
              ),
              description: Text(description),
              constraints: const BoxConstraints(maxWidth: 680),
              actions: [
                ShadButton.outline(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ),
              ],
              child: _BotMcpToolListViewport(
                serverId: serverId,
                tools: tools,
                embedded: widget.embedded,
                readOnly: widget.readOnly,
                buildBatchActions: _buildToolBatchActions,
                buildToolRow: _buildToolRow,
              ),
            ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            key: ValueKey<String>('bot-mcp-tools-dialog-$serverId'),
            title: Text(
              title,
              style: TextStyle(
                color: StarsDesktopThemeSpec.text(dialogContext),
              ),
            ),
            content: SizedBox(
              width: 560,
              child: _BotMcpToolListViewport(
                serverId: serverId,
                tools: tools,
                embedded: widget.embedded,
                readOnly: widget.readOnly,
                buildBatchActions: _buildToolBatchActions,
                buildToolRow: _buildToolRow,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(MaterialLocalizations.of(context).closeButtonLabel),
              ),
            ],
          ),
    );
  }

  Widget _buildToolBatchActions(
    List<McpToolDescriptor> tools, {
    required StateSetter refresh,
  }) {
    final strings = S.of(context);
    final serverId = tools.first.serverId;
    final configuredByKey = _configuredByKey;
    final allToolsEnabled = tools.every(
      (tool) => configuredByKey.containsKey(
        McpToolConfiguration.keyFor(tool.serverId, tool.remoteName),
      ),
    );
    final enabledConfigurations = [
      for (final tool in tools)
        if (configuredByKey[McpToolConfiguration.keyFor(
              tool.serverId,
              tool.remoteName,
            )]
            case final configuration?)
          configuration,
    ];
    final allNoApproval =
        enabledConfigurations.isNotEmpty &&
        enabledConfigurations.every(
          (configuration) => !configuration.requiresApproval,
        );

    void toggleAllTools() {
      _setAllToolsEnabled(tools, !allToolsEnabled);
      refresh(() {});
    }

    void toggleAllNoApproval() {
      _setAllApprovalExempt(tools, !allNoApproval);
      refresh(() {});
    }

    if (widget.embedded) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          ShadButton.outline(
            key: ValueKey<String>('bot-mcp-tools-toggle-all-$serverId'),
            size: ShadButtonSize.sm,
            width: 0,
            onPressed: toggleAllTools,
            child: Text(
              allToolsEnabled
                  ? strings.disableAllMcpTools
                  : strings.enableAllMcpTools,
            ),
          ),
          ShadButton.outline(
            key: ValueKey<String>('bot-mcp-tools-no-approval-all-$serverId'),
            size: ShadButtonSize.sm,
            width: 0,
            enabled: enabledConfigurations.isNotEmpty,
            onPressed:
                enabledConfigurations.isEmpty ? null : toggleAllNoApproval,
            child: Text(
              allNoApproval
                  ? strings.disableAllMcpToolNoApproval
                  : strings.enableAllMcpToolNoApproval,
            ),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          key: ValueKey<String>('bot-mcp-tools-toggle-all-$serverId'),
          onPressed: toggleAllTools,
          child: Text(
            allToolsEnabled
                ? strings.disableAllMcpTools
                : strings.enableAllMcpTools,
          ),
        ),
        OutlinedButton(
          key: ValueKey<String>('bot-mcp-tools-no-approval-all-$serverId'),
          onPressed: enabledConfigurations.isEmpty ? null : toggleAllNoApproval,
          child: Text(
            allNoApproval
                ? strings.disableAllMcpToolNoApproval
                : strings.enableAllMcpToolNoApproval,
          ),
        ),
      ],
    );
  }

  Widget _buildToolRow(McpToolDescriptor tool, {required StateSetter refresh}) {
    final key = McpToolConfiguration.keyFor(tool.serverId, tool.remoteName);
    final configuration = _configuredByKey[key];
    final enabled = configuration != null;
    final title = tool.title.isEmpty ? tool.remoteName : tool.title;
    final enabledStatus =
        enabled ? S.of(context).skillEnabled : S.of(context).skillDisabled;
    final enableSwitch =
        widget.embedded
            ? ShadSwitch(
              key: ValueKey<String>(
                'bot-mcp-tool-toggle-${tool.serverId}-${tool.remoteName}',
              ),
              value: enabled,
              enabled: !widget.readOnly,
              onChanged:
                  widget.readOnly
                      ? null
                      : (value) {
                        _setEnabled(tool, value);
                        refresh(() {});
                      },
              label: Text(enabledStatus),
            )
            : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(enabledStatus),
                Switch(
                  key: ValueKey<String>(
                    'bot-mcp-tool-toggle-${tool.serverId}-${tool.remoteName}',
                  ),
                  value: enabled,
                  onChanged:
                      widget.readOnly
                          ? null
                          : (value) {
                            _setEnabled(tool, value);
                            refresh(() {});
                          },
                ),
              ],
            );
    final approvalSwitch =
        widget.embedded
            ? ShadSwitch(
              key: ValueKey<String>(
                'bot-mcp-tool-no-approval-${tool.serverId}-${tool.remoteName}',
              ),
              value: configuration?.requiresApproval == false,
              enabled: enabled && !widget.readOnly,
              onChanged:
                  enabled && !widget.readOnly
                      ? (value) {
                        _setApprovalExempt(tool, value);
                        refresh(() {});
                      }
                      : null,
              label: Text(S.of(context).mcpNoApprovalRequired),
            )
            : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(S.of(context).mcpNoApprovalRequired),
                Switch(
                  key: ValueKey<String>(
                    'bot-mcp-tool-no-approval-${tool.serverId}-${tool.remoteName}',
                  ),
                  value: configuration?.requiresApproval == false,
                  onChanged:
                      enabled && !widget.readOnly
                          ? (value) {
                            _setApprovalExempt(tool, value);
                            refresh(() {});
                          }
                          : null,
                ),
              ],
            );
    return Padding(
      key: ValueKey<String>('bot-mcp-tool-${tool.serverId}-${tool.remoteName}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            tool.annotations.destructiveHint
                ? Icons.warning_amber_rounded
                : tool.annotations.readOnlyHint
                ? Icons.visibility_outlined
                : Icons.edit_outlined,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              key: ValueKey<String>(
                'bot-mcp-tool-description-${tool.serverId}-${tool.remoteName}',
              ),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: StarsDesktopThemeSpec.text(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  tool.description.isEmpty
                      ? tool.canonicalName
                      : tool.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      widget.embedded
                          ? StarsDesktopThemeSpec.metaStyle(context)
                          : Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Wrap(
            key: ValueKey<String>(
              'bot-mcp-tool-controls-${tool.serverId}-${tool.remoteName}',
            ),
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [enableSwitch, approvalSwitch],
          ),
        ],
      ),
    );
  }

  void _addServer(BuildContext dialogContext, String serverId) {
    if (widget.readOnly) return;
    widget.onSelectedServerIdsChanged(
      Set<String>.unmodifiable({...widget.selectedServerIds, serverId}),
    );
    Navigator.of(dialogContext).pop();
  }

  void _removeServer(String serverId) {
    if (widget.readOnly) return;
    widget.onSelectedServerIdsChanged(
      Set<String>.unmodifiable(
        widget.selectedServerIds.where((id) => id != serverId),
      ),
    );
    _configurations = Set<McpToolConfiguration>.unmodifiable(
      _configurations.where(
        (configuration) => configuration.serverId != serverId,
      ),
    );
    widget.onChanged(_configurations);
  }

  void _setEnabled(McpToolDescriptor tool, bool enabled) {
    if (widget.readOnly) return;
    final next = {
      for (final configuration in _configurations)
        configuration.key: configuration,
    };
    final key = McpToolConfiguration.keyFor(tool.serverId, tool.remoteName);
    if (enabled) {
      next[key] = McpToolConfiguration(
        serverId: tool.serverId,
        remoteName: tool.remoteName,
      );
    } else {
      next.remove(key);
    }
    _configurations = Set<McpToolConfiguration>.unmodifiable(next.values);
    widget.onChanged(_configurations);
  }

  void _setAllToolsEnabled(List<McpToolDescriptor> tools, bool enabled) {
    if (widget.readOnly) return;
    final next = {
      for (final configuration in _configurations)
        configuration.key: configuration,
    };
    for (final tool in tools) {
      final key = McpToolConfiguration.keyFor(tool.serverId, tool.remoteName);
      if (enabled) {
        next.putIfAbsent(
          key,
          () => McpToolConfiguration(
            serverId: tool.serverId,
            remoteName: tool.remoteName,
          ),
        );
      } else {
        next.remove(key);
      }
    }
    _configurations = Set<McpToolConfiguration>.unmodifiable(next.values);
    widget.onChanged(_configurations);
  }

  void _setAllApprovalExempt(List<McpToolDescriptor> tools, bool exempt) {
    if (widget.readOnly) return;
    final next = {
      for (final configuration in _configurations)
        configuration.key: configuration,
    };
    for (final tool in tools) {
      final key = McpToolConfiguration.keyFor(tool.serverId, tool.remoteName);
      final current = next[key];
      if (current == null) continue;
      next[key] = current.copyWith(requiresApproval: !exempt);
    }
    _configurations = Set<McpToolConfiguration>.unmodifiable(next.values);
    widget.onChanged(_configurations);
  }

  void _setApprovalExempt(McpToolDescriptor tool, bool exempt) {
    if (widget.readOnly) return;
    final next = {
      for (final configuration in _configurations)
        configuration.key: configuration,
    };
    final key = McpToolConfiguration.keyFor(tool.serverId, tool.remoteName);
    final current = next[key];
    if (current == null) return;
    next[key] = current.copyWith(requiresApproval: !exempt);
    _configurations = Set<McpToolConfiguration>.unmodifiable(next.values);
    widget.onChanged(_configurations);
  }
}
