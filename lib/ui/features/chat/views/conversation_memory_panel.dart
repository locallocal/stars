import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/stars_system_prompt.dart';
import 'package:stars/domain/use_cases/compact_conversation.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/view_models/conversation_memory_view_model.dart';
import 'package:stars/utils/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

part 'conversation_memory_summary.dart';
part 'conversation_memory_manager.dart';

const double _memoryTrailingControlWidth = 44;

final class ConversationMemoryPanel extends StatefulWidget {
  const ConversationMemoryPanel({
    super.key,
    required this.viewModel,
    required this.generationViewModel,
  });

  final ConversationMemoryViewModel viewModel;
  final ChatGenerationViewModel? generationViewModel;

  @override
  State<ConversationMemoryPanel> createState() =>
      _ConversationMemoryPanelState();
}

final class _ConversationMemoryPanelState
    extends State<ConversationMemoryPanel> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_changed);
    widget.generationViewModel?.addListener(_changed);
    unawaited(widget.viewModel.load());
  }

  @override
  void didUpdateWidget(covariant ConversationMemoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_changed);
      widget.viewModel.addListener(_changed);
      unawaited(widget.viewModel.load());
    }
    if (oldWidget.generationViewModel != widget.generationViewModel) {
      oldWidget.generationViewModel?.removeListener(_changed);
      widget.generationViewModel?.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_changed);
    widget.generationViewModel?.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final state = viewModel.state;
    final report = widget.generationViewModel?.contextAssemblyReport;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    return Material(
      type: MaterialType.transparency,
      child: Column(
        key: const ValueKey<String>('conversation-memory-panel'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 25),
          Text(
            S.of(context).contextAndMemory,
            key: const ValueKey<String>('conversation-memory-section-title'),
            style: StarsDesktopThemeSpec.sectionTitleStyle(context),
          ),
          const SizedBox(height: 12),
          if (report != null) ...[
            _MemoryMetric(
              key: const ValueKey<String>('memory-context-window'),
              icon: Icons.memory_rounded,
              label: S.of(context).contextWindow,
              value: numberFormat.format(report.contextWindowTokens),
            ),
            _MemoryMetric(
              key: const ValueKey<String>('memory-estimated-usage'),
              icon: Icons.data_usage_rounded,
              label: S.of(context).estimatedContextUsage,
              value:
                  '${numberFormat.format(report.estimatedInputTokens)} / '
                  '${numberFormat.format(report.inputBudgetTokens)}',
            ),
            _MemoryMetric(
              key: const ValueKey<String>('memory-retained-turns'),
              icon: Icons.forum_outlined,
              label: S.of(context).retainedRecentTurns,
              value: numberFormat.format(report.includedTurnIds.length),
            ),
          ],
          _MemoryMetric(
            key: const ValueKey<String>('memory-summarized-turns'),
            icon: Icons.summarize_outlined,
            label: S.of(context).summarizedTurns,
            valueWidth: _memoryTrailingControlWidth,
            valueTextAlign: TextAlign.right,
            value: numberFormat.format(
              viewModel.summary?.metadata.sourceMessageIds.length ?? 0,
            ),
          ),
          _MemoryMetric(
            key: const ValueKey<String>('memory-compaction-status'),
            icon: Icons.sync_rounded,
            label: S.of(context).compactionStatus,
            valueWidth: _memoryTrailingControlWidth,
            valueTextAlign: TextAlign.right,
            value:
                viewModel.compacting
                    ? S.of(context).compactingContext
                    : _statusLabel(context, state?.compactionStatus),
          ),
          _AutomaticMemoryRow(
            enabled: !viewModel.loading,
            value: state?.autoMemoryEnabled ?? true,
            onChanged:
                (value) => unawaited(_setAutoMemoryEnabled(context, value)),
          ),
          const SizedBox(height: 10),
          _MemoryActions(
            compacting: viewModel.compacting,
            onViewSummary: () => _showSummary(context),
            onManage: () => _showMemoryManager(context),
            onCompact: () => unawaited(_compact(context)),
          ),
          if (viewModel.error != null) ...[
            const SizedBox(height: 10),
            Text(
              safeFailureMessage(context, viewModel.error!),
              style: (StarsDesktopThemeSpec.metaStyle(context) ??
                      const TextStyle())
                  .copyWith(color: StarsDesktopThemeSpec.error(context)),
            ),
          ],
          _ConversationSystemPromptBlock(
            bot: viewModel.bot,
            conversationId: viewModel.chatId,
            artifactsDirectoryPath: viewModel.artifactsDirectoryPath,
          ),
        ],
      ),
    );
  }

  Future<void> _compact(BuildContext context) async {
    try {
      final result = await widget.viewModel.compactNow();
      if (!context.mounted) return;
      final text = switch (result) {
        ConversationCompactionResult.committed =>
          S.of(context).contextCompacted,
        ConversationCompactionResult.noCandidates =>
          S.of(context).nothingToCompact,
        ConversationCompactionResult.revisionConflict =>
          S.of(context).memoryChangedRetry,
        ConversationCompactionResult.invalidSummary =>
          S.of(context).invalidSummary,
      };
      _showNotice(
        context,
        text,
        destructive:
            result == ConversationCompactionResult.revisionConflict ||
            result == ConversationCompactionResult.invalidSummary,
      );
    } on Object catch (error) {
      if (context.mounted) {
        _showNotice(
          context,
          safeFailureMessage(context, error),
          destructive: true,
        );
      }
    }
  }

  Future<void> _setAutoMemoryEnabled(BuildContext context, bool enabled) async {
    try {
      await widget.viewModel.setAutoMemoryEnabled(enabled);
    } on Object catch (error) {
      if (context.mounted) {
        _showNotice(
          context,
          safeFailureMessage(context, error),
          destructive: true,
        );
      }
    }
  }

  void _showSummary(BuildContext context) {
    final markdown = widget.viewModel.summary?.markdown;
    if (markdown == null || markdown.trim().isEmpty) {
      _showNotice(context, S.of(context).noConversationSummary);
      return;
    }
    unawaited(
      showChatShadDialog<void>(
        context: context,
        builder:
            (dialogContext) => ShadDialog(
              key: const ValueKey<String>('conversation-summary-dialog'),
              title: Text(
                S.of(dialogContext).conversationSummary,
                style: StarsDesktopThemeSpec.pageTitleStyle(dialogContext),
              ),
              description: Text(S.of(dialogContext).automaticSummaryWarning),
              constraints: const BoxConstraints(maxWidth: 720),
              actions: [
                ShadButton.outline(
                  key: const ValueKey<String>('conversation-summary-close'),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    MaterialLocalizations.of(dialogContext).closeButtonLabel,
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 520,
                  child: _ConversationSummaryDocument(markdown: markdown),
                ),
              ),
            ),
      ),
    );
  }

  void _showNotice(
    BuildContext context,
    String message, {
    bool destructive = false,
  }) {
    showStarsNotice(
      context,
      message,
      tone: destructive ? StarsNoticeTone.error : StarsNoticeTone.info,
    );
  }

  void _showMemoryManager(BuildContext context) {
    unawaited(
      showChatShadDialog<void>(
        context: context,
        builder:
            (dialogContext) =>
                _MemoryManagerDialog(viewModel: widget.viewModel),
      ),
    );
  }
}
