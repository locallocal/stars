import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:stars/domain/models/provider_failure.dart';

typedef ProviderRetryDelay = Future<void> Function(Duration duration);

final class ProviderRetryPolicy {
  const ProviderRetryPolicy({
    this.maxAttempts = 3,
    this.initialBackoff = const Duration(milliseconds: 50),
    this.maximumBackoff = const Duration(seconds: 1),
  }) : assert(maxAttempts > 0);

  final int maxAttempts;
  final Duration initialBackoff;
  final Duration maximumBackoff;

  Duration backoffAfter(int failedAttempt) {
    var milliseconds = initialBackoff.inMilliseconds;
    for (var exponent = 1; exponent < failedAttempt; exponent += 1) {
      milliseconds *= 2;
      if (milliseconds >= maximumBackoff.inMilliseconds) {
        return maximumBackoff;
      }
    }
    return Duration(
      milliseconds:
          milliseconds > maximumBackoff.inMilliseconds
              ? maximumBackoff.inMilliseconds
              : milliseconds,
    );
  }
}

Future<http.Response> sendProviderRequest({
  required Future<http.Response> Function() send,
  required ProviderEndpointKind endpointKind,
  required Duration timeout,
  ProviderRetryPolicy retryPolicy = const ProviderRetryPolicy(),
  ProviderRetryDelay delay = Future<void>.delayed,
}) async {
  ProviderFailure? lastFailure;
  for (var attempt = 1; attempt <= retryPolicy.maxAttempts; attempt += 1) {
    try {
      final response = await send().timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      lastFailure = ProviderFailure.fromHttp(
        statusCode: response.statusCode,
        endpointKind: endpointKind,
        headers: response.headers,
        responseBody: response.body,
      );
    } catch (error) {
      lastFailure = classifyProviderTransportFailure(
        error,
        endpointKind: endpointKind,
      );
    }

    if (!lastFailure.retryable || attempt == retryPolicy.maxAttempts) {
      throw lastFailure;
    }
    await delay(retryPolicy.backoffAfter(attempt));
  }
  throw StateError('Provider retry loop completed without a result.');
}

Future<http.StreamedResponse> sendProviderStreamRequest({
  required Future<http.StreamedResponse> Function() send,
  required ProviderEndpointKind endpointKind,
  required Duration timeout,
  ProviderRetryPolicy retryPolicy = const ProviderRetryPolicy(),
  ProviderRetryDelay delay = Future<void>.delayed,
}) async {
  ProviderFailure? lastFailure;
  for (var attempt = 1; attempt <= retryPolicy.maxAttempts; attempt += 1) {
    try {
      final response = await send().timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      final body = await response.stream.bytesToString();
      lastFailure = ProviderFailure.fromHttp(
        statusCode: response.statusCode,
        endpointKind: endpointKind,
        headers: response.headers,
        responseBody: body,
      );
    } catch (error) {
      lastFailure = classifyProviderTransportFailure(
        error,
        endpointKind: endpointKind,
      );
    }

    if (!lastFailure.retryable || attempt == retryPolicy.maxAttempts) {
      throw lastFailure;
    }
    await delay(retryPolicy.backoffAfter(attempt));
  }
  throw StateError('Provider retry loop completed without a result.');
}
