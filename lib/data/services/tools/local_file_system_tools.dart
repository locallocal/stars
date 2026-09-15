import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path_context;
import 'package:stars/domain/models/models.dart';

part 'local_file_transfer_tools.dart';
part 'local_file_content_tools.dart';
part 'local_file_query_tool.dart';

const _pathSchema = {'type': 'string', 'minLength': 1, 'maxLength': 4096};
const _directoryListingSubject = 'directory:listing';
const _directoryExistenceSubject = 'directory:existence';
const _fileQuerySubject = 'file:query';
const _fileCopySubject = 'file:copy';
const _fileMoveSubject = 'file:move';
const _fileExistenceSubject = 'file:existence';

Map<String, Object?> _evidenceScopeFor(
  ToolCallRequest call,
  Iterable<String> argumentNames,
) => <String, Object?>{
  for (final name in argumentNames)
    if (call.arguments.containsKey(name)) name: call.arguments[name],
};

List<ExecutableTool> createLocalFileSystemTools({
  String Function()? currentWorkingDirectory,
}) => [
  ListLocalDirectoryTool(currentWorkingDirectory: currentWorkingDirectory),
  CreateLocalDirectoryTool(currentWorkingDirectory: currentWorkingDirectory),
  DeleteLocalDirectoryTool(currentWorkingDirectory: currentWorkingDirectory),
  QueryLocalFilesTool(currentWorkingDirectory: currentWorkingDirectory),
  ReadLocalFileTool(currentWorkingDirectory: currentWorkingDirectory),
  WriteLocalFileTool(currentWorkingDirectory: currentWorkingDirectory),
  CopyLocalFileTool(currentWorkingDirectory: currentWorkingDirectory),
  MoveLocalFileTool(currentWorkingDirectory: currentWorkingDirectory),
  DeleteLocalFileTool(currentWorkingDirectory: currentWorkingDirectory),
];

final class _LocalPathResolver {
  const _LocalPathResolver(this._currentWorkingDirectory);

  final String Function() _currentWorkingDirectory;

  String resolve(Object? value) {
    final requested = value?.toString().trim() ?? '';
    if (requested.isEmpty ||
        requested.length > 4096 ||
        requested.contains('\u0000')) {
      throw const FormatException('The local path is invalid.');
    }
    return path_context.normalize(
      path_context.isAbsolute(requested)
          ? requested
          : path_context.join(_currentWorkingDirectory(), requested),
    );
  }
}

mixin _LocalFileSystemToolSupport {
  ToolResult error(ToolCallRequest call, String message, String code) =>
      ToolResult(
        callId: call.callId,
        name: call.name,
        content: message,
        isError: true,
        errorCode: code,
      );

  ToolResult invalidPath(ToolCallRequest call) =>
      error(call, 'The requested local path is invalid.', 'invalid_local_path');

  ToolResult fileSystemError(ToolCallRequest call) => error(
    call,
    'The local file system operation could not be completed.',
    'local_file_system_error',
  );

  Future<FileSystemEntityType> entityType(String path) =>
      FileSystemEntity.type(path, followLinks: false);

  String entityTypeName(FileSystemEntityType type) => switch (type) {
    FileSystemEntityType.file => 'file',
    FileSystemEntityType.directory => 'directory',
    FileSystemEntityType.link => 'link',
    _ => 'not_found',
  };
}

