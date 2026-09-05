part of 'skill_tool_sessions.dart';

String _groundedAnswerSynthesisPrompt(GroundedAnswerSynthesisRequest request) {
  final envelope = jsonEncode(<String, Object?>{
    'draft_text': request.draftText,
    if (request.reliabilityFeedback.isNotEmpty)
      'application_validation_feedback': request.reliabilityFeedback,
    'required_claims': [
      for (final requirement in request.requiredClaims)
        <String, Object?>{
          'claim_id': requirement.claimId,
          if (requirement.claimKind case final kind?)
            'claim_kind': kind.wireName,
          'subject': requirement.subject,
          'scope': requirement.scope,
          'required_fact_names': requirement.requiredFactNames.toList(),
          'required_fact_values': requirement.requiredFactValues,
          'verification_available': requirement.verificationAvailable,
          if (requirement.toolName.isNotEmpty)
            'verification_tool_name': requirement.toolName,
        },
    ],
    'available_evidence': [
      for (final reference in request.evidence)
        <String, Object?>{
          'evidence_id': reference.evidenceId,
          'tool_name': reference.toolName,
          'is_error': reference.isError,
        },
    ],
  });
  return '''
<stars_grounded_answer_protocol>
Return exactly one JSON object and no Markdown or surrounding prose.
Use exactly this schema:
{"schema_version":1,"claims":[{"claim_id":"unique-id","text":"one user-visible segment","kind":"external_fact|current_fact|completed_action|execution_failure|user_assertion|non_factual","evidence_ids":["application-evidence-id"]}],"non_factual_text":"optional prose containing no factual assertion"}

Rules:
- Put every user-visible factual assertion in its own claims item.
- Use only evidence_id values listed in available_evidence. Never output Provider call IDs.
- Treat required_claims as application constraints. Preserve each claim_id and claim_kind, but do not invent a claim when matching evidence is absent.
- A failed evidence item may describe only execution_failure.
- Preserve useful qualifications and failure disclosures from the draft.
- When draft_text is empty, write a concise answer using only required_claims
  and facts from preceding stars_tool_result envelopes whose evidence_id is
  listed in available_evidence; never infer facts those inputs do not establish.
- If application_validation_feedback is present, correct only the structured
  claim bindings it identifies. Do not request or invoke Tools in this turn.
- Put greetings, transitions, and other genuinely non-factual prose in non_factual_text.
- Do not emit a legacy evidence footer; it is a deprecated input format.

Application-authored synthesis input:
$envelope
</stars_grounded_answer_protocol>
'''.trim();
}

ModelEvent _parseGroundedAnswerOutput(
  String source,
  GroundedAnswerSynthesisRequest request,
) {
  try {
    return GroundedAnswerProduced(
      GroundedAnswerCandidate.parseProviderOutput(
        source,
        allowedEvidenceIds: request.allowedEvidenceIds,
        providerCallToEvidenceId: request.legacyEvidenceAliases,
      ),
    );
  } on GroundedAnswerFormatException catch (error) {
    return ModelTurnFailed(error: error.code, code: error.code);
  } on FormatException {
    return const ModelTurnFailed(
      error: 'invalid_grounded_answer',
      code: 'invalid_grounded_answer',
    );
  }
}
