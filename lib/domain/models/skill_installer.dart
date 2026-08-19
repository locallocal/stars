const skillInstallerSkillId = 'system:skill-installer';
const skillInstallerSkillPromptVersion = 3;
const skillInstallerSkillContentDigest =
    '0509db200a1facc3861255695f5fa26964081438a93c678f18ec3a1716b7654a';
const installSkillToolName = 'install_skill';
const listInstalledSkillsToolName = 'list_installed_skills';
const listCurrentConversationSkillsToolName =
    'list_current_conversation_skills';
const skillInventoryToolNames = {
  listInstalledSkillsToolName,
  listCurrentConversationSkillsToolName,
};
const skillInstallerToolNames = {
  installSkillToolName,
  ...skillInventoryToolNames,
};