final class ListLocalDirectoryTool
    with _LocalFileSystemToolSupport
    implements ExecutableTool {
  ListLocalDirectoryTool({String Function()? currentWorkingDirectory})
    : _paths = _LocalPathResolver(
        currentWorkingDirectory ?? (() => Directory.current.path),
      );

  static const defaultMaxEntries = 100;
  static const maxEntries = 500;

  final _LocalPathResolver _paths;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: listLocalDirectoryToolName,
    title: 'List local directory',
    description:
        'List bounded metadata for entries in one local directory without '
        'following symbolic links. Supports native paths on every Stars '
        'platform and requires user approval.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'path': _pathSchema,
        'recursive': {'type': 'boolean'},
        'max_entries': {'type': 'integer', 'minimum': 1, 'maximum': maxEntries},
      },
      'required': ['path'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'recursive': {'type': 'boolean'},
        'entries': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'relative_path': {'type': 'string'},
              'path': {'type': 'string'},
              'type': {'type': 'string'},
            },
            'required': ['name', 'relative_path', 'path', 'type'],
            'additionalProperties': false,
          },
        },
        'truncated': {'type': 'boolean'},
        ...toolEvidenceOutputSchemaProperties,
      },
      'required': [
        'path',
        'recursive',
        'entries',
        'truncated',
        ...toolEvidenceOutputRequiredFields,
      ],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: const {ToolCapability.localRead},
    toolVersion: '1.0.0',
    evidenceCapabilities: const {EvidenceKind.observation},
    evidenceScope: ToolEvidenceScopeRule(
      subject: _directoryListingSubject,
      argumentToScope: const {
        'path': 'path',
        'recursive': 'recursive',
        'max_entries': 'max_entries',
      },
    ),
    defaultEvidenceValidity: const Duration(minutes: 1),
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final String path;
    try {
      path = _paths.resolve(call.arguments['path']);
    } on FormatException {
      return invalidPath(call);
    }
    final recursive = call.arguments['recursive'] == true;
    final requestedLimit = call.arguments['max_entries'];
    final limit = requestedLimit is int ? requestedLimit : defaultMaxEntries;
    if (limit < 1 || limit > maxEntries) {
      return error(
        call,
        'The directory entry limit is outside the allowed range.',
        'invalid_directory_entry_limit',
      );
    }

    try {
      final type = await entityType(path);
      if (type == FileSystemEntityType.notFound) {
        return error(
          call,
          'The requested directory does not exist.',
          'directory_not_found',
        );
      }
      if (type != FileSystemEntityType.directory) {
        return error(
          call,
          'The requested path is not a directory.',
          'local_path_type_mismatch',
        );
      }
      final entries = <Map<String, Object?>>[];
      var truncated = false;
      await for (final entity in Directory(
        path,
      ).list(recursive: recursive, followLinks: false)) {
        cancellationToken.throwIfCancelled();
        if (entries.length >= limit) {
          truncated = true;
          break;
        }
        final entryPath = path_context.normalize(entity.path);
        final type = await entityType(entryPath);
        entries.add({
          'name': path_context.basename(entryPath),
          'relative_path': path_context.relative(entryPath, from: path),
          'path': entryPath,
          'type': entityTypeName(type),
        });
      }
      entries.sort(
        (left, right) => (left['relative_path']! as String).compareTo(
          right['relative_path']! as String,
        ),
      );
      final scope = _evidenceScopeFor(call, const {
        'path',
        'recursive',
        'max_entries',
      });
      final facts = <StructuredFact>[
        StructuredFact(name: 'directory.entry_count', value: entries.length),
        StructuredFact(name: 'directory.listing_complete', value: !truncated),
        StructuredFact(name: 'directory.recursive', value: recursive),
      ];
      final observedAt = DateTime.now().toUtc();
      final structured = <String, Object?>{
        'path': path,
        'recursive': recursive,
        'entries': entries,
        'truncated': truncated,
        ...toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.observation,
          subject: _directoryListingSubject,
          scope: scope,
          structuredFacts: facts,
          observedAt: observedAt,
        ),
      };
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content:
            '${entries.length} entr${entries.length == 1 ? 'y' : 'ies'} '
            'in $path${truncated ? ' (truncated)' : ''}.',
        structuredContent: structured,
        truncated: truncated,
        evidenceKind: EvidenceKind.observation,
        subject: _directoryListingSubject,
        scope: scope,
        structuredFacts: facts,
        observedAt: observedAt,
      );
    } on AgentRunCancelledException {
      rethrow;
    } on FileSystemException {
      return fileSystemError(call);
    }
  }
}

final class CreateLocalDirectoryTool
    with _LocalFileSystemToolSupport
    implements ExecutableTool {
  CreateLocalDirectoryTool({String Function()? currentWorkingDirectory})
    : _paths = _LocalPathResolver(
        currentWorkingDirectory ?? (() => Directory.current.path),
      );

  final _LocalPathResolver _paths;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: createLocalDirectoryToolName,
    title: 'Create local directory',
    description:
        'Create a local directory using the current platform native path '
        'semantics. This write requires user approval.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'path': _pathSchema,
        'recursive': {'type': 'boolean'},
      },
      'required': ['path'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'created': {'type': 'boolean'},
        ...toolEvidenceOutputSchemaProperties,
      },
      'required': ['path', 'created', ...toolEvidenceOutputRequiredFields],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.write,
    capabilities: const {ToolCapability.localWrite},
    toolVersion: '1.0.0',
    evidenceCapabilities: const {EvidenceKind.actionReceipt},
    evidenceScope: ToolEvidenceScopeRule(
      subject: _directoryExistenceSubject,
      argumentToScope: const {'path': 'path', 'recursive': 'recursive'},
    ),
    isIdempotent: true,
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final String path;
    try {
      path = _paths.resolve(call.arguments['path']);
    } on FormatException {
      return invalidPath(call);
    }
    try {
      final type = await entityType(path);
      if (type == FileSystemEntityType.directory) {
        return _successResult(
          call,
          path: path,
          created: false,
          content: 'Directory already exists: $path',
        );
      }
      if (type != FileSystemEntityType.notFound) {
        return error(
          call,
          'The requested path already exists and is not a directory.',
          'local_path_type_mismatch',
        );
      }
      await Directory(
        path,
      ).create(recursive: call.arguments['recursive'] != false);
      cancellationToken.throwIfCancelled();
      return _successResult(
        call,
        path: path,
        created: true,
        content: 'Created directory: $path',
      );
    } on AgentRunCancelledException {
      rethrow;
    } on FileSystemException {
      return fileSystemError(call);
    }
  }

  ToolResult _successResult(
    ToolCallRequest call, {
    required String path,
    required bool created,
    required String content,
  }) {
    final scope = _evidenceScopeFor(call, const {'path', 'recursive'});
    final facts = <StructuredFact>[
      StructuredFact(name: 'action.completed', value: true),
      StructuredFact(name: 'directory.created', value: created),
      StructuredFact(name: 'directory.exists', value: true),
    ];
    final observedAt = DateTime.now().toUtc();
    return ToolResult(
      callId: call.callId,
      name: call.name,
      content: content,
      structuredContent: {
        'path': path,
        'created': created,
        ...toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.actionReceipt,
          subject: _directoryExistenceSubject,
          scope: scope,
          structuredFacts: facts,
          observedAt: observedAt,
        ),
      },
      evidenceKind: EvidenceKind.actionReceipt,
      subject: _directoryExistenceSubject,
      scope: scope,
      structuredFacts: facts,
      observedAt: observedAt,
    );
  }
}

