part of 'skill_tool_sessions.dart';

const _openAiWebSearchToolName = 'openai.responses.web_search';
const _openAiWebSearchToolVersion = 'openai.responses.web_search.1';
const _openAiWebSearchValidity = Duration(minutes: 15);
const _maxOpenAiCitations = 20;
const _maxOpenAiCitationTextCharacters = 512;
const _maxOpenAiCitationTitleCharacters = 256;
const _maxOpenAiSourceUrlCharacters = 2048;

final ToolDefinition _openAiWebSearchDefinition = ToolDefinition(
  name: _openAiWebSearchToolName,
  title: 'OpenAI web search',
  description: 'Provider-hosted web search normalized by Stars.',
  inputSchema: const {
    'type': 'object',
    'properties': {
      'action': {
        'type': 'string',
        'enum': ['search', 'open_page', 'find_in_page'],
      },
      'query_digest': {'type': 'string', 'pattern': r'^[a-f0-9]{64}$'},
      'source_resource_id': {'type': 'string', 'minLength': 1},
      'pattern_digest': {'type': 'string', 'pattern': r'^[a-f0-9]{64}$'},
    },
    'required': ['action'],
    'additionalProperties': false,
  },
  outputSchema: const {
    'type': 'object',
    'properties': {
      'citations': {
        'type': 'array',
        'minItems': 1,
        'maxItems': _maxOpenAiCitations,
        'items': {
          'type': 'object',
          'properties': {
            'provider_reference_id': {'type': 'string', 'minLength': 1},
            'source_resource_id': {'type': 'string', 'minLength': 1},
            'url': {'type': 'string', 'format': 'uri'},
            'title': {'type': 'string'},
            'text': {'type': 'string', 'minLength': 1},
          },
          'required': [
            'provider_reference_id',
            'source_resource_id',
            'url',
            'title',
            'text',
          ],
          'additionalProperties': false,
        },
      },
      ...toolEvidenceOutputSchemaProperties,
    },
    'required': ['citations', ...toolEvidenceOutputRequiredFields],
    'additionalProperties': false,
  },
  source: ToolSource.providerNative,
  riskLevel: ToolRiskLevel.readOnly,
  capabilities: const {ToolCapability.network, ToolCapability.externalRead},
  toolVersion: _openAiWebSearchToolVersion,
  evidenceCapabilities: const {EvidenceKind.observation},
  evidenceScope: ToolEvidenceScopeRule(
    subject: 'web:search',
    argumentToScope: const {
      'action': 'action',
      'query_digest': 'query_digest',
      'source_resource_id': 'source_resource_id',
      'pattern_digest': 'pattern_digest',
    },
  ),
  defaultEvidenceValidity: _openAiWebSearchValidity,
);

Map<String, ProviderNativeToolResult> _normalizeOpenAiNativeToolResults({
  required Map<String, Object?> root,
  required List<Object?> output,
  required DateTime Function() now,
}) {
  final webItems = [
    for (final rawItem in output)
      if (_objectMap(rawItem)['type'] == 'web_search_call') _objectMap(rawItem),
  ];
  if (webItems.isEmpty) return const {};
  final reportedAt = _openAiResponseTime(root, now);
  final extracted = _openAiUrlCitations(output);
  final results = <String, ProviderNativeToolResult>{};
  for (final item in webItems) {
    final providerCallId = item['id']?.toString() ?? '';
    if (!_isSafeProviderIdentifier(providerCallId) ||
        results.containsKey(providerCallId)) {
      continue;
    }
    final action = _objectMap(item['action']);
    final arguments = _openAiWebSearchArguments(action);
    final call = ToolCallRequest(
      callId: providerCallId,
      name: _openAiWebSearchToolName,
      arguments: arguments,
    );
    final result = _openAiWebSearchResult(
      item: item,
      action: action,
      call: call,
      allCitations: extracted.citations,
      singleWebCall: webItems.length == 1,
      citationCollectionIncomplete: extracted.incomplete,
      reportedAt: reportedAt,
    );
    results[providerCallId] = ProviderNativeToolResult(
      definition: _openAiWebSearchDefinition,
      call: call,
      result: result,
      reportedAt: reportedAt,
    );
  }
  return Map<String, ProviderNativeToolResult>.unmodifiable(results);
}

