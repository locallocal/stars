part of 'agent_run_coordinator.dart';

extension _AgentRunEvidence on AgentRunCoordinator {
  ValidatedToolResult _validateToolResultContract(
    ToolDefinition definition,
    ToolCallRequest call,
    ToolResult result,
  ) => ToolResultValidator(
    schemaValidator: _schemaValidator,
  ).validate(definition, call, result);
}
