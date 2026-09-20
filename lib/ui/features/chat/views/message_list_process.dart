import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/ui/features/chat/views/execution_status_card.dart';
import 'package:stars/ui/features/chat/views/execution_metric.dart';
import 'package:stars/ui/features/chat/views/task_status_colors.dart';

part 'message_list_process_labels.dart';

class ProcessInfoSection extends StatefulWidget {
  final MessageProcessInfo processInfo;
  final ModelTokenUsage tokenUsage;
  final bool isDesktop;
  final bool isStreaming;
  final bool hasReasoningContent;
  final MessageGrounding? grounding;

  const ProcessInfoSection({
    super.key,
    required this.processInfo,
    this.tokenUsage = ModelTokenUsage.empty,
    this.isDesktop = false,
    this.isStreaming = false,
    this.hasReasoningContent = false,
    this.grounding,
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
          iconColor: StarsStatusTone.reasoning.foreground(context),
          label: _reasoningStatusLabel(
            strings,
            widget.processInfo.reasoningStatus,
          ),
        ),
      );
    }

    if (widget.processInfo.durationMs != null) {
      headerMetrics.add(
        ExecutionMetric(
          icon: LucideIcons.clock3,
          label: strings.processDuration(
            formatProcessDuration(strings, widget.processInfo.durationMs!),
          ),
        ),
      );
    }

    if (widget.tokenUsage.inputTokens > 0 ||
        widget.tokenUsage.outputTokens > 0) {
      headerMetrics
        ..add(
          ExecutionMetric(
            icon: Icons.login_rounded,
            label: '${strings.inputTokens} ${widget.tokenUsage.inputTokens}',
          ),
        )
        ..add(
          ExecutionMetric(
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
                    itemDetailsBuilder:
                        (item) => _ToolLifecycleStages(
                          toolCall: item,
                          grounding: widget.grounding,
                        ),
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
                              formatProcessDuration(strings, item.durationMs!),
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
      return ExecutionStatusCard(
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
              child: ExecutionStatusHeader(
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

class _ProcessChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _ProcessChip({required this.icon, required this.label, this.iconColor});

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
                color: iconColor ?? StarsStatusTone.info.foreground(context),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: executionMetricTextStyle.copyWith(
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
  final Widget Function(T item)? itemDetailsBuilder;

  const _ProcessListCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.statusBuilder,
    this.itemDetailsBuilder,
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
                color: StarsStatusTone.info.foreground(context),
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
                        if (itemDetailsBuilder != null) ...[
                          const SizedBox(height: 6),
                          itemDetailsBuilder!(item),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ExecutionStatusBadge(status: statusBuilder(item)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ToolLifecycleStages extends StatelessWidget {
  const _ToolLifecycleStages({required this.toolCall, this.grounding});

  final MessageToolCall toolCall;
  final MessageGrounding? grounding;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final accepted = _toolActionAccepted(toolCall);
    final completed = _toolActionCompleted(toolCall);
    final readBackVerified = _toolStateReadBackVerified(toolCall, grounding);
    final stages = <(bool, String)>[
      (
        accepted,
        accepted ? strings.toolActionAccepted : strings.toolActionNotAccepted,
      ),
      (
        completed,
        completed
            ? strings.toolActionCompleted
            : strings.toolActionNotCompleted,
      ),
      (
        readBackVerified,
        readBackVerified
            ? strings.toolStateReadBackVerified
            : strings.toolStateNotReadBackVerified,
      ),
    ];
    return Semantics(
      container: true,
      label: stages.map((stage) => stage.$2).join('. '),
      child: ExcludeSemantics(
        child: Wrap(
          key: ValueKey<String>(
            'tool-lifecycle-${toolCall.attemptId.isEmpty ? toolCall.callId : toolCall.attemptId}',
          ),
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final stage in stages)
              ShadBadge.outline(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stage.$1 ? LucideIcons.checkCircle : LucideIcons.circleX,
                      size: 12,
                      color: (stage.$1
                              ? StarsStatusTone.success
                              : StarsStatusTone.warning)
                          .foreground(context),
                    ),
                    const SizedBox(width: 4),
                    Flexible(child: Text(stage.$2)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

bool _toolActionAccepted(MessageToolCall call) {
  if (call.approvalStatus == 'deny' ||
      call.status == 'denied' ||
      call.status == 'rejected') {
    return false;
  }
  if (call.approvalStatus == 'allowOnce') return true;
  return call.status.isNotEmpty &&
      call.status != 'requested' &&
      call.status != 'awaitingApproval';
}

bool _toolActionCompleted(MessageToolCall call) =>
    call.status == 'succeeded' ||
    call.status == 'completed' ||
    call.status == 'duplicateReused';

bool _toolStateReadBackVerified(
  MessageToolCall call,
  MessageGrounding? grounding,
) {
  if (call.attemptId.isEmpty || grounding == null) return false;
  final evidenceId = '${call.attemptId}:evidence';
  return grounding.claims.any(
    (claim) =>
        claim.trustLevel == ClaimTrustLevel.verified &&
        claim.acceptedEvidenceIds.contains(evidenceId),
  );
}

class ExecutionStatusBadge extends StatelessWidget {
  final String status;

  const ExecutionStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.foregroundColor,
    this.backgroundColor,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
  });

  final bool compact;
  final Color? foregroundColor, backgroundColor;

  /// Null inherits the shape from the active shadcn badge theme.
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final normalized = status.isEmpty ? 'unknown' : status;
    final colors = ShadTheme.of(context).toolStatusBadgeColors(normalized);

    return ShadBadge.secondary(
      foregroundColor: foregroundColor ?? colors.foreground,
      backgroundColor: backgroundColor ?? colors.background,
      hoverBackgroundColor: backgroundColor ?? colors.background,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 6,
      ),
      shape: shape,
      child: Text(
        _statusLabel(S.of(context), normalized),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