ToolResult _openAiWebSearchResult({
  required Map<String, Object?> item,
  required Map<String, Object?> action,
  required ToolCallRequest call,
  required List<_OpenAiUrlCitation> allCitations,
  required bool singleWebCall,
  required bool citationCollectionIncomplete,
  required DateTime reportedAt,
}) {
  final status = item['status']?.toString() ?? '';
  if (status != 'completed') {
    return _openAiWebSearchFailure(
      call,
      reportedAt,
      errorCode: 'provider_native_tool_incomplete',
    );
  }
  final actionType = action['type']?.toString() ?? '';
  if (!const {'search', 'open_page', 'find_in_page'}.contains(actionType)) {
    return _openAiWebSearchFailure(
      call,
      reportedAt,
      errorCode: 'provider_native_tool_invalid_action',
    );
  }
  final binding = _openAiActionSourceBinding(action);
  final citations =
      binding.hasMetadata
          ? allCitations
              .where((citation) => binding.urls.contains(citation.url))
              .toList(growable: false)
          : singleWebCall
          ? allCitations
          : const <_OpenAiUrlCitation>[];
  if (citations.isEmpty) {
    return _openAiWebSearchFailure(
      call,
      reportedAt,
      errorCode:
          singleWebCall
              ? 'provider_native_citation_missing'
              : 'provider_native_citations_unbound',
    );
  }
  if (citationCollectionIncomplete ||
      citations.any((citation) => citation.truncated)) {
    return _openAiWebSearchFailure(
      call,
      reportedAt,
      errorCode: 'provider_native_result_truncated',
      truncated: true,
    );
  }

  final facts = <StructuredFact>[
    for (var index = 0; index < citations.length; index += 1)
      StructuredFact(
        name: 'web.citation.${index + 1}',
        value: citations[index].text,
        attributes: citations[index].factAttributes,
      ),
  ];
  final scope = Map<String, Object?>.from(call.arguments);
  final structuredCitations = [
    for (final citation in citations) citation.toJson(),
  ];
  return ToolResult(
    callId: call.callId,
    name: call.name,
    content:
        'Provider web search returned ${citations.length} cited source(s).',
    structuredContent: {
      'citations': structuredCitations,
      ...toolEvidenceOutputMetadata(
        evidenceKind: EvidenceKind.observation,
        subject: 'web:search',
        scope: scope,
        structuredFacts: facts,
        observedAt: reportedAt,
      ),
    },
    source: ToolSource.providerNative,
    schemaValid: true,
    evidenceKind: EvidenceKind.observation,
    subject: 'web:search',
    scope: scope,
    structuredFacts: facts,
    observedAt: reportedAt,
  );
}

ToolResult _openAiWebSearchFailure(
  ToolCallRequest call,
  DateTime reportedAt, {
  required String errorCode,
  bool truncated = false,
}) => ToolResult(
  callId: call.callId,
  name: call.name,
  content: 'Provider web search did not return usable cited evidence.',
  isError: true,
  errorCode: errorCode,
  source: ToolSource.providerNative,
  truncated: truncated,
  observedAt: reportedAt,
);

