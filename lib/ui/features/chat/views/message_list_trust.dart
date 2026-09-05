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
  Future<Map<String, ToolEvidenceRecord?>>? _evidence;
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _MessageTrustStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.grounding, widget.grounding)) {
      _evidence = null;
      _expanded = false;
    }
  }

  void _handleExpansion(bool expanded) {
    setState(() {
      _expanded = expanded;
      if (expanded && _evidence == null) {
        _evidence = widget.actionViewModel?.loadEvidenceRecords(<String>{
          for (final claim in widget.grounding.claims)
            ...claim.claim.evidenceIds,
        });
      }
    });
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

    return Semantics(
      key: const ValueKey<String>('message-trust-status'),
      container: true,
      button: true,
      expanded: _expanded,
      label: semanticLabel,
      hint: strings.answerTrustDetails,
      child: Material(
        color: visual.background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius:
              widget.isDesktop
                  ? StarsDesktopThemeSpec.statusRadius
                  : const BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: visual.border, width: 1.2),
        ),
        child: ExpansionTile(
          key: const ValueKey<String>('message-trust-details-toggle'),
          initiallyExpanded: false,
          onExpansionChanged: _handleExpansion,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: Icon(visual.icon, size: 16, color: visual.foreground),
          title: Text(
            visual.label,
            style: TextStyle(
              color: visual.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            reason,
            style: TextStyle(
              color: visual.foreground,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          children: [
            if (widget.hasNotFactCheckedContent &&
                visual.label != strings.answerTrustNotFactChecked)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ShadBadge.outline(
                  child: Text(strings.answerTrustNotFactChecked),
                ),
              ),
            if (widget.hasNotFactCheckedContent &&
                visual.label != strings.answerTrustNotFactChecked)
              const SizedBox(height: 8),
            _buildClaimDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimDetails(BuildContext context) {
    final claims = widget.grounding.claims;
    if (claims.isEmpty) {
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

({
  Color foreground,
  Color background,
  Color border,
  IconData icon,
  String label,
})
_trustVisual(
  BuildContext context,
  MessageGrounding grounding,
  bool hasNotFactCheckedContent,
) {
  final strings = S.of(context);
  final colors = Theme.of(context).colorScheme;
  final tokens = StarsDesktopTokens.of(context);
  if (grounding.trustLevel == AnswerTrustLevel.failed) {
    return (
      foreground: colors.error,
      background: colors.errorContainer.withValues(alpha: 0.35),
      border: colors.error.withValues(alpha: 0.65),
      icon: LucideIcons.triangleAlert,
      label: strings.answerTrustFailed,
    );
  }
  if (grounding.trustLevel == AnswerTrustLevel.verified) {
    return (
      foreground: colors.primary,
      background: colors.primaryContainer.withValues(alpha: 0.28),
      border: colors.primary.withValues(alpha: 0.6),
      icon: LucideIcons.shieldCheck,
      label: strings.answerTrustVerified,
    );
  }
  if (grounding.trustLevel == AnswerTrustLevel.partiallyVerified) {
    return (
      foreground: colors.tertiary,
      background: colors.tertiaryContainer.withValues(alpha: 0.3),
      border: colors.tertiary.withValues(alpha: 0.65),
      icon: LucideIcons.shieldAlert,
      label: strings.answerTrustPartiallyVerified,
    );
  }
  return (
    foreground: tokens.secondaryText,
    background: tokens.controlFill,
    border: tokens.separator,
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
) => switch (grounding.trustLevel) {
  AnswerTrustLevel.verified => strings.answerTrustVerified,
  AnswerTrustLevel.partiallyVerified => strings.answerTrustPartiallyVerified,
  AnswerTrustLevel.failed => strings.answerTrustFailed,
  AnswerTrustLevel.unverified =>
    hasNotFactCheckedContent
        ? strings.answerTrustNotFactChecked
        : strings.answerTrustUnverified,
};

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
