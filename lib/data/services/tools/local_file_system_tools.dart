import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path_context;
import 'package:stars/domain/models/models.dart';

part 'local_file_transfer_tools.dart';

const _pathSchema = {'type': 'string', 'minLength': 1, 'maxLength': 4096};

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
      },
      'required': ['path', 'recursive', 'entries', 'truncated'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: const {ToolCapability.localRead},
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
      final structured = <String, Object?>{
        'path': path,
        'recursive': recursive,
        'entries': entries,
        'truncated': truncated,
      };
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content:
            '${entries.length} entr${entries.length == 1 ? 'y' : 'ies'} '
            'in $path${truncated ? ' (truncated)' : ''}.',
        structuredContent: structured,
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
      },
      'required': ['path', 'created'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.write,
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
      if (type == FileSystemEntityType.directory) {
        return ToolResult(
          callId: call.callId,
          name: call.name,
          content: 'Directory already exists: $path',
          structuredContent: {'path': path, 'created': false},
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
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'Created directory: $path',
        structuredContent: {'path': path, 'created': true},
      );
    } on AgentRunCancelledException {
      rethrow;
    } on FileSystemException {
      return fileSystemError(call);
    }
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
      },
      'required': ['path', 'deleted', 'recursive'],
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
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'Deleted directory: $path',
        structuredContent: {
          'path': path,
          'deleted': true,
          'recursive': recursive,
        },
      );
    } on AgentRunCancelledException {
      rethrow;
    } on FileSystemException {
      return fileSystemError(call);
    }
  }
}

