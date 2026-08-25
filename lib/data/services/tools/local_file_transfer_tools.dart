part of 'local_file_system_tools.dart';

abstract base class _TwoPathFileTool
    with _LocalFileSystemToolSupport
    implements ExecutableTool {
  _TwoPathFileTool({String Function()? currentWorkingDirectory})
    : paths = _LocalPathResolver(
        currentWorkingDirectory ?? (() => Directory.current.path),
      );

  final _LocalPathResolver paths;

  Future<({String source, String destination})?> resolvePaths(
    ToolCallRequest call,
  ) async {
    try {
      return (
        source: paths.resolve(call.arguments['source_path']),
        destination: paths.resolve(call.arguments['destination_path']),
      );
    } on FormatException {
      return null;
    }
  }

  Future<ToolResult?> validatePaths(
    ToolCallRequest call,
    String source,
    String destination,
  ) async {
    if (source == destination) {
      return error(
        call,
        'Source and destination must be different.',
        'same_file_path',
      );
    }
    final sourceType = await entityType(source);
    if (sourceType == FileSystemEntityType.notFound) {
      return error(call, 'The source file does not exist.', 'file_not_found');
    }
    if (sourceType != FileSystemEntityType.file) {
      return error(
        call,
        'The source path is not a file.',
        'local_path_type_mismatch',
      );
    }
    final destinationType = await entityType(destination);
    if (destinationType != FileSystemEntityType.notFound &&
        destinationType != FileSystemEntityType.file) {
      return error(
        call,
        'The destination path is not a file.',
        'local_path_type_mismatch',
      );
    }
    if (destinationType == FileSystemEntityType.file &&
        call.arguments['overwrite'] != true) {
      return error(
        call,
        'The destination file already exists.',
        'file_already_exists',
      );
    }
    return null;
  }

  Future<void> prepareDestination(
    ToolCallRequest call,
    String destination,
  ) async {
    if (call.arguments['create_parents'] == true) {
      await Directory(
        path_context.dirname(destination),
      ).create(recursive: true);
    }
    if (call.arguments['overwrite'] == true &&
        await File(destination).exists()) {
      await File(destination).delete();
    }
  }
}

final class CopyLocalFileTool extends _TwoPathFileTool {
  CopyLocalFileTool({super.currentWorkingDirectory});

  @override
  final ToolDefinition definition = ToolDefinition(
    name: copyLocalFileToolName,
    title: 'Copy local file',
    description:
        'Copy one local file to another native path. Existing destinations '
        'are preserved unless overwrite is explicitly true. Requires user '
        'approval.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'source_path': _pathSchema,
        'destination_path': _pathSchema,
        'overwrite': {'type': 'boolean'},
        'create_parents': {'type': 'boolean'},
      },
      'required': ['source_path', 'destination_path'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'source_path': {'type': 'string'},
        'destination_path': {'type': 'string'},
        'bytes_copied': {'type': 'integer'},
      },
      'required': ['source_path', 'destination_path', 'bytes_copied'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.destructive,
    capabilities: const {ToolCapability.localRead, ToolCapability.localWrite},
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final resolved = await resolvePaths(call);
    if (resolved == null) return invalidPath(call);
    try {
      final validation = await validatePaths(
        call,
        resolved.source,
        resolved.destination,
      );
      if (validation != null) return validation;
      await prepareDestination(call, resolved.destination);
      final copied = await File(resolved.source).copy(resolved.destination);
      cancellationToken.throwIfCancelled();
      final bytes = await copied.length();
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'Copied ${resolved.source} to ${resolved.destination}.',
        structuredContent: {
          'source_path': resolved.source,
          'destination_path': resolved.destination,
          'bytes_copied': bytes,
        },
      );
    } on AgentRunCancelledException {
      rethrow;
    } on FileSystemException {
      return fileSystemError(call);
    }
  }
}

final class MoveLocalFileTool extends _TwoPathFileTool {
  MoveLocalFileTool({super.currentWorkingDirectory});

  @override
  final ToolDefinition definition = ToolDefinition(
    name: moveLocalFileToolName,
    title: 'Move local file',
    description:
        'Move a local file, with a copy-and-delete fallback across file '
        'systems. Existing destinations are preserved unless overwrite is '
        'explicitly true. Requires destructive-operation approval.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'source_path': _pathSchema,
        'destination_path': _pathSchema,
        'overwrite': {'type': 'boolean'},
        'create_parents': {'type': 'boolean'},
      },
      'required': ['source_path', 'destination_path'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'source_path': {'type': 'string'},
        'destination_path': {'type': 'string'},
        'bytes_moved': {'type': 'integer'},
      },
      'required': ['source_path', 'destination_path', 'bytes_moved'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.destructive,
    capabilities: const {ToolCapability.localRead, ToolCapability.localWrite},
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final resolved = await resolvePaths(call);
    if (resolved == null) return invalidPath(call);
    try {
      final validation = await validatePaths(
        call,
        resolved.source,
        resolved.destination,
      );
      if (validation != null) return validation;
      await prepareDestination(call, resolved.destination);
      final source = File(resolved.source);
      File moved;
      try {
        moved = await source.rename(resolved.destination);
      } on FileSystemException {
        moved = await source.copy(resolved.destination);
        await source.delete();
      }
      cancellationToken.throwIfCancelled();
      final bytes = await moved.length();
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'Moved ${resolved.source} to ${resolved.destination}.',
        structuredContent: {
          'source_path': resolved.source,
          'destination_path': resolved.destination,
          'bytes_moved': bytes,
        },
      );
    } on AgentRunCancelledException {
      rethrow;
    } on FileSystemException {
      return fileSystemError(call);
    }
  }
}

final class DeleteLocalFileTool
    with _LocalFileSystemToolSupport
    implements ExecutableTool {
  DeleteLocalFileTool({String Function()? currentWorkingDirectory})
    : _paths = _LocalPathResolver(
        currentWorkingDirectory ?? (() => Directory.current.path),
      );

  final _LocalPathResolver _paths;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: deleteLocalFileToolName,
    title: 'Delete local file',
    description:
        'Delete one local file without following a symbolic link. Requires '
        'user approval as a destructive operation.',
    inputSchema: const {
      'type': 'object',
      'properties': {'path': _pathSchema},
      'required': ['path'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'deleted': {'type': 'boolean'},
      },
      'required': ['path', 'deleted'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.destructive,
    capabilities: const {ToolCapability.localWrite},
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
      if (type == FileSystemEntityType.notFound) {
        return error(
          call,
          'The requested file does not exist.',
          'file_not_found',
        );
      }
      if (type != FileSystemEntityType.file) {
        return error(
          call,
          'The requested path is not a file.',
          'local_path_type_mismatch',
        );
      }
      await File(path).delete();
      cancellationToken.throwIfCancelled();
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'Deleted file: $path',
        structuredContent: {'path': path, 'deleted': true},
      );
    } on AgentRunCancelledException {
      rethrow;
    } on FileSystemException {
      return fileSystemError(call);
    }
  }
}
