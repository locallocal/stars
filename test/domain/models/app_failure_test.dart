import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  test('classifies retryable transport failures without exposing cause', () {
    final failure = AppFailure.from(
      TimeoutException('secret endpoint and response body'),
    );

    expect(failure.kind, AppFailureKind.networkTimeout);
    expect(failure.retryable, isTrue);
    expect(failure.code, 'network_timeout');
    expect(failure.toString(), 'AppFailure(network_timeout)');
    expect(failure.toString(), isNot(contains('secret endpoint')));
  });

  test('maps structured Provider failures into product-safe failures', () {
    final authentication = AppFailure.from(
      ProviderFailure.fromHttp(
        statusCode: 401,
        endpointKind: ProviderEndpointKind.responses,
      ),
    );
    final rateLimit = AppFailure.from(
      ProviderFailure.fromHttp(
        statusCode: 429,
        endpointKind: ProviderEndpointKind.responses,
      ),
    );

    expect(authentication.kind, AppFailureKind.authentication);
    expect(authentication.code, 'provider_authentication_failed');
    expect(authentication.retryable, isFalse);
    expect(rateLimit.kind, AppFailureKind.rateLimited);
    expect(rateLimit.code, 'provider_rate_limited');
    expect(rateLimit.retryable, isTrue);
  });

  test('classifies Provider HTTP failures with explicit retry semantics', () {
    final expectations = <(int, ProviderFailureKind, String, bool)>[
      (
        401,
        ProviderFailureKind.authentication,
        'provider_authentication_failed',
        false,
      ),
      (
        403,
        ProviderFailureKind.authorization,
        'provider_authorization_failed',
        false,
      ),
      (404, ProviderFailureKind.notFound, 'provider_endpoint_not_found', false),
      (408, ProviderFailureKind.timeout, 'provider_request_timeout', true),
      (429, ProviderFailureKind.rateLimited, 'provider_rate_limited', true),
      (503, ProviderFailureKind.server, 'provider_server_error', true),
    ];

    for (final (status, kind, code, retryable) in expectations) {
      final failure = ProviderFailure.fromHttp(
        statusCode: status,
        endpointKind: ProviderEndpointKind.chatCompletions,
      );
      expect(failure.kind, kind, reason: 'HTTP $status');
      expect(failure.code, code, reason: 'HTTP $status');
      expect(failure.httpStatus, status, reason: 'HTTP $status');
      expect(failure.retryable, retryable, reason: 'HTTP $status');
    }
  });

  test('does not retain response secrets and redacts request trace IDs', () {
    const traceId = 'req-secret-correlation-value';
    const secretBody =
        '{"error":{"message":"Bearer sk-secret Cookie=session-secret"}}';

    final failure = ProviderFailure.fromHttp(
      statusCode: 404,
      endpointKind: ProviderEndpointKind.responses,
      headers: const {'X-Request-Id': traceId},
      responseBody: secretBody,
    );

    expect(failure.requestTraceId, startsWith('trace_'));
    expect(failure.requestTraceId, isNot(contains(traceId)));
    expect(failure.toString(), 'ProviderFailure(provider_endpoint_not_found)');
    expect(failure.toString(), isNot(contains('sk-secret')));
    expect(failure.toString(), isNot(contains('session-secret')));
  });

  test('does not infer local Provider failures from external client text', () {
    final failure = AppFailure.from(
      Exception(
        'Codex client GET https://chatgpt.com/backend-api/codex returned 404',
      ),
    );

    expect(failure.kind, AppFailureKind.unknown);
    expect(failure.code, 'unknown_failure');
  });

  test('preserves a safe MCP code without exposing its raw message', () {
    final failure = AppFailure.from(
      const McpException(
        'mcp_stdio_start_failed',
        message: 'secret command and environment',
      ),
    );

    expect(failure.kind, AppFailureKind.providerRejected);
    expect(failure.code, 'mcp_stdio_start_failed');
    expect(failure.toString(), isNot(contains('secret command')));
  });
}
