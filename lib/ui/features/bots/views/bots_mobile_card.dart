part of 'bots.dart';

class _BotListItem extends StatefulWidget {
  final Bot bot;
  final BotCardMetrics metrics;
  final String subtitle;
  final String timestamp;
  final bool isSelected;
  final double fontSize;
  final VoidCallback onTap;

  const _BotListItem({
    required this.bot,
    required this.metrics,
    required this.subtitle,
    required this.timestamp,
    required this.isSelected,
    required this.fontSize,
    required this.onTap,
  });

  @override
  State<_BotListItem> createState() => _BotListItemState();
}

class _BotListItemState extends State<_BotListItem> {
  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    final selectedTextColor = widget.isSelected ? Colors.white : null;
    final titleStyle = StarsDesktopThemeSpec.bodyStyle(context)?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: widget.fontSize,
      color: selectedTextColor,
    );
    final metaStyle = StarsDesktopThemeSpec.metaStyle(
      context,
    )?.copyWith(fontSize: widget.fontSize - 2, color: selectedTextColor);
    final contextWindow =
        widget.metrics.contextWindowTokens == null
            ? '—'
            : numberFormat.format(widget.metrics.contextWindowTokens);

    return DesktopInteractiveListItem(
      selected: widget.isSelected,
      onTap: widget.onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                widget.bot.avatar.isEmpty
                    ? getFrostedProviderColor(
                      widget.bot.provider,
                      Theme.of(context).colorScheme.primary,
                    )
                    : Theme.of(context).colorScheme.primary,
            radius: 20,
            backgroundImage:
                widget.bot.avatar.isNotEmpty
                    ? FileImage(File(widget.bot.avatar))
                    : null,
            child:
                widget.bot.avatar.isEmpty
                    ? buildProviderLogo(context, '', widget.bot.provider, 20)
                    : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.bot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(widget.timestamp, style: metaStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle?.copyWith(
                    color:
                        widget.isSelected
                            ? Colors.white
                            : StarsDesktopThemeSpec.mutedText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  key: ValueKey<String>(
                    'bot-list-model-features-${widget.bot.id}',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _BotCardMetric(
                        key: ValueKey<String>(
                          'bot-list-context-window-${widget.bot.id}',
                        ),
                        icon: Icons.data_array_rounded,
                        name: S.of(context).modelContextWindow,
                        value: contextWindow,
                        separatorKey: ValueKey<String>(
                          'bot-list-context-window-separator-${widget.bot.id}',
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ModelModalitiesView(
                        inputModalities: widget.metrics.inputModalities,
                        outputModalities: widget.metrics.outputModalities,
                        keyPrefix: 'bot-list-modalities-${widget.bot.id}',
                        density: ModelModalitiesDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  key: ValueKey<String>(
                    'bot-list-usage-features-${widget.bot.id}',
                  ),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _BotCardMetric(
                        key: ValueKey<String>(
                          'bot-list-token-total-${widget.bot.id}',
                        ),
                        icon: Icons.data_usage_rounded,
                        name: S.of(context).totalTokens,
                        value: numberFormat.format(
                          widget.metrics.tokenUsage.effectiveTotalTokens,
                        ),
                        separatorKey: ValueKey<String>(
                          'bot-list-token-total-separator-${widget.bot.id}',
                        ),
                      ),
                    ),
                    Expanded(
                      child: _BotCardMetric(
                        key: ValueKey<String>(
                          'bot-list-skill-count-${widget.bot.id}',
                        ),
                        icon: LucideIcons.wrench,
                        name: S.of(context).botSkills,
                        value: '${widget.metrics.skillCount}',
                        separatorKey: ValueKey<String>(
                          'bot-list-skill-count-separator-${widget.bot.id}',
                        ),
                      ),
                    ),
                    Expanded(
                      child: _BotCardMetric(
                        key: ValueKey<String>(
                          'bot-list-mcp-count-${widget.bot.id}',
                        ),
                        icon: Icons.hub_outlined,
                        name: S.of(context).mcpServers,
                        value: '${widget.metrics.mcpServerNames.length}',
                        separatorKey: ValueKey<String>(
                          'bot-list-mcp-count-separator-${widget.bot.id}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotCardMetric extends StatelessWidget {
  const _BotCardMetric({
    super.key,
    required this.icon,
    required this.name,
    required this.value,
    this.separatorKey,
  });

  final IconData icon;
  final String name;
  final String value;
  final Key? separatorKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: name,
            child: Icon(
              icon,
              size: 14,
              color: StarsDesktopThemeSpec.mutedText(context),
            ),
          ),
          if (separatorKey == null)
            const SizedBox(width: 5)
          else ...[
            const SizedBox(width: 6),
            Container(
              key: separatorKey,
              width: 1,
              height: 14,
              color: StarsDesktopThemeSpec.divider(context),
            ),
            const SizedBox(width: 6),
          ],
          Text(value, style: StarsDesktopThemeSpec.metaStyle(context)),
        ],
      ),
    );
  }
}
