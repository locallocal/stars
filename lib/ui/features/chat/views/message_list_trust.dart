part of 'message_list.dart';

class _MessageTrustStatus extends StatefulWidget {
  const _MessageTrustStatus({
    required this.grounding,
    required this.isDesktop,
    required this.strictMode,
    required this.hasNotFactCheckedContent,
    this.actionViewModel,
  });

  final MessageGrounding grounding;
  final bool isDesktop;
  final bool strictMode;
  final bool hasNotFactCheckedContent;
  final MessageActionViewModel? actionViewModel;

  @override
  State<_MessageTrustStatus> createState() => _MessageTrustStatusState();
}

class _MessageTrustStatusState extends State<_MessageTrustStatus> {
  static const _itemValue = 'message-trust';

  late final ShadAccordionController<String> _controller;
  Future<Map<String, ToolEvidenceRecord?>>? _evidence;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller =
        ShadAccordionController<String>()..addListener(_handleAccordionChanged);
  }

  @override
  void didUpdateWidget(covariant _MessageTrustStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.grounding, widget.grounding)) {
      _evidence = null;
      _expanded = false;
      _controller
        ..removeListener(_handleAccordionChanged)
        ..value = const <String>[]
        ..addListener(_handleAccordionChanged);
    }
  }

  void _handleAccordionChanged() {
    final expanded = _controller.value.contains(_itemValue);
    if (_expanded == expanded) return;
    setState(() {
      _expanded = expanded;
      final actionViewModel = widget.actionViewModel;
      if (expanded && _evidence == null && actionViewModel != null) {
        _evidence = actionViewModel.loadEvidenceRecords(<String>{
          ...widget.grounding.evidenceIds,
          for (final claim in widget.grounding.claims)
            ...claim.claim.evidenceIds,
        });
      }
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleAccordionChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final visual = _trustVisual(
      context,
      widget.grounding,
      widget.hasNotFactCheckedContent,
    );
    final reason = _answerTrustReason(strings, widget.grounding.reasonCode);
    final semanticLabel = strings.answerTrustSemanticLabel(
      visual.label,
      reason,
    );
    final details = _buildExpandedDetails(
      context,
      showNotFactCheckedBadge:
          widget.hasNotFactCheckedContent &&
          visual.label != strings.answerTrustNotFactChecked,
    );

    return Semantics(
      key: const ValueKey<String>('message-trust-status'),
      container: true,
      button: true,
      expanded: _expanded,
      label: semanticLabel,
      hint: strings.answerTrustDetails,
      onTap: _toggleExpansion,
      child:
          widget.isDesktop
              ? _buildDesktopStatusCard(
                context,
                icon: visual.icon,
                iconColor: visual.foreground,
                title: visual.label,
                subtitle: reason,
                details: details,
              )
              : _buildMobileStatusCard(
                context,
                icon: visual.icon,
                iconColor: visual.foreground,
                title: visual.label,
                subtitle: reason,
                details: details,
              ),
    );
  }

  void _toggleExpansion() => _controller.toggle(_itemValue);

  Widget _buildDesktopStatusCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget details,
  }) {
    final tokens = StarsDesktopTokens.of(context);
    final duration =
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180);
    return ShadCard(
      key: const ValueKey<String>('message-trust-card'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      backgroundColor: tokens.controlFill,
      radius: StarsDesktopThemeSpec.statusRadius,
      border: ShadBorder.all(color: tokens.separator),
      child: ShadAccordion<String>(
        controller: _controller,
        children: [
          ShadAccordionItem<String>(
            key: const ValueKey<String>('message-trust-details-toggle'),
            value: _itemValue,
            separator: const SizedBox.shrink(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            duration: duration,
            underlineTitleOnHover: false,
            iconData: LucideIcons.chevronDown,
            title: _buildHeader(
              isDesktop: true,
              icon: icon,
              iconColor: iconColor,
              title: title,
              subtitle: subtitle,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: details,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatusCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget details,
  }) {
    final tokens = StarsDesktopTokens.of(context);
    final duration =
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180);
    return Container(
      key: const ValueKey<String>('message-trust-card'),
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.controlFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const ValueKey<String>('message-trust-details-toggle'),
            onTap: _toggleExpansion,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildHeader(
                      isDesktop: false,
                      icon: icon,
                      iconColor: iconColor,
                      title: title,
                      subtitle: subtitle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: duration,
                    turns: _expanded ? 0.5 : 0,
                    child: const Icon(LucideIcons.chevronDown, size: 16),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            child:
                _expanded
                    ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: details,
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required bool isDesktop,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return _StatusCardHeader(
      isDesktop: isDesktop,
      icon: icon,
      iconKey: const ValueKey<String>('message-trust-status-icon'),
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
    );
  }

  Widget _buildExpandedDetails(
    BuildContext context, {
    required bool showNotFactCheckedBadge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showNotFactCheckedBadge) ...[
          ShadBadge.outline(
            child: Text(S.of(context).answerTrustNotFactChecked),
          ),
          const SizedBox(height: 8),
        ],
        _buildClaimDetails(context),
      ],
    );
  }

  Widget _buildClaimDetails(BuildContext context) {
    final claims = widget.grounding.claims;
    if (claims.isEmpty) {
      final evidenceIds = widget.grounding.evidenceIds;
      if (evidenceIds.isNotEmpty) {
        return FutureBuilder<Map<String, ToolEvidenceRecord?>>(
          future: _evidence,
          builder: (context, snapshot) {
            final evidence =
                snapshot.data ?? const <String, ToolEvidenceRecord?>{};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _answerTrustReason(
                    S.of(context),
                    widget.grounding.reasonCode,
                  ),
                ),
                for (final evidenceId in evidenceIds) ...[
                  const SizedBox(height: 8),
                  _EvidenceTrustDetails(
                    evidenceId: evidenceId,
                    record: evidence[evidenceId],
                  ),
                ],
              ],
            );
          },
        );
      }
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          _answerTrustReason(S.of(context), widget.grounding.reasonCode),
          key: const ValueKey<String>('message-trust-empty-details'),
        ),
      );
    }
    return FutureBuilder<Map<String, ToolEvidenceRecord?>>(
      future: _evidence,
      builder: (context, snapshot) {
        final evidence = snapshot.data ?? const <String, ToolEvidenceRecord?>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < claims.length; index++) ...[
              _ClaimTrustDetails(
                grounding: claims[index],
                evidence: evidence,
                strictMode: widget.strictMode,
              ),
              if (index != claims.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _ClaimTrustDetails extends StatelessWidget {
  const _ClaimTrustDetails({
    required this.grounding,
    required this.evidence,
    required this.strictMode,
  });

  final MessageClaimGrounding grounding;
  final Map<String, ToolEvidenceRecord?> evidence;
  final bool strictMode;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final hidesClaim =
        strictMode &&
        _claimRequiresVerification(grounding.claim.kind) &&
        grounding.trustLevel != ClaimTrustLevel.verified;
    final claimText =
        hidesClaim ? strings.answerTrustClaimHidden : grounding.claim.text;
    final trust = _claimTrustLabel(strings, grounding.trustLevel);
    final evidenceIds =
        grounding.acceptedEvidenceIds.isNotEmpty
            ? grounding.acceptedEvidenceIds
            : grounding.claim.evidenceIds;
    final failure =
        grounding.trustLevel == ClaimTrustLevel.verified
            ? ''
            : _claimFailureReason(strings, grounding.reasonCode);

    return Semantics(
      container: true,
      label: '$trust. $claimText${failure.isEmpty ? '' : '. $failure'}',
      child: ExcludeSemantics(
        child: Container(
          key: ValueKey<String>(
            'message-trust-claim-${grounding.claim.claimId}',
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: StarsDesktopThemeSpec.statusRadius,
            border: Border.all(color: StarsDesktopTokens.of(context).separator),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      claimText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShadBadge.outline(child: Text(trust)),
                ],
              ),
              if (failure.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${strings.answerTrustFailureReason}: $failure',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (evidenceIds.isEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  strings.answerTrustEvidenceUnavailable,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              for (final evidenceId in evidenceIds) ...[
                const SizedBox(height: 8),
                _EvidenceTrustDetails(
                  evidenceId: evidenceId,
                  record: evidence[evidenceId],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenceTrustDetails extends StatelessWidget {
  const _EvidenceTrustDetails({required this.evidenceId, this.record});

  final String evidenceId;
  final ToolEvidenceRecord? record;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final value = record;
    if (value == null) {
      return Text(
        '${strings.answerTrustEvidence}: $evidenceId · '
        '${strings.answerTrustEvidenceUnavailable}',
        key: ValueKey<String>('message-evidence-$evidenceId'),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final observedAt = intl.DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).add_Hms().format(value.observedAt.toLocal());
    final source = _toolSourceLabel(strings, value.source.name);
    final failure = value.errorCode.trim();
    return Container(
      key: ValueKey<String>('message-evidence-$evidenceId'),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StarsDesktopTokens.of(context).controlFill,
        borderRadius: StarsDesktopThemeSpec.itemRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${strings.answerTrustTool}: ${value.toolName}'),
          Text('${strings.answerTrustSource}: $source'),
          Text('${strings.answerTrustObservedAt}: $observedAt'),
          if (failure.isNotEmpty)
            Text('${strings.answerTrustFailureReason}: $failure'),
        ],
      ),
    );
  }
}

({Color foreground, IconData icon, String label}) _trustVisual(
  BuildContext context,
  MessageGrounding grounding,
  bool hasNotFactCheckedContent,
) {
  final strings = S.of(context);
  final colors = Theme.of(context).colorScheme;
  final tokens = StarsDesktopTokens.of(context);
  if (_isGenerationTimeout(grounding.reasonCode)) {
    return (
      foreground: colors.error,
      icon: LucideIcons.clock3,
      label: strings.statusTimedOut,
    );
  }
  if (grounding.trustLevel == AnswerTrustLevel.failed) {
    return (
      foreground: colors.error,
      icon: LucideIcons.triangleAlert,
      label: strings.answerTrustFailed,
    );
  }
  if (grounding.trustLevel == AnswerTrustLevel.verified) {
    return (
      foreground: colors.primary,
      icon: LucideIcons.shieldCheck,
      label: strings.answerTrustVerified,
    );
  }
  if (grounding.trustLevel == AnswerTrustLevel.partiallyVerified) {
    return (
      foreground: colors.tertiary,
      icon: LucideIcons.shieldAlert,
      label: strings.answerTrustPartiallyVerified,
    );
  }
  return (
    foreground: tokens.secondaryText,
    icon: hasNotFactCheckedContent ? LucideIcons.info : LucideIcons.shieldAlert,
    label:
        hasNotFactCheckedContent
            ? strings.answerTrustNotFactChecked
            : strings.answerTrustUnverified,
  );
}

String _messageDisplayContent(
  BuildContext context,
  Message message,
  StrictGroundingPresentation? presentation,
) {
  if (presentation == null) return message.content;
  return <String>[
    if (presentation.content.isNotEmpty) presentation.content,
    if (presentation.suppressedFacts)
      S.of(context).strictGroundingUnableToVerify,
  ].join('\n\n');
}

String _messageExportText(
  BuildContext context,
  Message message, {
  required String displayedContent,
  required bool isCurrentUser,
  required bool strictMode,
}) {
  if (isCurrentUser) return message.content;
  final strings = S.of(context);
  final claimLines = <String>[];
  for (final claim in message.grounding.claims) {
    final hidesClaim =
        strictMode &&
        _claimRequiresVerification(claim.claim.kind) &&
        claim.trustLevel != ClaimTrustLevel.verified;
    claimLines.add(
      '- ${claim.claim.claimId}: ${_claimTrustLabel(strings, claim.trustLevel)}'
      '${hidesClaim ? '' : ' — ${claim.claim.text}'}',
    );
  }
  return <String>[
    if (displayedContent.isNotEmpty) displayedContent,
    '---',
    _messageTrustExportAnnotation(context, message),
    if (claimLines.isNotEmpty) ...claimLines,
  ].join('\n');
}

String _messageTrustExportAnnotation(BuildContext context, Message message) {
  final strings = S.of(context);
  final status = _answerTrustLabel(
    strings,
    message.grounding,
    _hasNotFactCheckedContent(message),
  );
  final reason = _answerTrustReason(strings, message.grounding.reasonCode);
  return '${strings.answerTrustExportStatus}: $status\n'
      '${strings.answerTrustExportReason}: $reason';
}

String _answerTrustLabel(
  S strings,
  MessageGrounding grounding,
  bool hasNotFactCheckedContent,
) {
  if (_isGenerationTimeout(grounding.reasonCode)) {
    return strings.statusTimedOut;
  }
  return switch (grounding.trustLevel) {
    AnswerTrustLevel.verified => strings.answerTrustVerified,
    AnswerTrustLevel.partiallyVerified => strings.answerTrustPartiallyVerified,
    AnswerTrustLevel.failed => strings.answerTrustFailed,
    AnswerTrustLevel.unverified =>
      hasNotFactCheckedContent
          ? strings.answerTrustNotFactChecked
          : strings.answerTrustUnverified,
  };
}

bool _isGenerationTimeout(String reasonCode) =>
    reasonCode == 'agent_run_timeout' ||
    reasonCode == 'agent_synthesis_timeout';

String _claimTrustLabel(S strings, ClaimTrustLevel trustLevel) =>
    switch (trustLevel) {
      ClaimTrustLevel.verified => strings.answerTrustVerified,
      ClaimTrustLevel.unverified => strings.answerTrustUnverified,
      ClaimTrustLevel.notVerifiable => strings.answerTrustNotFactChecked,
    };

bool _hasNotFactCheckedContent(Message message) =>
    message.grounding.reasonCode == 'no_verifiable_claims' ||
    message.grounding.claims.any(
      (item) =>
          item.trustLevel == ClaimTrustLevel.notVerifiable ||
          !_claimRequiresVerification(item.claim.kind),
    );

bool _claimRequiresVerification(ClaimKind kind) => switch (kind) {
  ClaimKind.externalFact ||
  ClaimKind.currentFact ||
  ClaimKind.completedAction ||
  ClaimKind.executionFailure => true,
  ClaimKind.userAssertion || ClaimKind.nonFactual => false,
};

String _claimFailureReason(S strings, String reasonCode) =>
    switch (reasonCode) {
      'not_fact_checked' => strings.answerTrustNotFactChecked,
      'claimHasNoEvidence' => strings.answerTrustReasonNoTool,
      'evidenceExpired' => strings.answerTrustReasonEvidenceExpired,
      'evidenceNotFound' ||
      'evidenceLedgerUnavailable' => strings.answerTrustEvidenceUnavailable,
      'verificationUnavailable' ||
      'verification_unavailable' => strings.answerTrustReasonUnavailable,
      _ => strings.answerTrustReasonGateFailed,
    };

String _answerTrustReason(S strings, String reasonCode) {
  return switch (reasonCode) {
    'all_claims_verified' ||
    'all_evidence_validated' => strings.answerTrustReasonVerified,
    'some_claims_verified' ||
    'partial_evidence_validated' => strings.answerTrustReasonPartiallyVerified,
    'no_verifiable_claims' => strings.answerTrustReasonNotFactChecked,
    'provider_tools_unsupported' =>
      strings.answerTrustReasonProviderUnsupported,
    'tool_rejected' => strings.answerTrustReasonToolRejected,
    'agent_run_timeout' ||
    'agent_synthesis_timeout' => strings.answerTrustReasonGenerationTimedOut,
    'provider_failed' ||
    'provider_generation_failed' ||
    'provider_authentication_failed' ||
    'provider_authorization_failed' ||
    'provider_endpoint_not_found' ||
    'provider_request_timeout' ||
    'provider_quota_exceeded' ||
    'provider_rate_limited' ||
    'provider_server_error' ||
    'provider_request_rejected' ||
    'provider_transport_error' ||
    'provider_invalid_base_url' ||
    'network_timeout' => strings.answerTrustReasonProviderFailed,
    'answer_trust_gate_failed' ||
    'evidence_validation_failed' ||
    'critical_persistence_failed' ||
    'tool_execution_persist_failed' ||
    'generation_response_persist_failed' => strings.answerTrustReasonGateFailed,
    'no_tool_evidence' ||
    'no_usable_evidence' ||
    'legacy_evidence_unverified' ||
    'tool_unavailable' ||
    'tool_failed' ||
    'incomplete_tool_execution' => strings.answerTrustReasonNoTool,
    _ => strings.answerTrustReasonUnavailable,
  };
}
