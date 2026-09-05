import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:stars/domain/models/provider_failure.dart';

typedef ProviderRetryDelay = Future<void> Function(Duration duration);

/// Default wall-clock budget for one generation or Skill-model request.
///
/// Agent runs can contain several model turns, so this remains bounded below
/// the run-level deadline while allowing slower reasoning providers to finish.
const Duration defaultProviderGenerationTimeout = Duration(minutes: 5);

/// Applies one wall-clock deadline to an entire response stream.
///
/// [Stream.timeout] restarts its timer after every event and therefore only
/// detects idle gaps. Provider generation needs a total body deadline as well,
/// otherwise a slow but active stream can outlive the request budget forever.
Stream<T> withProviderStreamTimeout<T>(Stream<T> source, Duration timeout) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? timer;
  var closed = false;

  Future<void> close() async {
    if (closed) return;
    closed = true;
    timer?.cancel();
    timer = null;
    await controller.close();
  }

  controller = StreamController<T>(
    sync: true,
    onListen: () {
      timer = Timer(timeout, () {
        if (closed) return;
        controller.addError(
          TimeoutException('Provider response stream timed out.'),
        );
        unawaited(subscription?.cancel());
        unawaited(close());
      });
      subscription = source.listen(
        (event) {
          if (!closed) controller.add(event);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (closed) return;
          controller.addError(error, stackTrace);
          unawaited(close());
        },
        onDone: () => unawaited(close()),
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      closed = true;
      timer?.cancel();
      timer = null;
      await subscription?.cancel();
    },
  );
  return controller.stream;
}

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
