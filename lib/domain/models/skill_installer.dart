const skillInstallerSkillId = 'system:skill-installer';
const skillInstallerSkillPromptVersion = 7;
const skillInstallerSkillContentDigest =
    '9e13ab03194d980a1f0dcbae406c5ee627374164b139c343004b6ff345b3f515';
const installSkillToolName = 'install_skill';
const resolveSkillSourceToolName = 'resolve_skill_source';
const listInstalledSkillsToolName = 'list_installed_skills';
const listCurrentConversationSkillsToolName =
    'list_current_conversation_skills';
const skillInventoryToolNames = {
  listInstalledSkillsToolName,
  listCurrentConversationSkillsToolName,
};
const skillInstallerToolNames = {
  resolveSkillSourceToolName,
  installSkillToolName,
  ...skillInventoryToolNames,
};
