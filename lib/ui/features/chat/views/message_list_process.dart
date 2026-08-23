part of 'message_list.dart';

class ReasoningSection extends StatefulWidget {
  final String reasoning;
  final bool isDesktop;
  final bool isStreaming;
  final int? durationMs;
  final MessageActionViewModel? actionViewModel;

  const ReasoningSection({
    super.key,
    required this.reasoning,
    this.isDesktop = false,
    this.isStreaming = false,
    this.durationMs,
    this.actionViewModel,
  });

  @override
  State<ReasoningSection> createState() => _ReasoningSectionState();
}

class ProcessInfoSection extends StatefulWidget {
  final MessageProcessInfo processInfo;
  final ModelTokenUsage tokenUsage;
  final bool isDesktop;
  final bool isStreaming;
  final bool hasReasoningContent;

  const ProcessInfoSection({
    super.key,
    required this.processInfo,
    this.tokenUsage = ModelTokenUsage.empty,
    this.isDesktop = false,
    this.isStreaming = false,
    this.hasReasoningContent = false,
  });

  static const desktopDetailsMaxHeight = 320.0;

  @override
  State<ProcessInfoSection> createState() => _ProcessInfoSectionState();
}

class _ProcessInfoSectionState extends State<ProcessInfoSection> {
  static const _itemValue = 'execution-status';

  late final ShadAccordionController<String> _desktopController;
  late final ScrollController _detailsScrollController;

  @override
  void initState() {
    super.initState();
    _desktopController = ShadAccordionController<String>(null);
    _detailsScrollController = ScrollController();
  }