final class DeleteLocalDirectoryTool
    with _LocalFileSystemToolSupport
    implements ExecutableTool {
  DeleteLocalDirectoryTool({String Function()? currentWorkingDirectory})
    : _paths = _LocalPathResolver(
        currentWorkingDirectory ?? (() => Directory.current.path),
      );

  final _LocalPathResolver _paths;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: deleteLocalDirectoryToolName,
    title: 'Delete local directory',
    description:
        'Delete a local directory. Recursive deletion must be explicitly '
        'requested, never follows a directory symlink, and requires user '
        'approval as a destructive operation.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'path': _pathSchema,
        'recursive': {'type': 'boolean'},
      },
      'required': ['path'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'deleted': {'type': 'boolean'},
        'recursive': {'type': 'boolean'},
        ...toolEvidenceOutputSchemaProperties,
      },
      'required': [
        'path',
        'deleted',
        'recursive',
        ...toolEvidenceOutputRequiredFields,
      ],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.destructive,
    capabilities: const {ToolCapability.localWrite},
    toolVersion: '1.0.0',
    evidenceCapabilities: const {EvidenceKind.actionReceipt},
    evidenceScope: ToolEvidenceScopeRule(
      subject: _directoryExistenceSubject,
      argumentToScope: const {'path': 'path', 'recursive': 'recursive'},
    ),
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final String path;
    try {
      path = _paths.resolve(call.arguments['path']);
    } on FormatException {
      return invalidPath(call);
    }
    final recursive = call.arguments['recursive'] == true;
    if (path_context.equals(path_context.dirname(path), path)) {
      return error(
        call,
        'A file-system root directory cannot be deleted.',
        'protected_local_path',
      );
    }
    try {
      final type = await entityType(path);
      if (type == FileSystemEntityType.notFound) {
        return error(
          call,
          'The requested directory does not exist.',
          'directory_not_found',
        );
      }
      if (type != FileSystemEntityType.directory) {
        return error(
          call,
          'The requested path is not a directory.',
          'local_path_type_mismatch',
        );
      }
      if (!recursive &&
          !await Directory(path).list(followLinks: false).isEmpty) {
        return error(
          call,
          'The directory is not empty. Set recursive to true only when the '
              'user explicitly requested recursive deletion.',
          'directory_not_empty',
        );
      }
      await Directory(path).delete(recursive: recursive);
      cancellationToken.throwIfCancelled();
      final scope = _evidenceScopeFor(call, const {'path', 'recursive'});
      final facts = <StructuredFact>[
        StructuredFact(name: 'action.completed', value: true),
        StructuredFact(name: 'directory.deleted', value: true),
        StructuredFact(name: 'directory.exists', value: false),
        StructuredFact(name: 'directory.recursive', value: recursive),
      ];
      final observedAt = DateTime.now().toUtc();
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'Deleted directory: $path',
        structuredContent: {
          'path': path,
          'deleted': true,
          'recursive': recursive,
          ...toolEvidenceOutputMetadata(
            evidenceKind: EvidenceKind.actionReceipt,
            subject: _directoryExistenceSubject,
            scope: scope,
            structuredFacts: facts,
            observedAt: observedAt,
          ),
        },
        evidenceKind: EvidenceKind.actionReceipt,
        subject: _directoryExistenceSubject,
        scope: scope,
        structuredFacts: facts,
        observedAt: observedAt,
      );
    } on AgentRunCancelledException {
      rethrow;
    } on FileSystemException {
      return fileSystemError(call);
    }
  }
}