Map<String, Object?> _openAiWebSearchArguments(Map<String, Object?> action) {
  final actionType = action['type']?.toString() ?? 'unknown';
  final arguments = <String, Object?>{'action': actionType};
  switch (actionType) {
    case 'search':
      final queries = <String>[
        for (final value in _objectList(action['queries']))
          if (value is String && value.trim().isNotEmpty) value,
      ];
      final legacyQuery = action['query'];
      if (queries.isEmpty &&
          legacyQuery is String &&
          legacyQuery.trim().isNotEmpty) {
        queries.add(legacyQuery);
      }
      if (queries.isNotEmpty) {
        arguments['query_digest'] = _openAiDigest(queries);
      }
    case 'open_page':
      final url = _safeOpenAiSourceUrl(action['url']);
      if (url != null) arguments['source_resource_id'] = _openAiSourceId(url);
    case 'find_in_page':
      final url = _safeOpenAiSourceUrl(action['url']);
      if (url != null) arguments['source_resource_id'] = _openAiSourceId(url);
      final pattern = action['pattern'];
      if (pattern is String && pattern.trim().isNotEmpty) {
        arguments['pattern_digest'] = _openAiDigest(pattern);
      }
  }
  return arguments;
}

_OpenAiActionSourceBinding _openAiActionSourceBinding(
  Map<String, Object?> action,
) {
  final urls = <String>{};
  var hasMetadata = false;
  final rawSources = action['sources'];
  if (rawSources is List) {
    hasMetadata = true;
    for (final rawSource in rawSources) {
      final url = _safeOpenAiSourceUrl(_objectMap(rawSource)['url']);
      if (url != null) urls.add(url);
    }
  }
  if (const {'open_page', 'find_in_page'}.contains(action['type'])) {
    hasMetadata = true;
    final url = _safeOpenAiSourceUrl(action['url']);
    if (url != null) urls.add(url);
  }
  return _OpenAiActionSourceBinding(urls, hasMetadata: hasMetadata);
}

_OpenAiCitationCollection _openAiUrlCitations(List<Object?> output) {
  final citations = <_OpenAiUrlCitation>[];
  var incomplete = false;
  for (final rawItem in output) {
    final item = _objectMap(rawItem);
    if (item['type'] != 'message') continue;
    final messageId = item['id']?.toString() ?? '';
    if (!_isSafeProviderIdentifier(messageId)) {
      if (_objectList(item['content']).isNotEmpty) incomplete = true;
      continue;
    }
    var annotationIndex = 0;
    for (final rawContent in _objectList(item['content'])) {
      final content = _objectMap(rawContent);
      if (content['type'] != 'output_text') continue;
      final text = content['text'];
      if (text is! String) continue;
      for (final rawAnnotation in _objectList(content['annotations'])) {
        final currentIndex = annotationIndex;
        annotationIndex += 1;
        final annotation = _objectMap(rawAnnotation);
        if (annotation['type'] != 'url_citation') continue;
        if (citations.length >= _maxOpenAiCitations) {
          incomplete = true;
          continue;
        }
        final citation = _openAiUrlCitation(
          annotation: annotation,
          messageId: messageId,
          annotationIndex: currentIndex,
          text: text,
        );
        if (citation == null) {
          incomplete = true;
        } else {
          citations.add(citation);
        }
      }
    }
  }
  return _OpenAiCitationCollection(
    List<_OpenAiUrlCitation>.unmodifiable(citations),
    incomplete: incomplete,
  );
}

_OpenAiUrlCitation? _openAiUrlCitation({
  required Map<String, Object?> annotation,
  required String messageId,
  required int annotationIndex,
  required String text,
}) {
  final url = _safeOpenAiSourceUrl(annotation['url']);
  final start = annotation['start_index'];
  final end = annotation['end_index'];
  if (url == null ||
      start is! int ||
      end is! int ||
      start < 0 ||
      end <= start ||
      end > text.length) {
    return null;
  }
  final excerpt = _boundedOpenAiText(
    text.substring(start, end),
    _maxOpenAiCitationTextCharacters,
  );
  if (excerpt.value.isEmpty) return null;
  final title = _boundedOpenAiText(
    annotation['title']?.toString() ?? '',
    _maxOpenAiCitationTitleCharacters,
  );
  return _OpenAiUrlCitation(
    providerReferenceId: '$messageId:url_citation:$annotationIndex',
    sourceResourceId: _openAiSourceId(url),
    url: url,
    title: title.value,
    text: excerpt.value,
    truncated: excerpt.truncated || title.truncated,
  );
}

