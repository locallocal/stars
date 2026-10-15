const skillInstallerSkillId = 'system:skill-installer';
const skillInstallerSkillPromptVersion = 4;
const skillInstallerSkillContentDigest =
    '8cc3c2456eeaaac3f023cf70af95d705b61bab5d05c4cb88e0911c9bd39d15b2';
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
