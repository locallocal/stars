const directoryOperationsSkillId = 'system:directory-operations';
const directoryOperationsSkillPromptVersion = 2;
const directoryOperationsSkillContentDigest =
    'a1f9753d1be6bb35a320c26fd8f886e30e411ddcc25b8122f879fd8ac7de395e';

const listLocalDirectoryToolName = 'list_local_directory';
const createLocalDirectoryToolName = 'create_local_directory';
const deleteLocalDirectoryToolName = 'delete_local_directory';
const directoryOperationsToolNames = {
  listLocalDirectoryToolName,
  createLocalDirectoryToolName,
  deleteLocalDirectoryToolName,
};

const fileOperationsSkillId = 'system:file-operations';
const fileOperationsSkillPromptVersion = 2;
const fileOperationsSkillContentDigest =
    'd86ff49a8a323bb1193cda2effd4ecc36f04ffde809d3e464fe0683fa45f6fc0';

const readLocalFileToolName = 'read_local_file';
const writeLocalFileToolName = 'write_local_file';
const copyLocalFileToolName = 'copy_local_file';
const moveLocalFileToolName = 'move_local_file';
const deleteLocalFileToolName = 'delete_local_file';
const fileOperationsToolNames = {
  readLocalFileToolName,
  writeLocalFileToolName,
  copyLocalFileToolName,
  moveLocalFileToolName,
  deleteLocalFileToolName,
};
