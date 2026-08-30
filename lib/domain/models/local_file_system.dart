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
const fileOperationsSkillPromptVersion = 3;
const fileOperationsSkillContentDigest =
    '311b9f9e3f34547c954f3ad770c672127fb697fbf86f871a3163d3423fc975e5';

const queryLocalFilesToolName = 'query_local_files';
const readLocalFileToolName = 'read_local_file';
const writeLocalFileToolName = 'write_local_file';
const copyLocalFileToolName = 'copy_local_file';
const moveLocalFileToolName = 'move_local_file';
const deleteLocalFileToolName = 'delete_local_file';
const fileOperationsToolNames = {
  queryLocalFilesToolName,
  readLocalFileToolName,
  writeLocalFileToolName,
  copyLocalFileToolName,
  moveLocalFileToolName,
  deleteLocalFileToolName,
};