  @override
  void dispose() {
    _desktopController.dispose();
    _detailsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final headerMetrics = <Widget>[];
    final summaryChips = <Widget>[];

    if (!widget.hasReasoningContent &&
        widget.processInfo.reasoningStatus.isNotEmpty) {
      summaryChips.add(
        _ProcessChip(
          icon: LucideIcons.brain,
          label: _reasoningStatusLabel(
            strings,
            widget.processInfo.reasoningStatus,
          ),
        ),
      );
    }

    if (widget.processInfo.durationMs != null) {
      headerMetrics.add(
        _ProcessHeaderMetric(
          icon: LucideIcons.clock3,
          label: strings.processDuration(
            _formatDuration(strings, widget.processInfo.durationMs!),
          ),
        ),
      );
    }

    if (widget.tokenUsage.inputTokens > 0 ||
        widget.tokenUsage.outputTokens > 0) {
      headerMetrics
        ..add(
          _ProcessHeaderMetric(
            icon: Icons.login_rounded,
            label: '${strings.inputTokens} ${widget.tokenUsage.inputTokens}',
          ),
        )
        ..add(
          _ProcessHeaderMetric(
            icon: Icons.logout_rounded,
            label: '${strings.outputTokens} ${widget.tokenUsage.outputTokens}',
          ),
        );
    }

    if (widget.processInfo.toolCalls.isNotEmpty) {
      summaryChips.add(
        _ProcessChip(
          icon: LucideIcons.wrench,
          label: strings.processToolCount(
            widget.processInfo.toolCalls.length.toString(),
          ),
        ),
      );
    }

    final mcpToolCallCount =
        widget.processInfo.toolCalls
            .where((call) => call.source == ToolSource.mcp.name)
            .length;
    if (mcpToolCallCount > 0) {
      summaryChips.add(
        _ProcessChip(
          icon: LucideIcons.plug,
          label: '${strings.toolSourceMcp} $mcpToolCallCount',
        ),
      );
    }

    if (widget.processInfo.commandExecutions.isNotEmpty) {
      summaryChips.add(
        _ProcessChip(
          icon: LucideIcons.terminal,
          label: strings.processCommandCount(
            widget.processInfo.commandExecutions.length.toString(),
          ),
        ),
      );
    }

    if (widget.processInfo.fileEdits.isNotEmpty) {
      summaryChips.add(
        _ProcessChip(
          icon: LucideIcons.filePenLine,
          label: strings.processFileCount(
            widget.processInfo.fileEdits.length.toString(),
          ),
        ),
      );
    }

    if (widget.processInfo.skillActivations.isNotEmpty) {
      summaryChips.add(
        _ProcessChip(
          icon: LucideIcons.wrench,
          label:
              '${strings.messageSkills} '
              '${widget.processInfo.skillActivations.length}',
        ),
      );
    }

    final details =
        summaryChips.isEmpty &&
                widget.processInfo.toolCalls.isEmpty &&
                widget.processInfo.commandExecutions.isEmpty &&
                widget.processInfo.fileEdits.isEmpty &&
                widget.processInfo.skillActivations.isEmpty
            ? null
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summaryChips.isNotEmpty)
                  Wrap(spacing: 8, runSpacing: 8, children: summaryChips),
                if (widget.processInfo.toolCalls.isNotEmpty) ...[
                  SizedBox(height: summaryChips.isNotEmpty ? 12 : 0),
                  _ProcessListCard<MessageToolCall>(
                    title: strings.toolCalls,
                    icon: LucideIcons.wrench,
                    items: widget.processInfo.toolCalls,
                    titleBuilder: _toolCallTitle,
                    subtitleBuilder: (item) => _toolCallSubtitle(strings, item),
                    statusBuilder: (item) => item.status,
                  ),
                ],
                if (widget.processInfo.commandExecutions.isNotEmpty) ...[
                  SizedBox(height: summaryChips.isNotEmpty ? 12 : 0),
                  _ProcessListCard<MessageCommandExecution>(
                    title: strings.commandExecutions,
                    icon: LucideIcons.terminal,
                    items: widget.processInfo.commandExecutions,
                    titleBuilder: (item) => item.command,
                    subtitleBuilder:
                        (item) => _joinMeta([
                          if (item.detail.isNotEmpty)
                            _processDetailLabel(strings, item.detail),
                          if (item.durationMs != null)
                            strings.processDuration(
                              _formatDuration(strings, item.durationMs!),
                            ),
                        ]),
                    statusBuilder: (item) => item.status,
                  ),
                ],
                if (widget.processInfo.fileEdits.isNotEmpty) ...[
                  SizedBox(height: summaryChips.isNotEmpty ? 12 : 0),
                  _ProcessListCard<MessageFileEdit>(
                    title: strings.fileStatus,
                    icon: LucideIcons.fileText,
                    items: widget.processInfo.fileEdits,
                    titleBuilder:
                        (item) => item.path.split(Platform.pathSeparator).last,
                    subtitleBuilder:
                        (item) => _joinMeta([
                          if (item.detail.isNotEmpty)
                            _processDetailLabel(strings, item.detail),
                          if (item.type.isNotEmpty)
                            _fileTypeLabel(strings, item.type),
                        ]),
                    statusBuilder: (item) => item.status,
                  ),
                ],
                if (widget.processInfo.skillActivations.isNotEmpty) ...[
                  SizedBox(height: summaryChips.isNotEmpty ? 12 : 0),
                  _ProcessListCard<MessageSkillActivation>(
                    title: strings.messageSkills,
                    icon: LucideIcons.wrench,
                    items: widget.processInfo.skillActivations,
                    titleBuilder: (item) => item.name,
                    subtitleBuilder:
                        (item) => _joinMeta([
                          _skillActivationTriggerLabel(strings, item.trigger),
                          if (item.contentDigest.isNotEmpty)
                            item.contentDigest.substring(
                              0,
                              item.contentDigest.length.clamp(0, 12),
                            ),
                        ]),
                    statusBuilder: (item) => item.status,
                  ),
                ],
              ],
            );

    final subtitleContent =
        headerMetrics.isEmpty
            ? null
            : Wrap(
              key: const ValueKey<String>('execution-header-metrics'),
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: headerMetrics,
            );

    if (!widget.isDesktop || details == null) {
      return _StatusCardSection(
        isDesktop: widget.isDesktop,
        icon:
            widget.isDesktop
                ? LucideIcons.sparkles
                : Icons.auto_awesome_motion_rounded,
        title: strings.executionStatus,
        subtitle: _buildSubtitle(strings),
        subtitleContent: subtitleContent,
        child: details,
      );
    }

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return ShadCard(
      key: const ValueKey<String>('desktop-execution-status'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      backgroundColor: StarsDesktopTokens.of(context).controlFill,
      radius: StarsDesktopThemeSpec.statusRadius,
      border: ShadBorder.all(color: StarsDesktopTokens.of(context).separator),
      child: ShadAccordion<String>(
        controller: _desktopController,
        maintainState: true,
        children: [
          ShadAccordionItem<String>(
            value: _itemValue,
            separator: const SizedBox.shrink(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            duration:
                disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
            underlineTitleOnHover: false,
            iconData: LucideIcons.chevronDown,
            title: ListenableBuilder(
              listenable: _desktopController,
              builder:
                  (context, child) => Semantics(
                    expanded: _desktopController.value.contains(_itemValue),
                    child: child,
                  ),
              child: _StatusCardHeader(
                isDesktop: true,
                icon: LucideIcons.sparkles,
                title: strings.executionStatus,
                subtitle: _buildSubtitle(strings),
                subtitleContent: subtitleContent,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: ProcessInfoSection.desktopDetailsMaxHeight,
                ),
                child: Scrollbar(
                  controller: _detailsScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    key: const ValueKey<String>('execution-details-scroll'),
                    controller: _detailsScrollController,
                    primary: false,
                    padding: const EdgeInsets.only(right: 8),
                    child: details,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(S strings) {
    final parts = <String>[];
    if (widget.processInfo.toolCalls.isNotEmpty) {
      parts.add(
        strings.processToolCount(
          widget.processInfo.toolCalls.length.toString(),
        ),
      );
    }
    if (widget.processInfo.commandExecutions.isNotEmpty) {
      parts.add(
        strings.processCommandCount(
          widget.processInfo.commandExecutions.length.toString(),
        ),
      );
    }
    if (widget.processInfo.fileEdits.isNotEmpty) {
      parts.add(
        strings.processFileCount(
          widget.processInfo.fileEdits.length.toString(),
        ),
      );
    }
    if (widget.processInfo.skillActivations.isNotEmpty) {
      parts.add(
        '${strings.messageSkills} '
        '${widget.processInfo.skillActivations.length}',
      );
    }
    return parts.isEmpty ? strings.structuredProcessInfo : parts.join(' · ');
  }
}

const _processMetricTextStyle = TextStyle(
  fontSize: 12,
  height: 1.2,
  fontWeight: FontWeight.w400,
  leadingDistribution: TextLeadingDistribution.even,
);

class _ProcessHeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProcessHeaderMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = StarsDesktopTokens.of(context).secondaryText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 14,
          child: Center(child: Icon(icon, size: 14, color: color)),
        ),
        const SizedBox(width: 6),
        Text(label, style: _processMetricTextStyle.copyWith(color: color)),
      ],
    );
  }
}

class _ProcessChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProcessChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ShadBadge.outline(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 14,
            child: Center(
              child: Icon(
                icon,
                size: 14,
                color: StarsDesktopTokens.of(context).secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: _processMetricTextStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessListCard<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<T> items;
  final String Function(T item) titleBuilder;
  final String Function(T item) subtitleBuilder;
  final String Function(T item) statusBuilder;

  const _ProcessListCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.statusBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StarsDesktopTokens.of(context).separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: StarsDesktopTokens.of(context).secondaryText,
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final subtitle = subtitleBuilder(item);
            final hasSubtitle = subtitle.isNotEmpty;
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == items.length - 1 ? 0 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleBuilder(item),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (hasSubtitle) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  StarsDesktopTokens.of(context).secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(status: statusBuilder(item)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.isEmpty ? 'unknown' : status;
    final variant = switch (normalized) {
      'completed' ||
      'created' ||
      'attached' ||
      'succeeded' ||
      'activated' => ShadBadgeVariant.secondary,
      'failed' ||
      'error' ||
      'denied' ||
      'timedOut' => ShadBadgeVariant.destructive,
      _ => ShadBadgeVariant.outline,
    };

    return ShadBadge.raw(
      variant: variant,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Text(
        _statusLabel(S.of(context), normalized),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