final class QueryLocalFilesTool
    with _LocalFileSystemToolSupport
    implements ExecutableTool {
  QueryLocalFilesTool({String Function()? currentWorkingDirectory})
    : _paths = _LocalPathResolver(
        currentWorkingDirectory ?? (() => Directory.current.path),
      );

  static const defaultMaxEntries = 5000;
  static const maxEntries = 20000;
  static const defaultMaxResults = 50;
  static const maxResults = 200;
  static const maxQueryLength = 1024;

  final _LocalPathResolver _paths;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: queryLocalFilesToolName,
    title: 'Query local files',
    description:
        'Find regular local files by exact or partial basename under one '
        'directory without reading contents or following symbolic links. '
        'The bounded result reports whether the search was truncated and '
        'requires user approval.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'root_path': _pathSchema,
        'query': {
          'type': 'string',
          'minLength': 1,
          'maxLength': maxQueryLength,
        },
        'match_mode': {
          'type': 'string',
          'enum': ['exact', 'contains'],
        },
        'case_sensitive': {'type': 'boolean'},
        'recursive': {'type': 'boolean'},
        'max_results': {'type': 'integer', 'minimum': 1, 'maximum': maxResults},
        'max_entries': {'type': 'integer', 'minimum': 1, 'maximum': maxEntries},
      },
      'required': ['root_path', 'query'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'root_path': {'type': 'string'},
        'query': {'type': 'string'},
        'match_mode': {'type': 'string'},
        'case_sensitive': {'type': 'boolean'},
        'recursive': {'type': 'boolean'},
        'files': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'relative_path': {'type': 'string'},
              'path': {'type': 'string'},
              'size_bytes': {'type': 'integer'},
              'modified_at': {'type': 'string'},
            },
            'required': [
              'name',
              'relative_path',
              'path',
              'size_bytes',
              'modified_at',
            ],
            'additionalProperties': false,
          },
        },
        'scanned_entries': {'type': 'integer'},
        'truncated': {'type': 'boolean'},
      },
      'required': [
        'root_path',
        'query',
        'match_mode',
        'case_sensitive',
        'recursive',
        'files',
        'scanned_entries',
        'truncated',
      ],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: const {ToolCapability.localRead},
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final String rootPath;
    try {
      rootPath = _paths.resolve(call.arguments['root_path']);
    } on FormatException {
      return invalidPath(call);
    }
    final requestedQuery = call.arguments['query'];
    final matchMode = call.arguments['match_mode']?.toString() ?? 'exact';
    if (requestedQuery is! String ||
        requestedQuery.isEmpty ||
        requestedQuery.length > maxQueryLength ||
        requestedQuery.contains('\u0000') ||
        !const {'exact', 'contains'}.contains(matchMode)) {
      return error(
        call,
        'The requested file query is invalid.',
        'invalid_file_query',
      );
    }
    final recursive = call.arguments['recursive'] == true;
    final caseSensitive = call.arguments['case_sensitive'] == true;
    final requestedMaxResults = call.arguments['max_results'];
    final resultLimit =
        requestedMaxResults is int ? requestedMaxResults : defaultMaxResults;
    final requestedMaxEntries = call.arguments['max_entries'];
    final entryLimit =
        requestedMaxEntries is int ? requestedMaxEntries : defaultMaxEntries;
    if (resultLimit < 1 ||
        resultLimit > maxResults ||
        entryLimit < 1 ||
        entryLimit > maxEntries) {
      return error(
        call,
        'The requested file query limits are invalid.',
        'invalid_file_query_limit',
      );
    }

    try {
      final rootType = await entityType(rootPath);
      if (rootType == FileSystemEntityType.notFound) {
        return error(
          call,
          'The requested query root does not exist.',
          'directory_not_found',
        );
      }
      if (rootType != FileSystemEntityType.directory) {
        return error(
          call,
          'The requested query root is not a directory.',
          'local_path_type_mismatch',
        );
      }

      final normalizedQuery =
          caseSensitive ? requestedQuery : requestedQuery.toLowerCase();
      final matchedPaths = <String>[];
      var scannedEntries = 0;
      var scanTruncated = false;
      await for (final entity in Directory(
        rootPath,
      ).list(recursive: recursive, followLinks: false)) {
        cancellationToken.throwIfCancelled();
        if (scannedEntries >= entryLimit) {
          scanTruncated = true;
          break;
        }
        scannedEntries += 1;
        final filePath = path_context.normalize(entity.path);
        if (await entityType(filePath) != FileSystemEntityType.file) continue;
        final name = path_context.basename(filePath);
        final candidate = caseSensitive ? name : name.toLowerCase();
        final matches = switch (matchMode) {
          'exact' => candidate == normalizedQuery,
          'contains' => candidate.contains(normalizedQuery),
          _ => false,
        };
        if (matches) matchedPaths.add(filePath);
      }

      matchedPaths.sort((left, right) {
        final leftRelative = path_context.relative(left, from: rootPath);
        final rightRelative = path_context.relative(right, from: rootPath);
        return leftRelative.compareTo(rightRelative);
      });
      final resultsTruncated = matchedPaths.length > resultLimit;
      final files = <Map<String, Object?>>[];
      for (final filePath in matchedPaths.take(resultLimit)) {
        cancellationToken.throwIfCancelled();
        final stat = await File(filePath).stat();
        files.add({
          'name': path_context.basename(filePath),
          'relative_path': path_context.relative(filePath, from: rootPath),
          'path': filePath,
          'size_bytes': stat.size,
          'modified_at': stat.modified.toUtc().toIso8601String(),
        });
      }
      final truncated = scanTruncated || resultsTruncated;
      final structured = <String, Object?>{
        'root_path': rootPath,
        'query': requestedQuery,
        'match_mode': matchMode,
        'case_sensitive': caseSensitive,
        'recursive': recursive,
        'files': files,
        'scanned_entries': scannedEntries,
        'truncated': truncated,
      };
      final content = switch ((files.length, truncated)) {
        (0, false) => 'No matching regular files found under $rootPath.',
        (0, true) =>
          'No matches found among $scannedEntries scanned entries under '
              '$rootPath. The query was truncated and does not prove that no '
              'matching file exists.',
        (final count, false) =>
          'Found $count matching regular ${count == 1 ? 'file' : 'files'} '
              'under $rootPath. The query completed.',
        (final count, true) =>
          'Returned $count matching regular ${count == 1 ? 'file' : 'files'} '
              'under $rootPath. The query was truncated, so more matches may '
              'exist.',
      };
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: content,
        structuredContent: structured,
        truncated: truncated,
      );
    } on AgentRunCancelledException {
      rethrow;
    } on FileSystemException {
      return fileSystemError(call);
    }
  }
}

