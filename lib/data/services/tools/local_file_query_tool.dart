part of 'local_file_system_tools.dart';

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
        ...toolEvidenceOutputSchemaProperties,
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
      subject: _fileQuerySubject,
      argumentToScope: const {
        'root_path': 'root_path',
        'query': 'query',
        'match_mode': 'match_mode',
        'case_sensitive': 'case_sensitive',
        'recursive': 'recursive',
        'max_results': 'max_results',
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
      final scope = _evidenceScopeFor(call, const {
        'root_path',
        'query',
        'match_mode',
        'case_sensitive',
        'recursive',
        'max_results',
        'max_entries',
      });
      final facts = <StructuredFact>[
        StructuredFact(name: 'file.match_count', value: files.length),
        StructuredFact(name: 'file.query_complete', value: !truncated),
        StructuredFact(name: 'file.scanned_entries', value: scannedEntries),
      ];
      final observedAt = DateTime.now().toUtc();
      final structured = <String, Object?>{
        'root_path': rootPath,
        'query': requestedQuery,
        'match_mode': matchMode,
        'case_sensitive': caseSensitive,
        'recursive': recursive,
        'files': files,
        'scanned_entries': scannedEntries,
        'truncated': truncated,
        ...toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.observation,
          subject: _fileQuerySubject,
          scope: scope,
          structuredFacts: facts,
          observedAt: observedAt,
        ),
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
        evidenceKind: EvidenceKind.observation,
        subject: _fileQuerySubject,
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
