import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Stable categories for failures observed at a provider boundary.
enum ProviderFailureKind {
  authentication,
  authorization,
  notFound,
  timeout,
  rateLimited,
  quotaExceeded,
  server,
  transport,
  invalidResponse,
  configuration,
  rejected,
}

/// Identifies the API surface without retaining or exposing its URL.
enum ProviderEndpointKind {
  models,
  chatCompletions,
  responses,
  images,
  speech,
  videos,
  messages,
  unknown,
}

/// A provider failure containing only product-safe, structured diagnostics.
///
/// Product-visible fields never retain raw URLs, headers, credentials, or
/// response bodies. [debugCause] is diagnostic-only and must not be rendered
/// or written to ordinary logs because a transport exception can be sensitive.
final class ProviderFailure implements Exception {
  ProviderFailure({
    required this.code,
    required this.kind,
    required this.endpointKind,
    required this.retryable,
    this.httpStatus,
    String requestTraceId = '',
    this.debugCause,
  }) : requestTraceId = redactRequestTraceId(requestTraceId);

  factory ProviderFailure.fromHttp({
    required int statusCode,
    required ProviderEndpointKind endpointKind,
    Map<String, String> headers = const {},
    String responseBody = '',
  }) {
    final requestTraceId = _requestTraceId(headers);
    return switch (statusCode) {
      401 => ProviderFailure(
        code: 'provider_authentication_failed',
        kind: ProviderFailureKind.authentication,
        httpStatus: statusCode,
        endpointKind: endpointKind,
        retryable: false,
        requestTraceId: requestTraceId,
      ),
      403 => ProviderFailure(
        code: 'provider_authorization_failed',
        kind: ProviderFailureKind.authorization,
        httpStatus: statusCode,
        endpointKind: endpointKind,
        retryable: false,
        requestTraceId: requestTraceId,
      ),
      404 => ProviderFailure(
        code: 'provider_endpoint_not_found',
        kind: ProviderFailureKind.notFound,
        httpStatus: statusCode,
        endpointKind: endpointKind,
        retryable: false,
        requestTraceId: requestTraceId,
      ),
      408 => ProviderFailure(
        code: 'provider_request_timeout',
        kind: ProviderFailureKind.timeout,
        httpStatus: statusCode,
        endpointKind: endpointKind,
        retryable: true,
        requestTraceId: requestTraceId,
      ),
      429 when _providerErrorCode(responseBody) == 'insufficient_quota' =>
        ProviderFailure(
          code: 'provider_quota_exceeded',
          kind: ProviderFailureKind.quotaExceeded,
          httpStatus: statusCode,
          endpointKind: endpointKind,
          retryable: false,
          requestTraceId: requestTraceId,
        ),
      429 => ProviderFailure(
        code: 'provider_rate_limited',
        kind: ProviderFailureKind.rateLimited,
        httpStatus: statusCode,
        endpointKind: endpointKind,
        retryable: true,
        requestTraceId: requestTraceId,
      ),
      >= 500 && <= 599 => ProviderFailure(
        code: 'provider_server_error',
        kind: ProviderFailureKind.server,
        httpStatus: statusCode,
        endpointKind: endpointKind,
        retryable: true,
        requestTraceId: requestTraceId,
      ),
      _ => ProviderFailure(
        code: 'provider_request_rejected',
        kind: ProviderFailureKind.rejected,
        httpStatus: statusCode,
        endpointKind: endpointKind,
        retryable: false,
        requestTraceId: requestTraceId,
      ),
    };
  }

  factory ProviderFailure.timeout({
    required ProviderEndpointKind endpointKind,
    int? httpStatus,
    Object? cause,
  }) => ProviderFailure(
    code: 'provider_request_timeout',
    kind: ProviderFailureKind.timeout,
    httpStatus: httpStatus,
    endpointKind: endpointKind,
    retryable: true,
    debugCause: cause,
  );

  factory ProviderFailure.transport({
    required ProviderEndpointKind endpointKind,
    Object? cause,
  }) => ProviderFailure(
    code: 'provider_transport_error',
    kind: ProviderFailureKind.transport,
    endpointKind: endpointKind,
    retryable: true,
    debugCause: cause,
  );

  factory ProviderFailure.invalidResponse({
    required ProviderEndpointKind endpointKind,
    String code = 'invalid_provider_response',
    Object? cause,
  }) => ProviderFailure(
    code: code,
    kind: ProviderFailureKind.invalidResponse,
    endpointKind: endpointKind,
    retryable: false,
    debugCause: cause,
  );

  factory ProviderFailure.configuration({
    required ProviderEndpointKind endpointKind,
    String code = 'provider_invalid_base_url',
    Object? cause,
  }) => ProviderFailure(
    code: code,
    kind: ProviderFailureKind.configuration,
    endpointKind: endpointKind,
    retryable: false,
    debugCause: cause,
  );

  final String code;
  final ProviderFailureKind kind;
  final int? httpStatus;
  final ProviderEndpointKind endpointKind;
  final bool retryable;
  final String requestTraceId;
  final Object? debugCause;

  /// Produces a stable correlation value without retaining the provider ID.
  static String redactRequestTraceId(String source) {
    final value = source.trim();
    if (value.isEmpty) return '';
    var hash = 0xcbf29ce484222325;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return 'trace_${hash.toRadixString(16).padLeft(16, '0')}';
  }

  static String _requestTraceId(Map<String, String> headers) {
    if (headers.isEmpty) return '';
    final normalized = <String, String>{
      for (final entry in headers.entries) entry.key.toLowerCase(): entry.value,
    };
    for (final name in const [
      'x-request-id',
      'request-id',
      'x-trace-id',
      'traceparent',
    ]) {
      final value = normalized[name]?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _providerErrorCode(String responseBody) {
    if (responseBody.isEmpty || responseBody.length > 65536) return '';
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map) return '';
      final error = decoded['error'];
      final rawCode =
          error is Map
              ? error['code']?.toString()
              : decoded['code']?.toString();
      final code = rawCode?.trim().toLowerCase() ?? '';
      return RegExp(r'^[a-z0-9_.-]{1,64}$').hasMatch(code) ? code : '';
    } on FormatException {
      return '';
    }
  }

  @override
  String toString() => 'ProviderFailure($code)';
}

/// Converts known transport exceptions without parsing their messages.
ProviderFailure classifyProviderTransportFailure(
  Object error, {
  required ProviderEndpointKind endpointKind,
}) {
  if (error is ProviderFailure) return error;
  if (error is TimeoutException) {
    return ProviderFailure.timeout(endpointKind: endpointKind, cause: error);
  }
  if (error is SocketException) {
    return ProviderFailure.transport(endpointKind: endpointKind, cause: error);
  }
  return ProviderFailure.transport(endpointKind: endpointKind, cause: error);
}