final class ReadLocalFileTool
    with _LocalFileSystemToolSupport
    implements ExecutableTool {
  ReadLocalFileTool({String Function()? currentWorkingDirectory})
    : _paths = _LocalPathResolver(
        currentWorkingDirectory ?? (() => Directory.current.path),
      );

  static const defaultMaxBytes = 65536;
  static const maxBytes = 262144;

  final _LocalPathResolver _paths;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: readLocalFileToolName,
    title: 'Read local file',
    description:
        'Read a bounded byte range from a local file as UTF-8 text or base64 '
        'without invoking a shell. Requires user approval.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'path': _pathSchema,
        'encoding': {
          'type': 'string',
          'enum': ['utf8', 'base64'],
        },
        'offset_bytes': {'type': 'integer', 'minimum': 0},
        'max_bytes': {'type': 'integer', 'minimum': 1, 'maximum': maxBytes},
      },
      'required': ['path'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'encoding': {'type': 'string'},
        'content': {'type': 'string'},
        'size_bytes': {'type': 'integer'},
        'offset_bytes': {'type': 'integer'},
        'bytes_returned': {'type': 'integer'},
        'next_offset_bytes': {'type': 'integer'},
        'truncated': {'type': 'boolean'},
        'sha256': {'type': 'string'},
        ...toolEvidenceOutputSchemaProperties,
      },
      'required': [
        'path',
        'encoding',
        'content',
        'size_bytes',
        'offset_bytes',
        'bytes_returned',
        'next_offset_bytes',
        'truncated',
        'sha256',
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
      subject: 'file:content',
      argumentToScope: const {'path': 'path'},
    ),
    defaultEvidenceValidity: const Duration(minutes: 5),
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
    final encoding = call.arguments['encoding']?.toString() ?? 'utf8';
    if (encoding != 'utf8' && encoding != 'base64') {
      return error(
        call,
        'The requested file encoding is invalid.',
        'invalid_file_encoding',
      );
    }
    final requestedOffset = call.arguments['offset_bytes'];
    final offset = requestedOffset is int ? requestedOffset : 0;
    final requestedMaxBytes = call.arguments['max_bytes'];
    final limit =
        requestedMaxBytes is int ? requestedMaxBytes : defaultMaxBytes;
    if (offset < 0 || limit < 1 || limit > maxBytes) {
      return error(
        call,
        'The requested file byte range is invalid.',
        'invalid_file_range',
      );
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
      final file = File(path);
      final size = await file.length();
      final start = math.min(offset, size);
      final bytesToRead = math.min(limit, size - start);
      final handle = await file.open();
      List<int> bytes;
      try {
        await handle.setPosition(start);
        bytes = await handle.read(bytesToRead);
      } finally {
        await handle.close();
      }
      cancellationToken.throwIfCancelled();

      String content;
      if (encoding == 'base64') {
        content = base64Encode(bytes);
      } else {
        try {
          final decoded = _decodeUtf8Prefix(bytes, start + bytes.length < size);
          content = decoded.text;
          bytes = bytes.sublist(0, decoded.byteLength);
        } on FormatException {
          return error(
            call,
            'The requested byte range is not valid UTF-8. Read it as base64 instead.',
            'file_not_utf8',
          );
        }
      }
      final nextOffset = start + bytes.length;
      final truncated = nextOffset < size;
      final evidenceIncomplete = start != 0 || truncated;
      final contentDigest = sha256.convert(bytes).toString();
      final scope = <String, Object?>{'path': call.arguments['path']};
      final facts = <StructuredFact>[
        StructuredFact(name: 'file.size_bytes', value: size),
        StructuredFact(name: 'file.content_sha256', value: contentDigest),
      ];
      final observedAt = DateTime.now().toUtc();
      final structured = <String, Object?>{
        'path': path,
        'encoding': encoding,
        'content': content,
        'size_bytes': size,
        'offset_bytes': start,
        'bytes_returned': bytes.length,
        'next_offset_bytes': nextOffset,
        'truncated': truncated,
        'sha256': contentDigest,
        ...toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.observation,
          subject: 'file:content',
          scope: scope,
          structuredFacts: facts,
          observedAt: observedAt,
        ),
      };
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: content,
        structuredContent: structured,
        truncated: evidenceIncomplete,
        evidenceKind: EvidenceKind.observation,
        subject: 'file:content',
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

  ({String text, int byteLength}) _decodeUtf8Prefix(
    List<int> bytes,
    bool mayEndMidCharacter,
  ) {
    final maxRemoved = mayEndMidCharacter ? math.min(3, bytes.length) : 0;
    for (var removed = 0; removed <= maxRemoved; removed++) {
      final byteLength = bytes.length - removed;
      try {
        return (
          text: utf8.decode(bytes.sublist(0, byteLength)),
          byteLength: byteLength,
        );
      } on FormatException {
        if (removed == maxRemoved) rethrow;
      }
    }
    throw const FormatException('Invalid UTF-8 input.');
  }
}

