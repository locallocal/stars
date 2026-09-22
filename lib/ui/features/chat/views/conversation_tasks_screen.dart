import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/ui/core/dependency_injection/app_dependencies.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/features/chat/view_models/conversation_tasks_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_task_card.dart';
import 'package:stars/ui/features/chat/views/conversation_task_retry_dialog.dart';
import 'package:stars/ui/features/chat/views/conversation_tasks_page.dart';

/// Owns the page subscription; background execution belongs to the app runtime.
final class ConversationTasksScreen extends StatefulWidget {
  const ConversationTasksScreen({
    super.key,
    required this.chatId,
    required this.bot,
    this.embedded = false,
    this.strictGroundingMode = false,
    this.showVerificationStatus = true,
  });
  final String chatId;
  final Bot bot;
  final bool embedded, strictGroundingMode, showVerificationStatus;

  @override
  State<ConversationTasksScreen> createState() =>
      _ConversationTasksScreenState();
}

final class _ConversationTasksScreenState
    extends State<ConversationTasksScreen> {
  AppDependencies? _dependencies;
  ConversationTasksViewModel? _viewModel;
  bool _reviewing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppScope.of(context);
    if (_dependencies == dependencies) return;
    _dependencies = dependencies;
    _replaceViewModel();
  }

  @override
  void didUpdateWidget(covariant ConversationTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId || oldWidget.bot != widget.bot) {
      _replaceViewModel();
    }
  }

  void _replaceViewModel() {
    _viewModel?.dispose();
    _viewModel = _dependencies!.createConversationTasksViewModel(
      widget.chatId,
      widget.bot,
    );
    unawaited(_viewModel!.start());
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  Future<void> _action(
    ConversationTaskProgressSummary summary,
    TaskCardAction action,
  ) async {
    final vm = _viewModel!;
    switch (action) {
      case TaskCardAction.status:
        await vm.refresh();
      case TaskCardAction.approve:
        await vm.decide(summary, TaskApprovalDecision.approved);
      case TaskCardAction.deny:
        await vm.decide(summary, TaskApprovalDecision.denied);
      case TaskCardAction.cancel:
        await vm.cancel(summary);
      case TaskCardAction.resume:
        await vm.resume(summary);
      case TaskCardAction.retry:
        if (_reviewing || !vm.canRetry) return;
        _reviewing = true;
        try {
          final draft = await vm.retryDraft(summary);
          if (!mounted || vm != _viewModel) return;
          final reviewedBot = widget.bot;
          final strict = widget.strictGroundingMode;
          final showVerification = widget.showVerificationStatus;
          final words = TaskProgressStrings(
            Localizations.localeOf(context).toLanguageTag(),
          );
          final input = await showConversationTaskRetryDialog(
            context,
            input: draft.input,
            policyDescription:
                '${reviewedBot.model} · ${words.verification}: ${strict ? words.pick("strict", "严格") : words.pick("standard", "标准")}',
          );
          if (input == null || !mounted || vm != _viewModel) return;
          if (widget.bot != reviewedBot ||
              widget.strictGroundingMode != strict ||
              widget.showVerificationStatus != showVerification) {
            throw StateError('task_retry_policy_changed');
          }
          await vm.retryReviewed(
            draft: draft,
            input: input,
            language: Localizations.localeOf(context).toLanguageTag(),
            verification: VerificationPolicySnapshot(
              reliabilityEnabled: true,
              strictGroundingEnabled: strict,
              showVerificationStatus: showVerification,
            ),
          );
        } on Object {
          if (mounted) {
            showStarsNotice(
              context,
              TaskProgressStrings(
                Localizations.localeOf(context).toLanguageTag(),
              ).commandFailed,
              tone: StarsNoticeTone.error,
            );
          }
        } finally {
          _reviewing = false;
        }
    }
  }

  @override
  Widget build(BuildContext context) => ConversationTasksPage(
    viewModel: _viewModel!,
    embedded: widget.embedded,
    onAction: _action,
  );
}
