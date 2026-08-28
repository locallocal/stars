part of 'bot_mcp_tool_picker.dart';

class _BotMcpServerSearchList extends StatefulWidget {
  const _BotMcpServerSearchList({
    required this.servers,
    required this.toolsByServer,
    required this.embedded,
    required this.onSelected,
  });

  final List<McpServer> servers;
  final Map<String, List<McpToolDescriptor>> toolsByServer;
  final bool embedded;
  final ValueChanged<String> onSelected;

  @override
  State<_BotMcpServerSearchList> createState() =>
      _BotMcpServerSearchListState();
}

class _BotMcpServerSearchListState extends State<_BotMcpServerSearchList> {
  static const _serverListHeight = 360.0;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<McpToolDescriptor> _toolsFor(String serverId) =>
      (widget.toolsByServer[serverId] ?? const <McpToolDescriptor>[])
          .where((tool) => tool.isSupportedByClient)
          .toList(growable: false);

  void _search(String query) {
    if (_query == query) return;
    setState(() => _query = query);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
    if (_query.isNotEmpty) setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final filteredServers = filterMcpServers(
      widget.servers,
      _query,
      toolsForServer: _toolsFor,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: _serverListHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StarsSearchField(
              key: const ValueKey<String>('bot-mcp-server-search'),
              hintText: strings.searchMcpServers,
              semanticLabel: strings.searchMcpServers,
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _search,
              insetFocusRing: widget.embedded,
              suffixIcon:
                  _query.isEmpty
                      ? null
                      : StarsDesktopIconAction(
                        key: const ValueKey<String>(
                          'clear-bot-mcp-server-search',
                        ),
                        icon: LucideIcons.x,
                        label: strings.clearSearch,
                        onPressed: _clearSearch,
                        iconSize: 16,
                      ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  filteredServers.isEmpty
                      ? SingleChildScrollView(
                        child: Padding(
                          key: const ValueKey<String>(
                            'bot-mcp-server-search-empty',
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            strings.noMatchingMcpServers,
                            textAlign: TextAlign.center,
                            style:
                                widget.embedded
                                    ? StarsDesktopThemeSpec.metaStyle(context)
                                    : Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                      : ListView.separated(
                        itemCount: filteredServers.length,
                        separatorBuilder:
                            (context, index) =>
                                widget.embedded
                                    ? const ShadSeparator.horizontal()
                                    : const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final server = filteredServers[index];
                          return Padding(
                            key: ValueKey<String>(
                              'available-bot-mcp-server-${server.id}',
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        server.name,
                                        style: (widget.embedded
                                                ? ShadTheme.of(
                                                  context,
                                                ).textTheme.small
                                                : Theme.of(
                                                  context,
                                                ).textTheme.titleSmall)
                                            ?.copyWith(
                                              color: StarsDesktopThemeSpec.text(
                                                context,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${_toolsFor(server.id).length} '
                                        '${strings.mcpTools}',
                                        style:
                                            widget.embedded
                                                ? StarsDesktopThemeSpec.metaStyle(
                                                  context,
                                                )
                                                : Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (widget.embedded)
                                  ShadButton(
                                    key: ValueKey<String>(
                                      'select-bot-mcp-server-${server.id}',
                                    ),
                                    size: ShadButtonSize.sm,
                                    width: 0,
                                    onPressed:
                                        () => widget.onSelected(server.id),
                                    leading: const Icon(
                                      LucideIcons.plus,
                                      size: 14,
                                    ),
                                    child: Text(strings.addMcpServer),
                                  )
                                else
                                  FilledButton.tonalIcon(
                                    key: ValueKey<String>(
                                      'select-bot-mcp-server-${server.id}',
                                    ),
                                    onPressed:
                                        () => widget.onSelected(server.id),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 17,
                                    ),
                                    label: Text(strings.addMcpServer),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
