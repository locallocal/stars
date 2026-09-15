part of 'chat.dart';

extension ChatTaskActions on ChatPageState {
  void _handleTaskChanges() {
    if (mounted) _updateState(() {});
  }

  void _queryTask([String? taskId]) {
    unawaited(
      _tasksViewModel?.query(
        language: Localizations.localeOf(context).toLanguageTag(),
        taskId: taskId,
      ),
    );
  }

  Widget _buildTasksPanel() {
    final tasks = _tasksViewModel;
    if (tasks == null) return const SizedBox.shrink();
    return ConversationTasksPanel(
      state: tasks.state,
      onQuery: _queryTask,
      onRefresh: () => tasks.start(),
      onAction: _taskAction,
    );
  }

  Future<void> _taskAction(
    ConversationTaskProgressSummary summary,
    TaskCardAction action,
  ) async {
    final tasks = _tasksViewModel;
    if (tasks == null) return;
    switch (action) {
      case TaskCardAction.status:
        _queryTask(summary.taskId);
      case TaskCardAction.approve:
        await tasks.decide(summary, TaskApprovalDecision.approved);
      case TaskCardAction.deny:
        await tasks.decide(summary, TaskApprovalDecision.denied);
      case TaskCardAction.cancel:
        await tasks.cancel(summary);
      case TaskCardAction.resume:
        await tasks.resume(summary);
      case TaskCardAction.retry:
        if (_isTyping || _sendPending) return;
        try {
          final draft = await tasks.retryDraft(summary);
          if (!mounted) return;
          final w = TaskProgressStrings(
            Localizations.localeOf(context).toLanguageTag(),
          );
          final reviewedBot = widget.bot;
          final reviewedStrict = widget.strictGroundingMode;
          final reviewedVerification = widget.showVerificationStatus;
          final input = await showConversationTaskRetryDialog(
            context,
            input: draft.input,
            policyDescription:
                '${widget.bot.model} · ${w.verification}: '
                '${widget.strictGroundingMode ? w.pick("strict", "严格") : w.pick("standard", "标准")}',
          );
          if (input == null || !mounted || _isTyping || _sendPending) return;
          if (widget.bot != reviewedBot ||
              widget.strictGroundingMode != reviewedStrict ||
              widget.showVerificationStatus != reviewedVerification) {
            throw StateError('task_retry_policy_changed');
          }
          _updateState(() => _sendPending = true);
          try {
            final message = _chatViewModel.createUserMessage(
              currentUserId: _currentUserId,
              content: input,
              imagePaths: const [],
              filePaths: const [],
              imageDetail: '',
              fileDetail: '',
            );
            await _generationViewModel.dispatchText(
              userMessage: message,
              language: Localizations.localeOf(context).toLanguageTag(),
              verification: VerificationPolicySnapshot(
                reliabilityEnabled: true,
                strictGroundingEnabled: widget.strictGroundingMode,
                showVerificationStatus: widget.showVerificationStatus,
              ),
              retryOfTaskId: draft.taskId,
            );
          } finally {
            if (mounted) _updateState(() => _sendPending = false);
          }
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
        }
    }
  }
}
