const directoryOperationsSkillId = 'system:directory-operations';
const directoryOperationsSkillPromptVersion = 1;
const directoryOperationsSkillContentDigest =
    'ef332302ecdca30cf3c9e52c0207f50d3f45b14084d9e5deb8dac5a745f576a2';

const listLocalDirectoryToolName = 'list_local_directory';
const createLocalDirectoryToolName = 'create_local_directory';
const deleteLocalDirectoryToolName = 'delete_local_directory';
const directoryOperationsToolNames = {
  listLocalDirectoryToolName,
  createLocalDirectoryToolName,
  deleteLocalDirectoryToolName,
};

const fileOperationsSkillId = 'system:file-operations';
const fileOperationsSkillPromptVersion = 1;
const fileOperationsSkillContentDigest =
    '4c2244762bd95c33ffd1a66c537f02e1614e86bc3fe82782f884bdb48a08ad9c';

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
