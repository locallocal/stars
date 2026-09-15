import 'package:stars/domain/models/tool.dart';

/// Shared deterministic tool-output validation for foreground and durable runs.
final class ToolResultValidator {
  const ToolResultValidator({
    JsonSchemaValidator schemaValidator = const JsonSchemaValidator(),
  }) : _schemaValidator = schemaValidator;
  final JsonSchemaValidator _schemaValidator;
  ValidatedToolResult validate(
    ToolDefinition definition,
    ToolCallRequest call,
    ToolResult result,
  ) {
    if (result.isError) return ValidatedToolResult(result);
    final outputSchema = definition.outputSchema;
    if (outputSchema == null) {
      return ValidatedToolResult(result.copyWith(schemaValid: false));
    }
    final structuredContent = result.structuredContent;
    if (structuredContent == null ||
        _schemaValidator.validate(structuredContent, outputSchema).isNotEmpty) {
      return ValidatedToolResult(
        _invalidToolResult(definition, call, 'invalid_tool_output'),
      );
    }
    final schemaValidated = result.copyWith(schemaValid: true);
    if (!definition.producesEvidence) {
      return ValidatedToolResult(schemaValidated);
    }
    if (schemaValidated.truncated) {
      // A bounded result remains useful untrusted Tool data, but cannot become
      // a business-fact evidence candidate.
      return ValidatedToolResult(schemaValidated);
    }
    try {
      final candidate = validateToolEvidenceResult(
        definition,
        call.arguments,
        schemaValidated,
      );
      return ValidatedToolResult(
        schemaValidated.copyWith(validUntil: candidate?.validUntil),
        evidenceCandidate: candidate,
      );
    } on ToolEvidenceContractException catch (error) {
      return ValidatedToolResult(
        _invalidToolResult(definition, call, error.code),
      );
    } on ArgumentError {
      return ValidatedToolResult(
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

final class ValidatedToolResult {
  const ValidatedToolResult(this.result, {this.evidenceCandidate});

  final ToolResult result;
  final ToolEvidenceCandidate? evidenceCandidate;
}
