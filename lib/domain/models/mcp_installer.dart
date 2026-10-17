const mcpInstallerSkillId = 'system:mcp-installer';
const mcpInstallerSkillPromptVersion = 3;
const mcpInstallerSkillContentDigest =
    '28b918c3cc609b1491c11749814be4c41a6dae687de6a01f7044db70da0c285b';
const addMcpServerToolName = 'add_mcp_server';
const addMcpServerToolNames = {addMcpServerToolName};
const listInstalledMcpServersToolName = 'list_installed_mcp_servers';
const listCurrentConversationMcpToolName = 'list_current_conversation_mcp';
const mcpInventoryToolNames = {
  listInstalledMcpServersToolName,
  listCurrentConversationMcpToolName,
};
const mcpInstallerToolNames = {addMcpServerToolName, ...mcpInventoryToolNames};
