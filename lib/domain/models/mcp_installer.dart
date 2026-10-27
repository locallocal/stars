const mcpInstallerSkillId = 'system:mcp-installer';
const mcpInstallerSkillPromptVersion = 4;
const mcpInstallerSkillContentDigest =
    'e82948de4f812a1f02ea692270ee346d3dd7c26b77c41c7ad8ca9abe5200f925';
const addMcpServerToolName = 'add_mcp_server';
const addMcpServerToolNames = {addMcpServerToolName};
const listInstalledMcpServersToolName = 'list_installed_mcp_servers';
const listCurrentConversationMcpToolName = 'list_current_conversation_mcp';
const mcpInventoryToolNames = {
  listInstalledMcpServersToolName,
  listCurrentConversationMcpToolName,
};
const mcpInstallerToolNames = {addMcpServerToolName, ...mcpInventoryToolNames};
