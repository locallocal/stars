part of 'local_file_system_tools.dart';

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
          if (bytes.isNotEmpty && decoded.byteLength == 0) {
            return error(
              call,
              'The requested byte range is too small to contain one complete '
                  'UTF-8 character. Increase max_bytes or read it as base64.',
              'file_utf8_range_too_small',
            );
          }
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
      if (mode == 'create') {
        try {
          await file.create(exclusive: true);
        } on FileSystemException {
          if (await entityType(path) == FileSystemEntityType.file) {
            return error(
              call,
              'The destination file already exists.',
              'file_already_exists',
            );
          }
          rethrow;
        }
      }
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
