const directoryOperationsSkillId = 'system:directory-operations';
const directoryOperationsSkillPromptVersion = 4;
const directoryOperationsSkillContentDigest =
    '269c00840d3e20c4044b091f3cf7a11798448473f8b7c744cfb8afba5ca5fc83';

const listLocalDirectoryToolName = 'list_local_directory';
const createLocalDirectoryToolName = 'create_local_directory';
const deleteLocalDirectoryToolName = 'delete_local_directory';
const directoryOperationsToolNames = {
  listLocalDirectoryToolName,
  createLocalDirectoryToolName,
  deleteLocalDirectoryToolName,
};

const fileOperationsSkillId = 'system:file-operations';
const fileOperationsSkillPromptVersion = 6;
const fileOperationsSkillContentDigest =
    '410e45eb4bcbeacd313e29f0a8b1de1159ceb9815231e221a54e449f12a94247';

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