final class WriteLocalFileTool
    with _LocalFileSystemToolSupport
    implements ExecutableTool {
  WriteLocalFileTool({String Function()? currentWorkingDirectory})
    : _paths = _LocalPathResolver(
        currentWorkingDirectory ?? (() => Directory.current.path),
      );

  static const maxContentCharacters = 1398104;
  static const maxWriteBytes = 1048576;

  final _LocalPathResolver _paths;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: writeLocalFileToolName,
    title: 'Write local file',
    description:
        'Create, overwrite, or append a bounded UTF-8 or base64 payload to a '
        'local file. The mode must be explicit and every write requires user '
        'approval.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'path': _pathSchema,
        'content': {'type': 'string', 'maxLength': maxContentCharacters},
        'encoding': {
          'type': 'string',
          'enum': ['utf8', 'base64'],
        },
        'mode': {
          'type': 'string',
          'enum': ['create', 'overwrite', 'append'],
        },
        'create_parents': {'type': 'boolean'},
      },
      'required': ['path', 'content', 'mode'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'mode': {'type': 'string'},
        'bytes_written': {'type': 'integer'},
        'size_bytes': {'type': 'integer'},
        'sha256': {'type': 'string'},
        ...toolEvidenceOutputSchemaProperties,
      },
      'required': [
        'path',
        'mode',
        'bytes_written',
        'size_bytes',
        'sha256',
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
      subject: 'file:content',
      argumentToScope: const {'path': 'path'},
    ),
    requiresReadAfterWrite: true,
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
    final content = call.arguments['content'];
    final mode = call.arguments['mode']?.toString() ?? '';
    final encoding = call.arguments['encoding']?.toString() ?? 'utf8';
    if (content is! String ||
        !const {'create', 'overwrite', 'append'}.contains(mode)) {
      return error(
        call,
        'The requested file write is invalid.',
        'invalid_file_write',
      );
    }
    final List<int> bytes;
    try {
      bytes =
          encoding == 'utf8'
              ? utf8.encode(content)
              : encoding == 'base64'
              ? base64Decode(content)
              : throw const FormatException('Invalid encoding.');
    } on FormatException {
      return error(
        call,
        'The file content encoding is invalid.',
        'invalid_file_encoding',
      );
    }
    if (bytes.length > maxWriteBytes) {
      return error(
        call,
        'The file content exceeds the one MiB write limit.',
        'file_write_too_large',
      );
    }

    try {
      final type = await entityType(path);
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.file) {
        return error(
          call,
          'The requested path is not a file.',
          'local_path_type_mismatch',
        );
      }
      if (mode == 'create' && type == FileSystemEntityType.file) {
        return error(
          call,
          'The destination file already exists.',
          'file_already_exists',
        );
      }
      if (call.arguments['create_parents'] == true) {
        await Directory(path_context.dirname(path)).create(recursive: true);
      }
      final file = File(path);
      await file.writeAsBytes(
        bytes,
        mode: mode == 'append' ? FileMode.append : FileMode.write,
        flush: true,
      );
      cancellationToken.throwIfCancelled();
      final size = await file.length();
      final contentDigest =
          (await sha256.bind(file.openRead()).first).toString();
      final scope = <String, Object?>{'path': call.arguments['path']};
      final facts = <StructuredFact>[
        StructuredFact(name: 'action.completed', value: true),
        StructuredFact(name: 'file.size_bytes', value: size),
        StructuredFact(name: 'file.content_sha256', value: contentDigest),
      ];
      final observedAt = DateTime.now().toUtc();
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'Wrote ${bytes.length} bytes to $path.',
        structuredContent: {
          'path': path,
          'mode': mode,
          'bytes_written': bytes.length,
          'size_bytes': size,
          'sha256': contentDigest,
          ...toolEvidenceOutputMetadata(
            evidenceKind: EvidenceKind.actionReceipt,
            subject: 'file:content',
            scope: scope,
            structuredFacts: facts,
            observedAt: observedAt,
          ),
        },
        evidenceKind: EvidenceKind.actionReceipt,
        subject: 'file:content',
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
