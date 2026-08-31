const directoryOperationsSkillId = 'system:directory-operations';
const directoryOperationsSkillPromptVersion = 3;
const directoryOperationsSkillContentDigest =
    '7b35ba5980954dd75f7aa8d268e69ce57a10f044a8763d44eccde948faed1d1f';

const listLocalDirectoryToolName = 'list_local_directory';
const createLocalDirectoryToolName = 'create_local_directory';
const deleteLocalDirectoryToolName = 'delete_local_directory';
const directoryOperationsToolNames = {
  listLocalDirectoryToolName,
  createLocalDirectoryToolName,
  deleteLocalDirectoryToolName,
};

const fileOperationsSkillId = 'system:file-operations';
const fileOperationsSkillPromptVersion = 4;
const fileOperationsSkillContentDigest =
    'bc175cb154df95b9b5d02eebee067e0954aa158239e52c6268d3fbaa5bc4ccb1';

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
