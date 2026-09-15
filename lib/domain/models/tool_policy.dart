part of 'tool.dart';

enum ToolPolicyOutcome { allow, requireApproval, deny }

final class ToolPolicyDecision {
  const ToolPolicyDecision({required this.outcome, this.reason = ''});

  const ToolPolicyDecision.allow({this.reason = ''})
    : outcome = ToolPolicyOutcome.allow;

  const ToolPolicyDecision.requireApproval({this.reason = ''})
    : outcome = ToolPolicyOutcome.requireApproval;

  const ToolPolicyDecision.deny({this.reason = ''})
    : outcome = ToolPolicyOutcome.deny;

  final ToolPolicyOutcome outcome;
  final String reason;
}

final class ToolPolicyContext {
  ToolPolicyContext({
    required this.runId,
    required this.chatId,
    required this.botId,
    Set<String> requestedToolNames = const {},
    Set<String> verificationToolNames = const {},
    Set<String> approvalExemptToolNames = const {},
  }) : requestedToolNames = Set<String>.unmodifiable(requestedToolNames),
       verificationToolNames = Set<String>.unmodifiable(verificationToolNames),
       approvalExemptToolNames = Set<String>.unmodifiable(
         approvalExemptToolNames,
       );

  final String runId;
  final String chatId;
  final String botId;
  final Set<String> requestedToolNames;
  final Set<String> verificationToolNames;
  final Set<String> approvalExemptToolNames;
}

abstract interface class ToolPolicy {
  ToolPolicyDecision evaluate(
    ToolDefinition definition,
    ToolCallRequest call,
    ToolPolicyContext context,
  );
}

final class DefaultToolPolicy implements ToolPolicy {
  const DefaultToolPolicy({
    this.allowNetwork = false,
    this.allowLocalRead = false,
    this.allowExternalRead = false,
    this.allowDestructiveWithApproval = false,
    this.allowSkillScripts = false,
    this.allowProcessExecution = false,
  });

  final bool allowNetwork;
  final bool allowLocalRead;
  final bool allowExternalRead;
  final bool allowDestructiveWithApproval;
  final bool allowSkillScripts;
  final bool allowProcessExecution;

  @override
  ToolPolicyDecision evaluate(
    ToolDefinition definition,
    ToolCallRequest call,
    ToolPolicyContext context,
  ) {
    final requestedBySkill = context.requestedToolNames.contains(
      definition.name,
    );
    final requestedForVerification = context.verificationToolNames.contains(
      definition.name,
    );
    if (!requestedBySkill && !requestedForVerification) {
      return const ToolPolicyDecision.deny(
        reason: 'tool_not_requested_by_active_skill',
      );
    }
    if (!requestedBySkill &&
        requestedForVerification &&
        !isEligibleVerificationTool(definition)) {
      return const ToolPolicyDecision.deny(
        reason: 'verification_tool_not_eligible',
      );
    }
    if (definition.source == ToolSource.mcp &&
        context.approvalExemptToolNames.contains(definition.name)) {
      return const ToolPolicyDecision.allow(
        reason: 'bot_mcp_tool_approval_exempt',
      );
    }
    final skillApprovalExempt =
        requestedBySkill &&
        context.approvalExemptToolNames.contains(definition.name);
    const historyTools = {
      'search_conversation_history',
      'read_conversation_history',
    };
    if (definition.source == ToolSource.builtIn &&
        definition.riskLevel == ToolRiskLevel.readOnly &&
        definition.capabilities.length == 1 &&
        definition.capabilities.contains(ToolCapability.localRead) &&
        historyTools.contains(definition.name) &&
        context.approvalExemptToolNames.contains(definition.name)) {
      return const ToolPolicyDecision.allow(
        reason: 'conversation_history_read_only_exempt',
      );
    }
    const inventoryTools = {
      ...skillInventoryToolNames,
      ...mcpInventoryToolNames,
    };
    if (definition.source == ToolSource.builtIn &&
        definition.riskLevel == ToolRiskLevel.readOnly &&
        definition.capabilities.length == 1 &&
        definition.capabilities.contains(ToolCapability.localRead) &&
        inventoryTools.contains(definition.name) &&
        context.approvalExemptToolNames.contains(definition.name)) {
      return const ToolPolicyDecision.allow(
        reason: 'application_inventory_read_only_exempt',
      );
    }
    if (definition.source == ToolSource.skillScript) {
      if (!allowSkillScripts) {
        return const ToolPolicyDecision.deny(
          reason: 'process_execution_disabled',
        );
      }
      return skillApprovalExempt
          ? const ToolPolicyDecision.allow(
            reason: 'bot_skill_tool_approval_exempt',
          )
          : const ToolPolicyDecision.requireApproval(
            reason: 'skill_script_requires_approval',
          );
    }
    if (definition.capabilities.contains(ToolCapability.process)) {
      if (!allowProcessExecution) {
        return const ToolPolicyDecision.deny(
          reason: 'process_execution_disabled',
        );
      }
      return skillApprovalExempt
          ? const ToolPolicyDecision.allow(
            reason: 'bot_skill_tool_approval_exempt',
          )
          : const ToolPolicyDecision.requireApproval(
            reason: 'process_execution_requires_approval',
          );
    }
    if (definition.riskLevel == ToolRiskLevel.destructive) {
      if (!allowDestructiveWithApproval) {
        return const ToolPolicyDecision.deny(
          reason: 'destructive_tools_disabled',
        );
      }
      return skillApprovalExempt
          ? const ToolPolicyDecision.allow(
            reason: 'bot_skill_tool_approval_exempt',
          )
          : const ToolPolicyDecision.requireApproval(
            reason: 'destructive_write_requires_approval',
          );
    }
    if (skillApprovalExempt) {
      return const ToolPolicyDecision.allow(
        reason: 'bot_skill_tool_approval_exempt',
      );
    }
    if (definition.capabilities.isEmpty) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'unspecified_capability_requires_approval',
      );
    }
    if (definition.riskLevel == ToolRiskLevel.write ||
        definition.capabilities.contains(ToolCapability.localWrite) ||
        definition.capabilities.contains(ToolCapability.externalWrite)) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'write_requires_approval',
      );
    }
    if (definition.capabilities.contains(ToolCapability.network) &&
        !allowNetwork) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'network_requires_approval',
      );
    }
    if (definition.capabilities.contains(ToolCapability.localRead) &&
        !allowLocalRead) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'local_read_requires_approval',
      );
    }
    if (definition.capabilities.contains(ToolCapability.externalRead) &&
        !allowExternalRead) {
      return const ToolPolicyDecision.requireApproval(
        reason: 'external_read_requires_approval',
      );
    }
    return const ToolPolicyDecision.allow();
  }
}
