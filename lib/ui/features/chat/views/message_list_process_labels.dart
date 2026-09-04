part of 'message_list.dart';

String _statusLabel(S strings, String status) {
  switch (status) {
    case 'completed':
      return strings.statusCompleted;
    case 'created':
      return strings.statusGenerated;
    case 'attached':
      return strings.statusAttached;
    case 'streaming':
      return strings.statusInProgress;
    case 'running':
      return strings.statusRunning;
    case 'requested':
      return strings.statusRequested;
    case 'awaitingApproval':
      return strings.statusAwaitingApproval;
    case 'cancelled':
      return strings.statusCancelled;
    case 'denied':
      return strings.statusDenied;
    case 'timedOut':
      return strings.statusTimedOut;
    case 'duplicate':
    case 'duplicateReused':
    case 'duplicateConflict':
      return strings.statusDuplicate;
    case 'skipped':
      return strings.statusSkipped;
    case 'activated':
      return strings.statusActivated;
    case 'unknown':
      return strings.statusUnknown;
    case 'succeeded':
      return strings.statusCompleted;
    case 'failed':
    case 'error':
      return strings.statusFailed;
    case 'recorded':
      return strings.statusRecorded;
    default:
      return strings.statusUnknown;
  }
}

String _reasoningStatusLabel(S strings, String status) {
  switch (status) {
    case 'completed':
      return strings.reasoningCompleted;
    case 'cancelled':
      return strings.reasoningInterrupted;
    case 'streaming':
      return strings.reasoningInProgress;
    default:
      return strings.processInformation;
  }
}

String _fileTypeLabel(S strings, String type) {
  switch (type) {
    case 'image':
      return strings.uploadImage;
    case 'audio':
      return strings.fileTypeSpeech;
    case 'music':
      return strings.fileTypeMusic;
    case 'video':
      return strings.fileTypeVideo;
    default:
      return strings.uploadFile;
  }
}

String _joinMeta(List<String> parts) {
  final filtered = parts.where((item) => item.isNotEmpty).toSet().toList();
  return filtered.join(' · ');
}

String _toolCallTitle(MessageToolCall item) {
  if (item.source != ToolSource.mcp.name || item.mcpServerName.trim().isEmpty) {
    return item.name;
  }
  final toolName = item.title.trim().isEmpty ? item.name : item.title.trim();
  return '${item.mcpServerName.trim()} · $toolName';
}

String _toolCallSubtitle(S strings, MessageToolCall item) => _joinMeta([
  if (item.source.isNotEmpty || item.riskLevel.isNotEmpty)
    _joinMeta([
      _toolSourceLabel(strings, item.source),
      _toolRiskLabel(strings, item.riskLevel),
    ]),
  if (item.argumentsSummary.isNotEmpty) item.argumentsSummary,
  if (item.detail.isNotEmpty) _processDetailLabel(strings, item.detail),
  if (item.resultSummary.isNotEmpty && item.errorCode.isEmpty)
    _processDetailLabel(strings, item.resultSummary),
  if (item.approvalStatus.isNotEmpty)
    _toolApprovalLabel(strings, item.approvalStatus),
  if (item.durationMs != null)
    strings.processDuration(_formatDuration(strings, item.durationMs!)),
]);

String _toolSourceLabel(S strings, String source) {
  switch (source) {
    case 'builtIn':
      return strings.toolSourceBuiltIn;
    case 'mcp':
      return strings.toolSourceMcp;
    case 'skillScript':
      return strings.toolSourceSkillScript;
    case 'providerNative':
      return strings.provider;
    case '':
      return '';
    default:
      return strings.statusUnknown;
  }
}

String _toolRiskLabel(S strings, String riskLevel) {
  switch (riskLevel) {
    case 'readOnly':
      return strings.toolRiskReadOnly;
    case 'write':
      return strings.toolRiskWrite;
    case 'destructive':
      return strings.toolRiskDestructive;
    case '':
      return '';
    default:
      return strings.statusUnknown;
  }
}

String _toolApprovalLabel(S strings, String approvalStatus) {
  switch (approvalStatus) {
    case 'allowOnce':
      return strings.toolApprovalAllowOnce;
    case 'deny':
      return strings.toolApprovalDenied;
    case '':
      return '';
    default:
      return strings.statusUnknown;
  }
}

String _skillActivationTriggerLabel(S strings, String trigger) {
  switch (trigger) {
    case 'model':
      return strings.autoActivation;
    case 'manual':
      return strings.manualActivation;
    case 'always':
      return strings.alwaysActivation;
    case '':
      return '';
    default:
      return strings.statusUnknown;
  }
}

String _processDetailLabel(S strings, String detail) {
  switch (detail) {
    case 'completed':
    case 'succeeded':
      return strings.statusCompleted;
    case 'created':
      return strings.statusGenerated;
    case 'attached':
      return strings.statusAttached;
    case 'streaming':
      return strings.statusInProgress;
    case 'requested':
      return strings.statusRequested;
    case 'awaitingApproval':
      return strings.statusAwaitingApproval;
    case 'running':
      return strings.statusRunning;
    case 'cancelled':
      return strings.statusCancelled;
    case 'denied':
      return strings.statusDenied;
    case 'timedOut':
      return strings.statusTimedOut;
    case 'duplicate':
    case 'duplicateReused':
    case 'duplicateConflict':
      return strings.statusDuplicate;
    case 'skipped':
      return strings.statusSkipped;
    case 'activated':
      return strings.statusActivated;
    case 'recorded':
      return strings.statusRecorded;
    case 'failed':
    case 'error':
      return strings.statusFailed;
    case 'unknown':
      return strings.statusUnknown;
    case 'skill_provider_timeout':
    case 'provider_timeout':
    case 'tool_approval_timeout':
    case 'tool_execution_timeout':
    case 'Tool approval timed out.':
    case 'Tool execution timed out.':
      return strings.statusTimedOut;
    case 'tool_approval_denied':
    case 'tool_policy_denied':
    case 'tool_not_requested_by_active_skill':
    case 'process_execution_disabled':
    case 'destructive_tools_disabled':
    case 'The tool call was blocked by application policy.':
    case 'The user denied the tool call.':
      return strings.statusDenied;
    case 'agent_run_cancelled':
      return strings.statusCancelled;
    case 'duplicate_call_id_conflict':
    case 'duplicate_call_reused':
    case 'The call id was already used with different arguments.':
      return strings.statusDuplicate;
    case 'skill_provider_error':
    case 'provider_error':
    case 'invalid_candidate':
    case 'tool_retry_limit_reached':
    case 'tool_not_available':
    case 'invalid_tool_arguments':
    case 'tool_execution_failed':
    case 'invalid_tool_output':
    case 'unsupported':
    case 'The requested tool is not available for this run.':
    case 'Tool arguments failed schema validation.':
    case 'Tool execution failed.':
    case 'Tool output failed schema validation.':
      return strings.statusFailed;
  }

  final looksLikeInternalCode = RegExp(
    r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)+$',
  ).hasMatch(detail);
  return looksLikeInternalCode ? strings.statusFailed : detail;
}

String _formatDuration(S strings, int durationMs) {
  final locale = intl.Intl.getCurrentLocale();
  if (durationMs < 1000) {
    final milliseconds = intl.NumberFormat.decimalPattern(
      locale,
    ).format(durationMs);
    return strings.durationMilliseconds(milliseconds);
  }
  final seconds = durationMs / 1000;
  final formatted = intl.NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: seconds >= 10 ? 0 : 1,
  ).format(seconds);
  return strings.durationSeconds(formatted);
}
