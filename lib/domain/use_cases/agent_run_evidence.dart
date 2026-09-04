part of 'agent_run_coordinator.dart';

extension _AgentRunEvidence on AgentRunCoordinator {
  _ValidatedToolResult _validateToolResultContract(
    ToolDefinition definition,
    ToolCallRequest call,
    ToolResult result,
  ) {
    if (result.isError) return _ValidatedToolResult(result);
    final outputSchema = definition.outputSchema;
    if (outputSchema == null) {
      return _ValidatedToolResult(result.copyWith(schemaValid: false));
    }
    final structuredContent = result.structuredContent;
    if (structuredContent == null ||
        _schemaValidator.validate(structuredContent, outputSchema).isNotEmpty) {
      return _ValidatedToolResult(
        _invalidToolResult(definition, call, 'invalid_tool_output'),
      );
    }
    final schemaValidated = result.copyWith(schemaValid: true);
    if (!definition.producesEvidence) {
      return _ValidatedToolResult(schemaValidated);
    }
    try {
      final candidate = validateToolEvidenceResult(
        definition,
        call.arguments,
        schemaValidated,
      );
      return _ValidatedToolResult(
        schemaValidated.copyWith(validUntil: candidate?.validUntil),
        evidenceCandidate: candidate,
      );
    } on ToolEvidenceContractException catch (error) {
      return _ValidatedToolResult(
        _invalidToolResult(definition, call, error.code),
      );
    } on ArgumentError {
      return _ValidatedToolResult(
        _invalidToolResult(definition, call, 'invalid_tool_evidence'),
      );
    }
  }

  ToolResult _invalidToolResult(
    ToolDefinition definition,
    ToolCallRequest call,
    String errorCode,
  ) => ToolResult(
    callId: call.callId,
    name: call.name,
    content: 'Tool evidence failed deterministic validation.',
    isError: true,
    errorCode: errorCode,
    source: definition.source,
  );
}

final class _ValidatedToolResult {
  const _ValidatedToolResult(this.result, {this.evidenceCandidate});

  final ToolResult result;
  final ToolEvidenceCandidate? evidenceCandidate;
}
