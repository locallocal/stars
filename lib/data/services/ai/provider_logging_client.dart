import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:stars/data/services/ai/provider_log_redactor.dart';
import 'package:stars/data/services/ai/provider_log_sink.dart';
import 'package:stars/domain/models/bot.dart';

/// Observes the transport without buffering delivery or owning injected clients.
final class ProviderLoggingClient extends http.BaseClient {
  ProviderLoggingClient({
    required http.Client inner,
    required ProviderLogSink sink,
    required Bot bot,
    required String operation,
    this.maxBodyBytes = 2 * 1024 * 1024,
  }) : assert(maxBodyBytes > 0),
       _inner = inner,
       _sink = sink,
       _redactor = ProviderLogRedactor(apiKey: bot.apiKey),
       _metadata = {
         'bot_id': bot.id,
         'provider': bot.apiType,
         'model': bot.model,
         'operation': operation,
       };

  final http.Client _inner;
  final ProviderLogSink _sink;
  final ProviderLogRedactor _redactor;
  final Map<String, String> _metadata;
  final int maxBodyBytes;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    var enabled = false;
    try {
      enabled = await _sink.enabled;
    } on Object {
      /* Diagnostics are optional. */
    }
    if (!enabled) return _inner.send(request);
    final random = Random.secure();
    final id =
        List.generate(
          16,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
    final elapsed = Stopwatch()..start();
    void record(String kind, Map<String, Object?> Function() fields) {
      try {
        _sink.add({
          ..._metadata,
          'request_id': id,
          'event': kind,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          ...fields(),
        });
      } on Object {
        /* A diagnostic failure must not change the request. */
      }
    }

    record('request', () {
      final bytes = request is http.Request ? request.bodyBytes : const <int>[];
      return {
        'method': request.method,
        'url': _redactor.url(request.url),
        'headers': _redactor.headers(request.headers),
        'body':
            request is http.MultipartRequest
                ? {
                  'fields': _redactor.value(request.fields),
                  'files': [
                    for (final file in request.files)
                      {
                        'field': _redactor.text(file.field),
                        'bytes': file.length,
                        'content_type': file.contentType.toString(),
                      },
                  ],
                }
                : _body(
                  bytes,
                  request.headers['content-type'] ?? '',
                  truncated: bytes.length > maxBodyBytes,
                ),
        'body_bytes': request.contentLength,
        'body_truncated': bytes.length > maxBodyBytes,
      };
    });
    try {
      final response = await _inner.send(request);
      record(
        'response_headers',
        () => {
          'status_code': response.statusCode,
          'headers': _redactor.headers(response.headers),
          'elapsed_ms': elapsed.elapsedMilliseconds,
        },
      );
      return http.StreamedResponse(
        _observe(response, elapsed, record),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } on Object catch (error) {
      record(
        'transport_error',
        () => {
          'error': _redactor.text(error.toString()),
          'elapsed_ms': elapsed.elapsedMilliseconds,
        },
      );
      rethrow;
    }
  }

  Stream<List<int>> _observe(
    http.StreamedResponse response,
    Stopwatch elapsed,
    void Function(String, Map<String, Object?> Function()) record,
  ) {
    final retained = BytesBuilder(copy: false);
    var total = 0;
    var finished = false;
    var outcome = 'completed';
    void finish(String status) {
      if (finished) return;
      finished = true;
      record(
        'response',
        () => {
          'status_code': response.statusCode,
          'outcome': status,
          'elapsed_ms': elapsed.elapsedMilliseconds,
          'body_bytes': total,
          'body_truncated': total > maxBodyBytes,
          'body': _body(
            retained.takeBytes(),
            response.headers['content-type'] ?? '',
            truncated: total > maxBodyBytes,
          ),
        },
      );
    }

    late StreamController<List<int>> controller;
    StreamSubscription<List<int>>? subscription;
    controller = StreamController<List<int>>(
      sync: true,
      onListen: () {
        subscription = response.stream.listen(
          (bytes) {
            total += bytes.length;
            final remaining = maxBodyBytes - retained.length;
            if (remaining > 0) {
              retained.add(Uint8List.fromList(bytes.take(remaining).toList()));
            }
            controller.add(bytes);
          },
          onError: (Object error, StackTrace stack) {
            outcome = 'stream_error';
            record(
              'stream_error',
              () => {'error': _redactor.text(error.toString())},
            );
            controller.addError(error, stack);
          },
          onDone: () {
            finish(outcome);
            unawaited(controller.close());
          },
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        finish(outcome == 'stream_error' ? outcome : 'cancelled');
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  Object? _body(
    List<int> bytes,
    String contentType, {
    required bool truncated,
  }) {
    if (bytes.isEmpty) return null;
    if (contentType.startsWith('image/') ||
        contentType.startsWith('audio/') ||
        contentType.startsWith('video/') ||
        contentType.contains('octet-stream')) {
      return '[binary body omitted]';
    }
    var source = utf8.decode(
      bytes.take(maxBodyBytes).toList(),
      allowMalformed: true,
    );
    final eventStream = contentType.contains('text/event-stream');
    if (truncated) {
      // An incomplete JSON string cannot reliably be redacted. SSE can retain
      // complete events, but never write the partially captured last line.
      if (!eventStream) return '[body omitted: capture limit exceeded]';
      final lastLine = source.lastIndexOf('\n');
      source = lastLine < 0 ? '' : source.substring(0, lastLine + 1);
    }
    return _redactor.body(source, eventStream: eventStream);
  }

  @override
  void close() => _inner.close();
}