String? _safeOpenAiSourceUrl(Object? raw) {
  if (raw is! String || raw.length > _maxOpenAiSourceUrlCharacters) {
    return null;
  }
  final parsed = Uri.tryParse(raw);
  if (parsed == null ||
      !const {'http', 'https'}.contains(parsed.scheme.toLowerCase()) ||
      parsed.host.isEmpty) {
    return null;
  }
  final safe =
      Uri(
        scheme: parsed.scheme.toLowerCase(),
        host: parsed.host.toLowerCase(),
        port: parsed.hasPort ? parsed.port : null,
        path: parsed.path.isEmpty ? '/' : parsed.path,
      ).toString();
  return safe.length <= _maxOpenAiSourceUrlCharacters ? safe : null;
}

({String value, bool truncated}) _boundedOpenAiText(
  String raw,
  int maxCharacters,
) {
  final redacted =
      raw
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
          .replaceAll(
            RegExp(
              r'-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----',
            ),
            '[redacted private key]',
          )
          .replaceAll(
            RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
            'Bearer [redacted]',
          )
          .replaceAll(RegExp(r'\bsk-[A-Za-z0-9_-]{8,}\b'), '[redacted]')
          .replaceAllMapped(
            RegExp(
              r'''(authorization|cookie|password|secret|token|api[_-]?key|access[_-]?token|private[_-]?key)(["']?\s*[:=]\s*["']?)[^"'\s,;}]+''',
              caseSensitive: false,
            ),
            (match) => '${match.group(1)}${match.group(2)}[redacted]',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
  final runes = redacted.runes.toList(growable: false);
  if (runes.length <= maxCharacters) {
    return (value: redacted, truncated: false);
  }
  return (
    value: String.fromCharCodes(runes.take(maxCharacters)),
    truncated: true,
  );
}

DateTime _openAiResponseTime(
  Map<String, Object?> root,
  DateTime Function() now,
) {
  final createdAt = root['created_at'];
  if (createdAt is int && createdAt >= 0) {
    return DateTime.fromMillisecondsSinceEpoch(createdAt * 1000, isUtc: true);
  }
  return now().toUtc();
}

bool _isSafeProviderIdentifier(String value) =>
    value.isNotEmpty &&
    value.trim() == value &&
    value.length <= 1024 &&
    !RegExp(r'[\x00-\x1F\x7F]').hasMatch(value);

String _openAiSourceId(String url) => 'url:${_openAiDigest(url)}';

String _openAiDigest(Object value) =>
    sha256.convert(utf8.encode(jsonEncode(value))).toString();

final class _OpenAiCitationCollection {
  const _OpenAiCitationCollection(this.citations, {required this.incomplete});

  final List<_OpenAiUrlCitation> citations;
  final bool incomplete;
}

final class _OpenAiActionSourceBinding {
  const _OpenAiActionSourceBinding(this.urls, {required this.hasMetadata});

  final Set<String> urls;
  final bool hasMetadata;
}

final class _OpenAiUrlCitation {
  const _OpenAiUrlCitation({
    required this.providerReferenceId,
    required this.sourceResourceId,
    required this.url,
    required this.title,
    required this.text,
    required this.truncated,
  });

  final String providerReferenceId;
  final String sourceResourceId;
  final String url;
  final String title;
  final String text;
  final bool truncated;

  Map<String, Object?> get factAttributes => <String, Object?>{
    'provider_reference_id': providerReferenceId,
    'source_resource_id': sourceResourceId,
    'source_url': url,
    if (title.isNotEmpty) 'source_title': title,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_reference_id': providerReferenceId,
    'source_resource_id': sourceResourceId,
    'url': url,
    'title': title,
    'text': text,
  };
}
