part of 'skill_tool_sessions.dart';

String _groundedAnswerSynthesisPrompt(GroundedAnswerSynthesisRequest request) {
  final envelope = jsonEncode(<String, Object?>{
    'draft_text': request.draftText,
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
- A failed evidence item may describe only execution_failure.
- Preserve useful qualifications and failure disclosures from the draft.
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
